vim-LanguageTool
----------------

This plugin integrates the LanguageTool grammar checker into Vim.
The current version of LanguageTool can check grammar in many languages.

See the list of supported languages:

* http://www.languagetool.org/languages/

* http://www.languagetool.org/ or more information about LanguageTool.


## Screenshots

English Language

![English
Check](http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png)

French Language

![French check](http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png)


## Usage

* `:LanguageToolCheck`

  To check grammar in current buffer.  This will check for grammar mistakes in
  the current buffer and highlight grammar or spelling errors. It also opens a
  new scratch window with the list of errors with further explanations about each
  error.  Pressing <Enter> in scratch buffer will jump to that error. The
  location list for the buffer being checked is also populated.  So you can use
  location commands such as :lopen to open the location list window, :lne to
  jump to the next error, etc.

* `:LanguageToolClear`

  To remove highlighting of grammar mistakes, close the scratch window
  containing the list of errors, clear and close the location list.

* `:help LanguageTool`

  To get more details on various commands and configuration information.


## Installation instructions

To use this plugin, you need to install the Java LanguageTool program.

### Download LanguageTool

* Official Website

  Download stand-alone version of
  LanguageTool(LanguageTool-\*.zip) from
  [here](http://www.languagetool.org/) using the orange button labeled
  "LanguageTool for standalone for your desktop".

* Nightly build

  Download a nightly build LanguageTool-.\*-snapshot.zip from
  http://www.languagetool.org/download/snapshots/. It contains a more recent
  version than the stable version but it is not as well tested. 

* Git

  Checkout and build the latest LanguageTool from sources in git from https://github.com/languagetool-org/languagetool

```
:help languagetool-installation
```

### Installing vim-LanguageTool

You can use any popular plugin manager according to your convenience.

#### [Vundle](https://github.com/VundleVim/Vundle.vim)

Add the text below to your .vimrc file and save:

```
Plugin 'reedes/vim-pencil'
```

then run the following in Vim:

```
:source %
:PluginInstall
```

## Configuration

After installing LanguageTool, you must specify the location of the file
`languagetool-commandline.jar` in your `$HOME/.vimrc` file.

Example:

```

let
g:languagetool_jar='$HOME/languagetool/languagetool-standalone/target/LanguageTool-3.7-SNAPSHOT/LanguageTool-3.7-SNAPSHOT/languagetool-commandline.jar'

```
