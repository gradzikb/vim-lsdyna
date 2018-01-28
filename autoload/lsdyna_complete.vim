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
    "
    if line =~? '^\*\?\h\+$'
      let b:lsdynaCompleteType = 'keyword'
      if line[0] == "*"
        return 1
      else
        return 0
      endif
    endif

    "---------------------------------------------------------------------------
    " parameter completion

    " lsdyna column start index
    let cpos = ((float2nr((virtcol(".")-1)/10))*10)
    " & index from begining of lsdyna column
    let apos = stridx(strpart(line, cpos, col(".")-cpos), '&')
    if apos > -1
      let b:lsdynaCompleteType = 'parameter'
      return cpos+apos+1
    endif

    "---------------------------------------------------------------------------
    " field completion
    "
    let fpos = ((float2nr((virtcol(".")-1)/10))*10)
    let b:lsdynaCompleteType = 'field'
    return fpos

  "-----------------------------------------------------------------------------
  " 2nd function call --> build completion list
  else

    " remove whit signs from completion string
    let base = substitute(a:base,'\s','','g')

    "---------------------------------------------------------------------------
    " keyword completion
    if b:lsdynaCompleteType == 'keyword'

      let keywords = []
      for keyword in g:lsdynaLibKeywords
        if keyword =~? '^' . a:base | call add(keywords, keyword) | endif
      endfor
      return keywords

    "---------------------------------------------------------------------------
    "parameter completion
    elseif b:lsdynaCompleteType == 'parameter'

      " build completion list for parameters only
      call g:dtags.set('parameter', g:lsdynaSearchMode)
      " loop over tags list to build completion list
      let parameters = []
      for tag in g:dtags.get('parameter')
        if tag.id =~? '^'.base
          call add(parameters, {'word' : tag.id,
                              \ 'menu' : tag.title[2:],
                              \ 'kind' : tag.title[0]})
        endif
      endfor
      return parameters

    "---------------------------------------------------------------------------
    " field completion (kvar or id)
    elseif b:lsdynaCompleteType == 'field'

      " get keyword and field name
      let items = []
      let keyword = tolower(getline(search('^\*\a', 'bn'))[1:])
      let header = tolower(lsdyna_complete#getOption())

      "-------------------------------------------------------------------------
      " keyword variable (kvar) completion

      " get kvars and if not empty return completion list
      let kvars = g:kvars.get(keyword, header)
      echom string(kvars)
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
      " count number of keyword typs I am looking for
      " used later for kind --> if only one type on the list do not add kind to completion list
      let nrKeys = len(split(keywords))
      " build list of tags
      call g:dtags.set(keywords, g:lsdynaSearchMode)
      " loop over tags list to build completion list
      for tag in g:dtags.get(keywords)
        if tag.id =~? '^'.base || tag.title =~? base
          " add new item to completion list
          call add(items, {'word' : printf("%10s", tag.id),
                         \ 'menu' : tag.title,
                         \ 'kind' : nrKeys > 1 ? tag.kind[0] : '',
                         \ 'dup'  : 1})
        endif
      endfor
      return items

    endif

  endif

endfunction

"-------------------------------------------------------------------------------

function lsdyna_complete#getOption()

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

  " save unnamed register
  let tmpUnnamedReg = @@

  " remove empty line if exists
  if len(getline('.')) == 0
    normal! ddk
  endif

  " get keyword from current line
  if getline('.')[0] == "*"
    let keyword = tolower(getline('.')[1:])
  else
    let keyword = tolower(getline('.')[0:])
  endif

  " extract sub directory name from keyword name
  let KeyLibSubDir = keyword[0] . "/"

  " set keyword file path
  let file = g:lsdynaPathKeywords . KeyLibSubDir . keyword . ".k"

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

  " do not mapp if menu not visible
  if !pumvisible() | return "\<CR>" | endif

  " choose mapping depend on completion type
  if b:lsdynaCompleteType == 'keyword'
    let mapStr = "\<CR>\<ESC>:call lsdyna_complete#InputKeyword()\<CR>"
  elseif b:lsdynaCompleteType == 'parameter'
    let mapStr = "\<CR>\<ESC>"
  elseif b:lsdynaCompleteType == 'field'
    let mapStr = "\<CR>\<ESC>"
  else
    let mapStr = "\<CR>"
  endif

  " reset completion type
  let b:lsdynaCompleteType = 'none'

  return mapStr

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#lsdynamapCtrly()

  " do not mapp if menu not visible
  if !pumvisible() | return "\<C-Y>" | endif

  " choose mapping depend on completion type
  if b:lsdynaCompleteType == 'keyword'
    let mapStr = "\<ESC>:call lsdyna_complete#InputKeyword()\<CR>"
  elseif b:lsdynaCompleteType == 'parameter'
    let mapStr = "\<ESC>"
  elseif b:lsdynaCompleteType == 'field'
    let mapStr = "\<ESC>"
  else
    let mapStr = "\<C-Y>"
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
