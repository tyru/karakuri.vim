" submode.vim compatible interface
call karakuri#enter_with('undo/redo', 'n', '', 'g-', 'g-')
call karakuri#enter_with('undo/redo', 'n', '', 'g+', 'g+')
call karakuri#map('undo/redo', 'n', '', '-', 'g-')
call karakuri#map('undo/redo', 'n', '', '+', 'g+')

" Builder interface
let s:unredo = karakuri#builder('undo/redo')
call s:unredo.enter_with().mode('n').lhs('g-').rhs('g-').exec()
call s:unredo.enter_with().mode('n').lhs('g+').rhs('g+').exec()
call s:unredo.map().mode('n').lhs('-').rhs('g-').exec()
call s:unredo.map().mode('n').lhs('+').rhs('g+').exec()

" More fluent builder example
call karakuri#builder('undo/redo')
  \.enter_with().mode('n').lhs('g-').rhs('g-')
  \.enter_with().mode('n').lhs('g+').rhs('g+')
  \.map().mode('n').lhs('-').rhs('g-')
  \.map().mode('n').lhs('+').rhs('g+')
  \.exec()

" Change options
" (v:true/v:false works in Vim 8.0 or higher)
call karakuri#builder('undo/redo')
  \.keep_leaving_key(v:true)
  \.always_show_submode(v:true)
  \.enter_with().mode('n').lhs('g-').rhs('g-')
  \.enter_with().mode('n').lhs('g+').rhs('g+')
  \.map().mode('n').lhs('-').rhs('g-')
  \.map().mode('n').lhs('+').rhs('g+')
  \.exec()

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

" Builder interface
let s:winsize = karakuri#builder('winsize')
call s:winsize.enter_with().mode('n').lhs('<C-w>>').rhs('<C-w>>').exec()
call s:winsize.enter_with().mode('n').lhs('<C-w><').rhs('<C-w><').exec()
call s:winsize.enter_with().mode('n').lhs('<C-w>+').rhs('<C-w>+').exec()
call s:winsize.enter_with().mode('n').lhs('<C-w>-').rhs('<C-w>-').exec()
call s:winsize.map().mode('n').lhs('>').rhs('<C-w>>').exec()
call s:winsize.map().mode('n').lhs('<').rhs('<C-w><').exec()
call s:winsize.map().mode('n').lhs('+').rhs('<C-w>+').exec()
call s:winsize.map().mode('n').lhs('-').rhs('<C-w>-').exec()

" More fluent builder example
call karakuri#builder('winsize')
  \.enter_with().mode('n').lhs('<C-w>>').rhs('<C-w>>')
  \.enter_with().mode('n').lhs('<C-w><').rhs('<C-w><')
  \.enter_with().mode('n').lhs('<C-w>+').rhs('<C-w>+')
  \.enter_with().mode('n').lhs('<C-w>-').rhs('<C-w>-')
  \.map().mode('n').lhs('>').rhs('<C-w>>')
  \.map().mode('n').lhs('<').rhs('<C-w><')
  \.map().mode('n').lhs('+').rhs('<C-w>+')
  \.map().mode('n').lhs('-').rhs('<C-w>-')
  \.exec()

" Change options
function! s:init_func(ctx) abort
  echom printf("[%s] Initializing...", a:ctx.submode)
endfunction
function! s:prompt_func(ctx) abort
  return printf("[%s] <,>:dec/inc width, -,+:dec/inc height", a:ctx.submode)
endfunction
function! s:timeout_func(ctx) abort
  echom printf("[%s] Timeout!", a:ctx.submode)
endfunction
function! s:finalize_func(ctx) abort
  echom printf("[%s] Finalizing...", a:ctx.submode)
endfunction

