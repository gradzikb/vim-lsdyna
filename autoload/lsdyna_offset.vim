"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  20th of November 2016
" Version:      1.0.1
"
" History of change:
"
" v1.0.0
"   - element_mass fix
" v1.0.1
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_offset#Offset(line1, line2, ...)

  " command arguments check
  if a:0 != 2
      echo "Error! Incorrect number of arguments."
  elseif a:1 !~? '^[nep]\{1,3}$'
      echo "Error! Incorrect arguments syntax."
  endif

  " script variables used in local functions
  let s:line1 = a:line1
  let s:line2 = a:line2
  let s:args = a:1
  let s:offset = a:2

  " keyword name
  call search('^\*\a','bcW')
  let keyword = getline('.')

  " select function for offset
  if keyword =~? '^\*NODE\s*$' ||
  \  keyword =~? '^\*AIRBAG_REFERENCE_GEOMETRY\w*\s*$'
    call <SID>Offset(['8n'])
  elseif keyword =~? '^\*NODE %\s*$' ||
  \      keyword =~? '^\*AIRBAG_REFERENCE_GEOMETRY\w* %\s*$'
    call <SID>Offset(['10n'])
  elseif keyword =~? '^\*SET_'
    call <SID>Offset(['10n','10n','10n','10n','10n','10n','10n','10n'])
  elseif keyword =~? '^\*ELEMENT_MASS\w*\s*$'
    call <SID>Offset(['8e','8n','16','8p'])
  elseif keyword =~? '^\*ELEMENT_MASS\w* %\s*$'
    call <SID>Offset(['10e','10n','16','10p'])
  elseif keyword =~? '^\*ELEMENT_BEAM\w*\s*$'
    call <SID>Offset(['8e','8p','8n','8n','8n'])
  elseif keyword =~? '^\*ELEMENT_BEAM\w* %\s*$'
    call <SID>Offset(['10e','10p','10n','10n','10n'])
  elseif keyword =~? '^\*ELEMENT_DISCRETE\w*\s*$'
    call <SID>Offset(['8e','8p','8n','8n'])
  elseif keyword =~? '^\*ELEMENT_DISCRETE\w* %\s*$'
    call <SID>Offset(['10e','10p','10n','10n'])
  elseif keyword =~? '^\*ELEMENT_\w\+\s*$' ||
  \      keyword =~? '^\*AIRBAG_SHELL_REFERENCE_GEOMETRY\w\+\s*$'
    call <SID>Offset(['8e','8p','8n','8n','8n','8n','8n','8n','8n','8n'])
  elseif keyword =~? '^\*ELEMENT_\w\+ %\s*$' ||
  \      keyword =~? '^\*AIRBAG_SHELL_REFERENCE_GEOMETRY\w\+ %\s*$'
    call <SID>Offset(['10e','10p','10n','10n','10n','10n','10n','10n','10n','10n'])
  endif

  " restore cursor position
  call cursor(a:line1, 0)

endfunction

"-------------------------------------------------------------------------------

function! s:Offset(def) abort

  for lnum in range(s:line1, s:line2)
    
    let line = getline(lnum)
    if line =~? '^[$*]' | continue | endif

    let lpos = 0 " position in line
    let new_line = ''
    for def in a:def

      let clen = str2nr(def)                 " column length
      let colstr = strpart(line, lpos, clen) " column value as string
      let colnr = str2nr(colstr)             " column value as number
      if len(colstr) == 0 | break | endif    " end of the line, do nothing after this point
      let lpos += clen                       " update position in line

      " offset id if condition meet
      let def_type = substitute(def, '^\d\+', '', '') " '8p' --> 'p' 
      if !empty(def_type) && s:args =~? def_type && colnr != 0
        let new_col = colnr + s:offset
      else
        let new_col = colstr
      endif 

      " concate columns to new line
      let new_line ..= printf('%'..clen..'s', new_col)

    endfor

    " write a new line
    let new_line ..= line[lpos:]
    call setline(lnum, new_line)

  endfor
  

endfunction

"-------------------------------------EOF---------------------------------------
