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

" This functions shows the error at point in the preview window
function LanguageTool#errors#showErrorAtPoint() "{{{1
    let current_line = line('.')
    let current_col = col('.')

    for l:error in b:errors
        if error.fromy <= current_line && error.toy >=current_line &&
                    \ error.fromx <=current_col && error.tox >= current_col

            " Open preview window and jump to it
            pedit LanguageTool
            wincmd P
            setlocal filetype=languagetool
            setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap nonumber norelativenumber

            call matchadd('LanguageToolErrorCount', '\m^Error:.*$')
            call matchadd('LanguageToolLabel',      '\m^\(Context\|Message\|Corrections\|URL\):')
            call matchadd('LanguageToolUrl',        '\m^URL:\s*\zs.*')

            let l:re =
                        \   '\m\%'  . line('$') . 'l\%9c'
                        \ . '.\{' . (4 + l:error.context.offset) . '}\zs'
                        \ . '.\{' .     (l:error.length) . '}'
            if l:error.rule.id =~# 'HUNSPELL_RULE\|HUNSPELL_NO_SUGGEST_RULE\|MORFOLOGIK_RULE_\|_SPELLING_RULE\|_SPELLER_RULE'
                call matchadd('LanguageToolSpellingError', l:re)
            else
                call matchadd('LanguageToolGrammarError', l:re)
            endif

            call LanguageTool#errors#prettyprint(l:error)

            call execute('0delete')
            " Return to original window
            exe "norm! \<C-W>\<C-P>"
            return
        endif
    endfor
endfunction

" This functions appends a pretty printed version of current error at the end of the current buffer
function LanguageTool#errors#prettyprint(error) "{{{1
    call append(line('$'), 'Error:      '
              \ . ' '  . a:error.rule.id . ( !has_key(a:error.rule, 'subId') ? '' : (':' . a:error.rule['subId']))
              \ . ' @ ' . a:error.fromy . 'L ' . a:error.fromx . 'C')
    call append(line('$'), 'Message:    '     . a:error.message)
    call append(line('$'), 'Context:    ' . a:error.context.text)

    if has_key(a:error, 'replacements')
        call append(line('$'), 'Corrections:')
        for l:replacement in a:error.replacements
            call append(line('$'), '    ' . l:replacement.value)
        endfor
    endif
    if has_key(a:error, 'urls')
        call append(line('$'), 'URL:        ' . a:error.urls[0].value)
    endif
endfunction
