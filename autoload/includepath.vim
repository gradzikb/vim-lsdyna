"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  12th of August 2014
"
"-------------------------------------------------------------------------------

function! includepath#IncludePath()

  "-----------------------------------------------------------------------------
  " Function to scan Ls-Dyna keyword file for *INCLUDE_PATH keywords and extend
  " VIM path variable with new paths.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " store start position
  let startlnum = line('.')

  " store number of last line in the file
  let lastlnum = line('$')

  " jump to beginning of the file / start position for search
  normal! gg0

  " loop over the file (used to find all *INCLUDE_PATH)
  while 1

    " find *INCLUDE_PATH and store line number
    let lnumFind = search("\\c^\*INCLUDE_PATH.*$", 'cW')

    "found nothing -> stop loop
    if lnumFind == 0 | break | endif

    "move to next line, line after *INCLUDE_PATH
    normal! j

    " loop over *INCLUDE_PATH (used to collect all paths)
    while 1

       " get current line
       let line = getline(".")

       " keyword line -> break loop
       if line =~? "^\*"
         break
       " use lines which do not start with comment sign
       elseif line =~? "^[^$]"
         "----------------------------------------------------------------------
         " substitution (\ -> /) is made according to :help path
         " - Careful with '\' characters, type two to get one in the option:
         " :set path=.,c:\\include
         " Or just use '/' instead:
         " :set path=.,c:/include
         "----------------------------------------------------------------------
         let line = substitute(line, "\\", "/", "g")
         " add new path only if does not exist yet
         if match(&path, line) == -1
           let &path = &path . "," . line
         endif
       endif

       "last line in the file ? -> stop loop
       if line(".") == lastlnum | break | endif

       " go to next line
       normal! j

    endwhile

  endwhile

  " restore start position
  call cursor(startlnum, 0)

endfunction

"-------------------------------------EOF---------------------------------------
