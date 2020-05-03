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

function! lsdyna_vimgrep#Vimgrep(kword, file, mode)

  "-----------------------------------------------------------------------------
  " Vimgrep wrapper to look for Ls-Dyna keywords
  "
  " Arguments:
  " - kword : list of keywords for search (* - any keyword)
  " - file  : file where to start search (% - current buffer)
  " - mode  : search mode
  "           ''  - a:file only
  "           'i' - a:file + includes
  " Return:
  " - None
  " Examples:
  " lsdyna_vimgrep#Vimgrep('part', '%', 'b')
  " lsdyna_vimgrep#Vimgrep('part section mat', '%', 'b')
  " lsdyna_vimgrep#Vimgrep('*', '%', 'i')
  "-----------------------------------------------------------------------------

  let kwords = split(a:kword, '\s\+')
  "call map(kwords, 'toupper(v:val[0]=="*"?v:val:"*".v:val)')
  for i in range(len(kwords))
    let kwords[i] = kwords[i][0]=='*' ? kwords[i] : '*'.kwords[i]
    let kwords[i] = toupper(kwords[i])
  endfor
  let search_pattern = join(kwords, '\|')

  " set paths where to search
  if empty(a:mode)
    let paths = a:file
  elseif a:mode == 'i'
    let incls = <SID>SearchIncludes(a:file)
    "echo incls[0].Qf()
    "call input('key')
    " if I am looking for *INCLDE I do not need make second vimgrep pass.
    " SearchIncludes function already return list of include object so I can
    " manually set qf list here plus it has correct order of includes
    if search_pattern ==? '*INCLUDE'
      call setqflist(map(incls, '{"lnum":v:val.first, "bufnr":v:val.bufnr}'))
      return
    endif
    let paths = a:file.' '.join(map(incls, 'v:val.path'))
  endif

  " fire vimgrep
  execute 'noautocmd silent! vimgrep /\c^'.search_pattern.'/j '.paths

  return

endfunction

"-------------------------------------------------------------------------------

function! s:SearchIncludes(file, ...)

  " carry over includes found in previous search
  let includes = a:0 > 0 ? a:1 : []

  " look for all includes in specific file
  execute 'noautocmd silent! vimgrep /\c^*INCLUDE/j ' . a:file
  let qflist = getqflist()

  " I found nothing so I am out
  if !len(qflist) | return includes | endif

  " collect all *INCLUDE in current file
  let includes_infile = []
  for item in qflist
      let incls = lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fc')._Include()
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
