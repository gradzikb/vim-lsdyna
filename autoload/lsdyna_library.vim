"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  23th of March 2016
"
"-------------------------------------------------------------------------------
"
" v1.2.1
"   - function GetCompletion updated
"     - search function do not wrap around a file
"     - code clean up
" v1.2.0
"   - new library structure supported (with subdirectories inside)
" v1.1.0
"   - library initialization function added
" v1.0.1
"   - new library structure supported (with subdirectories inside)
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_library#initLib(path)

  "-----------------------------------------------------------------------------
  " Function to initialize Ls-Dyna keyword library.
  "
  " Arguments:
  " - path (string) : path to directory with keyword files
  " Return:
  " - keyLib (dict) : keywords list
  "-----------------------------------------------------------------------------

  " get list of files in the library
  let keyLib = split(globpath(a:path, '**/*.k'))
  " keep only file names without extension
  call map(keyLib, 'fnamemodify(v:val, ":t:r")')

  return keyLib

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_library#CompleteKeywords(findstart, base)

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

    " completion loop
    let compKeywords = []
    for key in g:lsdynaKeyLib
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

function! lsdyna_library#GetCompletion()

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
    let keyword = tolower(getline('.')[1:])
  else
    let keyword = tolower(getline('.')[0:])
  endif

  " extract sub directory name from keyword name
  if keyword =~? "^\*"
    "let KeyLibSubDir = matchstr(keyword, "^.\\{-}\\ze_", 0) . "/"
    let KeyLibSubDir = keyword[1] . "/"
  else
    let KeyLibSubDir = keyword[0] . "/"
  endif

  " set keyword file path
  let file = g:lsdynaKeyLibPath . KeyLibSubDir . keyword . ".k"

  " check if the file exist and put it
  if filereadable(file)
   execute "read " . file
   normal! kdd
   " jump to first dataline under the keyword
   call search("^[^$]\\|^$", "W")
  else
    normal! <C-Y>
  endif

  " restore unnamed register
  let @@ = tmpUnnamedReg

  " reset completion flag
  let b:lsDynaUserComp = 0

endfunction

"-------------------------------------EOF---------------------------------------
