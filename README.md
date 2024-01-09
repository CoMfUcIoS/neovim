# Neovim Configuration Repository

This repository contains a comprehensive Neovim configuration written in Lua. It includes a variety of plugins and settings to enhance your Neovim experience.

## Structure

The repository is structured as follows:

- [`init.lua`](init.lua): This is the main configuration file for the project.
- [`lazy-lock.json`](lazy-lock.json): This file contains settings for the lazy-lock feature.
- [`lua/.luarc.json`](lua/.luarc.json): This file contains Lua-specific settings.
- [`lua/plugins.lua`](lua/plugins.lua): This file manages the plugins used in the project.
- [`lua/vim-options.lua`](lua/vim-options.lua): This file contains various Vim options and settings.

## Plugins

The project includes a variety of plugins, each with its own purpose. All plugins are located in the [`lua/plugins/`](lua/plugins/) directory. Here are some of them:

- `alpha.lua`: This plugin provides a startup screen for Neovim.
- `auto-pairs.lua`: This plugin automatically pairs brackets and quotes.
- `auto-save.lua`: This plugin automatically saves your work at regular intervals.
- `completion.lua`: This plugin provides advanced auto-completion features.
- `dracula.lua`: This plugin provides the Dracula theme for Neovim.
- `firevim.lua`: This plugin provides a browser-based Neovim interface. ([firevim](https://github.com/glacambre/firenvim))
- `fugitive.lua`: This plugin provides Git integration for Neovim.
- `gitsigns.lua`: This plugin shows Git diff signs in the Neovim gutter.
- `lsp-config.lua`: This plugin configures the Language Server Protocol (LSP) for Neovim.
- `lspkind.lua`: This plugin shows icons next to LSP completion items.
- `lualine.lua`: This plugin provides a status line for Neovim.
- `neo-tree.lua`: This plugin provides a file explorer for Neovim.
- `none-ls.lua`: This plugin provides a dummy LSP for Neovim.
- `telescope.lua`: This plugin provides a highly extensible fuzzy finder.
- `treesitter.lua`: This plugin provides better syntax highlighting and code navigation.

## Installation

### MacOS

1. Install Neovim using Homebrew:

```bash
brew install neovim
```

2. Clone this repository into your Neovim configuration directory:

```bash
git clone https://github.com/CoMfUcIoS/neovim.git ~/.config/nvim
```


### Linux

1. Install Neovim using your package manager. For Ubuntu, you can use:

```bash
sudo apt install neovim
```

2. Clone this repository into your Neovim configuration directory:

```bash
git clone https://github.com/CoMfUcIoS/neovim.git ~/.config/nvim
```