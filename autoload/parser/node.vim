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

function! parser#node#Node() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *NODE object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of node objects base on keyword object.
  " Members:
  " - self.xxxx   : inherits from keyword abstract class
  " - self.format : columns format (i8, i10, i20)
  " Methods:
  " - self.Nodes()   : return dict with nodes
  " - self.QF()      : return quickfix list
  " - self.Replace() : replace nodes coordinates
  " - self.Tag()     : return tags list
  "-----------------------------------------------------------------------------

  "-----------------------------------------------------------------------------
  " memebers

  if self.name =~? '%\s*$'
    let self.format = 'i10'
  elseif self.name =~? '+\s*$'
    let self.format = 'i20'
  else
    let self.format = 'i8'
  endif
 
  "-----------------------------------------------------------------------------
  " methods

  let self.Nodes   = function('<SID>Nodes')
  let self.Qf      = function('<SID>Qf')
  let self.Replace = function('<SID>Replace')
  let self.Tag     = function('<SID>Tag')

  "-----------------------------------------------------------------------------
  " get rid of members/mehods you do not want to inherit
  call filter(self, 'v:key[0] != "_"')

  return [self]

endfunction

"-------------------------------------------------------------------------------
"    METHODS
"-------------------------------------------------------------------------------
"
function! s:Qf() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Convert contact object to quickfix item.
  " Returns:
  "   Quickfix list item (dict, see :help setqflist())
  "   - self.bufnr : buffer number
  "   - self.lnum  : part id line number
  "   - self.text  : kword_name|kword_type|kword_id|kword_title
  "-----------------------------------------------------------------------------

    let qf = {}
    let qf.bufnr = self.bufnr
    let qf.lnum  = self.first
    let qf.type  = 'U'
    "let qf.text  = self.name.'|'.self.hide
    let qftext = copy(self)
    call filter(qftext, 'type(v:val) != v:t_func') 
    call remove(qftext, 'lines')
    let qf.text  = string(qftext)

  return qf

endfunction

function! s:Tag() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Generate tag item from node object.
  " Returns:
  "   Tag string
  "-----------------------------------------------------------------------------

  let tag = "0\t".self.file."\t".self.first.";\"\tkind:NODE\ttitle:"
  return tag

endfunction

function! s:Nodes() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Return list of nodes id and coordinates.
  " Returns:
  "   Dict {'id':'[x, y, z]', ...}
  "-----------------------------------------------------------------------------

  let nodes = {}

  if self.format == 'i8'
    for line in self.Datalines()[1:]
      let id = str2nr(line[0:7])
      let x  = str2float(line[8:23])
      let y  = str2float(line[24:39])
      let z  = str2float(line[40:55])
      let nodes[id] = [x, y, z]
    endfor
  elseif self.format == 'i10'
    for line in self.Datalines()[1:]
      let id = str2nr(line[0:9])
      let x  = str2float(line[10:25])
      let y  = str2float(line[26:41])
      let z  = str2float(line[42:57])
      let nodes[id] = [x, y, z]
    endfor
  elseif self.format == 'i20'
    for line in self.Datalines()[1:]
      let id = str2nr(line[0:19])
      let x  = str2float(line[20:39])
      let y  = str2float(line[40:59])
      let z  = str2float(line[60:79])
      let nodes[id] = [x, y, z]
    endfor
  endif

  return nodes

endfunction

function! s:Replace(nodes, offset) dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Replace nodes in current node object.
  " Arguments:
  "   - nodes (dict)    : dictinary with new nodes in format as in self.Nodes()
  "   - offset (number) : offset used to compare nodes id
  " Returns:
  "   - ncount (number) : number of replaced nodes
  "-----------------------------------------------------------------------------

  if self.format == 'i8'
    let str_format = '%8s%16.6f%16.6f%16.6f'
    let id_len     = 8
  elseif self.format == 'i10'
    let str_format = '%10s%16.6f%16.6f%16.6f'
    let id_len     = 10
  elseif self.format == 'i20'
    let str_format = '%20s%20.6f%20.6f%20.6f'
    let id_len     = 20
  endif

  let ncount = 0
  for i in range(1, len(self.lines)-1)
    if self.lines[i][0] !=# '$'
      let id = str2nr(self.lines[i]->strpart(0,id_len))-a:offset
      if has_key(a:nodes, id)
        let self.lines[i] = printf(str_format, id+a:offset, a:nodes[id][0], a:nodes[id][1], a:nodes[id][2])
        let ncount += 1
      endif
    endif
  endfor

  return ncount

endfunction

"-------------------------------------EOF---------------------------------------
