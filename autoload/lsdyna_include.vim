"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  6th of May 2017
"
" History of change:
"
" v1.1.0
"   - use vimgrep and quickfix list for search
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_include#getIncludes()

  "-----------------------------------------------------------------------------
  " Function to find all includes in current file
  "
  " Arguments:
  " - None
  " Return:
  " - includes (list) : list with includes paths
  "-----------------------------------------------------------------------------

  "-------------------------------------------------------------------------------
  " find *INCLUDE
  silent! vimgrep /^\*INCLUDE\s*$/j %

  " collect all paths
  let includes = []
  for item in getqflist()
    let i = 1
    while 1
      " take line
      let line = getline(item['lnum']+i)
      " keyword line --> break loop
      if line[0] == '*' | break | endif
      " comment line --> go to next line
      if line[0] == '$' | let i = i + 1 | continue | endif
      " get include path
      call add(includes, getline(item['lnum']+i))
      let i = i + 1
    endwhile
  endfor

  "-------------------------------------------------------------------------------
  " find *INCLUDE_TRANSFORM
  silent! vimgrep /^\*INCLUDE_TRANSFORM\s*$/j %

  " collect all paths
  for item in getqflist()
    let i = 1
    while 1
      " take line
      let line = getline(item['lnum']+i)
      " comment line --> go to next line
      if line[0] == '$' | let i = i + 1 | continue | endif
      " get include path
      call add(includes, getline(item['lnum']+i))
      break
    endwhile
  endfor

  return includes

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#getIncludePaths()

  "-----------------------------------------------------------------------------
  " Function to find all include paths in current file
  "
  " Arguments:
  " - None
  " Return:
  " - includes (list) : list with includes paths
  "-----------------------------------------------------------------------------

  " find all keywords used to create tags
  silent! vimgrep /^\*INCLUDE_PATH/j %

  " collect all paths
  let includes = []
  for item in getqflist()
    let i = 1
    while 1
      " take line
      let line = getline(item['lnum']+i)
      " last line in file --> break loop
      if line('.') == line('$') | break | endif
      " keyword line --> break loop
      if line[0] == '*' | break | endif
      " comment line --> go to next line
      if line[0] == '$' | let i = i + 1 | continue | endif
      " get include path
      call add(includes, getline(item['lnum']+i))
      let i = i + 1
    endwhile
  endfor

  return includes

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#incl2buff()

  "-----------------------------------------------------------------------------
  " Function to open all include files in new buffers.
  "
  " Arguments:
  " - files (list) : file paths
  " Return:
  " None
  "-----------------------------------------------------------------------------

  call lsdyna_include#expandPath()
  let files = lsdyna_include#getIncludes()
  for file in files
    execute "badd " . file
  endfor

  echo len(files) . " new buffer(s) added."

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#expandPath()

  "-----------------------------------------------------------------------------
  " Function to expand VIM &path variable.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " scan file for include paths
  let paths = lsdyna_include#getIncludePaths()

  " expand &path variable
  for path in paths
    " substitution (\ -> /) is made according to :help path
    let path = substitute(path, "\\", "/", "g")
    " if path does not exist add it
    if match(&path, path) == -1
      let &path = &path . "," . path
    endif
  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#checkIncl()

  "-----------------------------------------------------------------------------
  " Function to check include file paths.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " collect paths
  let paths = lsdyna_include#getIncludePaths()

  " collect includes
  let includes = lsdyna_include#getIncludes()

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
    echohl Title | echom "--- Included files not found in path ---" | echohl Directory
    for include in missing
      echom include
    endfor
  echohl None
  endif

  return len(missing)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#quit(cmd)

  "-----------------------------------------------------------------------------
  " Fundtion to check includes at write/quit.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " check includes
  let incl = lsdyna_include#checkIncl()

  " if include missing --> confirm write
  if incl !=0
    let choice = confirm("Include files missings!\nDo you want to write/quit anyway?", "&Yes\n&No", 2, "Warrning")
    if choice == 1
      if a:cmd == "w"
        write
      elseif a:cmd == "wq"
        write
        quit
      endif
    endif
  else
    if a:cmd == "w"
      write
    elseif a:cmd == "wq"
      write
      quit
    endif
  endif

endfunction

"-------------------------------------EOF---------------------------------------
