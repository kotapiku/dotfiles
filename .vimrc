" encoding
set encoding=utf-8
scriptencoding utf-8
set fileencodings=utf-8

" appearence
set number
set title
syntax on
set ruler           "display cursor position
set wildmenu        "completion
set nofoldenable    "disable fold

" indent
set autoindent
set cindent
set expandtab    "replace tab with space

set tabstop=4
set shiftwidth=4

" search
set incsearch    "incremental search
set hlsearch     "highlight
set ignorecase
set smartcase    "大文字含んでいたら区別
set wrapscan

set noswapfile    "swapファイルをつくらない
nnoremap n nzz    "検索時にカーソル位置を中央に
nnoremap N Nzz
nnoremap Y y$    "Yでカーソル位置から行末までコピー

" clipboard
set clipboard+=unnamed

" ignore in completion
set wildignorecase  "to ignorecase in e command
set wildignore=.svn,CVS,.git,*.o,*.a,*.class,*.mo,*.la,*.so,*.obj,*.swp,*.jpg,*.png,*.xpm,*.gif,*.pdf,*.bak,*.beam,*.cmi,*.cmo,*.cma

" vimgrepで自動cw
autocmd QuickFixCmdPost *grep* cwindow

" 括弧補完
inoremap {{ {}<LEFT><Left>
inoremap [ []<LEFT>
inoremap ( ()<LEFT>
inoremap " ""<LEFT>
inoremap ' ''<LEFT>
inoremap {<Enter> {}<Left><CR><ESC><S-o>

" nerdtree
nnoremap <Space>n :NERDTreeToggle<CR>

" tagbar
nnoremap <Space>t :TagbarToggle<CR><C-w>l

" buffer
set hidden
set nosol   "buffer間をカーソル位置を保存して移動
nnoremap <Space>bp :bprevious<CR>
nnoremap <Space>bn :bnext<CR>
nnoremap <Space>bb :b#<CR>
nnoremap <Space>bf :bf<CR>
nnoremap <Space>bl :bl<CR>
nnoremap <Space>bm :bm<CR>
nnoremap <Space>bd :bdelete<CR>

" keymap
let mapleader = "\\"
inoremap jk <Esc>
nnoremap gs  :<C-u>%s///g<Left><Left><Left>
vnoremap gs  :s///g<Left><Left><Left>
nnoremap k   gk
nnoremap j   gj
vnoremap k   gk
vnoremap j   gj
nnoremap gk  k
nnoremap gj  j
vnoremap gk  k
vnoremap gj  j
nnoremap ; :
nnoremap : ;

" terminal mode
tnoremap <silent> jk <C-\><C-n>

if has("mac")
    let g:python_host_prog='/Users/kotapiku/.pyenv/shims/shims/python'
    let g:python3_host_prog='/Users/kotapiku/.pyenv/shims/shims/python3'
elseif has("unix")
    let g:python_host_prog='/usr/bin/python'
    let g:python3_host_prog='/usr/bin/python3'
endif

if has("nvim")
"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
let s:dein_path = $HOME . '/dotfiles/config/nvim/dein'
let s:dein_repo_path = s:dein_path . '/repos/github.com/Shougo/dein.vim'

if !isdirectory(s:dein_repo_path)
  execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_path
endif

execute 'set runtimepath^=' . s:dein_repo_path

" Required:
if dein#load_state(s:dein_path)

" XDG base direcory compartible
 let g:dein#cache_directory = $HOME . '/.cache/dein'

 " dein begin
 call dein#begin(s:dein_path)
 let s:toml_dir  = s:dein_path . '/toml'
 let s:lazy_toml = s:toml_dir . '/dein_lazy.toml'
 if has("mac")
   let s:toml      = s:toml_dir . '/dein.toml'
 elseif has("unix")
   let s:toml      = s:toml_dir . '/dein_unix.toml'
 endif

 " TOML を読み込み、キャッシュしておく
 call dein#load_toml(s:toml,      {'lazy': 0})
 call dein#load_toml(s:lazy_toml, {'lazy': 1})

 " Required:
 call dein#end()
 call dein#save_state()

 call map(dein#check_clean(), "delete(v:val, 'rf')")
endif

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif

"End dein Scripts-------------------------
endif

set background=dark
colorscheme gruvbox

set clipboard=unnamedplus
