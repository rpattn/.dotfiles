# ~/.zshrc

[[ -o interactive ]] || return

setopt NO_CLOBBER

# history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=20000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS

# terminal colours
export TERM=xterm-256color
export COLORTERM=truecolor

if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
fi

alias ls='ls --color=auto'

bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# path
export PATH="$HOME/.local/bin:$PATH"

# aliases
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lah'
alias la='ls -A'
alias grep='grep --color=auto'
alias brave='flatpak run com.brave.Browser &'
alias c='clear'

alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases

# completion
autoload -Uz compinit
compinit

# starship
eval "$(starship init zsh)"

# nvm lazy load
export NVM_DIR="$HOME/.nvm"

[ -f ~/.env.local ] && source ~/.env.local

nvm() {
  unset -f nvm node npm npx
  [[ -s /usr/share/nvm/init-nvm.sh ]] && source /usr/share/nvm/init-nvm.sh
  nvm "$@"
}

node() { nvm >/dev/null; command node "$@"; }
npm()  { nvm >/dev/null; command npm "$@"; }
npx()  { nvm >/dev/null; command npx "$@"; }
