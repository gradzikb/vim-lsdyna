"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  6th of May 2017
"
" History of change:
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

" function to trim empty signs on string
function! s:Trim(string)
  let string = substitute(a:string,'^\s\+','','')
  let string = substitute(string,'\s\+$','','')
  return string
endfunction

function! lsdyna_keyword#Keyword(lnum, ...)

  "-----------------------------------------------------------------------------
  " Keyword class.
  "
  " Create keyword class of any Ls-Dyna keyword in line {lnum} in buffer {bufnr}.
  " Used as abstract class for more specialized classes as part, section.
  "
  " Constructor:
  "   let kword = lsdyna_keyword#Keyword(lnum[, bufnr])
  " Arguments:
  "   - lnum  : keyword line number
  "   - bufnr : buffer number, optional, by default active buffer
  " Return:
  "   - dict : keyword class object
  " Members:
  "   - *.first : kword 1st line number in file
  "   - *.last  : kword last line number
  "   - *.bufnr : buffer number with kword
  "   - *.file  : file name with kword
  "   - *.name  : full kword name (*PART, *SECTION, ...)
  "   - *.type  : kword type, substring of kword name after 1st '_' (INERTIA)
  "   - *.lines : list with all kword lines, includes comments lines
  " Methods:
  "   - *.datalines()   : return all kword data lines
  "   - *.part()        : return child class for *PART
  "   - *.section()     : return child class for *SECTION
  "   - *.material()    : return child class for *MATERIAL
  "   - *.defineCurve() : return child class for *DEFINE_CURVE
  "   - *.set()         : return child class for *SET
  "   - *.contact()     : return child class for *CONTACT
  "   - *.parameter()   : return child class for *PARAMETER
  "   - *.include()     : return child class for *INCLUDE
  "
  "-----------------------------------------------------------------------------

  " set buffer number
  let save_cursor = getpos(".")
  let save_cursor[0] = bufnr('%') " buffer number is always set to 0 in getpos() function

  let bufnr = a:0 == 1 ? a:1 : bufnr('%')

  let re_kword = '^*'         " regular expression to find keyword name
  let re_dline = '^[^$]\|^$'  " regular expression to find data line

  " load user buffer
  execute 'buffer ' bufnr

  " search first and last kword line
  " 1. look backward keyword name
  " 2. look forward next keyword name or end of the file
  " 3. look backward data line
  call cursor(a:lnum, 0)
  let lnum_start = search(re_kword,'bWc')
  let next_kw = search(re_kword, 'W')
  if next_kw == 0 | call cursor(line('$'), 0) | endif
  let lnum_end = next_kw == 0 ? search(re_dline,'bWc') : search(re_dline,'bW')

  " keyword class
  let kword = {}

  " class members
  let kword.first  = lnum_start
  let kword.last   = lnum_end
  let kword.bufnr  = bufnr
  let kword.file   = expand('%:p')
  let kword.name   = toupper(s:Trim(getline(lnum_start)))
  let kword.type   = stridx(kword.name, '_') >= 0 ? kword.name[stridx(kword.name, '_')+1:] : ''
  let kword._lines = getline(lnum_start, lnum_end)

  " class methods
  let kword.write        = function('lsdyna_keyword#write')
  let kword.delete       = function('lsdyna_keyword#delete')
  let kword._datalines   = function('lsdyna_keyword#_datalines')
  let kword._general     = function('lsdyna_keyword#_general')
  let kword._node        = function('lsdyna_keyword#_node')
  let kword._part        = function('lsdyna_keyword#_part')
  let kword._section     = function('lsdyna_keyword#_section')
  let kword._material    = function('lsdyna_keyword#_material')
  let kword._set         = function('lsdyna_keyword#_set')
  let kword._defineCurve = function('lsdyna_keyword#_defineCurve')
  let kword._contact     = function('lsdyna_keyword#_contact')
  let kword._parameter   = function('lsdyna_keyword#_parameter')
  let kword._include     = function('lsdyna_keyword#_include')

  " when you done restore previous position
  execute 'buffer ' . save_cursor[0]
  call setpos('.', save_cursor)

  return kword

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_keyword#write(lnum) dict
  call append(a:lnum-1, self._lines)
endfunction

