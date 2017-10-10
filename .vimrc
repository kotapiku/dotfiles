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

" indent
set autoindent
set cindent
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

" clipboard
set clipboard+=unnamed

" 括弧補完
inoremap {{ {}<LEFT>
inoremap [ []<LEFT>
inoremap ( ()<LEFT>
" inoremap < <><LEFT>
inoremap " ""<LEFT>
inoremap ' ''<LEFT>
inoremap {<Enter> {}<Left><CR><ESC><S-o>

" =前後に空白補完
inoremap <expr> = getline(".")[col(".")-3] == '=' ? "<bs>= " : getline(".")[col(".")-2] =~ '\s' ? "= " : "="

" == でバッファ内インデント
nnoremap == gg=G''

" color scheme
set background=dark
colorscheme solarized

" nerdtree
map <C-n> :NERDTreeToggle<CR>

" buffer
set hidden
nnoremap <Space>bp :bprevious<CR>
nnoremap <Space>bn :bnext<CR>
nnoremap <Space>bb :b#<CR>
nnoremap <Space>bf :bf<CR>
nnoremap <Space>bl :bl<CR>
nnoremap <Space>bm :bm<CR>
nnoremap <Space>bd :bdelete<CR>

"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=/Users/kotapiku/.cache/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state($HOME . '/.config/nvim/dein')

" XDG base direcory compartible
  let g:dein#cache_directory = $HOME . '/.cache/dein'

  " dein begin
  call dein#begin($HOME . '/.config/nvim/dein')

 " プラグインリストを収めた TOML ファイル
 " 予め TOML ファイル（後述）を用意しておく
 let s:toml_dir  = $HOME . '/.config/nvim/dein/toml' 
 let s:toml      = s:toml_dir . '/dein.toml'
 let s:lazy_toml = s:toml_dir . '/dein_lazy.toml'

 " TOML を読み込み、キャッシュしておく
 call dein#load_toml(s:toml,      {'lazy': 0})
 call dein#load_toml(s:lazy_toml, {'lazy': 1})


  " Required:
  call dein#end()
  call dein#save_state()
endif

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif

"End dein Scripts-------------------------
