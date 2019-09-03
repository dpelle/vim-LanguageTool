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

" This functions finds the error at point
function! LanguageTool#errors#find() "{{{1
    let line_byte_index = line2byte('.')
    let current_col = col('.')

    let current_byte_idx = line_byte_index + current_col

    for l:error in b:errors
        if error.start_byte_idx <= current_byte_idx && error.stop_byte_idx >= current_byte_idx
            return l:error
        endif
    endfor
    return {}
endfunction

" This functions appends a pretty printed version of current error at the end of the current buffer
function! LanguageTool#errors#prettyprint(error) "{{{1
    call append(line('$'), 'Error:     '
              \ . ' '  . a:error.rule.id . ( !has_key(a:error.rule, 'subId') ? '' : (':' . a:error.rule['subId']))
              \ . ' @ ' . a:error.fromy . 'L ' . a:error.fromx . 'C')
    call append(line('$'), 'Message:    '     . a:error.message)
    call append(line('$'), 'Context:    ' . a:error.context.text)

    call clearmatches()

    let l:re = LanguageTool#errors#highlightRegex(
                \ line('$') - 1,
                \ a:error.context.text,
                \ a:error.context.offset,
                \ a:error.context.length)

    if a:error.rule.id =~# 'HUNSPELL_RULE\|HUNSPELL_NO_SUGGEST_RULE\|MORFOLOGIK_RULE_\|_SPELLING_RULE\|_SPELLER_RULE'
        call matchadd('LanguageToolSpellingError', l:re)
    else
        call matchadd('LanguageToolGrammarError', l:re)
    endif

    if has_key(a:error, 'urls')
        call append(line('$'), 'URL:        ' . a:error.urls[0].value)
    endif
    if has_key(a:error, 'replacements')
        call append(line('$'), 'Corrections:')
        for l:replacement in a:error.replacements
            call append(line('$'), '    ' . l:replacement.value)
        endfor
    endif
endfunction

" Return a regular expression used to highlight a grammatical error
" at line a:line in text.  The error starts at character a:start in
" context a:context and its length in context is a:len.
function! LanguageTool#errors#highlightRegex(line, context, start, len)  "{{{1
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
