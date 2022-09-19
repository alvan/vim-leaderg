let s:cpo_save = &cpo
set cpo&vim

highlight default link LeadergPrompt Constant

if !exists("g:leaderg_root_markers")
    let g:leaderg_root_markers = ['.root', '.git']
endif

if !exists("g:leaderg_default_dirs")
    " cwd,dir,root,filecwd
    let g:leaderg_default_dirs = ['cwd', 'dir', 'root', 'filecwd']
endif

if !exists("g:leaderg_default_file")
    let g:leaderg_default_file = '*'
endif

if !exists("g:leaderg_default_mode")
    let g:leaderg_default_mode = 'dirs'
endif

if !exists("g:leaderg_default_tool")
    let g:leaderg_default_tool = 'grep'
endif

if !exists("g:leaderg_tool_options")
    let g:leaderg_tool_options = {
                \   'rg' : {
                \     'cmdpath' : 'rg',
                \     'defargs' : '--vimgrep',
                \     'expargs' : '-e',
                \     'nulldev' : ''
                \   },
                \   'git' : {
                \     'cmdpath' : 'git',
                \     'defargs' : 'grep --no-color -n',
                \     'expargs' : '-e',
                \     'nulldev' : ''
                \   },
                \   'grep': {
                \     'cmdpath': 'grep',
                \     'defargs': '-s -n -I',
                \     'expargs': '--',
                \     'nulldev': has('win32') ? 'NUL' : '/dev/null'
                \   }
                \ }
endif

" Location of the find utility
if !exists("g:leaderg_utility_find_path")
    let g:leaderg_utility_find_path = 'find'
endif

" The find utility is from the cygwin package or some other find utility.
if !exists("g:leaderg_utility_find_cygwin")
    let g:leaderg_utility_find_cygwin = 0
endif

" The list of directories to skip while searching for a pattern.
if !exists("g:leaderg_utility_find_skip_dirs")
    let g:leaderg_utility_find_skip_dirs = ['.git', 'RCS', 'CVS', 'SCCS']
endif

" The list of files to skip while searching for a pattern.
if !exists("g:leaderg_utility_find_skip_files")
    let g:leaderg_utility_find_skip_files = [
                \ '.DS_Store',
                \ '*~', '*,v', 's.*', '*.swp', '*.swo', '*.pyc',
                \ ]
endif

" Location of the xargs utility
if !exists("g:leaderg_utility_xargs_path")
    let g:leaderg_utility_xargs_path = 'xargs'
endif

" The command-line arguments to supply to the xargs utility
if !exists('g:leaderg_utility_xargs_args')
    let g:leaderg_utility_xargs_args = '-0'
endif

" Define plugin-specific mappings
if !exists("g:leaderg_mapping__cr_")
    let g:leaderg_mapping__cr_ = '<cr>'
endif

if !exists("g:leaderg_mapping_list")
    let g:leaderg_mapping_list = '<c-l>'
endif

if !exists("g:leaderg_mapping_tool")
    let g:leaderg_mapping_tool = '<c-t>'
endif

if !exists("g:leaderg_mapping_dirs")
    let g:leaderg_mapping_dirs = '<c-d>'
endif

if !exists("g:leaderg_mapping_file")
    let g:leaderg_mapping_file = '<c-f>'
endif

if !exists("g:leaderg_mapping_args")
    let g:leaderg_mapping_args = '<c-a>'
endif

" Display a message
func! s:echohl(text) abort
    echohl WarningMsg | echomsg a:text | echohl None
endfunc

" Locate directories
func! s:locate(dirs, skip) abort
    let l:list = split(a:dirs, ',')
    for l:flag in split(a:dirs, ',')
        call add(l:list, remove(l:list, 0))

        let l:path = ''
        if l:flag == 'root'
            for l:mark in g:leaderg_root_markers
                let l:path = finddir(l:mark, expand('%:p:h').';')
                if empty(l:path)
                    let l:path = findfile(l:mark, expand('%:p:h').';')
                endif
                if !empty(l:path)
                    let l:path = fnamemodify(l:path, ':h')
                    break
                endif
            endfor
        elseif l:flag == 'dir'
            let l:path = expand('%:p:h')
        elseif l:flag == 'cwd'
            let l:path = getcwd()
        elseif l:flag == 'filecwd'
            let l:path = expand('%:p:h')
            if stridx(l:path, getcwd()) == 0
                let l:path = ''
            endif
        endif

        if !empty(l:path) && l:path != a:skip
            return [join(l:list, ','), l:path]
        endif
    endfor

    return [a:dirs, '']
endfunc

