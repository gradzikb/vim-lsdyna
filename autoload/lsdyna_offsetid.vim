"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  8th of November 2015
" Version:      1.0.2
"
" History of change:
"
" v1.0.3
"   - search pattern for keyword improved
"   - *ELEMENT_MASS support
" v1.0.2
"   - incorrect argument behaviour fixed
"   - comment lines are ignored
"   - keyword lines are ignored
"   - zero values at the end of element line are ignored
" v1.0.1
"   - trailing spaces in line are ignored
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_offsetid#OffsetId(line1, line2, ...)

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
    let arg = "DEFAULT"
    " get user offset
    let offset = str2nr(a:1)

  elseif a:0 == 2

    " check user arguments
    if a:1 == "-n"
      let arg = "NODE"
    elseif a:1 == "-e"
      let arg = "ELEMENT"
    elseif a:1 == "-p"
      let arg = "PART"
    elseif a:1 == "-a"
      let arg = "ALL"
    endif

    " get user offset
    let offset = str2nr(a:2)

  endif

  "-----------------------------------------------------------------------------
  " find keyword
  call search('^\*[a-zA-Z]','bcW')
  let keyword = getline('.')

  "-----------------------------------------------------------------------------
  if keyword =~? "^\*NODE\s*$"

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

      " dump line with new id
      let eid = str2nr(line[:7]) + offset
      let nid = str2nr(line[8:15]) + offset
      let newline = printf("%8s%8s", eid, nid) . line[16:]
      call setline(lnum, newline)

    endfor

  "-----------------------------------------------------------------------------

  elseif keyword =~? "^\*ELEMENT_.*$"

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

        "-----------------------------------------------------------------------
        if arg == "DEFAULT"
        " offset node/elements id
          if i == 1
            let newId = strpart(line,s,8)
          else
            let newId = str2nr(strpart(line,s,8)) + offset
          endif
        elseif arg == "ELEMENT"
          " offset only nodes
          if i == 0
            let newId = str2nr(strpart(line,s,8)) + offset
          else
            let newId = strpart(line,s,8)
          endif
        elseif arg == "NODE"
          " offset only elements
          if i >= 2
            let newId = str2nr(strpart(line,s,8)) + offset
          else
            let newId = strpart(line,s,8)
          endif
        elseif arg == "PART"
          " offset only parts
          if i == 1
            let newId = str2nr(strpart(line,s,8)) + offset
          else
            let newId = strpart(line,s,8)
          endif
        elseif arg == "ALL"
          " offset all entities
            let newId = str2nr(strpart(line,s,8)) + offset
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

"-------------------------------------EOF---------------------------------------
