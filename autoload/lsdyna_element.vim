"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  12th of December 2016
" Version:      1.0.1
"
" History of change:
"
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

function! lsdyna_element#Sort(line1, line2, ...)

  "-----------------------------------------------------------------------------
  " Function sort Ls-Dyna elements in order of part id.
  "
  " Arguments:
  " - a:line1 : first line of selection
  " - a:line2 : last line of selection
  " - a:1     : user part id
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " sort lines respect to part id
  execute a:line1 . ',' . a:line2 . 'sort /\%9c\(\s\|\d\)\{8}/ r'


    " search for all part ids
    if a:0 == 0

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

    " search only for user part id
    else

      " user part id
      let userPid = str2nr(a:1)

      " loop over element lines
      let lnum = a:line1
      let endline = a:line2
      let pid = 0
      while (lnum <= endline)

        " take line
        let line1 = getline(lnum)

        " compare part ids and put header line
        if (pid ==0 && str2nr(line1[8:15]) == userPid)
          " add header with part id
          let str = '$ Part: ' . line1[8:15]
          call append(lnum-1, str)
          let pid = 1
          " one more line to complete whole loop
          let endline += 1
        endif

        " add end break
        if (pid == 1 && line1[8:15] !~? a:1)
          call append(lnum-1, '$')
          break
        endif

        " move to next line (not if I added header)
        let lnum += 1

      endwhile

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
