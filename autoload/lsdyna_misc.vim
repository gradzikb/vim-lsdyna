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

  if getline(a:firstline) =~? "^\\$"
    silent execute a:firstline . ',' . a:lastline . 's/^\$//'
  else
    silent execute a:firstline . ',' . a:lastline . 's/^/$/'
  endif

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_misc#CommentSign()

  if col('.') == 2 && getline('.')[0] == '4'
    let tmpUnnamedReg = @@
    normal! hx
    let @@ = tmpUnnamedReg
    return '$'
  else
    return ''
  endif

endfunction

"-------------------------------------------------------------------------------
function! lsdyna_misc#KeywordTextObject()

 let reKeyWord  = "^\*[A-Za-z_]"
 let reDataLine = "^[^$]\\|^$"

  " find keyword in backword
  call search(reKeyWord,'bWc')
  " start line visual mode
  normal! V
  " serach next keyword
  let res = search(reKeyWord, 'W')
  " go to the end of file if you did not find the keyword
  if res == 0
    normal! G
  endif
  " move back to first data line
  call search(reDataLine,'bW')

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_misc#ColumnTextObject()

  " ----------------------------------------------------------------------------
  " Function to select column with visual block.
  " ----------------------------------------------------------------------------

  " keyword/comment regular expression
  let rekw  = '^[*]'
  " dataline regular expression
  let redl = '^[^$*]'

  " get column number
  if col("'<") < col(".")
    let cnum = col(".")
  else
    let cnum = col("'<'")
  endif

  " set start of selection
  " find keyword line and move to first data line below
  let kwlnum = search(rekw, 'bcW')
  let lnums = search(redl, 'W')

  " get keyword
  let keyword = getline(kwlnum)

  " set end of selection
  let lnumtmp = search(rekw, 'W')
  " go to end of the file if found nothing
  if lnumtmp == 0
    normal! G
  endif
  let lnume = search(redl, 'bW')

  "-----------------------------------------------------------------------------
  if keyword =~? "*NODE.*$"

    " set column start and column move
    if cnum <= 8
      let cstart = 1
      let cmove = 7
    elseif cnum > 8 && cnum <= 24
      let cstart = 9
      let cmove = 15
    elseif cnum > 24 && cnum <= 40
      let cstart = 25
      let cmove = 15
    elseif cnum > 40 && cnum <= 56
      let cstart = 41
      let cmove = 15
    elseif cnum > 56 && cnum <= 64
      let cstart = 57
      let cmove = 7
    elseif cnum > 64
      let cstart = 65
      let cmove = 7
    endif

  "-----------------------------------------------------------------------------
  elseif keyword =~? "*ELEMENT.*$"

    " set column start and column move
    let cstart = (float2nr(cnum/8)*8)+1
    let cmove = 7

  endif

  " go to first line in selection and 1st position in column
  call cursor(lnums, cstart)
  " line move
  let lmove = lnume - lnums
  execute "normal! zo\<C-v>" . lmove . "j" . cmove . "lo'"

endfunction

"-------------------------------------EOF---------------------------------------
