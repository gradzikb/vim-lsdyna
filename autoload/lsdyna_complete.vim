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
    let fpos = ((float2nr((virtcol(".")-1)/10))*10)
    let b:lsdynaCompleteType = 'field'
    return fpos

  "-----------------------------------------------------------------------------
  " 2nd function call --> build completion list
  else

    "---------------------------------------------------------------------------
    " keyword completion
    if b:lsdynaCompleteType == 'keyword'

      let keywords = []
      for keyword in g:lsdynaKeyLib
        if keyword =~? '^' . a:base | call add(keywords, keyword) | endif
      endfor
      return keywords

    "---------------------------------------------------------------------------
    "parameter completion
    elseif b:lsdynaCompleteType == 'parameter'

      " update tag list
      call lsdyna_complete#tags(g:lsdynaTagsPath, g:lsdynaSearchMode)
      " build completion list
      let params = []
      for param in lsdyna_complete#checkTags("param")
        if param['word'] =~ '^'.a:base | call add(params,param) | endif
      endfor
      return params

    "---------------------------------------------------------------------------
    " field completion (option or id)
    elseif b:lsdynaCompleteType == 'field'

      " get keyword and field name
      let keyword = tolower(getline(search('^\*\a', 'bn'))[1:])
      let option = lsdyna_complete#getOption()

      " set option list
      let items = lsdyna_complete#checkOptLib(keyword, option)
      if len(items) | return items | endif

      " if empty set id list
      call lsdyna_complete#tags(g:lsdynaTagsPath, g:lsdynaSearchMode)
      for tag in lsdyna_complete#checkTags(option)
        let basetmp = substitute(a:base,"\\s","","g")
        let id     = substitute(tag['word'],"\\s","","g")
        let title  = substitute(tag['menu'],"\\s","","g")
        if id =~? '^'.basetmp || title =~? basetmp | call add(items, tag) | endif
      endfor
      return items

    endif

  endif

endfunction

"-------------------------------------------------------------------------------

function lsdyna_complete#getOption()

  "-----------------------------------------------------------------------------
  " Function to find keyword option in libe above.
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

function! lsdyna_complete#InitKeyLib(path)

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

function! lsdyna_complete#InitOptLib(path)

  "-----------------------------------------------------------------------------
  " Function to initialize Ls-Dyna options library.
  "
  " Arguments:
  " - path (string) : path to directory with omni completion library
  " Return:
  " - omniLib (dict) : omni completion library
  "-----------------------------------------------------------------------------

  " read all lines from file
  let lines = readfile(a:path)

  let omniLib = {}
  for lineStr in lines

    " get keyword and option
    let line = split(lineStr,'\s*;\s*')
    let keyName = tolower(line[0])
    let optName = tolower(line[1])

    " add keyword if not exists
    if !has_key(omniLib, keyName)
      let omniLib[keyName] = {}
    endif

    " add option if not exists
    if !has_key(omniLib[keyName], optName)
      let omniLib[keyName][optName] = []
    endif

    " add menu entry
    let tmpEntry = {}
    let tmpEntry['word'] = printf("%10s", line[2])
    let tmpEntry['menu'] = line[3]
    call add(omniLib[keyName][optName], tmpEntry)

  endfor

  return omniLib

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

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#extendLine()

  "-----------------------------------------------------------------------------
  " Function to extend line with signs, workaround for case when
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

function! lsdyna_complete#checkOptLib(keyword, option)

  "-----------------------------------------------------------------------------
  " Function to build completion list for specific keyword and option.
  "
  " Arguments:
  " - keyword (string) : lsdyna keyword
  " - option (string) : option (dof, vad, ...)
  " Return:
  " - items (list) : completion list
  "-----------------------------------------------------------------------------

  " loop over keywords in omni library
  for name in keys(g:lsdynaOptLib)
    if a:keyword =~? name
      return get(g:lsdynaOptLib[name], a:option, [])
    endif
  endfor

  return []

endfunction

"-------------------------------------------------------------------------------

