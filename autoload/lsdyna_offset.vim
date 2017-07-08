"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  20th of November 2016
" Version:      1.0.1
"
" History of change:
"
" v1.0.0
"   - element_mass fix
" v1.0.1
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_offset#Offset(line1, line2, ...)

  "-----------------------------------------------------------------------------
  " find keyword
  call search('^\*\a','bcW')
  let keyword = getline('.')

  "-----------------------------------------------------------------------------
  if keyword =~? '^\*NODE' ||
  \  keyword =~? '^\*AIRBAG_REFERENCE_GEOMETRY'

    " it let use with and w/o flags
    if a:0 == 2
      let offset = a:2
    else
      let offset = a:1
    endif

    call lsdyna_offset#Node(a:line1, a:line2, offset)

  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*SET_'

    " it let use with and w/o flags
    if a:0 == 2
      let offset = a:2
    else
      let offset = a:1
    endif

    call lsdyna_offset#Set(a:line1, a:line2, offset)

  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*ELEMENT_MASS\s*$'

    if a:0 == 2 && a:1 =~? '^[nep]\{1,3}$'
      call lsdyna_offset#ElementMass(a:line1, a:line2, join(sort(split(a:1, '\zs')), ""), a:2)
    else
      echo "ERROR: Please check arguments!"
    endif

  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*ELEMENT_BEAM\s*$'

    if a:0 == 2 && a:1 =~? '^[nep]\{1,3}$'
      call lsdyna_offset#ElementBeam(a:line1, a:line2, join(sort(split(a:1, '\zs')), ""), a:2)
    else
      echo "ERROR: Please check arguments!"
    endif

  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*ELEMENT_DISCRETE\s*$'

    if a:0 == 2 && a:1 =~? '^[nep]\{1,3}$'
      call lsdyna_offset#ElementDiscrete(a:line1, a:line2, join(sort(split(a:1, '\zs')), ""), a:2)
    else
      echo "ERROR: Please check arguments!"
    endif

  "-----------------------------------------------------------------------------
  elseif keyword =~? '^\*ELEMENT_.*$' ||
  \      keyword =~? '^\*AIRBAG_SHELL_REFERENCE_GEOMETRY\s*$'

    if a:0 == 2 && a:1 =~? '^[nep]\{1,3}$'
      call lsdyna_offset#Element(a:line1, a:line2, join(sort(split(a:1, '\zs')), ""), a:2)
    else
      echo "ERROR: Please check arguments!"
    endif

  endif

  " restore cursor position
  call cursor(a:line1, 0)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_offset#Node(line1, line2, offset)

  for lnum in range(a:line1, a:line2)

    " take current line
    let line = getline(lnum)

    " skip comment/keyword lines
    if line =~? "^[$*]" | continue | endif

    " dump line with new id
    let newNid = str2nr(line[:7]) + a:offset
    call setline(lnum, printf("%8s", newNid) . line[8:])

  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_offset#Set(line1, line2, offset)

    for lnum in range(a:line1, a:line2)

      " take current line
      let line = getline(lnum)

      " skip comment/keyword lines and any line with alphabetic sign (title)
      if line =~? "^[$*]" || line =~? "\\a"
        continue
      endif

      " take current line & remove trailing signs
      let line = substitute(line, "\\s*$", "", "")

      " how many columns?
      let cnum = len(line) / 10

      " loop over columns
      let newline = ""
      for i in range(0, cnum-1, 1)

        " get id from current line
        let id = strpart(line,i*10,10)

        " calc new id but skip empty fields
        if id !~ '^\s\{10}'
          let id = str2nr(id) + a:offset
        endif

        " extend new line
        let newline = newline . printf("%10s", id)

      endfor

      " write new line to file
      call setline(lnum, newline)

    endfor


endfunction

"-------------------------------------------------------------------------------

