# ~/.bashrc

[[ $- != *i* ]] && return

set -o noclobber

# history
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# ───── Colours (IMPORTANT FIX) ─────
export TERM=xterm-256color
export COLORTERM=truecolor

eval "$(dircolors -b)"
alias ls='ls --color=auto'

eval "$(starship init bash)"

# ───── PATH ─────
export PATH="$HOME/.local/bin:$PATH"

# ───── aliases ─────
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases

# ───── bash completion ─────
[[ -r /usr/share/bash-completion/bash_completion ]] && \
    source /usr/share/bash-completion/bash_completion

# ───── NVM lazy load ─────
export NVM_DIR="$HOME/.nvm"
nvm() {
    unset -f nvm node npm npx
    [ -s "/usr/share/nvm/init-nvm.sh" ] && source /usr/share/nvm/init-nvm.sh
    nvm "$@"
}

node() { nvm >/dev/null; node "$@"; }
npm()  { nvm >/dev/null; npm "$@"; }
npx()  { nvm >/dev/null; npx "$@"; }
