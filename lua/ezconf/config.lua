---@alias EZConfMappingCmd string|function

---@class EZConfMapping: vim.api.keyset.keymap
---@field [1] EZConfMappingCmd rhs of keymap
---@field name string? optional which-key mapping name

---@alias EZConfMappings table<string,table<string,(EZConfMapping|EZConfMappingCmd|false)?>?>

---@class EZConfCommand: vim.api.keyset.user_command
---@field [1] string|function the command to execute

---@class EZConfAutocmd: vim.api.keyset.create_autocmd
---@field event string|string[] Event(s) that will trigger the handler

---@class EZConfFeatureOpts
---@field diagnostics_mode integer? diagnostic mode on start (0 = off, 1 = no signs/virtual text, 2 = no virtual text, 3 = off; default = 3)

---@class EZConfOpts
---Configuration of auto commands
---The key into the table is the group name for the auto commands (`:h augroup`) and the value
---is a list of autocmd tables where `event` key is the event(s) that trigger the auto command
---and the rest are auto command options (`:h nvim_create_autocmd`)
---Example:
---
---```lua
---autocmds = {
---  -- first key is the `augroup` (:h augroup)
---  highlightyank = {
---    -- list of auto commands to set
---    {
---      -- events to trigger
---      event = { "TextYankPost" },
---      -- the rest of the autocmd options (:h nvim_create_autocmd)
---      desc = "Highlight yanked text",
---      callback = function() vim.highlight.on_yank() end
---    }
---  }
---}
---```
---@field autocmds table<string,EZConfAutocmd[]|false>?
---Configuration of user commands
---The key into the table is the name of the user command and the value is a table of command options
---Example:
---
---```lua
---commands = {
---  -- key is the command name
---  ConfReload = {
---    -- first element with no key is the command (string or function)
---    function() require("ezconf").reload() end, -- this functionality only works if you are using lazy.nvim as your plugin manager
---    -- the rest are options for creating user commands (:h nvim_create_user_command)
---    desc = "Reload user config (Experimental)",
---  }
---}
---```
---@field commands table<string,EZConfCommand|false>?
---Configure diagnostics options (`:h vim.diagnostic.config()`)
---Example:
--
---```lua
---diagnostics = { update_in_insert = false },
---```
---@field diagnostics vim.diagnostic.Opts?
---Configuration of filetypes, simply runs `vim.filetype.add`
---
---See `:h vim.filetype.add` for details on usage
---
---Example:
---
---```lua
---filetypes = { -- parameter to `vim.filetype.add`
---  extension = {
---    foo = "fooscript"
---  },
---  filename = {
---    [".foorc"] = "fooscript"
---  },
---  pattern = {
---    [".*/etc/foo/.*"] = "fooscript",
---  }
---}
---```
---@field filetypes vim.filetype.add.filetypes?
---Configuration of vim mappings to create.
---The first key into the table is the vim map mode (`:h map-modes`), and the value is a table of entries to be passed to `vim.keymap.set` (`:h vim.keymap.set`):
---  - The key is the first parameter or the vim mode (only a single mode supported) and the value is a table of keymaps within that mode:
---    - The first element with no key in the table is the action (the 2nd parameter) and the rest of the keys/value pairs are options for the third parameter.
---Example:
--
---```lua
---mappings = {
---  -- map mode (:h map-modes)
---  n = {
---    -- use vimscript strings for mappings
---    ["<C-s>"] = { ":w!<cr>", desc = "Save File" },
---    -- navigate buffer tabs with `H` and `L`
---    L = {
---      function() vim.cmd "bnext" end,
---      desc = "Next buffer",
---    },
---    H = {
---      function() vim.cmd "bprevious" end,
---      desc = "Previous buffer",
---    },
---    -- tables with just a `desc` key will be registered with which-key if it's installed
---    -- this is useful for naming menus
---    ["<leader>b"] = { desc = "Buffers" },
---  }
---}
---```
---@field mappings EZConfMappings?
---@field _map_sections table<string,{ desc: string?, name: string? }>?
---Configuration of vim `on_key` functions.
---The key into the table is the namespace of the function and the value is a list like table of `on_key` functions
---Example:
---
---```lua
---on_keys = {
---  -- first key is the namespace
---  auto_hlsearch = {
---    -- list of functions to execute on key press (:h vim.on_key)
---    function(char) -- example automatically disables `hlsearch` when not actively searching
---      if vim.fn.mode() == "n" then
---        local new_hlsearch = vim.tbl_contains({ "<CR>", "n", "N", "*", "#", "?", "/" }, vim.fn.keytrans(char))
---        if vim.opt.hlsearch:get() ~= new_hlsearch then vim.opt.hlsearch = new_hlsearch end
---      end
---    end,
---  },
---},
---```
---@field on_keys table<string,fun(key:string)[]|false>?
---Configuration of `vim` options (`vim.<first_key>.<second_key> = value`)
---The first key into the table is the type of option and the second key is the setting
---Example:
---
---```lua
---options = {
---  -- first key is the type of option
---  opt = { -- (`vim.opt`)
---    relativenumber = true, -- sets `vim.opt.relativenumber`
---    signcolumn = "auto", -- sets `vim.opt.signcolumn`
---  },
---  g = { -- (`vim.g`)
---    -- set global `vim.g.<key>` settings here
---  }
---}
---```
---@field options table<string,table<string,any>>?
---Configure signs (`:h sign_define()`)
---Example:
--
---```lua
---signs = {
---  DapBreakPoint" = { text = "", texthl = "DiagnosticInfo" },
---},
---```
---@field signs table<string,vim.fn.sign_define.dict|false>?
---Configuration table of features provided by AstroCore
---Example:
--
---```lua
---features = {
---  autopairs = true,
---  cmp = true,
---  diagnostics_mode = 3,
---  highlighturl = true,
---  notiifcations = true,
---  large_buf = { size = 1024 * 100, lines = 10000 },
---}
---```
---@field features EZConfFeatureOpts?

---@type EZConfOpts
local M = {
	autocmds = {},
	commands = {},
	diagnostics = {},
	filetypes = {},
	mappings = {},
	on_keys = {},
	options = {},
	signs = {},
	features = {
		diagnostics_mode = 3,
	},
}

return M
