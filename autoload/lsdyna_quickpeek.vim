" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  30.12.2021
" Version:      1.0.0
"
" History of change:
" v1.0.0
"   - Initial version

"-------------------------------------------------------------------------------

let b:winid_ids = -1
let b:winid_duplicates = -1
"let b:popup_items = []
let b:popup_items_display = []

"-------------------------------------------------------------------------------

function! lsdyna_quickpeek#Quickpeek(what, options) abort

  "-----------------------------------------------------------------------------
  " Quickpeek main function.
  "
  " Arguments:
  " - what (string)     : value to peek
  " - inclFlag (string) : flag to search in include files
  "                       ''  : look only in current buffer
  "                       'i' : look in include files
  " Return:
  " - none
  "-----------------------------------------------------------------------------

  let options = {}
  let options.mode     = get(a:options, 'mode', 'n')
  let options.includes = get(a:options, 'includes', 0)

  "-----------------------------------------------------------------------------
  " charwise visual mode

  if options.mode ==# 'v'

    let pos1 = getpos("'<")
    let pos2 = getpos("'>")
    let expr = getline(pos1[1])[pos1[2]-1:pos2[2]-1]->substitute('[ &<>]','','g')

    " find all *PARAMETER and build global list
    let g:lsdyna_manager_parameters = {}
    let qfid = lsdyna_vimgrep#Vimgrep('parameter', {}) 
    let kwords = getqflist({'id':qfid, 'items':''}).items
    call map(kwords, {_, kword->lsdyna_parser#Keyword({'lnum':kword.lnum, 'bufnr':kword.bufnr})._Parameter()})

    let eval = lsdyna_parameter#Eval(expr)->str2float()->printf('%.4g')
    call cursor(pos2[1], pos2[2])
    call popup_atcursor(eval, #{
         \ border:[],
         \ moved:'any',
         \ filter:'QP_popup_filter_Quit',
         \})

  "-----------------------------------------------------------------------------
  " linewise visual mode

  elseif options.mode ==# 'V'

    let lnum1 = line("'<")
    let lnum2 = line("'>")
    let lines = getline(lnum1,lnum2)

    let kword = lsdyna_parser#Keyword({})

    let g:lsdyna_manager_parameters = {}
    let qfid = lsdyna_vimgrep#Vimgrep('parameter', {}) 
    let kwords = getqflist({'id':qfid, 'items':''}).items
    call map(kwords, {_, kword->lsdyna_parser#Keyword({'lnum':kword.lnum, 'bufnr':kword.bufnr})._Parameter()})

    for i in range(len(lines))

      if lines[i][0] ==? '$'
        continue
      endif

      if lines[i] =~? '[&<>]'
        let kwrow = kword.GetText({'curline':lnum1+i, 'rowlist':'', 'isfreeformat':''})
        let cols = kwrow.rowlist
        for j in range(len(cols))
          if cols[j] =~? '[&<>]'
            let cols[j] = lsdyna_parameter#Eval(cols[j]->substitute('[ &<>]','','g'))
            \             ->str2float()
            \             ->printf('%'..len(cols[j])..'.4g')
          endif
        endfor 
        let lines[i] = kwrow.isfreeformat ? cols->join(',') : cols->join('')
      endif

    endfor

    call s:QP_popup_create(lines, {})

  "-----------------------------------------------------------------------------
  " normal mode

    elseif options.mode ==# 'n'
 
    " if there is only one popup window and it includes *PARAMETER use this
    " parameter value for quickpeek
    if len(popup_list())==1 && b:popup_items_display[0].name=~?'PARAMETER'
      let peekValue = b:popup_items_display[0].peval->str2float()->float2nr()->string()
    " any other call
    else
      if !empty(a:what)
        let peekValue = a:what
      else
        let peekValue = lsdyna_parser#Keyword(line('.'), bufnr('%'), '').GetText({'cword':''}).cword
      endif
    endif

    call popup_clear()

    " there is nothing to do here ... goodbye
    if getline('.')[0] =~? '[*$]' || empty(peekValue)
      return
    endif

    "-----------------------------------------------------------------------------
    " peek keyword id

    if peekValue =~? '^\d\+$'

      " what kword I will be looking for?
      let peekValue = peekValue->str2nr()
      let peekHeader = s:GetHeader()
      let kwordToLook = get(g:lsdynaLibHeaders, peekHeader, 'part set mat section define')
      let b:popup_items = s:MatchKeywords(kwordToLook, peekValue, options.includes)

      " add file line in case I am looking over many includes so I know in which
      " include file the kword is
      if options.includes
        for i in range(len(b:popup_items))
          call insert(b:popup_items[i].lines, '$ FILE: '..fnamemodify(b:popup_items[i].file, ':t'), 0)
        endfor
      endif

      " zero ids found --> show message
      if len(b:popup_items) == 0
        call popup_atcursor('No reference found for '..peekValue, #{
             \ border:[],
             \ moved:'any',
             \ filter:'QP_popup_filter_Quit',
             \})
      " one item found --> display popup window for item in 'b:popup_items'
      elseif len(b:popup_items) == 1
        call QP_popup_display(0,0)
      " many ids found --> display popup menu
      else
        let kword_names = b:popup_items->copy()->map({idx, val->idx+1..'. '..val.name})
        let b:winid_ids = popup_menu(kword_names, #{
             \ callback: 'QP_popup_display',
             \ pos:'topleft',
             \ line:"cursor+1",
             \ col:"cursor",
             \ border:[0,0,0,0],
             \ })
      endif

    "-----------------------------------------------------------------------------
    " peek parameter name
    else

      " parameter name to look
      "let pname = expand("<cword>")
      let b:popup_items = s:MatchKeywords('parameter', peekValue, options.includes)

      " add line with EVAL value
      for i in range(len(b:popup_items))
        let param = b:popup_items[i]
        if param.ptype ==? 'I'
          let peval = param.peval->str2float()->float2nr()->string()
        elseif param.ptype ==? 'R'
          let peval = param.peval->str2float()->printf('%.4g')
        else
          let peval = param.peval
        endif  
        call insert(b:popup_items[i].lines, '$ EVAL: '..peval, 0)
      endfor

      " add file line in case I am looking over many includes 
      if options.includes
        for i in range(len(b:popup_items))
          call insert(b:popup_items[i].lines, '$ FILE: '..fnamemodify(b:popup_items[i].file, ':t'), 0)
        endfor
      endif

      "---------------------------------------------------------------------------
      " display message for no found
      if len(b:popup_items) == 0
        call popup_atcursor('No reference found for '..peekValue, #{
             \ border:[],
             \ moved:'any',
             \ filter:'QP_popup_filter_Quit',
             \})
      else
        " display popup windows for items in 'b:popup_items'
        call QP_popup_display(0,0)
      endif

    endif

  endif

