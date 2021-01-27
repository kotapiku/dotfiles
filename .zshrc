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

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
  zinit-zsh/z-a-as-monitor \
  zinit-zsh/z-a-patch-dl \
  zinit-zsh/z-a-bin-gem-node
### End of Zinit's installer chunk

zinit ice blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions

autoload -U compinit
compinit

zinit light zdharma/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search
zinit light wfxr/forgit # git + fzf

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

# Alias
alias cdd="cd .."
alias ls='ls -G -F' # 色付けして表示, 名前の末尾に記号(種類)を表示
alias la='ls -a'
alias ll='ls -l'
alias cp='cp -i'    # コピー先に同名のファイルが存在したとき確認
alias mv='mv -i'    # 上書き前に確認
alias mkdir='mkdir -p'
alias sudo='sudo '    # sudo の後のコマンドでエイリアスを有効にする
alias cat='bat'

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

function mktar () { tar cvzf $1.tar.gz $1 }

function extract() {
  case $1 in
    *.tar.gz|*.tgz) tar xzvf $1;;
    *.tar.xz) tar Jxvf $1;;
    # *.zip) unzip $1;;
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
alias vi='nvim'

alias -s py=python3
alias -s cpp=g++ -Wall -o

alias zshrc='nvim ~/.zshrc'
alias vimrc='nvim ~/.vimrc'
alias tmuxconf='nvim ~/.tmux.conf'
alias deintoml='nvim ~/dotfiles/.config/nvim/dein/toml/dein.toml'
alias deintoml_lazy='nvim ~/dotfiles/.config/nvim/dein/toml/dein_lazy.toml'

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

# desktop icon
alias killdeskon="defaults write com.apple.finder CreateDesktop false && killall Finder"
alias killdeskoff="defaults delete com.apple.finder CreateDesktop && killall Finder"

# reboot
alias relogin='exec $SHELL -l'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh  # for fzf
unalias zi # to resolve conflict between zinit and zoxide
eval "$(zoxide init zsh)" # for zoxide
eval "$(starship init zsh)" # for starship
