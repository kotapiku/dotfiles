" Terminal appearance. VS Code owns the UI when Neovim is embedded in it.
if exists('g:vscode')
  finish
endif

set title
syntax on
set ruler wildmenu nofoldenable
set termguicolors background=dark

" Keep the text in place when Git signs appear, and give the cursor some room.
set number norelativenumber numberwidth=4
set signcolumn=yes
set cursorline
if exists('+cursorlineopt')
  set cursorlineopt=screenline,number
endif
set scrolloff=5 sidescrolloff=5

" Show only meaningful whitespace; keep wrapped prose easy to follow.
set list
let &listchars = 'tab:  ,trail:·,nbsp:␣'
set breakindent
let &showbreak = '↳ '
set fillchars+=vert:│
if has('nvim') || has('patch-8.0.0728')
  execute 'set fillchars+=eob:\ '
endif
set pumheight=10
if exists('+winborder')
  set winborder=rounded
endif

let g:nord_italic = 1
let g:nord_italic_comments = 1
let g:nord_uniform_status_lines = 0

function! s:apply_highlights() abort
  if get(g:, 'colors_name', '') !=# 'nord'
    return
  endif
  " A little more contrast for comments and numbers than the stock palette.
  highlight Comment guifg=#8995AA gui=italic ctermfg=246 cterm=italic
  highlight LineNr guifg=#738099 guibg=NONE ctermfg=244 ctermbg=NONE
  highlight CursorLine guibg=#353D4A gui=NONE ctermbg=237 cterm=NONE
  highlight CursorLineNr guifg=#88C0D0 guibg=NONE gui=bold ctermfg=110 ctermbg=NONE cterm=bold
  highlight SignColumn guibg=#2E3440 ctermbg=236
  highlight VertSplit guifg=#4C566A guibg=NONE gui=NONE ctermfg=240 ctermbg=NONE cterm=NONE
  highlight! link WinSeparator VertSplit

  " Soft search matches; the current match / :s///gc confirmation stays clear.
  highlight Search guifg=#ECEFF4 guibg=#4C566A gui=NONE ctermfg=255 ctermbg=240 cterm=NONE
  highlight IncSearch guifg=#2E3440 guibg=#EBCB8B gui=bold ctermfg=236 ctermbg=222 cterm=bold
  highlight! link CurSearch IncSearch

  " Keep spelling hints subtle and preserve the underlying syntax colors.
  highlight SpellBad guifg=NONE guibg=NONE guisp=#616E88 gui=undercurl ctermfg=NONE ctermbg=NONE cterm=underline
  highlight! link SpellCap SpellBad
  highlight! link SpellLocal SpellBad
  highlight! link SpellRare SpellBad

  highlight NormalFloat guifg=#D8DEE9 guibg=#3B4252 ctermfg=253 ctermbg=237
  highlight FloatBorder guifg=#738099 guibg=#3B4252 ctermfg=244 ctermbg=237
  highlight Pmenu guifg=#D8DEE9 guibg=#3B4252 ctermfg=253 ctermbg=237
  highlight PmenuSel guifg=#2E3440 guibg=#88C0D0 gui=bold ctermfg=236 ctermbg=110 cterm=bold

  " Make LaTeX structure stand out without coloring whole environments.
  highlight texCmdEnv guifg=#88C0D0 gui=bold ctermfg=110 cterm=bold
  highlight texEnvArgName guifg=#EBCB8B gui=bold ctermfg=222 cterm=bold
  highlight! link texCmdMathEnv texCmdEnv
  highlight! link texCmdEnvM texCmdEnv
  highlight! link texMathEnvArgName texEnvArgName
  highlight! link texEnvMArgName texEnvArgName
  highlight! link texCmdNewenv texCmdEnv
  highlight! link texCmdNewthm texCmdEnv
  highlight texCmdPart guifg=#B48EAD gui=bold ctermfg=139 cterm=bold
  highlight texPartArgTitle guifg=#ECEFF4 gui=bold ctermfg=255 cterm=bold
  highlight texCmdRef guifg=#8FBCBB gui=bold ctermfg=109 cterm=bold
  highlight texRefArg guifg=#A3BE8C gui=NONE ctermfg=144 cterm=NONE
endfunction

augroup dotfiles_appearance
  autocmd!
  autocmd ColorScheme * call <SID>apply_highlights()
  autocmd WinEnter * setlocal cursorline
  autocmd WinLeave * setlocal nocursorline
augroup END

" Nord is installed by dein. Keep first startup / plain Vim usable without it.
try
  colorscheme nord
catch /^Vim\%((\a\+)\)\=:E185/
  colorscheme hybrid
endtry
