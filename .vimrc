" encoding
set encoding=utf-8
scriptencoding utf-8
set fileencodings=utf-8

" appearence
set title
syntax on
set ruler           " display cursor position
set wildmenu        " completion
set nofoldenable    " disable fold
set termguicolors

if winwidth('%') <= 78 " show number only when window width is small
  set nonumber
else
  set number
endif

" indent
set autoindent
set expandtab    " replace tab with space
set tabstop=2
set shiftwidth=2

" search
set incsearch    " incremental search
set ignorecase
set smartcase    " 大文字含んでいたら区別
set wrapscan

set noswapfile    " swapファイルをつくらない
nnoremap n nzz    " 検索時にカーソル位置を中央に
nnoremap N Nzz
nnoremap Y y$     " Yでカーソル位置から行末までコピー

set hlsearch      " highlight

" clipboard
set clipboard+=unnamedplus

" fzf
set rtp+=/usr/local/opt/fzf

" ignore in completion
set wildignorecase  " to ignorecase in e command
set wildignore=.svn,CVS,.git,*.o,*.a,*.class,*.mo,*.la,*.so,*.obj,*.swp,*.jpg,*.png,*.xpm,*.gif,*.pdf,*.bak,*.beam,*.cmi,*.cmo,*.cma

" autocmd
augroup vimrc
  autocmd!
  au BufNewFile,BufRead *.x setf alex  " set filetype
  au BufNewFile,BufRead *.y setf happy
  au BufNewFile,BufRead *.{md,mdwn,mkd,mkdn,mark*} setf markdown
  au BufNewFile,BufRead *.v setf coq
  au BufNewFile,BufRead *.lean setf lean
  au BufNewFile,BufRead *.jl setf julia
  au BufNewFile,BufRead *.tex setf tex
  au BufWritePre * call DeleteWhiteSpaces()  " delete whitespace in end of line
  au FileType qf set nobuflisted  " remove quickfix from buffer list
augroup End

function! DeleteWhiteSpaces()
  let pos = getpos(".")
  %s/\s\+$//ge
  call setpos('.', pos)
endfunction

" buffer
set hidden
set nosol   " buffer間をカーソル位置を保存して移動
nnoremap <Space>hn :bn<CR>
nnoremap <Space>hp :bp<CR>
nnoremap <Space>hb :b#<CR>
nnoremap <Space>hf :bf<CR>
nnoremap <Space>hm :call OpenMiddleBuffer()<CR>
nnoremap <Space>hl :bl<CR>
nnoremap <Space>hd :bp<bar>bd#<CR>  " 1個前に行って元いたbufferを閉じる

function! OpenMiddleBuffer()
  let ls = map(split(execute("buffers"), "\n"), "get(split(v:val), 0)")
  execute(":b" . str2nr(get(ls, (len(ls)-1)/2)))
endfunction

" keymap
let mapleader = "\\"

inoremap jk <Esc>
nnoremap gs  :<C-u>%s///g<Left><Left><Left>
vnoremap gs  :s///g<Left><Left><Left>
noremap k   gk
noremap j   gj
noremap 0   g0
noremap $   g$
nnoremap ; :
nnoremap : ;
nnoremap == gg=G
nnoremap ta :call JumpRefToLabel()<CR>

function! JumpRefToLabel()
  normal "ayi{
  let ref = @a
  execute("/label{" . ref . "}")
endfunction

" spell check
set spell
nnoremap \s ]s

" terminal mode
tnoremap <silent> jk <C-\><C-n>

" open dotfiles by command
command! Zshrc e ~/.zshrc
command! Vimrc e ~/.vimrc
command! Tmuxconf e ~/.tmux.conf
command! Deintoml e ~/dotfiles/.config/nvim/dein/toml/dein.toml
command! DeintomlLazy e ~/dotfiles/.config/nvim/dein/toml/dein_lazy.toml

if has("mac")
  let g:python_host_prog='/usr/bin/python'
  let g:python3_host_prog='/usr/bin/python3'
endif

if has("nvim")
  "dein Scripts-----------------------------
  if &compatible
    set nocompatible               " Be improved
  endif

  " Required:
  set runtimepath+=/Users/kotapiku/.cache/dein/repos/github.com/Shougo/dein.vim

  " Required:
  if dein#load_state('/Users/kotapiku/.cache/dein')
    call dein#begin('/Users/kotapiku/.cache/dein')

    let s:toml_dir  = $HOME . '/dotfiles/.config/nvim/dein/toml'

    " TOML を読み込み、キャッシュしておく
    call dein#load_toml(s:toml_dir . '/dein.toml',      {'lazy': 0})
    call dein#load_toml(s:toml_dir . '/dein_lazy.toml', {'lazy': 1})

    " Required:
    call dein#end()
    call dein#save_state()

    call map(dein#check_clean(), "delete(v:val, 'rf')")
    call dein#recache_runtimepath()
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
colorscheme molokai

hi IncSearch guifg=#00D0D0 " highlight color when gc
hi IncSearch guibg=#000000
