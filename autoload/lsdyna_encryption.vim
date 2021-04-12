"-------------------------------------BOF---------------------------------------
"
" Vim filetype plugin file
"
" Language:     VIM Script
" Filetype:     LS-Dyna FE solver input file
" Maintainer:   Bartosz Gradzik <bartosz.gradzik@hotmail.com>
" Last Change:  18th July 2019
"
"-------------------------------------------------------------------------------
"
" v1.0.0
"   - initial version
"
"-------------------------------------------------------------------------------

function! lsdyna_encryption#Encrypt(lines)

  "-----------------------------------------------------------------------------
  " Function to encrypt selected lines.
  "
  " Arguments:
  " - a:lines  : list of lines for encryption
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " command used for encryption
  if !exists("g:lsdynaEncryptCommand")
    let g:lsdynaEncryptCommand = "gpg --encrypt --armor --rfc2440 --trust-model always --textmode --cipher-algo AES --compress-algo 0 --recipient LSTC"
  endif

  " create temporary file
  let file = tempname()

  " write lines to temporary file and encrypt it
  call writefile(a:lines, file)
  silent execute 'silent !' . g:lsdynaEncryptCommand . " " . file
  let encrypt_lines = readfile(file.'.asc')

  " remove temporary files
  call delete(file)
  call delete(file.'.asc')

  return encrypt_lines

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_encryption#EncryptLines(line1, line2, ...)

  "-----------------------------------------------------------------------------
  " Function to encrypt selected lines.
  "
  " Arguments:
  " - a:line1  : first line of selection
  " - a:line2  : last line of selection
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  if a:0 == 2
    if a:1 == '--date'
      let vendor_date = a:2
    endif
  endif

  " encrypt selected lines, delete them and write encryption block
  let lines_for_encrypt = getline(a:line1, a:line2)
  if exists('vendor_date')
    let vBlock = ['*VENDOR', 'DATE      ' .. vendor_date]
    let lines_for_encrypt = vBlock + lines_for_encrypt + ['*VENDOR_END']
  endif
  let lines_after_encrypt = lsdyna_encryption#Encrypt(lines_for_encrypt)
  "if exists('vendor_date')
  "  let vBlock = ['$*VENDOR', '$DATE      ' .. vendor_date]
  "  let lines_after_encrypt = vBlock + lines_after_encrypt + ['$*VENDOR_END']
  "endif
  silent execute a:line1.','.a:line2.'delete'
  call append(a:line1-1, lines_after_encrypt)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_encryption#read_rules(path, flag)

  "-----------------------------------------------------------------------------
  " Function to read encryption profile file.
  "
  " Arguments:
  " - path (string) : encryption rule string or profile file
  " - flag (string) : "cmd_arg" : profile read from command argument
  "                   "file"    : profile read from external file
  " Return:
  " - kw_to_encrypt (dict) : encryption rules
  "-----------------------------------------------------------------------------

  " read rules from file or command argument
  if a:flag == "file"
      let lines = readfile(glob(a:path))
  elseif a:flag == "cmd_arg"
      "let lines = [a:path]
      let lines = split(a:path,'\s*,\s*')
  endif

  " build up rules dict
  let kw_to_encrypt = {}
  for line in lines

    " skip comment line
    if line[0] == "#" | continue | endif
    " skip empty line
    if line =~? '^\s*$' | continue | endif

    " unpack encryption rule
    let rule = split(line,'\s*/\s*')
    let rule_len = len(rule)
    if rule_len == 1
      let part = rule[0]
      let mode = "encrypt"
      let string = ""
    elseif rule_len == 2
      let part = rule[0]
      let mode = rule[1]
      let string = ""
    elseif rule_len == 3
      let part = rule[0]
      let mode = rule[1]
      let string = rule[2]
    endif

    " add asteriks if user does not write it in encryption rule
    if part[0] != '*'
      let part = '*' . part
    endif

    " add new encryption rule
    let kw_to_encrypt[tolower(part)] = {'encryption_mode':tolower(mode), 'exclude_string':string}
  endfor

  return kw_to_encrypt

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_encryption#EncryptKeyword(lnum, mode, string, vendor_date)

  "-----------------------------------------------------------------------------
  " Function to encrypt keyword.
  "
  " Arguments:
  " - a:lnum   : keyword first line number
  " - a:mode   : encryption mode
  " - a:string : exclude string
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " do nothing if encryption mode is 'none'
  if a:mode == 'none' | return | endif

  " get kword from line a:lnum
  let kword = lsdyna_parser#Keyword(a:lnum, bufnr('%'), 'fnc')

  " if kword include exclude string skip it
  if a:string != ""
    for line in kword.lines[1:]
      if line =~? a:string | return | endif
    endfor
  endif

  " set first and last line for encryption base on encryption rule
  if a:mode ==? 'encrypt' || a:mode ==? 'encrypt:0'
    let encrypt_lvl = 0
  else
    let encrypt_lvl = str2nr(split(a:mode,'\s*:\s*')[-1])
    if kword.name =~? '_id\|_title\|part'
      let encrypt_lvl += 1
    endif
  endif

  " encrypt keyword and write it back to the file
  call kword.Encrypt(encrypt_lvl, a:vendor_date)
  call kword.Delete()
  call kword.Write(kword.first)

endfunction

"-------------------------------------------------------------------------------

function! lsdyna_encryption#EncryptFile(...)

  "-----------------------------------------------------------------------------
  " Function to encrypt the file base on encryption rules.
  "
  " Arguments:
  " - None
  " Return:
  " - None
  "-----------------------------------------------------------------------------

  " check do I have any arguments
  if a:0 == 0
    echo "LsEncryptFile command error! Required command argument missed."
    return
  endif

  " process arguments
  let vendor_date = ''
  let i = 0
  while i < a:0
    if a:000[i] ==# '--date'
      let vendor_date = a:000[i+1]
      let i += 2
    elseif a:000[i] ==# '--file'
      let kw_to_encrypt = lsdyna_encryption#read_rules(a:000[i+1], "file")
      let i += 2
    else
      let kw_to_encrypt = lsdyna_encryption#read_rules(join(a:000[i:]), "cmd_arg")
      break
    endif
  endwhile

  " avoid more message stop when list of encrypted keywords is long
  let more_old = &more
  setlocal nomore

  " main loop to find all keywords and encrypt them respect to the rules
  call cursor(1,1)
  while 1

    " find keyword for encryption
    let kwName_lnum = search('^*', 'cW')
    if kwName_lnum == 0 || kwName_lnum == line("$") | break | endif
    let kwName = getline(kwName_lnum)

    " find encryption rule for specific keyword
    " reverse sorting is used to check *DEFINE_CURVE before *DEFINE_
    for key in reverse(sort(keys(kw_to_encrypt)))
      if kwName =~ '^' . key
        echo "Encryption" kwName "on line" kwName_lnum
        let encryption_mode = kw_to_encrypt[key]['encryption_mode']
        let exclude_string = kw_to_encrypt[key]['exclude_string']
        call lsdyna_encryption#EncryptKeyword(kwName_lnum, encryption_mode, exclude_string, vendor_date)
        break
      endif
    endfor

    " move to next line so I can search next keyword in the file
    call cursor(kwName_lnum+1, 0)

  endwhile

  " restore more option
  let &more = more_old

endfunction

"-------------------------------------EOF---------------------------------------
