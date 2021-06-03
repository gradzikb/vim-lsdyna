"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  14th of July 2020
"
"-------------------------------------------------------------------------------
"
" v1.1.0
"   - update for VIM 8.2
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------
"

function! lsdyna_complete#OmnifunctPre(flag)

  "-----------------------------------------------------------------------------
  " Function trigger before "omnifunc". It defines type of completion
  " (keyword/parameter/field/...) and return list of candidates for
  " completion.
  "
  " I am doing it before "omnifunc" because I am not able make a jump to
  " other buffer to parse keywords when I am in "omnifunc" function.
  "
  " Arguments:
  " - None
  " Return:
  " - s:lsdynaOmniCompletionType (string) : 'keyword'
  "                                         'parameter'
  "                                         'field_opt'
  "                                         'field_id'
  " - s:complete_items (list)  : list with all candidates for completion
  "                              this list is tested against 'base' in 'omnifunct'
  "                              item type depends on type completion
  "-----------------------------------------------------------------------------

  echo 'Building completion list ... '

  let s:lsdynaOmniCompletionType = 'none'
  let s:complete_items = []

  "-----------------------------------------------------------------------------
  " keyword completion
  if getline(".") =~? '^\*\?\h\+$'
    let s:lsdynaOmniCompletionType = 'keyword'
    let s:complete_items = b:lsdynaLibKeywords
    return
  endif

  "-----------------------------------------------------------------------------
  " parameter completion
  let apos = stridx(getline(".")[:col('.')], '&', <SID>Start_dyna_col())
  if apos > -1
    let s:lsdynaOmniCompletionType = 'parameter'
    normal! mP
    let qfid = lsdyna_vimgrep#Vimgrep('parameter', '%', a:flag)
    for item in getqflist({'id':qfid, 'items':''}).items
      call extend(s:complete_items, lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fn')._Parameter())
    endfor
    normal! `P
    return
  endif

  "-----------------------------------------------------------------------------
  " field option completion
  let keyword = tolower(getline(search('^\*\a', 'bn'))[1:])
  let header = <SID>GetHeader()
  let options = []
  for kword in keys(g:lsdynaLibKvars)
    if keyword =~? '^' .. kword
      let options = get(g:lsdynaLibKvars[kword], header, '')
      break
    endif
  endfor
  if !empty(options)
    let s:lsdynaOmniCompletionType = 'field_opt'
    let s:complete_items = options
    return
  endif

  "-------------------------------------------------------------------------
  " field id completion
  let s:lsdynaOmniCompletionType = 'field_id'
  normal! mP
  let qfid = lsdyna_vimgrep#Vimgrep(get(g:lsdynaLibHeaders, header, "set part"), '%', a:flag)
  for item in getqflist({'id':qfid, 'items':''}).items
    call extend(s:complete_items, lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fn')._Autodetect())
  endfor
  normal! `P
  return

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#Omnifunc(findstart, base)

  "-----------------------------------------------------------------------------
  " Omni completion function used with Ls-Dyna completion.
  "
  " Arguments:
  " - see :help complete-functions
  " Return:
  " - see :help complete-functions
  "-----------------------------------------------------------------------------

  "-----------------------------------------------------------------------------
  " first function call --> set beginning of string
  " text between this position and cursor position when completion was used
  " will be tested against completion list in next function call

  if a:findstart

    let line = getline(".")

    " for keyword completion --> from line beginning but w/o asterisk sign 
    " for parameter completion --> from ampersand sign '&'
    " for field completion --> from beginning of ls-dyna column
    if s:lsdynaOmniCompletionType == 'keyword'
      return line[0] == '*' ? 1 : 0
    elseif s:lsdynaOmniCompletionType == 'parameter'
      let apos = stridx(line[:col('.')], '&', <SID>Start_dyna_col())
      return apos+1
    elseif s:lsdynaOmniCompletionType == 'field_opt' || s:lsdynaOmniCompletionType == 'field_id'
    "else
      return <SID>Start_dyna_col()
    endif

  "-----------------------------------------------------------------------------
  " 2nd function call --> build completion list
  else

    let base = trim(a:base)
    let complete = []

    "---------------------------------------------------------------------------
    " keyword completion
    if s:lsdynaOmniCompletionType == 'keyword'
      for item in s:complete_items
        if item.name =~? '^' . base
        call add(complete, {'word'      : item.name,
                          \ 'dup'       : 1,
                          \ 'user_data' : item.path
                          \})
        endif
      endfor
    "---------------------------------------------------------------------------
    "parameter completion
    elseif s:lsdynaOmniCompletionType == 'parameter'
      for item in s:complete_items
        if item.pname =~? '^'.base
          call add(complete, item.Omni())
        endif
      endfor
    "---------------------------------------------------------------------------
    " field option completion
    elseif s:lsdynaOmniCompletionType == 'field_opt'
      for item in s:complete_items
        let option = split(item,';')
        call add(complete, {'word' : printf('%10s', option[0]),
                          \ 'menu' : option[1]})
      endfor
    "---------------------------------------------------------------------------
    " field id completion
    elseif s:lsdynaOmniCompletionType == 'field_id'
      for item in s:complete_items
        if item.id =~? '^'.base || item.title =~? base
          call add(complete, item.Omni())
        endif
      endfor

    endif

    echo
    return complete

  endif

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#libKeywords(paths)

  "-----------------------------------------------------------------------------
  " Function to initialize Ls-Dyna keyword snippets library.
  " It create list of all *.k files in 'a:paths'.
  "
  " Arguments:
  " - paths (string) : list of paths separated by ','
  " Return:
  " - library (list) : keywords list for completion
  "                    {
  "                      'path' : absolute path for snippet
  "                      'name' : keyword name
  "                    }
  "-----------------------------------------------------------------------------

  let library = []
  for path in split(a:paths, ',')
    "let files = split(globpath(path, '**/*.k'))
    let files = split(globpath(path, '**/*.*'))
    for file in files
      let snippet = {}
      let snippet.path = file
      let snippet.name = fnamemodify(snippet.path, ':t:r')
      call add(library, snippet)
    endfor
  endfor
  return library

endfunction

"-----------------------------------------------------------------------------

function! lsdyna_complete#extendLine()

  "-----------------------------------------------------------------------------
  " Function to extend line with white signs, workaround for case when
  " omni-completion is made in virtual column.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " return colum number
  let vcol = min([virtcol('.'), 79]) " limited to 79 to wvoid situation I am at last position in line
  let  col = col('.')
  if vcol > col
    call setline(".", getline(".") .. repeat(" ", vcol-col))
    normal! $
  endif

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#CompleteDone()

  "-----------------------------------------------------------------------------
  " Function trigger by autocmd "CompleteDonePre" event after completion is done.
  " If I complete keyword and completion is not empty I read keyword
  " definition from external file. It depends on gloabl variable set by
  " "lsdyna_complete#OmnifunctPre" function.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  " Dependencies:
  " - var "s:lsdynaOmniCompletionType" set by "lsdyna_complete#OmnifunctPre()"
  "-----------------------------------------------------------------------------

  let complete_mode = complete_info().mode
 
  if complete_mode == 'omni'

    if s:lsdynaOmniCompletionType == 'keyword' && !empty(v:completed_item)
      silent execute 'delete _'
      silent execute '.-1read ' .. v:completed_item.user_data
      call search('^[^$*]','W')
      stopinsert
    else
      stopinsert
    endif

  elseif complete_mode == 'function' && g:lsdynaInclPathAutoSplit == 1

    let incl = lsdyna_parser#Keyword('.', '%', '')._Autodetect()[0]
    call incl.SetPath(incl.pathraw,'')
    let pathlnum2 = incl.pathlnum2 " new position of last line of path, I need it to set cursor at the end 
    call incl.Delete()
    call incl.Write()
    " restor cursor position at the end of path
    let lnum = incl.first + pathlnum2
    call cursor(lnum, len(getline(lnum))+1)
    normal! zo

  endif

endfunction

"-------------------------------------------------------------------------------

"function! lsdyna_complete#MapEnter()
"
"  "-----------------------------------------------------------------------------
"  " Function change behaviour of <CR> to perform completion.
"  " It depends on variable set by "lsdyna_complete#OmnifunctPre" function.
"  "
"  " Arguments:
"  " - None
"  " Return:
"  " - None
"  "-----------------------------------------------------------------------------
"
"  " do not map if menu not visible
"  if !pumvisible() | return "\<CR>" | endif
"
"  " choose mapping depend on completion type
"  if s:lsdynaOmniCompletionType == 'keyword'
"    " insert entry from menu, leave insert mode, insert keyword
"    let mapStr = "\<C-Y>\<ESC>:call lsdyna_complete#InputKeyword()\<CR>"
"  elseif s:lsdynaOmniCompletionType == 'parameter'
"    " insert entry from menu, leave insert mode
"    let mapStr = "\<C-Y>\<ESC>"
"  elseif s:lsdynaOmniCompletionType == 'field_opt' || s:lsdynaOmniCompletionType == 'field_id'
"    " insert entry from menu, leave insert mode
"    let mapStr = "\<C-Y>\<ESC>"
"  else
"    " act normal
"    let mapStr = "\<CR>"
"  endif
"
"  " reset completion type
"  let s:lsdynaOmniCompletionType = 'none'
"
"  return mapStr
"
"endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#libHeaders(path)

  "-----------------------------------------------------------------------------
  " Function to initialize Ls-Dyna headers library from external file.
  "
  " Arguments:
  " - path (string) : path to headers file
  " Return:
  " - headers (dict) : dyna headers library
  "-----------------------------------------------------------------------------

  " build up headers dict
  let headers = {}
  for sline in readfile(a:path)

    " get keyword and option and set dict item
    let line = split(sline,'\s*:\s*')
    let headers[tolower(line[0])] =  tolower(line[1])

  endfor

  return headers

endfunction

"-------------------------------------------------------------------------------

function s:GetHeader()

  "-----------------------------------------------------------------------------
  " Function to find keyword option in line above.
  "
  " Arguments:
  " - None
  " Return:
  " - keyLib (string) : keyword option
  "-----------------------------------------------------------------------------

  " find comment line
  let lnum = search('^\$', 'bn')
  " set cursor position
  "let fpos = ((float2nr((virtcol(".")-1)/10))*10)
  let fpos = <SID>Start_dyna_col()
  " get keyword option
  let option = tolower(substitute(strpart(getline(lnum), fpos, 10), "[#$:]\\?\\s*", "", "g"))

  return option

endfunction

"-------------------------------------------------------------------------------

function! s:Start_dyna_col()

  "-----------------------------------------------------------------------------
  " Small function to return beginning of ls-dyna column for current cursor
  " position. It assumes all columns are 10 signs length.
  " Cursor position count from 1, ls-dyna columns position count from 0
  "
  " cursor position --> ls-dyna column 1st position
  "            1-10 --> 0
  "           11-20 --> 10
  "             ... --> ...
  "           61-70 --> 60
  "           71-80 --> 70
  "-----------------------------------------------------------------------------
  "
  return (float2nr((virtcol(".")-1)/10))*10

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#CompletefuncPre()

  "-----------------------------------------------------------------------------
  " Function trigger before "completefunc". Collect all neccessary data for
  " file completion made in "completefunc" function.
  " in *INCLUDE_PATHS. 
  "
  " Arguments:
  " - None
  " Return:
  " - b:match (list)  : list of files/dirs names for completefunc
  " - b:base (string) : name for completefunc
  "-----------------------------------------------------------------------------

  " parse *INCLUDE_ keyword to get include path
  let incl = lsdyna_parser#Keyword('.', '%', '')._Autodetect()[0]
  let path = fnamemodify(incl.pathraw, ':h')
  let b:base = fnamemodify(incl.pathraw, ':t')

  " absolute path --> never use *INCLUDE_PATH
  if path[0] == '/' || path[0] == '\' || path[0:1] =~? '\a:'
    let include_paths = [path]
  " relative path --> look in current working directory and all *INCLUDE_PATH paths
  " at the end full path is *INCLUDE_PATH path + *INCLUDE path
  else
    let include_paths = [getcwd()] + lsdyna_include#GetIncludePaths()
    if !empty(path)
      call map(include_paths, {idx, val -> val .. '/' .. path})
    endif
  endif

  " find all files/directories and store it w/o paths
  " add separator for directories only, it easy to see what is on the list and
  " also I do not have to add path separator manually to follow the path
  let b:match = globpath(include_paths->join(','), '*', 1, 1)
  call map(b:match, {_,val -> isdirectory(val) ? fnamemodify(val, ':t') .. '/' : fnamemodify(val, ':t')})

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#Completefunc(findstart, base)

  "-----------------------------------------------------------------------------
  " User completion function used for filename completion with *INCLUDE_PATH.
  "
  " Arguments:
  " - see :help complete-functions
  " - "b:match" : variable set by lsdyna_complete#CompletefuncPre function
  " - "b:base"  : variable set by lsdyna_complete#CompletefuncPre function
  " Return:
  " - see :help complete-functions
  "-----------------------------------------------------------------------------

  if a:findstart

    " in 1st call I define start position for completion, text between start
    " position and current position will be used for completion and set as
    " a:base variable in 2nd call of the function. Using this approach I am
    " limited only for text in one line and it is a problem for multi line
    " paths under *INCLUDE_PATH. In example below completion text might be
    " only 'cto' and I want to use 'directo'
    " *INCLUDE
    " /path/dire +
    " cto<c-x><c-f>
    " To over came it in "CompletefuncPre" function I set my own "b:base" with
    " text for completion.
 
    " starting position for completion is 1st separator in path or column 0
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] !~ '[\/]'
      let start -= 1
    endwhile
    return start

  else

    " base_skip is part of text which will be removed from match in case part of
    " the file name is in previous line
    let lineUp = getline(line('.')-1)  
    let base_skip = lineUp =~? ' +$' ? fnamemodify(lineUp[0:-3], ':t') : ''

    " test names against completion text
    let complete = []
    for file in b:match
      if file =~? '^' .. b:base " !!! test against b:base not a:base
        call add(complete, {'word' : substitute(file,base_skip,'',''),
                          \ 'abbr' : file
                          \})
      endif
    endfor  
    return complete

  endif

endfunction


"-------------------------------------EOF---------------------------------------
