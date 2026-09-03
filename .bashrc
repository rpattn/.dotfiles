# ~/.bashrc
# Executed by Bash for interactive non-login shells.

# Stop here for non-interactive shells.
case $- in
    *i*) ;;
      *) return ;;
esac

# Prevent accidental overwriting with >.
# Use >| when an overwrite is intentional.
set -o noclobber

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------

HISTFILE="$HOME/.bash_history"
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups

shopt -s histappend
shopt -s checkwinsize

# Write new commands after each prompt.
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# ---------------------------------------------------------------------------
# PATH
# ---------------------------------------------------------------------------

path_prepend() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

[[ -d "$HOME/.local/bin" ]] && path_prepend "$HOME/.local/bin"
[[ -d "$HOME/go/bin" ]] && path_prepend "$HOME/go/bin"
[[ -d "$HOME/.cargo/bin" ]] && path_prepend "$HOME/.cargo/bin"

export PATH

unset -f path_prepend

export KUBECONFIG="$HOME/.kube/config"

# Rust environment.
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Personal environment variables and secrets.
# Do not commit ~/.env.local.
[[ -f "$HOME/.env.local" ]] && source "$HOME/.env.local"

# ---------------------------------------------------------------------------
# Colours and aliases
# ---------------------------------------------------------------------------

if command -v dircolors >/dev/null 2>&1; then
    if [[ -r "$HOME/.dircolors" ]]; then
        eval "$(dircolors -b "$HOME/.dircolors")"
    else
        eval "$(dircolors -b)"
    fi
fi

alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias c='clear'

# Debian uses different executable names for these packages.
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'
command -v batcat >/dev/null 2>&1 && alias bat='batcat'

# Bare Git repository used to manage dotfiles.
alias dotfiles='git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'

# Additional aliases that should not live in this file.
[[ -f "$HOME/.bash_aliases" ]] && source "$HOME/.bash_aliases"

# ---------------------------------------------------------------------------
# Bash completion
# ---------------------------------------------------------------------------

if ! shopt -oq posix; then
    if [[ -r /usr/share/bash-completion/bash_completion ]]; then
        source /usr/share/bash-completion/bash_completion
    elif [[ -r /etc/bash_completion ]]; then
        source /etc/bash_completion
    fi
fi

# ---------------------------------------------------------------------------
# SSH agent
# ---------------------------------------------------------------------------

# Reuse one SSH agent across WSL terminal sessions.
if command -v keychain >/dev/null 2>&1 &&
   [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    eval "$(keychain --eval --quiet id_ed25519)"
fi

# ---------------------------------------------------------------------------
# Node.js
# ---------------------------------------------------------------------------

export NVM_DIR="$HOME/.nvm"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
fi

if [[ -s "$NVM_DIR/bash_completion" ]]; then
    source "$NVM_DIR/bash_completion"
fi

# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------

# Use Starship when installed; otherwise use a simple coloured prompt.
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
elif [[ "$TERM" == *-256color || "$TERM" == xterm-color ]]; then
    PS1='\[\e[01;32m\]\u@\h\[\e[00m\]:\[\e[01;34m\]\w\[\e[00m\]\$ '
else
    PS1='\u@\h:\w\$ '
fi
