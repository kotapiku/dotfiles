" Terminal appearance. VS Code owns the UI when Neovim is embedded in it.
if exists('g:vscode')
  finish
endif

set title
" In Neovim, leave syntax initialization to startup after plugin setup.
" Enabling it here triggers TeX ftplugins too early for `nvim file.tex`.
if !has('nvim')
  syntax on
endif
set ruler wildmenu nofoldenable
set termguicolors background=dark
" Keep a file tab visible even when only one file is open (including plain Vim).
set showtabline=2

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

" Use the same tab colors in Airline and Vim's built-in tab bar.
function! DotfilesAirlineTheme(palette) abort
  if get(g:, 'airline_theme', '') !=# 'nord'
    return
  endif
  let a:palette.tabline = {
        \ 'airline_tab': ['#B4BFCE', '#303846', 250, 237, ''],
        \ 'airline_tabsel': ['#1B2029', '#88C0D0', 234, 110, 'bold'],
        \ 'airline_tabmod': ['#1B2029', '#EBCB8B', 234, 222, 'bold'],
        \ 'airline_tabmod_unsel': ['#EBCB8B', '#303846', 222, 237, ''],
        \ 'airline_tabhid': ['#B4BFCE', '#303846', 250, 237, ''],
        \ 'airline_tabfill': ['#98A7BC', '#1B2029', 248, 234, ''],
        \ }
  for name in ['airline_tab', 'airline_tabsel', 'airline_tabmod', 'airline_tabmod_unsel', 'airline_tabhid']
    let a:palette.tabline[name . '_right'] = copy(a:palette.tabline[name])
  endfor
endfunction
let g:airline_theme_patch_func = 'DotfilesAirlineTheme'

function! s:apply_highlights() abort
  if index(['nord', 'hybrid'], get(g:, 'colors_name', '')) < 0
    return
  endif
  " Apply the same contrast in Nord and the plain Vim / first-start fallback.
  highlight Normal guifg=#F0F3F8 guibg=#1B2029 gui=NONE ctermfg=255 ctermbg=234 cterm=NONE
  highlight! link NormalNC Normal
  highlight Comment guifg=#B4BFCE gui=italic ctermfg=250 cterm=italic
  highlight LineNr guifg=#98A7BC guibg=NONE ctermfg=248 ctermbg=NONE
  highlight CursorLine guibg=#303846 gui=NONE ctermbg=237 cterm=NONE
  highlight CursorLineNr guifg=#88C0D0 guibg=NONE gui=bold ctermfg=110 ctermbg=NONE cterm=bold
  highlight SignColumn guibg=#1B2029 ctermbg=234
  highlight VertSplit guifg=#4C566A guibg=NONE gui=NONE ctermfg=240 ctermbg=NONE cterm=NONE
  highlight! link WinSeparator VertSplit
  highlight NonText guifg=#98A7BC guibg=NONE ctermfg=248 ctermbg=NONE
  highlight! link SpecialKey NonText
  highlight Folded guifg=#B4BFCE guibg=#303846 ctermfg=250 ctermbg=237

  highlight TabLine guifg=#B4BFCE guibg=#303846 gui=NONE ctermfg=250 ctermbg=237 cterm=NONE
  highlight TabLineSel guifg=#1B2029 guibg=#88C0D0 gui=bold ctermfg=234 ctermbg=110 cterm=bold
  highlight TabLineFill guifg=#98A7BC guibg=#1B2029 gui=NONE ctermfg=248 ctermbg=234 cterm=NONE

  " Keep selected text and matching brackets readable over their highlights.
  highlight Visual guifg=#F0F3F8 guibg=#46556B gui=NONE ctermfg=255 ctermbg=239 cterm=NONE
  highlight MatchParen guifg=#1B2029 guibg=#EBCB8B gui=bold ctermfg=234 ctermbg=222 cterm=bold

  " Lift common syntax colors too, so commands stay as legible as prose.
  highlight Statement guifg=#A6C1DC ctermfg=153
  highlight Keyword guifg=#A6C1DC ctermfg=153
  highlight Function guifg=#A6C1DC ctermfg=153
  highlight PreProc guifg=#A6C1DC ctermfg=153
  highlight Type guifg=#A6C1DC ctermfg=153
  highlight Identifier guifg=#A4D0CF ctermfg=152
  highlight Constant guifg=#C3A6BD ctermfg=182
  highlight Number guifg=#C3A6BD ctermfg=182
  highlight String guifg=#B4CBA2 ctermfg=151
  highlight Special guifg=#E5E9F0 ctermfg=254
  highlight Delimiter guifg=#BCC8D9 ctermfg=152

  " Soft search matches; the current match / :s///gc confirmation stays clear.
  highlight Search guifg=#ECEFF4 guibg=#4C566A gui=NONE ctermfg=255 ctermbg=240 cterm=NONE
  highlight IncSearch guifg=#2E3440 guibg=#EBCB8B gui=bold ctermfg=236 ctermbg=222 cterm=bold
  highlight! link CurSearch IncSearch

  " Keep spelling hints subtle and preserve the underlying syntax colors.
  highlight SpellBad guifg=NONE guibg=NONE guisp=#616E88 gui=undercurl ctermfg=NONE ctermbg=NONE cterm=underline
  highlight! link SpellCap SpellBad
  highlight! link SpellLocal SpellBad
  highlight! link SpellRare SpellBad

  highlight NormalFloat guifg=#F0F3F8 guibg=#303846 ctermfg=255 ctermbg=237
  highlight FloatBorder guifg=#98A7BC guibg=#303846 ctermfg=248 ctermbg=237
  highlight Pmenu guifg=#F0F3F8 guibg=#303846 ctermfg=255 ctermbg=237
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
  highlight texCmdPart guifg=#C3A6BD gui=bold ctermfg=182 cterm=bold
  highlight texPartArgTitle guifg=#ECEFF4 gui=bold ctermfg=255 cterm=bold
  highlight texCmdRef guifg=#A4D0CF gui=bold ctermfg=152 cterm=bold
  highlight texRefArg guifg=#B4CBA2 gui=NONE ctermfg=151 cterm=NONE
endfunction

augroup dotfiles_appearance
  autocmd!
  autocmd ColorScheme * call <SID>apply_highlights()
  autocmd WinEnter * setlocal cursorline
  autocmd WinLeave * setlocal nocursorline
augroup END

" Nord is installed by lazy.nvim. Keep first startup / plain Vim usable without it.
try
  colorscheme nord
catch /^Vim\%((\a\+)\)\=:E185/
  colorscheme hybrid
endtry
