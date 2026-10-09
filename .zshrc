[[ -o interactive ]] || return

# Character encoding
export LANG=ja_JP.UTF-8

# History
HISTFILE=~/.zsh_history
HISTSIZE=200000
SAVEHIST=100000
setopt extended_history
# Save after each command, keeping navigation local to this shell.
unsetopt share_history inc_append_history
setopt inc_append_history_time
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups
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

# Select the keymap before fzf and other plugins install their bindings.
bindkey -v
KEYTIMEOUT=20

# zinit: installation is explicit so opening a shell never clones repositories.
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
typeset -ga _dotfiles_zsh_plugins=(
  zsh-users/zsh-completions
  wfxr/forgit
  zsh-users/zsh-autosuggestions
  zdharma-continuum/fast-syntax-highlighting
  zsh-users/zsh-history-substring-search
)

zsh-plugins-install() (
  # Keep plugin initialization and widget changes in a separate shell scope.
  emulate -L zsh
  (( $+commands[git] )) || { print -u2 'zsh-plugins-install: git is required'; return 1; }
  if [[ ! -r "$ZINIT_HOME/zinit.zsh" ]]; then
    command mkdir -p -- "${ZINIT_HOME:h}" || return
    command git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" || return
  fi
  source "$ZINIT_HOME/zinit.zsh" || return
  local plugin
  for plugin in "${_dotfiles_zsh_plugins[@]}"; do
    zinit light "$plugin" || return
  done
  print 'Zsh plugins are ready. Run relogin to reload the shell.'
)

# Load the manager only for maintenance; installed plugins can be sourced directly.
if (( ! $+functions[zinit] )); then
  zinit() {
    [[ -r "$ZINIT_HOME/zinit.zsh" ]] || {
      print -u2 'zsh: run zsh-plugins-install first.'
      return 1
    }
    source "$ZINIT_HOME/zinit.zsh" || return
    zinit "$@"
  }
fi

typeset -ga _dotfiles_zsh_missing=()
_dotfiles_zsh_load_plugin() {
  local plugin="${ZINIT_HOME:h}/plugins/${1//\//---}/$2"
  if [[ -r "$plugin" ]]; then
    set --
    source "$plugin"
  else
    _dotfiles_zsh_missing+=("$1")
  fi
}

# Add completion providers before initializing the completion system.
typeset -U fpath
if [[ -n "${HOMEBREW_PREFIX:-}" && -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
fi
[[ -d "$ZINIT_HOME" ]] && fpath=("$ZINIT_HOME" $fpath)
_dotfiles_zsh_load_plugin zsh-users/zsh-completions zsh-completions.plugin.zsh

# Keep compinit's normal ownership and permission checks, including on cache hits.
autoload -Uz compinit
zmodload zsh/complist
_dotfiles_zsh_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
if [[ -d "$_dotfiles_zsh_cache" ]] || command mkdir -p -- "$_dotfiles_zsh_cache"; then
  compinit -d "$_dotfiles_zsh_cache/zcompdump-${HOST}-${ZSH_VERSION}"
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path "$_dotfiles_zsh_cache/completion"
else
  compinit -D
fi
unset _dotfiles_zsh_cache

if [[ -r "$ZINIT_HOME/_zinit" ]]; then
  autoload -Uz _zinit
  _dotfiles_zinit_complete() {
    # Plugin-name completion needs Zinit's directory metadata too.
    [[ -n ${ZINIT[PLUGINS_DIR]:-} ]] || zinit help >/dev/null || return
    _zinit "$@"
  }
  compdef _dotfiles_zinit_complete zinit
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'
[[ -n "${LS_COLORS:-}" ]] && zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS} "ma=48;5;242;1"

# gd: keep +/- markers and Git's colors in the preview. Difftastic's
# automatic color detection disables colors when forgit pipes its output.
export FORGIT_DIFF_GIT_OPTS='--no-ext-diff'
export FORGIT_DIFF_FZF_OPTS='
--height=90%
--preview-window=down:75%:wrap
--bind="ctrl-d:preview-page-down,ctrl-u:preview-page-up"
--header="Enter: full diff | Ctrl-D/U: scroll | Alt-W: wrap"
'

# Runtime manager: mise
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# fzf: only file/directory pickers should run file previews.
export FZF_DEFAULT_OPTS='--ansi --height=40% --reverse --border --cycle'
if (( $+commands[rg] )); then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
export FZF_CTRL_T_OPTS='--preview-window=right:60% --bind=ctrl-/:toggle-preview'
if (( $+commands[bat] && $+commands[eza] )); then
  FZF_CTRL_T_OPTS+=" --preview 'if [ -d {} ]; then eza --tree --level=2 --all --color=always --icons --group-directories-first -- {}; else bat --color=always --style=header,grid --line-range=:300 -- {}; fi'"
fi
export FZF_ALT_C_OPTS='--walker-skip=.git,node_modules,.cache,.venv --preview-window=right:60% --bind=ctrl-/:toggle-preview'
if (( $+commands[eza] )); then
  FZF_ALT_C_OPTS+=" --preview 'eza --tree --level=2 --all --color=always --icons --group-directories-first -- {}'"
fi
(( $+commands[fzf] )) && source <(fzf --zsh)

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
alias fv='(file=$(fzf) && nvim -- "$file")'

alias md='npx mdts --port auto'

alias zshrc='nvim ~/.zshrc'
alias zshenv='nvim ~/.zshenv'
alias vimrc='nvim "$XDG_CONFIG_HOME/nvim/init.lua"'
alias tmuxconf='nvim ~/.tmux.conf'
alias nvim_plugins='nvim "$XDG_CONFIG_HOME/nvim/lua/plugins"'
alias relogin='exec "$SHELL" -l'

# for yugen
alias ip-add-yugen='curl -fsSL ifconfig.me | xargs -I {} curl -fsSL http://49.212.25.77/cgi-bin/ssh.cgi --data network={}'

# Functions
pdf() {
  local file
  file=$(rg --files --no-ignore -g "*.pdf" | fzf) || return
  # open "$@" -- "$file"
  open -a Dia "$@" -- "$file"
}

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
  tmp=$(ghq list -p | FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" fzf) || return 1
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
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M viins '^N' expand-or-complete
bindkey -M viins '^P' reverse-menu-complete

# Native history search remains available when plugins are not installed.
bindkey -M vicmd 'k' history-beginning-search-backward
bindkey -M vicmd 'j' history-beginning-search-forward

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=30'

# Initialize widgets after completion, fzf and prompt integrations are ready.
# History substring search must follow the syntax highlighter.
_dotfiles_zsh_load_plugin wfxr/forgit forgit.plugin.zsh
_dotfiles_zsh_load_plugin zsh-users/zsh-autosuggestions zsh-autosuggestions.zsh
_dotfiles_zsh_load_plugin zdharma-continuum/fast-syntax-highlighting fast-syntax-highlighting.plugin.zsh
_dotfiles_zsh_load_plugin zsh-users/zsh-history-substring-search zsh-history-substring-search.zsh

if (( $+widgets[history-substring-search-up] )); then
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
fi
if (( ${#_dotfiles_zsh_missing} )); then
  print -u2 "zsh: missing plugins: ${(j:, :)_dotfiles_zsh_missing}; run zsh-plugins-install."
fi
unset _dotfiles_zsh_missing
unfunction _dotfiles_zsh_load_plugin
