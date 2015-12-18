"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  2nd of May 2015
" Version:      1.1.0
"
"-------------------------------------------------------------------------------
"
" v1.1.0
"   - lsdyna_curves#Reverse function fixed
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_curves#Read(firstLine, lastLine)

  "-----------------------------------------------------------------------------
  " Function to read selected lines and store data into the list.
  " Arguments:
  " - a:firstLine : 1st line in range
  " - a:lastLine  : last line in  range
  " Return:
  " - points : list [x1,y1,x2,y2, ... ,xn,yn]
  "-----------------------------------------------------------------------------

  " creat empty list to store data
  let points = []

  " read lines and store data into the list
  for i in range(a:firstLine, a:lastLine)
    let points = points + split(getline(i), '\s*,\s*\|\s\+')
  endfor

  " convert all data into float values
  call map(points, 'str2float(v:val)')

  return points

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curves#Write(startLine, points, strFormat)

  "-----------------------------------------------------------------------------
  " Function to write points into a file.
  " Arguments:
  " - a:startLine : line nmber where start write the data
  " - a:points    : list [x1,y1,x2,y2, ... ,xn,yn]
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " set cursor position
  let lnum = a:startLine - 1
  "execute "normal! " . lnum . "G"

  " save points into the file
  for i in range(0, len(a:points)-1, 2)

    " format line
    let newLine = printf(a:strFormat, a:points[i], a:points[i+1])

    " add new line
    call append(lnum, newLine)

    " remove empty line if added
    if (lnum == 0 && getline('.') =~ "^$")
      execute "normal! dd"
    endif

    " increment line number
    let lnum = lnum + 1

  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curves#WhatNumFormat(str, width)

  " what type?
  if a:str =~? "e"
    let numType = "e"
  else
    let numType = "f"
  endif

  " number of numbers after coma sign
  let numComa = len(matchstr(a:str, "\\.\\zs\\d*"))

  " formating patter for printf function
  let numFormat = "%" . a:width . "." . numComa . numType

  return numFormat

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curves#Shift(line1,line2,...)

  "-----------------------------------------------------------------------------
  " Function to offset curve.
  " Arguments:
  " - a:line1 : first selected line
  " - a:line2 : last selected line
  " - a:1     : x offset value (default 0.0)
  " - a:2     : y offset value (default 0.0)
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " set default options
  if a:0 == 0
    let xOff = 0.0 " set default x offset
    let yOff = 0.0 " set default y offset
  elseif a:0 == 1
    let xOff = str2float(a:1) " set user x offset
    let yOff = 0.0            " set default y offset
  elseif a:0 == 2
    let xOff = str2float(a:1) " set user x offset
    let yOff = str2float(a:2) " set user y offset
  endif

  " what number format?
  let line1 = split(getline(a:line1), '\s*,\s*\|\s\+')
  let strFormat = repeat(lsdyna_curves#WhatNumFormat(line1[0], 20), 2)

  " collect the data
  let points = lsdyna_curves#Read(a:line1,a:line2)

  " remove old lines
  execute a:line1 . "," . a:line2 . "delete"

  " scale data
  for i in range(0, len(points)-1, 2)
    let points[i]   = xOff + points[i]
    let points[i+1] = yOff + points[i+1]
  endfor

  " save data
  call lsdyna_curves#Write(a:line1, points, strFormat)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curves#Scale(line1,line2,...)

  "-----------------------------------------------------------------------------
  " Function to scale curve.
  " Arguments:
  " - a:line1 : first selected line
  " - a:line2 : last selected line
  " - a:1     : x scaling factor (1.0)
  " - a:2     : y scaling factor (1.0)
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " set default options
  if a:0 == 0
    let xScl = 1.0 " set default x scale factor
    let yScl = 1.0 " set default y scale factor
  elseif a:0 == 1
    let xScl = str2float(a:1) " set user x scale factor
    let yScl = 1.0            " set default y scale factor
  elseif a:0 == 2
    let xScl = str2float(a:1) " use user x scale factor
    let yScl = str2float(a:2) " use user y scale factor
  endif

  " what number format?
  let line1 = split(getline(a:line1), '\s*,\s*\|\s\+')
  let strFormat = repeat(lsdyna_curves#WhatNumFormat(line1[0], 20), 2)

  " collect the data
  let points = lsdyna_curves#Read(a:line1,a:line2)

  " remove old lines
  execute a:line1 . "," . a:line2 . "delete"

  " scale data
  for i in range(0, len(points)-1, 2)
    let points[i]   = xScl * points[i]
    let points[i+1] = yScl * points[i+1]
  endfor

  " save data
  call lsdyna_curves#Write(a:line1, points, strFormat)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curves#Resample(line1,line2,...)

  "-----------------------------------------------------------------------------
  " Function to interpolate curve with user increment or number of points.
  " Arguments:
  " - a:line1 : first selected line
  " - a:line2 : last selected line
  " - a:1     : setp definition type (-p/-i)
  " - a:2     : number of points / increment
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " set default options
  if a:0 == 0

    echom 'No function arguments!'
    echom 'To set number of points use :Interpolate -p 10'
    echom 'To set increment use :Interpolate -i 0.1'
    return 0

  else

    " what number format?
    let line1 = split(getline(a:line1), '\s*,\s*\|\s\+')
    let strFormat = repeat(lsdyna_curves#WhatNumFormat(line1[0], 20), 2)

    " collect the data
    let points = lsdyna_curves#Read(a:line1,a:line2)

    " define interpolation step
    if a:1 ==? '-p'
      let incr = (points[-2] - points[0]) / (str2float(a:2)-1)
    elseif a:1 ==? '-i'
      let incr = str2float(a:2)
    " unknow option
    else
      return 0
    endif

  endif

  " remove old lines
  execute a:line1 . "," . a:line2 . "delete"

  " set first step
  let x = points[0]
  " set loop end conditon (small value help not skip last point in while loop)
  let maxVal = points[-2] + (points[-2]*0.001)

  let tempPoints = [] " temp list used to store new points

  " interpolation loop
  while x <= maxVal

    " set first point
    if x <= points[0]
      let y = points[1]

    " set last point
    elseif x >= points[-2]
      let y = points[-1]

   " find points for interpolation
    else
      for i in range(2, len(points), 2)
        if points[i] > x
          let p1x = points[i-2]
          let p1y = points[i-1]
          let p2x = points[i]
          let p2y = points[i+1]
          let y = p1y*((x-p2x)/(p1x-p2x))
          \     + p2y*((x-p1x)/(p2x-p1x))
          break
        endif
      endfor

    endif

    call add(tempPoints, x) " save new x point
    call add(tempPoints, y) " save new y point

    " increment step
    let x = x + incr

  endwhile

  " save data
  call lsdyna_curves#Write(a:line1, tempPoints, strFormat)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curves#AddPoint(line1,line2,...)

  "-----------------------------------------------------------------------------
  " Function to add a new point for curve.
  " Arguments:
  " - a:line1 : first selected line
  " - a:line2 : last selected line
  " - a:1     : x value for new point
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " check input data
  if a:line1 == a:line2
    echom "You need to select at least 2 lines!"
    return 0
  endif

  " get a user point
  let x = str2float(a:1)

  " what number format?
  let line1 = split(getline(a:line1), '\s*,\s*\|\s\+')
  let strFormat = repeat(lsdyna_curves#WhatNumFormat(line1[0], 20), 2)

  " collect the data
  let points = lsdyna_curves#Read(a:line1,a:line2)

  for i in range(0, len(points)-1, 2)
    if (points[i] == x)
      echom "The point already exists!"
      return 0
    endif
  endfor

  if (x < points[0])

    " calc linear function coef.
    let a = (points[3]-points[1]) / (points[2]-points[0])
    let b = points[1] - a*points[0]
    let y = a*x+b

    " format line
    let newLine = printf(strFormat,x,y)
    " save new line
    call append(a:line1-1, newLine)

  elseif (x > points[-2])

    " calc linear function coef.
    let a = (points[-1]-points[-3]) / (points[-2]-points[-4])
    let b = points[-3] - a*points[-4]
    let y = a*x+b

    " format line
    let newLine = printf(strFormat,x,y)
    " save new line
    call append(a:line2, newLine)

  else

      for i in range(2, len(points), 2)

        if points[i] > x
          let p1x = points[i-2]
          let p1y = points[i-1]
          let p2x = points[i]
          let p2y = points[i+1]
          let y = p1y*((x-p2x)/(p1x-p2x))
          \     + p2y*((x-p1x)/(p2x-p1x))

          " format line
          let newLine = printf(strFormat,x,y)
          " calc line number
          let lnum = (a:line1 + i/2)-1
          " save new line
          call append(lnum, newLine)
          break
        endif

      endfor

  endif

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curves#SwapXY(line1,line2)

  "-----------------------------------------------------------------------------
  " Function to swap x and y vakues.
  " Arguments:
  " - a:line1 : first selected line
  " - a:line2 : last selected line
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " what number format?
  let line1 = split(getline(a:line1), '\s*,\s*\|\s\+')
  let strFormat = repeat(lsdyna_curves#WhatNumFormat(line1[0], 20), 2)

  " collect the data
  let points = lsdyna_curves#Read(a:line1,a:line2)

  " swap x & y
  for i in range(0, len(points)-1, 2)
    let tmpPoint = points[i]
    let points[i] = points[i+1]
    let points[i+1] = tmpPoint
  endfor

  " remove old lines
  execute a:line1 . "," . a:line2 . "delete"

  " save data
  call lsdyna_curves#Write(a:line1, points, strFormat)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curves#Reverse(line1,line2)

  "-----------------------------------------------------------------------------
  " Function to reverse curve.
  " Arguments:
  " - a:line1 : first selected line
  " - a:line2 : last selected line
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " what number format?
  let line1 = split(getline(a:line1), '\s*,\s*\|\s\+')
  let strFormat = repeat(lsdyna_curves#WhatNumFormat(line1[0], 20), 2)

  " collect the data
  let points = lsdyna_curves#Read(a:line1,a:line2)

  " split (x,y) list into x & y vectors
  let x = []
  let y = []
  for i in range(0,len(points)-1,2)
    call add(x, points[i])
    call add(y, points[i+1])
  endfor

  " revers x & y vectors
  call reverse(x)
  call reverse(y)

  " combine x & y vectors
  let revPoints = []
  for i in range(len(x))
    call add(revPoints, x[i])
    call add(revPoints, y[i])
  endfor

  " remove old lines
  execute a:line1 . "," . a:line2 . "delete"

  " save data
  call lsdyna_curves#Write(a:line1, revPoints, strFormat)

endfunction

"-------------------------------------EOF---------------------------------------
