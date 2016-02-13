"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  13th of February 2016
" Version:      1.0.1
"
" History of change:
"
" v1.0.1
"   - *PARAMETER formating improved
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_autoformat#LsDynaLine() range

  "-----------------------------------------------------------------------------
  " Function to autformat Ls-Dyna line.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " find keyword
  call search('^\*[a-zA-Z]','b')
  let keyword = getline('.')

  "-----------------------------------------------------------------------------
  if keyword =~? "*DEFINE_CURVE.*$"

    let line = getline(a:firstline)
    let lenLine = len(split(line, '\s*,\s*\|\s\+'))

    " format 8x10 (first line under the keyword)
    if lenLine !=2 && line !~ ","

      let oneline = split(getline(a:firstline))
      for j in range(len(oneline))
        let oneline[j] = printf("%10s", oneline[j])
      endfor
      call setline(a:firstline, join(oneline, ""))
      call cursor(a:firstline, 0)

    " format 2x20
    else

      " get all lines with points
      let points = []
      for i in range(a:firstline, a:lastline)
        let points = points + split(getline(i), '\s*,\s*\|\s\+')
      endfor

      " remove old lines
      execute a:firstline . "," . a:lastline . "delete"
      normal! k

      " save new lines
      for i in range(0, len(points)-1, 2)
        let newLine = printf("%20s%20s", points[i], points[i+1])
        normal! o
        call setline(".", newLine)
      endfor

      call cursor(a:firstline+1, 0)

    endif

  "-----------------------------------------------------------------------------
  elseif keyword =~? "*NODE *$"

      for i in range(a:firstline, a:lastline)
        let line = split(getline(i))
        let newLine = printf("%8s%16s%16s%16s",line[0],line[1],line[2],line[3])
        call setline(i, newLine)
      endfor
      call cursor(a:lastline+1, 0)

  "-----------------------------------------------------------------------------
  elseif keyword =~? "*ELEMENT_SHELL *$" ||
       \ keyword =~? "*ELEMENT_SOLID *$" ||
       \ keyword =~? "*ELEMENT_BEAM *$" ||
       \ keyword =~? "*ELEMENT_PLOTEL *$"

      for i in range(a:firstline, a:lastline)
        let line = split(getline(i))
        for j in range(len(line))
          let line[j] = printf("%8s", line[j])
        endfor
        call setline(i, join(line, ""))
      endfor
      call cursor(a:lastline+1, 0)

  "-----------------------------------------------------------------------------
  elseif keyword =~? "*ELEMENT_MASS *$"

      for i in range(a:firstline, a:lastline)
        let line = split(getline(i))
        for j in range(len(line))
          if j == 2
            let line[j] = printf("%16s", line[j])
          else
            let line[j] = printf("%8s", line[j])
          endif
        endfor
        call setline(i, join(line, ""))
      endfor
      call cursor(a:lastline+1, 0)

  "-----------------------------------------------------------------------------
  elseif keyword =~? "*ELEMENT_MASS_PART.*$"

      for i in range(a:firstline, a:lastline)
        let line = split(getline(i))
        for j in range(len(line))
          if j == 0
            let line[j] = printf("%8s", line[j])
          else
            let line[j] = printf("%16s", line[j])
          endif
        endfor
        call setline(i, join(line, ""))
      endfor
      call cursor(a:lastline+1, 0)

  "-----------------------------------------------------------------------------
  elseif keyword =~? "*ELEMENT_DISCRETE *$"

      for i in range(a:firstline, a:lastline)
        let line = split(getline(i))
        for j in range(len(line))
          if j == 5 || j == 7
            let line[j] = printf("%16s", line[j])
          else
            let line[j] = printf("%8s", line[j])
          endif
        endfor
        call setline(i, join(line, ""))
      endfor
      call cursor(a:lastline+1, 0)

  "-----------------------------------------------------------------------------
  elseif keyword =~? "*ELEMENT_SEATBELT *$"

      for i in range(a:firstline, a:lastline)
        let line = split(getline(i))
        for j in range(len(line))
          if j == 5
            let line[j] = printf("%16s", line[j])
          else
            let line[j] = printf("%8s", line[j])
          endif
        endfor
        call setline(i, join(line, ""))
      endfor
      call cursor(a:lastline+1, 0)

  "-----------------------------------------------------------------------------
  elseif keyword =~? "*PARAMETER *$" ||
       \ keyword =~? "*PARAMETER_LOCAL *$"

     for i in range(a:firstline, a:lastline)

       " take a line
       let line = split(getline(i))

       echo line
       " prefix exists?
       if len(line) == 3
         let line[0] = toupper(line[0])
         let newLine = printf("%1s%9s%10s",line[0],line[1],line[2])
       " try to guess prefix and add one
       else
         " integer
         if line[1] =~? '^[-+]\?\d\+$'
           let newLine = printf("%1s%9s%10s","I",line[0],line[1])
         " real
         elseif line[1] =~? '\d\.\?\d\?[eE][+-]\?\d'
           let newLine = printf("%1s%9s%10s","R",line[0],line[1])
         " character
         else
           let newLine = printf("%1s%9s%10s","C",line[0],line[1])
         endif
       endif

       " dump new line
       call setline(i, newLine)

     endfor

     call cursor(a:lastline+1, 0)

  "-----------------------------------------------------------------------------
  elseif keyword =~? "*PARAMETER_EXPRESSION\s*$" ||
       \ keyword =~? "*PARAMETER_EXPRESSION_LOCAL\s*$"

     for i in range(a:firstline, a:lastline)

       " take a line
       let line = split(getline(i))

       " prefix exists?
       if line[0] =~? '^[IR]$'
         let line[0] = toupper(line[0])
         let newLine = printf("%1s%9s%1s%1s",line[0],line[1]," ",join(line[2:]))
       else
         " real
         if join(line[1:]) =~? '\.'
           let newLine = printf("%1s%9s%1s%1s","R",line[0]," ",join(line[1:]))
         " integer
         else
           let newLine = printf("%1s%9s%1s%1s","I",line[0]," ",join(line[1:]))
         endif
       endif

       " dump new line
       call setline(i, newLine)

     endfor

     call cursor(a:lastline+1, 0)

  "-----------------------------------------------------------------------------
  " standart format line (8x10)
  " allow to use coma as empty col
  else

    for i in range(a:firstline, a:lastline)
      let line = split(getline(i))
      for j in range(len(line))
        let fStr = "%10s"
        if line[j] =~# ","
          if len(line[j]) !=# 1
            let fStr = "%" . line[j][:-2] . "0s"
          endif
          let line[j] = printf(fStr, "")
        else
          let line[j] = printf(fStr, line[j])
        endif
      endfor
      call setline(i, join(line, ""))
    endfor
    call cursor(a:lastline+1, 0)

  endif
endfunction

"-------------------------------------EOF---------------------------------------
