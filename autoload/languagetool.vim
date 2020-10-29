" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Dominique Pellé <dominique.pelle@gmail.com>
" Screenshots:  http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png
"               http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png
" Last Change:  2020/10/30

" Guess language from 'a:lang' (either 'spelllang' or 'v:lang')
function s:FindLanguage(lang) "{{{1
  " This replaces things like en_gb en-GB as expected by LanguageTool,
  " only for languages that support variants in LanguageTool.
  let l:language = substitute(substitute(a:lang,
  \  '\(\a\{2,3}\)\(_\a\a\)\?.*',
  \  '\=tolower(submatch(1)) . toupper(submatch(2))', ''),
  \  '_', '-', '')

  " All supported languages (with variants) by LanguageTool.
  let l:supportedLanguages =  {
  \  'ar'    : 1,
  \  'ast'   : 1,
  \  'be'    : 1,
  \  'br'    : 1,
  \  'ca'    : 1,
  \  'cs'    : 1,
  \  'da'    : 1,
  \  'de'    : 1,
  \  'de-AT' : 1,
  \  'de-CH' : 1,
  \  'de-DE' : 1,
  \  'el'    : 1,
  \  'en'    : 1,
  \  'en-AU' : 1,
  \  'en-CA' : 1,
  \  'en-GB' : 1,
  \  'en-NZ' : 1,
  \  'en-US' : 1,
  \  'en-ZA' : 1,
  \  'eo'    : 1,
  \  'es'    : 1,
  \  'fa'    : 1,
  \  'fr'    : 1,
  \  'ga'    : 1,
  \  'gl'    : 1,
  \  'it'    : 1,
  \  'ja'    : 1,
  \  'km'    : 1,
  \  'lt'    : 1,
  \  'nl'    : 1,
  \  'pl'    : 1,
  \  'pt'    : 1,
  \  'pt-AO' : 1,
  \  'pt-BR' : 1,
  \  'pt-MZ' : 1,
  \  'pt-PT' : 1,
  \  'ro'    : 1,
  \  'ru'    : 1,
  \  'sk'    : 1,
  \  'sl'    : 1,
  \  'sv'    : 1,
  \  'ta'    : 1,
  \  'tl'    : 1,
  \  'uk'    : 1,
  \  'zh'    : 1
  \}

  if has_key(l:supportedLanguages, l:language)
    return l:language
  endif

  " Removing the region (if any) and trying again.
  let l:language = substitute(l:language, '-.*', '', '')
  return has_key(l:supportedLanguages, l:language) ? l:language : ''
endfunction

" Return a regular expression used to highlight a grammatical error
" at line a:line in text.  The error starts at character a:start in
" context a:context and its length in context is a:len.
function s:LanguageToolHighlightRegex(line, context, start, len)  "{{{1
  let l:start_idx     = byteidx(a:context, a:start)
  let l:end_idx       = byteidx(a:context, a:start + a:len) - 1
  let l:start_ctx_idx = byteidx(a:context, a:start + a:len)
  let l:end_ctx_idx   = byteidx(a:context, a:start + a:len + 5) - 1

  " The substitute allows matching errors which span multiple lines.
  " The part after \ze gives a bit of context to avoid spurious
  " highlighting when the text of the error is present multiple
  " times in the line.
  return '\V'
  \     . '\%' . a:line . 'l'
  \     . substitute(escape(a:context[l:start_idx : l:end_idx], "'\\"), ' ', '\\_\\s', 'g')
  \     . '\ze'
  \     . substitute(escape(a:context[l:start_ctx_idx : l:end_ctx_idx], "'\\"), ' ', '\\_\\s', 'g')
endfunction

" Unescape XML special characters in a:text.
function s:XmlUnescape(text) "{{{1
  " Change XML escape char such as &quot; into "
  " Substitution of &amp; must be done last or else something
  " like &amp;quot; would get first transformed into &quot;
  " and then wrongly transformed into "  (correct is &quot;)
  let l:escaped = substitute(a:text,    '&quot;', '"',  'g')
  let l:escaped = substitute(l:escaped, '&apos;', "'",  'g')
  let l:escaped = substitute(l:escaped, '&gt;',   '>',  'g')
  let l:escaped = substitute(l:escaped, '&lt;',   '<',  'g')
  let l:escaped = substitute(l:escaped, '&#x9;',  '	', 'g')
  return          substitute(l:escaped, '&amp;',  '\&', 'g')
