" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Dominique Pellé <dominique.pelle@gmail.com>
" Screenshots:  http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png
"               http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png
" Last Change:  2019 Sep 10
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

" This function is the callback for text checking
function! LanguageTool#check#callback(output) "{{{1
    if empty(a:output)
        return -1
    endif

    call LanguageTool#clear()

    let l:file_content = system('cat ' . expand('%'))
    let l:languagetool_text_winid = exists('*win_getid')
    \                             ? win_getid() : winnr()

    " Loop on all errors in output of LanguageTool and
    " collect information about all errors in list s:errors
    let b:errors = a:output.matches
    let l:index = 0
    for l:error in b:errors

        " There be dragons, this is true blackmagic happening here, we hardpatch offset field of LT
        " {from|to}{x|y} are not provided by LT JSON API, thus we have to compute them
        let l:start_byte_index = byteidxcomp(l:file_content, l:error.offset) + 2 " All errrors are offsetted by 2
        let l:error.fromy = byte2line(l:start_byte_index)
        let l:error.fromx = l:start_byte_index - line2byte(l:error.fromy)
        let l:error.start_byte_idx = l:start_byte_index

        let l:stop_byte_index = byteidxcomp(l:file_content, l:error.offset + l:error.length) + 2
        " Sometimes the error goes too far to the end of the file
        " causing byte2line to give negative values
        if byte2line(l:stop_byte_index) >= 0
            let l:error.toy = byte2line(l:stop_byte_index)
            let l:error.tox = l:stop_byte_index - line2byte(l:error.toy)
        else
            let l:error.toy = line('$')
            let l:error.tox = col([l:error.toy, '$'])
        endif

        let l:error.stop_byte_idx = l:stop_byte_index

        let l:error.source_win = l:languagetool_text_winid
        let l:error.index = l:index
        let l:index = l:index + 1
        let l:error.nr_errors = len(b:errors)
    endfor

    " Also highlight errors in original buffer and populate location list.
    setlocal errorformat=%f:%l:%c:%m
    for l:error in b:errors
        let l:re = LanguageTool#errors#highlightRegex(l:error.fromy, l:error)

        if l:error.rule.id =~# 'HUNSPELL_RULE\|HUNSPELL_NO_SUGGEST_RULE\|MORFOLOGIK_RULE_\|_SPELLING_RULE\|_SPELLER_RULE'
            call matchadd('LanguageToolSpellingError', l:re)
        else
            call matchadd('LanguageToolGrammarError', l:re)
        endif
        laddexpr expand('%') . ':'
        \ . l:error.fromy . ':'  . l:error.fromx . ':'
        \ . l:error.rule.id . ' : ' . l:error.message
    endfor

    doautocmd User LanguageToolCheckDone
    return 0
endfunction
