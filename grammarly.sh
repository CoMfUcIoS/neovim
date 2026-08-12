#!/usr/bin/env sh
source "$HOME/.nvm/nvm.sh"
nvm run 16 ~/.local/share/nvim/mason/bin/grammarly-languageserver --stdio
