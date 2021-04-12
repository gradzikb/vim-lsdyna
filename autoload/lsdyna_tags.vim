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

  "TODO: I need this variable for evaluation of parameters value but I do not
  "need this option to do it for tags only fo lsmanager, update parameter
  "construction to not always make parameter evaluation 
  let g:lsdyna_manager_parameters = {}

  let kword = a:0 ? a:1 : '*'

  if a:bang
    let qfid = lsdyna_vimgrep#Vimgrep(kword, '%', 'i')
  else
    let qfid = lsdyna_vimgrep#Vimgrep(kword, '%', '')
  endif

  " parsing keywords change cursor position and I want to stay in place
  " save cursor position
  "let save_cursor = getpos(".")
  "let save_cursor[0] = bufnr('%')

  let dtags = []
  "for item in getqflist()
  for item in getqflist({'id':qfid, 'items':0}).items
    let kword = lsdyna_parser#Keyword(item.lnum, item.bufnr, '')._Autodetect()
    call extend(dtags, map(kword, 'v:val.Tag()'))
  endfor

  call writefile(dtags, &tags)
  echo 'Write '.len(dtags).' dtags.'

  " retore cursor position
  "execute 'noautocmd buffer ' . save_cursor[0]
  "call setpos('.', save_cursor)

endfunction

"-------------------------------------------------------------------------------

