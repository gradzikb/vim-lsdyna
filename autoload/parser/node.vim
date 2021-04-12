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
  " - self.first : kword 1st line number
  " - self.last  : kword last line number
  " - self.bufnr : buffer number
  " - self.file  : full file path
  " - self.name  : kword name
  " - self.type  : kword type
  " - self.id    : kword id
  " - self.title : kword title
  " - self.nodes : dict of nodes
  " Methods:
  "-----------------------------------------------------------------------------

  "let self.write   = function('lsdyna_keyword#node_write')
  "let self.replace = function('lsdyna_keyword#node_replace')
  let self.Tag     = function('<SID>Tag')
  let self.Qf      = function('<SID>Qf')
  let self.Nodes   = function('<SID>Nodes')
  let self.Replace = function('<SID>Replace')
  "let self.Offset = function('<SID>Offset')

  "let self.nodes = {}
  "for line in self.Datalines()[1:]
  "  let id = str2nr(line[0:7])
  "  let x  = str2float(line[8:23])
  "  let y  = str2float(line[24:39])
  "  let z  = str2float(line[40:55])
  "  let self.nodes[id] = [x, y, z]
  "endfor

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
    let qf.text  = self.name

  return qf

endfunction
"
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

  "let self.nodes = {}
  let nodes = {}

  " long format
  if self.Datalines()[0] =~? '+\s*$'
    for line in self.Datalines()[1:]
      let id = str2nr(line[0:19])
      let x  = str2float(line[20:39])
      let y  = str2float(line[40:59])
      let z  = str2float(line[60:79])
      let nodes[id] = [x, y, z]
    endfor
  " standard format
  else
    for line in self.Datalines()[1:]
      let id = str2nr(line[0:7])
      let x  = str2float(line[8:23])
      let y  = str2float(line[24:39])
      let z  = str2float(line[40:55])
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

  let ncount = 0
  for i in range(1, len(self.lines)-1)
    if self.lines[i][0] !=# '$'
      let id  = str2nr(self.lines[i][0:7])-a:offset
      if has_key(a:nodes, id)
        let self.lines[i] = printf("%8s%16.6f%16.6f%16.6f", id+a:offset, a:nodes[id][0], a:nodes[id][1], a:nodes[id][2])
        let ncount += 1
      endif
    endif
  endfor

  return ncount

endfunction

"-------------------------------------EOF---------------------------------------