function!  lsdyna_complete#keyword2tag(bnum, lnum)

  "-----------------------------------------------------------------------------
  " Function to create tag line from keyword.
  "
  " Arguments:
  " - bnum (number) : buffer number
  " - lnum (number) : line number with keyword
  " Return:
  " - tag (list) : tags
  "-----------------------------------------------------------------------------

  " go to buffer with current keyword
  if bufnr("%") != a:bnum
    execute "buffer " . a:bnum
  endif

  let tags = []
  let kw = getline(a:lnum)

  " keyword --> tag
  if kw =~? '^\*PART'
    let tags = lsdyna_complete#part2tag(a:lnum)
  elseif kw =~? '^\*SECTION'
    let tags = lsdyna_complete#section2tag(a:lnum)
  elseif kw =~? '^\*MAT'
    let tags = lsdyna_complete#material2tag(a:lnum)
  elseif kw =~? '^\*SET'
    let tags = lsdyna_complete#set2tag(a:lnum)
  elseif kw =~? '^\*DEFINE_CURVE'
    let tags = lsdyna_complete#curve2tag(a:lnum)
  elseif kw =~? '^\*DEFINE_TRANSFORMATION'
    let tags = lsdyna_complete#transformation2tag(a:lnum)
  elseif kw =~? '^\*DEFINE_VECTOR'
    let tags = lsdyna_complete#vector2tag(a:lnum)
  elseif kw =~? '^\*DEFINE_COORDINATE'
    let tags = lsdyna_complete#coordinate2tag(a:lnum)
  elseif kw =~? '^\*PARAMETER\s*$' || kw =~? '^\*PARAMETER_LOCAL\s*$'
    let tags = lsdyna_complete#parameter2tag(a:lnum)
  elseif kw =~? '^\*PARAMETER_EXPRESSION'
    let tags = lsdyna_complete#parameterExpr2tag(a:lnum)
  endif

  return tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#part2tag(lnum)

  " Function to grap *PART_ keyword and convert to tag.

  let tagfile = expand("%:p") " get current file path and name
  let tagkind = "PART"        " set tag kind

  let tags = [] " list of tags
  let i = 1     " all lines index
  let kwlnum = 1    " keyword lines index

  " get keyword
  let keyword = getline(a:lnum)

  " keyword lines
  if keyword =~? '^\*PART_CONTACT\s*$'
    let kwLines = 3
  elseif keyword =~? '^\*PART_INERTIA\s*$'
    let kwLines = 5
  else
    let kwLines = 2
  endif

  "main loop over lines
  while 1
    " end of file --> break
    if a:lnum+i == line("$") | break | endif
    " take next line after keyword line
    let line = getline(a:lnum+i)
    " keyword line --> break
    if line[0] == '*' | break | endif
    " comment line --> go to next line
    if line[0] == '$' | let i = i + 1 | continue | endif

    " take first line --> title
    if kwlnum == 1
      let tagtitle = line
    " take second line --> id
    elseif kwlnum == 2
      let tagname = substitute(line[:9], "\\s*", "", "g")
      let tagaddress = a:lnum + i
      call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
    endif

    " keyword line index, if max reset to 1
    if kwlnum == kwLines
      let kwlnum = 1
    else
      let kwlnum = kwlnum + 1
    endif

    " line index
    let i = i + 1

  endwhile

  return tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#section2tag(lnum)

  " Function to grap *SECTION_ keyword and convert to tag.

  let tagfile = expand("%:p") " get current file path and name
  let tagkind = "SECTION"    " set tag kind

  let tags = []  " list of tags
  let i = 1      " all lines index
  let kwlnum = 1 " keyword lines index

  " get keyword
  let keyword = getline(a:lnum)

  "main loop over lines
  while 1
    " end of file --> break
    if a:lnum+i == line("$") | break | endif
    " take next line after keyword line
    let line = getline(a:lnum+i)
    " keyword line --> break
    if line[0] == '*' | break | endif
    " comment line --> go to next line
    if line[0] == '$' | let i = i + 1 | continue | endif

    " with TITLE option
    if keyword =~? "TITLE"
      " take first line --> title
      if kwlnum == 1
        let tagtitle = line
        let kwlnum = kwlnum + 1
      " take second line --> id
      elseif kwlnum == 2
        let tagname = substitute(line[:9], "\\s*", "", "g")
        let tagaddress = a:lnum + i
        call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
        break
      endif
    " without TITLE option
    else
        let tagtitle = ""
        let tagname = substitute(line[:9], "\\s*", "", "g")
        let tagaddress = a:lnum + i
        call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
        break
    endif

    " line index
    let i = i + 1

  endwhile

  return tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#material2tag(lnum)

  " Function to grap *DEFINE_CURVE keyword and convert to tag.

  let tagfile = expand("%:p") " get current file path and name
  let tagkind = "MATERIAL"    " set tag kind

  let tags = []   " list of tags
  let i = 1       " all lines index
  let kwlnum = 1  " keyword lines index

  " get keyword
  let keyword = getline(a:lnum)

  "main loop over lines
  while 1
    " end of file --> break
    if a:lnum+i == line("$") | break | endif
    " take next line after keyword line
    let line = getline(a:lnum+i)
    " keyword line --> break
    if line[0] == '*' | break | endif
    " comment line --> go to next line
    if line[0] == '$' | let i = i + 1 | continue | endif

    " with TITLE option
    if keyword =~? "TITLE"
      " take first line --> title
      if kwlnum == 1
        let tagtitle = line
        let kwlnum = kwlnum + 1
      " take second line --> id
      elseif kwlnum == 2
        let tagname = substitute(line[:9], "\\s*", "", "g")
        let tagaddress = a:lnum + i
        call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
        break
      endif
    " without TITLE option
    else
        let tagtitle = ""
        let tagname = substitute(line[:9], "\\s*", "", "g")
        let tagaddress = a:lnum + i
        call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
        break
    endif

    " line index
    let i = i + 1

  endwhile

  return tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#curve2tag(lnum)

  " Function to grap *DEFINE_CURVE keyword and convert to tag.

  let tagfile = expand("%:p") " get current file path and name
  let tagkind = "CURVE"        " set tag kind

  let tags = []  " list of tags
  let i = 1      " all lines index
  let kwlnum = 1 " keyword lines index

  " get keyword
  let keyword = getline(a:lnum)

  "main loop over lines
  while 1
    " end of file --> break
    if a:lnum+i == line("$") | break | endif
    " take next line after keyword line
    let line = getline(a:lnum+i)
    " keyword line --> break
    if line[0] == '*' | break | endif
    " comment line --> go to next line
    if line[0] == '$' | let i = i + 1 | continue | endif

    " with TITLE option
    if keyword =~? "TITLE"
      " take first line --> title
      if kwlnum == 1
        let tagtitle = line
        let kwlnum = kwlnum + 1
      " take second line --> id
      elseif kwlnum == 2
        let tagname = substitute(line[:9], "\\s*", "", "g")
        let tagaddress = a:lnum + i
        call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
        break
      endif
    " without TITLE option
    else
        let tagtitle = ""
        let tagname = substitute(line[:9], "\\s*", "", "g")
        let tagaddress = a:lnum + i
        call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
        break
    endif

    " line index
    let i = i + 1

  endwhile

  return tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#set2tag(lnum)

  " Function to grap *DEFINE_CURVE keyword and convert to tag.

  let tagfile = expand("%:p") " get current file path and name
  let tagkind = "SET"         " set tag kind

  let tags = []  " list of tags
  let i = 1      " all lines index
  let kwlnum = 1 " keyword lines index

  " get keyword
  let keyword = getline(a:lnum)

  "main loop over lines
  while 1
    " end of file --> break
    if a:lnum+i == line("$") | break | endif
    " take next line after keyword line
    let line = getline(a:lnum+i)
    " keyword line --> break
    if line[0] == '*' | break | endif
    " comment line --> go to next line
    if line[0] == '$' | let i = i + 1 | continue | endif

    " with TITLE option
    if keyword =~? "TITLE"
      " take first line --> title
      if kwlnum == 1
        let tagtitle = line
        let kwlnum = kwlnum + 1
      " take second line --> id
      elseif kwlnum == 2
        let tagname = substitute(line[:9], "\\s*", "", "g")
        let tagaddress = a:lnum + i
        call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
        break
      endif
    " without TITLE option
    else
        let tagtitle = ""
        let tagname = substitute(line[:9], "\\s*", "", "g")
        let tagaddress = a:lnum + i
        call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
        break
    endif

    " line index
    let i = i + 1

  endwhile

  return tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#transformation2tag(lnum)

  " Function to grap *DEFINE_TRANSFORMATION keyword and convert to tag.

  let tagfile = expand("%:p") " get current file path and name
  let tagkind = "TRSFM"       " set tag kind

  let tags = [] " list of tags
  let i = 1     " all lines index
  let kwlnum = 1    " keyword lines index

  " get keyword
  let keyword = getline(a:lnum)

  "main loop over lines
  while 1
    " end of file --> break
    if a:lnum+i == line("$") | break | endif
    " take next line after keyword line
    let line = getline(a:lnum+i)
    " keyword line --> break
    if line[0] == '*' | break | endif
    " comment line --> go to next line
    if line[0] == '$' | let i = i + 1 | continue | endif

    " with TITLE option
    if keyword =~? "TITLE"
      " take first line --> title
      if kwlnum == 1
        let tagtitle = line
        let kwlnum = kwlnum + 1
      " take second line --> id
      elseif kwlnum == 2
        let tagname = substitute(line[:9], "\\s*", "", "g")
        let tagaddress = a:lnum + i
        call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
        break
      endif
    " without TITLE option
    else
        let tagtitle = ""
        let tagname = substitute(line[:9], "\\s*", "", "g")
        let tagaddress = a:lnum + i
        call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
        break
    endif

    " line index
    let i = i + 1

  endwhile

  return tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#vector2tag(lnum)

  " Function to grap *DEFINE_VECTOR keyword and convert to tag.

  let tagfile = expand("%:p") " get current file path and name
  let tagkind = "VECTOR"      " set tag kind

  let tags = []  " list of tags
  let i = 1      " all lines index
  let kwlnum = 1

  " get keyword
  let keyword = getline(a:lnum)

  "main loop over lines
  while 1
    " end of file --> break
    if a:lnum+i == line("$") | break | endif
    " take next line after keyword line
    let line = getline(a:lnum+i)
    " keyword line --> break
    if line[0] == '*' | break | endif
    " comment line --> go to next line
    if line[0] == '$' | let i = i + 1 | continue | endif

    " keyword with TITLE
    if keyword =~? "TITLE"
      " take first line --> title
      if kwlnum == 1
        let tagtitle = line
        let kwlnum = kwlnum + 1
      " take second line --> id
      elseif kwlnum == 2
        let tagname = substitute(line[:9], "\\s*", "", "g")
        let tagaddress = a:lnum + i
        call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
        let kwlnum = 1
      endif
    " keyword with out TITLE
    else
      let tagtitle = ""
      let tagname = substitute(line[:9], "\\s*", "", "g")
      let tagaddress = a:lnum + i
      call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
    endif

    " line index
    let i = i + 1

  endwhile

  return tags

