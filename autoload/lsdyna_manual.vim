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

function! lsdyna_manual#Manual(arg1)

  "-----------------------------------------------------------------------------
  " Open ls-dyna manual pdf file at keyword at line 'lnum'.
  "
  " Arguments:
  " - lnum : line number
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  let page = 0
  let manual_bookmarks = <SID>ReadBookmarks(g:lsdynaPathManual.'keywords.txt') 

  " if argument is a number I am looking for lsdyna keyword at a:arg1 line
  " if argument is a string this is a keyowrd I am looking for
  if type(a:arg1) == v:t_number
    let kword = lsdyna_parser#Keyword(a:arg1, bufnr('%'), 'cn').name
    let kword = substitute(kword, '\s*[+%]\s*$', '', '')
  elseif type(a:arg1) == v:t_string
    let kword = a:arg1
  endif
  let kword = kword[0] == '*' ? kword : '*'.kword

  " keep only bookmarks starting with prefix
  let kword_prefix = split(kword, '_')[0]
  call filter(manual_bookmarks, 'v:key =~? kword_prefix')

  " using bookmarks find file and page where kword is described
  for key in reverse(sort(keys(manual_bookmarks)))
    if kword =~? key
      let page = manual_bookmarks[key].page "pdf page with keyword
      let file = g:lsdynaPathManual.manual_bookmarks[key].file " full path to pdf volume
      break
    endif
  endfor

  if page
    if has("win32") || has("win64")
      let file = substitute(file,'/','\','g')
      let cmd = '!start /B '. g:lsdynaPathAcrobat.' /A page='.page.' '.file
      silent execute cmd
    endif
  elseif has("unix")
     let cmd = ':! '. g:lsdynaPathAcrobat.' '.file.' -P '.page
     silent execute cmd
  else
    echo 'No manual found for "'..kword..'"'
  endif

endfunction

"-------------------------------------------------------------------------------

function! s:ReadBookmarks(file)

  "-----------------------------------------------------------------------------
  " Function to read manual bookmarks manual.
  "
  " Arguments:
  " - file  : path to bookmarks file
  " Return:
  " - bookmarks (dict) : {keyword : {file, page}}
  "-----------------------------------------------------------------------------

  let bookmarks_file = readfile(a:file)

  let volumes = []
  call add(volumes, split(bookmarks_file[0], '=')[0])
  call add(volumes, split(bookmarks_file[1], '=')[0])
  call add(volumes, split(bookmarks_file[2], '=')[0])

  let bookmarks = {}
  for sline in bookmarks_file[4:]
    let split_equal = split(sline, '=')
    let split_coma = split(split_equal[1], ',')
    let bookmarks[split_equal[0]] = {'file' : volumes[split_coma[0]-1], 'page':split_coma[1]}
  endfor

  return bookmarks

endfunction

"-------------------------------------EOF---------------------------------------
