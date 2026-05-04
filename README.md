# Dotfiles

Personal dotfiles managed with a bare Git repository.

## Overview

This setup tracks configuration files directly from `$HOME` using a bare repo:

* Repo: `~/.dotfiles`
* Work tree: `$HOME`
* Alias: `dotfiles`

This avoids symlinks and keeps everything in place.

---

## Setup

### 1. Clone

```bash
git clone --bare git@github.com:rpattn/.dotfiles.git $HOME/.dotfiles
```

### 2. Alias

```bash
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

Add to `.zshrc` or `.bashrc` to persist.

### 3. Checkout

```bash
dotfiles checkout
```

If files would be overwritten:

```bash
mkdir -p ~/.dotfiles-backup
dotfiles checkout 2>&1 | grep "\s\+\." | awk '{print $1}' | xargs -I{} mv {} ~/.dotfiles-backup/{}
dotfiles checkout
```

### 4. Hide untracked files

```bash
dotfiles config --local status.showUntrackedFiles no
```

---

## Usage

### Add files

```bash
dotfiles add ~/.zshrc
dotfiles commit -m "zsh: update config"
dotfiles push
```

### Check status

```bash
dotfiles status
```

---

## Interactive helper

Use the helper script:

```bash
dotfiles-add
```

Features:

* fuzzy-select files with fzf
* previews diffs
* auto-suggests commit messages
* skips sensitive files

---

## What gets tracked

Only config-style files:

* top-level dotfiles (`.zshrc`, `.gitconfig`, etc.)
* `.config/*`
* optionally `.local/bin`

Everything else is filtered out.

---

## Ignored files

Global ignore file:

```
~/.dotfiles-ignore
```

Configured via:

```bash
dotfiles config --local core.excludesfile ~/.dotfiles-ignore
```

Covers:

* secrets (`.ssh`, `.gnupg`, `.env`)
* caches (`.cache`, `.local/share`)
* package managers (`.npm`, `.cargo`)
* large/system dirs (`Downloads`, `Projects`)

---

## Safety

The setup avoids committing sensitive data by:

* using a global ignore file
* filtering in the helper script
* blocking known sensitive paths at runtime

Never commit:

* `.ssh/`
* `.gnupg/`
* `.aws/`
* `.env*`
* browser profiles

---

## Structure

This repo mirrors `$HOME`:

```
.zshrc
.gitconfig
.config/
  nvim/
  kitty/
```

---

## Notes

* This is a personal setup; no attempt at cross-machine abstraction
* Machine-specific config should go in `*.local` files and not be tracked
* History files (`.zsh_history`, `.bash_history`) are ignored

---

## Bootstrap (quick setup)

```bash
git clone --bare git@github.com:rpattn/.dotfiles.git $HOME/.dotfiles
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfiles checkout
dotfiles config --local status.showUntrackedFiles no
```

---

## Requirements

* git
* optional: fzf (for interactive selection)