endfunction

"-------------------------------------------------------------------------------

function! QP_popup_display(winid, result) abort

  "-----------------------------------------------------------------------------
  " Callback function for popup menu. Create keyword popup for user selection.
  "-----------------------------------------------------------------------------

  " script callback, not from other popup
  if a:winid == 0
    let b:popup_items_display = b:popup_items

  " kword ids popup menu --> display duplicates of selection
  elseif a:winid == b:winid_ids

    let item_selected = b:popup_items[a:result-1]
    " kword group is kword 1st or 1st & 2nd word in kword name
    " *MAT_ELASTIC -> *MAT
    " *SET_PART_LIST -> *SET_PART
    if item_selected.name =~? '^\(*SET_\)\|\(*DEFINE_\)'
      let kword_group = item_selected.name->split('_')[:1]->join('_')
    else
      let kword_group = item_selected.name->split('_')[0]
    endif
    " find keyword duplicates in the same group
    let b:popup_items_display = b:popup_items->copy()->filter(
    \ {_, val -> val.id==item_selected.id && val.name=~?'^'..kword_group})

  " duplicates popup menu -> display selection only
  elseif a:winid == b:winid_duplicates
    let b:popup_items_display = [b:popup_items[a:result-1]]
  endif

  " create popup windows
  call popup_clear()
  let height = 1
  for kword in b:popup_items_display
    let popup_id = s:QP_popup_create(kword.lines, #{line: 'cursor+'..height})
    let height += popup_getpos(popup_id).height
  endfor

  return popup_id

endfunction

"-------------------------------------------------------------------------------

function! s:QP_popup_create(what, options)

  "-----------------------------------------------------------------------------
  " Function to create lsdyna keyword popup.
  "-----------------------------------------------------------------------------

  " default popup options
  let options = #{
                \ pos:'topleft',
                \ line:"cursor+1",
                \ col:1,
                \ moved:[0,0,0],
                \ minwidth:80,
                \ maxheight:20,
                \ border:[],
                \ title:'QuickPeek',
                \ drag:'1',
                \ close:'button',
                \ resize:1,
                \ padding:[0,1,0,1],
                \ filter:'QP_popup_filter',
                \ filtermode:'n',
                \ }

  " overwrite default options
  for option in keys(a:options)
    let options[option] = a:options[option]
  endfor

  let popup_id = popup_create(a:what, options)
  call win_execute(popup_id, 'setlocal syntax=lsdyna')

  return popup_id

