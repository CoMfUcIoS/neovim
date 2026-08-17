#!/usr/bin/env bash
# Provision a Debian/Ubuntu box for the remote half of this Neovim config.
#
#   ssh <host> 'bash -s' < scripts/remote-bootstrap.sh
#
# Idempotent — safe to re-run. Installs only what the remote profile needs
# (see `remote_disabled` in init.lua); no Rust, no yarn, no ImageMagick, because
# the plugins wanting those are switched off remotely.
#
# Deliberately not Ansible/Puppet: this is one apt line and a Go tarball for a
# handful of hosts. Revisit if you're managing enough boxes that drift matters.
set -euo pipefail

GO_VERSION="1.25.0"
log() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

if ! have apt-get; then
	echo "This script targets Debian/Ubuntu (needs apt-get)." >&2
	exit 1
fi

log "Installing apt packages"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
	build-essential \
	ca-certificates \
	curl \
	default-jdk \
	fd-find \
	fzf \
	git \
	nodejs \
	npm \
	php-cli \
	php-mbstring \
	php-xml \
	python3 \
	python3-pip \
	python3-venv \
	ripgrep \
	tar \
	unzip
# build-essential : treesitter parsers, telescope-fzf-native, LuaSnip jsregexp
# nodejs + npm    : intelephense, ts_ls, eslint, jsonls, dockerls, prettierd,
#                   mcphub's bundled build, and vscode-js-debug's npm compile
# default-jdk     : jdtls needs a JDK 17+, and google-java-format is a jar
# python3 + venv  : mason's jdtls launcher is literally `python:bin/jdtls`, and
#                   debugpy/ruff/mypy/pylint install into a mason-managed venv
# php-cli + ext   : php-cs-fixer / phpcs / phpstan are PHP programs themselves;
#                   mbstring and xml are what php-cs-fixer and phpstan need
# ripgrep + fzf   : snacks/fzf-lua pickers and live grep
# git             : plugin clones, fugitive/octo, codecompanion's `git apply` patch

# Debian ships fd as `fdfind`; every plugin looks for `fd`.
if have fdfind && ! have fd; then
	log "Linking fdfind -> fd"
	sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

# Mason installs the Go tools (gopls, delve, gofumpt, gotests, ...) with
# `go install`, so a Go toolchain has to exist first. Ubuntu's `golang` package
# lags far enough behind to break gopls, hence the tarball.
if have go; then
	log "Go already present: $(go version)"
else
	log "Installing Go ${GO_VERSION}"
	case "$(uname -m)" in
		x86_64) go_arch=amd64 ;;
		aarch64 | arm64) go_arch=arm64 ;;
		*) echo "Unsupported arch: $(uname -m)" >&2; exit 1 ;;
	esac
	tmp="$(mktemp -d)"
	curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${go_arch}.tar.gz" -o "$tmp/go.tar.gz"
	sudo rm -rf /usr/local/go
	sudo tar -C /usr/local -xzf "$tmp/go.tar.gz"
	rm -rf "$tmp"
fi

# Both the Go toolchain and Mason's bin dir need to be on a LOGIN shell's PATH:
# remote-nvim starts the server through a login shell, and dap-remote.lua runs
# `bash -lc 'dlv ...'`.
profile="$HOME/.profile"
add_path() {
	grep -qF "$1" "$profile" 2>/dev/null || {
		log "Adding to $profile: $1"
		printf '\n%s\n' "$1" >>"$profile"
	}
}
add_path 'export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"'
add_path 'export PATH="$PATH:$HOME/.local/share/nvim/mason/bin"'

# Optional: octo needs the gh CLI, and it must be authenticated separately
# with `gh auth login`. Non-fatal — octo is the only thing that wants it.
if ! have gh; then
	log "Installing GitHub CLI (for octo.nvim)"
	if curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
		sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null 2>&1; then
		sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
			sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
		sudo apt-get update -qq && sudo apt-get install -y gh || log "gh install failed — octo will not work until 'gh' is installed"
	else
		log "Could not fetch gh keyring — skipping (octo will not work)"
	fi
fi

log "Done. Verifying:"
for b in gcc git curl rg fd fzf node npm php python3 java javac; do
	printf '  %-8s %s\n' "$b" "$(command -v "$b" || echo MISSING)"
done
printf '  %-8s %s\n' "go" "$( (PATH="$PATH:/usr/local/go/bin" command -v go) || echo MISSING)"
printf '  %-8s %s\n' "gh" "$(command -v gh || echo 'missing (octo only)')"
have java && java -version 2>&1 | head -1 | sed 's/^/  java:   /'

cat <<'EOF'

Next:
  1. From the laptop: <leader>Hs, pick this host, choose a 0.12.x Neovim.
  2. First launch runs :Lazy sync + Mason installs — give it a few minutes.
  3. For octo: run `gh auth login` on this host.
  4. Log out and back in (or `source ~/.profile`) if `go` is not on PATH yet.
EOF
