#!/usr/bin/env bash
set -u

check() {
  local label="$1"
  shift
  printf '%-14s' "$label"
  if command -v "$1" >/dev/null 2>&1; then
    "$@" 2>&1 | head -n 1
  else
    echo "not found"
  fi
}

check "Git" git --version
check "GitHub CLI" gh --version
check "Git LFS" git lfs version
check "GCC" gcc --version
check "Clang" clang --version
check "CMake" cmake --version
check "Python" python3 --version
check "uv" uv --version
check "Go" go version
check "Rust" rustc --version
check "Cargo" cargo --version
check "Node" node --version
check "npm" npm --version
check "Docker" docker --version
check "VS Code" code --version

echo
echo "Git identity:"
git config --global user.name 2>/dev/null || echo "name not set"
git config --global user.email 2>/dev/null || echo "email not set"

echo
echo "Repository directory: $HOME/src"
echo "Docker requires Docker Desktop WSL integration to be enabled for Debian."
