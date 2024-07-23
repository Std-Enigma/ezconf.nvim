---@class ezconf
local M = {}

--- Get a plugin spec from lazy
---@param plugin string The plugin to search for
---@return LazyPlugin? available # The found plugin spec from Lazy
local function get_plugin(plugin)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  return lazy_config_avail and lazy_config.spec.plugins[plugin] or nil
end

--- Execute a function when a specified plugin is loaded with Lazy.nvim, or immediately if already loaded
---@param plugins string|string[] the name of the plugin or a list of plugins to defer the function execution on. If a list is provided, only one needs to be loaded to execute the provided function
---@param load_op fun()|string|string[] the function to execute when the plugin is loaded, a plugin name to load, or a list of plugin names to load
local function on_load(plugins, load_op)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  if lazy_config_avail then
    if type(plugins) == "string" then plugins = { plugins } end
    if type(load_op) ~= "function" then
      local to_load = type(load_op) == "string" and { load_op } or load_op --[=[@as string[]]=]
      load_op = function() require("lazy").load { plugins = to_load } end
    end

    for _, plugin in ipairs(plugins) do
      if vim.tbl_get(lazy_config.plugins, plugin, "_", "loaded") then
        vim.schedule(load_op)
        return
      end
    end
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyLoad",
      desc = ("A function to be ran when one of these plugins runs: %s"):format(vim.inspect(plugins)),
      callback = function(args)
        if vim.tbl_contains(plugins, args.data) then
          load_op()
          return true
        end
      end,
    })
  end
end

--- The configuration as set by the user through the `setup()` function
M.config = require "ezconf.config"

--- A table of settings for different levels of diagnostics
---@type table<integer,vim.diagnostic.Opts>
M.diagnostics = { [0] = {}, {}, {}, {} }

--- Partially reload user settings. Includes core vim options, mappings, and highlights. This is an experimental feature and may lead to instabilities until restart.
function M.reload()
  local lazy, was_modifiable = require "lazy", vim.opt.modifiable:get()
  if not was_modifiable then vim.opt.modifiable = true end
  lazy.reload { plugins = { get_plugin "ezconf" } }
  if not was_modifiable then vim.opt.modifiable = false end
  vim.cmd.doautocmd "ColorScheme"
end

--- A placeholder variable used to queue section names to be registered by which-key
---@type table?
M.which_key_queue = nil

--- Register queued which-key mappings
function M.which_key_register()
  if M.which_key_queue then
    local wk_avail, wk = pcall(require, "which-key")
    if wk_avail then
      wk.add(M.which_key_queue)
      M.which_key_queue = nil
    end
  end
end

--- Get an empty table of mappings with a key for each map mode
---@return table<string,table> # a table with entries for each map mode
function M.empty_map_table()
  local maps = {}
  for _, mode in ipairs { "", "n", "v", "x", "s", "o", "!", "i", "l", "c", "t" } do
    maps[mode] = {}
  end
  if vim.fn.has "nvim-0.10.0" == 1 then
    for _, abbr_mode in ipairs { "ia", "ca", "!a" } do
      maps[abbr_mode] = {}
    end
  end
  return maps
end

--- Table based API for setting keybindings
---@param map_table EZConfMappings A nested table where the first key is the vim mode, the second key is the key to map, and the value is the function to set the mapping to
---@param base? vim.keymap.set.Opts A base set of options to set on every keybinding
function M.set_mappings(map_table, base)
  local was_no_which_key_queue = not M.which_key_queue
  -- iterate over the first keys for each mode
  for mode, maps in pairs(map_table) do
    -- iterate over each keybinding set in the current mode
    for keymap, options in pairs(maps) do
      -- build the options for the command accordingly
      if options then
        local cmd
        local keymap_opts = base or {}
        if type(options) == "string" or type(options) == "function" then
          cmd = options
        else
          cmd = options[1]
          keymap_opts = vim.tbl_deep_extend("force", keymap_opts, options)
          keymap_opts[1] = nil
        end
        if not cmd then -- if which-key mapping, queue it
          ---@cast keymap_opts wk.Spec
          keymap_opts[1], keymap_opts.mode = keymap, mode
          if not keymap_opts.group then keymap_opts.group = keymap_opts.desc end
          if not M.which_key_queue then M.which_key_queue = {} end
          table.insert(M.which_key_queue, keymap_opts)
        else -- if not which-key mapping, set it
          vim.keymap.set(mode, keymap, cmd, keymap_opts)
        end
      end
    end
  end
  if was_no_which_key_queue and M.which_key_queue then on_load("which-key.nvim", M.which_key_register) end
