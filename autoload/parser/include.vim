"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  23.10 2019
"
" History of change:
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

"-------------------------------------------------------------------------------
"    LOCAL FUNCTIONS
"-------------------------------------------------------------------------------

function! s:Trim(string)

  "-----------------------------------------------------------------------------
  " Function to trim empty signs on string
  "-----------------------------------------------------------------------------

  let string = substitute(a:string,'^\s\+','','')
  let string = substitute(string,'\s\+$','','')
  return string

endfunction

"-------------------------------------------------------------------------------
"    CLASS
"-------------------------------------------------------------------------------

function! parser#include#Include() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *INCLUDE object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of include objects base on keyword object.
  " Members:
  " - self.first : kword 1st line number
  " - self.last  : kword last line number
  " - self.bufnr : buffer number
  " - self.file  : full file path
  " - self.name  : kword name
  " - self.type  : kword type
  " - self.path  : include file path
  " - self.read  : read status
  " - self.lnum  : include file path line number
  " Methods:
  " - Qf() : create representation used with setqflist()
  " Comment:
  "   Multi line entries are not supported.
  "   I assume 1st not comment line after *INCLUDE has path
  "   Multi line paths (' +' at the end) are supported.
  "-----------------------------------------------------------------------------

  let path = ''
  let pathlines = []

  " join path, ' +' at the end
  let count_path_lines = 0
  for line in self.Datalines()[1:]
    let count_path_lines += 1
    if line =~? ' +\s*$'
      let path = path . s:Trim(line)[0:-3]
    else
      let path = path . s:Trim(line)
      break
    endif
  endfor

  " find path line number
  let lnum = 0
  for line in self.lines[1:]
    let lnum += 1
    if line[0] != '$'
      break
    endif
  endfor

  " resolve path
  let file  = lsdyna_include#Resolve(path)

  " get rid of members which are not inherit
  call filter(self, 'v:key[0] != "_"')

  " include object
  let incl         = copy(self)
  let incl.lnum    = incl.first + lnum
  let incl.path    = file.path "path to file where *INCLUDE file is
  let incl.pathraw = path
  let incl.pathlnum1 = lnum " 1st line number with path
  let incl.pathlnum2 = lnum + count_path_lines - 1 " last line number with path
  let incl.read    = file.read
  let incl.Qf      = function('<SID>Qf')
  let incl.Tag     = function('<SID>Tag')
  "let incl.SetPath = function('<SID>SetPath')
  let incl.SetPath = function('parser#include#SetPath')

  return [incl]

endfunction

"-------------------------------------------------------------------------------
"    METHODS
"-------------------------------------------------------------------------------

function! s:Qf() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Convert kword object to quickfix item.
  " Returns:
  "   Quickfix list item (dict, see :help setqflist())
  "   - self.bufnr : buffer number
  "   - self.lnum  : part id line number
  "   - self.col   : column cursor position
  "   - self.text  : kword_name|kword_type|kword_id|kword_title
  "-----------------------------------------------------------------------------

    let qf = {}
    let qf.bufnr = self.bufnr
    "let qf.lnum  = self.lnum
    let qf.lnum  = self.first + self.pathlnum2
    let qf.col   = 1
    let qf.type  = 'I'
    "let qf.text  = fnamemodify(self.path,':t').'|'.self.read.'|'.self.type.'|'.self.file.'|'.self.hide
    let qftext = copy(self)
    call filter(qftext, 'type(v:val) != v:t_func') 
    call remove(qftext, 'lines')
    let qf.text  = string(qftext)

  return qf

endfunction

function! s:Tag() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Generate tag item from include object.
  " Returns:
  "   Tag string
  "-----------------------------------------------------------------------------

  let tag = fnamemodify(self.path,':p:t')."\t".self.file."\t".self.lnum.";\"\tkind:INCLUDE\ttitle:"
  return tag

endfunction

function! parser#include#SetPath(path, flag) dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Set *INCLUDE path to new or old value in specific format (single line,
  "   multi line)
  " Arguments:
  "   - path : string with new path, if empty '' path is not change
  "   - flag : flag to define path format
  "            s : whole path is set in single line
  "            m : whole path is set with multi line
  " Returns:
  "   -
  "-----------------------------------------------------------------------------

  let path = empty(a:path) ? self.pathraw : a:path
  if empty(a:flag)
    let flag = len(path)>80 ? 'm' : 's'
  else
    let flag = a:flag
  endif  

  if flag =~? 's'

    let lines = self.lines[0:self.pathlnum1-1] + [path] + self.lines[self.pathlnum2+1:]   

  elseif flag =~? 'm'

    " include path
    let pathname = fnamemodify(path, ':h') .. '/'
    let filename = fnamemodify(path, ':t')

    " split path over two first lines and file name put into 3rd line
    " this can be done only if path length can fit into two lines (max 156
    " signs) and file name can be fit into one line (max 80 signs)
    let multi_line_path = ''
    if len(pathname) <= 156 && len(filename) <= 80

      " I am try to not to cut directory name in the middle
      " look for last separator position in first 78 signs (max what I can put
      " inot one line), next check does the rest of pathname can be fit into
      " second line (another 78 signs) if not make cut at max position
      let lnum1_end = strridx(pathname, '/', 78)
      if lnum1_end > -1 && len(pathname)-lnum1_end < 78
        let cut_pos = lnum1_end+1
      else
        let cut_pos = 78
      endif

      for i in range(1, len(pathname))
        let multi_line_path = multi_line_path .. pathname[i-1]
        if i == cut_pos || i == 156 || (i == len(pathname) && !empty(filename))
          let multi_line_path = multi_line_path .. ' +'
        endif
      endfor

      let multi_line_path = multi_line_path .. filename

    " split everything equaly over all three lines
    else

      for i in range(1, len(path))
        let multi_line_path = multi_line_path .. path[i-1]
        if i == 78 || i == 156
          let multi_line_path = multi_line_path .. ' +'
        endif
      endfor

    endif

    let lines = self.lines[0:self.pathlnum1-1] + split(multi_line_path, ' +\zs') + self.lines[self.pathlnum2+1:]   

  endif

  let self.pathlnum2 = self.pathlnum2 + (len(lines) - len(self.lines)) " update position of last line in path
  let self.lines = lines

endfunction

"-------------------------------------EOF---------------------------------------