func! leaderg#prompt(...) abort
    let s:modal = ''

    let l:state = {}
    " quickfix list: add|set
    let l:state.list = a:0 > 0 ? a:1 : 'set'
    let l:state.tool = g:leaderg_default_tool
    let l:state.mode = g:leaderg_default_mode
    let l:state.file = g:leaderg_default_file
    let [l:state.dirs, l:state.path] = s:locate(join(g:leaderg_default_dirs, ','), '')
    let l:state.term = expand('<cword>')
    let l:state.args = ''
    let l:state.text = ''

    return s:prompt(l:state)
endfunc

let s:modal = ''
func! s:switch(modal) abort
    let s:modal = a:modal
    return getcmdline()
endfunc

func! s:prompt(state) abort
    let l:value = ''
    if a:state.mode == 'dirs'
        let l:value = a:state.path
    elseif has_key(a:state, a:state.mode)
        let l:value = a:state[a:state.mode]
    endif

    if s:modal == 'list'
        let a:state.list = a:state.list == 'add' ? 'set' : 'add'
        let l:value = a:state.text

    elseif s:modal == 'tool'
        let l:tools = sort(keys(g:leaderg_tool_options))
        let a:state.tool = get(l:tools, index(l:tools, a:state.tool) + 1, get(l:tools, 0, a:state.tool))
        let l:value = a:state.text

    elseif s:modal == 'dirs'
        if a:state.mode == 'dirs'
            let [a:state.dirs, l:value] = s:locate(a:state.dirs, a:state.text)
        else
            let l:value = a:state.path
        endif
        let a:state.mode = 'dirs'

    elseif s:modal == 'file'
        let l:value = a:state.file
        let a:state.mode = 'file'

    elseif s:modal == 'args'
        let l:value = a:state.args
        let a:state.mode = 'args'

    endif
    let s:modal = ''

    " Store original mappings
    let l:maparg__cr_ = maparg(g:leaderg_mapping__cr_, 'c', '', 1)
    let l:maparg_list = maparg(g:leaderg_mapping_list, 'c', '', 1)
    let l:maparg_tool = maparg(g:leaderg_mapping_tool, 'c', '', 1)
    let l:maparg_dirs = maparg(g:leaderg_mapping_dirs, 'c', '', 1)
    let l:maparg_file = maparg(g:leaderg_mapping_file, 'c', '', 1)
    let l:maparg_args = maparg(g:leaderg_mapping_args, 'c', '', 1)

    " Set plugin-specific mappings
    execute 'cnoremap <silent>' g:leaderg_mapping__cr_ "\<c-\>e\<sid>switch('_cr_')<cr><cr>"
    execute 'cnoremap <silent>' g:leaderg_mapping_list "\<c-\>e\<sid>switch('list')<cr><cr>"
    execute 'cnoremap <silent>' g:leaderg_mapping_tool "\<c-\>e\<sid>switch('tool')<cr><cr>"
    execute 'cnoremap <silent>' g:leaderg_mapping_dirs "\<c-\>e\<sid>switch('dirs')<cr><cr>"
    execute 'cnoremap <silent>' g:leaderg_mapping_file "\<c-\>e\<sid>switch('file')<cr><cr>"
    execute 'cnoremap <silent>' g:leaderg_mapping_args "\<c-\>e\<sid>switch('args')<cr><cr>"

    " Set low timeout for key codes, so <esc> would cancel prompt faster
    let ttimeoutsave = &ttimeout
    let ttimeoutlensave = &ttimeoutlen
    let &ttimeout = 1
    let &ttimeoutlen = 100

    echohl LeadergPrompt
    call inputsave()

    try
        let l:label = a:state.list == 'add' ? '+' : '!'
        let l:label = l:label . 'Leaderg.' . a:state.tool . ' '
        if !empty(a:state.args)
            let l:label = l:label . a:state.args . ' '
        endif

        if a:state.mode == 'term'
            let l:label = l:label .
                        \ fnamemodify(trim(a:state.path, "/\\"), ':t') . '/ ' .
                        \ a:state.file . ' > '
        elseif a:state.mode == 'dirs'
            let l:label = l:label . 'Directory: '
        elseif a:state.mode == 'file'
            let l:label = l:label . 'Filenames: '
        elseif a:state.mode == 'args'
            let l:label = l:label . 'Arguments: '
        endif

        if a:state.mode == 'dirs'
            let l:value = input(l:label, l:value, 'file')
        else
            let l:value = input(l:label, l:value)
        endif
    catch /^Vim:Interrupt$/  " Ctrl-c was pressed
        let s:modal = ''
    finally
        redraw!

        " Restore mappings
        execute 'cunmap' g:leaderg_mapping__cr_
        execute 'cunmap' g:leaderg_mapping_list
        execute 'cunmap' g:leaderg_mapping_tool
        execute 'cunmap' g:leaderg_mapping_dirs
        execute 'cunmap' g:leaderg_mapping_file
        execute 'cunmap' g:leaderg_mapping_args
        call s:reset_map(l:maparg__cr_)
        call s:reset_map(l:maparg_list)
        call s:reset_map(l:maparg_tool)
        call s:reset_map(l:maparg_dirs)
        call s:reset_map(l:maparg_file)
        call s:reset_map(l:maparg_args)

        " Restore original timeout settings for key codes
        let &ttimeout = ttimeoutsave
        let &ttimeoutlen = ttimeoutlensave

        echohl NONE
        call inputrestore()
    endtry

    if s:modal == ''
        return
    endif

    " Store the input text
    let a:state.text = l:value
    if a:state.mode == 'term' && l:value != ''
        let a:state.term = l:value
    endif

    if s:modal == '_cr_'
        let s:modal = ''

        if a:state.mode == 'term'
            if l:value == ''
                return
            endif

            let a:state.term = l:value
            call s:invoke(a:state)
            return

        elseif a:state.mode == 'dirs'
            if l:value == ''
                return
            endif

            let a:state.path = l:value
            let a:state.mode = 'file'

        elseif a:state.mode == 'file'
            let a:state.file = l:value
            let a:state.mode = 'term'

        elseif a:state.mode == 'args'
            let a:state.args = l:value
            let a:state.mode = 'term'

        endif
    endif

    return s:prompt(a:state)