end

--- Setup and configure EZConf
---@param opts EZConfOpts
---@see ezconf.config
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  -- options
  if vim.bo.filetype == "lazy" then vim.cmd.bw() end
  if vim.tbl_get(M.config, "options", "opt", "clipboard") then
    local opt = M.config.options.opt
    local lazy_clipboard = opt.clipboard
    opt.clipboard = nil
    vim.schedule(function() -- defer setting clipboard
      opt.clipboard = lazy_clipboard
      vim.opt.clipboard = opt.clipboard
    end)
  end
  for scope, settings in pairs(M.config.options) do
    for setting, value in pairs(settings) do
      vim[scope][setting] = value
    end
  end

  -- mappings
  M.set_mappings(M.config.mappings)

  -- autocmds
  for augroup, autocmds in pairs(M.config.autocmds) do
    if autocmds then
      local augroup_id = vim.api.nvim_create_augroup(augroup, { clear = true })
      for _, autocmd in ipairs(autocmds) do
        local event = autocmd.event
        autocmd.event = nil
        autocmd.group = augroup_id
        vim.api.nvim_create_autocmd(event, autocmd)
        autocmd.event = event
      end
    end
  end

  -- user commands
  for cmd, spec in pairs(M.config.commands) do
    if spec then
      local action = spec[1]
      spec[1] = nil
      vim.api.nvim_create_user_command(cmd, action, spec)
      spec[1] = action
    end
  end

  -- vim.filetype
  if M.config.filetypes then vim.filetype.add(M.config.filetypes) end

  -- on_key hooks
  for namespace, funcs in pairs(M.config.on_keys) do
    if funcs then
      local ns = vim.api.nvim_create_namespace(namespace)
      for _, func in ipairs(funcs) do
        vim.on_key(func, ns)
      end
    end
  end

  -- sign definition
  -- TODO: Remove when dropping support for Neovim v0.9
  -- Backwards compatibility of new diagnostic sign API to Neovim v0.9
  if vim.fn.has "nvim-0.10" ~= 1 then
    local signs = vim.tbl_get(M.config, "diagnostics", "signs") or {}
    if not M.config.signs then M.config.signs = {} end
    for _, type in ipairs { "Error", "Hint", "Info", "Warn" } do
      local name, severity = "DiagnosticSign" .. type, vim.diagnostic.severity[type:upper()]
      if M.config.signs[name] == nil then M.config.signs[name] = { text = "" } end
      if M.config.signs[name] then
        if not M.config.signs[name].texthl then M.config.signs[name].texthl = name end
        for attribute, severities in pairs(signs) do
          if severities[severity] then M.config.signs[name][attribute] = severities[severity] end
        end
      end
    end
  end
  for name, dict in pairs(M.config.signs or {}) do
    if dict then vim.fn.sign_define(name, dict) end
  end

  -- setup diagnostics
  M.diagnostics = {
    -- diagnostics off
    [0] = vim.tbl_deep_extend(
      "force",
      M.config.diagnostics,
      { underline = false, virtual_text = false, signs = false, update_in_insert = false }
    ) --[[@as vim.diagnostic.Opts]],
    -- status only
    vim.tbl_deep_extend("force", M.config.diagnostics, { virtual_text = false, signs = false }),
    -- virtual text off, signs on
    vim.tbl_deep_extend("force", M.config.diagnostics, { virtual_text = false }),
    -- all diagnostics on
    M.config.diagnostics,
  }
  vim.diagnostic.config(M.diagnostics[M.config.features.diagnostics_mode])
end

return M
