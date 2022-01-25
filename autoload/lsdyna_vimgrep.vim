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

"function! lsdyna_vimgrep#Vimgrep(kwords, file, mode)
function! lsdyna_vimgrep#Vimgrep(what, options)

  "-----------------------------------------------------------------------------
  " Vimgrep wrapper to look for Ls-Dyna keywords.
  "
  " Arguments:
  " - what (string)  : words to search
  " - options (dict) : vimgrep options
  "   - options.files : list of files to search
  "   - options.includes : flag to search inside includes
  "   - options.notlook : reverse flag for search pattern
  "   - options.type    : search type
  "     - 'string' : search literal string
  "     - 'kword'  : search ls-dyna keywords
  "
  " Return:
  " - qf (number) : quicklist id with search results
  "-----------------------------------------------------------------------------

  "-----------------------------------------------------------------------------
  " set options
  let options = {}
  let options.files    = get(a:options, 'files', '%')
  let options.includes = get(a:options, 'includes', 0)
  let options.notlook  = get(a:options, 'notlook', 0)
  let options.type     = get(a:options, 'type', 'kword')

  "-----------------------------------------------------------------------------
  " process options

  if options.type ==? 'string'
    let search_pattern = split(a:what, '\s\+')
    let search_pattern = '\(' .. join(search_pattern, '\|') .. '\)'
  elseif options.type ==? 'kword'
    " 'part *Section' --> '^*\(PART\|SECTION\)'
    let kwords = substitute(a:what, '*', '', 'g')
    let kwords = toupper(kwords)
    let kwords = split(kwords, '\s\+')
    let search_pattern = '^\(\' .. g:lsdynaCommentString .. '\)\?\*\('.join(kwords, '\|').'\)'
  endif

  if options.notlook
    let search_pattern = search_pattern .. '\@!'
  endif

  if options.includes
    let incls = <SID>SearchIncludes(options.files)
  else
    let incls = []
  endif

  "-----------------------------------------------------------------------------

  " save current qf list id
  "let qfid_ = getqflist({'nr':0, 'id':0}).id

  if search_pattern =~? 'INCLUDE' && options.includes
     " If I am looking for *INCLUDE keywords in many files there is no point
     " to use "vimgrep" second time since "SearchIncludes" already did the job.
     " Another advantage is file order in quickfix list.
     " - include_A.inc             include_A.inc
     " - include_A1.inc            include_B.inc
     " - include_A2.inc    VS.     include_A1.inc
     " - include_B.inc             include_A2.inc
     " - include_B1.inc            include_B1.inc
     "
    call setqflist([], ' ', #{
    \    items: map(incls, {_,val -> {'bufnr':val.bufnr, 'lnum':val.first}}),
    \    title: 'Vimgrep '..search_pattern,
    \    context: #{type:'vimgrep', 
    \               command: ':vimgrep /\c'..search_pattern..'/j'},
    \    })
 
  else
    " filter() --> remove hided *INCLUDES so I do not search inside them
    let files = options.files .. ' ' .. join(map(filter(incls, '!v:val.hide'), 'v:val.path'))
    execute 'noautocmd silent! vimgrep /\c' .. search_pattern .. '/j ' .. files
    call setqflist([], 'r', #{
    \    nr: '$',
    \    title: 'Vimgrep '..search_pattern,
    \    context: #{type:'vimgrep', 
    \               command: ':vimgrep /\c'..search_pattern..'/j'},
    \    })
  endif

  " quickfix id of the latest created list
  let qfid = getqflist({'nr':'$', 'id':0}).id
  "echo getqflist({'id':qfid, 'items':''}).items

  " restore old qf list
  "let qfnr = getqflist({'id':qfid_, 'nr':''}).nr
  "silent execute qfnr .. 'chistory'

  return qfid

endfunction

"-------------------------------------------------------------------------------

function! s:SearchIncludes(file, ...)

  " list of includes to start
  let includes = a:0 > 0 ? a:1 : []

  " look for all includes in specific file
  execute 'noautocmd silent! vimgrep /\c^\('..g:lsdynaCommentString..'\)\?\*INCLUDE/j ' . a:file
  let qflist = getqflist()

  " I've found nothing so I am out
  if !len(qflist) | return includes | endif

  " collect all *INCLUDE in current file
  let includes_infile = []
  for item in qflist
      let incls = lsdyna_parser#Keyword(item.lnum, item.bufnr, '')._Include()
      call extend(includes_infile, incls)
  endfor

  " loop over includes I found in current call and
  " if path is valid and path is not directory search inside new *INCLUDE
  for incl in includes_infile
    call add(includes, incl)
    let file = lsdyna_include#Resolve(incl.path)
    if !incl.hide && file.read && !isdirectory(file.path)
      let includes = <SID>SearchIncludes(file.path, includes)
    endif
  endfor

  return includes

endfunction

"-------------------------------------EOF---------------------------------------
