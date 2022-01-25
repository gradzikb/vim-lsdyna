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

"function! lsdyna_parser#Keyword(lnum, bufnr, flags)
function! lsdyna_parser#Keyword(...)

  "-----------------------------------------------------------------------------
  " Keyword class.
  "
  " Create keyword object of any Ls-Dyna keyword in line {lnum} in buffer {bufnr}.
  " Used as abstract class for more specialized classes as part, section, ... .
  "
  " Constructor:
  "   let kword = lsdyna_keyword#Keyword(lnum[, bufnr])
  " Arguments:
  "   - lnum  : keyword line number
  "   - bufnr : buffer number
  "   - flags : not used anymore
  " Return:
  "   - dict : keyword class object
  " Members:
  "   - self.bufnr   : buffer number with kword
  "   - self.curcol  : column number, cursor position at parsing
  "   - self.curline : line number, cursor position at parsing
  "   - self.file    : file path name with kword
  "   - self.first   : kword 1st line number in file
  "   - self.hide    : status if the keyword is commented or not (0 - not commented, 1- commented)
  "   - self.id      : keyword id, set to 0, must be overwrite by child
  "   - self.last    : kword last line number in file
  "   - self.lines   : list with all kword lines, includes comments lines
  "   - self.lnum    : kword object poistion line for multi keywords case
  "   - self.name    : full kword name (*PART_INERTIA, *SECTION_SHELL_TITLE, ...)
  "   - self.title   : keyword title, set to empty string, must be overwrite by child
  "   - self.type    : kword type, substring of kword name after 1st '_' (INERTIA, SHELL_TITLE)
  " Methods:
  "   - self.Comment()                 : comment kword body
  "   - self.Uncomment()               : uncomment kword body
  "   - self.Datalines()               : Return all datalines (remove comment lines from kword body)
  "   - self.Delete()                  : delete kword body from file
  "   - self.Encrypt()                 : encrypt kword body
  "   - self.Write()                   : write kword body into file
  "
  "   - self._Autodetect()             : detect kword type and return child class
  "   - self._Kword()                  : return child class for any kword
  "   - self._Contact()                : return child class for *CONTACT
  "   - self._Database_cross_section() : return child class for *DATABASE_CROSS_SECTION
  "   - self._Database_history()       : return child class for *DATABASE_HISTORY
  "   - self._Define_coord()           : return child class for *DEFINE_COORDINATE
  "   - self._Define_cpm_vent()        : return child class for *DEFINE_CPM_VENT
  "   - self._Define_curve()           : return child class for *DEFINE_CURVE
  "   - self._Define_friction()        : return child class for *DEFINE_FRICTION
  "   - self._Define_trans()           : return child class for *DEFINE_TRANSFORMATION
  "   - self._Define_vector()          : return child class for *DEFINE_VECTOR
  "   - self._Include()                : return child class for *INCLUDE
  "   - self._Include_path()           : return child class for *INCLUDE_PATH
  "   - self._Material()               : return child class for *MATERIAL
  "   - self._Node()                   : return child class for *NODE
  "   - self._Parameter()              : return child class for *PARAMETER
  "   - self._Part()                   : return child class for *PART
  "   - self._Section()                : return child class for *SECTION
  "   - self._Sensor()                 : return child class for *SENSOR
  "   - self._Set()                    : return child class for *SET
  "
  "-----------------------------------------------------------------------------

  " collect function arguments
  let options = {}
  if type(a:1) == v:t_dict
    let options.lnum  = get(a:1,  'lnum',  line('.'))
    let options.bufnr = get(a:1, 'bufnr', bufnr('%'))
  else
    " backward compability
    let options.lnum  = a:1
    let options.bufnr = a:2
  endif

  " regular expression to find keyword name
  let re_kword = '^\(\'..g:lsdynaCommentString..'\)\?\*'
  " regular expression to find data line
  let re_dline = '^\(\'..g:lsdynaCommentString..'\)\?\([^$]\|$\)'

  " search() funciton used later change cursor position
  " save current cursor position so I can restore it later
  let save_cursor = getpos(".")
  let save_cursor[0] = bufnr('%')

  " set cursor on a:lnum in a:bufnr
  if options.bufnr != bufnr('%')
    execute 'noautocmd buffer' options.bufnr
  endif
  call cursor(options.lnum, 0)

  " class
  let kword = {}
  let kword.curline = options.lnum
  let kword.curcol  = virtcol('.')

  " find first and last kword line number in file
  " 1. look backward keyword name
  " 2. look forward next keyword name or end of the file
  " 3. look backward data line
  let lnum_start = search(re_kword,'bWc')
  let next_kw = search(re_kword.'\|BEGIN PGP MESSAGE', 'W')
  if next_kw == 0
    call cursor(line('$'), 0)
  else
    call cursor(line('.')-1, 0)
  endif
  let lnum_end = search(re_dline,'bWc')

  " class members
  let kword.id    = 0
  let kword.title = ''
  let kword.first = lnum_start
  let kword.last  = lnum_end
  let kword.lnum  = kword.first
  let kword.bufnr = options.bufnr
  let kword.file  = expand('%:p')
  let kword.hide  = getline(kword.first) =~? '^\'..g:lsdynaCommentString ? 1 : 0
  let kword.lines = getline(lnum_start, lnum_end)
  " remove comment prefix from all kword lines
  if kword.hide | call map(kword.lines, {idx, val -> val[len(g:lsdynaCommentString):] }) | endif
  let kword.name   = kword.lines[0]->trim()->toupper()
  let kword.type   = kword.name->split('_')[1:]->join('_')

  " class methods to operate on kword lines
  let kword.Comment                 = function('s:Comment')
  let kword.Datalines               = function('s:Datalines')
  let kword.Delete                  = function('s:Delete')
  let kword.Encrypt                 = function('s:Encrypt')
  let kword.Write                   = function('s:Write')
  let kword.GetText                 = function('s:GetText')

  " class methods to create specific kword objects
  let kword._Autodetect             = function('s:Autodetect')
  let kword._Kword                  = function('parser#kword#Kword')
  let kword._Node                   = function('parser#node#Node')
  let kword._Part                   = function('parser#part#Part')
  let kword._Section                = function('parser#section#Section')
  let kword._Mat                    = function('parser#mat#Mat')
  let kword._Set                    = function('parser#set#Set')
  let kword._Define_curve           = function('parser#define_curve#Define_curve')
  let kword._Define_coord           = function('parser#define_coord#Define_coord')
  let kword._Define_trans           = function('parser#define_trans#Define_trans')
  let kword._Define_vector          = function('parser#define_vector#Define_vector')
  let kword._Define_friction        = function('parser#define_friction#Define_friction')
  let kword._Define_cpm_vent        = function('parser#define_cpm_vent#Define_cpm_vent')
  let kword._Contact                = function('parser#contact#Contact')
  let kword._Parameter              = function('parser#parameter#Parameter')
  let kword._Include                = function('parser#include#Include')
  let kword._Include_path           = function('parser#include_path#Include_path')
  let kword._Database_cross_section = function('parser#database_cross_section#Database_cross_section')
  let kword._Database_history       = function('parser#database_history#Database_history')
  let kword._Sensor                 = function('parser#sensor#Sensor')

  " restore original cursor position
  execute 'noautocmd buffer ' . save_cursor[0]
  call setpos('.', save_cursor)

  return kword

