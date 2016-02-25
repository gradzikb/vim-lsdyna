"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  28th of December 2015
"
" History of change:
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_include#CollectPaths()

  "-----------------------------------------------------------------------------
  " Function to scan Ls-Dyna keyword file for *INCLUDE_PATH keywords.
  "
  " Arguments:
  " - None
  " Return:
  " - paths : list of paths
  "-----------------------------------------------------------------------------

  " initialize empty list for paths
  let paths = []

  " store start position
  let startlnum = line('.')

  " store number of last line in the file
  let lastlnum = line('$')

  " jump to beginning of the file / start position for search
  normal! gg0

  " loop over the file (used to find all *INCLUDE_PATH)
  while 1

    " find *INCLUDE_PATH and store line number
    let lnumFind = search("\\c^\\*INCLUDE_PATH.*$", 'cW')

    "found nothing -> stop loop
    if lnumFind == 0 | break | endif

    "move to next line, line after *INCLUDE_PATH
    normal! j

    " loop used to collect all paths
    while 1

       " get current line
       let line = getline(".")

       " keyword line
       if line =~? '^\*'

         break

       " comment line
       elseif line =~? '^\$'

         " last line in the file? -> break loop
         if line(".") == lastlnum | break | endif
         " go to next line
         normal! j

       " get path
       else

         " substitution (\ -> /) is made according to :help path
         let line = substitute(line, "\\", "/", "g")
         " add path only when does not exist
         if count(paths, line) == 0 | call add(paths, line) | endif
         " last line in the file? -> break loop
         if line(".") == lastlnum | break | endif
         " go to next line
         normal! j

       endif

    endwhile

  endwhile

  " restore start position
  call cursor(startlnum, 0)

  return paths

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#ExpandPath()

  "-----------------------------------------------------------------------------
  " Function to expand VIM &path variable.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " scan file for include paths
  let paths = lsdyna_include#CollectPaths()

  " expand &path variable
  for path in paths
    if match(&path, path) == -1
      let &path = &path . "," . path
    endif
  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#CollectIncludes()

  "-----------------------------------------------------------------------------
  " Function to check include file paths.
  "
  " Arguments:
  " - None
  " Return:
  " - includes : list of includes
  "-----------------------------------------------------------------------------

  " includes list
  let includes = []

  " store start position
  let startlnum = line('.')

  " store number of last line in the file
  let lastlnum = line('$')

  " jump to beginning of the file / start position for search
  normal! gg0

  " loop over the file (used to find all *INCLUDE_)
  while 1

    " find *INCLUDE keywords
    let inclnum = search('\c^\*INCLUDE\(_TRANSFORM\)\?\s*$', 'cW')

    " found nothing -> stop loop
    if inclnum == 0 | break | endif

    " include or include_transform?
    if getline(inclnum) =~? 'include_transform'
      let inckw = 'include_transform'
    else
      let inckw = 'include'
    endif

    "---------------------------------------------------------------------------
    if inckw ==# 'include'

      "move to next line, line after *INCLUDE
      normal! j

      " loop over *INCLUDE (used to collect all paths)
      while 1

         " get current line
         let line = getline(".")

         " keyword line -> break loop
         if line =~? '^\*'
           break
         " do it only for non comment lines
         elseif line =~? '^[^$]'
           " add include line
          let line = substitute(line, "\\", "/", "g")
          call add(includes, line)
         endif

         "last line in the file ? -> stop loop
         if line(".") == lastlnum | break | endif

         " go to next line
         normal! j

      endwhile

    "---------------------------------------------------------------------------
    elseif inckw ==# 'include_transform'

      " move to 1st line after *INCLUDE_TRANSFORM
      normal! j

      while 1

        " get current line
        let line = getline(".")

        " skip comment line
        if line =~? "^\\$"
          " move forward
          normal! j
        else
           " add include line
          let line = substitute(line, "\\", "/", "g")
          call add(includes, line)
          break
        endif

      endwhile

    endif

  endwhile

  " restore start position
  call cursor(startlnum, 0)

  return includes

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#CheckPath()

  "-----------------------------------------------------------------------------
  " Function to check include file paths.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " collect paths
  let paths = lsdyna_include#CollectPaths()

  " collect includes
  let includes = lsdyna_include#CollectIncludes()

  " list of missing includes
  let missing = []

  " loop over includes
  for include in includes

    " if include does not exist check *INCLUDE_PATH
    if !filereadable(include)

      let incFlag = 0
      for path in paths
        let tmpIncl = path . "/" . include
        if filereadable(tmpIncl)
          let incFlag = 1
          break
        endif
      endfor

      " add include for missing
      if incFlag == 0 | call add(missing, include) | endif

    endif

  endfor

  " write message
  if len(missing) == 0
    echom "All include files were found."
  else
    echohl Title | echom "--- Included files not found in path ---" | echohl None
    for include in missing
      echohl Directory | echom include | echohl None
    endfor
  endif

endfunction

"-------------------------------------EOF---------------------------------------
