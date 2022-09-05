" -- {{{
"
"          File:  leaderg.vim
"        Author:  Alvan
"   Description:  leaderg project for VIM
"
" -- }}}

" Exit if already loaded
if exists("g:loaded_leaderg") | finish | else | let g:loaded_leaderg = "1" | endif

if v:version < 801
    finish
endif

let s:cpo_save = &cpo
set cpo&vim

nnoremap <leader>g :Leaderg<CR>
command! -nargs=* -complete=file Leaderg
            \ call leaderg#prompt(<f-args>)

" Add the Tools->Search Files menu
if has('gui_running')
    anoremenu <silent> Tools.Search.Leaderg<Tab>:Leaderg
                \ :Leaderg<CR>
endif

let &cpo = s:cpo_save
unlet s:cpo_save
