"-------------------------------------BOF---------------------------------------
"
" Vimgrep wrapper for Ls-Dyna keywords search.
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  13.10.2017
"
"-------------------------------------------------------------------------------

function! lsdyna_vimgrep#Vimgrep(kwords, file, mode)

  "-----------------------------------------------------------------------------
  " Vimgrep wrapper to look for Ls-Dyna keywords.
  "
  " Arguments:
  " - kword : list of keywords for search (* - any keyword)
  " - file  : file where to start search (% - current buffer)
  " - mode  : search mode
  "           ''  - a:file only
  "           'i' - a:file + includes
  "           'r' - reverse selection (look for any kw but not a:kword)
  " Return:
  " - None
  " Examples:
  "   lsdyna_vimgrep#Vimgrep('part', '%', 'b')
  "   lsdyna_vimgrep#Vimgrep('part section mat', '%', 'b')
  "   lsdyna_vimgrep#Vimgrep('*', '%', 'i')
  "-----------------------------------------------------------------------------

  " save current qf list id
  let qfid_ = getqflist({'nr':0, 'id':0}).id

  " build regular expression for search pattern
  " "part *Section" --> "^*\(PART\|SECTION\)"
  let kwords = substitute(a:kwords, '*', '', 'g')
  let kwords = toupper(kwords)
  let kwords = split(kwords, '\s\+')
  let search_pattern = '^*\('.join(kwords, '\|').'\)'

  " use current file if not defined
  if a:file =~ '\s*'
    let file = '%'
  endif

  " reverse flag, search all keywords but not defined 
  if a:mode =~? 'r'
    let search_pattern = search_pattern.'\@!'
  endif

  " include flag, search in all include files
  if a:mode =~? 'i'
    let incls = <SID>SearchIncludes(file)
  else
    let incls = []
  endif

  if search_pattern =~? 'INCLUDE' && a:mode =~? 'i'
     " If I am looking for *INCLUDE keywords in many files there is no point
     " to use "vimgrep" second time since "SearchIncludes" already did the job.
     " Another advantage is file order in quickfix list.
     " - include_A.inc             include_A.inc
     " - include_A1.inc            include_B.inc
     " - include_A2.inc    VS.     include_A1.inc
     " - include_B.inc             include_A2.inc
     " - include_B1.inc            include_B1.inc
     "
    call setqflist([], ' ', {'items'   : map(incls, {_,val -> {'bufnr':val.bufnr, 'lnum':val.first}}),
                            \'title'   : ':vimgrep /\c' .. search_pattern .. '/j'})
  else
    let files = file .. ' ' .. join(map(incls, 'v:val.path'))
    execute 'noautocmd silent! vimgrep /\c' .. search_pattern .. '/j ' .. files
    call setqflist([], 'a', {'title' : ':vimgrep /\c' .. search_pattern .. '/j'})
  endif

  let qfid = getqflist({'nr':'$', 'id':0}).id

  " restore previous current qf list
  let qfnr = getqflist({'id':qfid_, 'nr':''}).nr
  silent execute qfnr .. 'chistory'

  return qfid

endfunction

"-------------------------------------------------------------------------------

function! s:SearchIncludes(file, ...)

  " carry over includes found in previous search
  let includes = a:0 > 0 ? a:1 : []
  if a:0 > 0
    let includes = a:1
    let s:count += 1
  else
    let includes = []
    " function call counter set to 1 for 1st function call
    " used to set include tree level
    let s:count = 0
  endif

  " look for all includes in specific file
  execute 'noautocmd silent! vimgrep /\c^*INCLUDE/j ' . a:file
  let qflist = getqflist()

  " I found nothing so I am out
  if !len(qflist) | return includes | endif

  " collect all *INCLUDE in current file
  let includes_infile = []
  for item in qflist
      let incls = lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fc')._Include()
      "call input(len(incls))
      "call map(incls, {idx,val -> val.treelvl='9'})
      "for i in range(len(incls))
      "  call input(string(incls[i]))
      "  let incls[i].treelvl = 5
      "  echom incls[i].treelvl
      "  call input(string(incls[i]))
      "endfor
      call extend(includes_infile, incls)
  endfor

  " loop over includes I found in current call and
  " if path is valid and path is not directory search inside new *INCLUDE
  for incl in includes_infile
    call add(includes, incl)
    let file = lsdyna_include#Resolve(incl.path)
    if file.read && !isdirectory(file.path)
      let includes = <SID>SearchIncludes(file.path, includes)
    endif
  endfor

  return includes

endfunction

"-------------------------------------EOF---------------------------------------
