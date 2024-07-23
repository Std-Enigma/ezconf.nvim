# ⚙️ EZConf

An alternative solution to setup your neovim configuration.

## ⚠️ Caution

<b>which-key.nvim registration and reloading isn't possible if you are using any package manager rather than [lazy.nvim](https://github.com/folke/lazy.nvim)</b>

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "Std-Enigma/ezconf.nvim",
  lazy = false, -- disable lazy loading
  priority = 10000, -- load EZConf first
  opts = {
    -- set configuration options  as described below
  },
}
```

<!-- config:end -->

</details>

## 💡 API

**EZConf** provides a Lua API with utility functions. This can be viewed with `:h ezconf` or in the repository at [doc/api.md](doc/api.md)

## ⭐ Credits

This plugin is a direct implementation of [AstroNvim](https://github.com/AstroNvim/astrocore) core configuration engine.

<div align="center" id="madewithlua">

[![Lua](https://img.shields.io/badge/Made%20with%20Lua-blue.svg?style=for-the-badge&logo=lua)](https://lua.org)

</div>
