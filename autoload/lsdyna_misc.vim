"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  5th of November 2016
"
"-------------------------------------------------------------------------------
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_misc#CommentLine() range

  " ----------------------------------------------------------------------------
  " Function to comment/uncomment selecte lines.
  " ----------------------------------------------------------------------------

  if getline(a:firstline)[0] ==? '$'
    silent execute a:firstline . ',' . a:lastline . 's/^\$//'
  else
    silent execute a:firstline . ',' . a:lastline . 's/^/$/'
  endif

endfunction

"-------------------------------------------------------------------------------

"function! lsdyna_misc#CommentSign()
"
"  " ----------------------------------------------------------------------------
"  " Function to swap '4' into '$' at the begining of line.
"  " ----------------------------------------------------------------------------
"
"  if col('.') == 2 && getline('.')[0] == '4'
"    let tmpUnnamedReg = @@
"    normal! hx
"    let @@ = tmpUnnamedReg
"    return '$'
"  else
"    return ''
"  endif
"
"endfunction

"-------------------------------------------------------------------------------

function! lsdyna_misc#KeywordTextObject()

  " ----------------------------------------------------------------------------
  " Function to select all keyword lines.
  " ----------------------------------------------------------------------------

  " keyword parser
  let kword = lsdyna_parser#Keyword(line('.'), bufnr('%'), 'c')

  " select kword lines
  execute ':' kword.first
  normal! V
  execute ':' kword.last

endfunction

"-------------------------------------------------------------------------------

"function! lsdyna_misc#getKeyword(lnum, flags)
"  "-----------------------------------------------------------------------------
"  " Function returns number of first and last line of the keyword under the
"  " cursor.
"  "
"  " Arguments:
"  " - lnum     : f - keyword line number
"  " - flags    : f - number of First kword line
"  "              l - number of Last kword number
"  "              n - kword Name
"  "              b - keyword Body (all kword lines)
"  "              d - keyword Datalines only (all comment lines are removed)
"  " Return:
"  " - {'first' : first_line_number, 'last' : last_line_number}
"  "-----------------------------------------------------------------------------
"  " default flags
"  let flags = empty(a:flags) ? 'fln' : a:flags
"  let re_kword   = '^*'       " regular expression to find keyword name
"  let re_dline = '^[^$]\|^$'  " regular expression to find dataline
"  " search first and last kword line
"  call cursor(a:lnum, 0)
"  let lnum_start = search(re_kword,'bWc')
"  let next_kw = search(re_kword, 'W')
"  if next_kw == 0 | call cursor(line('$'), 0) | endif
"  let lnum_end = next_kw == 0 ? search(re_dline,'bWc') : search(re_dline,'bW')
"  " set info base on user flags
"  let kword = {}
"  if flags =~# 'f' | let kword.first  = lnum_start | endif
"  if flags =~# 'l' | let kword.last   = lnum_end | endif
"  if flags =~# 'n' | let kword.name   = toupper(substitute(getline(lnum_start),'\s','','g')) | endif
"  if flags =~# 'b' | let kword.lines  = getline(lnum_start, lnum_end) | endif
"  if flags =~# 'd' | let kword.dlines = filter(getline(lnum_start, lnum_end), 'v:val[0] != "$"') | endif
"  return kword
"endfunction

"-------------------------------------------------------------------------------

"function! lsdyna_misc#ColumnTextObject()
"
"  " ----------------------------------------------------------------------------
"  " Function to select column with visual block.
"  " ----------------------------------------------------------------------------
"
"  " keyword/comment regular expression
"  let rekw  = '^[*]'
"  " dataline regular expression
"  let redl = '^[^$*]'
"
"  " get column number
"  if col("'<") < col(".")
"    let cnum = col(".")
"  else
"    let cnum = col("'<'")
"  endif
"
"  " set start of selection
"  " find keyword line and move to first data line below
"  let kwlnum = search(rekw, 'bcW')
"  let lnums = search(redl, 'W')
"
"  " get keyword
"  let keyword = getline(kwlnum)
"
"  " set end of selection
"  let lnumtmp = search(rekw, 'W')
"  " go to end of the file if found nothing
"  if lnumtmp == 0
"    normal! G
"  endif
"  let lnume = search(redl, 'bW')
"
"  "-----------------------------------------------------------------------------
"  if keyword =~? "*NODE.*$"
"
"    " set column start and column move
"    if cnum <= 8
"      let cstart = 1
"      let cmove = 7
"    elseif cnum > 8 && cnum <= 24
"      let cstart = 9
"      let cmove = 15
"    elseif cnum > 24 && cnum <= 40
"      let cstart = 25
"      let cmove = 15
"    elseif cnum > 40 && cnum <= 56
"      let cstart = 41
"      let cmove = 15
"    elseif cnum > 56 && cnum <= 64
"      let cstart = 57
"      let cmove = 7
"    elseif cnum > 64
"      let cstart = 65
"      let cmove = 7
"    endif
"
"  "-----------------------------------------------------------------------------
"  "elseif keyword =~? "*ELEMENT.*$"
"  else
"
"    " set column start and column move
"    let cstart = (float2nr(cnum/8)*8)+1
"    let cmove = 7
"
"  endif
"
"  " go to first line in selection and 1st position in column
"  call cursor(lnums, cstart)
"  " line move
"  let lmove = lnume - lnums
"  execute "normal! zo\<C-v>" . lmove . "j" . cmove . "lo'"
"
"endfunction

"-------------------------------------EOF---------------------------------------
