"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  1st February 2018
" Version:      1.2.1
"
"-------------------------------------------------------------------------------
"
" v1.2.1
"   - lsdyna_curve#resample(step) function fixed
"     (could happend to skip last point)
" v1.2.0
"   - new internal representation of curve
" v1.1.0
"   - lsdyna_curves#Reverse function fixed
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_curve#Scale(line1, line2, sx, sy)

  "-----------------------------------------------------------------------------
  " Function to scale curve points by {sx}, {sy} scale factors.
  "
  " Arguments:
  " - line1 (number) : first line to read
  " - line2 (number) : last line to read
  " - sx (float)     : x scale factor
  " - sy (float)     : y scale factor
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " create curve class object
  let curve = lsdyna_curve#curve()

  call curve.read(a:line1, a:line2)                  " read curve
  call curve.scale(str2float(a:sx), str2float(a:sy)) " scale curve
  call curve.write(a:line1, a:line2)                 " write curve

  " delete curve object
  unlet curve

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#Offset(line1, line2, ox, oy)

  "-----------------------------------------------------------------------------
  " Function to offset curve points by {ox}, {oy} values.
  "
  " Arguments:
  " - line1 (number) : first line to read
  " - line2 (number) : last line to read
  " - ox (float)     : x offset
  " - oy (float)     : y offset
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " create curve class object
  let curve = lsdyna_curve#curve()

  call curve.read(a:line1, a:line2)                   " read curve
  call curve.offset(str2float(a:ox), str2float(a:oy)) " offset curve
  call curve.write(a:line1, a:line2)                  " write curve

  " delete curve object
  unlet curve

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#Mirror(line1, line2)

  "-----------------------------------------------------------------------------
  " Function to mirror curve respect to origin.
  "
  " Arguments:
  " - line1 (number) : first line to read
  " - line2 (number) : last line to read
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " create curve class object
  let curve = lsdyna_curve#curve()

  call curve.read(a:line1, a:line2)   " read curve
  call curve.mirror()                 " mirror curve
  call curve.write(a:line1, a:line2)  " write curve

  " delete curve object
  unlet curve

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#Cut(line1, line2, ...)

  "-----------------------------------------------------------------------------
  " Function to cut curve in x range.
  "
  " Arguments:
  " - line1 (number) : first line to read
  " - line2 (number) : last line to read
  " - ... (string)   : cut boundaries (1.0:5.0, :6.0, 2.0:)
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " create curve class object
  let curve = lsdyna_curve#curve()
  " read curve from file
  call curve.read(a:line1, a:line2)
  " set cut boundaries
  let argv = split(join(a:000),':',1)
  let first = empty(argv[0]) ? curve.curve[0].x  : str2float(argv[0])
  let last  = empty(argv[1]) ? curve.curve[-1].x : str2float(argv[1])
  " cut curve
  call curve.cut(first, last)
  " write curve
  call curve.write(a:line1, a:line2)
  " delete curve object
  unlet curve

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#Addpoint(line1, line2, x)

  "-----------------------------------------------------------------------------
  " Function to add new point for user {x} value.
  "
  " Arguments:
  " - line1 (number) : first line to read
  " - line2 (number) : last line to read
  " - x (float)      : user x value
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " create curve class object
  let curve = lsdyna_curve#curve()

  call curve.read(a:line1, a:line2)   " read curve
  call curve.addpoint(str2float(a:x)) " offset curve
  call curve.write(a:line1, a:line2)  " write curve

  " delete curve object
  unlet curve

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#Resample(line1, line2, argn, argv)

  "-----------------------------------------------------------------------------
  " Function to add new point for user {x} value.
  "
  " Arguments:
  " - line1 (number) : first line to read
  " - line2 (number) : last line to read
  " - argn (string)  : argument name
  " - argv (float)   : argument value
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " create curve class object
  let curve = lsdyna_curve#curve()
  " read curve
  call curve.read(a:line1, a:line2)

  " set step value for resampling
  " user step
  if a:argn ==? '-i'
    let step = str2float(a:argv)
  " number of points
  elseif a:argn ==? '-p'
    let step = (curve.curve[-1].x-curve.curve[0].x) / (str2nr(a:argv)-1)
  endif

  call curve.resample(step)          " resample curve
  call curve.write(a:line1, a:line2) " write curve

  " delete curve object
  unlet curve

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#curve()

  "-----------------------------------------------------------------------------
  " Class constructor for curve object.
  "
  " Arguments:
  " - none
  " Return:
  " - curve object
  "-----------------------------------------------------------------------------

  let class = {}

  " class data
  let class.curve  = []
  let class.format = ''

  " class functions
  let class.addpoint = function("lsdyna_curve#addpoint")
  let class.cut      = function("lsdyna_curve#cut")
  let class.mirror   = function("lsdyna_curve#mirror")
  let class.offset   = function("lsdyna_curve#offset")
  let class.read     = function("lsdyna_curve#read")
  let class.resample = function("lsdyna_curve#resample")
  let class.scale    = function("lsdyna_curve#scale")
  let class.write    = function("lsdyna_curve#write")

  return class

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#read(line1, line2) dict

  "-----------------------------------------------------------------------------
  " Class curve function to read curve lines from file.
  "
  " Arguments:
  " - line1 (number) : first line to read
  " - line2 (number) : last line to read
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " get number (abcissa value from 1st line)
  let number = getline(a:line1)[0:19]
  " set number type
  let type = number =~? "e" ? "e" : "f"
  " set number precision
  let precision = len(matchstr(number, "\\.\\zs\\d*"))
  " set number format
  let self.format = repeat('%20.'.precision.type, 2)

  "-----------------------------------------------------------------------------

  " loop over all selected lines
  for line in getline(a:line1, a:line2)

    " get data from line
    let x = str2float(line[0:19])
    let y = str2float(line[20:39])
    " add to curve list
    call add(self.curve, {'x':x, 'y':y})

  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#write(line1, line2) dict

  "-----------------------------------------------------------------------------
  " Class curve function to write curve into file.
  "
  " Arguments:
  " - line1 (number) : first line to read
  " - line2 (number) : last line to read
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " loop over all points in curve
  let lines = []
  for point in self.curve
    call add(lines, printf(self.format, point.x, point.y))
  endfor

  " remove old lines
  silent execute a:line1 . "," . a:line2 . "delete"

  " write curve
  call append(a:line1-1, lines)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#scale(sx, sy) dict

  "-----------------------------------------------------------------------------
  " Class curve function to scale curve.
  "
  " Arguments:
  " - sx : x scaling factor
  " - sy : y scaling factor
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " scale points
  for point in self.curve
    let point.x = point.x * a:sx
    let point.y = point.y * a:sy
  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#offset(ox, oy) dict

  "-----------------------------------------------------------------------------
  " Class curve function to offset curve.
  "
  " Arguments:
  " - ox : x offset factor
  " - oy : y offset factor
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " scale points
  for point in self.curve
    let point.x = point.x + a:ox
    let point.y = point.y + a:oy
  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#mirror() dict

  "-----------------------------------------------------------------------------
  " Class curve function to mirror curve.
  "
  " Arguments:
  " - none
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " reflect from positive to negative
  if self.curve[1].x > 0.0
    for point in self.curve[1:]
      call insert(self.curve, {'x': -1.0*point.x, 'y': -1.0*point.y})
    endfor
  " reflect from negative to positive
  else
    for point in reverse(copy(self.curve))[1:]
      call add(self.curve, {'x': -1.0*point.x, 'y': -1.0*point.y})
    endfor
  endif

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#cut(first, last) dict

  "-----------------------------------------------------------------------------
  " Class curve function to cut curve.
  "
  " Arguments:
  " - first : first cut value
  " - last  : last cut value
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " set default first and last index
  let first = 0
  let last = len(self.curve)

  " find first index
  for i in range(0, len(self.curve), 1)
    if self.curve[i].x >= a:first
      let first = i | break
    endif
  endfor

  " find last index
  for i in range(len(self.curve)-1, 0, -1)
    if self.curve[i].x <= a:last
      let last = i | break
    endif
  endfor

  " cut curve
  let self.curve = self.curve[first : last]

  " add interpolated first point
  if self.curve[0].x != a:first
    call insert(self.curve, lsdyna_curve#linint(a:first, self.curve[0], self.curve[1]))
  endif

  " add interpolated last point
  if self.curve[-1].x != a:last
    call add(self.curve, lsdyna_curve#linint(a:last, self.curve[-2], self.curve[-1]))
  endif

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#addpoint(x) dict

  "-----------------------------------------------------------------------------
  " Class curve function to add a new point for x value.
  "
  " Arguments:
  " - x : x value for added point
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " do nothing if point in curve
  for point in self.curve
    if point.x == a:x | return 0 | endif
  endfor

  " add point before 1st point
  if a:x < self.curve[0].x
    call insert(self.curve, lsdyna_curve#linint(a:x, self.curve[0], self.curve[1]))
  " add point after last point
  elseif a:x > self.curve[-1].x
    call add(self.curve, lsdyna_curve#linint(a:x, self.curve[-2], self.curve[-1]))
  " find place where to add new point
  else
    for i in range(len(self.curve))
      if self.curve[i].x >= a:x
        call insert(self.curve, lsdyna_curve#linint(a:x, self.curve[i-1], self.curve[i]), i)
        break
      endif
    endfor
  endif

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#resample(step) dict

  "-----------------------------------------------------------------------------
  " Class curve function to resample function.
  "
  " Arguments:
  " - step (float) : sampling step
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " add first point
  let curve = [self.curve[0]]

  " variables used in while loop
  let start = 1
  let len = len(self.curve)-1
  let x = self.curve[0].x + a:step
  let last = self.curve[-1].x

  " interpolation loop
  while x < last

    " find two neighbour points for x value
    for i in range(start, len)
      if (self.curve[i].x >= x)
        " interpolate new value
        let point = lsdyna_curve#linint(x, self.curve[i], self.curve[i-1])
        " remember position to start from here in next loop
        let start = i
        break
      endif
    endfor

    " add new point
    call add(curve, point)

    " increment x value by step
    let x += a:step

  endwhile

  " add last point
  call add(curve, self.curve[-1])

  " save new curve
  let self.curve = curve

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#linint(x, point1, point2)

  "-----------------------------------------------------------------------------
  " Linear interpolation for x between point1 & point2.
  "
  " Arguments:
  " - x      : interpolation value
  " - point1 : 1st point {'x':x1,'y':y1}
  " - point2 : 2nd point {'x':x2,'y':y2}
  " Return:
  " - point  : new point with interpolated value
  "-----------------------------------------------------------------------------

  let y = a:point1.y*((a:x-a:point2.x)/(a:point1.x-a:point2.x))
  \     + a:point2.y*((a:x-a:point1.x)/(a:point2.x-a:point1.x))

  return {'x':a:x, 'y':y}

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_curve#curve2xydata(...)

  "-----------------------------------------------------------------------------
  " Find and write all *DEFINE_CURVE in file.
  "
  " Arguments:
  " - a:1 : bang status (bang=0 : write only curve under the cursor)
  "                     (bang=1 : write all curves in file)
  " - a:2 : (optional) file where to save all curves
  "         by default file_name + 'xy' extension
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " if user set dump file use it ...
  if a:0 == 2
    let file = a:2
  " ... use current file, just add xy extension
  else
    let file = expand('%')
  endif

  " write all curves (with bang)
  if a:1
    execute 'noautocmd silent! vimgrep/\c^*DEFINE_CURVE\s*$\|^*DEFINE_CURVE_TITLE\s*$/j %'
    for item in getqflist()
      let kword = lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fnc')
      let curve = kword._Define_curve()[0]
      "call curve.Points()
      call curve.WriteXYData(file.'.crv')
    endfor
  " write only current keyword (w/o bang)
  else
    let kword = lsdyna_parser#Keyword(line('.'), bufnr('%'), 'nc')
    let curve = kword._Define_curve()[0]
    "call curve.Points()
    call curve.WriteXYData(file.'_ID'.curve.id.'.crv')
  endif

endfunction
"-------------------------------------EOF---------------------------------------