endfunction

" Parse a xml attribute such as: ruleId="FOO" in line a:line.
" where ruleId is the key a:key, and FOO is the returned value corresponding
" to that key.
function s:ParseKeyValue(key, line) "{{{1
  return s:XmlUnescape(matchstr(a:line, '\<' . a:key . '="\zs[^"]*\ze"'))
endfunction

" Set up configuration.
" Returns 0 if success, < 0 in case of error.
function s:LanguageToolSetUp() "{{{1
  let s:languagetool_disable_rules = exists("g:languagetool_disable_rules")
  \ ? g:languagetool_disable_rules
  \ : 'WHITESPACE_RULE,EN_QUOTES'
  let s:languagetool_enable_rules = exists("g:languagetool_enable_rules")
  \ ? g:languagetool_enable_rules
  \ : ''
  let s:languagetool_disable_categories = exists("g:languagetool_disable_categories")
  \ ? g:languagetool_disable_categories
  \ : ''
  let s:languagetool_enable_categories = exists("g:languagetool_enable_categories")
  \ ? g:languagetool_enable_categories
  \ : ''
  let s:languagetool_win_height = exists("g:languagetool_win_height")
  \ ? g:languagetool_win_height
  \ : 14
  let s:languagetool_encoding = &fenc ? &fenc : &enc

  " Setting up language...
  if exists("g:languagetool_lang")
    let s:languagetool_lang = g:languagetool_lang
  else
    " Trying to guess language from 'spelllang' or 'v:lang'.
    let s:languagetool_lang = s:FindLanguage(&spelllang)
    if s:languagetool_lang == ''
      let s:languagetool_lang = s:FindLanguage(v:lang)
      if s:languagetool_lang == ''
        echoerr 'Failed to guess language from spelllang=['
        \ . &spelllang . '] or from v:lang=[' . v:lang . ']. '
        \ . 'Defauling to English (en-US). '
        \ . 'See ":help LanguageTool" regarding setting g:languagetool_lang.'
        let s:languagetool_lang = 'en-US'
      endif
    endif
  endif

  let s:languagetool_jar = exists("g:languagetool_jar")
  \ ? g:languagetool_jar
  \ : $HOME . '/languagetool/languagetool-commandline.jar'

  if !exists("g:languagetool_cmd") && !filereadable(s:languagetool_jar)
    " Hmmm, can't find the jar file.  Try again with expand() in case user
    " set it up as: let g:languagetool_jar = '$HOME/languagetool-commandline.jar'
    let l:languagetool_jar = expand(s:languagetool_jar)
    if !filereadable(expand(l:languagetool_jar))
      echomsg "LanguageTool cannot be found at: " . s:languagetool_jar
      echomsg "You need to install LanguageTool and/or set up g:languagetool_jar"
      echomsg "to indicate the location of the languagetool-commandline.jar file."
      return -1
    endif
    let s:languagetool_jar = l:languagetool_jar
  endif
  return 0
endfunction

" Jump to a grammar mistake (called when pressing <Enter>
" on a particular error in scratch buffer).
function <sid>JumpToCurrentError() "{{{1
  let l:save_cursor = getpos('.')
  norm! $
  if search('^Error:\s\+', 'beW') > 0
    let l:error_idx = expand('<cword>')
    let l:error = s:errors[l:error_idx - 1]
    let l:line = l:error['fromy']
    let l:col  = l:error['fromx']
    let l:rule = l:error['ruleId']
    call setpos('.', l:save_cursor)
    if exists('*win_gotoid')
      call win_gotoid(s:languagetool_text_winid)
    else
      exe s:languagetool_text_winid . ' wincmd w'
    endif
    exe 'norm! ' . l:line . 'G0'
    if l:col > 0
      exe 'norm! ' . (l:col  - 1) . 'l'
    endif

    echon 'Jump to error ' . l:error_idx . '/' . len(s:errors)
    \ . ' ' . l:rule . ' @ ' . l:line . 'L ' . l:col . 'C'
    norm! zz
  else
    call setpos('.', l:save_cursor)
  endif
