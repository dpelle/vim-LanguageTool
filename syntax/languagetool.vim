" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Dominique Pellé <dominique.pelle@gmail.com>
" Screenshots:  http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png
"               http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png
" Last Change:  2019 Aug 30
" Version:      1.32


syntax match LanguageToolErrorCount /\m^Error:.*$/
syntax match LanguageToolLabel /\v^(Context|Message|Correction|URL):/
" call matchadd('LanguageToolUrl',        '\m^URL:\s*\zs.*')
