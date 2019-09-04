" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Dominique Pellé <dominique.pelle@gmail.com>
" Screenshots:  http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png
"               http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png
" Last Change:  2019 Sep 03
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

" This function is used to know if the language is supported or not by the running languagetool server
function! s:languageIsSupported(lang) "{{{1
    if !exists('s:supported_languages')
        let s:supported_languages = LanguageTool#server#get()
    endif

    for l:language in s:supported_languages
        if a:lang ==? l:language.longCode
            return 1
        endif
    endfor

    return 0
endfunction

" Guess language from 'a:lang' (either 'spelllang' or 'v:lang')
function! LanguageTool#languages#findLanguage(lang) "{{{1
  " This replaces things like en_gb en-GB as expected by LanguageTool,
  " only for languages that support variants in LanguageTool.
  let l:language = substitute(substitute(a:lang,
  \  '\(\a\{2,3}\)\(_\a\a\)\?.*',
  \  '\=tolower(submatch(1)) . toupper(submatch(2))', ''),
  \  '_', '-', '')

  if s:languageIsSupported(l:language)
    return l:language
  endif

  " Removing the region (if any) and trying again.
  let l:language = substitute(l:language, '-.*', '', '')
  return s:languageIsSupported(l:language) ? l:language : ''
endfunction

" This functions prints all languages supported by the server
function! LanguageTool#languages#supportedLanguages() "{{{1

    if !exists('s:supported_languages')
        let s:supported_languages = LanguageTool#server#get()
    endif

    let l:language_list = []

    for l:language in s:supported_languages
        call add(l:language_list, l:language.name . ' [' . l:language.longCode . ']')
    endfor

    echomsg join(l:language_list, ', ')
endfunction
