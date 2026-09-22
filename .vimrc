" Resolve the checkout even when this file is loaded through a symlink.
let s:dotfiles_dir = fnamemodify(resolve(expand("<sfile>:p")), ":h")
execute "set runtimepath^=" . fnameescape(s:dotfiles_dir . "/.config/nvim")
execute "set runtimepath+=" . fnameescape(s:dotfiles_dir . "/.config/nvim/after")

" encoding
set encoding=utf-8
scriptencoding utf-8
set fileencodings=utf-8

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

" Recover unsaved edits with swap; retain undo history across Neovim sessions.
set swapfile
if has("nvim")
  set undofile
endif

" 検索時にカーソル位置を中央に
nnoremap n nzz
nnoremap N Nzz
" Yでカーソル位置から行末までコピー
nnoremap Y y$

set hlsearch      " highlight

" clipboard
set clipboard+=unnamedplus

" ctags
set tags=./tags;,tags;

" completion
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
  " au BufWritePre * call DeleteWhiteSpaces()  " delete whitespace in end of line
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
nnoremap <Space>hd :bp<bar>bd#<CR>

function! OpenMiddleBuffer()
  let ls = map(split(execute("buffers"), "\n"), "get(split(v:val), 0)")
  execute(":b" . str2nr(get(ls, (len(ls)-1)/2)))
endfunction

" keymap
let mapleader = "\\"
let maplocalleader = "\\"

inoremap jk <Esc>
nnoremap gs  :<C-u>%s///g<Left><Left><Left>
vnoremap gs  :s///g<Left><Left><Left>
noremap k   gk
noremap j   gj
noremap 0   g0
noremap $   g$
nnoremap ; :
nnoremap : ;

nnoremap <leader>rw "_ciw<C-r>+<Esc>
nnoremap <leader>r" "_ci"<C-r>+<Esc>
nnoremap <leader>r' "_ci'<C-r>+<Esc>
nnoremap <leader>r( "_ci(<C-r>+<Esc>
nnoremap <leader>r[ "_ci[<C-r>+<Esc>
nnoremap <leader>r{ "_ci{<C-r>+<Esc>

" Spell checking is useful for prose, including TeX (after/ftplugin/tex.vim).
set nospell
augroup prose_spell
  autocmd!
  autocmd FileType markdown,text setlocal spell
augroup END
nnoremap \s ]s

" terminal mode
tnoremap <silent> jk <C-\><C-n>

" open dotfiles by command
command! Zshrc e ~/.zshrc
command! Vimrc e ~/.vimrc
command! Tmuxconf e ~/.tmux.conf
command! Deintoml execute "edit " . fnameescape(s:dotfiles_dir . "/.config/nvim/dein/toml/dein.toml")
command! DeintomlLazy execute "edit " . fnameescape(s:dotfiles_dir . "/.config/nvim/dein/toml/dein_lazy.toml")

if has("nvim")
  execute "source " . fnameescape(s:dotfiles_dir . "/.config/nvim/dein/setup.vim")
endif

execute "source " . fnameescape(s:dotfiles_dir . "/.config/nvim/appearance.vim")
