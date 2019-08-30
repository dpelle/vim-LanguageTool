" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Dominique Pellé <dominique.pelle@gmail.com>
" Screenshots:  http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png
"               http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png
" Last Change:  2019/08/14
" Version:      1.32
"
" Long Description: {{{1
"
" This plugin integrates the LanguageTool grammar checker into Vim.
" Current version of LanguageTool can check grammar in many languages:
" ast, be, br, ca, da, de, el, en, eo, es, fa, fr, gl, is, it, ja, km, lt,
" ml, nl, pl, pt, ro, ru, sk, sl, sv, ta, tl, uk, zh.
"
" See doc/LanguageTool.txt for more details about how to use the
" LanguageTool plugin.
"
" See http://www.languagetool.org/ for more information about LanguageTool.
"
" License: {{{1
"
" The VIM LICENSE applies to LanguageTool.vim plugin
" (see ":help copyright" except use "LanguageTool.vim" instead of "Vim").
"
" }}} 1

" Guess language from 'a:lang' (either 'spelllang' or 'v:lang')
function s:FindLanguage(lang) "{{{1
  " This replaces things like en_gb en-GB as expected by LanguageTool,
  " only for languages that support variants in LanguageTool.
  let l:language = substitute(substitute(a:lang,
  \  '\(\a\{2,3}\)\(_\a\a\)\?.*',
  \  '\=tolower(submatch(1)) . toupper(submatch(2))', ''),
  \  '_', '-', '')

  " All supported languages (with variants) from version LanguageTool.
  let l:supportedLanguages =  {
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
  \  'gl'    : 1,
  \  'is'    : 1,
  \  'it'    : 1,
  \  'ja'    : 1,
  \  'km'    : 1,
  \  'lt'    : 1,
  \  'ml'    : 1,
  \  'nl'    : 1,
  \  'pl'    : 1,
  \  'pt'    : 1,
  \  'pt-BR' : 1,
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

" Set up configuration.
" Returns 0 if success, < 0 in case of error.
function LanguageTool#setup() "{{{1
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
  let s:lt_server_started = get(s:, 'lt_server_started', 0)

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

  let s:languagetool_jar = get(g:, 'languagetool_jar', $HOME . '/languagetool/languagetool-commandline.jar')

  if !filereadable(s:languagetool_jar)
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

  let s:languagetool_server = get(g:, 'languagetool_server', $HOME . '/languagetool/languagetool-server.jar')

  if !filereadable(s:languagetool_server)
    " Hmmm, can't find the server file.  Try again with expand() in case user
    " set it up as: let g:languagetool_server = '$HOME/languagetool-server.jar
    let l:languagetool_server = expand(s:languagetool_server)
    if !filereadable(expand(l:languagetool_server))
      echomsg "LanguageTool cannot be found at: " . s:languagetool_server
      echomsg "You need to install LanguageTool and/or set up g:languagetool_server"
      echomsg "to indicate the location of the languagetool-server.jar file."
      return -1
    endif
    let s:languagetool_server = l:languagetool_server
  endif

  call LanguageTool#server#start(s:languagetool_server)

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
function LanguageTool#check() "{{{1
  if !exists('s:lt_server_started')
        echomsg 'LanguageTool needs to be initialized, call :LanguageToolSetUp'
        return -1
  endif
  call LanguageTool#clear()

  " Using window ID is more reliable than window number.
  " But win_getid() does not exist in old version of Vim.
  let s:languagetool_text_winid = exists('*win_getid')
  \                             ? win_getid() : winnr()
  let l:file_content = system('cat ' . expand('%'))

  let data = {
              \ 'disabledRules' : s:languagetool_disable_rules,
              \ 'enabledRules'  : s:languagetool_enable_rules,
              \ 'disabledCategories' : s:languagetool_disable_categories,
              \ 'enabledCategories' : s:languagetool_enable_categories,
              \ 'language' : s:languagetool_lang,
              \ 'text' : l:file_content
              \ }

  let output = LanguageTool#server#send(data)

  " Loop on all errors in output of LanguageTool and
  " collect information about all errors in list s:errors
  let s:errors = output.matches
  for l:error in s:errors
    " There be dragons, this is true blackmagic happening here, we hardpatch offset field of LT
    " {from|to}{x|y} are not provided by LT JSON API, thus we have to compute them
    let l:start_byte_index = byteidxcomp(l:file_content, l:error.offset) + 2 " All errrors are offsetted by 2
    let l:error.fromy = byte2line(l:start_byte_index)
    let l:error.fromx = l:start_byte_index - line2byte(l:error.fromy)

    let l:stop_byte_index = byteidxcomp(l:file_content, l:error.offset + l:error.length) + 2
    let l:error.toy = byte2line(l:stop_byte_index)
    let l:error.tox = l:stop_byte_index - line2byte(l:error.toy)
  endfor

  " Also highlight errors in original buffer and populate location list.
  setlocal errorformat=%f:%l:%c:%m
  for l:error in s:errors
    let l:re = s:LanguageToolHighlightRegex(l:error.fromy,
    \                                       l:error.context.text,
    \                                       l:error.context.offset,
    \                                       l:error.context.length)
    if l:error.rule.id =~# 'HUNSPELL_RULE\|HUNSPELL_NO_SUGGEST_RULE\|MORFOLOGIK_RULE_\|_SPELLING_RULE\|_SPELLER_RULE'
      call matchadd('LanguageToolSpellingError', l:re)
    else
      call matchadd('LanguageToolGrammarError', l:re)
    endif
    laddexpr expand('%') . ':'
    \ . l:error.fromy . ':'  . l:error.fromx . ':'
    \ . l:error.rule.id . ' : ' . l:error.message
  endfor
  return 0
endfunction

" This function clears syntax highlighting created by LanguageTool plugin
" and removes the scratch window containing grammar errors.
function LanguageTool#clear() "{{{1
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


