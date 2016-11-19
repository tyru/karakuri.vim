" submode.vim compatible interface
call karakuri#enter_with('undo/redo', 'n', '', 'g-', 'g-')
call karakuri#enter_with('undo/redo', 'n', '', 'g+', 'g+')
call karakuri#map('undo/redo', 'n', '', '-', 'g-')
call karakuri#map('undo/redo', 'n', '', '+', 'g+')

" Define mappings of given dictionary
call karakuri#define('undo/redo', {
\ 'enter_with': [
\   {'mode': 'n', 'lhs': 'g-', 'rhs': 'g-'},
\   {'mode': 'n', 'lhs': 'g+', 'rhs': 'g+'}
\ ],
\ 'map': [
\   {'mode': 'n', 'lhs': '-', 'rhs': 'g-'},
\   {'mode': 'n', 'lhs': '+', 'rhs': 'g+'}
\ ]
\})

" Change options
" (v:true/v:false works in Vim 8.0 or higher)
call karakuri#define('undo/redo', {
\ 'keep_leaving_key': v:true,
\ 'always_show_submode': v:true,
\ 'enter_with': [
\   {'mode': 'n', 'lhs': 'g-', 'rhs': 'g-'},
\   {'mode': 'n', 'lhs': 'g+', 'rhs': 'g+'}
\ ],
\ 'map': [
\   {'mode': 'n', 'lhs': '-', 'rhs': 'g-'},
\   {'mode': 'n', 'lhs': '+', 'rhs': 'g+'}
\ ]
\})

" =========================================================
"
" winsize (for test)
"

" submode.vim compatible interface
call karakuri#enter_with('winsize', 'n', '', '<C-w>>', '<C-w>>')
call karakuri#enter_with('winsize', 'n', '', '<C-w><', '<C-w><')
call karakuri#enter_with('winsize', 'n', '', '<C-w>+', '<C-w>+')
call karakuri#enter_with('winsize', 'n', '', '<C-w>-', '<C-w>-')

call karakuri#map('winsize', 'n', '', '>', '<C-w>>')
call karakuri#map('winsize', 'n', '', '<', '<C-w><')
call karakuri#map('winsize', 'n', '', '+', '<C-w>+')
call karakuri#map('winsize', 'n', '', '-', '<C-w>-')

" Define mappings of given dictionary
call karakuri#define('winsize', {
\ 'enter_with': [
\   {'mode': 'n', 'lhs': '<C-w>>', 'rhs': '<C-w>>'},
\   {'mode': 'n', 'lhs': '<C-w><', 'rhs': '<C-w><'},
\   {'mode': 'n', 'lhs': '<C-w>+', 'rhs': '<C-w>+'},
\   {'mode': 'n', 'lhs': '<C-w>-', 'rhs': '<C-w>-'}
\ ],
\ 'map': [
\   {'mode': 'n', 'lhs': '>', 'rhs': '<C-w>>'},
\   {'mode': 'n', 'lhs': '<', 'rhs': '<C-w><'},
\   {'mode': 'n', 'lhs': '+', 'rhs': '<C-w>+'},
\   {'mode': 'n', 'lhs': '-', 'rhs': '<C-w>-'}
\ ]
\})

" Change options
function! s:init_func(ctx) abort
  echom printf('[%s] Initializing...', a:ctx.submode)
endfunction
function! s:prompt_func(ctx) abort
  return printf('[%s] <,>:dec/inc width, -,+:dec/inc height', a:ctx.submode)
endfunction
function! s:timeout_func(ctx) abort
  echom printf('[%s] Timeout!', a:ctx.submode)
endfunction
function! s:finalize_func(ctx) abort
  echom printf('[%s] Finalizing...', a:ctx.submode)
endfunction

