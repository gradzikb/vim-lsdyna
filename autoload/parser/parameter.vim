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

function! parser#parameter#Parameter() dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *PARAMETER_ object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of parameter objects base on keyword object.
  " Members:
  " - self.first : kword 1st line number
  " - self.last  : kword last line number
  " - self.bufnr : buffer number
  " - self.file  : full file path
  " - self.name  : kword name
  " - self.type  : kword type
  " - self.lnum  : parameter line
  " - self.pname : parameter name
  " - self.ptype : parameter type (R, I, C))
  " - self.pval  : parameter value
  " Methods:
  " - Qf() : create representation used with setqflist()
  "-----------------------------------------------------------------------------

  " new members
  let params = []

  let lines = self.lines[1:]

  " get rid of members/mehods you do not want to inherit
  call filter(self, 'v:key[0] != "_"')

  "-----------------------------------------------------------------------------
  " this part process *PARAMETER_EXPRESSION
  if self.name =~? 'EXPRESSION'

    let lcount = 0
    for line in lines
      let lcount += 1
      if line[0] =~? '[RIC]'
        let param = copy(self)
        let param.pname = s:Trim(line[1:9])
        let param.ptype = toupper(line[0])
        let param.pval  = s:Trim(line[10:])
        let param.lnum  = param.first + lcount
        let param.Qf    = function('<SID>Qf')
        let param.Tag   = function('<SID>Tag')
        let param.Omni  = function('<SID>Omni')
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
            let param.pname = s:Trim(cline[1:9])
            let param.ptype = toupper(cline[0])
            let param.pval  = s:Trim(cline[10:19])
            let param.lnum  = param.first + lcount
            let param.Qf    = function('<SID>Qf')
            let param.Tag   = function('<SID>Tag')
            let param.Omni  = function('<SID>Omni')
            call add(params, param)
          endif
        endfor
      endif
    endfor

  endif

  return params

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
  "   - self.text  : kword_name|kword_type|kword_id|kword_title
  "-----------------------------------------------------------------------------

    let qf = {}
    let qf.bufnr = self.bufnr
    let qf.lnum  = self.lnum
    let qf.text  = 'parameter'.'|'.self.name.'|'.self.type.'|'.self.ptype.'|'.self.pname.'|'.self.pval

  return qf

endfunction

function! s:Tag() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Generate tag item from parameter object.
  " Returns:
  "   Tag string
  "-----------------------------------------------------------------------------

  let tag = self.pname."\t".self.file."\t".self.lnum.";\"\tkind:PARAMETER\ttitle:"
  return tag

endfunction

function! s:Omni() dict

  "-----------------------------------------------------------------------------
  " Method:
  "   Generate omni complete item base on kword
  " Returns:
  "   Tag string
  "-----------------------------------------------------------------------------

  let item = {}
  let item.word = self.pname
  let item.menu = self.pval
  let item.kind = self.ptype
  let item.dup  = 1
  return item

endfunction

"-------------------------------------EOF---------------------------------------
