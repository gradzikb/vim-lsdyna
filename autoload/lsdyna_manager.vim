"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  13.10.2019
"
" History of change:
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_manager#Manager(bang, kword)

  " with bang --> search in all *INCLUDE
  " w/o  bang --> search in current buffer only
  if a:bang
    call lsdyna_vimgrep#Vimgrep(a:kword, '%', 'i')
  else
    call lsdyna_vimgrep#Vimgrep(a:kword, '%', '')
  endif

  " oops ... I found nothing ... goodbye
  if len(getqflist()) == 0
    echo 'No ' . a:kword . ' found.'
    return
  endif

  " parsing keywords change cursor position and I want to stay in place
  " save cursor position
  let save_cursor = getpos(".")
  let save_cursor[0] = bufnr('%')

  " loop over keywords, parser them and next collect quickfix items
  let qflist = []
  for item in getqflist()
    let kwords = lsdyna_parser#Keyword(item.lnum, item.bufnr, 'f')._Kword()
    call extend(qflist, map(kwords, 'v:val.Qf()'))
  endfor

  " retore cursor position
  execute 'noautocmd buffer ' . save_cursor[0]
  call setpos('.', save_cursor)

  " finally open manager
  call lsdyna_manager#Open(qflist)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_manager#format()

  "-----------------------------------------------------------------------------
  " Function to format qf list lines in qf window
  "
  " After split with '|' I got follwoing items.
  " Items above [2] depend on keyword type and qf() function.
  "
  " [0] : file name with kword (VIM) (bufname(qf.bufnr))
  " [1] : line number (VIM) (qf.lnum)
  " [2] : 1st qf.text item
  " [n] : n-2 qf.text item
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  "-----------------------------------------------------------------------------
  " global settings

  setlocal nolist
  setlocal number
  setlocal nowrap
  setlocal statusline=LsManager:\ (F\|f)ilter\ (u)ndo_filter

  nnoremap <buffer><silent> <ESC> :cclose<CR>zz
  nnoremap <buffer><silent> <CR> :cclose<CR>zz
  nnoremap <buffer><silent> <kEnter> :cclose<CR>zz
  nnoremap <buffer><silent> <Home> gg
  nnoremap <buffer><silent> <End> G
  nnoremap <buffer><silent><expr> <Down> line(".") == line("$") ? "gg" : "j"
  nnoremap <buffer><silent><expr> <Up> line(".") == 1 ? "G" : "k"
  nnoremap <buffer><silent><expr> j line(".") == line("$") ? "gg" : "j"
  nnoremap <buffer><silent><expr> k line(".") == 1 ? "G" : "k"
  nnoremap <buffer><silent> f :call <SID>Filter('')<CR>
  nnoremap <buffer><silent> F :call <SID>Filter('r')<CR>
  nnoremap <buffer><silent> u :call <SID>UndoFilter()<CR>

  " in case window is open with no results do not make any formating or a lot
  " of error will be generated
  if empty(getline(1))
    return
  endif

  "-----------------------------------------------------------------------------
  " local settings

  " first loop over all lines to check that all lines requries the same view
  " if not 'kword' will be used
  let view_type_1 = split(getline(1),'\s*|\s*',1)[2]
  let view_type = view_type_1
  for lnum in range(2, line('$'))
    let view_type_2 = split(getline(lnum),'\s*|\s*',1)[2]
    if view_type_1 !=? view_type_2
      let view_type = 'kword'
      break
    else
      let view_type = view_type_2
      let view_type_1 = view_type_2
    endif
  endfor

  "-----------------------------------------------------------------------------
  if view_type ==# 'id_title_type'

    for lnum in range(1, line('$'))
      let qf_text = split(getline(lnum), '|' ,1)
      let id      = printf('%10s', qf_text[5])
      let title   = printf('%-57s', qf_text[6][:56])
      let type    = qf_text[4]
      call setline(lnum, id.' '.title.' | '.type)
    endfor

  "-----------------------------------------------------------------------------
  elseif view_type ==# 'parameter'

    " list of all parameter names used to find duplicates
    let pnames = map(getline(1,line('$')), 'split(v:val, "|", 1)[6]')

    " main loop to format qf window lines
    for lnum in range(1, line('$'))
      let qf_text = split(getline(lnum), '|', 1)
      let ktype   = qf_text[4] =~# 'EXPRESSION' ? 'E' : ' '
      let kscope  = qf_text[4] =~# 'LOCAL' ? 'L' : ' '
      let puniq   = count(pnames, qf_text[6]) > 1 ? 'D' : ' '
      let pflag   = '['.kscope.ktype.puniq.']'
      let ptype   = qf_text[5]
      let pname   = printf('%9s', qf_text[6])
      let pval    = printf('%-55s',qf_text[7][:53])
      call setline(lnum, ptype.' '.pname.' = '.pval.'| '.pflag)
    endfor

  "-----------------------------------------------------------------------------
  elseif view_type ==# 'include'

    setlocal statusline=LsManager:\ (F\|f)ilter\ (u)ndo_filter\ (C)opy\ (D)elete\ (R\|r)ename

    nmap <buffer><silent> <CR> <ESC>gf
    nmap <buffer><silent> <kEnter> <ESC>gf
    nmap <buffer><silent> gf <ESC>gf
    nmap <buffer><silent> gF <ESC>gF
    nmap <buffer><silent> gt <ESC><C-w>gf
    nmap <buffer><silent> gT <ESC><C-w>gf:tabrewind<CR>:LsIncludes<CR>
    nmap <buffer><silent> gd <ESC>gd
    nmap <buffer><silent> gD <ESC>gD
    nmap <buffer><silent> g<C-d> <ESC>g<C-d>

    nnoremap <buffer><silent> C :cclose<CR>:call lsdyna_include#Touch('C')<CR>
    nnoremap <buffer><silent> D :cclose<CR>:call lsdyna_include#Touch('D')<CR>
    nnoremap <buffer><silent> r :cclose<CR>$F.C
    nnoremap <buffer><silent> R :cclose<CR>:call lsdyna_include#Touch('R')<CR>

    " loop to set include file names with level prefix and find lenght of the
    " longes include file name
    let incl_paths = {}
    let incl_names = []
    let max_len_name = 0
    let incl_lvl = -2
    for line in getline(1, line('$'))
      let _line = split(line,'\s*|\s*',1)
      let path = _line[7]
      if !has_key(incl_paths, path) | let incl_paths[path] = incl_lvl + 2 | endif
      let incl_lvl = incl_paths[path]
      let incl_name = repeat(' ', incl_lvl) . _line[5]
      let max_len_name = len(incl_name) > max_len_name ? len(incl_name) : max_len_name
      call add(incl_names, incl_name)
    endfor

    " main loop to format qf window lines
    for lnum in range(1, line('$'))
      let items  = split(getline(lnum),'\s*|\s*',1)
      let ifile  = printf('%-'.max_len_name.'s', incl_names[lnum-1])
      let itype  = items[4]
      let iread  = items[6] == 0 ? 'error' : ''
      call setline(lnum, ifile.' | '.itype.' '.iread)
    endfor

  "-----------------------------------------------------------------------------
  elseif view_type ==# 'kword'

    for lnum in range(1, line('$'))
      let items = split(getline(lnum),'\s*|\s*',1)
      let kword = items[3]
      call setline(lnum, kword)
    endfor

  endif

