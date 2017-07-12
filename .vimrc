
" encoding
set encoding=utf-8
scriptencoding utf-8
set fileencodings=utf-8

" appearence
set number
set title
syntax on
set ruler    "display cursor position
set wildmenu    "completion
set showmatch    "jump to corresponding parenthesis

" indent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab    "replace tab with space


" search
set incsearch    "increment
set hlsearch    "highlight
set ignorecase
set wrapscan

set noswapfile    "swapファイルをつくらない
nnoremap n nzz    "検索時にカーソル位置を中央に
nnoremap N Nzz
nnoremap Y y$    "Yでカーソル位置から行末までコピー

" color scheme
set background=dark
colorscheme solarized
