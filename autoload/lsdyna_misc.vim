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

function! lsdyna_misc#KwordDelete(bang, ...)

  " ----------------------------------------------------------------------------
  " Function to delete all specific keywords.
  " ----------------------------------------------------------------------------

  let vg = a:bang ? 'r' : ''

  let kw_lnum = 0
  let kwords = lsdyna_vimgrep#Vimgrep(join(a:000), '%', vg)
  for item in getqflist()
    " after I delete kword number of lines will change, it means kw position will
    " change. I must substract number of lines I deleted from kw position.
    let kword = lsdyna_parser#Keyword(item.lnum - kw_lnum, item.bufnr, 'fc')
    call kword.Delete()
    let kw_lnum = kw_lnum + (kword.last - kword.first) + 1
  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_misc#KwordComment(bang, ...)

  " ----------------------------------------------------------------------------
  " Function to comment all specific keywords.
  " ----------------------------------------------------------------------------

  let vg = a:bang ? 'r' : ''

  let kwords = lsdyna_vimgrep#Vimgrep(join(a:000), '%', vg)
  for item in getqflist()
    let kword = lsdyna_parser#Keyword(item.lnum, item.bufnr, 'fc')
    call kword.Delete()
    call kword.Comment()
    call kword.Write()
  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_misc#KwordAddComment() abort

  " ----------------------------------------------------------------------------
  " Function to comment all specific keywords.
  " ----------------------------------------------------------------------------

  let kword = lsdyna_parser#Keyword(line('.'), bufnr('%'), '')._Autodetect()[0]
  call kword.AddComments()
  call kword.Delete()
  call kword.Write()

endfunction

"-------------------------------------------------------------------------------

"function lsdyna_misc#ZipList(list1, list2) abort
"  let list = []
"  for i in range(0, max([len(a:list1), len(a:list2)])-1)
"    call add(list, get(a:list1, i, ''))
"    call add(list, get(a:list2, i, ''))
"  endfor
"  return list
"endfunction

"-------------------------------------------------------------------------------

"function lsdyna_misc#Format()
"  let kword = lsdyna_parser#Keyword(v:lnum, bufnr('%'), '')
"  let kword.Addheader()
"  let kword.Delete()
"  let kword.Write()
"endfunction

"-------------------------------------------------------------------------------

function lsdyna_misc#MakeMarkers(line1, line2, ...)

  " ----------------------------------------------------------------------------
  " Function to create markers for defined list of coordinates.
  " ----------------------------------------------------------------------------

  "let fname = a:0 == 0 ? expand('%:p:r') .. '_markers.key' : a:1
  let fname = expand('%:p:r') .. '_markers.key'
  let delimeter = a:0 == 0 ? '\s\+' : a:1

  let id_offset = 0
  let dump = ['*KEYWORD', '$']
  for line in getline(a:line1, a:line2)
    if line[0] !~ '[*$]' " skip keyword and comment line
      let s_line = split(line, delimeter)
      if len(s_line) < 3
        echo 'Line "' .. line .. '" skiped.'
        continue
      elseif len(s_line) == 3
        let s_line = [id_offset] + s_line
      endif
      let m_id = trim(s_line[0])
      let m_x = eval(s_line[1])
      let m_y = eval(s_line[2])
      let m_z = eval(s_line[3])
      let dump += ['$-------------------------------------------------------------------------------']
      let dump += ['$  Marker : ' .. m_id]
      let dump += ['$  x,y,z  : ' .. printf('%8.1f,%8.1f,%8.1f', m_x, m_y, m_z)]
      let dump += ['$-------------------------------------------------------------------------------']
      let dump += ['$']
      let dump += <SID>Marker(m_id, m_x, m_y, m_z, id_offset)
      let dump += ['$']
    let id_offset += 100
    endif
  endfor
  let dump += ['*END']
  call writefile(dump, fname)

endfunction

"-------------------------------------------------------------------------------

