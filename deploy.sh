#!/bin/bash
set -eu
DOT_DIRECTORY="${HOME}/dotfiles"
OVERWRITE=false

has() {
  type "$1" > /dev/null 2>&1
}

usage() {
  name=`basename $0`
  cat <<EOF
Usage:
  $name [option]

Options:
  -f $(tput setaf 1)** warning **$(tput sgr0) Overwrite dotfiles.
  -h Print help (this message)
EOF
  exit 1
}

while getopts fh OPT
do
  case ${OPT} in
    f) OVERWRITE=true ;;
    h) usage ;;
  esac
done

for f in .??*
do
  [ -n "${OVERWRITE}" -a -e ${HOME}/${f} ] && rm -f ${HOME}/${f}
  if [ ! -e ${HOME}/${f} ]; then
    # ignore files
    [[ ${f} = ".git" ]] && continue
    [[ ${f} = ".gitignore" ]] && continue
    [[ ${f} = ".DS_Store" ]] && continue
    [[ ${f} = ".lvimrc" ]] && continue
    [[ ${f} = ".latexmkrc" ]] && continue
    [[ ${f} = ".latexmkrc_pdflatex" ]] && continue
    [[ ${f} = ".vimrc_vscode" ]] && continue

    ln -snfv ${DOT_DIRECTORY}/${f} ${HOME}/${f}
  fi
done

# for ctags
if [ ! -e ${HOME}/.ctags.d ]; then
  mkdir ${HOME}/.ctags.d
fi
for f in *.ctags
do
  if [ ! -e ${HOME}/.ctags.d/${f} ]; then
    ln -snfv ${DOT_DIRECTORY}/${f} ${HOME}/.ctags.d/${f}
  fi
done

# for brew
if [[ !$(command -v brew)  ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew bundle

# for mac setting
defaults write -g InitialKeyRepeat -int 25 # initial key repeat time
defaults write -g KeyRepeat -int 2 # key repeat time
defaults write -g AppleWindowTabbingMode -string "always" # prefer tab always
defaults write com.apple.dock autohide -bool false # dockを自動で隠さない
defaults write com.apple.AppleMultitouchTrackpad Clicking -int 1 # クリックでタップ
defaults write com.apple.trackpad.scaling scaling -float true # マウスの移動速度を最大に
defaults write com.apple.finder AppleShowAllFiles -bool true # finderで隠しファイル/フォルダを表示
defaults write com.apple.finder ShowPathbar -bool true # パスバーを表示
defaults write com.apple.finder ShowStatusBar -bool true # ステータスバーを表示
defaults write com.apple.NSGlobalDomain AppleShowAllExtensions -bool true # finderで拡張子を表示
defaults write com.apple.menuextra.battery ShowPercent -string "YES" # バッテリの%を表示
defaults write com.apple.screencapture disable-shadow -bool true # スクショの影を消す
defaults write com.apple.Siri StatusMenuVisible -int 0 # メニューバーからsiriを消す
defaults write com.apple.Siri VoiceTriggerUserEnabled -int 0 # disable ask siri
defaults write com.apple.universalaccess mouseDriverCursorSize -float 2.5 # large cursor size

echo "$(tput setaf 2)Dotfiles are deployed! ✔$(tput sgr0)"
