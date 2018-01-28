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
"
" ls-dyna tags class:
" - includes representation of ls-dyna supported keywords
" - includes methods to work with them
"
" Class constructor:
" - let objName = lsdyna_tags#dynatags()
"
" Dyna tags class structure:
" - enties:
"   - objName.tags         : list of all tags
"   - objName.dynakeywords : list of all supported keywords
" - function:
"   - objName.set(keywords)         : function to set objName.tags
"   - objName.get(keywords)         : function to get objName.tags
"   - objName.write(keywords, path) : function to write objName.tags into tag file
"   - objName.read(keywords, path)  : function to read objName.tags from tag file
"   - objName.clear(keywords)       : function to delete objName.tags
"
"-------------------------------------------------------------------------------

function! lsdyna_tags#dynatags()

  "-----------------------------------------------------------------------------
  " Function to initialize dyna tags dictionary (class constructor).
  "
  " Arguments:
  " - none
  " Return:
  " - dynatags object
  "-----------------------------------------------------------------------------

  let class = {}

  " list of supported ls-dyna keywords
  let class.dynakeywords = ['part',
  \                         'section',
  \                         'mat',
  \                         'set',
  \                         'define_curve',
  \                         'define_coordinate',
  \                         'define_transformation',
  \                         'define_vector',
  \                         'define_friction',
  \                         'parameter']

  " initialize class dict
  let class.tags = {}
  for keyword in class.dynakeywords | let class.tags[keyword] = [] | endfor

  " class methods
  let class.clear = function("lsdyna_tags#clear")
  let class.get   = function("lsdyna_tags#get")
  let class.read  = function("lsdyna_tags#read")
  let class.set   = function("lsdyna_tags#set")
  let class.write = function("lsdyna_tags#write")

  return class

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#cmdlstags(...)

  "-----------------------------------------------------------------------------
  " Function used with LsTags command.
  "-----------------------------------------------------------------------------

  if a:0 == 0
    let searchMode = 'i'
  else
    let searchMode = a:1
  endif

  call g:dtags.set(join(a:000[1:]), searchMode)
  call g:dtags.write(join(a:000[1:]), g:lsdynaPathTags)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#tagCompare(i1, i2)

  "-----------------------------------------------------------------------------
  " Function used with sort() to compare 'id' key of two dictionaries.
  "-----------------------------------------------------------------------------

  return a:i1.id == a:i2.id ? 0 : a:i1.id > a:i2.id ? 1 : -1

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#headers(path)

  "-----------------------------------------------------------------------------
  " Function to initialize Ls-Dyna headers library from external file.
  "
  " Arguments:
  " - path (string) : path to headers file
  " Return:
  " - headers (dict) : dyna headers library
  "-----------------------------------------------------------------------------

  " build up headers dict
  let headers = {}
  for line in readfile(a:path)

    " get keyword and option and set dict item
    let line = split(line,'\s*:\s*')
    let headers[tolower(line[0])] =  tolower(line[1])

  endfor

  return headers

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#clear(keywords) dict

  "-----------------------------------------------------------------------------
  " Function to clear tags list for specific keywords.
  "
  " Arguments:
  " - keywords (string) : list of keywords to reset, when empty all supported
  "                       keywords used (self.tags.dynakeywords)
  " Return:
  " - none
  " Example:
  " - tags.clear("")
  " - tags.clear("part set")
  "-----------------------------------------------------------------------------

  if empty(a:keywords)
    for key in keys(self.tags) | let self.tags[key] = [] | endfor
  else
    for key in split(a:keywords) | let self.tags[key] = [] | endfor
  endif

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#write(keywords, path) dict

  "-----------------------------------------------------------------------------
  " Function to write tags for specific keywords into a tag file.
  "
  " Arguments:
  " - keywords (string) : list of keywords to write, when empty all supported
  "                       keywords used (self.tags.dynakeywords)
  " - path (string)     : path to the file
  " Return:
  " - none
  " Example:
  " - tags.write('', '~\.dynatags')
  " - tags.write('part set', '~\.dynatags')
  "-----------------------------------------------------------------------------

  " get list of tags for specific keywords
  let tags = self.get(a:keywords)

  " loop over tags and create one line entry for each
  let lines = []
  for tag in tags
    let line = tag.id."\t".tag.file."\t".tag.line.";\""."\t"."kind:".tag.kind."\t"."title:".tag.title
    call add(lines, line)
  endfor

  " write tags into a file
  call writefile(lines, a:path)

  " summary
  redraw | echo "Wrote " . len(tags) . " tags."

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#read(keywords, path) dict

  "-----------------------------------------------------------------------------
  " Function to read tags from external tag file.
  "
  " Arguments:
  " - keywords (string) : list of keywords to read, when empty all supported
  "                       keywords used (self.tags.dynakeywords)
  " - path (string)     : path to the file
  " Return:
  " - none
  " Example:
  " - tags.read('', '~\.dynatags')
  " - tags.read('part set', '~\.dynatags')
  "-----------------------------------------------------------------------------

  " build keywords list
  if empty(a:keywords)
    let keywords = join(self.dynakeywords, '\|')
  else
    let keywords = join(split(a:keywords), '\|')
  endif

  " reset current tags
  call self.clear('')

  " loop over all lines
  for line in readfile(a:path)

    " split with tabulator
    let line = split(line, '\t')

    " create dict entry for current tag
    let tag = {}
    let tag.id    = line[0]
    let tag.file  = line[1]
    let tag.line  = split(line[2], ';')[0]
    let tag.kind  = tolower(split(line[3], ':', 1)[-1])
    let tag.title = split(line[4], ':', 1)[-1]

    " add new tag entry if keyword is ok
    if tag.kind =~? keywords
      call add(self.tags[tag.kind], tag)
    endif

  endfor

  "return self.tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#get(keywords) dict

  "-----------------------------------------------------------------------------
  " Function to return list of tags for specific keywords.
  "
  " Arguments:
  " - keywords (string) : list of keywords to get, when empty all supported
  "                       keywords used (self.tags.dynakeywords)
  " Return:
  " - tags (list) : list of tags
  " Example:
  " - tags.get('')
  " - tags.get('part set')
  "-----------------------------------------------------------------------------

  let tags = []

  " return all tags
  if len(a:keywords) == 0
    for item in values(self.tags)
      let tags = tags + item
    endfor
  " return only specific tags
  else
    for tag in split(a:keywords)
      let tags = tags + get(self.tags, tag, [])
    endfor
  endif

  return tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#set(keywords, searchMode) dict

  "-----------------------------------------------------------------------------
  " Function to create tags for specific Ls-Dyna keywords.
  "
  " Arguments:
  " - keywords (string) : string with keywords to serach
  "                       empty string means all keywords
  " - searchMode (string) : search mode
  "   't' - search in tag file only
  "   'b' - search in current buffer only
  "   'B' - search in all loaded buffers
  "   'i' - like 2 but load all *INLCUDE files into buffers
  " Return:
  " - none
  " Example:
  " - tags.set('', 3)
  " - tags.set('part set, 1)
  "-----------------------------------------------------------------------------

  " define keywords list to search
  if empty(a:keywords)
    let keywords = copy(self.dynakeywords)
  else
    let keywords = split(a:keywords)
  endif

  " build regular expression for vimgrep command
  let reVimgrep = join(map(keywords, '"^\\*".v:val'), '\|')

  " clear qf list before vimgrep command
  call setqflist([])

  "-----------------------------------------------------------------------------
  " search ls-dyna keywords

  if a:searchMode ==# 't'
    " read dynatag file
    return g:tags.read(a:keywords, g:lsdynaTagsPath)
  " search only in current buffer
  elseif a:searchMode ==# 'b'
    silent! execute 'vimgrepadd /\c' . reVimgrep . '/j %'
  " search in all loaded buffers
  elseif a:searchMode ==# 'B'
    let buffer = bufnr('%')
    silent! execute 'bufdo! vimgrepadd /\c' . reVimgrep . '/j %'
    silent! execute 'buffer '.buffer
  " load *INCLUDES and search in all buffers
  elseif a:searchMode ==# 'i'
    let buffer = bufnr('%')
    call lsdyna_include#incl2buff()
    silent! execute 'bufdo! vimgrepadd /\c' . reVimgrep . '/j %'
    silent! execute 'buffer ' . buffer
  endif

  "-----------------------------------------------------------------------------
  " convert each entry from quick fix list (each keyword) into tag

  call self.clear('')
  for qf in getqflist()

    " qflist entry --> tag
    if qf.text =~? '^*PART'
      call extend(self.tags.part, lsdyna_tags#kw2tag_part(qf.bufnr, qf.lnum))
    elseif qf.text =~? '^*SECTION'
      call extend(self.tags.section, lsdyna_tags#kw2tag_section(qf.bufnr, qf.lnum))
    elseif qf.text =~? '^*MAT'
      call extend(self.tags.mat, lsdyna_tags#kw2tag_material(qf.bufnr, qf.lnum))
    elseif qf.text =~? '^*SET'
      call extend(self.tags.set, lsdyna_tags#kw2tag_define(qf.bufnr, qf.lnum, 1, 's', 'SET'))
    elseif qf.text =~? '^*DEFINE_CURVE'
      call extend(self.tags.define_curve, lsdyna_tags#kw2tag_define(qf.bufnr, qf.lnum, 1, 's', 'DEFINE_CURVE'))
    elseif qf.text =~? '^*DEFINE_COORDINATE_NODES'
      call extend(self.tags.define_coordinate, lsdyna_tags#kw2tag_define(qf.bufnr, qf.lnum, 1, '', 'DEFINE_COORDINATE'))
    elseif qf.text =~? '^*DEFINE_COORDINATE_SYSTEM'
      call extend(self.tags.define_coordinate, lsdyna_tags#kw2tag_define(qf.bufnr, qf.lnum, 2, '', 'DEFINE_COORDINATE'))
    elseif qf.text =~? '^*DEFINE_COORDINATE_VECTOR'
      call extend(self.tags.define_coordinate, lsdyna_tags#kw2tag_define(qf.bufnr, qf.lnum, 1. '', 'DEFINE_COORDINATE'))
    elseif qf.text =~? '^*DEFINE_FRICTION'
      call extend(self.tags.define_friction, lsdyna_tags#kw2tag_define(qf.bufnr, qf.lnum, 1, 's', 'DEFINE_FRICTION'))
    elseif qf.text =~? '^*DEFINE_TRANSFORMATION'
      call extend(self.tags.define_transformation, lsdyna_tags#kw2tag_define(qf.bufnr, qf.lnum, 1, 's', 'DEFINE_TRANSFORMATION'))
    elseif qf.text =~? '^*DEFINE_VECTOR'
      call extend(self.tags.define_vector, lsdyna_tags#kw2tag_define(qf.bufnr, qf.lnum, 1, '', 'DEFINE_VECTOR'))
    elseif qf.text =~? '^*PARAMETER'
      call extend(self.tags.parameter, lsdyna_tags#kw2tag_parameter(qf.bufnr, qf.lnum))
    endif

  endfor

  " sort tags for each keyword,
  " not necessary but completion list looks is easier to read after
  for tag in values(self.tags) | call sort(tag, "lsdyna_tags#tagCompare") | endfor


  "return self.tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#readkeyword(bufnr, lnum)

  "-----------------------------------------------------------------------------
  " Function to read keyword lines starting at {lnum} line in {bufnr} buffer.
  " Keyword lines are from {lnum} till EOF or next keyword definition (^*).
  " All comment lines are ignored. Line numbers are kept.
  "
  " Arguments:
  " - bufnr (number)   : buffer number with keyword
  " - lnum (number)    : line number with keyword
  " Return:
  " - kwLines (list) : [{'lnum':'line number', 'lstr':'line string'}, ... , {}]
  "-----------------------------------------------------------------------------

  " 1st line with keyword
  let kwLines = [{'lnum':a:lnum, 'lstr':getbufline(a:bufnr, a:lnum)[0]}]

  "-----------------------------------------------------------------------------
  " loop to read keyword data lines

  let lnum = a:lnum
  while 1

    " current line number
    let lnum += 1

    " get current line
    let line = getbufline(a:bufnr, lnum)

    " check line and add it
    if empty(line) " end of file
      break
    elseif line[0][0] == '*' " next keyword
      break
    elseif line[0][0] == '$' " comment line
      continue
    else
      call add(kwLines, {'lnum':lnum, 'lstr':line[0]}) " add current line
    endif

  endwhile

  return kwLines

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#kw2tag_material(bufnr, lnum)

  "-----------------------------------------------------------------------------
  " Function to create tag for *MAT_ ls-dyna keywords.
  "
  " Arguments:
  " - bufnr (number)   : buffer number with keyword
  " - lnum (number)    : line number with keyword
  " Return:
  " - tag : [{'id'    : 'keyword id or parameter name',
  "           'file'  : 'keyword file',
  "           'line'  : 'keyword line number',
  "           'kind'  : 'keyword kind',
  "           'title' : 'keyword title'}]
  "-----------------------------------------------------------------------------

  " read all keyword lines
  let lines = lsdyna_tags#readkeyword(a:bufnr, a:lnum)

  " set all tag info
  let tag = {}
  let tag.kind = 'MATERIAL'
  "let tag.file = getbufinfo(a:bufnr)[0].name
  let tag.file = fnamemodify(bufname(a:bufnr), ":p")
  if lines[0].lstr =~? 'TITLE'
    let tag.title = lines[1].lstr
    let tag.line  = lines[2].lnum
    let tag.id    = str2nr(lines[2].lstr[:9])
  else
    let tag.title = ""
    let tag.line  = lines[1].lnum
    let tag.id    = str2nr(lines[1].lstr[:9])
  endif

  return [tag]

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#kw2tag_part(bufnr, lnum)

  "-----------------------------------------------------------------------------
  " Function to create tag for *PART_ ls-dyna keywords.
  "
  " Arguments:
  " - bufnr (number)   : buffer number with keyword
  " - lnum (number)    : line number with keyword
  " Return:
  " - tags : [{'id'    : 'keyword id or parameter name',
  "            'file'  : 'keyword file',
  "            'line'  : 'keyword line number',
  "            'kind'  : 'keyword kind',
  "            'title' : 'keyword title'}, ..., {}]
  "-----------------------------------------------------------------------------

  " tag dictionary
  let tags = []

  " read all keyword lines
  let lines = lsdyna_tags#readkeyword(a:bufnr, a:lnum)

  " set keyword block size
  if lines[0].lstr =~? '_CONTACT'
    let size = 3
  elseif lines[0].lstr =~? '_INERTIA'
    let size = 5
  else
    let size = 2
  endif

  " loop over all keyword blocks
  for i in range(1, len(lines)-size, size)

    " cut one keyword block
    "let block = lines[i:i+size]
    let block = []
    for j in range(i, i+size-1)
      call add(block, lines[j])
    endfor

    " set all tag info
    let tag = {}
    let tag.kind  = 'PART'
    "let tag.file  = getbufinfo(a:bufnr)[0].name
    let tag.file = fnamemodify(bufname(a:bufnr), ":p")
    let tag.title = block[0].lstr
    let tag.line  = block[1].lnum
    let tag.id    = str2nr(block[1].lstr[:9])

    call add(tags, tag)

  endfor

  return tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#kw2tag_section(bufnr, lnum)

  "-----------------------------------------------------------------------------
  " Function to create tag for *SECTION_ ls-dyna keywords.
  "
  " Arguments:
  " - bufnr (number)   : buffer number with keyword
  " - lnum (number)    : line number with keyword
  " Return:
  " - tags : [{'id'    : 'keyword id or parameter name',
  "            'file'  : 'keyword file',
  "            'line'  : 'keyword line number',
  "            'kind'  : 'keyword kind',
  "            'title' : 'keyword title'}, ..., {}]
  "-----------------------------------------------------------------------------

  " tag dictionary
  let tags = []
  let kwSize = 2

  " read all keyword lines
  let lines = lsdyna_tags#readkeyword(a:bufnr, a:lnum)

  " keyword with title ? If yes increase block size by 1 line
  if lines[0].lstr =~? 'TITLE'
    let title = 1
    let size = kwSize + 1
  else
    let title = 0
    let size = kwSize
  endif

  " loop over all keyword blocks
  for i in range(1, len(lines)-size, size)

    " cut one keyword block
    "let block = lines[i:i+size]
    let block = []
    for j in range(i, i+size-1)
      call add(block, lines[j])
    endfor

    " set all tag info
    let tag = {}
    "let tag.file = getbufinfo(a:bufnr)[0].name
    let tag.file = fnamemodify(bufname(a:bufnr), ":p")
    let tag.kind = 'SECTION'
    if title
      let tag.title = block[0].lstr
      let tag.line  = block[1].lnum
      let tag.id    = str2nr(block[1].lstr[:9])
    else
      let tag.title = ""
      let tag.line  = block[0].lnum
      let tag.id    = str2nr(block[0].lstr[:9])
    endif
    call add(tags, tag)

  endfor

  return tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#kw2tag_define(bufnr, lnum, kwSize, single, kind)

  "-----------------------------------------------------------------------------
  " Function to create tag for *DEFINE_ ls-dyna keywords.
  "
  " Arguments:
  " - bufnr (number)   : buffer number with keyword
  " - lnum (number)    : line number with keyword
  " - kwSize (number)  : keyword block size with out title line
  " - single (string)  : single or multi block keyword definition flag
  "                      ''  : multi block definition
  "                      's' : single block definition
  " - kind (string)    : kind for keyword
  " Return:
  " - tags : [{'id'    : 'keyword id or parameter name',
  "            'file'  : 'keyword file',
  "            'line'  : 'keyword line number',
  "            'kind'  : 'keyword kind',
  "            'title' : 'keyword title'}, ..., {}]
  "-----------------------------------------------------------------------------

  " tag dictionary
  let tags = []

  " read all keyword lines
  let lines = lsdyna_tags#readkeyword(a:bufnr, a:lnum)

  " keyword with title ? If yes increase block size by 1 line
  if lines[0].lstr =~? 'TITLE'
    let title = 1
    let size = a:kwSize + 1
  else
    let title = 0
    let size = a:kwSize
  endif

  " loop over all keyword blocks
  for i in range(1, len(lines)-size, size)

    " one loop for single block keyword
    if a:single == 's' && i > 1 | break | endif

    " cut one keyword block
    "let block = lines[i:i+size]
    let block = []
    for j in range(i, i+size-1)
      call add(block, lines[j])
    endfor

    " set all tag info
    let tag = {}
    "let tag.file = getbufinfo(a:bufnr)[0].name
    let tag.file = fnamemodify(bufname(a:bufnr), ":p")
    let tag.kind = a:kind
    if title
      let tag.title = block[0].lstr
      let tag.line  = block[1].lnum
      let tag.id    = str2nr(block[1].lstr[:9])
    else
      let tag.title = ""
      let tag.line  = block[0].lnum
      let tag.id    = str2nr(block[0].lstr[:9])
    endif
    call add(tags, tag)

  endfor

  return tags

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_tags#kw2tag_parameter(bufnr, lnum)

  "-----------------------------------------------------------------------------
  " Function to create tag for *PARAMETER ls-dyna keywords.
  "
  " Arguments:
  " - bufnr (number)   : buffer number with keyword
  " - lnum (number)    : line number with keyword
  " Return:
  " - tags : [{'id'    : 'parameter name',
  "            'file'  : 'keyword file',
  "            'line'  : 'keyword line number',
  "            'kind'  : 'keyword kind',
  "            'title' : 'keyword title'}, ..., {}]
  "-----------------------------------------------------------------------------

  " tag dictionary
  let tags = []

  " read all keyword lines
  let lines = lsdyna_tags#readkeyword(a:bufnr, a:lnum)

  "-----------------------------------------------------------------------------
  " *PARAMETER_EXPRESSION

  if lines[0].lstr =~? 'EXPRESSION'

    " loop over keyword lines
    for line in lines[1:]

      if line.lstr =~? "[IRC]"

        " set tag info
        let tag = {}
        "let tag.file  = getbufinfo(a:bufnr)[0].name
        let tag.file = fnamemodify(bufname(a:bufnr), ":p")
        let tag.kind  = 'PARAMETER'
        let tag.id    = join(split(line.lstr[1:9]))
        let tag.line  = line.lnum
        let tag.title = line.lstr[0] . '_' . join(split(line.lstr[10:]))
        call add(tags, tag)

      endif

    endfor

  "-----------------------------------------------------------------------------
  " *PARAMETER

  else

    " read all keyword lines
    for line in lines[1:]

      " cut line into 20 length strings
      for col in range(0, 80, 20)

        " parameter definition
        let parameter = strpart(line.lstr, col, 20)

        if !empty(parameter)
          " set tag info
          let tag = {}
          "let tag.file  = getbufinfo(a:bufnr)[0].name
          let tag.file = fnamemodify(bufname(a:bufnr), ":p")
          let tag.kind  = 'PARAMETER'
          let tag.id    = join(split(parameter[1:9]))
          let tag.line  = line.lnum
          let tag.title = parameter[0] . '_' . join(split(parameter[10:]))
          call add(tags, tag)
        endif

      endfor

    endfor

  endif

  "-----------------------------------------------------------------------------

  return tags

endfunction

"-------------------------------------EOF---------------------------------------
