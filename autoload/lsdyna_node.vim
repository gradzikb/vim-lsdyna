"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  6th of December 2015
" Version:      1.0.1
"
" History of change:
"
" v1.0.1
"   - origin of reflection can be defined by user
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_node#Shift(line1, line2, ...)

  "-----------------------------------------------------------------------------
  " Function to shift node coordinates.
  "
  " Arguments:
  " - a:line1  : first line of selection
  " - a:line2  : last line of selection
  " - ...      : x, y, z shift values
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " set user scaling factors
  if a:0 == 1
    let xSh = str2float(a:1)
    let ySh = 0.0
    let zSh = 0.0
  elseif a:0 == 2
    let xSh = str2float(a:1)
    let ySh = str2float(a:2)
    let zSh = 0.0
  elseif a:0 == 3
    let xSh = str2float(a:1)
    let ySh = str2float(a:2)
    let zSh = str2float(a:3)
  endif

  " lines loop
  for lnum in range(a:line1, a:line2)

    " take current line
    let line = getline(lnum)

    " skip comment/keyword lines
    if line =~? "^[$*]"
      continue
    endif

    " get and scale node coordinates
    let nid = line[0:7]
    let nx = xSh + str2float(line[8:23])
    let ny = ySh + str2float(line[24:39])
    let nz = zSh + str2float(line[40:55])

    " dump line with new coord.
    let newline = printf("%8s%16.8f%16.8f%16.8f", nid, nx, ny, nz)
    call setline(lnum, newline)

  endfor

  " restore cursor position
  call cursor(a:line1, 0)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#Scale(line1, line2, ...)

  "-----------------------------------------------------------------------------
  " Function to scale node coordinates.
  "
  " Arguments:
  " - a:line1  : first line of selection
  " - a:line2  : last line of selection
  " - ...      : x, y, z scale factors
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " set user scaling factors
  if a:0 == 1
    let xSf = str2float(a:1)
    let ySf = 1.0
    let zSf = 1.0
  elseif a:0 == 2
    let xSf = str2float(a:1)
    let ySf = str2float(a:2)
    let zSf = 1.0
  elseif a:0 == 3
    let xSf = str2float(a:1)
    let ySf = str2float(a:2)
    let zSf = str2float(a:3)
  endif

  " lines loop
  for lnum in range(a:line1, a:line2)

    " take current line
    let line = getline(lnum)

    " skip comment/keyword lines
    if line =~? "^[$*]"
      continue
    endif

    " get and scale node coordinates
    let nid = line[0:7]
    let nx = xSf * str2float(line[8:23])
    let ny = ySf * str2float(line[24:39])
    let nz = zSf * str2float(line[40:55])

    " dump line with new coord.
    let newline = printf("%8s%16.8f%16.8f%16.8f", nid, nx, ny, nz)
    call setline(lnum, newline)

  endfor

  " restore cursor position
  call cursor(a:line1, 0)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#Reflect(line1, line2, ...)

  "-----------------------------------------------------------------------------
  " Function to reflect node coordinates respect to origin of global coord.
  "
  " Arguments:
  " - a:line1  : first line of selection
  " - a:line2  : last line of selection
  " - ...      : palne definition / origin
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " get command arguments
  if a:0 == 1
    let dir = tolower(a:1)
    let origin = 0.0
  elseif a:0 == 2
    let dir = tolower(a:1)
    let origin = str2float(a:2)
  endif

  " lines loop
  for lnum in range(a:line1, a:line2)

    " take current line
    let line = getline(lnum)

    " skip comment/keyword lines
    if line =~? "^[$*]"
      continue
    endif

    " get node coordinates from line
    let nid = line[0:7]
    let nx = str2float(line[8:23])
    let ny = str2float(line[24:39])
    let nz = str2float(line[40:55])

    " reflect node coord.
    if dir == "x" || dir == "yz" || dir "zy"
      let nx = origin - (nx - origin)
    elseif dir == "y" || dir == "xz" || dir == "zx"
      let ny = origin - (ny - origin)
    elseif dir == "z" || dir == "xy" || dir == "yz"
      let nz = origin - (nz - origin)
    endif

    " dump line with new coord.
    let newline = printf("%8s%16.8f%16.8f%16.8f", nid, nx, ny, nz)
    call setline(lnum, newline)

  endfor

  " restore cursor position
  call cursor(a:line1, 0)

endfunction

"-------------------------------------EOF---------------------------------------
