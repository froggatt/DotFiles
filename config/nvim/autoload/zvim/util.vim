scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim
let g:unite_source_menu_menus = get(g:,'unite_source_menu_menus',{})
let g:unite_source_menu_menus.CustomKeyMaps = {'description': 'Custom mapped keyboard shortcuts                   [unite]<SPACE>'}
let g:unite_source_menu_menus.CustomKeyMaps.command_candidates = get(g:unite_source_menu_menus.CustomKeyMaps,'command_candidates', [])
let g:unite_source_menu_menus.MyStarredrepos = {'description': 'All github repos starred by me                   <leader>ls'}
let g:unite_source_menu_menus.MyStarredrepos.command_candidates = get(g:unite_source_menu_menus.MyStarredrepos,'command_candidates', [])
fu! zvim#util#defineMap(type,key,value,desc,...)
    exec a:type . ' ' . a:key . ' ' . a:value
    let description = "➤ "
                \. a:desc
                \. repeat(' ', 80 - len(a:desc) - len(a:key))
                \. a:key
    let cmd = len(a:000) > 0 ? a:000[0] : a:value
    call add(g:unite_source_menu_menus.CustomKeyMaps.command_candidates, [description,cmd])

endf
fu! zvim#util#source_rc(file)
    if filereadable(g:Config_Main_Home. '/' . a:file)
        execute 'source ' . g:Config_Main_Home  . '/' . a:file
    endif
endf

fu! zvim#util#SmartClose()
    let ignorewin = get(g:settings,'smartcloseignorewin',[])
    let ignoreft = get(g:settings,'smartcloseignoreft',[])
    let win_count = winnr('$')
    let num = win_count
    for i in range(1,win_count)
        if index(ignorewin , bufname(winbufnr(i))) != -1 || index(ignoreft, getbufvar(bufname(winbufnr(i)),"&filetype")) != -1
            let num = num - 1
        endif
    endfor
    if num == 1
    else
        close
    endif
endf

"call zvim#util#defineMap('nnoremap <silent>', '<C-c>', ':let @+=expand("%:p")<CR>:echo "Copied to clipboard."<CR>',
            "\ 'Copy buffer absolute path to X11 clipboard',':let @+=expand("%:p")|echo "Copied to clipboard."')
"call zvim#util#defineMap('nnoremap <silent>', '<Leader><C-c>',
            "\ ':let @+="https://github.com/wsdjeg/DotFiles/blob/master/" . expand("%")<CR>:echo "Copied to clipboard."<CR>',
            "\ 'Yank the github link to X11 clipboard',
            "\ ':let @+="https://github.com/wsdjeg/DotFiles/blob/master/" . expand("%")|echo "Copied to clipboard."')

fu! s:findFileInParent(what, where) abort " {{{2
    let old_suffixesadd = &suffixesadd
    let &suffixesadd = ''
    let file = findfile(a:what, escape(a:where, ' ') . ';')
    let &suffixesadd = old_suffixesadd
    return file
endf " }}}2
fu! s:findDirInParent(what, where) abort " {{{2
    let old_suffixesadd = &suffixesadd
    let &suffixesadd = ''
    let dir = finddir(a:what, escape(a:where, ' ') . ';')
    let &suffixesadd = old_suffixesadd
    return dir
endf " }}}2
fu! zvim#util#CopyToClipboard(...)
    if a:0
        if executable('git')
            let repo_home = fnamemodify(s:findDirInParent('.git', expand('%:p')), ':p:h:h')
            if repo_home !=# '' || !isdirectory(repo_home)
                let branch = split(systemlist('git -C '. repo_home. ' branch -a |grep "*"')[0],' ')[1]
                let remotes = filter(systemlist('git -C '. repo_home. ' remote -v'),'match(v:val,"^origin") >= 0 && match(v:val,"fetch") > 0')
                if len(remotes) > 0
                    let remote = remotes[0]
                    if stridx(remote, '@') > -1
                        let repo_url = 'https://github.com/'. split(split(remote,' ')[0],':')[1]
                    else
                        let repo_url = split(remote,' ')[0]
                        let repo_url = strpart(repo_url, stridx(repo_url, 'http'),len(repo_url) - 4 - stridx(repo_url, 'http'))
                    endif
                    let f_url =repo_url. '/blob/'. branch. '/'. strpart(expand('%:p'), len(repo_home) + 1, len(expand('%:p')))
                    let @+=f_url
                    echo "Copied to clipboard"
                else
                    echohl WarningMsg | echom "This git repo has no remote host" | echohl None
                endif
            else
                echohl WarningMsg | echom "This file is not in a git repo" | echohl None
            endif
        else
            echohl WarningMsg | echom "You need install git!" | echohl None
        endif
    else
        let @+=expand("%:p")
        echo "Copied to clipboard"
    endif
endf

fu! zvim#util#check_if_expand_tab()
    let has_noexpandtab = search('^\t','wn')
    let has_expandtab = search('^    ','wn')
    if has_noexpandtab && has_expandtab
        let idx = inputlist ( ['ERROR: current file exists both expand and noexpand TAB, python can only use one of these two mode in one file.\nSelect Tab Expand Type:',
                    \ '1. expand (tab=space, recommended)',
                    \ '2. noexpand (tab=\t, currently have risk)',
                    \ '3. do nothing (I will handle it by myself)'])
        let tab_space = printf('%*s',&tabstop,'')
        if idx == 1
            let has_noexpandtab = 0
            let has_expandtab = 1
            silent exec '%s/\t/' . tab_space . '/g'
        elseif idx == 2
            let has_noexpandtab = 1
            let has_expandtab = 0
            silent exec '%s/' . tab_space . '/\t/g'
        else
            return
        endif
    endif
    if has_noexpandtab == 1 && has_expandtab == 0
        echomsg 'substitute space to TAB...'
        set noexpandtab
        echomsg 'done!'
    elseif has_noexpandtab == 0 && has_expandtab == 1
        echomsg 'substitute TAB to space...'
        set expandtab
        echomsg 'done!'
    else
        " it may be a new file
        " we use original vim setting
    endif
endf

function! zvim#util#BufferEmpty()
    let l:current = bufnr('%')
    if ! getbufvar(l:current, '&modified')
        enew
        silent! execute 'bdelete '.l:current
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo