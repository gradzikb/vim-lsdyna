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

function! library#CompleteKeywords(findstart, base)

  "-----------------------------------------------------------------------------
  " User completion function used with keyword library.
  "
  " Arguments:
  " - see :help complete-functions
  " Return:
  " - see :help complete-functions
  "-----------------------------------------------------------------------------

  " run for first function call
  if a:findstart

    " find completion start
    if getline('.')[0] == "*"
      return 1
    else
      return 0
    endif

  else

    " get list of files in the library
    let keylibrary = split(globpath(g:lsdynaKeyLibPath, '*'))
    " keep only file names
    call map(keylibrary, 'fnamemodify(v:val, ":t")')

    " completion loop
    let compKeywords = []
    for key in keylibrary
      if key =~? '^' . a:base
        call add(compKeywords, key)
      endif
    endfor

    " set completion flag
    let b:lsDynaUserComp = 1
    " return list after completion
    return compKeywords

  endif

endfunction

"-------------------------------------------------------------------------------

function! library#GetCompletion()

  "-----------------------------------------------------------------------------
  " Function to take keyword name from current line and insert keyword
  " definition from the library.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " save unnamed register
  let tmpUnnamedReg = @@

  " get keyword from current line
  if getline('.')[0] == "*"
    let keyword = tolower(strpart(getline('.'), 1))
  else
    let keyword = tolower(strpart(getline('.'), 0))
  endif
  " set keyword file path
  let file = g:lsdynaKeyLibPath . keyword

  " check if the file exist and put it
  if filereadable(file)
   execute "read " . file
   normal! kdd
   " jump to first dataline under the keyword
   call search("^[^$]\\|^$")
  else
    normal! <C-Y>
  endif

  " restore unnamed register
  let @@ = tmpUnnamedReg

  " reset completion flag
  let b:lsDynaUserComp = 0

endfunction

"-------------------------------------EOF---------------------------------------
