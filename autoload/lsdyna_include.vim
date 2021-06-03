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
  "                     'e' - explore directory with OS file manager
  " Return:
  " - none
  "-----------------------------------------------------------------------------

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
      if has('win32') || has('win64')
        let dir_path =  substitute(fnamemodify(incl.path,':p:h'),'/','\','g')
        execute 'silent ! explorer' dir_path
      endif
    endif
  else
    echo 'Path ' .. incl.path .. ' not found!'
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

  let paths = []
  let qfid = lsdyna_vimgrep#Vimgrep('include_path', '%', '')
  for item in getqflist({'id':qfid, 'items':''}).items
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
  let path = expand('%:p:h').'/'.a:path
  if filereadable(path) || isdirectory(a:path)
    return {'read':1, 'path':path}
  endif

  " look in include_paths
  let incl_paths = lsdyna_include#GetIncludePaths()
  for incl_path in incl_paths
    let path = incl_path.'/'.a:path
    if filereadable(path) || isdirectory(a:path)
      return {'read':1, 'path':path}
    endif
  endfor

  return {'read':0, 'path':a:path}

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#Touch(command)

  "-----------------------------------------------------------------------------
  " Function to manage include files.
  "
  " Arguments:
  " - command (string) : defined type of operation
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  if a:command ==# 'D'

    " delete selected include file

    let incl = lsdyna_parser#Keyword(line('.'), '%', '')._Include()[0]
    if incl.read
      if input('Delete file ' .. incl.path .. ' (y/n)? ') == 'y'
        call delete(incl.path)
        call incl.Delete()
      endif
    else
      echo 'File ' . incl.path . ' does not exist.'
    endif

  "-----------------------------------------------------------------------------
  elseif a:command ==# 'C' || a:command ==# 'R'

    " copy/rename include file

    let incl = lsdyna_parser#Keyword(line('.'), '%', '')._Include()[0]

    " do nothing if the file does not exists
    if !incl.read
      echo 'File ' .. incl.path .. ' does not exist!'
      return
    endif

    let fop = fnamemodify(incl.path, ':h')   " file old path
    let fon = fnamemodify(incl.path, ':t:r') " file old name
    let foe = fnamemodify(incl.path, ':e')   " file old extension

    " get file new name
    let fnn = input('New include name (*.' .. foe .. '): ', fon, 'file')
    if empty(fnn) | return | endif

    " keep old extension unless new one is defined
    if fnn =~?'\.\a\+$'
      let pathnew = fop .. '/' .. fnn
    else
      let pathnew = fop .. '/' .. fnn .. '.' .. foe
    endif

    " if a file with new name exists ask a user what to do
    let file = lsdyna_include#Resolve(pathnew)
    if file.read
      if input('File exists! Overwrite (y/n)? ') !=# 'y'
        return
      endif
    endif

    " finally do main job
    if a:command == 'R'
      call rename(incl.path, pathnew)
    elseif a:command == 'C'
      call writefile(readfile(incl.path, 'b'), pathnew, 'b')
    endif

    " update keyword with new path
    let pathhead = fnamemodify(incl.pathraw, ':h')
    let pathhead = pathhead == '.' && incl.pathraw[0] != '.' ? '' : pathhead .. '/' 
    let new_path =  pathhead .. fnamemodify(pathnew, ':t')
    call incl.SetPath(new_path, '')
    call incl.Delete()
    call incl.Write()

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
  let qfid = lsdyna_vimgrep#Vimgrep('include', '%', '')
  let qflist = []
  for item in getqflist({'id':qfid, 'items':''}).items
    let incls = lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fnc')._Autodetect()
    for incl in incls
      if !incl.read && !incl.hide
        call add(qflist, incl.Qf())
      endif
    endfor
  endfor

  " open manager
  if !empty(qflist)
    call setqflist([], ' ', {'items' : qflist,
    \                        'title' : 'Check include'})
    call lsdyna_manager#QfOpen(getqflist({'id':0}).id, 0)
  endif

  return len(qflist)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#Quit(bang, cmd)

  "-----------------------------------------------------------------------------
  " Function to check includes at write/quit.
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

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_include#CommentIncludes(bang, ...)

  "-----------------------------------------------------------------------------
  " Function to comment matching includes.
  "
  " Arguments:
  " - bang : 0 : comment matching includes
  "          1 : comment NOT matching includes
  " - ...  : words to match include paths
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  let names = a:0 == 0 || a:1 == '*' ? '.' : join(split(a:1),'\|')
 
  " function started with keyword manager
  if &filetype == 'qf'
    let qflist = getqflist()
    let qfopen = 1
    cclose
  " keyword started w/o keyword manager
  else
    let qfid = lsdyna_vimgrep#Vimgrep('include', '%', '')
    let qflist = getqflist({'id':qfid, 'items':''}).items
    let qfopen = 0
  endif

  " parse keywords on qflist
  let includes = []
  for kw in qflist
    call extend(includes, lsdyna_parser#Keyword(kw.lnum, kw.bufnr, 'f')._Autodetect())
  endfor

  " loop to comment matching includes
  echo 'Commenting ...'
  let nr = 0
  let bufnr = bufnr('%')
  for include in includes
    " comment includes which does not match regex
    if a:bang
      if include.pathraw !~? names
        let nr += 1
        echo nr .. '. ' .. include.pathraw
        silent execute 'buffer' include.bufnr
        call include.Comment(g:lsdynaCommentString)
        call include.Delete()
        call include.Write()
      endif
    " comment includes which match regex
    else
      if include.pathraw =~? names
        let nr += 1
        echo nr .. '. ' .. include.pathraw
        silent execute 'buffer' include.bufnr
        call include.Comment(g:lsdynaCommentString)
        call include.Delete()
        call include.Write()
      endif
    endif
  endfor
  silent execute 'buffer' bufnr
  
  if qfopen
    execute g:lsdynaManagerCommand
  endif

endfunction

"-------------------------------------------------------------------------------

"function! lsdyna_include#UnCommnetIncludes()
"  
"  "-----------------------------------------------------------------------------
"  " Function to uncomment includes. The function assume whole *INCLUDE block
"  " is commented with prefix "$-->".
"  "
"  " Arguments:
"  " - None
"  " Return:
"  " - None
"  "-----------------------------------------------------------------------------
"
"  let lnum = 1
"  let incl_block = 0
"  let nr = 0
"
"  " check every line in the file
"  while lnum <= line('$')
"
"    " mark *INCLUDE block
"    if getline(lnum) =~? '^\$-->\*INCLUDE'  
"      let incl_block = 1
"    endif
"
"    " remove prefix
"    silent execute lnum .. 's/^\$-->//e'
"
"    " print message about uncomment
"    if incl_block == 1 && getline(lnum)[0] !~? '[$*]'
"      let nr += 1
"      echo nr .. '. ' .. getline(lnum)
"      let incl_block = 0
"    endif
"
"    let lnum += 1
"
"  endwhile
"  echo 'Uncommented ' .. nr .. ' includes.'
"
"endfunction

"-------------------------------------EOF---------------------------------------