endfunc

func! s:invoke(state) abort
    let l:term = shellescape(a:state.term)
    if l:term == ''
        return
    endif

    let l:path = a:state.path
    if g:leaderg_utility_find_cygwin == 1
        let l:path = substitute(l:path, "\\", "/", 'g')
    endif
    if l:path == ''
        return
    endif
    if !isdirectory(l:path)
        call s:echohl('Error: Directory ' . l:path . " doesn't exist")
        return
    endif

    " To compare against the current directory, convert to full path
    let l:path = fnamemodify(l:path, ':p:h')

    " On MS-Windows, convert the directory name to 8.3 style pathname.
    " Otherwise, using a path with space characters causes problems.
    if has('win32')
        let l:path = fnamemodify(l:path, ':8')
    endif

    let l:file = a:state.file
    if l:file == ''
        return
    endif

    " Character to use to escape special characters before passing to grep.
    let l:find_escape_char = ''
    if !has('win32')
        let l:find_escape_char = '\'
    endif

    let l:find_file_pattern = ''
    for l:find_file_one_pattern in split(l:file, ' ')
        if l:find_file_pattern != ''
            let l:find_file_pattern = l:find_file_pattern . ' -o'
        endif
        let l:find_file_pattern = l:find_file_pattern . ' -name ' .
                    \ shellescape(l:find_file_one_pattern)
    endfor

    let l:find_file_pattern = l:find_escape_char . '(' .
                \ l:find_file_pattern . ' ' . l:find_escape_char . ')'

    let l:find_prune = ''
    if !empty(g:leaderg_utility_find_skip_dirs)
        for l:find_prune_one_dir in g:leaderg_utility_find_skip_dirs
            if l:find_prune != ''
                let l:find_prune = l:find_prune . ' -o'
            endif
            let l:find_prune = l:find_prune . ' -name ' .
                        \ shellescape(l:find_prune_one_dir)
        endfor
        let l:find_prune = '-type d ' . l:find_escape_char . '(' .
                    \ l:find_prune . ' ' . l:find_escape_char . ')' .
                    \ ' -prune -o'
    endif

    let l:find_skip_files = '-type f'
    for l:find_skip_one_file in g:leaderg_utility_find_skip_files
        let l:find_skip_files = l:find_skip_files . ' ! -name ' .
                    \ shellescape(l:find_skip_one_file)
    endfor

    " On MS-Windows, convert the find/xargs program path to 8.3 style path
    let cmd = (has('win32') ? fnamemodify(g:leaderg_utility_find_path, ':8') : g:leaderg_utility_find_path) .
                \ ' "' . l:path . '"'
                \ . ' ' . l:find_prune
                \ . ' ' . l:find_skip_files
                \ . ' ' . l:find_file_pattern
                \ . " -print0 | "
                \ . (has('win32') ? fnamemodify(g:leaderg_utility_xargs_path, ':8') : g:leaderg_utility_xargs_path)
                \ . ' ' . g:leaderg_utility_xargs_args
                \ . ' ' . s:build_cmd(a:state.tool, a:state.args, l:term)

    call s:start_job(a:state, cmd)
endfunc