function! lsdyna_keyword#delete() dict
  execute 'silent 'self.first.','.self.last.'delete'
endfunction

function! lsdyna_keyword#_datalines() dict
  return filter(self._lines, 'v:val[0] != "$"')
endfunction

"-------------------------------------------------------------------------------
"    GENERAL
"-------------------------------------------------------------------------------

function! lsdyna_keyword#_general() dict

  " new members
  let self.qf = function('lsdyna_keyword#general2qf')

  call filter(self, 'v:key[0] != "_"')
  return [self]

endfunction

function! lsdyna_keyword#general2qf() dict

    let qf = {}
    let qf.bufnr = self.bufnr
    let qf.lnum  = self.first
    let qf.text  = self.name

    return qf

endfunction

"-------------------------------------------------------------------------------
"    NODES
"-------------------------------------------------------------------------------

function! lsdyna_keyword#_node() dict

  let self.write   = function('lsdyna_keyword#node_write')
  let self.replace = function('lsdyna_keyword#node_replace')

  let self.nodes = {}
  for line in self._datalines()[1:]
    let id = str2nr(line[0:7])
    let x  = str2float(line[8:23])
    let y  = str2float(line[24:39])
    let z  = str2float(line[40:55])
    let self.nodes[id] = [x, y, z]
  endfor

  call filter(self, 'v:key[0] != "_"')
  return [self]

endfunction

"-------------------------------------------------------------------------------
"    PART
"-------------------------------------------------------------------------------

function! lsdyna_keyword#_part() dict

  " new members
  let parts = []

  " look for all paths
  " *PART         --> every 2 line is a new kword
  " *PART_INERTIA --> every 5 line is a new kword
  " *PART_CONTACT --> every 3 line is a new kword
  if self.type ==# 'INERTIA'
    let dlstep = 5
  elseif self.type ==# 'CONTACT'
    let dlstep = 3
  else
    let dlstep = 2
  endif

  let lines = self._lines[1:]
  call filter(self, 'v:key[0] != "_"')

  " main loop over all kword lines to find all parts
  let lcount  = 0 " line counter
  let dlcount = 0 " dataline counter
  for line in lines
    let lcount += 1
    " datalines: 0, dlstep, 2xdlstep, 3xdlstep
    if line[0] != '$' && dlcount % dlstep == 0
      let part = copy(self)
      let part.title = s:Trim(line)
      let part.qf    = function('lsdyna_keyword#part2qf')
    " datalines: 0+1, dlstep+1, 2xdlstep+1, 3xdlstep+1
    elseif line[0] != '$' && (dlcount-1) % dlstep == 0
      let part.id   = s:Trim(line[:9])
      let part.lnum = part.first + lcount
      call add(parts, part)
    endif
    let dlcount = line[0] != '$' ? dlcount+1 : dlcount
  endfor

  return parts

endfunction

function! lsdyna_keyword#part2qf() dict

    let qf = {}
    let qf.bufnr = self.bufnr
    let qf.lnum  = self.lnum
    let qf.text  = self.name.'|'.self.type.'|'.self.id.'|'.self.title

    return qf

endfunction

"-------------------------------------------------------------------------------
"    SECTION
"-------------------------------------------------------------------------------

