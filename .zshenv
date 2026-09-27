# XDG
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# Editor
export EDITOR="nvim"

# Homebrew (preserve an existing prefix, otherwise detect the installation).
if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
  elif [[ -x /usr/local/bin/brew ]]; then
    export HOMEBREW_PREFIX="/usr/local"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
  fi
fi

# PATH (zsh配列で管理 + 重複削除)
typeset -U path PATH

path=(
  "$HOME/go/bin"              # golang
  "$HOME/dev/git-fuzzy/bin"
  "$HOME/.poetry/bin"
  $path
)
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
fi

# pager
export PAGER=less
export LESS='-R'