endfunction

"-------------------------------------------------------------------------------

function! s:Autodetect() dict
  if self.name =~? '^*PART'
    return self._Part()
  elseif self.name =~? '^*SECTION'
    return self._Section()
  elseif self.name =~? '^*MAT'
    return self._Mat()
  elseif self.name =~? '^*SET'
    return self._Set()
  elseif self.name =~? '^*DEFINE_CURVE'
    return self._Define_curve()
  elseif self.name =~? '^*DEFINE_COORDINATE'
    return self._Define_coord()
  elseif self.name =~? '^*DEFINE_TRANSFORMATION'
    return self._Define_trans()
  elseif self.name =~? '^*DEFINE_VECTOR'
    return self._Define_vector()
  elseif self.name =~? '^*DEFINE_FRICTION'
    return self._Define_friction()
  elseif self.name =~? '^*DEFINE_CPM_VENT'
    return self._Define_cpm_vent()
  elseif self.name =~? '^*CONTACT'
    return self._Contact()
  elseif self.name =~? '^*PARAMETER'
    return self._Parameter()
  elseif self.name =~? '^*INCLUDE_PATH'
    return self._Include_path()
  elseif self.name =~? '^*INCLUDE'
    return self._Include()
  elseif self.name =~? '^*NODE'
    return self._Node()
  elseif self.name =~? '^*DATABASE_CROSS_SECTION'
    return self._Database_cross_section()
  elseif self.name =~? '^*DATABASE_HISTORY'
    return self._Database_history()
  elseif self.name =~? '^*SENSOR'
    return self._Sensor()
  else
    return self._Kword()
  endif
