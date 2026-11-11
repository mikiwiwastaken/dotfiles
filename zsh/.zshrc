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

# Alias
alias ls='eza --icons auto'
alias cat='bat'
alias y="yazi"
alias ncmpcpp="$HOME/.local/bin/ncmpcpp-mocha"

export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4"