function! lsdyna_keyword#_section() dict

  let lines = self._lines[1:]
  call filter(self, 'v:key[0] != "_"')

  " new members
  let sects = []

  " if I have TITLE I count data lines from 0 otherwise from 1
  let dlcount_min = self.type =~? 'TITLE' ? 0 : 1

  " type of keyword defines number of datalines in keyword w/o title line
  if self.type =~? 'SHELL'
    let dlcount_max = 2
  else
    let dlcount_max = 1
  endif

  let lcount  = 0           " line counter
  let dlcount = dlcount_min " dataline counter

  "-----------------------------------------------------------------------------
  if self.type =~? 'SHELL'

    let dlcount_max_default = dlcount_max
    for line in lines
      let lcount += 1      " count number of lines
      if line[0] != '$'

        " build new keyword object
        if dlcount == dlcount_min
          let dlcount_max = dlcount_max_default " it can be change later so for each new section I want to reset it
          let sect       = copy(self)
          let sect.title = ''
          let sect.qf    = function('lsdyna_keyword#section2qf')
        endif

        if dlcount == 0
          let sect.title = s:Trim(line)
        elseif dlcount == 1
          let sect.id   = str2nr(line[:9])
          let sect.lnum = sect.first + lcount
          let dlcount_max = str2nr(line[60:70]) == 1 ? dlcount_max+1 : dlcount_max " icomp=1 --> one extra line
        endif

        if dlcount == dlcount_max
          call add(sects, sect)
          let dlcount = dlcount_min
       else
         let dlcount += 1   " count number of data lines
       endif

      endif
    endfor

  "-----------------------------------------------------------------------------
  else

    for line in lines
      let lcount += 1      " count number of lines
      if line[0] != '$'

        " section object
        let sect       = copy(self)
        let sect.title = ''
        let sect.qf    = function('lsdyna_keyword#section2qf')

        if dlcount == 0
          let sect.title = s:Trim(line)
        elseif dlcount == 1
          let sect.id   = str2nr(line[:9])
          let sect.lnum = sect.first + lcount
        endif

        if dlcount == dlcount_max
          call add(sects, sect)
          let dlcount = dlcount_min
          continue
       endif
       let dlcount += 1   " count number of data lines

      endif
    endfor

  endif

  return sects

endfunction

function! lsdyna_keyword#section2qf() dict

    let qf = {}
    let qf.bufnr = self.bufnr
    let qf.lnum  = self.lnum
    let qf.text  = self.name.'|'.self.type.'|'.self.id.'|'.self.title

    return qf

endfunction

"-------------------------------------------------------------------------------
"    CONTACT
"-------------------------------------------------------------------------------

function! lsdyna_keyword#_contact() dict

  " new members
  let self.id    = self.name =~# '_ID\|_TITLE' ? s:Trim(self._datalines()[1][:9])  : ''
  let self.title = self.name =~# '_ID\|_TITLE' ? s:Trim(self._datalines()[1][10:]) : 'No title'
  let self.qf    = function('lsdyna_keyword#contact2qf')

  call filter(self, 'v:key[0] != "_"')
  return [self]

endfunction

function! lsdyna_keyword#contact2qf() dict

    let qf = {}
    let qf.bufnr = self.bufnr
    let qf.lnum  = self.first
    let qf.text  = self.name.'|'.self.type.'|'.self.id.'|'.self.title

    return qf

endfunction

"-------------------------------------------------------------------------------
"    DEFINE_CURVE
"-------------------------------------------------------------------------------

function! lsdyna_keyword#_defineCurve() dict

  "-----------------------------------------------------------------------------
  " Define curve class.
  "-----------------------------------------------------------------------------

  " new members
  let self.id    = self.name =~? '_TITLE' ? s:Trim(self._datalines()[2][:9]) : s:Trim(self._datalines()[1][:9])
  let self.title = self.name =~? '_TITLE' ? s:Trim(self._datalines()[1])     : 'No title'
  let self.type  = self.name[14:]
  let self.qf    = function('lsdyna_keyword#defineCurve2qf')

  call filter(self, 'v:key[0] != "_"')
  return [self]

endfunction

function! lsdyna_keyword#defineCurve2qf() dict

    let qf = {}
    let qf.bufnr = self.bufnr
    let qf.lnum  = self.first
    let qf.text  = self.name.'|'.self.type.'|'.self.id.'|'.self.title

    return qf

endfunction

"-------------------------------------------------------------------------------
"    MATERIAL
"-------------------------------------------------------------------------------

function! lsdyna_keyword#_material() dict

  " new members
  let self.id    = self.name =~# '_TITLE' ? s:Trim(self._datalines()[2][:9]) : s:Trim(self._datalines()[1][:9])
  let self.title = self.name =~# '_TITLE' ? s:Trim(self._datalines()[1])     : 'No title'
  let self.qf = function('lsdyna_keyword#material2qf')

  call filter(self, 'v:key[0] != "_"')
  return [self]

endfunction

function! lsdyna_keyword#material2qf() dict

    let qf = {}
    let qf.bufnr = self.bufnr
    let qf.lnum  = self.first
    let qf.text  = self.name.'|'.self.type.'|'.self.id.'|'.self.title

    return qf

endfunction

