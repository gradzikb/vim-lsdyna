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

function! parser#parameter#Parameter(...) dict

  "-----------------------------------------------------------------------------
  " Class:
  "   Represent *PARAMETER_ object.
  " Inherits:
  "   Keyword class.
  " Returns:
  "   List of parameter objects base on keyword object.
  " Members:
  " - self.bufnr : buffer number
  " - self.dub   : duplicate flag (0 - no dub, 1 - dub)
  " - self.file  : full file path
  " - self.first : kword 1st line number
  " - self.last  : kword last line number
  " - self.lnum  : parameter line number
  " - self.name  : kword name
  " - self.peval : parameter value after evaluation
  " - self.pname : parameter name
  " - self.ptype : parameter type (R, I, C))
  " - self.pval  : parameter value
  " - self.type  : kword type (kword name after 1st '_', _EXPRESSION, _LOCAL)
  " Methods:
  " - Omni() : create representation used with omni-completion
  " - Qf()   : create representation used with setqflist()
  " - Tag()  : create representation used with tags
  "-----------------------------------------------------------------------------

  " global list of all parameters and there values, need for evaluation of
  " parameters values when depend on other parameters
  if !exists('g:lsdyna_manager_parameters')
    let g:lsdyna_manager_parameters = {}
  endif

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
        let param.lnum  = param.first + lcount
        "----------------------------------------------------------------------
        " set parameter value, if needed loop over multi line definition
        let param.pval  = trim(line[10:])
        let lnum = param.lnum + 1
        while 1
          let exprline = getline(lnum)
          if exprline[0] == '$'
            let lnum += 1
            continue
          elseif exprline =~? '^ \{10}'
            let param.pval = param.pval . getline(lnum)[10:]
            let lnum = lnum + 1
          else
            break
          endif
        endwhile
        let param.pval = substitute(param.pval, '[ &<>]', '', 'g')
        "let param.dub = has_key(g:lsdyna_manager_parameters, toupper(param.pname)) ? 1 : 0
        let param.peval = lsdyna_parameter#Eval(param.pval)
        " all parameter values are saved in global dict cause I need them to
        " make evaluation, I use this dict also to check duplicate parameters
        let g:lsdyna_manager_parameters[toupper(param.pname)] = param.peval
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

          " free format
          let lline = []
          if line =~? ','
            let lline = split(line, '\s*,\s*')
          " columne format
          else
            for i in range(8)
              call add(lline, strpart(trim(line), i*10, 10))
            endfor
            call filter(lline, '!empty(v:val)')
          endif

          " clean up all items
          call map(lline, 'trim(v:val)')

          " process parameter line list
          for i in range(0, len(lline)-1, 2)
            let param = copy(self)
            let param.lnum  = param.first + lcount
            let param.pname = trim(lline[i][1:])
            let param.ptype = toupper(lline[i][0])
            let param.pval  = trim(substitute(lline[i+1], '[&<>\s]', '', 'g'))
            "let param.dub   = has_key(g:lsdyna_manager_parameters, toupper(param.pname)) ? 1 : 0
            let param.peval = lsdyna_parameter#Eval(param.pval)
            let g:lsdyna_manager_parameters[toupper(param.pname)] = param.peval
            let param.Qf    = function('<SID>Qf')
            let param.Tag   = function('<SID>Tag')
            let param.Omni  = function('<SID>Omni')
            call add(params, param)
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
    let qf.type  = 'P'
    "let qf.text  = self.name.'|'.self.type.'|'.self.ptype.'|'.self.pname.'|'.self.pval.'|'.self.peval.'|'.self.hide
    let qftext = copy(self)
    call filter(qftext, 'type(v:val) != v:t_func') 
    call remove(qftext, 'lines')
    let qf.text  = string(qftext)

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
  let item.menu = self.peval
  let item.kind = self.ptype
  let item.dup  = 1
  "let item.info = self.type =~? 'EXPRESSION' ? '' : self.pval
  let item.info = self.pval ==? self.peval ? '' : '='..self.pval
  return item

endfunction

"-------------------------------------EOF---------------------------------------
