"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  18th of October 2015
" Version:      1.0.0
"
" History of change:
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_indent#Indent(dir)

  "-----------------------------------------------------------------------------
  " Function to move to left/right selected Ls-Dyna column.
  "
  " Arguments:
  " - dir: move direction
  "        "Right" : move to right side
  "        "Left"  : move to left side
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " flag used to guess is it first call in current line
  if !exists("b:oldlnum")
    let b:oldlnum = -1
  endif

  " find in which column am I?
  let cnum = ((col('.')-1)/10)*10

  " if move right and last column do nothing
  if a:dir == "Right" && cnum == 70
    return
  " if move left and first column do nothing
  elseif a:dir == "Left" && cnum == 0
    return
  endif

  " if 1st move leave empty field
  let lnum = line('.')
  if lnum != b:oldlnum
    let b:presubstr = printf("%10s", " ")
  endif

  " get current line
  let line = getline('.')

  " move to right
  if a:dir == "Right"

    " from beginning till current column
    let substr1 = strpart(line, 0, cnum)
    " current column
    let substr2 = strpart(line, cnum, 10)
    " column after current
    let substr3 = strpart(line, cnum+10, 10)
    " from column after current till eol
    let substr4 = strpart(line, cnum+20)

    "set a new line
    let newLine = substr1 . b:presubstr . substr2 . substr4
    " dump a new line
    call setline('.', newLine)
    " move cursor to next column
    call cursor('.', col('.')+10)

    " store in memory column you just overwrite
    if len(substr3) == 10
      let b:presubstr = substr3
    else
      let b:presubstr = printf("%10s", " ")
    endif

  " move to left
  elseif a:dir == "Left"

    " from beginning till column before current
    let substr1 = strpart(line, 0, cnum-10)
    " column before current
    let substr2 = strpart(line, cnum-10, 10)
    " current column
    let substr3 = strpart(line, cnum, 10)
    " from current column till eol
    let substr4 = strpart(line, cnum+10)

    " set a new line
    let newLine = substr1 . substr3 . b:presubstr . substr4
    " I save cursor position because substitute change it
    let col = col('.')
    " remove trailing spaces
    let newLine = substitute(newLine, "\\s*$", "", "")
    " dump a new line
    call setline('.', newLine)
    " move cursor to previous column
    call cursor('.', col-10)

    " store in memory column you just overwrite
    let b:presubstr = substr2

  endif

  " store current line number
  let b:oldlnum = lnum

endfunction

"-------------------------------------EOF---------------------------------------
