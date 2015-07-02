"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  2nd of July 2015
" Version:      1.1.0
"
" History of change:
"
" v1.1.0
"   - user pid can be search now
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_sort#SortByPart(line1, line2, ...)

  "-----------------------------------------------------------------------------
  " Function sort Ls-Dyna elements in order of part id.
  " A header with part id is added as well.
  "
  " Arguments:
  " - a:line1 : first line of selection
  " - a:line2 : last line of selection
  " - a:1     : user part id
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " sort lines respect to part id
  execute a:line1 . ',' . a:line2 . 'sort /\%9c\(\s\|\d\)\{8}/ r'


    " search for all part ids
    if a:0 == 0

      " loop over element lines
      let lnum = a:line1
      let endline = a:line2
      while (lnum <= endline)

        " write header for 1st part in the list
        if (lnum == a:line1)
          let str = '$ Part: ' . getline(lnum)[8:15]
          call append(lnum-1, str)
          let lnum += 1
          continue
        endif

        " take current and next line
        let line1 = getline(lnum)
        let line2 = getline(lnum+1)

        " compare part ids and put header line if not the same
        if (line1[8:15] !~? line2[8:15])
          " add header with part id
          let str = '$ Part: ' . line2[8:15]
          call append(lnum, str)
          " one more line to complete whole loop
          let endline += 1
          " two extra line to skip header I just added
          let lnum += 2
          continue
        endif

        " move to next line (not used if I added header)
        let lnum += 1

      endwhile

    " search only for user part id
    else

      " user part id
      let userPid = str2nr(a:1)

      " loop over element lines
      let lnum = a:line1
      let endline = a:line2
      let pid = 0
      while (lnum <= endline)

        " take line
        let line1 = getline(lnum)

        " compare part ids and put header line
        if (pid ==0 && str2nr(line1[8:15]) == userPid)
          " add header with part id
          let str = '$ Part: ' . line1[8:15]
          call append(lnum-1, str)
          let pid = 1
          " one more line to complete whole loop
          let endline += 1
        endif

        " add end break
        if (pid == 1 && line1[8:15] !~? a:1)
          call append(lnum-1, '$')
          break
        endif

        " move to next line (not if I added header)
        let lnum += 1

      endwhile

    endif

endfunction

"-------------------------------------EOF---------------------------------------
