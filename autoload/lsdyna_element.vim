"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  27th of September 2016
" Version:      1.1.1
"
" History of change:
"
" v1.1.1
"   - FindPid function with no arguments works as SortPid function
"   - SortPid function removed
" v1.1.0
"   - FindPid function added
"     - *SET_
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
"
function! lsdyna_element#OffsetId(line1, line2, ...)

  "-----------------------------------------------------------------------------
  " Function to offset Ls-Dyna node/element/part ids.
  "
  " Arguments:
  " - a:line1  : first line of selection
  " - a:line2  : last line of selection
  " - ...      : user arguments (operation mode flag, offset)
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  "-----------------------------------------------------------------------------

  " user parameters setup
  if a:0 == 1

    " set default flag
    let arg = "en"
    " get user offset
    let offset = str2nr(a:1)

  elseif a:0 == 2

    " get information what to renumber?
    let argList = []
    for i in range(0, len(a:1))
      if a:1[i] =~? "[nep]"
        call add(argList, a:1[i])
      endif
    endfor
    let arg = join(sort(argList), "")

    " get user offset
    let offset = str2nr(a:2)

  endif

  "-----------------------------------------------------------------------------
  " find keyword
  call search('^\*[a-zA-Z]','bcW')
  let keyword = getline('.')

  "-----------------------------------------------------------------------------
  if keyword =~? "^\*NODE\s*$" || keyword =~? "^\*AIRBAG_REFERENCE_GEOMETRY.*$"

    for lnum in range(a:line1, a:line2)

      " take current line
      let line = getline(lnum)

      " skip comment/keyword lines
      if line =~? "^[$*]"
        continue
      endif

      " dump line with new id
      let newNid = str2nr(line[:7]) + offset
      let newline = printf("%8s", newNid) . line[8:]
      call setline(lnum, newline)

    endfor

  "-----------------------------------------------------------------------------
  elseif keyword =~? "^\*SET_.*$"

    for lnum in range(a:line1, a:line2)

      " take current line
      let line = getline(lnum)

      " skip comment/keyword lines and any line with alphabetic sign (title)
      if line =~? "^[$*]" || line =~? "\\a"
        continue
      endif

      " take current line & remove trailing signs
      let line = substitute(line, "\\s[ 0]*$", "", "")

      " how many columns?
      let cnum = len(line) / 10

      " loop over columns
      let newline = ""
      for i in range(0, cnum-1, 1)

        " get id from current line
        let id = strpart(line,i*10,10)

        " calc new id but skip empty fields
        if id !~ "^\\s\\{10}"
          let id = str2nr(id) + offset
        endif

        " extend new line
        let newline = newline . printf("%10s", id)

      endfor

      " write new line to file
      call setline(lnum, newline)

    endfor

  "-----------------------------------------------------------------------------
  "
  elseif keyword =~? "^\*ELEMENT_MASS\s*$"

    for lnum in range(a:line1, a:line2)

      " take current line
      let line = getline(lnum)

      " skip comment/keyword lines
      if line =~? "^[$*]"
        continue
      endif

      " offset only element id
      if arg == "e"
        let eid = str2nr(line[:7]) + offset
        let nid = str2nr(line[8:15])
        let pid = str2nr(line[33:])
      " offset only node id
      elseif arg == "n"
        let eid = str2nr(line[:7])
        let nid = str2nr(line[8:15]) + offset
        let pid = str2nr(line[33:])
      " offset node and element id
      elseif arg == "p"
        let eid = str2nr(line[:7])
        let nid = str2nr(line[8:15])
        let pid = str2nr(line[33:]) + offset
      elseif arg == "en"
        let eid = str2nr(line[:7]) + offset
        let nid = str2nr(line[8:15]) + offset
        let pid = str2nr(line[33:])
      elseif arg == "ep"
        let eid = str2nr(line[:7]) + offset
        let nid = str2nr(line[8:15])
        let pid = str2nr(line[33:]) + offset
      elseif arg == "np"
        let eid = str2nr(line[:7])
        let nid = str2nr(line[8:15]) + offset
        let pid = str2nr(line[33:]) + offset
      elseif arg == "enp"
        let eid = str2nr(line[:7]) + offset
        let nid = str2nr(line[8:15]) + offset
        let pid = str2nr(line[33:]) + offset
      endif

      " dump line with new id
      let newline = printf("%8s%8s", eid, nid) . line[16:31] . printf("%8s", pid)
      call setline(lnum, newline)

    endfor

  "-----------------------------------------------------------------------------

  elseif keyword =~? "^\*ELEMENT_.*$" || keyword =~? "^\*AIRBAG_SHELL_REFERENCE_GEOMETRY.*$"

    for lnum in range(a:line1, a:line2)

      " get line
      let line = getline(lnum)

      " skip comment/keyword lines
      if line =~? "^[$*]"
        continue
      endif

      " take current line & remove trailing signs
      let line = substitute(line, "\\s[ 0]*$", "", "")
      " set line length
      let llen = len(line)

      " number of columns
      let cnum = llen / 8

      " loop over columns
      for i in range(0, cnum-1, 1)

        " slice index
        let s = i * 8
        " get line slice
        let slice = strpart(line,s,8)

        "-----------------------------------------------------------------------
        " offset only nodes
        if arg == "e"
          if i == 0
            let newId = str2nr(slice) + offset
          else
            let newId = slice
          endif
        " offset only elements
        elseif arg == "n"
          if i >= 2 && str2nr(slice) != 0
            let newId = str2nr(slice) + offset
          else
            let newId = slice
          endif
        " offset only parts
        elseif arg == "p"
          if i == 1
            let newId = str2nr(slice) + offset
          else
            let newId = slice
          endif
        " offset node/elements id
        elseif arg == "en"
          if i == 1 || str2nr(slice) == 0
            let newId = slice
          else
            let newId = str2nr(slice) + offset
          endif
        " offset elements/parts id
        elseif arg == "ep"
          if i <= 1
            let newId = str2nr(slice) + offset
          else
            let newId = slice
          endif
        " offset node/parts id
        elseif arg == "np"
          if i == 0 || str2nr(slice) == 0
            let newId = slice
          else
            let newId = str2nr(slice) + offset
          endif
        " offset nodes/parts/elements id
        elseif arg == "enp"
            if str2nr(slice) == 0
              let newId = slice
            else
              let newId = str2nr(slice) + offset
            endif
        endif
        "-----------------------------------------------------------------------

        " update line with new values
        let line = strpart(line,0,s) . printf("%8s", newId) . strpart(line,s+8)

      endfor

      " dump new line
      call setline(lnum, line)

    endfor

  endif

  " restore cursor position
  call cursor(a:line1, 0)