endfunction

"-------------------------------------------------------------------------------

function! s:GetLayout(kwname) abort

  if a:kwname =~? 'NODE\s*$' ||
  \  a:kwname =~? 'AIRBAG_REFERENCE_GEOMETRY\h*\s*$'
    return [
    \        [8,16,16,16,8,8]
    \      ]
  endif

  if a:kwname =~? 'NODE %\s*$' ||
  \  a:kwname =~? 'AIRBAG_REFERENCE_GEOMETRY\h* %\s*$'
    return [
    \        [10,16,16,16,10,10]
    \      ]
  endif

  if a:kwname =~? 'ELEMENT_SEATBELT\s*$'
    return [
    \        [8,8,8,8,8,16,8,8]
    \      ]
  endif

  if a:kwname =~? 'ELEMENT_SEATBELT %\s*$'
    return [
    \        [10,10,10,10,10,16,10,10]
    \      ]
  endif

  if a:kwname =~? 'ELEMENT_SEATBELT\h\+\s*$'
    return [
    \        [8,8,8,8,8,8,8,8]
    \      ]
  endif

  if a:kwname =~? 'ELEMENT_SEATBELT\h\+ %\s*$'
    return [
    \        [10,10,10,10,10,10,10,10]
    \      ]
  endif

  if a:kwname =~? 'ELEMENT\h\+\s*$' ||
  \  a:kwname =~? 'AIRBAG_SHELL_REFERENCE_GEOMETRY\h*\s*$'
    return [
    \        [8,8,8,8,8,8,8,8,8,8]
    \      ]
  endif

  if a:kwname =~? 'ELEMENT\h\+ %\s*$' ||
  \  a:kwname =~? 'AIRBAG_SHELL_REFERENCE_GEOMETRY\h* %\s*$'
    return [
    \        [10,10,10,10,10,10,10,10,10,10]
    \      ]
  endif

  if a:kwname =~? 'PART'
    return [
    \        [70],
    \        [10,10,10,10,10,10,10,10]
    \      ]
  endif

  if a:kwname =~? 'DEFINE_CURVE_TITLE'
    return [
    \        [80],
    \        [10,10,10,10,10,10,10,10],
    \        [20, 20] 
    \      ]
  endif

  if a:kwname =~? 'DEFINE_CURVE'
    return [
    \       [10,10,10,10,10,10,10,10],
    \       [20, 20]
    \      ]
  endif

  if a:kwname =~? 'PARAMETER_EXPRESSION'
    return [
    \       [10, 70],
    \      ]
  endif

  return [[10,10,10,10,10,10,10,10]]


endfunction

"-------------------------------------------------------------------------------

