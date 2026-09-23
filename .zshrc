# Character encoding
export LANG=ja_JP.UTF-8

# Homebrew
export HOMEBREW_DEVELOPER=1

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=100000
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_reduce_blanks

# Basic options
setopt no_beep
setopt no_flow_control
setopt ignore_eof
setopt auto_pushd
setopt pushd_ignore_dups
setopt extended_glob
setopt auto_cd
setopt globdots
setopt glob_complete
setopt auto_param_slash

# Colors
autoload -Uz colors && colors

# PATH helpers
typeset -U path PATH

path_append() {
  path=($path "$1")
}

path_prepend() {
  path=("$1" $path)
}

path_remove() {
  path=(${path:#"$1"})
}

# zinit
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME/.git" ]]; then
  mkdir -p "${ZINIT_HOME:h}"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

zinit light zsh-users/zsh-completions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light wfxr/forgit

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Completion
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
[[ -n "${LS_COLORS:-}" ]] && zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS} "ma=48;5;242;1"

# Runtime manager: mise
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# fzf
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# zoxide / starship
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[starship] )) && eval "$(starship init zsh)"

# opam
[[ -r "$HOME/.opam/opam-init/init.zsh" ]] && source "$HOME/.opam/opam-init/init.zsh" >/dev/null 2>/dev/null

# Aliases
alias cdd='cd ..'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
alias sudo='sudo '

if (( $+commands[eza] )); then
  alias ls='eza --icons --git'
  alias la='eza -a --icons --git'
  alias ll='eza -l --icons --git'
  alias lt='eza -T -L 2 -a -I "node_modules|.git|.cache|.venv|__pycache__|.pytest_cache" --icons --group-directories-first'
  alias ltl='eza -T -L 2 -a -I "node_modules|.git|.cache|.venv|__pycache__|.pytest_cache" -l --icons --group-directories-first --time-style long-iso'
fi

alias noti='terminal-notifier -message "finish!"'

alias gst='git status'
alias gaa='git add -A'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log -p -2'

alias ocaml='rlwrap ocaml'
alias vi='nvim'
# Open Markdown files in Warp.
alias md='open -a Warp'

alias zshrc='nvim ~/.zshrc'
alias zshenv='nvim ~/.zshenv'
alias vimrc='nvim ~/.vimrc'
alias tmuxconf='nvim ~/.tmux.conf'
alias deintoml='nvim "$XDG_CONFIG_HOME/nvim/dein/toml/dein.toml"'
alias deintoml_lazy='nvim "$XDG_CONFIG_HOME/nvim/dein/toml/dein_lazy.toml"'
alias relogin='exec "$SHELL" -l'

# for yugen
alias ip-add-yugen='curl -fsSL ifconfig.me | xargs -I {} curl -fsSL http://49.212.25.77/cgi-bin/ssh.cgi --data network={}'

# Functions
mkcd() {
  [[ -n "$1" ]] || return 1
  mkdir -p -- "$1" && cd -- "$1"
}

fcp() {
  [[ -f "$1" ]] || return 1
  pbcopy < "$1"
}

g() {
  (( $+commands[ghq] )) || return 1
  (( $+commands[fzf] )) || return 1

  local tmp
  tmp=$(ghq list -p | fzf) || return 1
  [[ -n "$tmp" ]] && cd -- "$tmp"
}

mktar() {
  [[ -n "$1" ]] || return 1
  tar cvzf "$1.tar.gz" -- "$1"
}

extract() {
  [[ -f "$1" ]] || {
    echo "extract: file not found: $1" >&2
    return 1
  }

  case "$1" in
    *.tar.gz|*.tgz)   tar xzvf "$1" ;;
    *.tar.xz)         tar Jxvf "$1" ;;
    *.zip)            unar "$1" ;;
    *.lzh)            lha e "$1" ;;
    *.tar.bz2|*.tbz)  tar xjvf "$1" ;;
    *.tar.Z)          tar zxvf "$1" ;;
    *.gz)             gzip -d "$1" ;;
    *.bz2)            bzip2 -d "$1" ;;
    *.Z)              uncompress "$1" ;;
    *.tar)            tar xvf "$1" ;;
    *.arj)            unarj "$1" ;;
    *)
      echo "extract: unsupported file type: $1" >&2
      return 1
      ;;
  esac
}

# Key bindings
bindkey -v
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
bindkey '^N' expand-or-complete
bindkey '^P' reverse-menu-complete

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=30'
