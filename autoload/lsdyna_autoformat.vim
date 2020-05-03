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

  " find keyword
  let keyword = getline(search('^\*\a','bcnW'))

  "-----------------------------------------------------------------------------
  if keyword =~? "*DEFINE_CURVE.*$"

    call lsdyna_autoformat#define_curve(a:firstline, a:lastline)

  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*NODE\s*$' ||
       \ keyword =~? '^\*AIRBAG_REFERENCE_GEOMETRY\s*$'

    call lsdyna_autoformat#node(a:firstline, a:lastline)

  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*ELEMENT_PLOTEL\s*$' ||
       \ keyword =~? '^\*ELEMENT_BEAM\s*$' ||
       \ keyword =~? '^\*ELEMENT_SHELL\s*$' ||
       \ keyword =~? '^\*ELEMENT_SOLID\s*$' ||
       \ keyword =~? '^\*AIRBAG_SHELL_REFERENCE_GEOMETRY\s*$'

    call lsdyna_autoformat#element(a:firstline, a:lastline)

  "-----------------------------------------------------------------------------
  elseif keyword =~? '\*ELEMENT_MASS\s*$'

    call lsdyna_autoformat#element_mass(a:firstline, a:lastline)

  "-----------------------------------------------------------------------------
  elseif keyword =~? '\*ELEMENT_MASS_PART.*$'

    call lsdyna_autoformat#element_mass_part(a:firstline, a:lastline)

  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*ELEMENT_DISCRETE\s*$'

    call lsdyna_autoformat#element_discrete(a:firstline, a:lastline)

  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*ELEMENT_SEATBELT\s*$'

    call lsdyna_autoformat#element_seatbelt(a:firstline, a:lastline)

  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*PARAMETER\s*$' ||
       \ keyword =~? '^\*PARAMETER_LOCAL\s*$'

    call lsdyna_autoformat#parameter(a:firstline, a:lastline)

  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*PARAMETER_EXPRESSION\s*$' ||
       \ keyword =~? '^\*PARAMETER_EXPRESSION_LOCAL\s*$'

    call lsdyna_autoformat#parameter_expr(a:firstline, a:lastline)

  "-----------------------------------------------------------------------------
  else

    call lsdyna_autoformat#keyword(a:firstline, a:lastline)

  endif

endfunction

"-------------------------------------------------------------------------------
"    INTERNAL FUNCTIONS
"-------------------------------------------------------------------------------

function! lsdyna_autoformat#node(line1, line2)

  " loop over all selected lines
  for i in range(a:line1, a:line2)

    " take current line
    let lineStr = getline(i)
    " ignore keyword and comment line
    if lineStr =~? '^[*$]' | continue | endif
    " split the line
    let line = split(lineStr, '\s*,\s*\|\s\+')

    " loop inside line
    for j in range(len(line))
      if j == 1 || j == 2 || j == 3
        let line[j] = printf("%16s", line[j])
      else
        let line[j] = printf("%8s", line[j])
      endif
    endfor
    call setline(i, join(line, ""))

  endfor

  " go to next line after the last one
  call cursor(a:line2+1, 0)

endfunction

"-------------------------------------------------------------------------------
"
function! lsdyna_autoformat#element(line1, line2)

  " loop over all selected lines
  for i in range(a:line1, a:line2)

    " take current line
    let lineStr = getline(i)
    " ignore keyword and comment line
    if lineStr =~? '^[*$]' | continue | endif
    " split the line
    let line = split(lineStr, '\s*,\s*\|\s\+')

    " set 8 length string for each item
    call map(line, 'printf("%8s", v:val)')
    " dump the line
    call setline(i, join(line, ""))

  endfor

  " go to next line after the last one
  call cursor(a:line2+1, 0)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_autoformat#element_discrete(line1, line2)

  " loop over all selected lines
  for i in range(a:line1, a:line2)

    " take current line
    let lineStr = getline(i)
    " ignore keyword and comment line
    if lineStr =~? '^[*$]' | continue | endif
    " split the line
    let line = split(lineStr, '\s*,\s*\|\s\+')

    " loop inside line
    for j in range(len(line))
      if j == 5 || j == 7
        let line[j] = printf("%16s", line[j])
      else
        let line[j] = printf("%8s", line[j])
      endif
    endfor
    call setline(i, join(line, ""))

  endfor

  " go to next line after the last one
  call cursor(a:line2+1, 0)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_autoformat#element_seatbelt(line1, line2)

  " loop over all selected lines
  for i in range(a:line1, a:line2)

    " take current line
    let lineStr = getline(i)
    " ignore keyword and comment line
    if lineStr =~? '^[*$]' | continue | endif
    " split the line
    let line = split(lineStr, '\s*,\s*\|\s\+')

    " loop inside line
    for j in range(len(line))
      if j == 5
        let line[j] = printf("%16s", line[j])
      else
        let line[j] = printf("%8s", line[j])
      endif
    endfor
    call setline(i, join(line, ""))

  endfor

  " go to next line after the last one
  call cursor(a:line2+1, 0)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_autoformat#element_mass(line1, line2)

  " loop over all selected lines
  for i in range(a:line1, a:line2)

    " take current line
    let lineStr = getline(i)
    " ignore keyword and comment line
    if lineStr =~? '^[*$]' | continue | endif
    " split the line
    let line = split(lineStr, '\s*,\s*\|\s\+')

    " loop inside line
    for j in range(len(line))
      if j == 2
        let line[j] = printf("%16s", line[j])
      else
        let line[j] = printf("%8s", line[j])
      endif
    endfor
    call setline(i, join(line, ""))

  endfor

  " go to next line after the last one
  call cursor(a:line2+1, 0)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_autoformat#element_mass_part(line1, line2)

  " loop over all selected lines
  for i in range(a:line1, a:line2)

    " take current line
    let lineStr = getline(i)
    " ignore keyword and comment line
    if lineStr =~? '^[*$]' | continue | endif
    " split the line
    let line = split(lineStr, '\s*,\s*\|\s\+')

    " loop inside line
    for j in range(len(line))
      if j == 0
        let line[j] = printf("%8s", line[j])
      else
        let line[j] = printf("%16s", line[j])
      endif
    endfor
    call setline(i, join(line, ""))

  endfor

  " go to next line after the last one
  call cursor(a:line2+1, 0)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_autoformat#parameter(line1, line2)

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

function! lsdyna_autoformat#parameter_expr(line1, line2)

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

function! lsdyna_autoformat#keyword(line1, line2)

  " loop over all selected lines
  for i in range(a:line1, a:line2)

    " take current line
    let lineStr = getline(i)
    " ignore keyword and comment line
    if lineStr =~? '^[*$]' | continue | endif
    " split the line, decide to keep empty item at the beginning
    if lineStr =~? '^\s*,'
      let line = split(lineStr, '\s*,\s*\|\s\+', 1)
    else
      let line = split(lineStr, '\s*,\s*\|\s\+', 0)
    endif

    " set 10 length string for each item
    call map(line, 'printf("%10s", v:val)')
    " dump the line
    call setline(i, join(line, ""))


  endfor

  " go to next line after the last one
  call cursor(a:line2+1, 0)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_autoformat#define_curve(line1, line2)

  " take 1st line current line
  let lineStr = getline(a:line1)
  " split the line
  let line = split(lineStr, '\s*,\s*\|\s\+')

  " format 8x10
  if len(line) !=2 && lineStr !~ ","

    call lsdyna_autoformat#keyword(a:line1, a:line1)

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
