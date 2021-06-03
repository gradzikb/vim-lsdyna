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
  "   - self.bufnr : buffer number with kword
  "   - self.file  : file path name with kword
  "   - self.first : kword 1st line number in file
  "   - self.last  : kword last line number in file
  "   - self.lines : list with all kword lines, includes comments lines
  "   - self.name  : full kword name (*PART, *SECTION, ...)
  "   - self.type  : kword type, substring of kword name after 1st '_' (INERTIA)
  "   - self.hide  : status if the keyword is commented or not (0 - not commented, 1- commented)
  " Methods:
  "   - self.Comment()                 : comment kword body
  "   - self.Uncomment()               : uncomment kword body
  "   - self.Datalines()               : Return all datalines (remove comment lines from kword body)
  "   - self.Delete()                  : delete kword body from file
  "   - self.Encrypt()                 : encrypt kword body
  "   - self.Write()                   : write kword body into file
  "   - self._Autodetect()             : detect kword type and return child class
  "   - self._Kword()                  : return child class for any kword
  "   - self._Contact()                : return child class for *CONTACT
  "   - self._Database_cross_section() : return child class for *DATABASE_CROSS_SECTION
  "   - self._Define_coord()           : return child class for *DEFINE_COORDINATE
  "   - self._Define_curve()           : return child class for *DEFINE_CURVE
  "   - self._Define_trans()           : return child class for *DEFINE_TRANSFORMATION
  "   - self._Define_vector()          : return child class for *DEFINE_VECTOR
  "   - self._Include()                : return child class for *INCLUDE
  "   - self._Include_path()           : return child class for *INCLUDE_PATH
  "   - self._Material()               : return child class for *MATERIAL
  "   - self._Node()                   : return child class for *NODE
  "   - self._Parameter()              : return child class for *PARAMETER
  "   - self._Part()                   : return child class for *PART
  "   - self._Section()                : return child class for *SECTION
  "   - self._Set()                    : return child class for *SET
  "
  "-----------------------------------------------------------------------------

  "let re_kword = '^*'         " regular expression to find keyword name
  "let re_dline = '^[^$]\|^$'  " regular expression to find data line
  let re_kword = '^\(\'..g:lsdynaCommentString..'\)\?\*'           " regular expression to find keyword name
  let re_dline = '^\(\'..g:lsdynaCommentString..'\)\?\([^$]\|$\)'  " regular expression to find data line

  " save current cursor position so I can restore it later
  " getpos() set bufnr only for mark, so I overwrite it manually.
  let save_cursor = getpos(".")
  let save_cursor[0] = bufnr('%')

  " set cursor on a:lnum in a:bufnr
  if a:bufnr != bufnr('%')
    execute 'noautocmd buffer' a:bufnr
  endif
  call cursor(a:lnum, 0)

  " search first and last kword line
  " 1. look backward keyword name
  " 2. look forward next keyword name or end of the file
  " 3. look backward data line
  "let lnum_start = a:flags =~? 'f' ? a:lnum : search(re_kword,'bWc')
  let lnum_start = search(re_kword,'bWc')
  let next_kw = search(re_kword.'\|BEGIN PGP MESSAGE', 'W')
  if next_kw == 0
    call cursor(line('$'), 0)
  else
    call cursor(line('.')-1, 0)
  endif
  let lnum_end = search(re_dline,'bWc')

  " class
  let kword = {}

  " class members
  let kword.first = lnum_start
  let kword.last  = lnum_end
  let kword.bufnr = a:bufnr
  let kword.file  = expand('%:p')
  let kword.hide  = getline(kword.first) =~? '^\'..g:lsdynaCommentString ? 1 : 0
  let kword.lines = getline(lnum_start, lnum_end)
  " remove comment prefix from all kword lines
  if kword.hide
    call map(kword.lines, {idx, val -> val[len(g:lsdynaCommentString):] })
  endif
  let kword.name  = toupper(trim(kword.lines[0]))
  let kword.type  = stridx(kword.name, '_') >= 0 ? kword.name[stridx(kword.name, '_')+1:] : ''

  " class methods to operate on kword lines
  let kword.Comment                 = function('s:Comment')    " comment kword body
  let kword.Datalines               = function('s:Datalines')  " return all datalines (remove comment lines from kword body)
  let kword.Delete                  = function('s:Delete')     " delete kword body from file
  let kword.Encrypt                 = function('s:Encrypt')    " encrypt kword body
  let kword.Write                   = function('s:Write')      " write kword body into file

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
  let kword._Contact                = function('parser#contact#Contact')
  let kword._Parameter              = function('parser#parameter#Parameter')
  let kword._Include                = function('parser#include#Include')
  let kword._Include_path           = function('parser#include_path#Include_path')
  let kword._Database_cross_section = function('parser#database_cross_section#Database_cross_section')

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
    return self._Kword()
  endif
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

"-------------------------------------EOF---------------------------------------
