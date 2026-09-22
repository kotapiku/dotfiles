" Keep prose readable without inserting hard line breaks into the source.
setlocal spell linebreak

" Start with all folds open; zx refreshes VimTeX's manual folds after edits.
setlocal foldenable foldlevel=99

" Forward search directly, independent of leader mappings.
nnoremap <buffer> <silent> <C-A-j> :<C-u>VimtexView<CR>

" Tag navigation without conflicting with the terminal's pane shortcuts.
" Jump directly to one match, or offer a choice if the tag is ambiguous.
nnoremap <buffer> <silent> gd g<C-]>

augroup dotfiles_tex_tags
  autocmd! * <buffer>
  autocmd BufEnter <buffer> call dotfiles#tex_tags#update(0)
  autocmd BufWritePost <buffer> call dotfiles#tex_tags#update(1)
augroup END
call dotfiles#tex_tags#update(0)

if has('nvim') && !exists('g:vscode')
  lua require('dotfiles.tex').setup_buffer()
endif

" Undo these settings if the buffer changes filetype.
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
      \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : ' | ')
      \ . 'setlocal spell< linebreak< tags< foldenable< foldlevel<'
      \ . ' | execute "silent! nunmap <buffer> <C-A-j>"'
      \ . ' | execute "silent! nunmap <buffer> gd"'
      \ . ' | execute "autocmd! dotfiles_tex_tags * <buffer>"'
if has('nvim') && !exists('g:vscode')
  let b:undo_ftplugin .= ' | call luaeval(''require("dotfiles.tex").undo_buffer()'')'
endif
