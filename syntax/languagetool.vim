" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Thomas Vigouroux <tomvig38@gmail.com>
" Last Change:  2019 Sep 11
" Version:      1.0
" License: {{{1
"
" The VIM LICENSE applies to LanguageTool.nvim plugin
" (see ":help copyright" except use "LanguageTool.nvim" instead of "Vim").
"
" }}} 1

" Matchs {{{1
syntax match LanguageToolErrorCount /\m^Error:.*$/
syntax match LanguageToolLabel /\v^\s*(Message|Context|Corrections|More|Category|Rule|Subrule):/
" syntax match LanguageToolUrl /\m^URL:\s*\zs.*/

" Regions {{{1
syntax region Normal start="More:" end="^$" keepend fold transparent