function s:Marker(name, x, y, z, id)

  " ----------------------------------------------------------------------------
  " Function to create one marker at x,y,z coordinate with id starting at id.
  "
  " Argument:
  "    x : x-coordinate for marker
  "    y : y-coordinate for marker
  "    z : z-coordinate for marker
  "   id : 1st id for marker node/elements numbers
  " Return:
  "   dyna_lines : list of strings with marker mesh in ls-dyna format
  "
  " ----------------------------------------------------------------------------

  " marker mesh
  let nodes = [
  \            [  1,  0.00,   0.00,   0.00 ],
  \            [  3,  0.00, -10.00,   0.00 ],
  \            [  4,  7.07,  -7.07,   0.00 ],
  \            [  5, 10.00,   0.00,   0.00 ],
  \            [  6,  7.07,   7.07,   0.00 ],
  \            [  7,  0.00,  10.00,   0.00 ],
  \            [  8, -7.07,   7.07,   0.00 ],
  \            [  9, -10.0,   0.00,   0.00 ],
  \            [ 10, -7.07,  -7.07,   0.00 ],
  \            [ 11,  0.00,  -7.07,  -7.07 ],
  \            [ 12,  0.00,   0.00, -10.00 ],
  \            [ 13,  0.00,   7.07,  -7.07 ],
  \            [ 14,  0.00,   7.07,   7.07 ],
  \            [ 15,  0.00,   0.00,  10.00 ],
  \            [ 16,  0.00,  -7.07,   7.07 ],
  \            [ 17,  7.07,   0.00,  -7.07 ],
  \            [ 18,  7.07,   0.00,   7.07 ],
  \            [ 19, -7.07,   0.00,   7.07 ],
  \            [ 20, -7.07,   0.00,  -7.07 ]
  \           ]
  let elements = [
  \               [  1,  1,  3,  1,  5,  4 ],
  \               [  2,  1,  1,  9,  8,  7 ],
  \               [  3,  1,  3,  1, 15, 16 ],
  \               [  4,  1,  1,  7, 13, 12 ],
  \               [  5,  1, 12,  1,  5, 17 ],
  \               [  6,  1,  1,  9, 19, 15 ],
  \               [  7,  2,  3,  1,  9, 10 ],
  \               [  8,  2,  1,  7,  6,  5 ],
  \               [  9,  2,  3,  1, 12, 11 ],
  \               [ 10,  2,  1, 15, 14,  7 ],
  \               [ 11,  2, 12,  1,  9, 20 ],
  \               [ 12,  2,  1, 15, 18,  5 ]
  \              ]

  " offset marker cooridnates and offset mesh ids
  call map(nodes, { _, val -> [val[0]+a:id, val[1]+a:x, val[2]+a:y, val[3]+a:z] })
  call map(elements, { _, val -> [val[0]+a:id, val[1], val[2]+a:id, val[3]+a:id, val[4]+a:id, val[5]+a:id] })
  "let first_id = nodes[0]
  "let last_id = nodes[-1]

  " save in ls-dyna format
  let dyna_lines  = ['*NODE']
  let dyna_lines += map(nodes, { _, val -> printf('%8d%16.4f%16.4f%16.4f', val[0], val[1], val[2], val[3]) })
  let dyna_lines += ['*ELEMENT_SHELL']
  let dyna_lines += map(elements, { _, val -> printf('%8d%8d%8d%8d%8d%8d', val[0], val[1], val[2], val[3], val[4], val[5]) })

  let dyna_lines += ['$']
  let dyna_lines += ['*SET_NODE_LIST_GENERATE_TITLE']
  let dyna_lines += ['Marker - ' .. a:name]
  let dyna_lines += [nodes[0][0:7]]
  let dyna_lines += [nodes[0][0:7] .. nodes[-1][0:7]]

  return dyna_lines

endfunction

"-------------------------------------EOF---------------------------------------
