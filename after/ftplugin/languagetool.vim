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

setlocal foldmethod=syntax
let b:undo_ftplugin += "setlocal foldmethod<"

nnoremap <buffer><silent> <CR> :call LanguageTool#errors#jumpToCurrentError()<CR>
nnoremap <buffer><silent> f 
            \ :call LanguageTool#errors#fix(
            \ LanguageTool#errors#errorAtPoint(),
            \ LanguageTool#errors#suggestionAtPoint())<CR>
nnoremap <buffer><silent> ]] :execute LanguageTool#errors#nextSummary()<CR>
nnoremap <buffer><silent> [[ :execute LanguageTool#errors#previousSummary()<CR>

normal zx
