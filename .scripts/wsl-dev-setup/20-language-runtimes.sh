#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal WSL user, not as root." >&2
  exit 1
fi

# Go from Debian's repositories.
sudo apt update
sudo apt install -y golang-go

# Rust via rustup.
if [[ ! -x "$HOME/.cargo/bin/rustup" ]]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
# shellcheck disable=SC1091
source "$HOME/.cargo/env"
rustup component add rustfmt clippy

# Python tooling via uv.
if [[ ! -x "$HOME/.local/bin/uv" ]]; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Node.js via nvm. Clone nvm and select its newest tagged release.
export NVM_DIR="$HOME/.nvm"
if [[ ! -d "$NVM_DIR/.git" ]]; then
  git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
else
  git -C "$NVM_DIR" fetch --tags --prune
fi

LATEST_NVM_TAG="$(git -C "$NVM_DIR" tag --sort=-v:refname | head -n 1)"
if [[ -n "$LATEST_NVM_TAG" ]]; then
  git -C "$NVM_DIR" checkout --quiet "$LATEST_NVM_TAG"
fi

# shellcheck disable=SC1091
source "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'

if command -v corepack >/dev/null 2>&1; then
  corepack enable
fi

BASHRC="$HOME/.bashrc"
START_MARKER="# >>> wsl-dev runtimes >>>"

if ! grep -Fq "$START_MARKER" "$BASHRC"; then
  cat >> "$BASHRC" <<'EOT'

# >>> wsl-dev runtimes >>>
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
[[ -s "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
# <<< wsl-dev runtimes <<<
EOT
fi

mkdir -p "$HOME/go/bin"

echo
echo "Language runtimes installed. Open a new shell or run: source ~/.bashrc"
