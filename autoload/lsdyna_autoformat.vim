"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  27th of July 2017
" Version:      1.1.2
"
" History of change:
"
" v1.1.2
"   - empty fields at the beginning of the line supported
" v1.1.1
"   - define_curve function fixed
" v1.1.0
"   - script new layout
"   - keyword and comment lines are ignored
"   - free format (with coma) is now converted to fixed format
" v1.0.3
"   - autoformationg for standard keyword (8*10) improved
" v1.0.2
"   - *PARAMETER formatting improved (again)
" v1.0.1
"   - *PARAMETER formatting improved
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_autoformat#Autoformat() range

  "-----------------------------------------------------------------------------
  " Function to autformat Ls-Dyna lines.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  let s:line1 = a:firstline
  let s:line2 = a:lastline

  " find keyword
  let keyword = getline(search('^\*\a','bcnW'))

  "-----------------------------------------------------------------------------
  if keyword =~? "*DEFINE_CURVE.*$"
    call <SID>define_curve(a:firstline, a:lastline)
  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*NODE\s*$' ||
       \ keyword =~? '^\*AIRBAG_REFERENCE_GEOMETRY\w*\s*$'
    call <SID>Autoformat([8,16,16,16,8,8])
  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*NODE %\s*$' ||
       \ keyword =~? '^\*AIRBAG_REFERENCE_GEOMETRY\w* %\s*$'
    call <SID>Autoformat([10,16,16,16,10,10])
  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*ELEMENT_PLOTEL\s*$' ||
       \ keyword =~? '^\*ELEMENT_BEAM\s*$' ||
       \ keyword =~? '^\*ELEMENT_SHELL\s*$' ||
       \ keyword =~? '^\*ELEMENT_SOLID\s*$' ||
       \ keyword =~? '^\*AIRBAG_SHELL_REFERENCE_GEOMETRY\w*\s*$'
    call <SID>Autoformat([8,8,8,8,8,8,8,8,8,8])
  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*ELEMENT_PLOTEL %\s*$' ||
       \ keyword =~? '^\*ELEMENT_BEAM %\s*$' ||
       \ keyword =~? '^\*ELEMENT_SHELL %\s*$' ||
       \ keyword =~? '^\*ELEMENT_SOLID %\s*$' ||
       \ keyword =~? '^\*AIRBAG_SHELL_REFERENCE_GEOMETRY\w* %\s*$'
    call <SID>Autoformat([10,10,10,10,10,10,10,10,10,10])
  "-----------------------------------------------------------------------------
  elseif keyword =~? '\*ELEMENT_MASS\s*$'
    call <SID>Autoformat([8, 8, 16, 8])
  "-----------------------------------------------------------------------------
  elseif keyword =~? '\*ELEMENT_MASS %\s*$'
    call <SID>Autoformat([10, 10, 16, 10])
  "-----------------------------------------------------------------------------
  elseif keyword =~? '\*ELEMENT_MASS_PART\w*\s*$'
    call <SID>Autoformat([8, 16, 16, 16])
  "-----------------------------------------------------------------------------
  elseif keyword =~? '\*ELEMENT_MASS_PART\w %*\s*$'
    call <SID>Autoformat([10, 16, 16, 16])
  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*ELEMENT_DISCRETE\s*$'
    call <SID>Autoformat([8,8,8,8,8,16,8,16])
  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*ELEMENT_DISCRETE %\s*$'
    call <SID>Autoformat([10,10,10,10,10,16,10,16])
  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*ELEMENT_SEATBELT\s*$'
    call <SID>Autoformat([8,8,8,8,8,16,8,8])
  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*ELEMENT_SEATBELT %\s*$'
    call <SID>Autoformat([10,10,10,10,10,16,10,10])
  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*PARAMETER\s*$' ||
       \ keyword =~? '^\*PARAMETER_LOCAL\s*$'
    call <SID>parameter(a:firstline, a:lastline)
  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*PARAMETER_EXPRESSION\s*$' ||
       \ keyword =~? '^\*PARAMETER_EXPRESSION_LOCAL\s*$'
    call <SID>parameter_expr(a:firstline, a:lastline)
  "-----------------------------------------------------------------------------
  else
    call <SID>Autoformat([10,10,10,10,10,10,10,10])
  endif