call karakuri#define('winsize', {
\ 'keep_leaving_key': v:true,
\ 'always_show_submode': v:true,
\ 'timeout': v:true,
\ 'timeoutlen': 3000,
\ 'on_init': function('s:init_func'),
\ 'on_prompt': function('s:prompt_func'),
\ 'on_timeout': function('s:timeout_func'),
\ 'on_finalize': function('s:finalize_func'),
\ 'enter_with': [
\   {'mode': 'n', 'lhs': '<C-w>>', 'rhs': '<C-w>>'},
\   {'mode': 'n', 'lhs': '<C-w><', 'rhs': '<C-w><'},
\   {'mode': 'n', 'lhs': '<C-w>+', 'rhs': '<C-w>+'},
\   {'mode': 'n', 'lhs': '<C-w>-', 'rhs': '<C-w>-'}
\ ],
\ 'map': [
\   {'mode': 'n', 'lhs': '>', 'rhs': '<C-w>>'},
\   {'mode': 'n', 'lhs': '<', 'rhs': '<C-w><'},
\   {'mode': 'n', 'lhs': '+', 'rhs': '<C-w>+'},
\   {'mode': 'n', 'lhs': '-', 'rhs': '<C-w>-'}
\ ]
\})

" =========================================================
"
" textmanip
"

let s:INVOKE_TEXTMANIP_SUBMODE = '<Leader>tm'

call karakuri#define('textmanip', {
\ 'enter_with': [
\   {'mode': 'n', 'lhs': s:INVOKE_TEXTMANIP_SUBMODE},
\   {'mode': 'x', 'lhs': s:INVOKE_TEXTMANIP_SUBMODE}
\ ],
\ 'map': [
\   {'mode': 'x', 'remap': v:true, 'lhs': 'J', 'rhs': '<Plug>(textmanip-duplicate-down)'},
\   {'mode': 'n', 'remap': v:true, 'lhs': 'J', 'rhs': '<Plug>(textmanip-duplicate-down)'},
\   {'mode': 'x', 'remap': v:true, 'lhs': 'K', 'rhs': '<Plug>(textmanip-duplicate-up)'},
\   {'mode': 'n', 'remap': v:true, 'lhs': 'K', 'rhs': '<Plug>(textmanip-duplicate-up)'},
\   {'mode': 'x', 'remap': v:true, 'lhs': 'j', 'rhs': '<Plug>(textmanip-move-down)'},
\   {'mode': 'x', 'remap': v:true, 'lhs': 'k', 'rhs': '<Plug>(textmanip-move-up)'},
\   {'mode': 'x', 'remap': v:true, 'lhs': 'h', 'rhs': '<Plug>(textmanip-move-left)'},
\   {'mode': 'x', 'remap': v:true, 'lhs': 'l', 'rhs': '<Plug>(textmanip-move-right)'},
\   {'mode': 'n', 'remap': v:true, 'lhs': 't', 'rhs': '<Plug>(textmanip-toggle-mode)'},
\   {'mode': 'x', 'remap': v:true, 'lhs': 't', 'rhs': '<Plug>(textmanip-toggle-mode)'},
\   {'mode': 'x', 'remap': v:true, 'lhs': '<C-j>', 'rhs': '<Plug>(textmanip-move-down-r)'},
\   {'mode': 'x', 'remap': v:true, 'lhs': '<C-k>', 'rhs': '<Plug>(textmanip-move-up-r)'},
\   {'mode': 'x', 'remap': v:true, 'lhs': '<C-h>', 'rhs': '<Plug>(textmanip-move-left-r)'},
\   {'mode': 'x', 'remap': v:true, 'lhs': '<C-l>', 'rhs': '<Plug>(textmanip-move-right-r)'}
\ ]
\})


" =========================================================
"
" winmove
"

let s:INVOKE_WINMOVE_SUBMODE = '<Leader>wm'

call karakuri#define('winmove', {
\ 'enter_with': [
\   {'mode': 'n', 'lhs': s:INVOKE_WINMOVE_SUBMODE}
\ ],
\ 'map': [
\   {'mode': 'n', 'remap': v:true, 'lhs': 'j', 'rhs': '<Plug>(winmove-down)'},
\   {'mode': 'n', 'remap': v:true, 'lhs': 'k', 'rhs': '<Plug>(winmove-up)'},
\   {'mode': 'n', 'remap': v:true, 'lhs': 'h', 'rhs': '<Plug>(winmove-left)'},
\   {'mode': 'n', 'remap': v:true, 'lhs': 'l', 'rhs': '<Plug>(winmove-right)'}
\ ]
\})


