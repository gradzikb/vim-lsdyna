"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  6th of April 2017
" Version:      1.1.3
"
" History of change:
"
" v1.1.3
"   - FindPid function fixed
" v1.1.2
"   - offset function moved to lsdyna_offset
" v1.1.2
"   - element offset improved for *ELEMENT_BEAM
"   - element offset improved for *ELEMENT_MASS
" v1.1.1
"   - FindPid function with no arguments works as SortPid function
"   - SortPid function removed
" v1.1.0
"   - FindPid function added
" v1.0.2
"   - OffsetId function support new keywords:
"     - *SET_
" v1.0.1
"   - OffsetId function support new keywords:
"     - *AIRBAG_SHELL_REFERENCE_GEOMETRY
"     - *AIRBAG_REFERENCE_GEOMETRY
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_element#ChangePid(line1, line2, ...)

  "-----------------------------------------------------------------------------
  " Function to change part id.
  "
  " Arguments:
  " - a:line1  : first line of selection
  " - a:line2  : last line of selection
  " - ...      : user arguments
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " user parameters setup
  if a:0 == 1

    let newPID = a:1
    " add "&" if needed
    if newPID[0] =~ '\h'
      let newPID = "&" . substitute(newPID, '^\s*', "", "")
    endif

  elseif a:0 == 2

    " set old part id
    let oldPID = a:1
    " add "&" if needed
    if oldPID[0] =~ '\h'
      let oldPID = "&" . substitute(oldPID, '^\s*', "", "")
    endif

    " set new part id
    let newPID = a:2
    " add "&" if needed
    if newPID[0] =~ '\h'
      let newPID = "&" . substitute(newPID, '^\s*', "", "")
    endif

  endif

  " set counter
  let counter = 0

  " loop over all selected lines
  for lnum in range(a:line1, a:line2)

    " take current line
    let line = getline(lnum)

    " skip comment/keyword lines
    if line =~? "^[$*]"
      continue
    endif

    " chnage all PIDs
    if a:0 == 1

      let newline = line[:7] . printf("%8s", newPID) . line[16:]

    " change only user PIDs
    elseif a:0 == 2

      " what am I comparing?
      " number vs number
      if oldPID =~ '^\s*\d'

        if str2nr(line[8:15]) == str2nr(oldPID)
          let newline = line[:7] . printf("%8s", newPID) . line[16:]
        else
          continue
        endif

      " paramter vs parameter
      else

        if line[8:15] =~? oldPID
          let newline = line[:7] . printf("%8s", newPID) . line[16:]
        else
          continue
        endif
      endif

    endif

    " dump new line
    call setline(lnum, newline)

    " update counter
    let counter = counter + 1

  endfor

  " restore cursor position
  call cursor(a:line1, 0)

  " print message
  echom counter . " element(s) updated."

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_element#FindPid(line1, line2, ...)

  " find keyword name
  let kwName = getline(search('^\*','bcnW'))

  " i10 format
  if kwName =~? '%\s*$'
    let a = 10
    let z = 19
  " i20 format
  elseif kwName =~? '+\s*$'
    let a = 20
    let z = 39
  " i8 format
  else
    let a = 8
    let z = 15
  endif

  "-----------------------------------------------------------------------------
  " get all element line data and collect them by part ids

  let pids = {} " dict with elements grouped by part ids 
  let lines = getline(a:line1, a:line2)
  if kwName =~? 'THICKNESS\|BETA\|MCID\|OFFSET\|DOF\|COMPOSITE'
    for i in range(0, len(lines)-1, 2)
      let pid = trim(lines[i][a : z])
      if !has_key(pids, pid) | let pids[pid] = [] | endif
      call add(pids[pid], lines[i])
      call add(pids[pid], lines[i+1])
    endfor
  else
    for i in range(0, len(lines)-1, 1)
      let pid = trim(lines[i][a : z])
      if !has_key(pids, pid) | let pids[pid] = [] | endif
      call add(pids[pid], lines[i])
    endfor
  endif

  "-----------------------------------------------------------------------------
  " do stuff if no command arguments
  if a:0 == 0

    " sort all elements lines by pid and write them to file
    let lines_to_write = []
    for key in sort(keys(pids))
      call add(lines_to_write, '$ Part: '.key)
      call extend(lines_to_write, pids[key])
    endfor
    execute a:line1.','.a:line2.'delete'
    call append(a:line1-1, lines_to_write)

  "-----------------------------------------------------------------------------
  " do stuff if command arguments
  else

    " take user pids from command arguments
    " LsElemFindPid 1 5 10:20
    let user_pids = []
    for arg in a:000
      if match(arg, ":") != -1
        let ids = split(arg, ":")
        for i in range(ids[0], ids[1])
          call add(user_pids, i)
        endfor
      else
        call add(user_pids, arg)
      endif
    endfor

    let lines_to_write = [] " here I will store all lines to write to file

    " process pids I want to find
    for key in sort(user_pids)
      if has_key(pids, key)
        call add(lines_to_write, '$ Part: '.key)
        call extend(lines_to_write, pids[key])
        call remove(pids, key)
      endif
    endfor 

    "process other pids
    call add(lines_to_write, '$')
    for key in keys(pids)
      call extend(lines_to_write, pids[key])
    endfor

    " finally delete old lines and write a new ones
    execute a:line1.','.a:line2.'delete'
    call append(a:line1-1, lines_to_write)

  endif

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_element#ReverseNormals(line1, line2)

  "-----------------------------------------------------------------------------
  " Function to revers element normals.
  "
  " Arguments:
  " - a:line1  : first line of selection
  " - a:line2  : last line of selection
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " find keyword name
  let kwName = getline(search('^\*','bcnW'))
  " i10 format
  if kwName =~? '%\s*$'
    let len = 10
    let format = '%10s%10s%10s%10s%10s%10s'
  " i20 format
  elseif kwName =~? '+\s*$'
    let len = 20
    let format = '%20s%20s%20s%20s%20s%20s'
  " i8 format
  else
    let len = 8
    let format = '%8s%8s%8s%8s%8s%8s'
  endif

  " lines loop
  for lnum in range(a:line1, a:line2)

    " take current line
    let line = getline(lnum)
    " skip comment/keyword lines
    if line =~? "^[$*]" | continue | endif
    " split lines into columns
    let l = []
    for i in range(0,5,1)
      let l += [strpart(line, i*len, len)]
    endfor

    " revers tria element
    if str2nr(l[4]) == str2nr(l[5])
      "let newline = printf(format, eid, pid, n1, n3, n2, n2)
      let newline = printf(format, l[0], l[1], l[2], l[4], l[3], l[3])
    " revers quad element
    else
      "let newline = printf(format, eid, pid, n1, n4, n3, n2)
      let newline = printf(format, l[0], l[1], l[2], l[5], l[4], l[3])
    endif

    " dump line with new element definition
    call setline(lnum, newline)

  endfor

  " restore cursor position
  call cursor(a:line1, 0)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_element#ConvertI8I10(line1, line2, ...) abort

  "-----------------------------------------------------------------------------
  " Function to convert I8 definition to I10.
  "
  " Arguments:
  " - a:line1  : first line of selection
  " - a:line2  : last line of selection
  " - ...      : conversion type i8->i10 or i10->i8
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  if a:0 == 0
    echo 'Missing arguments.'
    return
  endif

  " set column length
  if a:1 == 'i10'
    let clen = 8
    let format = '%10s'
  elseif a:1 == 'i8'
    let clen = 10
    let format = '%8s'
  endif

  " lines loop
  for lnum in range(a:line1, a:line2)

    let line = getline(lnum)
    if line =~? '^\*ELEMENT'
      silent execute 's/\s%\s*$//e'
      if a:1 == 'i10'
        execute "normal! A %\<ESC>"
      endif
    endif
    if line =~? "^[$*]" | continue | endif

    let new_line = ''
    for i in range(8)
      let col = strpart(line, i*clen, clen)
      if empty(col) | break | endif " end of the line
      let new_line ..= printf(format, trim(col))
    endfor

    call setline(lnum, new_line)

  endfor

endfunction

"-------------------------------------EOF---------------------------------------
