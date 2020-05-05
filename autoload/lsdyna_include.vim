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

function! s:Slash(path, sign)

  "-----------------------------------------------------------------------------
  " Function to set path separators
  "-----------------------------------------------------------------------------

  if a:sign == 'u'
    let path = substitute(a:path,'\','/','g')
  elseif a:sign == 'w'
    let path = substitute(a:path,'/','\','g')
  endif
  return path

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#Open(lnum, flag)

  "-----------------------------------------------------------------------------
  " Function to open ls-dyna includ file in new buffer.
  "
  " Arguments:
  " - a:lnum (number) : line number with *INCLUDE keyword
  " - a:flag (string) : 'b' - open file in current window
  "                     's' - open file in split window
  "                     't' - open file in tab
  "                     'T' - open file in tab in background
  "                     'd' - open directory in current window
  "                     'D' - open directory in split window
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " paresr *INCLUDE at line a:lnum
  let incl = lsdyna_parser#Keyword(a:lnum, bufnr('%'), 'nc')._Include()[0]

  if incl.read
    if a:flag ==# 'b'
      execute 'edit' incl.path
    elseif a:flag ==# 's'
      execute 'vertical split' incl.path
    elseif a:flag ==# 't'
      execute 'tabnew' incl.path
    elseif a:flag ==# 'T'
      execute 'tabnew' incl.path
      execute 'tabprevious'
    elseif a:flag ==# 'd'
      execute 'edit' fnamemodify(incl.path, ':p:h')
    elseif a:flag ==# 'D'
      execute 'vertical split' fnamemodify(incl.path, ':p:h')
    elseif a:flag ==# 'e'
      let dir_path = <SID>Slash(fnamemodify(incl.path,':p:h'), 'w')
      execute 'silent ! explorer' dir_path
    endif
  else
    echo 'Path not found!'
  endif

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#GetIncludePaths()

  "-----------------------------------------------------------------------------
  " Function to find all *INCLUDE_PATH keywords and collect paths.
  "
  " Arguments:
  " - None
  " Return:
  " - paths (list) : list of paths
  "-----------------------------------------------------------------------------

  " find all *INCLUDE_PATH keywords in current buffer
  call lsdyna_vimgrep#Vimgrep('include_path', '%', '')

  " loop over all *INCLUDE_PATH and collect paths under the keyword
  let paths = []
  for item in getqflist()
    let incls = lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fnc')._Include_path()
    call extend(paths, map(incls, 'v:val.path'))
  endfor
  call filter(paths, 'isdirectory(v:val)') "remove broken paths
  return paths

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#Resolve(path)

  "-----------------------------------------------------------------------------
  " Function to test file status.
  "
  " Arguments:
  " - a:path (string) : path to tested file
  " Return:
  " - (dict) : self.path : full file path
  "            self.read : 0 - file cannot be read
  "                        1 - file can be read
  "-----------------------------------------------------------------------------

  " include path respect to master (current working directory)
  if filereadable(a:path) || isdirectory(a:path)
    return {'read':1, 'path':a:path}
  endif

  " include path respect to current include file
  let cwd = <SID>Slash(expand('%:p:h'), 'u')
  let path = cwd.'\'.a:path
  if filereadable(path) || isdirectory(a:path)
    return {'read':1, 'path':path}
  endif

  " look in include_paths
  let incl_paths = lsdyna_include#GetIncludePaths()
  for incl_path in incl_paths
    let path = incl_path.'\'.a:path
    if filereadable(path) || isdirectory(a:path)
      return {'read':1, 'path':path}
    endif
  endfor

  return {'read':0, 'path':a:path}

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#Touch(command)

  "-----------------------------------------------------------------------------
  " ?
  "
  " Arguments:
  " - None
  " Return:
  " - includes (list) : list with includes paths
  "-----------------------------------------------------------------------------

  "-----------------------------------------------------------------------------
  if a:command ==# 't'

    " toggle between *INCLUDE and *INCLUDE_TRANSFORM keyword

    let lnum_path  = line('.')
    let lnum_kword =search('^*','bWn')
    if getline(lnum_kword) =~? '_TRANSFORM'
      call setline(lnum_kword, '*INCLUDE')
      let kw = lsdyna_misc#getKeyword(line('.'), '')
      execute lnum_path+1 . ',' . kw.last . 'delete'
      call cursor(lnum_path, 0)
    else
      call setline(lnum_kword, '*INCLUDE_TRANSFORM')
      let lines = []
      call add(lines,"$#  idnoff    ideoff    idpoff    idmoff    idsoff    idfoff    iddoff")
      call add(lines,'')
      call add(lines,'$#  idroff')
      call add(lines,'')
      call add(lines,'$#  fctmas    fcttim    fctlen    fcttem   incout')
      call add(lines,'')
      call add(lines,'$#  tranid')
      call add(lines,'')
      call append(lnum_path, lines)
      call cursor(lnum_path, 0)
    endif

  "-----------------------------------------------------------------------------
  elseif a:command ==# 'd'

    " delete selected include keyword

    let kword = lsdyna_misc#getKeyword(line('.'), 'fl')
    execute kword.first.','.kword.last.'delete'

  "-----------------------------------------------------------------------------
  elseif a:command ==# 'D'

    " delete selected include file

    " to do anything a file must exist
    let file = lsdyna_include#Resolve(getline("."))
    if file.read
      if input('Delete file '.file.path.' (y/n)? ') == 'y'
        call delete(file.path)
        call lsdyna_include#touchInclude('d')
      endif
    else
      echo 'File ' . file.path . ' does not exist.'
    endif

  "-----------------------------------------------------------------------------
  elseif a:command ==# 'c'

    " copy selected include keyword

    let kword = lsdyna_misc#getKeyword(line('.'), 'fl')
    execute kword.first.','.kword.last.'copy '.kword.last
    let kword = lsdyna_misc#getKeyword(line('.'), 'fl')
    call cursor(kword.first, 0)
    call search('^[^$]\|^$', 'W')

  "-----------------------------------------------------------------------------
  elseif a:command ==# 'C' || a:command ==# 'R'

    " 'C' : copy include file
    " 'R' : rename/move include file

    let incl_paths = lsdyna_include#GetIncludePaths()
    "let incl_paths = []
    let file_old = getline(".")

    " defien path separator as usd in, if missing use as linux
    let sep = match(file_old, '/') == -1 ? '\' : '/'

    " to do anything first we need to check the file exists
    let file = lsdyna_include#Resolve(file_old)
    if !file.read
      echo 'File ' . file.path . ' does not exist.'
      return
    endif

    " strip current include file path
    let fop = fnamemodify(file_old, ':h')   " file old path
    let foe = fnamemodify(file_old, ':e')   " file old extension
    let fon = fnamemodify(file_old, ':t:r') " file old name

    " if include have only file name with no path, keep it
    " fnamemodify function will return path as '.' so I reset here old path
    " and separator
    if file_old !~ '[\/]'
      let fop = ''
      let sep = ''
    endif

    " get a new include name from a user
    let fname_new = input('New include name (*.'.foe.'): ', fon, 'file')
    if empty(fname_new) | return | endif

    " old extension is carryover unless a user set a new extension
    let file_new = fname_new =~? '\.\a\{1,3}$' ? fop.sep.fname_new : fop.sep.fname_new.'.'.foe

    " if a file with new name exists ask a user what to do
    let file = lsdyna_include#Resolve(file_new)
    if file.read
      if input('File exists! Overwrite (y/n)? ') !=# 'y'
        return
      endif
    endif

    " finally do main job
    if a:command == 'R'

      call rename(file_old, file_new)

    elseif a:command == 'C'

      call writefile(readfile(file_old, 'b'), file_new, 'b')

    endif

    " update path to new file
    call setline(".", substitute(file_new, '\', '/', 'g'))
    "call setline(".", file_new)

  endif

  " it will clear input() messages from command line
  normal! :<ESC>

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#Check()

  "-----------------------------------------------------------------------------
  " Function to check include file paths.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " collect all broken includes
  call lsdyna_vimgrep#Vimgrep('include', '%', '')
  let qflist = []
  for item in getqflist()
    let incls = lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fnc')._Include()
    for incl in incls
      if !incl.read
        call add(qflist, incl.Qf())
      endif
    endfor
  endfor

  " open manager
  if !empty(qflist)
    call lsdyna_manager#Open(qflist)
    "set readonly
  endif

  return len(qflist)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#Quit(bang, cmd)

  "-----------------------------------------------------------------------------
  " Fundtion to check includes at write/quit.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  if a:bang
    execute a:cmd.'!'
  else
    if lsdyna_include#Check() == 0
      execute a:cmd
    endif
  endif

  " if include missing --> confirm write
  "if incl_status == 0
  "  if a:cmd == "w"
  "    execute 'w'
  "  elseif a:cmd == "wq"
  "    execute 'wq'
  "  endif
  "else
  "  "let choice = confirm("Include files missings!\nDo you want to write/quit anyway?", "&Yes\n&No", 2, "Warrning")
  "  let choice = input('Includes missing. Write (y/n)? :')
  "  if choice ==? 'y'
  "    if a:cmd == "w"
  "      write
  "    elseif a:cmd == "wq"
  "      write
  "      quit
  "    endif
  "  endif
  "endif

endfunction

"-------------------------------------EOF---------------------------------------
