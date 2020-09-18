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
"-------------------------------------------------------------------------------

function! lsdyna_complete#OmnifunctPre()

  "-----------------------------------------------------------------------------
  " Function trigger before omnifunc. It defines type of completion
  " (keyword/parameter/field/...) and return list of candidates for
  " completion.
  "
  " Since Vim 8.2 I must not use ':vimgerp' in omnifunct. Vimgrep is used to
  " scan files for completion candidates. This is why first I use 'OmnifunctPre'
  " and next I call 'Omnifunc' to make completion.
  "
  " Arguments:
  " - None
  " Return:
  " - g:complete_type (string) : 'keyword'
  "                              'parameter'
  "                              'field_opt'
  "                              'field_id'
  " - g:complete_items (list)  : list with all candidates for completion
  "                              this list is tested against 'base' in 'omnifunct'
  "                              item type depends on type completion
  "-----------------------------------------------------------------------------

  let g:complete_type = 'none'
  let g:complete_items = []

  "-----------------------------------------------------------------------------
  " keyword completion
  if getline(".") =~? '^\*\?\h\+$'
    let g:complete_type = 'keyword'
    let g:complete_items = g:lsdynaLibKeywords
    return
  endif

  "-----------------------------------------------------------------------------
  " parameter completion
  " find '&' position between start of dyna column and current cursor position
  let apos = stridx(getline(".")[:col('.')], '&', <SID>Start_dyna_col())
  if apos > -1

    let g:complete_type = 'parameter'
    normal! mP
    call lsdyna_vimgrep#Vimgrep('parameter', '%', 'i')
    let g:complete_items = []
    for item in getqflist()
      call extend(g:complete_items, lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fn')._Parameter())
    endfor
    normal! `P
    return

  endif

  "-----------------------------------------------------------------------------
  " field option completion

  let keyword = tolower(getline(search('^\*\a', 'bn'))[1:])
  let header = <SID>GetHeader()
  let kvars = g:lsdynaKvars.get(keyword, header)
  if !empty(kvars)
    let g:complete_type = 'field_opt'
    let g:complete_items = kvars
    return
  endif

  "-------------------------------------------------------------------------
  " field id completion

  let g:complete_type = 'field_id'
  let g:complete_items = []
  normal! mP
  call lsdyna_vimgrep#Vimgrep(get(g:lsdynaLibHeaders, header, "set part"), '%', 'i')
  for item in getqflist()
    "echo item
    "call input("stop")
    call extend(g:complete_items, lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fn')._Kword())
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
    if g:complete_type == 'keyword'
      return line[0] == '*' ? 1 : 0
    elseif g:complete_type == 'parameter'
      let apos = stridx(line[:col('.')], '&', <SID>Start_dyna_col())
      return apos+1
    elseif g:complete_type == 'field_opt' || g:complete_type == 'field_id'
      return <SID>Start_dyna_col()
    endif

  "-----------------------------------------------------------------------------
  " 2nd function call --> build completion list
  else

    let base = trim(a:base)
    let complete = []

    "---------------------------------------------------------------------------
    " keyword completion
    if g:complete_type == 'keyword'
      for item in g:complete_items
        if item =~? '^' . base
          call add(complete, item)
        endif
      endfor
    "---------------------------------------------------------------------------
    "parameter completion
    elseif g:complete_type == 'parameter'
      for item in g:complete_items
        if item.pname =~? '^'.base
          call add(complete, item.Omni())
        endif
      endfor
    "---------------------------------------------------------------------------
    " field option completion
    elseif g:complete_type == 'field_opt'
      for item in g:complete_items
        call add(complete, {'word' : item.value,
                          \ 'menu' : item.description})
      endfor
    "---------------------------------------------------------------------------
    " field id completion
    elseif g:complete_type == 'field_id'
      for item in g:complete_items
        if item.id =~? '^'.base || item.title =~? base
          call add(complete, item.Omni())
        endif
      endfor

    endif

    return complete

  endif

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#libKeywords(path)

  "-----------------------------------------------------------------------------
  " Function to initialize Ls-Dyna keyword library.
  " It create list of all *.k files in 'a:path'.
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

function! lsdyna_complete#InputKeyword()

  "-----------------------------------------------------------------------------
  " Function to take keyword name from current line and insert keyword
  " definition from the library.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " get keyword name from current line
  " if necessary get rid of asterisk sign
  let kline = tolower(getline("."))
  let keyword = kline[0] == "*" ? kline[1:] : kline[0:]

  " step 1: completion put line with a keyword name, I do not need it any more since
  "         keyword definition I am going to read already include this line
  " step 2: read keyword definition from external file, start one line up
  " step 3: jump to first dataline under the keyword
  execute "delete _"
  execute ".-1read " . g:lsdynaPathKeywords . keyword[0] . "/" . keyword . ".k"
  "call search("^[^$]\\|^$", "W")

endfunction

"-------------------------------------------------------------------------------

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
  if virtcol(".") > col(".")
    call setline(".", getline(".").repeat(" ", virtcol(".")-col(".")+1))
  endif

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#MapEnter()

  "-----------------------------------------------------------------------------
  " Function change behaviour of <CR> to perform completion.
  " It depends on variable set by "lsdyna_complete#OmnifunctPre" function.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " do not map if menu not visible
  if !pumvisible() | return "\<CR>" | endif

  " choose mapping depend on completion type
  if g:complete_type == 'keyword'
    " insert entry from menu, leave insert mode, insert keyword
    let mapStr = "\<C-Y>\<ESC>:call lsdyna_complete#InputKeyword()\<CR>"
  elseif g:complete_type == 'parameter'
    " insert entry from menu, leave insert mode
    let mapStr = "\<C-Y>\<ESC>"
  elseif g:complete_type == 'field_opt' || g:complete_type == 'field_id'
    " insert entry from menu, leave insert mode
    let mapStr = "\<C-Y>\<ESC>"
  else
    " act normal
    let mapStr = "\<CR>"
  endif

  " reset completion type
  let g:complete_type = 'none'

  return mapStr

endfunction

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


"-------------------------------------EOF---------------------------------------
