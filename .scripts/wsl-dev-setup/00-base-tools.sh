#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal WSL user, not as root." >&2
  exit 1
fi

sudo apt update
sudo apt install -y \
  git git-lfs gh openssh-client keychain \
  build-essential gcc g++ make cmake ninja-build pkg-config \
  clang gdb \
  curl wget ca-certificates gnupg \
  unzip zip xz-utils rsync \
  jq ripgrep fd-find bat shellcheck \
  python3 python3-venv python3-pip pipx \
  sqlite3 postgresql-client \
  htop tree lsof dnsutils netcat-openbsd

git lfs install

BASHRC="$HOME/.bashrc"
START_MARKER="# >>> wsl-dev aliases >>>"
END_MARKER="# <<< wsl-dev aliases <<<"

if ! grep -Fq "$START_MARKER" "$BASHRC"; then
  cat >> "$BASHRC" <<'EOT'

# >>> wsl-dev aliases >>>
alias fd='fdfind'
alias bat='batcat'
# Start or reuse an SSH agent and load the default key when present.
if command -v keychain >/dev/null 2>&1 && [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  eval "$(keychain --eval --quiet id_ed25519)"
fi
# <<< wsl-dev aliases <<<
EOT
fi

mkdir -p "$HOME/dev"

echo
echo "Base tools installed. Open a new shell or run: source ~/.bashrc"
echo "Keep repositories under: $HOME/dev"

