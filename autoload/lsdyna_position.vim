"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  10th of November 2016
" Version:      1.1.0
"
" History of change:
"
"-------------------------------------------------------------------------------

function! lsdyna_position#Transl(line1, line2, tx, ty, tz)

  let nodes = lsdyna_position#nodes()
  call nodes.read(a:line1, a:line2)
  call nodes.transl(a:tx, a:ty, a:tz)
  call nodes.write(a:line1)
  unlet nodes

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_position#Scale(line1, line2, sx, sy, sz)

  let nodes = lsdyna_position#nodes()
  call nodes.read(a:line1, a:line2)
  call nodes.scale(a:sx, a:sy, a:sz)
  call nodes.write(a:line1)
  unlet nodes

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_position#Rotate(line1, line2, vx, vy, vz, px, py, pz, angle)

  let nodes = lsdyna_position#nodes()
  call nodes.read(a:line1, a:line2)
  call nodes.transl(-str2float(a:px), -str2float(a:py), -str2float(a:pz))
  call nodes.rotate(str2float(a:vx), str2float(a:vy), str2float(a:vz), str2float(a:angle))
  call nodes.transl(str2float(a:px), str2float(a:py), str2float(a:pz))
  call nodes.write(a:line1)
  unlet nodes

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_position#Pos6P(line1, line2, p1x, p1y, p1z,
 \                                            p2x, p2y, p2z,
 \                                            p3x, p3y, p3z,
 \                                            p4x, p4y, p4z,
 \                                            p5x, p5y, p5z,
 \                                            p6x, p6y, p6z)

  " object class nodes
  let nodes = lsdyna_position#nodes()

  " read nodes from file
  call nodes.read(a:line1, a:line2)

  " P1, P2, P3 to nodes list, they need to transform as well
  call add(nodes.nodes, {'id':'P3x', 'x':a:p3x, 'y':a:p3y, 'z':a:p3z })
  call add(nodes.nodes, {'id':'P2x', 'x':a:p2x, 'y':a:p2y, 'z':a:p2z })
  call add(nodes.nodes, {'id':'P1x', 'x':a:p1x, 'y':a:p1y, 'z':a:p1z })

  "-----------------------------------------------------------------------------
  " 1st transformation

  " translate from P1 to P4
  call nodes.transl(a:p4x-a:p1x, a:p4y-a:p1y, a:p4z-a:p1z)

  "-----------------------------------------------------------------------------
  " 2nd transformation

  " set points coordinates
  let P2 = [nodes.nodes[-2].x, nodes.nodes[-2].y, nodes.nodes[-2].z]
  let P4 = [a:p4x, a:p4y, a:p4z]
  let P5 = [a:p5x, a:p5y, a:p5z]
  " build vectors
  let vecP4P2 = lsdyna_position#pnt2vec(P4, P2)
  let vecP4P5 = lsdyna_position#pnt2vec(P4, P5)
  " calc angle between vectors
  let a = lsdyna_position#vec2angle(vecP4P2, vecP4P5, 'd')
  " vector normal to plane P4-P2-P5
  let v = lsdyna_position#crossProduct(vecP4P2, vecP4P5)

  " roatation about angle respect to axis passing through point
  " angle : between vector P4-P2 to vector P4-P5
  " axis  : vector normal to plane P4-P2-P5
  " point : point P4
  call nodes.transl(-a:p4x, -a:p4y, -a:p4z)
  call nodes.rotate(v[0], v[1], v[2], a)
  call nodes.transl(a:p4x, a:p4y, a:p4z)

  "-----------------------------------------------------------------------------
  " 3rd transformation

  " set points coordinates
  let P3 = [nodes.nodes[-3].x, nodes.nodes[-3].y, nodes.nodes[-3].z]
  let P4 = [a:p4x, a:p4y, a:p4z]
  let P5 = [a:p5x, a:p5y, a:p5z]
  let P6 = [a:p6x, a:p6y, a:p6z]
  " build vectors
  let vecP4P3 = lsdyna_position#pnt2vec(P4, P3)
  let vecP4P6 = lsdyna_position#pnt2vec(P4, P6)
  " calc angle between vectors
  let a = lsdyna_position#vec2angle(vecP4P3, vecP4P6, 'd')
  " vector from point P4 to point P5
  let v = lsdyna_position#pnt2vec(P4, P5)
  " remove points from nodes befor write (three last items in the list)
  call remove(nodes.nodes, -3, -1)

  " roatation about angle respect to axis passing through point
  " angle : between vector P4-P3 to vector P4-P6
  " axis  : vector P4-P5
  " point : point P4
  call nodes.transl(-a:p4x, -a:p4y, -a:p4z)
  call nodes.rotate(v[0], v[1], v[2], a)
  call nodes.transl(a:p4x, a:p4y, a:p4z)

  "-----------------------------------------------------------------------------
  " write new coordinates to file
  call nodes.write(a:line1)

  unlet nodes

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_position#nodes()

  let class = {}
  let class.nodes = []

  let class.read   = function("lsdyna_position#read")
  let class.write  = function("lsdyna_position#write")
  let class.transl = function("lsdyna_position#transl")
  let class.scale  = function("lsdyna_position#scale")
  let class.rotate = function("lsdyna_position#rotate")

  return class

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_position#read(line1, line2) dict

  for line in getline(a:line1, a:line2)
    let id = str2nr(line[0:7])
    let x  = str2float(line[8:23])
    let y  = str2float(line[24:39])
    let z  = str2float(line[40:55])
    call add(self.nodes, {'id':id, 'x':x, 'y':y, 'z':z})
  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_position#write(lnum) dict

  let lines = []
  for node in self.nodes
    call add(lines, printf("%8s%16.8f%16.8f%16.8f", node.id, node.x, node.y, node.z))
  endfor

  call setline(a:lnum, lines)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_position#transl(tx, ty, tz) dict

  for node in self.nodes
    let node.x = node.x + a:tx
    let node.y = node.y + a:ty
    let node.z = node.z + a:tz
  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_position#scale(sx, sy, sz) dict

  for node in self.nodes
    let node.x = node.x * a:sx
    let node.y = node.y * a:sy
    let node.z = node.z * a:sz
  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_position#rotate(x, y, z, angle) dict

  " degree --> radians
  let a = a:angle * (3.1415926535/180.0)

  " convert to unit vector
  let vMag = sqrt(pow(a:x,2)+pow(a:y,2)+pow(a:z,2))
  let [x, y, z] = [a:x/vMag, a:y/vMag, a:z/vMag]

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