function! lsdyna_offset#ElementMass(line1, line2, arg, offset)

  for lnum in range(a:line1, a:line2)

    " take current line
    let line = substitute(getline(lnum), "\\s*$", "", "")

    " skip comment/keyword lines
    if line =~? "^[$*]" | continue | endif

    " split line
    let eid  = str2nr(line[:7])
    let nid  = str2nr(line[8:15])
    let mass = line[16:31]
    let pid  = str2nr(line[32:39])

    " element offset
    if a:arg == "e"
      let eid  = eid + a:offset
    " node offset
    elseif a:arg == "n"
      let nid  = nid + a:offset
    " part offset
    elseif a:arg == "p"
      let pid = pid + a:offset
    " element and node offset
    elseif a:arg == "en"
      let eid  =  eid + a:offset
      let nid  =  nid + a:offset
    " element and part offset
    elseif a:arg == "ep"
      let eid  = eid + a:offset
      let pid  = pid + a:offset
    " part and node offset
    elseif a:arg == "np"
      let pid  =  pid + a:offset
      let nid  =  nid + a:offset
    " element, node and part offset
    elseif a:arg == "enp"
      let eid  =  eid + a:offset
      let pid  =  pid + a:offset
      let nid  =  nid + a:offset
    endif

    " dump line with new id
    if len(line) <= 32
      let newline = printf("%8s%8s%16s", eid, nid, mass)
    else
      if str2nr(line[32:39]) == 0 | let pid = line[32:39] | endif
      let newline = printf("%8s%8s%16s%8s", eid, nid, mass, pid)
    endif
    call setline(lnum, newline)

    endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_offset#ElementBeam(line1, line2, arg, offset)

  for lnum in range(a:line1, a:line2)

    " get current line and remove trailing white signs
    let line = substitute(getline(lnum), "\\s*$", "", "")

    " skip comment/keyword lines
    if line =~? "^[$*]" | continue | endif

    " split line
    let eid  = str2nr(line[:7])
    let pid  = str2nr(line[8:15])
    let n1id = str2nr(line[16:23])
    let n2id = str2nr(line[24:31])
    let n3id = str2nr(line[32:39])

    " element offset
    if a:arg == "e"
      let eid  = eid + a:offset
    " node offset
    elseif a:arg == "n"
      let n1id = n1id + a:offset
      let n2id = n2id + a:offset
      let n3id = n3id + a:offset
    " part offset
    elseif a:arg == "p"
      let pid = pid + a:offset
    " element and node offset
    elseif a:arg == "en"
      let eid  =  eid + a:offset
      let n1id = n1id + a:offset
      let n2id = n2id + a:offset
      let n3id = n3id + a:offset
    " element and part offset
    elseif a:arg == "ep"
      let eid  = eid + a:offset
      let pid  = pid + a:offset
    " part and node offset
    elseif a:arg == "np"
      let pid  =  pid + a:offset
      let n1id = n1id + a:offset
      let n2id = n2id + a:offset
      let n3id = n3id + a:offset
    " element, node and part offset
    elseif a:arg == "enp"
      let eid  =  eid + a:offset
      let pid  =  pid + a:offset
      let n1id = n1id + a:offset
      let n2id = n2id + a:offset
      let n3id = n3id + a:offset
    endif

    " dump only four columns
    if len(line) <= 32
      let newline = printf("%8s%8s%8s%8s", eid, pid, n1id, n2id)
    " dump whole line
    else
      " if 3rd node was zero or not defined keep it
      if str2nr(line[32:39]) == 0 | let n3id = line[32:39] | endif
      let newline = printf("%8s%8s%8s%8s%8s", eid, pid, n1id, n2id, n3id) . line[40:]
    endif
    call setline(lnum, newline)

  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_offset#ElementDiscrete(line1, line2, arg, offset)

  for lnum in range(a:line1, a:line2)

    " get current line and remove trailing white signs
    let line = substitute(getline(lnum), "\\s*$", "", "")

    " skip comment/keyword lines
    if line =~? "^[$*]" | continue | endif

    " split line
    let eid  = str2nr(line[:7])
    let pid  = str2nr(line[8:15])
    let n1id = str2nr(line[16:23])
    let n2id = str2nr(line[24:31])

    " element offset
    if a:arg == "e"
      let eid  = eid + a:offset
    " node offset
    elseif a:arg == "n"
      let n1id = n1id + a:offset
      let n2id = n2id + a:offset
    " part offset
    elseif a:arg == "p"
      let pid = pid + a:offset
    " element and node offset
    elseif a:arg == "en"
      let eid  =  eid + a:offset
      let n1id = n1id + a:offset
      let n2id = n2id + a:offset
    " element and part offset
    elseif a:arg == "ep"
      let eid  = eid + a:offset
      let pid  = pid + a:offset
    " part and node offset
    elseif a:arg == "np"
      let pid  =  pid + a:offset
      let n1id = n1id + a:offset
      let n2id = n2id + a:offset
    " element, node and part offset
    elseif a:arg == "enp"
      let eid  =  eid + a:offset
      let pid  =  pid + a:offset
      let n1id = n1id + a:offset
      let n2id = n2id + a:offset
    endif

    " dump new line
    call setline(lnum, printf("%8s%8s%8s%8s", eid, pid, n1id, n2id) . line[32:])

  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_offset#Element(line1, line2, arg, offset)

  for lnum in range(a:line1, a:line2)

    " get line
    let line = getline(lnum)

    " skip comment/keyword lines
    if line =~? "^[$*]" | continue | endif

    " take current line & remove trailing signs
    let line = substitute(line, "\\s[ 0]*$", "", "")
    " set line length
    let llen = len(line)

    " number of columns
    let cnum = llen / 8

    " loop over columns
    for i in range(0, cnum-1, 1)

      " slice index
      let s = i * 8
      " get line slice
      let slice = strpart(line,s,8)

      "-----------------------------------------------------------------------
      " offset only nodes
      if a:arg == "e"
        if i == 0
          let newId = str2nr(slice) + a:offset
        else
          let newId = slice
        endif
      " offset only elements
      elseif a:arg == "n"
        if i >= 2 && str2nr(slice) != 0
          let newId = str2nr(slice) + a:offset
        else
          let newId = slice
        endif
      " offset only parts
      elseif a:arg == "p"
        if i == 1
          let newId = str2nr(slice) + a:offset
        else
          let newId = slice
        endif
      " offset node/elements id
      elseif a:arg == "en"
        if i == 1 || str2nr(slice) == 0
          let newId = slice
        else
          let newId = str2nr(slice) + a:offset
        endif
      " offset elements/parts id
      elseif a:arg == "ep"
        if i <= 1
          let newId = str2nr(slice) + a:offset
        else
          let newId = slice
        endif
      " offset node/parts id
      elseif a:arg == "np"
        if i == 0 || str2nr(slice) == 0
          let newId = slice
        else
          let newId = str2nr(slice) + a:offset
        endif
      " offset nodes/parts/elements id
      elseif a:arg == "enp"
          if str2nr(slice) == 0
            let newId = slice
          else
            let newId = str2nr(slice) + a:offset
          endif
      endif

      "-----------------------------------------------------------------------
      " update line with new values
      let line = strpart(line,0,s) . printf("%8s", newId) . strpart(line,s+8)

    endfor

    " dump new line
    call setline(lnum, line)

  endfor

endfunction

"-------------------------------------EOF---------------------------------------
