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

    ln -snfv ${DOT_DIRECTORY}/${f} ${HOME}/${f}
  fi
done

# download color scheme for vim
if [ ! -e ${HOME}/.config/nvim/colors ]; then
  cd ~/.config/nvim
  curl -O https://github.com/morhetz/gruvbox/tree/master/colors
fi

# for dein
if [ ! -e ${HOME}/.cache ]; then
  curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > installer.sh
  sh ./installer.sh ~/.cache/dein
  rm installer.sh
fi

# for tpm (tmux plugin manager)
if [ ! -e ${HOME}/.tmux ]; then
  mkdir ~/.tmux
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "$(tput setaf 2)Dotfiles are deployed! ✔$(tput sgr0)"
