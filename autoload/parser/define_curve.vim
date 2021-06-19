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
"    CLASS
"-------------------------------------------------------------------------------

function! parser#define_curve#Define_curve() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *DEFINE_CURVE keyword object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of define_curve objects base on keyword object.
  " Members:
  " - self.xxxx   : inherit from parent class
  " - self.id     : kword id
  " - self.title  : kword title
  " Methods:
  " - self.xxxx()        : inherit from parent class
  " - self.Omni()        : set omni-completion dictionary
  " - self.Qf()          : set quickfix dictionary
  " - self.Tag()         : set tag file line
  " - self.Points()      : return list of curve points
  " - self.WriteXYData() : write curve points to external file 
  "-----------------------------------------------------------------------------

  " get rid of members/mehods you do not want to inherit
  call filter(self, 'v:key[0] != "_"')

  " local variables
  let datalines = self.Datalines()
  " new members
  let self.id     = self.name =~? 'TITLE' ? str2nr(datalines[2][:9]) : str2nr(datalines[1][:9])
  let self.title  = self.name =~? 'TITLE' ? trim(datalines[1])       : ''
  " new methods
  let self.Qf          = function('<SID>Qf')
  let self.Tag         = function('<SID>Tag')
  let self.Omni        = function('<SID>Omni')
  let self.Points      = function('<SID>Points')
  let self.WriteXYData = function('<SID>WriteXYData')

  return [self]

endfunction

"-------------------------------------------------------------------------------
"    METHODS
"-------------------------------------------------------------------------------

function! s:Qf() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Convert keyword object to quickfix item.
  " Returns:
  "   Quickfix list item (:help setqflist()).
  "-----------------------------------------------------------------------------

  let qf = {}
  let qf.bufnr = self.bufnr
  let qf.lnum  = self.first
  let qf.type  = 'K'
  "let qf.text  = self.id.'|'.self.title.'|'.self.type.'|'.self.hide
  let qftext = copy(self)
  call filter(qftext, 'type(v:val) != v:t_func') 
  call remove(qftext, 'lines')
  let qf.text  = string(qftext)

  return qf

endfunction

function! s:Omni() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Generate omni complete item base on kword.
  " Returns:
  "   Quickfix list item (:help complete-items).
  "-----------------------------------------------------------------------------

  let item = {}
  let item.word = printf("%10s", self.id)
  let item.menu = self.title
  let item.dup  = 1
  let item.info = join(self.lines, "\n")

  return item

endfunction

function! s:Tag() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Generate tag item from define_curve object.
  " Returns:
  "   Tag string
  "-----------------------------------------------------------------------------

  let tag = self.id."\t".self.file."\t".self.first.";\"\tkind:DEFINE_CURVE\ttitle:".self.title
  return tag

endfunction

function! s:Points() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Create curve's point representation
  " Returns:
  "   self.points = [[x1, y1], [x2, y2], [x3, y3], ... ]
  "-----------------------------------------------------------------------------

  let datalines = self.Datalines()
  let pointlines = self.name =~# 'TITLE' ? datalines[3:] : datalines[2:]

  let points = []
  for line in pointlines
    let x = str2float(line[:19])
    let y = str2float(line[20:])
    call add(points, [x, y])
  endfor

  return points

endfunction

function! s:WriteXYData(file) dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Write curve object in HyperGraph XY data format
  " Arguments:
  "   a:file (string) : path to file where save curve
  " Returns:
  "   None
  "-----------------------------------------------------------------------------

  let dump = []
  let title = empty(self.title) ? 'No title' : self.title
  call add(dump, 'XYDATA, '.self.id.' - '.title)
  for point in self.Points()
    call add(dump, printf('%20.6e %20.6e', point[0], point[1]))
  endfor
  call add(dump, 'ENDDATA')
  call writefile(dump, a:file, 'a')

endfunction

"-------------------------------------EOF---------------------------------------
