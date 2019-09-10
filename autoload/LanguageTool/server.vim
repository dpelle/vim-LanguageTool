" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Dominique Pellé <dominique.pelle@gmail.com>
" Screenshots:  http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_en.png
"               http://dominique.pelle.free.fr/pic/LanguageToolVimPlugin_fr.png
" Last Change:  2019 Sep 09
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

" This file contains all the server stuff and logic.

" This function starts the server
function LanguageTool#server#start(file_path) "{{{1
    let s:languagetool_port = get(g:, 'languagetool_port', 8081)

    " Start the server
    let s:languagetool_job = jobstart('java -cp '
              \ . a:file_path . ' org.languagetool.server.HTTPServer --port '
              \ . s:languagetool_port,
              \ {'on_stdout': function('LanguageTool#server#stdoutHandler')})
endfunction

" This functions stops the server
function LanguageTool#server#stop() "{{{1
    if exists('s:languagetool_job')
        jobstop(s:languagetool_job)
    endif
endfunction


" This functions handles the output of the server, to know when it has started,
" or find errors
function LanguageTool#server#stdoutHandler(job_id, stdout, event) "{{{1
    if string(a:stdout) =~? 'Server started'
        echomsg 'LanguageTool server started'
        let s:lt_server_started = 1
        doautocmd User LanguageToolServerStarted
    endif

    if exists('g:languagetool_debug')
        echomsg join(a:stdout)
    endif
endfunction

" Little util function to handle empty string to url-encode i the request
function s:urlEncodeNotEmpty(string, prefix) " {{{1
    return empty(a:string) ? '' : ' --data-urlencode "'. a:prefix . '=' .a:string.'"'
endfunction

" This function is used to send requests to the server
function! LanguageTool#server#send(method, endpoint, data, callback) "{{{1
    if !exists('s:lt_server_started')
        echoerr 'LanguageTool server not started, please run :LanguageToolSetUp'
        call a:callback({})
    endif

    let l:languagetool_cmd = 'curl -X ' . a:method . ' -s'
                \ . ' --header "Content-Type: application/x-www-form-urlencoded"'
                \ . ' --header "Accept: application/json"'
                \ . a:data
                \ . ' http://localhost:' . s:languagetool_port . '/v2/' . a:endpoint

    " Let json magic happen
    if s:lt_server_started
        let output_str = jobstart(l:languagetool_cmd, {'on_stdout' : function('LanguageTool#server#sendCallback', [a:callback])})
    else
        echomsg 'LanguageTool server offline...'
        call a:callback({})
    endif
endfunction

" This function is the callback for the send function, it calls callback with parsed json
" data as argument
function! LanguageTool#server#sendCallback(callback, job_id, data, event) "{{{1
    if a:event == 'stdout' && !empty(join(a:data))
        call a:callback(json_decode(join(a:data)))
    endif
endfunction

function! LanguageTool#server#send_sync(method, endpoint, data) "{{{1
    if !exists('s:lt_server_started')
        echoerr 'LanguageTool server not started, please run :LanguageToolSetUp'
        return {}
    endif

    let l:tmperror = tempname()

    let l:languagetool_cmd = 'curl -X ' . a:method . ' -s'
                \ . ' --header "Content-Type: application/x-www-form-urlencoded"'
                \ . ' --header "Accept: application/json"'
                \ . a:data
                \ . ' http://localhost:' . s:languagetool_port . '/v2/' . a:endpoint
                \ . ' 2> ' . l:tmperror

    " Let json magic happen
    if s:lt_server_started
        let output_str = system(l:languagetool_cmd)
    else
        echomsg 'LanguageTool server offline...'
        return {}
    endif

    if v:shell_error
        echoerr 'Command [' . l:languagetool_cmd . '] failed with error: ' . v:shell_error
        if filereadable(l:tmperror)
            echoerr string(readfile(l:tmperror))
        endif
        call delete(l:tmperror)
        call LanguageTool#clear()
        return {}
    endif

    call delete(l:tmperror)

    return json_decode(output_str)
endfunction

" This function is used to send data to the server, for now this is sync, but it will get async
" it returns the result as the vim dict corresponding to the json answer of the server
function! LanguageTool#server#check(data, callback) "{{{1
    let l:request = ' --data-urlencode "data={\"annotation\":[' . escape(LanguageTool#preprocess#getProcessedText(a:data.text), '$"\') . ']}"'

    for [l:key, l:value] in items(a:data)
        if l:key !~? '\v(file|text)'
            let l:request .= s:urlEncodeNotEmpty(l:value, l:key)
        endif
    endfor

    call LanguageTool#server#send('POST', 'check', l:request, a:callback)
endfunction

" This funcion gets the supported languages of LanguageTool using the server
function! LanguageTool#server#get() "{{{1
    return LanguageTool#server#send_sync('GET', 'languages', '')
endfunction