endfunction

"-------------------------------------------------------------------------------

function! QP_popup_filter(winid, key) abort

  "-----------------------------------------------------------------------------
  " Filter function for popup menu.
  " <ESC> : close popup
  " <q>   : quite popup
  " <CR>  : jump to preview keyword
  "-----------------------------------------------------------------------------

  if a:key == "\<CR>"
    if len(b:popup_items_display) == 1
      call popup_clear()
      let bufnr = b:popup_items_display[0].bufnr
      let lnum = b:popup_items_display[0].lnum
      silent execute 'buffer' bufnr
      call cursor(lnum, 0)
    elseif len(b:popup_items_display) > 1
      let popup_text = b:popup_items_display->copy()->map({idx, val->idx+1..'. '..val.name})
      let b:winid_duplicates = popup_menu(popup_text, #{
           \ callback: 'QP_popup_display',
           \ pos:'topleft',
           \ line:"cursor+1",
           \ col:"cursor",
           \ border:[0,0,0,0],
           \ })
    endif
    return 1
  elseif a:key == 'q' || a:key == "\<ESC>"
    call popup_clear()
    return 1
  elseif a:key == 'y'
    let popup_id = popup_list()[0]
    let winID = winbufnr(popup_id)
    let pBuffer = getbufline(winID,1,"$")
    call setreg('+', pBuffer, 'l')
    return 1
  endif
  return 0

endfunction

function! QP_popup_filter_Quit(winid, key) abort
  if a:key == 'q' || a:key == "\<ESC>"
    call popup_clear()
    return 1
  endif
  return 0
endfunction

"-------------------------------------------------------------------------------

function! s:MatchKeywords(kword, id, inclFlag) abort

  "-----------------------------------------------------------------------------
  " Function to match keywords for id or name.
  "
  " Arguments:
  " - kword (string) : keyword name used with vimgrep 'part section mat ...'
  " - id (integer)   : keyword id for search
  " Return:
  " - peekItems (list) : list of kword objects
  "-----------------------------------------------------------------------------

  " look for keywords
  let qfid = lsdyna_vimgrep#Vimgrep(a:kword, #{includes:a:inclFlag})
  let vimgrepList = getqflist({'id':qfid, 'items':0}).items

  " oops ... I found nothing ... goodbye
  if len(vimgrepList) == 0
    return []
  endif

  " parse keywords
  let kwords = []
  for item in vimgrepList
    let kword = lsdyna_parser#Keyword(item.lnum, item.bufnr, '')._Autodetect()
    call extend(kwords, kword)
  endfor

  " look for matching id
  "let peekItems = {}
  let peekItems = []
  for kword in kwords

    " parameter object has no 'id' member
    if !has_key(kword, 'id')
      if kword.pname ==? a:id
        call add(peekItems, kword)
      endif
    " keywords with 'id'
    else
      if kword.id == a:id
        call add(peekItems, kword)
      endif
    endif
  endfor

  return peekItems

endfunction

"-------------------------------------------------------------------------------

function! s:GetHeader() abort

  "-----------------------------------------------------------------------------
  " Function to find keyword header in line above.
  "
  " Arguments:
  " - None
  " Return:
  " - header (string)
  "-----------------------------------------------------------------------------

  let line = getline('.')

  " do nothing if you are in comment line 
  if line[0] == '$'
    return ''
  endif

  " find comment line backward
  let lnum = search('^\$', 'bnW')
  if !lnum
    return ''
  endif

  " return lsdyna column number, starting from 0
  let dynaColNr = float2nr((virtcol(".")-1)/10)*10
  " 10 width line slice
  let fieldVal = getline(lnum)[dynaColNr : dynaColNr+9]
  " clean up header
  let header = tolower(substitute(fieldVal, "[#$:]\\?\\s*", "", "g"))

  return header

endfunction

"-------------------------------------------------------------------------------
