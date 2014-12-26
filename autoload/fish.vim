function! fish#Indent()
    let l:prevlnum = prevnonblank(v:lnum - 1)
    if l:prevlnum ==# 0
        return 0
    endif
    let l:indent = 0
    let l:prevline = getline(l:prevlnum)
    let l:line = getline(v:lnum)

    if l:prevline =~# '\v^\s*%(begin|if|else|while|for|function|case|switch)>'
        let l:indent = &shiftwidth
    endif
    let l:pplnum = prevnonblank(l:prevlnum - 1)
    if l:pplnum ==# 0 || getline(l:pplnum) !~# '\\$'
        " previous line is not a continued line
        if l:prevline =~# '\\$'
            " this line is a first continued line
            let l:indent += &shiftwidth
        endif
    else
        " previous line is a continued line
        if l:prevline !~# '\\$'
            " previous line does not continue
            let l:indent -= &shiftwidth
        endif
    endif
    if l:line =~# '\v^\s*%(case|else|end)>'
        let l:indent -= &shiftwidth
    endif
    return indent(l:prevlnum) + l:indent
endfunction

function! fish#Format()
    if mode() =~# '\v^%(i|R)$'
        return 1
    else
        let l:command = v:lnum.','.(v:lnum+v:count-1).'!fish_indent'
        echo l:command
        execute l:command
    endif
endfunction

function! fish#Fold()
    let l:line = getline(v:lnum)
    if l:line =~# '\v^\s*%(begin|if|while|for|function|switch)>'
        return 'a1'
    elseif l:line =~# '\v^\s*end>'
        return 's1'
    else
        return '='
    end
endfunction

function! fish#Complete(findstart, base)
    if a:findstart
        return getline('.') =~# '\v^\s*$' ? -1 : 0
    else
        if empty(a:base)
            return []
        endif
        let l:results = []
        let l:completions =
                    \ system('fish -c "complete -C'.shellescape(a:base).'"')
        let l:cmd = substitute(a:base, '\v\S+$', '', '')
        for l:line in split(l:completions, '\n')
            let l:tokens = split(l:line, '\t')
            call add(l:results, {'word': l:cmd.l:tokens[0],
                                \'abbr': l:tokens[0],
                                \'menu': get(l:tokens, 1, '')})
        endfor
        return l:results
    endif
endfunction

function! fish#errorformat()
    return '%Afish: %m,%-G%*\\ ^,%-Z%f (line %l):%s'
endfunction