endfunction

function! lsdyna_complete#coordinate2tag(lnum)

  " Function to grap *DEFINE_COORDINATE keyword and convert to tag.

  let tagfile = expand("%:p") " get current file path and name
  let tagkind = "COORD"       " set tag kind

  let tags = []  " list of tags
  let i = 1      " all lines index
  let kwlnum = 1

  " get keyword
  let keyword = getline(a:lnum)

  "main loop over lines
  while 1
    " end of file --> break
    if a:lnum+i == line("$") | break | endif
    " take next line after keyword line
    let line = getline(a:lnum+i)
    " keyword line --> break
    if line[0] == '*' | break | endif
    " comment line --> go to next line
    if line[0] == '$' | let i = i + 1 | continue | endif

    " keyword with TITLE
    if keyword =~? "TITLE"
      " *DEF_COORD_SYSTEM --> 2 line definition
      if keyword =~? "SYSTEM"
        " take first line --> title
        if kwlnum == 1
          let tagtitle = line
          let kwlnum = kwlnum + 1
        " take second line --> id
        elseif kwlnum == 2
          let tagname = substitute(line[:9], "\\s*", "", "g")
          let tagaddress = a:lnum + i
          call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
          let kwlnum = kwlnum + 1
        " skip 3rd line and resen line index
        elseif kwlnum == 3
          let kwlnum = 1
        endif
      " other cases --> one line definition
      else
        " take first line --> title
        if kwlnum == 1
          let tagtitle = line
          let kwlnum = kwlnum + 1
        " take second line --> id
        elseif kwlnum == 2
          let tagname = substitute(line[:9], "\\s*", "", "g")
          let tagaddress = a:lnum + i
          call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
          let kwlnum = 1
        endif
      endif
    " keyword with out TITLE
    else
      " *DEF_COORD_SYSTEM --> 2 line definition
      if keyword =~? "SYSTEM"
        if kwlnum == 1
          let tagtitle = ""
          let tagname = substitute(line[:9], "\\s*", "", "g")
          let tagaddress = a:lnum + i
          call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
          let kwlnum = kwlnum + 1
        elseif kwlnum == 2
          let kwlnum = 1
        endif
      " other cases --> one line definition
      else
        let tagtitle = ""
        let tagname = substitute(line[:9], "\\s*", "", "g")
        let tagaddress = a:lnum + i
        call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
      endif
    endif

    " line index
    let i = i + 1

  endwhile

  return tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#parameter2tag(lnum)

  " Function to grap *PARAMETER keyword and convert to tag.

  " current file
  let tagfile = expand("%:p")
  " tag kind
  let tagkind = "PARAM"

  let tags = []
  let i = 1

  "main loop over keyword lines
  while 1
    " end of file --> break
    if a:lnum+i == line("$") | break | endif
    " take next line after keyword line
    let line = getline(a:lnum+i)
    " keyword line --> break
    if line[0] == '*' | break | endif
    " comment line --> go to next line
    if line[0] == '$' | let i = i + 1 | continue | endif
    " loop for columns with parameters
    for col in range(0, 80, 20)
      " take 10 width column
      let paramName = strpart(line, col+1, 10)
      " if not empty grap parameter type/name/value
      if len(paramName) != 0
        let tagname = substitute(paramName, "\\s*", "", "g")
        let tagtitle = line[col]." ".substitute(strpart(line, col+10, 10), "\\s*", "", "g")
        let tagaddress = a:lnum+i
        call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
      endif
    endfor
    " increment loop id
    let i = i + 1
  endwhile

  return tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#parameterExpr2tag(lnum)

  " Function to grap *PARAMETER_EXPRESSION keyword and convert to tag.

  " current file
  let tagfile = expand("%:p")
  " tag kind
  let tagkind = "PARAM"

  let tags = []
  let i = 1

  "main loop over keyword lines
  while 1
    " end of file --> break
    if a:lnum+i == line("$") | break | endif
    " take next line after keyword line
    let line = getline(a:lnum+i)
    " keyword line --> break
    if line[0] == '*' | break | endif
    " comment line --> go to next line
    if line[0] == '$' | let i = i + 1 | continue | endif
    " loop for columns with parameters
    if line[0] =~? "[IRC]"
      let tagname = substitute(strpart(line, 1, 10), "\\s*", "", "g")
      let tagtitle = line[0] . substitute(line[9:],"\\s","","g")
      let tagaddress = a:lnum+i
      call add(tags, tagname."\t".tagfile."\t".tagaddress.";\""."\t"."kind:".tagkind."\t"."title:".tagtitle)
    endif
    " increment loop id
    let i = i + 1
  endwhile

  return tags

endfunction
"-------------------------------------------------------------------------------

function! lsdyna_complete#tags(tagfile, searchMode)

  "-----------------------------------------------------------------------------
  " Function to write dynatags file.
  "
  " Arguments:
  " - tagfile (string)   : file to store tag entries
  " - dynafiles (string) : lsdyna files for scan
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " list of keyword to find
  let keywords = ['^\*PART',
               \  '^\*SECTION',
               \  '^\*MAT',
               \  '^\*SET',
               \  '^\*DEFINE_CURVE',
               \  '^\*DEFINE_TRANSFORMATION',
               \  '^\*DEFINE_COORDINATE',
               \  '^\*DEFINE_VECTOR',
               \  '^\*PARAMETER']
  " find keywords for tag lists
  let reVimgrep = join(keywords, '\|')

  " save current buffer
  let buf1st = bufnr("%")

  if a:searchMode == 0
    " clear quickfix lists --> no search
    call setqflist([])
  elseif a:searchMode == 1
    " search only in current buffer
    silent! execute "noautocmd vimgrep /".reVimgrep."/j %"
  elseif a:searchMode == 2
    " search in all lodaed buffers
    call setqflist([])
    silent! execute "bufdo! noautocmd vimgrepadd /".reVimgrep."/j %"
  elseif a:searchMode == 3
    " load includes to buffers and search in all buffers
    call lsdyna_include#incl2buff()
    call setqflist([])
    silent! execute "bufdo! noautocmd vimgrepadd /".reVimgrep."/j %"
  endif

  " create tag for each quickfix list entry
  let tags = []
  for qf in getqflist()
    call extend(tags, lsdyna_complete#keyword2tag(qf['bufnr'],qf['lnum']))
  endfor

  " go back to orginal buffer
  execute "buffer " . buf1st

  " write file with all tags
  call writefile(tags, a:tagfile)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_complete#checkTags(kind)

  "-----------------------------------------------------------------------------
  " Function to create completion list from tags list for specific kind tag.
  "
  " Arguments:
  " - kind (string) : tag kind
  " Return:
  " - items (list) : completion list
  "-----------------------------------------------------------------------------

  " lsdyna comment - tag kind pair lists
  let kind = {'pid':'PART',
           \  'secid':'SECTION',
           \  'mid':'MATERIAL',
           \  'lcid':'CURVE',
           \  'rlcid':'CURVE',
           \  'lca':'CURVE',
           \  'lcb':'CURVE',
           \  'lcab':'CURVE',
           \  'lcua':'CURVE',
           \  'lcub':'CURVE',
           \  'lcuab':'CURVE',
           \  'lcaa':'CURVE',
           \  'lcbb':'CURVE',
           \  'lctim':'CURVE',
           \  'tsrfac':'CURVE',
           \  'flc':'CURVE',
           \  'fac':'CURVE',
           \  'lcss':'CURVE',
           \  'tranid':'TRSFM',
           \  'trsid':'TRSFM',
           \  'cid':'COORD',
           \  'cida':'COORD',
           \  'cidb':'COORD',
           \  'vid':'VECTOR',
           \  'param':'PARAM'}

  " unknown kind --> add set & parts
  " I am doing two loops so sets are on the top of completion list
  let items = []
  if !has_key(kind, a:kind)

    " loop for sets
    let sets = []
    for tag in taglist(".")
      if '^\*SET' =~? tag['kind']
        let tagName = printf("%10s", tag['name'])
        call add (sets,{'word':tagName,'menu':tag['title'],'kind':tag['kind'][0],'dup':0,})
      endif
    endfor

    " loop for parts
    let parts = []
    for tag in taglist(".")
      if '^\*PART' =~? tag['kind']
        let tagName = printf("%10s", tag['name'])
        call add (parts,{'word':tagName,'menu':tag['title'],'kind':tag['kind'][0],'dup':1})
      endif
    endfor

  return sort(sets) + sort(parts)

  " known kind
  else

    for tag in taglist(".")
      if kind[a:kind] =~? tag['kind']
        " parameters
        if a:kind =~? 'param'
          let tagName = tag['name']
          call add (items,{'word':tagName,'menu':tag['title'][2:],'kind':tag['title'][0]})
        " others
        else
          let tagName = printf("%10s", tag['name'])
          call add (items,{'word':tagName,'menu':tag['title']})
        endif
      endif
    endfor

  return sort(items)

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

"-------------------------------------EOF---------------------------------------
