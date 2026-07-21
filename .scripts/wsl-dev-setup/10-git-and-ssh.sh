#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal WSL user, not as root." >&2
  exit 1
fi

NAME="${1:-}"
EMAIL="${2:-}"
KEY_PATH="${KEY_PATH:-$HOME/.ssh/id_ed25519}"

if [[ -z "$NAME" ]]; then
  read -r -p "Git name: " NAME
fi

if [[ -z "$EMAIL" ]]; then
  read -r -p "Git email: " EMAIL
fi

if [[ -z "$NAME" || -z "$EMAIL" ]]; then
  echo "Name and email are required." >&2
  exit 1
fi

git config --global user.name "$NAME"
git config --global user.email "$EMAIL"
git config --global init.defaultBranch main
git config --global core.autocrlf input
git config --global fetch.prune true

if command -v code >/dev/null 2>&1; then
  git config --global core.editor "code --wait"
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ ! -f "$KEY_PATH" ]]; then
  echo "Creating SSH key at $KEY_PATH"
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH"
else
  echo "Existing SSH key found at $KEY_PATH; leaving it unchanged."
fi

chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"

SSH_CONFIG="$HOME/.ssh/config"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

if ! grep -q '^Host github.com$' "$SSH_CONFIG"; then
  cat >> "$SSH_CONFIG" <<EOT

Host github.com
  HostName github.com
  User git
  IdentityFile $KEY_PATH
  IdentitiesOnly yes
EOT
fi

if command -v keychain >/dev/null 2>&1; then
  eval "$(keychain --eval --quiet "$(basename "$KEY_PATH")")"
fi

echo
if command -v clip.exe >/dev/null 2>&1; then
  clip.exe < "$KEY_PATH.pub"
  echo "Public key copied to the Windows clipboard."
else
  echo "Public key:"
  cat "$KEY_PATH.pub"
fi

echo
echo "Add it at GitHub -> Settings -> SSH and GPG keys -> New SSH key"
echo "Then test with: ssh -T git@github.com"
echo
echo "Git configuration:"
git config --global --list
