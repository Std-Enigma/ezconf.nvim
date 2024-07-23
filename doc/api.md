# Lua API

ezconf API documentation

## ezconf

Neovim Core settings manager.

This module can be loaded with `local ezconf = require "ezconf"`

copyright 2023
license GNU General Public License v3.0

### config

```lua
EZConfOpts
```

The configuration as set by the user through the `setup()` function

### diagnostics

```lua
{ [integer]: vim.diagnostic.Opts }
```

A table of settings for different levels of diagnostics

### empty_map_table

```lua
function ezconf.empty_map_table()
  -> table<string, table>
```

Get an empty table of mappings with a key for each map mode

_return_ — a table with entries for each map mode

### reload

```lua
function ezconf.reload()
```

Partially reload user settings. Includes core vim options, mappings, and highlights. This is an experimental feature and may lead to instabilities until restart.

### set_mappings

```lua
function ezconf.set_mappings(map_table: table<string, table<string, (string|function|EZConfMapping|false)?>?>, base?: vim.keymap.set.Opts)
```

Table based API for setting keybindings

_param_ `map_table` — A nested table where the first key is the vim mode, the second key is the key to map, and the value is the function to set the mapping to

_param_ `base` — A base set of options to set on every keybinding

### setup

```lua
function ezconf.setup(opts: EZConfOpts)
```

Setup and configure EZConf
See: [ezconf.config](file:///home/runner/work/ezconf/ezconf/./lua/ezconf/init.lua#13#0)

### which_key_queue

```lua
nil
```

A placeholder variable used to queue section names to be registered by which-key

### which_key_register

```lua
function ezconf.which_key_register()
```

Register queued which-key mappings
