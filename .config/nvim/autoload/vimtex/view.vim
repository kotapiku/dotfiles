" Loaded after VimTeX's view.vim by lua/plugins/tex.lua.
" funcref() keeps the original implementation even after redefining its name.
if !exists('s:InverseSearch')
  let s:InverseSearch = funcref('vimtex#view#inverse_search')
endif

function! vimtex#view#inverse_search(line, filename, column = 0) abort
  let l:previous_window = win_getid()
  let l:previous_buffer = bufnr()
  let l:file = fnamemodify(resolve(a:filename), ':p')
  let l:result = -1

  try
    " VimTeX v2.18 checks the current project before changing buffers. Select
    " the source first, including hidden buffers shown in the tab bar.
    for l:buffer in getbufinfo({'bufloaded': 1})
      if !empty(getbufvar(l:buffer.bufnr, 'vimtex', {}))
            \ && fnamemodify(resolve(l:buffer.name), ':p') ==# l:file
        let l:windows = win_findbuf(l:buffer.bufnr)
        if empty(l:windows)
          execute 'buffer' l:buffer.bufnr
        elseif index(l:windows, l:previous_window) < 0
          call win_gotoid(l:windows[0])
        endif
        break
      endif
    endfor

    let l:result = s:InverseSearch(a:line, a:filename, a:column)
    return l:result
  finally
    " Requests are broadcast to all editors; rejected requests must not move us.
    if l:result < 0
      call win_gotoid(l:previous_window)
      if bufnr() != l:previous_buffer && bufexists(l:previous_buffer)
        execute 'buffer' l:previous_buffer
      endif
    endif
  endtry
endfunction
