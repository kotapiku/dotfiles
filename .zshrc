# Character encoding
export LANG=ja_JP.UTF-8

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000    #メモリ上に保存される件数
SAVEHIST=100000    #ファイルに保存される件数
setopt hist_ignore_dups    #重複した履歴を保存しない
setopt hist_ignore_space    #半角スペースを入れたコマンドは履歴に残さない
setopt hist_ignore_all_dups    # 同じコマンドをヒストリに残さない
setopt hist_reduce_blanks    # ヒストリに保存するときに余分なスペースを削除する

# Color
autoload -Uz colors
colors

# Completion
zstyle ':completion:*' menu select
zstyle ":completion:*:default" list-colors ${(s.:.)LS_COLORS} "ma=48;5;242;1" # highlight selected item
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'    # 補完で小文字でも大文字にマッチさせる
setopt globdots # for hidden files
setopt glob_complete # tab押したら候補が並ぶ
setopt auto_param_slash                       # 末尾に自動的に / を追加

# Options
setopt no_beep    # beep を無効にする
setopt no_flow_control    # フローコントロールを無効にする
setopt ignore_eof    # Ctrl+Dでzshを終了しない
setopt auto_pushd    # cd したら自動的にpushdする
setopt pushd_ignore_dups    # 重複したディレクトリを追加しない
setopt extended_glob    # 高機能なワイルドカード展開を使用する
setopt auto_cd    #ディレクトリ名だけでcdする

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
  print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
  command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
  command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light-mode for \
  zinit-zsh/z-a-as-monitor \
  zinit-zsh/z-a-patch-dl \
  zinit-zsh/z-a-bin-gem-node

zinit light zsh-users/zsh-completions
zinit light zdharma/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light wfxr/forgit # git + fzf

autoload -U compinit
compinit


# Alias
alias cdd="cd .."
alias cp='cp -i'    # コピー先に同名のファイルが存在したとき確認
alias mv='mv -i'    # 上書き前に確認
alias mkdir='mkdir -p'
alias sudo='sudo '    # sudo の後のコマンドでエイリアスを有効にする
alias cat='bat'
alias diff='icdiff'

# amane
export HOMEBREW_NO_AUTO_UPDATE=1
if [[ $(command -v exa) ]]; then
  alias ls='exa --icons --git'
  alias ll='exa --icons --git -l'
  alias la='exa --icons --git -a'
  alias lt='exa -T -L 2 -a -I "node_modules|.git|.cache|.venv|__pycache__|.pytest_cache" --icons --group-directories-first'
  alias ltl='exa -T -L 2 -a -I "node_modules|.git|.cache|.venv|__pycache__|.pytest_cache" -l --icons --group-directories-first --time-style long-iso'
fi

alias noti='terminal-notifier -message "finish！"'
function mkcd () { mkdir -p $1 && cd $1 }
function fcp () { cat $1 | pbcopy } # file copy

alias gst='git status'
alias gaa='git add -A'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log -p -2'

alias g='{ tmp=$(ghq list -p | fzf); if [ "$tmp" = "" ]; then return 1; else cd $tmp; fi }'

alias ctags="`brew --prefix`/bin/ctags"

function wlog () { python3 ~/dev/weeklog.py $1 > ~/dev/log.txt && open ~/dev/log.txt }

function mktar () { tar cvzf $1.tar.gz $1 }

function extract() {
  case $1 in
    *.tar.gz|*.tgz) tar xzvf $1;;
    *.tar.xz) tar Jxvf $1;;
    *.zip) unar $1;;
    *.lzh) lha e $1;;
    *.tar.bz2|*.tbz) tar xjvf $1;;
    *.tar.Z) tar zxvf $1;;
    *.gz) gzip -d $1;;
    *.bz2) bzip2 -dc $1;;
    *.Z) uncompress $1;;
    *.tar) tar xvf $1;;
    *.arj) unarj $1;;
  esac
}

alias ocaml="rlwrap ocaml"  # ocamlでカーソル有効
alias vi='NVIM_LISTEN_ADDRESS=/tmp/nvimsocket nvim' # for synctex

alias zshrc='nvim ~/.zshrc'
alias zshenv='nvim ~/.zshenv'
alias vimrc='nvim ~/.vimrc'
alias tmuxconf='nvim ~/.tmux.conf'
alias deintoml='nvim ~/dotfiles/.config/nvim/dein/toml/dein.toml'
alias deintoml_lazy='nvim ~/dotfiles/.config/nvim/dein/toml/dein_lazy.toml'
alias relogin='exec $SHELL -l' # reboot

# for yugen
alias ip-add-yugen='curl ifconfig.me | xargs -I {} curl http://49.212.25.77/cgi-bin/ssh.cgi --data network={}'

# vi mode
bindkey -v
bindkey -M viins 'jk' vi-cmd-mode   # jkでvi-modeへ
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=30'
bindkey '^N' expand-or-complete
bindkey '^P' reverse-menu-complete

# pathの追加・削除のための関数
path_append ()  { path_remove $1; export PATH="$PATH:$1"; }
path_prepend () { path_remove $1; export PATH="$1:$PATH"; }
path_remove ()  { export PATH=`echo -n $PATH | awk -v RS=: -v ORS=: '$0 != "'$1'"' | sed 's/:$//'`; }

# for pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/shims:$PATH"
eval "$(pyenv init -)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh  # for fzf
eval "$(zoxide init zsh)" # for zoxide
eval "$(starship init zsh)"

# opam configuration
[[ ! -r /Users/kotapiku/.opam/opam-init/init.zsh ]] || source /Users/kotapiku/.opam/opam-init/init.zsh  > /dev/null 2> /dev/null
# for asdf (node)
. /opt/homebrew/opt/asdf/libexec/asdf.sh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/kotapiku/.pyenv/versions/miniforge3-4.10.3-10/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/kotapiku/.pyenv/versions/miniforge3-4.10.3-10/etc/profile.d/conda.sh" ]; then
        . "/Users/kotapiku/.pyenv/versions/miniforge3-4.10.3-10/etc/profile.d/conda.sh"
    else
        export PATH="/Users/kotapiku/.pyenv/versions/miniforge3-4.10.3-10/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