endfunction

"-------------------------------------------------------------------------------
"    INTERNAL FUNCTIONS
"-------------------------------------------------------------------------------

function! s:Autoformat(def)

  for lnum in range(s:line1, s:line2)
  
    let line_str = getline(lnum)
    if line_str =~? '^[*$]' | continue | endif
    let line = split(line_str, '\s*,\s*\|\s\+')

    let new_line = ''
    for idx in range(len(line))
      let str_format = '%'..a:def[idx]..'s'
      let new_line ..= printf(str_format, line[idx])
    endfor

    call setline(lnum, new_line)

  endfor  

endfunction

"-------------------------------------------------------------------------------

function! s:parameter(line1, line2)

  " loop over all selected lines
  for i in range(a:line1, a:line2)

    " take current line
    let lineStr = getline(i)
    " ignore keyword and comment line
    if lineStr =~? '^[*$]' | continue | endif
    " remove '&' sign
    let lineStr = substitute(lineStr, '&', '', 'g')
    " split the line
    let line = split(lineStr, '\s*,\s*\|\s\+')

    " prefix exists?
    if len(line) == 3
      let line[0] = toupper(line[0])
      let newLine = printf("%1s%9s%10s",line[0],line[1],line[2])
    " try to guess prefix and add one
    else
      " character
      if line[1] =~? '^\h.*$'
        let newLine = printf("%1s%9s%10s","C",line[0],line[1])
      " integer
      elseif line[1] =~? '^[-+]\?\d\+$'
        let newLine = printf("%1s%9s%10s","I",line[0],line[1])
      " real
      else
        let newLine = printf("%1s%9s%10s","R",line[0],line[1])
      endif
    endif

    " dump new line
    call setline(i, newLine)

  endfor

  " go to next line after the last one
  call cursor(a:line2+1, 0)

endfunction

"-------------------------------------------------------------------------------

function! s:parameter_expr(line1, line2)

  " loop over all selected lines
  for i in range(a:line1, a:line2)

    " take current line
    let lineStr = getline(i)
    " ignore keyword and comment line
    if lineStr =~? '^[*$]' | continue | endif
    " remove '&' sign
    let lineStr = substitute(lineStr, '&', '', 'g')
    " split the line
    let line = split(lineStr, '\s*,\s*\|\s\+')

    " prefix exists?
    if line[0] =~? '^[IR]$'
      let newLine = printf("%1s%9s%1s%1s",toupper(line[0]),line[1]," ",join(line[2:]))
    else
      let newLine = printf("%1s%9s%1s%1s","R",line[0]," ",join(line[1:]))
    endif

    " dump new line
    call setline(i, newLine)

  endfor

  " go to next line after the last one
  call cursor(a:line2+1, 0)

endfunction

"-------------------------------------------------------------------------------

function! s:define_curve(line1, line2)

  " take 1st line current line
  let lineStr = getline(a:line1)
  " split the line
  let line = split(lineStr, '\s*,\s*\|\s\+')

  " format 8x10
  if len(line) !=2 && lineStr !~ ","

    call <SID>Autoformat([10,10,10,10,10,10,10,10])

  " format 2x20
  else

    " get all lines with points
    let points1 = []
    for i in range(a:line1, a:line2)
      let points1 = points1 + split(getline(i), '\s*,\s*\|\s\+')
    endfor

    " remove old lines, keep unnamed register
    let tmpReg = @@
    silent execute a:line1 . "," . a:line2 . "delete"
    let @@ = tmpReg

    " format and dump all points
    let points2 = []
    for i in range(0, len(points1)-1, 2)
      call add(points2, printf("%20s%20s", points1[i], points1[i+1]))
    endfor
    call append(a:line1-1, points2)

  endif

  " go to next line after the last one
  call cursor(a:line2+1, 0)

endfunction

"-------------------------------------EOF---------------------------------------
