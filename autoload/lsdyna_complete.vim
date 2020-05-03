"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  10th of July 2017
"
"-------------------------------------------------------------------------------
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------
"
function! s:Start_dyna_col()
    return (float2nr((virtcol(".")-1)/10))*10
endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#LsdynaComplete(findstart, base)

  "-----------------------------------------------------------------------------
  " Omni completion function used with Ls-Dyna completion.
  "
  " Arguments:
  " - see :help complete-functions
  " Return:
  " - see :help complete-functions
  "-----------------------------------------------------------------------------

  "-----------------------------------------------------------------------------
  " first function call --> find completion type and start position
  if a:findstart

    " get current line
    let line = getline(".")

    "---------------------------------------------------------------------------
    " keyword completion
    " return 1ts or 2nd column in line depend on '*'

    if line =~? '^\*\?\h\+$'
      let b:lsdynaCompleteType = 'keyword'
      return line[0] == '*' ? 1 : 0
    endif

    "---------------------------------------------------------------------------
    " parameter completion
    " return one sign after '&' sign in current ls-dyna column

    " find '&' position between start of dyna column and current cursor position
    let apos = stridx(line[:col('.')], '&', <SID>Start_dyna_col())
    if apos > -1
      let b:lsdynaCompleteType = 'parameter'
      return apos+1
    endif

    "---------------------------------------------------------------------------
    " field completion
    " return start position of current ls-dyna column

    let b:lsdynaCompleteType = 'field'
    return <SID>Start_dyna_col()

  "-----------------------------------------------------------------------------
  " 2nd function call --> build completion list
  else

    let base = trim(a:base)

    "---------------------------------------------------------------------------
    " keyword completion

    if b:lsdynaCompleteType == 'keyword'

      let keywords = []
      for keyword in g:lsdynaLibKeywords
        if keyword =~? '^' . base
          call add(keywords, keyword)
        endif
      endfor
      return keywords

    "---------------------------------------------------------------------------
    "parameter completion

    elseif b:lsdynaCompleteType == 'parameter'

      " build all parameters list
      let save_cursor = getpos(".")
      let save_cursor[0] = bufnr('%')
      call lsdyna_vimgrep#Vimgrep('parameter', '%', 'i')
      let params = []
      for item in getqflist()
        call extend(params, lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fn')._Parameter())
      endfor
      execute 'noautocmd buffer ' . save_cursor[0]
      call setpos('.', save_cursor)

      " build completion list
      let complete = []
      for param in params
        if param.pname =~? '^'.base
          call add(complete, param.Omni())
        endif
      endfor
      return complete

    "---------------------------------------------------------------------------
    " field completion (kvar or id)

    elseif b:lsdynaCompleteType == 'field'

      let items = []

      " get keyword and field name
      let keyword = tolower(getline(search('^\*\a', 'bn'))[1:])
      let header = <SID>GetHeader()

      "-------------------------------------------------------------------------
      " keyword variable (kvar) completion

      " get kvars and if not empty return completion list
      let kvars = g:lsdynaKvars.get(keyword, header)
      if !empty(kvars)
        for kvar in kvars
          call add(items, {'word' : kvar.value,
                         \ 'menu' : kvar.description})
        endfor
        return items
      endif

      "-------------------------------------------------------------------------
      " id completion

      " check header and tell me what keywords I am looking for?
      let keywords = get(g:lsdynaLibHeaders, header, "set part")

      " build all keywords list
      let save_cursor = getpos(".")
      let save_cursor[0] = bufnr('%')
      let kwords = []
      call lsdyna_vimgrep#Vimgrep(keywords, '%', 'i')
      for item in getqflist()
        call extend(kwords, lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fn')._Kword())
      endfor
      execute 'noautocmd buffer ' . save_cursor[0]
      call setpos('.', save_cursor)

      " build completion list
      for kword in kwords
        if kword.id =~? '^'.base || kword.title =~? base
          call add(items, kword.Omni())
        endif
      endfor
      return items

    endif

  endif

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
  let fpos = ((float2nr((virtcol(".")-1)/10))*10)
  " get keyword option
  let option = tolower(substitute(strpart(getline(lnum), fpos, 10), "[#$:]\\?\\s*", "", "g"))

  return option

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#libKeywords(path)

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
  " step 2: read keyword definition from external file
  " step 3: jump to first dataline under the keyword
  delete _
  execute "read " . g:lsdynaPathKeywords . keyword[0] . "/" . keyword . ".k"
  call search("^[^$]\\|^$", "W")

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

function! lsdyna_complete#LsDynaMapEnter()

  "-----------------------------------------------------------------------------
  " Function change behaviour of <CR> to perform completion.
  " It depends on variable set by "lsdyna_complete#LsdynaComplete" function.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " do not map if menu not visible
  if !pumvisible() | return "\<CR>" | endif

  " choose mapping depend on completion type
  if b:lsdynaCompleteType == 'keyword'
    " insert entry from menu, leave insert mode, insert keyword
    let mapStr = "\<C-Y>\<ESC>:call lsdyna_complete#InputKeyword()\<CR>"
  elseif b:lsdynaCompleteType == 'parameter'
    " insert entry from menu, leave insert mode
    let mapStr = "\<C-Y>\<ESC>"
  elseif b:lsdynaCompleteType == 'field'
    " insert entry from menu, leave insert mode
    let mapStr = "\<C-Y>\<ESC>"
  else
    " act normal
    let mapStr = "\<CR>"
  endif

  " reset completion type
  let b:lsdynaCompleteType = 'none'

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

"-------------------------------------EOF---------------------------------------