function! lsdyna_position#crossProduct(v1, v2)

  let vx = a:v1[1]*a:v2[2] - a:v1[2]*a:v2[1]
  let vy = a:v1[2]*a:v2[0] - a:v1[0]*a:v2[2]
  let vz = a:v1[0]*a:v2[1] - a:v1[1]*a:v2[0]

  return [vx, vy, vz]

endfunction!

"-------------------------------------------------------------------------------

function! lsdyna_position#pnt2vec(p1, p2)

  return [a:p2[0]-a:p1[0], a:p2[1]-a:p1[1], a:p2[2]-a:p1[2]]

endfunction!

"-------------------------------------------------------------------------------

function! lsdyna_position#vecMag(v)

  return sqrt(pow(a:v[0],2)+pow(a:v[1],2)+pow(a:v[2],2))

endfunction!

"-------------------------------------------------------------------------------

function! lsdyna_position#vec2angle(v1, v2, unit)

  let ab = a:v1[0]*a:v2[0] + a:v1[1]*a:v2[1] + a:v1[2]*a:v2[2]
  let a = lsdyna_position#vecMag(a:v1)
  let b = lsdyna_position#vecMag(a:v2)
  let angle = acos(ab/(a*b))

  if a:unit ==# 'd'
    let angle = angle * (180.0/3.1415926535)
  endif

  return angle

endfunction!

"-------------------------------------EOF---------------------------------------