endfunction

"-------------------------------------------------------------------------------

function! s:Trim(string)
  let string = substitute(a:string,'^\s\+','','')
  let string = substitute(string,'\s\+$','','')
  return string
endfunction

"-------------------------------------------------------------------------------

"function! s:LongestName(lines, position)
"  let max = 0
"  for line in a:lines
"    let line_sp = split(line,'\s*|\s*',1)
"    let title   = line_sp[a:position]
"    let lvl     = count(line_sp[0], '/') " true only for lines with includes, I hope
"    let len     = len(title) + 4*lvl
"    let max     = len > max ? len : max
"  endfor
"  return max
"endfunction

"-------------------------------------------------------------------------------

function! s:Filter(flag)

  "-----------------------------------------------------------------------------
  " Function to filtr lines in qf window.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  let fname=input('Filter: ')

  if empty('fname') | return | endif

  let qflist = getqflist()
  let g:lsdyna_manager_qflist_filter_undo = qflist
  let qfwindow = getline(1, line('$'))
  let qflist_filter = []

  " inclusive filter
  if empty(a:flag)
    for i in range(len(qfwindow))
      if qfwindow[i] =~? fname
        call add(qflist_filter, qflist[i])
      endif
    endfor
  " exclusive filter
  else
    for i in range(len(qfwindow))
      if qfwindow[i] !~? fname
        call add(qflist_filter, qflist[i])
      endif
    endfor
  endif

  let g:lsdyna_manager_qflist_old = qflist_filter
  call lsdyna_manager#Open(qflist_filter)

endfunction

function! s:UndoFilter()

  if exists('g:lsdyna_manager_qflist_filter_undo')
    call lsdyna_manager#Open(g:lsdyna_manager_qflist_filter_undo)
  endif

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_manager#SetPosition()

  "-----------------------------------------------------------------------------
  " Function to set view for selected kword from qf list.
  " Trigged every time cursor change position in qf window.
  " Take line and buffor number for qf list and set this position in other
  " window.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  let qflist = getqflist()

  if empty(qflist)
    return
  endif

  let bufnr = qflist[line(".")-1].bufnr
  let lnum  = qflist[line(".")-1].lnum
  let col   = qflist[line(".")-1].col
  wincmd p
  execute 'buffer ' . bufnr
  "if &filetype != 'lsdyna'
  "  let &filetype='lsdyna'
  "endif
  call cursor(lnum, col)
  if foldclosed(lnum) != -1
    normal! zo
  endif
  normal! zz
  redraw!
  wincmd p

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_manager#Open(qflist)

  "-----------------------------------------------------------------------------
  " Function opens quick fix window.
  " Set two global variables:
  " - g:lsdyna_manager_qflist_old : qf list for any search
  " - g:lsdyna_manager_qflist_includes_old : qf list for includes list only
  " Set cursor position on the list respect to position in file at call time.
  "
  " Arguments:
  " - qflist : list with qf items for setqflist() function
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " default position on the list
  let lnum = line('.')
  let bufnr = bufnr('%')
  let pos_lnum = 1

  if !empty(a:qflist)

    " set position on the list
    let lnum = line('.')
    let bufnr = bufnr('%')
    let min = 1.0e+06
    let i = 1
    for item in a:qflist
      if item.bufnr == bufnr
        let dist = abs(item.lnum-lnum)
        if dist <= min
          let min = dist
          let pos_lnum = i
        endif
      endif
      let i += 1
    endfor

    " save current list
    let g:lsdyna_manager_qflist_old = a:qflist
    if a:qflist[0].text =~? '*include'
      let g:lsdyna_manager_qflist_includes_old = a:qflist
      let g:lsdyna_manager_view = 'include'
    endif

  endif

  " load qf list and reload qf window
  call setqflist(a:qflist)
  cclose
  execute 'copen' max([2, min([30, len(a:qflist)+1])])
  call cursor(pos_lnum, 0)

endfunction

"-------------------------------------EOF---------------------------------------
