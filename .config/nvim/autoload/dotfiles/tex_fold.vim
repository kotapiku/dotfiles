" Build VimTeX folds only when the user first uses a folding command.
function! dotfiles#tex_fold#setup() abort
  if &l:foldexpr !=# 'vimtex#fold#level(v:lnum)'
        \ || !get(g:, 'vimtex_fold_manual', 0)
    return
  endif

  " Do this before changing display options: expr folds can scan the whole
  " buffer even at foldlevel=99. VimTeX also queues a scan on CursorMoved.
  setlocal foldmethod=manual
  autocmd! vimtex_temporary CursorMoved <buffer>
  unlet! w:dotfiles_tex_folds_buffer

  for l:key in s:keys
    execute 'nnoremap <silent><buffer> ' . l:key
          \ . ' :<C-u>call dotfiles#tex_fold#command(' . string(l:key) . ', v:count)<CR>'
  endfor
  let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
        \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : ' | ')
        \ . 'call dotfiles#tex_fold#undo()'
endfunction

function! dotfiles#tex_fold#command(key, count) abort
  if !&diff && &l:foldmethod ==# 'manual'
        \ && &l:foldexpr ==# 'vimtex#fold#level(v:lnum)'
    if a:key ==# 'zx' || a:key ==# 'zX'
      call vimtex#fold#refresh(a:key)
      let w:dotfiles_tex_folds_buffer = bufnr()
      return
    endif
    " Folds belong to a window. Another split may not have computed them yet.
    if get(w:, 'dotfiles_tex_folds_buffer', -1) != bufnr()
      call vimtex#fold#refresh('zX')
      let w:dotfiles_tex_folds_buffer = bufnr()
    endif
  endif
  execute 'normal! ' . (a:count > 0 ? a:count : '') . a:key
endfunction

function! dotfiles#tex_fold#undo() abort
  for l:key in s:keys
    execute 'silent! nunmap <buffer> ' . l:key
  endfor
  unlet! w:dotfiles_tex_folds_buffer
  setlocal foldmethod< foldexpr< foldtext<
endfunction

let s:keys = ['za', 'zA', 'zc', 'zC', 'zo', 'zO', 'zm', 'zM', 'zr', 'zR',
      \ 'zv', 'zx', 'zX', 'zj', 'zk', '[z', ']z']
