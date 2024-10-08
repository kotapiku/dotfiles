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

# apple setting
defaults write -g ApplePressAndHoldEnabled -bool false

# for brew
if [[ !$(command -v brew)  ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  export PATH="/opt/homebrew/bin:$PATH" # for brew
  brew bundle
fi

echo "$(tput setaf 2)Dotfiles are deployed! ✔$(tput sgr0)"

