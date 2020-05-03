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

function! lsdyna_parser#Keyword(lnum, bufnr, flags)

  "-----------------------------------------------------------------------------
  " Keyword class.
  "
  " Create keyword object of any Ls-Dyna keyword in line {lnum} in buffer {bufnr}.
  " Used as abstract class for more specialized classes as part, section.
  " It change cursor position and does not restore it!
  "
  " Constructor:
  "   let kword = lsdyna_keyword#Keyword(lnum[, bufnr])
  " Arguments:
  "   - lnum  : keyword line number
  "   - bufnr : buffer number
  "   - flags : c - restore (c)ursor position after parsing
  "             n - use (n)oautocommand
  "             f - keyword name is in a:lnum
  " Return:
  "   - dict : keyword class object
  " Members:
  "   - self.first : kword 1st line number in file
  "   - self.last  : kword last line number
  "   - self.bufnr : buffer number with kword
  "   - self.file  : file name with kword
  "   - self.name  : full kword name (*PART, *SECTION, ...)
  "   - self.type  : kword type, substring of kword name after 1st '_' (INERTIA)
  "   - self.lines : list with all kword lines, includes comments lines
  " Methods:
  "   - self.Datalines()               : return all kword data lines
  "   - self._Kword()                  : return child class for any kword
  "   - self._Part()                   : return child class for *PART
  "   - self._Section()                : return child class for *SECTION
  "   - self._Material()               : return child class for *MATERIAL
  "   - self._Define_curve()           : return child class for *DEFINE_CURVE
  "   - self._Define_coord()           : return child class for *DEFINE_COORDINATE
  "   - self._Define_trans()           : return child class for *DEFINE_TRANSFORMATION
  "   - self._Define_vector()          : return child class for *DEFINE_VECTOR
  "   - self._Set()                    : return child class for *SET
  "   - self._Contact()                : return child class for *CONTACT
  "   - self._Parameter()              : return child class for *PARAMETER
  "   - self._Include()                : return child class for *INCLUDE
  "   - self._Node()                   : return child class for *NODE
  "   - self._Database_cross_section() : return child class for *DATABASE_CROSS_SECTION
  "
  "-----------------------------------------------------------------------------

  " load buffer if you are in diffrent

  if a:flags =~? 'c'
    let save_cursor = getpos(".")
    let save_cursor[0] = bufnr('%')
  endif

  if a:bufnr != bufnr('%')
    let cmd = a:flags =~? 'n' ? 'noautocmd buffer ' : 'buffer '
    execute cmd a:bufnr
  endif

  let re_kword = '^*'         " regular expression to find keyword name
  let re_dline = '^[^$]\|^$'  " regular expression to find data line

  " search first and last kword line
  " 1. look backward keyword name
  " 2. look forward next keyword name or end of the file
  " 3. look backward data line
  call cursor(a:lnum, 0)
  let lnum_start = a:flags =~? 'f' ? a:lnum : search(re_kword,'bWc')
  let next_kw = search(re_kword.'\|BEGIN PGP MESSAGE', 'W')
  if next_kw == 0 | call cursor(line('$'), 0) | endif
  let lnum_end = next_kw == 0 ? search(re_dline,'bWc') : search(re_dline,'bW')

  " class keyword
  let kword = {}

  " class members
  let kword.first = lnum_start
  let kword.last  = lnum_end
  let kword.bufnr = a:bufnr
  let kword.file  = expand('%:p')
  let kword.name  = toupper(trim(getline(lnum_start)))
  let kword.type  = stridx(kword.name, '_') >= 0 ? kword.name[stridx(kword.name, '_')+1:] : ''
  let kword.lines = getline(lnum_start, lnum_end)

  " class methods
  let kword.Write                   = function('<SID>Write')
  let kword.Delete                  = function('<SID>Delete')
  let kword.Datalines               = function('<SID>Datalines')
  let kword.Encrypt                 = function('<SID>Encrypt')
  let kword._Kword                  = function('<SID>Kword')
  let kword._General                = function('parser#general#General')
  let kword._Node                   = function('parser#node#Node')
  let kword._Part                   = function('parser#part#Part')
  let kword._Section                = function('parser#section#Section')
  let kword._Mat                    = function('parser#mat#Mat')
  let kword._Set                    = function('parser#set#Set')
  let kword._Define_curve           = function('parser#define_curve#Define_curve')
  let kword._Define_coord           = function('parser#define_coord#Define_coord')
  let kword._Define_trans           = function('parser#define_trans#Define_trans')
  let kword._Define_vector          = function('parser#define_vector#Define_vector')
  let kword._Contact                = function('parser#contact#Contact')
  let kword._Parameter              = function('parser#parameter#Parameter')
  let kword._Include                = function('parser#include#Include')
  let kword._Include_path           = function('parser#include_path#Include_path')
  let kword._Database_cross_section = function('parser#database_cross_section#Database_cross_section')

  if a:flags =~? 'c'
    execute 'noautocmd buffer ' . save_cursor[0]
    call setpos('.', save_cursor)
  endif

  return kword

endfunction

"-------------------------------------------------------------------------------

function! s:Kword() dict
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
  else
    return self._General()
  endif
endfunction

"-------------------------------------------------------------------------------

function! s:Write(lnum) dict
  call append(a:lnum-1, self.lines)
endfunction

"-------------------------------------------------------------------------------

function! s:Delete() dict
  execute 'silent 'self.first.','.self.last.'delete'
endfunction

"-------------------------------------------------------------------------------

function! s:Datalines() dict
  return filter(copy(self.lines), 'v:val[0] != "$"')
endfunction

"-------------------------------------------------------------------------------

function! s:Encrypt(lvl) dict

  let datalines = self.Datalines()
  let lines_open = a:lvl == 0 ? [] : datalines[: a:lvl-1]
  let lines_encrypt = lsdyna_encryption#Encrypt(datalines[a:lvl :])
  let self.lines = extend(lines_open, lines_encrypt)

  return self.lines

endfunction

"-------------------------------------------------------------------------------

function! s:Offset(val, flag) dict

  for line in self.lines[1:]
    if line[0] != '$'
      let line = trim(line)
      let lline = []
      for i in range(0, len(line), 10))
        call add(lline, line[i:i+9])
      endfor
      echo lline
    endif
  endfor

endfunction
"-------------------------------------EOF---------------------------------------