function s:GetText(options) dict

  "-----------------------------------------------------------------------------
  " Function to get row and column for specyfic cursor position.
  "
  " Arguments:
  "   - a:options dict with keys:
  "     - 'colcurpos' : cursor position in line, optional, count from 1, optional
  "                     if missing or 0 current cursor position is used.
  "     - 'colnr'     : keyword column number, optional, overwrite 'colcurpos'
  "                     if missing or 0 current 'colcurpos' is used.
  "     - 'rownr'     : keyword dataline row number, optional
  "                     if missing or 0 current cursor position is used.
  " Return:
  "   - a:options dict with keys:
  "     - 'all'       : all keys below
  "     - 'colcurpos' : cursor position in line
  "     - 'colnr'     : ls-dyna column number
  "     - 'coltext'   : ls-dyna column text
  "     - 'rownr'     : ls-dyna kword dataline number
  "     - 'rowtext'   : ls-dyna row text
  "     - 'rowlist'   : list of ls-dyna columns for 'rownr'
  "-----------------------------------------------------------------------------

  if getline('.')[0] == '$'
    return {}
  endif

  "set input data
  let options = {} 

  let options.curcol    = get(a:options,    'curcol',  0)  >  0 ? a:options.curcol    : self.curcol
  let options.curline   = get(a:options,   'curline',  0)  >  0 ? a:options.curline   : self.curline
  let options.rownr     = get(a:options,     'rownr',  0)  >  0 ? a:options.rownr     : (options.curline-self.first)-(self.lines[1:options.curline-self.first]->filter({_,val->val[0]=='$'})->len())
  let options.rowtext   = get(a:options,   'rowtext', '') != '' ? a:options.rowtext   : self.Datalines()[options.rownr]

  "-----------------------------------------------------------------------------
  let isfreeformat = s:IsFreeFormat(options.rowtext)
  " free line format
  if isfreeformat
    let nbracket = 0
    let rowLayout = []
    let collen = 0
    for char in options.rowtext->split('\zs')
      let collen += 1
      if char == '('
        let nbracket += 1
      elseif char == ')'
        let nbracket -= 1
      elseif char == ',' && nbracket == 0
        call add(rowLayout, collen) 
        let collen = 0
      endif
    endfor
    call add(rowLayout, len(options.rowtext)-rowLayout[-1]) 
  " fixed line format
  else
    let kwLayout = s:GetLayout(self.name)
    let rowLayout = kwLayout->get(options.rownr-1, kwLayout[-1])
  endif

  "-----------------------------------------------------------------------------
  " split line respect to row format
  let rowlist = []
  let start = 0
  for len in rowLayout 
    let lennr = str2nr(len)
    let rowlist += [options.rowtext->strpart(start, len)->substitute(',$','','')]
    let start += len
  endfor 

  "-----------------------------------------------------------------------------
  " find column number
  if has_key(a:options, 'colnr') && a:options.colnr > 0
    let colnr = a:options.colnr
  else
    let colnr = 1
    let lennr = 0
    for len in rowLayout
      let lennr += len
      if options.curcol <= lennr
        break
      endif
      let colnr += 1
    endfor
  endif

  "-----------------------------------------------------------------------------
  " return output
  
  let output = {}
  if a:options->has_key('curcol') || a:options->has_key('all')
    let output.curcol = options.curcol
  endif
  if a:options->has_key('curline') || a:options->has_key('all')
    let output.curline = options.curline
  endif
  if a:options->has_key('colnr') || a:options->has_key('all')
    let output.colnr = colnr
  endif
  if a:options->has_key('coltext') || a:options->has_key('all')
    let output.coltext = get(rowlist, colnr-1, '')
  endif
  if a:options->has_key('rownr') || a:options->has_key('all')
    let output.rownr = options.rownr
  endif
  if a:options->has_key('rowtext') || a:options->has_key('all')
    let output.rowtext = options.rowtext
  endif
  if a:options->has_key('rowlist') || a:options->has_key('all')
    let output.rowlist = rowlist
  endif
  if a:options->has_key('isfreeformat') || a:options->has_key('all')
    let output.isfreeformat = isfreeformat
  endif
  if a:options->has_key('cword') || a:options->has_key('all')
    if self.name =~? 'PARAMETER_EXPRESSION' && colnr == 2
      let output.cword = expand('<cword>')
    elseif self.name =~? 'PARAMETER' && fmod(colnr,2) != 0
      let output.cword = get(rowlist,colnr-1,'')->substitute('^[IRC]', '', '')->trim()
    elseif isfreeformat
      let output.cword = expand('<cword>')
    else
      let output.cword = substitute(get(rowlist,colnr-1,''), '[-&<>]', '', 'g')->trim()
    endif
  endif

  return output

endfunction

"-------------------------------------------------------------------------------

function! s:Write(...) dict
  let lnum = a:0 == 0 ? self.first : a:1
  call append(lnum-1, self.lines)
endfunction

"-------------------------------------------------------------------------------

function! s:Delete() dict
  execute 'silent 'self.first.','.self.last.'delete'
endfunction

"-------------------------------------------------------------------------------

function! s:Comment(prefix) dict
  call map(self.lines, 'a:prefix .. v:val')
endfunction

"-------------------------------------------------------------------------------

function! s:Datalines() dict
  return filter(copy(self.lines), 'v:val[0] != "$"')
endfunction

"-------------------------------------------------------------------------------

function! s:Encrypt(lvl, vendor_date='') dict
  let datalines = self.Datalines()
  let lines_open = a:lvl == 0 ? [] : datalines[: a:lvl-1]
  let lines_for_encrypt = datalines[a:lvl :]
  if !empty(a:vendor_date)
    let vBlock = ['*VENDOR', 'DATE      ' .. a:vendor_date]
    let lines_for_encrypt = vBlock + lines_for_encrypt + ['*VENDOR_END']
  endif
  let lines_after_encrypt = lsdyna_encryption#Encrypt(lines_for_encrypt)
  let self.lines = extend(lines_open, lines_after_encrypt)
  return self.lines
endfunction

"-------------------------------------------------------------------------------

function! s:IsFreeFormat(line) abort

  if a:line =~? '[<>]'
    return 1
  elseif a:line =~? ',' && a:line !~? '[()]'
    return 1
  endif
  return 0

endfunction

"-------------------------------------EOF---------------------------------------
