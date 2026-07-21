#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal WSL user, not as root." >&2
  exit 1
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot identify this Linux distribution." >&2
  exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release
if [[ "${ID:-}" != "debian" ]]; then
  echo "This script is intended for Debian. Detected: ${PRETTY_NAME:-unknown}" >&2
  exit 1
fi

is_wsl=false
if grep -qiE '(microsoft|wsl)' /proc/sys/kernel/osrelease 2>/dev/null; then
  is_wsl=true
fi

configure_wsl_systemd() {
  echo "Docker Engine needs a service manager. Enabling systemd for this WSL distribution..."
  sudo apt-get update
  sudo apt-get install -y systemd systemd-sysv python3

  sudo python3 <<'PY'
from pathlib import Path

path = Path('/etc/wsl.conf')
text = path.read_text() if path.exists() else ''
lines = text.splitlines()

boot_start = None
boot_end = len(lines)
for index, line in enumerate(lines):
    stripped = line.strip()
    if stripped.lower() == '[boot]':
        boot_start = index
        continue
    if boot_start is not None and index > boot_start and stripped.startswith('[') and stripped.endswith(']'):
        boot_end = index
        break

if boot_start is None:
    if lines and lines[-1].strip():
        lines.append('')
    lines.extend(['[boot]', 'systemd=true'])
else:
    found = False
    for index in range(boot_start + 1, boot_end):
        stripped = lines[index].strip()
        if stripped.lower().startswith('systemd='):
            lines[index] = 'systemd=true'
            found = True
            break
    if not found:
        lines.insert(boot_start + 1, 'systemd=true')

path.write_text('\n'.join(lines).rstrip() + '\n')
PY

  cat <<'MSG'

Systemd has been configured, but WSL must restart before Docker can be installed.

Run this in Windows PowerShell:

  wsl --shutdown

Then reopen Debian and rerun:

  ./40-docker-engine.sh
MSG
}

if [[ "$(ps -p 1 -o comm= | tr -d '[:space:]')" != "systemd" ]]; then
  if [[ "$is_wsl" == true ]]; then
    configure_wsl_systemd
    exit 2
  fi

  echo "systemd is not running, so the Docker service cannot be managed." >&2
  exit 1
fi

echo "Removing conflicting Docker/container packages when present..."
conflicting_packages=(
  docker.io
  docker-compose
  docker-doc
  podman-docker
  containerd
  runc
)
installed_conflicts=()
for package in "${conflicting_packages[@]}"; do
  if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii'; then
    installed_conflicts+=("$package")
  fi
done

if ((${#installed_conflicts[@]})); then
  sudo apt-get remove -y "${installed_conflicts[@]}"
fi

echo "Adding Docker's official Debian repository..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

architecture="$(dpkg --print-architecture)"
codename="${VERSION_CODENAME:-}"
if [[ -z "$codename" ]]; then
  echo "Debian VERSION_CODENAME is missing from /etc/os-release." >&2
  exit 1
fi

sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF_SOURCES
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $codename
Components: stable
Architectures: $architecture
Signed-By: /etc/apt/keyrings/docker.asc
EOF_SOURCES

sudo apt-get update
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

sudo systemctl enable --now docker

# Membership in the docker group gives root-equivalent control of the daemon.
sudo groupadd --force docker
sudo usermod -aG docker "$USER"

echo
echo "Verifying the daemon with sudo..."
sudo docker run --rm hello-world

cat <<MSG

Docker Engine and Docker Compose are installed.

Apply your new docker-group membership with either:

  newgrp docker

or close and reopen Debian. Then verify:

  docker version
  docker compose version
  docker run --rm hello-world

Do not also enable Docker Desktop's WSL integration for Debian unless you
intentionally want two separate Docker engines/contexts.
MSG
