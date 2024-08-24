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

The project includes a variety of plugins, each with its own purpose.
All plugins are located in the [`lua/plugins/`](lua/plugins/) directory.

## Installation

### MacOS

1. Install Neovim using Homebrew:

```bash
brew install neovim
```

for images to work properly, install the following:

1. Install `kitty` terminal

````bash
brew install imagemagick
brew install luarocks
luarocks --local --lua-version=5.1 install magick
```
If you use Tmux, ~/Tmux.conf should have set -gq allow-passthrough on

2. Clone this repository into your Neovim configuration directory:

```bash
git clone https://github.com/CoMfUcIoS/neovim.git ~/.config/nvim
````

### Tmux navigation

for tmux - nvim navigation to work properly, you need to add the following to your `~/.tmux.conf` file:

```bash
# in your tpm plugins
set -g @plugin 'christoomey/vim-tmux-navigator'

# in your key bindings

# decide whether we're in a Vim process
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"

bind-key -n 'M-Left' if-shell "$is_vim" 'send-keys M-Left' 'select-pane -L'
bind-key -n 'M-Down' if-shell "$is_vim" 'send-keys M-Down' 'select-pane -D'
bind-key -n 'M-Up' if-shell "$is_vim" 'send-keys M-Up' 'select-pane -U'
bind-key -n 'M-Right' if-shell "$is_vim" 'send-keys M-Right' 'select-pane -R'

tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'

if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
    "bind-key -n 'M-\\' if-shell \"$is_vim\" 'send-keys M-\\'  'select-pane -l'"
if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
    "bind-key -n 'M-\\' if-shell \"$is_vim\" 'send-keys M-\\\\'  'select-pane -l'"

bind-key -n 'M-Space' if-shell "$is_vim" 'send-keys M-Space' 'select-pane -t:.+'

bind-key -T copy-mode-vi 'M-Left' select-pane -L
bind-key -T copy-mode-vi 'M-Down' select-pane -D
bind-key -T copy-mode-vi 'M-Up' select-pane -U
bind-key -T copy-mode-vi 'M-Right' select-pane -R
bind-key -T copy-mode-vi 'M-\' select-pane -l
bind-key -T copy-mode-vi 'M-Space' select-pane -t:.+

```

Now you can use your Alt/Options key to navigate between tmux panes and nvim splits

### Linux

1. Install Neovim using your package manager. For Ubuntu, you can use:

```bash
sudo apt install neovim
```

2. Clone this repository into your Neovim configuration directory:

```bash
git clone https://github.com/CoMfUcIoS/neovim.git ~/.config/nvim
```
