export EDITOR="nvim"
export VISUAL="nvim"

export PATH="$PATH:$(go env GOPATH)/bin"

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

# Completion (case-insensitive, menu selection)
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Emacs-style keys, plus Home/End/Delete
bindkey -e
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[[3~' delete-char

# Plugins (installed via pacman)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# This adds a newline before every command, except the very first one
precmd() {
  precmd() {
    echo ""
  }
}

# Fixes 'clear' command from leaving an unwanted blank line at the top
alias clear="precmd() { precmd() { echo \"\" } } && clear"

# Prompt
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias ls="eza --icons auto --group-directories-first"
alias ll="eza -la --icons auto --group-directories-first --git"
alias la="eza -a --icons auto --group-directories-first"
alias lh="eza -l --icons auto --group-directories-first"
alias ld="eza -D --icons auto"
alias lt="eza -l -s modified --icons auto"
alias lk="eza -l -s size --icons auto"
alias tree="eza --tree --icons auto"

alias g='git'
alias gs='git status -s'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gca='git commit --amend --no-edit'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'
alias gd='git diff'
alias glg='git log --oneline --graph --decorate --all'

alias cat="bat"
alias ncmpcpp="$HOME/.local/bin/ncmpcpp-mocha"

# shell wrapper
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}

# fzf theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"

# rg theme
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

# vivid
export LS_COLORS="$(vivid generate catppuccin-mocha)"
