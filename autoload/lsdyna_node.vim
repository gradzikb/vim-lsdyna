"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  12th January 2018
" Version:      2.0.0
"
" History of change:
" v2.0.0
"   - all functions wrote from scratch
" v1.1.0
"   - lsdyna_node#OffsetId function added
" v1.0.1
"   - origin of reflection can be defined by user
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

" Pi number
"let s:Pi = 3.1415926535
let s:Pi = 4.0*atan(1.0)

"-------------------------------------------------------------------------------

function! lsdyna_node#Transl(line1, line2, tx, ty, tz)

  "-----------------------------------------------------------------------------
  " Function to translate nodes coordinates by {tx, ty, tz} vector.
  "
  " Arguments:
  " - line1 (number) : first line to read nodes table
  " - line2 (number) : last line to read nodes table
  " - tx (float)     : x translation value
  " - ty (float)     : y translation value
  " - tz (float)     : z translation value
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " get translation values
  let t = [str2float(a:tx), str2float(a:ty), str2float(a:tz)]

  " object nodes class
  let nodes = lsdyna_node#nodes()

  let format = nodes.read(a:line1, a:line2)    " read nodes coordinates from file
  call nodes.transl(t[0], t[1], t[2])          " translate coordinates
  call nodes.write(a:line1, format)            " write new coordinates

  " delete nodes object
  unlet nodes

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#Scale(line1, line2, sx, sy, sz)

  "-----------------------------------------------------------------------------
  " Function to translate nodes coordinates by {sx}, {sy}, {sz} scale factors.
  "
  " Arguments:
  " - line1 (number) : first line to read nodes table
  " - line2 (number) : last line to read nodes table
  " - sx (float)     : x scale factor
  " - sy (float)     : y scale factor
  " - sz (float)     : z scale factor
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " scaling values
  let s = [str2float(a:sx), str2float(a:sy), str2float(a:sz)]

  " object nodes class
  let nodes = lsdyna_node#nodes()

  let format = nodes.read(a:line1, a:line2)   " read nodes coordinates from file
  call nodes.scale(s[0], s[1], s[2])          " scale coordinates
  call nodes.write(a:line1, format)           " write new coordinates

  " delete nodes object
  unlet nodes

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#Rotate(line1, line2, vx, vy, vz, px, py, pz, angle)

  "-----------------------------------------------------------------------------
  " Function to rotate angles by {angle} around {vx, vy, vz} vector.
  "
  " Arguments:
  " - line1 (number) : first line to read nodes table
  " - line2 (number) : last line to read nodes table
  " - angle (float)  : rotation angle in degrees
  " - v (vx, vy, vz) : rotation vector
  " - p (px, py, pz) : rotation point
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " pack function arguments
  let angle = str2float(a:angle)                              " rotation angle
  let v = [str2float(a:vx), str2float(a:vy), str2float(a:vz)] " rotation vector
  let p = [str2float(a:px), str2float(a:py), str2float(a:pz)] " rotation point

  " object nodes class
  let nodes = lsdyna_node#nodes()

  let format = nodes.read(a:line1, a:line2)    " read nodes coordinates from file
  call nodes.transl(-p[0], -p[1], -p[2])       " translate to point (0, 0, 0)
  call nodes.rotate(angle, v)                  " rotate angle around vector v
  call nodes.transl(p[0], p[1], p[2])          " translate back to point p
  call nodes.write(a:line1, format)            " write new coordinates

  " delete nodes object
  unlet nodes

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#Pos6p(line1, line2, p1x, p1y, p1z,
 \                                        p2x, p2y, p2z,
 \                                        p3x, p3y, p3z,
 \                                        p4x, p4y, p4z,
 \                                        p5x, p5y, p5z,
 \                                        p6x, p6y, p6z)

  "-----------------------------------------------------------------------------
  " Function to position base on 6 points. Position is set from points
  " P1-P2-P3 to points P4-P5-P6.
  "
  " Arguments:
  " - line1 (number)     : first line to read nodes table
  " - line2 (number)     : last line to read nodes table
  " - p1 (p1x, p1y, p1z) : point P1
  " - p2 (p2x, p2y, p2z) : point P2
  " - p3 (p3x, p3y, p3z) : point P3
  " - p4 (p4x, p4y, p4z) : point P4
  " - p5 (p5x, p5y, p5z) : point P5
  " - p6 (p6x, p6y, p6z) : point P6
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " pack points coordinates
  let P1 = [str2float(a:p1x), str2float(a:p1y), str2float(a:p1z)]
  let P2 = [str2float(a:p2x), str2float(a:p2y), str2float(a:p2z)]
  let P3 = [str2float(a:p3x), str2float(a:p3y), str2float(a:p3z)]
  let P4 = [str2float(a:p4x), str2float(a:p4y), str2float(a:p4z)]
  let P5 = [str2float(a:p5x), str2float(a:p5y), str2float(a:p5z)]
  let P6 = [str2float(a:p6x), str2float(a:p6y), str2float(a:p6z)]

  " mid point between P4 & P5, used in 3rd transformation
  let P45 = [(P4[0]+P5[0])/2.0, (P4[1]+P5[1])/2.0, (P4[2]+P5[2])/2.0]

  " object class nodes
  let nodes = lsdyna_node#nodes()

  " read nodes from file
  let format = nodes.read(a:line1, a:line2)

  " add points  P1, P2, P3 to nodes list, they need to be transform as well
  call add(nodes.nodes, {'id':'P3', 'x':P3[0], 'y':P3[1], 'z':P3[2]})
  call add(nodes.nodes, {'id':'P2', 'x':P2[0], 'y':P2[1], 'z':P2[2]})
  call add(nodes.nodes, {'id':'P1', 'x':P1[0], 'y':P1[1], 'z':P1[2]})

  "-----------------------------------------------------------------------------
  " 1st transformation

  " translate from P1 to P4
  call nodes.transl(P4[0]-P1[0], P4[1]-P1[1], P4[2]-P1[2])

  "-----------------------------------------------------------------------------
  " 2nd transformation

  " update starting points to new position
  let P1 = [nodes.nodes[-1].x, nodes.nodes[-1].y, nodes.nodes[-1].z]
  let P2 = [nodes.nodes[-2].x, nodes.nodes[-2].y, nodes.nodes[-2].z]
  let P3 = [nodes.nodes[-3].x, nodes.nodes[-3].y, nodes.nodes[-3].z]

  " set rotation angle (angle between vectors P4-P2 and P4-P5)
  let a = lsdyna_node#vec2angle(lsdyna_node#vector(P4, P2), lsdyna_node#vector(P4, P5), 'd')

  " don't do rotation for 0.0 angle
  if a != 0.0
    " rotation about angle respect to axis passing through point
    " angle : between vector P4-P2 and vector P4-P5
    " axis  : vector normal to plane P4-P2-P5
    " point : point P4
    call nodes.transl(-P4[0], -P4[1], -P4[2])
    call nodes.rotate(a, lsdyna_node#vector(P4, P2, P5))
    call nodes.transl(P4[0], P4[1], P4[2])
  endif

  "-----------------------------------------------------------------------------
  " 3rd transformation

  " update starting points to new position
  let P1 = [nodes.nodes[-1].x, nodes.nodes[-1].y, nodes.nodes[-1].z]
  let P2 = [nodes.nodes[-2].x, nodes.nodes[-2].y, nodes.nodes[-2].z]
  let P3 = [nodes.nodes[-3].x, nodes.nodes[-3].y, nodes.nodes[-3].z]

  " set rotation angle (angle between P1-P2-P3 plane and P4-P5-P6 plane)
  let a = lsdyna_node#vec2angle(lsdyna_node#vector(P1, P2, P3), lsdyna_node#vector(P4, P5, P6), 'd')

  " don't do rotation for 0.0 angle
  if a != 0.0
   " rotation about angle respect to axis passing through point
   " angle : angle between P1-P2-P3 plane and P4-P5-P6 plane
   " axis  : vector P4-P5
   " point : point P4
   call nodes.transl(-P4[0], -P4[1], -P4[2])
   call nodes.rotate(a, lsdyna_node#vector(P4, P5))
   call nodes.transl(P4[0], P4[1], P4[2])
  endif

  "-----------------------------------------------------------------------------

  " remove positioning points from nodes list before write
  " three last items in the list
  call remove(nodes.nodes, -3, -1)
  " write new coordinates to file
  call nodes.write(a:line1, format)

  unlet nodes

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#Mirror(line1, line2, plane, base)

  "-----------------------------------------------------------------------------
  " Function to reflect nodes coordinates
  "
  " Arguments:
  " - line1 (number) : first line to read nodes table
  " - line2 (number) : last line to read nodes table
  " - plane (string) : reflection plane flag
  " - base (list)    : reflection point
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " object nodes class
  let nodes = lsdyna_node#nodes()

  let format = nodes.read(a:line1, a:line2)      " read nodes coordinates from file
  call nodes.mirror(a:plane, str2float(a:base))  " reflect coordinates
  call nodes.write(a:line1, format)              " write new coordinates

  " delete nodes object
  unlet nodes

endfunction
"-------------------------------------------------------------------------------

function! lsdyna_node#vecMag(v)

  "-----------------------------------------------------------------------------
  " Function to calc. vector magnitude.
  "
  " Arguments:
  " - v (list) : vector definition
  " Return:
  " - magnitude (float) : vector magnitude
  "-----------------------------------------------------------------------------

  return sqrt(pow(a:v[0],2)+pow(a:v[1],2)+pow(a:v[2],2))

endfunction!

"-------------------------------------------------------------------------------

function! lsdyna_node#vec2angle(v1, v2, unit)

  "-----------------------------------------------------------------------------
  " Function to calc. angle between two vectors.
  "
  " Arguments:
  " - v1 (list)     : 1st vector definition
  " - v2 (list)     : 2nd vector definition
  " - unit (string) : unit flag
  "                   ''  : radians
  "                   'd' : degrees
  " Return:
  " - angle (float) : angle value
  "-----------------------------------------------------------------------------

  let ab = a:v1[0]*a:v2[0] + a:v1[1]*a:v2[1] + a:v1[2]*a:v2[2]
  let a = lsdyna_node#vecMag(a:v1)
  let b = lsdyna_node#vecMag(a:v2)
  let angle = acos(ab/(a*b))

  " return in degrees if needed
  if a:unit ==# 'd'
    let angle = angle * (180.0/s:Pi)
  endif

  return angle

endfunction!

"-------------------------------------------------------------------------------

function! lsdyna_node#vector(...)

  "-----------------------------------------------------------------------------
  " Function to create vector definition.
  " Two arguments (points)   : vector between points is set
  " Three arguments (points) : vector normal to plane is set
  "
  " Arguments:
  " - p1 (list)     : 1st point definition
  " - p2 (list)     : 2nd point definition
  " - p3 (list)     : 3rd point definition (optional)
  " Return:
  " - vector (list) : vector definition
  "-----------------------------------------------------------------------------

  " two point case --> return P1-P2 vector
  if a:0 == 2

    let vector = [a:2[0]-a:1[0], a:2[1]-a:1[1], a:2[2]-a:1[2]]

  " three point case --> return vector normal to plane P1-P2-P3
  elseif a:0 == 3

    " set P1-P2 vector & P1-P3 vector
    let v1 = [a:2[0]-a:1[0], a:2[1]-a:1[1], a:2[2]-a:1[2]]
    let v2 = [a:3[0]-a:1[0], a:3[1]-a:1[1], a:3[2]-a:1[2]]

    " vector cross product
    let vx = v1[1]*v2[2] - v1[2]*v2[1]
    let vy = v1[2]*v2[0] - v1[0]*v2[2]
    let vz = v1[0]*v2[1] - v1[1]*v2[0]

    let vector = [vx, vy, vz]

  endif

  return vector

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#nodes()

  "-----------------------------------------------------------------------------
  " Class constructor for {nodes} object.
  "
  " Arguments:
  " - none
  " Return:
  " - nodes object
  "-----------------------------------------------------------------------------

  let class = {}

  " class data
  let class.nodes     = []
  let class.skiplines = []

  " class functions
  let class.read   = function("lsdyna_node#read")
  let class.write  = function("lsdyna_node#write")
  let class.transl = function("lsdyna_node#transl")
  let class.scale  = function("lsdyna_node#scale")
  let class.rotate = function("lsdyna_node#rotate")
  let class.mirror = function("lsdyna_node#mirror")

  return class

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#read(line1, line2) dict

  "-----------------------------------------------------------------------------
  " Class nodes function to read nodes coordinates from file.
  "
  " Arguments:
  " - line1 (number) : first line to read nodes table
  " - line2 (number) : last line to read nodes table
  " Return:
  " - format (string) : dataline format (i8, i10, i20)
  "-----------------------------------------------------------------------------

  " check keyword so I know what format dataline I am processing
  let kword = getline(search('^\*','bWc'))
  if kword =~? '%\s*$'
    let format = 'i10'
  elseif kword =~? '+\s*$'
    let format = 'i20'
  else
    let format = 'i8'
  endif

  " loop over all specific lines
  let lpos = 0
  "----------------------------------------------------------------------------
  if format == 'i8'
    for line in getline(a:line1, a:line2)
      if line[0] =~? "[*$]"
        call add(self.skiplines, {'lpos':lpos, 'value':line})
      else
        let id = str2nr(line[0:7])
        let x  = str2float(line[8:23])
        let y  = str2float(line[24:39])
        let z  = str2float(line[40:55])
        call add(self.nodes, {'id':id, 'x':x, 'y':y, 'z':z})
      endif
      let lpos += 1
    endfor
  "----------------------------------------------------------------------------
  elseif format == 'i10'
    for line in getline(a:line1, a:line2)
      if line[0] =~? "[*$]"
        call add(self.skiplines, {'lpos':lpos, 'value':line})
      else
        let id = str2nr(line[0:9])
        let x  = str2float(line[10:25])
        let y  = str2float(line[26:41])
        let z  = str2float(line[42:57])
        call add(self.nodes, {'id':id, 'x':x, 'y':y, 'z':z})
      endif
      let lpos += 1
    endfor
  "----------------------------------------------------------------------------
  elseif format == 'i20'
    for line in getline(a:line1, a:line2)
      if line[0] =~? "[*$]"
        call add(self.skiplines, {'lpos':lpos, 'value':line})
      else
        let id = str2nr(line[0:19])
        let x  = str2float(line[20:39])
        let y  = str2float(line[40:59])
        let z  = str2float(line[60:79])
        call add(self.nodes, {'id':id, 'x':x, 'y':y, 'z':z})
      endif
      let lpos += 1
    endfor
  endif

  return format

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#write(lnum, format) dict

  "-----------------------------------------------------------------------------
  " Class nodes function to write nodes coordinates into file.
  "
  " Arguments:
  " - lnum (number) : line number where to start write nodes table
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " set line format used to write nodes into a file
  if a:format == 'i8'
    let str_format = '%8s%16.8f%16.8f%16.8f'
  elseif a:format == 'i10'
    let str_format = '%10s%16.8f%16.8f%16.8f'
  elseif a:format == 'i20'
    let str_format = '%20s%20.8f%20.8f%20.8f'
  endif

  " loop over all nodes to set formatting
  let lines = []
  for node in self.nodes
    call add(lines, printf(str_format, node.id, node.x, node.y, node.z))
  endfor

  " add skiped lines
  for line in self.skiplines
    call insert(lines, line.value, line.lpos)
  endfor

  " write all lines into file
  call setline(a:lnum, lines)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#transl(tx, ty, tz) dict

  "-----------------------------------------------------------------------------
  " Class nodes function to translate nodes coordinates by {tx, ty, tz} vector.
  "
  " Arguments:
  " - tx (float) : x translation value
  " - ty (float) : y translation value
  " - tz (float) : z translation value
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " loop over all nodes
  for node in self.nodes
    let node.x = node.x + a:tx
    let node.y = node.y + a:ty
    let node.z = node.z + a:tz
  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#scale(sx, sy, sz) dict

  "-----------------------------------------------------------------------------
  " Class nodes function to scale nodes coordinates by {tx, ty, tz} vector.
  "
  " Arguments:
  " - sx (float) : x scaling factor
  " - sy (float) : y scaling factor
  " - sz (float) : z scaling factor
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " loop over all nodes
  for node in self.nodes
    let node.x = node.x * a:sx
    let node.y = node.y * a:sy
    let node.z = node.z * a:sz
  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#rotate(angle, vector) dict

  "-----------------------------------------------------------------------------
  " Class nodes function to rotate about {angle} around {vx, vy, vz} vector
  " passing through (0, 0, 0) point.
  "
  " Arguments:
  " - angle (float)  : rotation angle in degrees
  " - r (rx, ry, rz) : rotation vector
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " degree --> radians
  let a = a:angle * (s:Pi/180.0)

  " convert to unit vector
  let vMag = lsdyna_node#vecMag([a:vector[0], a:vector[1], a:vector[2]])
  let [x, y, z] = [a:vector[0]/vMag, a:vector[1]/vMag, a:vector[2]/vMag]

  " rotation matrix
  let [R11, R12, R13] = [ x*x*(1.0-cos(a))+  cos(a), y*x*(1.0-cos(a))-z*sin(a), z*x*(1.0-cos(a))+y*sin(a) ]
  let [R21, R22, R23] = [ x*y*(1.0-cos(a))+z*sin(a), y*y*(1.0-cos(a))+  cos(a), z*y*(1.0-cos(a))-x*sin(a) ]
  let [R31, R32, R33] = [ x*z*(1.0-cos(a))-y*sin(a), y*z*(1.0-cos(a))+x*sin(a), z*z*(1.0-cos(a))+  cos(a) ]

  " calc coordinates after rotation
  for node in self.nodes
    let [x, y, z] = [copy(node.x), copy(node.y), copy(node.z)]
    let node.x = R11*x + R12*y + R13*z
    let node.y = R21*x + R22*y + R23*z
    let node.z = R31*x + R32*y + R33*z
  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#mirror(plane, base) dict

  "-----------------------------------------------------------------------------
  " Class nodes function to reflect nodes respect specific plane.
  "
  " Arguments:
  " - plane (string) : plane for reflection
  " - base (list)    : base point for reflection
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " loop over nodes
  for node in self.nodes

    " reflect node coord.
    if a:plane ==? "x" || a:plane ==? "yz" || a:plane ==? "zy"
      let node.x = a:base - (node.x - a:base)
    elseif a:plane ==? "y" || a:plane ==? "xz" || a:plane ==? "zx"
      let node.y = a:base - (node.y - a:base)
    elseif a:plane ==? "z" || a:plane ==? "xy" || a:plane ==? "yz"
      let node.z = a:base - (node.z - a:base)
    endif

  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#ReplaceNodes(line1, line2, range, ...)

  if a:0 == 1
    let file = a:1
    let offset = 0
  elseif a:0 == 2
    let file = a:2
    let offset = a:1
  endif

  "-----------------------------------------------------------------------------
  " collect all nodes from source file

  let source_nodes = {}
  setlocal shortmess+=A
  execute 'noautocmd silent! vimgrep/\c^*NODE\s*+\?\s*$/j ' . file
  for item in getqflist()
    let kword = lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fnc')
    let node = kword._Node()[0]
    call extend(source_nodes, node.Nodes())
  endfor
  setlocal shortmess-=A

  echo 'Import '.len(source_nodes).' nodes from source file.'

  "-----------------------------------------------------------------------------
  " process *NODE in range lines or in whole target file

  echo 'Processing target nodes ...'

  let ncount = 0
  if a:range
    " process current *NODE table
    let kword = lsdyna_parser#Keyword(line('.'), '%', '')
    let node = kword._Node()[0]
    let ncount += node.Replace(source_nodes, offset)
    call node.Delete()
    call node.Write(kword.first)
  else
    " process whole file
    execute 'noautocmd silent! vimgrep/\c^*NODE\( [%+]\)\?\s*$/j %'
    for item in getqflist()
      let kword = lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fnc')
      let node = kword._Node()[0]
      let ncount += node.Replace(source_nodes, offset)
      call node.Delete()
      call node.Write(kword.first)
    endfor
    execute 'bdelete' bufnr('$')
  endif

  echo 'Replaced '.ncount.' nodes.'

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_node#ConvertI8I10(line1, line2, ...) abort

  "-----------------------------------------------------------------------------
  " Function to convert I8 definition to I10.
  "
  " Arguments:
  " - a:line1  : first line of selection
  " - a:line2  : last line of selection
  " - ...      : conversion type i8->i10 or i10->i8
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  if a:0 == 0
    echo 'Missing arguments.'
    return
  endif

  " set column length
  if a:1 == 'i10'
    let clen = 8
    let format = '%10s'
    let kword = '*NODE %'
  elseif a:1 == 'i8'
    let clen = 10
    let format = '%8s'
    let kword = '*NODE'
  endif

  " lines loop
  for lnum in range(a:line1, a:line2)
    let line = getline(lnum)
    if line =~? '^\*NODE'
      call setline(lnum, kword)
    endif
    if line =~? '^[$*]' | continue | endif
    call setline(lnum, printf(format, trim(line[0:clen-1]))..line[clen:])
  endfor

endfunction

"-------------------------------------EOF---------------------------------------