" Reset mapping
func! s:reset_map(mapping)
    if !empty(a:mapping)
        execute printf('%s %s%s%s%s %s %s',
                    \ (a:mapping.noremap ? 'cnoremap' : 'cmap'),
                    \ (a:mapping.silent  ? '<silent>' : ''    ),
                    \ (a:mapping.buffer  ? '<buffer>' : ''    ),
                    \ (a:mapping.nowait  ? '<nowait>' : ''    ),
                    \ (a:mapping.expr    ? '<expr>'   : ''    ),
                    \  a:mapping.lhs,
                    \  substitute(a:mapping.rhs, '\c<sid>', '<SNR>'.a:mapping.sid.'_', 'g'))
    endif
endfunc

func! s:build_cmd(tool, args, term) abort
    if !has_key(g:leaderg_tool_options, a:tool)
        call s:echohl('Error: Unsupported command tool ' . a:tool)
        return ''
    endif

    let l:path = g:leaderg_tool_options[a:tool].cmdpath
    if has('win32')
        " On MS-Windows, convert the program pathname to 8.3 style pathname.
        " Otherwise, using a path with space characters causes problems.
        let l:path = fnamemodify(l:path, ':8')
    endif

    return l:path . ' ' .
                \ g:leaderg_tool_options[a:tool].defargs .
                \ (a:args != '' ? ' ' . a:args : '') .
                \ (g:leaderg_tool_options[a:tool].expargs != '' ? ' ' . g:leaderg_tool_options[a:tool].expargs : '') .
                \ ' ' . a:term .
                \ (g:leaderg_tool_options[a:tool].nulldev != '' ? ' ' . g:leaderg_tool_options[a:tool].nulldev : '')
endfunc

" Run the command asynchronously
func! s:start_job(state, cmd) abort
    if s:cmd_job isnot 0
        " If the job is already running for some other search, stop it.
        call job_stop(s:cmd_job)
        caddexpr '[Search command interrupted]'
    endif

    let title = '[Search results for ' . a:state.term . ']'

    if a:state.list == 'add'
        caddexpr title . "\n"
    else
        cgetexpr title . "\n"
    endif

    call setqflist([], 'a', {'title' : title})
    " Save the quickfix list id, so that the output can be added to
    " the correct quickfix list
    let l = getqflist({'id' : 0})
    if has_key(l, 'id')
        let qf_id = l.id
    else
        let qf_id = -1
    endif

    let cmd_list = [&shell, &shellcmdflag, a:cmd]
    let s:cmd_job = job_start(cmd_list, {
                \ 'callback' : function('leaderg#cmd_output_cb', [qf_id]),
                \ 'close_cb' : function('leaderg#cmd_close_cb', [qf_id]),
                \ 'exit_cb' : function('leaderg#cmd_exit_cb', [qf_id]),
                \ 'in_io' : 'null'})

    if job_status(s:cmd_job) == 'fail'
        let s:cmd_job = 0
        call s:echohl('Error: Failed to start the command')
        return
    endif

    " Open the quickfix window below the current window
    bel copen
endfunc

let s:cmd_job = 0

" Add output (single line) from a command to the quickfix list
func! leaderg#cmd_output_cb(qf_id, channel, msg) abort
    let job = ch_getjob(a:channel)
    if job_status(job) == 'fail'
        call s:echohl('Error: Job not found in command output callback')
        return
    endif

    let l = getqflist({'id' : a:qf_id})
    if !has_key(l, 'id') || l.id == 0
        " Quickfix list is not present. Stop the search.
        call job_stop(job)
        return
    endif

    call setqflist([], 'a', {'id' : a:qf_id,
                \ 'efm' : '%f:%\\s%#%l:%c:%m,%f:%\s%#%l:%m',
                \ 'lines' : [a:msg]})
endfunc

" Close callback for the command channel. No more output is available.
func! leaderg#cmd_close_cb(qf_id, channel) abort
    let job = ch_getjob(a:channel)
    if job_status(job) == 'fail'
        call s:echohl('Error: Job not found in channel close callback')
        return
    endif
    let emsg = '[Search command exited with status ' . job_info(job).exitval . ']'

    let l = getqflist({'id' : a:qf_id})
    if has_key(l, 'id') && l.id == a:qf_id
        call setqflist([], 'a', {'id' : a:qf_id,
                    \ 'efm' : '%f:%\s%#%l:%m',
                    \ 'lines' : [emsg]})
    endif
endfunc

" Command exit handler
func! leaderg#cmd_exit_cb(qf_id, job, exit_status) abort
    " Process the exit status only if the cmd is not interrupted
    " by another invocation
    if s:cmd_job == a:job
        let s:cmd_job = 0
    endif
endfunc

let &cpo = s:cpo_save
unlet s:cpo_save
