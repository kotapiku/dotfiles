" Preserve VimTeX's matching and original spelling in Neovim's popup menu.
function! dotfiles#tex_complete#omnifunc(findstart, base) abort
  if a:findstart
    return vimtex#complete#omnifunc(a:findstart, a:base)
  endif

  " VimTeX's label matcher uses case-sensitive regexes even with ignore_case.
  let l:result = vimtex#complete#omnifunc(0, '\c' . a:base)
  let l:matches = []
  for l:item in l:result
    let l:match = type(l:item) == v:t_string ? {'word': l:item} : copy(l:item)
    " Ignore case when filtering, but keep distinct commands like delta/Delta.
    call add(l:matches, extend(l:match, {'icase': 1, 'dup': 1}))
  endfor
  return l:matches
endfunction