endfunction

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
"
function! lsdyna_element#FindPid(line1, line2, ...)

  "-----------------------------------------------------------------------------
  " Function to sort/find elements with specific part id in element table.
  "
  " Arguments:
  " - a:line1 : first line of selection
  " - a:line2 : last line of selection
  " - ...     : user part ids
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  "-----------------------------------------------------------------------------
  " if no arguments just sort element table with pids

  if len(a:000) == 0

    " loop over element lines
    let lnum = a:line1
    let endline = a:line2
    while (lnum <= endline)

      " write header for 1st part in the list
      if (lnum == a:line1)
        let str = '$ Part: ' . getline(lnum)[8:15]
        call append(lnum-1, str)
        let lnum += 1
        continue
      endif

      " take current and next line
      let line1 = getline(lnum)
      let line2 = getline(lnum+1)

      " compare part ids and put header line if not the same
      if (line1[8:15] !~? line2[8:15])
        " add header with part id
        let str = '$ Part: ' . line2[8:15]
        call append(lnum, str)
        " one more line to complete whole loop
        let endline += 1
        " two extra line to skip header I just added
        let lnum += 2
        continue
      endif

      " move to next line (not used if I added header)
      let lnum += 1

      endwhile

  else
  "-----------------------------------------------------------------------------
  " find only specific pids

    " take user pids
    let pids = []
    for arg in a:000
      if match(arg, ":") != -1
        let ids = split(arg, ":")
        for i in range(ids[0], ids[1])
          call add(pids, i)
        endfor
      else
        call add(pids, str2nr(arg))
      endif
    endfor

    " sort pids
    let pids = sort(pids, 'lsdyna_element#NumbersCompare')

    " set last line from selection
    let lend = a:line2

    " sort lines respect to part id
    execute a:line1 . ',' . a:line2 . 'sort /\%9c\(\s\|\d\)\{8}/ r'

    " set cursor position to start search
    call cursor(a:line1-1, 0)

    " loop over part ids
    for pid in pids

      " find current pid
      let snum = 8 - len(pid)
      let regexp = '^.\{8}\s\{'. snum . '}'  . pid
      let match = search(regexp, '', lend)

      " found pid
      if (match != 0)

        " put header
        call append(match-1, '$ Part: ' . pid)

        " find end of range
        call cursor(lend+2, 0)
        call append(search(regexp, 'b', a:line1), '$')

        " for every pid I found two extra lines are added
        let lend = lend + 2

      endif

    endfor

  endif

endfunction

function! lsdyna_element#NumbersCompare(i1, i2)
   return a:i1 - a:i2
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

  " lines loop
  for lnum in range(a:line1, a:line2)

    " take current line
    let line = getline(lnum)

    " skip comment/keyword lines
    if line =~? "^[$*]"
      continue
    endif

    " get element definition
    let eid = line[0:7]
    let pid = line[8:15]
    let n1  = line[16:23]
    let n2  = line[24:31]
    let n3  = line[32:39]
    let n4  = line[40:47]

    " revers tria element
    if str2nr(n3) == str2nr(n4)
      let newline = printf("%8s%8s%8s%8s%8s%8s", eid, pid, n1, n3, n2, n2)
    " revers quad element
    else
      let newline = printf("%8s%8s%8s%8s%8s%8s", eid, pid, n1, n4, n3, n2)
    endif

    " dump line with new element definition
    call setline(lnum, newline)

  endfor

  " restore cursor position
  call cursor(a:line1, 0)

endfunction

"-------------------------------------EOF---------------------------------------