endfunction

" This function performs grammar checking of text in the current buffer.
" It highlights grammar mistakes in current buffer and opens a scratch
" window with all errors found.  It also populates the location-list of
" the window with all errors.
" a:line1 and a:line2 parameters are the first and last line number of
" the range of line to check.
" Returns 0 if success, < 0 in case of error.
function languagetool#Check(line1, line2) "{{{1
  if s:LanguageToolSetUp() < 0
    return -1
  endif
  call languagetool#Clear()

  " Using window ID is more reliable than window number.
  " But win_getid() does not exist in old version of Vim.
  let s:languagetool_text_winid = exists('*win_getid')
  \                             ? win_getid() : winnr()
  sil %y
  botright new
  set modifiable
  let s:languagetool_error_buffer = bufnr('%')
  sil put!

  " LanguageTool somehow gives incorrect line/column numbers when
  " reading from stdin so we need to use a temporary file to get
  " correct results.
  let l:tmpfilename = tempname()
  let l:tmperror    = tempname()

  let l:range = a:line1 . ',' . a:line2
  silent exe l:range . 'w!' . l:tmpfilename

  let l:languagetool_cmd = exists("g:languagetool_cmd")
  \ ? g:languagetool_cmd
  \ : 'java -jar ' . s:languagetool_jar

  let l:languagetool_cmd = l:languagetool_cmd
  \ . ' -c '    . s:languagetool_encoding
  \ . (empty(s:languagetool_disable_rules) ? '' : ' -d '.s:languagetool_disable_rules)
  \ . (empty(s:languagetool_enable_rules) ?  '' : ' -e '.s:languagetool_enable_rules)
  \ . (empty(s:languagetool_disable_categories) ? '' : ' --disablecategories '.s:languagetool_disable_categories)
  \ . (empty(s:languagetool_enable_categories) ?  '' : ' --enablecategories '.s:languagetool_enable_categories)
  \ . ' -l '    . s:languagetool_lang
  \ . ' --api ' . l:tmpfilename
  \ . ' 2> '    . l:tmperror

  sil exe '%!' . l:languagetool_cmd
  call delete(l:tmpfilename)

  if v:shell_error
    echoerr 'Command [' . l:languagetool_cmd . '] failed with error: '
    \      . v:shell_error
    if filereadable(l:tmperror)
      echoerr string(readfile(l:tmperror))
    endif
    call delete(l:tmperror)
    call s:LanguageToolClear()
    return -1
  endif
  call delete(l:tmperror)

  " Loop on all errors in XML output of LanguageTool and
  " collect information about all errors in list s:errors
  let s:errors = []
  while search('^<error ', 'eW') > 0
    let l:l = getline('.')
    " The fromx and tox given by LanguageTool are not reliable.
    " They are even sometimes negative!

    let l:error= {}
    for l:k in [ 'fromy', 'fromx', 'tox', 'toy',
    \            'ruleId', 'subId', 'msg', 'replacements',
    \            'context', 'contextoffset', 'errorlength', 'url' ]
      let l:error[l:k] = s:ParseKeyValue(l:k, l:l)
    endfor

    " Make line/column number start at 1 rather than 0.
    " Make also line number absolute as in buffer.
    let l:error['fromy'] += a:line1
    let l:error['fromx'] += 1
    let l:error['toy']   += a:line1
    let l:error['tox']   += 1

    call add(s:errors, l:error)
  endwhile

  if s:languagetool_win_height >= 0
    " Reformat the output of LanguageTool (XML is not human friendly) and
    " set up syntax highlighting in the buffer which shows all errors.
    %d
    call append(0, '# ' . l:languagetool_cmd)
    set bt=nofile
    setlocal nospell
    syn clear
    call matchadd('LanguageToolCmd',        '\%1l.*')
    call matchadd('LanguageToolErrorCount', '^Error:\s\+\d\+/\d\+')
    call matchadd('LanguageToolLabel',      '^\(Context\|Message\|Correction\|URL\):')
    call matchadd('LanguageToolUrl',        '^URL:\s*\zs.*')

    let l:i = 1
    for l:error in s:errors
      call append('$', 'Error:      '
      \ . l:i . '/' . len(s:errors)
      \ . ' '  . l:error['ruleId'] . ((len(l:error['subId']) ==  0) ? '' : ':') . l:error['subId']
      \ . ' @ ' . l:error['fromy'] . 'L ' . l:error['fromx'] . 'C')
      call append('$', 'Message:    '     . l:error['msg'])
      call append('$', 'Context:    ' . l:error['context'])
      let l:re =
      \   '\%'  . line('$') . 'l\%9c'
      \ . '.\{' . (4 + l:error['contextoffset']) . '}\zs'
      \ . '.\{' .     (l:error['errorlength']) . '}'
      if l:error['ruleId'] =~# 'HUNSPELL_RULE\|HUNSPELL_NO_SUGGEST_RULE\|MORFOLOGIK_RULE_\|_SPELLING_RULE\|_SPELLER_RULE'
        call matchadd('LanguageToolSpellingError', l:re)
      else
        call matchadd('LanguageToolGrammarError', l:re)
      endif
      if !empty(l:error['replacements'])
        call append('$', 'Correction: ' . l:error['replacements'])
      endif
      if !empty(l:error['url'])
        call append('$', 'URL:        ' . l:error['url'])
      endif
      call append('$', '')
      let l:i += 1
    endfor
    exe "norm! z" . s:languagetool_win_height . "\<CR>"
    0
    map <silent> <buffer> <CR> :call <sid>JumpToCurrentError()<CR>
    redraw
    echon 'Press <Enter> on error in scratch buffer to jump its location'
    exe "norm! \<C-W>\<C-P>"
  else
    " Negative s:languagetool_win_height -> no scratch window.
    bd!
    unlet! s:languagetool_error_buffer
  endif

  " Also highlight errors in original buffer and populate location list.
  setlocal errorformat=%f:%l:%c:%m
  for l:error in s:errors
    let l:re = s:LanguageToolHighlightRegex(l:error['fromy'],
    \                                       l:error['context'],
    \                                       l:error['contextoffset'],
    \                                       l:error['errorlength'])
    if l:error['ruleId'] =~# 'HUNSPELL_RULE\|HUNSPELL_NO_SUGGEST_RULE\|MORFOLOGIK_RULE_\|_SPELLING_RULE\|_SPELLER_RULE'
      call matchadd('LanguageToolSpellingError', l:re)
    else
      call matchadd('LanguageToolGrammarError', l:re)
    endif
    laddexpr expand('%') . ':'
    \ . l:error['fromy'] . ':'  . l:error['fromx'] . ':'
    \ . l:error['ruleId'] . ' ' . l:error['msg']
  endfor
  return 0
endfunction

" This function clears syntax highlighting created by LanguageTool plugin
" and removes the scratch window containing grammar errors.
function languagetool#Clear() "{{{1
  if exists('s:languagetool_error_buffer')
    if bufexists(s:languagetool_error_buffer)
      sil! exe "bd! " . s:languagetool_error_buffer
    endif
  endif
  if exists('s:languagetool_text_winid')
    let l:win = winnr()
    " Using window ID is more reliable than window number.
    " But win_getid() does not exist in old version of Vim.
    if exists('*win_gotoid')
      call win_gotoid(s:languagetool_text_winid)
    else
      exe s:languagetool_text_winid . ' wincmd w'
    endif
    call setmatches(filter(getmatches(), 'v:val["group"] !~# "LanguageTool.*Error"'))
    lexpr ''
    lclose
    exe l:win . ' wincmd w'
  endif
  unlet! s:languagetool_error_buffer
  unlet! s:languagetool_text_winid
endfunction