call karakuri#builder('winsize')
  \.keep_leaving_key(v:true)
  \.always_show_submode(v:true)
  \.on_init(function('s:init_func'))
  \.on_prompt(function('s:prompt_func'))
  \.on_timeout(function('s:timeout_func'))
  \.on_finalize(function('s:finalize_func'))
  \.enter_with().timeout(v:true).timeoutlen(1000).mode('n').lhs('<C-w>>').rhs('<C-w>>')
  \.enter_with().timeout(v:true).timeoutlen(1000).mode('n').lhs('<C-w><').rhs('<C-w><')
  \.enter_with().timeout(v:true).timeoutlen(1000).mode('n').lhs('<C-w>+').rhs('<C-w>+')
  \.enter_with().timeout(v:true).timeoutlen(1000).mode('n').lhs('<C-w>-').rhs('<C-w>-')
  \.map().timeout(v:true).timeoutlen(1000).mode('n').lhs('>').rhs('<C-w>>')
  \.map().timeout(v:true).timeoutlen(1000).mode('n').lhs('<').rhs('<C-w><')
  \.map().timeout(v:true).timeoutlen(1000).mode('n').lhs('+').rhs('<C-w>+')
  \.map().timeout(v:true).timeoutlen(1000).mode('n').lhs('-').rhs('<C-w>-')
  \.exec()

" =========================================================
"
" textmanip
"

let s:INVOKE_TEXTMANIP_SUBMODE = '<Leader>tm'

call karakuri#builder('textmanip')
  \.enter_with().mode('n').lhs(s:INVOKE_TEXTMANIP_SUBMODE).rhs('<Nop>')
  \.enter_with().mode('x').lhs(s:INVOKE_TEXTMANIP_SUBMODE).rhs('<Nop>')
  \.map().mode('x').remap(v:true).lhs('J').rhs('<Plug>(textmanip-duplicate-down)')
  \.map().mode('n').remap(v:true).lhs('J').rhs('<Plug>(textmanip-duplicate-down)')
  \.map().mode('x').remap(v:true).lhs('K').rhs('<Plug>(textmanip-duplicate-up)')
  \.map().mode('n').remap(v:true).lhs('K').rhs('<Plug>(textmanip-duplicate-up)')
  \.map().mode('x').remap(v:true).lhs('j').rhs('<Plug>(textmanip-move-down)')
  \.map().mode('x').remap(v:true).lhs('k').rhs('<Plug>(textmanip-move-up)')
  \.map().mode('x').remap(v:true).lhs('h').rhs('<Plug>(textmanip-move-left)')
  \.map().mode('x').remap(v:true).lhs('l').rhs('<Plug>(textmanip-move-right)')
  \.map().mode('n').remap(v:true).lhs('t').rhs('<Plug>(textmanip-toggle-mode)')
  \.map().mode('x').remap(v:true).lhs('t').rhs('<Plug>(textmanip-toggle-mode)')
  \.map().mode('x').remap(v:true).lhs('<C-j>').rhs('<Plug>(textmanip-move-down-r)')
  \.map().mode('x').remap(v:true).lhs('<C-k>').rhs('<Plug>(textmanip-move-up-r)')
  \.map().mode('x').remap(v:true).lhs('<C-h>').rhs('<Plug>(textmanip-move-left-r)')
  \.map().mode('x').remap(v:true).lhs('<C-l>').rhs('<Plug>(textmanip-move-right-r)')
  \.exec()

" =========================================================
"
" winmove
"

let s:INVOKE_WINMOVE_SUBMODE = '<Leader>wm'

call karakuri#builder('winmove')
  \.enter_with().mode('n').lhs(s:INVOKE_WINMOVE_SUBMODE).rhs('<Nop>')
  \.map().mode('n').remap(v:true).lhs('j').rhs('<Plug>(winmove-down)')
  \.map().mode('n').remap(v:true).lhs('k').rhs('<Plug>(winmove-up)')
  \.map().mode('n').remap(v:true).lhs('h').rhs('<Plug>(winmove-left)')
  \.map().mode('n').remap(v:true).lhs('l').rhs('<Plug>(winmove-right)')
  \.exec()

