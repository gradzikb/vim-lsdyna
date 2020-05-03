"-------------------------------------BOF---------------------------------------

" Vim filetype plugin file
"
" Language:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  01.01.2018
" Version:      1.0.0
"
"-------------------------------------------------------------------------------
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_kvars#kvars(path)

  "-----------------------------------------------------------------------------
  " Function to initialize keywords variables dictionary (class constructor).
  "
  " Arguments:
  " - path (string) : path to directory with keyword variables library
  "                   if empty string kvars set to empty dict
  " Return:
  " - kvar object
  " Example:
  " - let kvars = lsdyna_kvars#kvars('')
  " - let kvars = lsdyna_kvars#kvars('/home/user/dynaKvars.dat')
  "-----------------------------------------------------------------------------

  " class
  let class = {}

  " class members
  let class.kvars = {}

  " class methods
  let class.get  = function("lsdyna_kvars#get")
  let class.read = function("lsdyna_kvars#read")

  " constructor
  if !empty(a:path) | call class.read(a:path) | endif

  return class

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_kvars#read(path) dict

  "-----------------------------------------------------------------------------
  " Function to read kvars library class from external file.
  "
  " Arguments:
  " - path (string) : path to directory with keyword variables library
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  " loop over lines
  for sline in readfile(a:path)

    " go to next line if empty
    if empty(sline) | continue | endif

    " get keyword and option
    let line = split(sline,'\s*:\s*')
    let keyword = tolower(line[0])
    let variable = tolower(line[1])

    " add keyword if not exists
    if !has_key(self.kvars, keyword)
      let self.kvars[keyword] = {}
    endif

    " add option if not exists
    if !has_key(self.kvars[keyword], variable)
      let self.kvars[keyword][variable] = []
    endif

    " add variable
    call add(self.kvars[keyword][variable], {'value':printf("%10s", line[2]), 'description': trim(line[3])})

  endfor

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_kvars#get(keyword, variable) dict

  "-----------------------------------------------------------------------------
  " Function to get kvars list for specific keyword and variable.
  "
  " Arguments:
  " - keyword (string)  : lsdyna keyword name
  " - variable (string) : variable header (dof, vad, ...)
  " Return:
  " - list : list with keyword variables
  " Example:
  " - kvars.get('lod_node', 'dof')
  "-----------------------------------------------------------------------------

  for key in keys(self.kvars)
    if a:keyword =~? key
      return get(self.kvars[key], a:variable, [])
    endif
  endfor

endfunction

"-------------------------------------EOF---------------------------------------
