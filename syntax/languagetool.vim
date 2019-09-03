" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Dominique Pellé <dominique.pelle@gmail.com>
" Screenshots:  http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png
"               http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png
" Last Change:  2019 Sep 03
" Version:      1.32
" License: {{{1
"
" The VIM LICENSE applies to LanguageTool.vim plugin
" (see ":help copyright" except use "LanguageTool.vim" instead of "Vim").
"
" }}} 1

" Highligths {{{1
hi def link LanguageToolErrorCount    Title
hi def link LanguageToolLabel         Label
hi def link LanguageToolUrl           Underlined
hi def link LanguageToolGrammarError  Error
hi def link LanguageToolSpellingError WarningMsg

" Matchs {{{1
syntax match LanguageToolErrorCount /\m^Error:.*$/
syntax match LanguageToolLabel /\v^(Context|Message|Corrections|URL):/
syntax match LanguageToolUrl /\m^URL:\s*\zs.*/