"-------------------------------------------------------------------------------
"    SET
"-------------------------------------------------------------------------------

function! lsdyna_keyword#_set() dict

  " new members
  let self.id    = self.name =~# '_TITLE' ? s:Trim(self._datalines()[2][:9]) : s:Trim(self._datalines()[1][:9])
  let self.title = self.name =~# '_TITLE' ? s:Trim(self._datalines()[1])     : 'No title'
  let self.qf    = function('lsdyna_keyword#set2qf')

  call filter(self, 'v:key[0] != "_"')
  return [self]

endfunction

function! lsdyna_keyword#set2qf() dict

    let qf = {}
    let qf.bufnr = self.bufnr
    let qf.lnum  = self.first
    let qf.text  = self.name.'|'.self.type.'|'.self.id.'|'.self.title

    return qf

endfunction

"-------------------------------------------------------------------------------
"    PARAMETER
"-------------------------------------------------------------------------------

function! lsdyna_keyword#_parameter() dict

  " new members
  let params = []

  let lines = self._lines[1:]
  call filter(self, 'v:key[0] != "_"')

  "-----------------------------------------------------------------------------
  " this part process *PARAMETER_EXPRESSION
  if self.name =~? 'EXPRESSION'

    let lcount = 0
    for line in lines
      let lcount += 1
      if line[0] =~? '[RIC]'
        let param = copy(self)
        let param.pname  = s:Trim(line[1:9])
        let param.ptype  = toupper(line[0])
        let param.val   = s:Trim(line[10:])
        let param.lnum  = param.first + lcount
        let param.qf    = function('lsdyna_keyword#parameter2qf')
        call add(params, param)
      endif
    endfor

  "-----------------------------------------------------------------------------
  " this part process *PARAMETER
  else

    let lcount = 0
    for line in lines
      let lcount += 1
      if line[0] =~? '[RIC]'
        " loop over 20 wide columns in each line to read more than one param
        for cnum in range(4)
          let cline = line[cnum*20 : cnum*20+19]
          if cline[0] =~? '[RIC]'
            let param = copy(self)
            let param.pname  = s:Trim(cline[1:9])
            let param.ptype  = toupper(cline[0])
            let param.val   = s:Trim(cline[10:19])
            let param.lnum  = param.first + lcount
            let param.qf    = function('lsdyna_keyword#parameter2qf')
            call add(params, param)
          endif
        endfor
      endif
    endfor

  endif

  return params

endfunction

function! lsdyna_keyword#parameter2qf() dict

    let qf = {}
    let qf.bufnr = self.bufnr
    let qf.lnum  = self.lnum
    let qf.text  = self.ptype.'|'.self.pname.'|'.self.val.'|'.self.type

    return qf

endfunction

"-------------------------------------------------------------------------------
"    INCLUDE
"-------------------------------------------------------------------------------

function! lsdyna_keyword#_include() dict

  " members
  let incls = []

  let lines = self._lines[1:]
  call filter(self, 'v:key[0] != "_"')

  " look for all paths
  " *INCLUDE --> every dataline is a path
  " *INCLUDE_TRANSFORM --> every 5th line is a path
  let dlstep = self.name =~? '_TRANSFORM' ? 5 : 1
  "
  " main loop over all kword lines to find all paths
  let lcount  = 0 " line counter
  let dlcount = 0 " dataline counter
  for line in lines
    let lcount += 1
    if line[0] != '$' && dlcount % dlstep == 0
      let incl = copy(self)
      let incl.path  = s:Trim(line)
      let incl.lnum  = incl.first + lcount
      let incl.read  = lsdyna_include#isFile(incl.path, []).read
      let incl.lvl   = 0
      let incl.qf = function('lsdyna_keyword#include2qf')
      call add(incls, incl)
    endif
    let dlcount = line[0] != '$' ? dlcount+1 : dlcount
  endfor

  return incls

endfunction

function! lsdyna_keyword#include2qf() dict

    let qf = {}
    let qf.bufnr = self.bufnr
    let qf.lnum  = self.lnum
    let qf.col   = 1
    let qf.text  = self.name.'|'.fnamemodify(self.path,':t').'|'.self.read.'|'.self.file.'|'.self.lvl

    return qf

endfunction

"-------------------------------------EOF---------------------------------------
