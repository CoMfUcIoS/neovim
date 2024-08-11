#!/usr/bin/env sh
source "$HOME/opt/bin/nvm/nvm.sh"
nvm run 16 ~/.local/share/nvim/mason/bin/grammarly-languageserver --stdio
