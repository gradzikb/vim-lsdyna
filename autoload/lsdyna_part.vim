"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  13th of December 2015
" Version:      1.0.0
"
" History of change:
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_part#ChangePID(line1, line2, ...)

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
  echom "LsDynaChangePID: " . counter . " element(s) updated."

endfunction

"-------------------------------------EOF---------------------------------------
