" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Thomas Vigouroux <tomvig38@gmail.com>
" Last Change:  2019 Sep 11
" Version:      1.0
"
" License: {{{1
"
" The VIM LICENSE applies to LanguageTool.nvim plugin
" (see ":help copyright" except use "LanguageTool.nvim" instead of "Vim").
"
" }}} 1

" This function reads the file at file path and returns the preprocessed text
" i.e. with the distinction between markup and real text
" For now it reads the file line by line, apply the rules to be applied and returns the text
" with \n as line separator
function! LanguageTool#preprocess#getProcessedText(lines)
    let l:result = []
    for l:line in a:lines
        let l:result = add(l:result, LanguageTool#preprocess#applyRules(l:line))
    endfor

    return join(l:result, ',')
endfunction

" This function applies the rules to the given line, in order
" If none of them applies, the text is considered as only text
" without markup
" For now this is just a function that return the text, it will
" then be used to differentiate markup and text using rules associated with current
" filetype
function! LanguageTool#preprocess#applyRules(line)
    return '{"text":"' . escape(a:line, "\"\\\t") . '\n"}'
endfunction
