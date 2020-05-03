"-------------------------------------BOF---------------------------------------

" Vim filetype plugin file
"
" Language:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  01.01.2018
" Version:      1.0.0
"
"-------------------------------------------------------------------------------
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_tags#Lstags(bang, ...)

  "-----------------------------------------------------------------------------
  " Function used with LsTags command.
  "-----------------------------------------------------------------------------

  let kword = a:0 ? a:1 : '*'

  if a:bang
    call lsdyna_vimgrep#Vimgrep(kword, '%', 'i')
    " it speed up opening includes for search
  else
    call lsdyna_vimgrep#Vimgrep(kword, '%', '')
  endif

  " parsing keywords change cursor position and I want to stay in place
  " save cursor position
  let save_cursor = getpos(".")
  let save_cursor[0] = bufnr('%')

  let dtags = []
  for item in getqflist()
    let kword = lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fn')._Kword()
    call extend(dtags, map(kword, 'v:val.Tag()'))
  endfor

  call writefile(dtags, g:lsdynaPathTags)
  echo 'Write '.len(dtags).' dtags.'

  " retore cursor position
  execute 'noautocmd buffer ' . save_cursor[0]
  call setpos('.', save_cursor)

endfunction

"-------------------------------------------------------------------------------

