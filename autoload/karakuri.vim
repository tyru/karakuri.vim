scriptencoding utf-8



" kana/vim-submode compatible interface:
"
" * karakuri#current() : String
" * karakuri#restore_options() : Unit
" * karakuri#enter_with(submode : String, modes : Modes, options : Options, lhs : String [, rhs : String]) : Unit
" * karakuri#leave_with(submode : String, modes : Modes, options : Options, lhs : String) : Unit
" * karakuri#map(submode : String, modes : Modes, options : Options, lhs : String, rhs : String) : Unit
" * karakuri#unmap(submode : String, modes : Modes, options : Options, lhs :
" String) : Unit
"
" Modes = String
"   String: each character represents a mode (n, v, o, i, c, s, x, l).
"
" Options = String | Dictionary
"   String: each character represents a option (quoted from help of kana/vim-submode).
"     * b   Same as |:map-<buffer>|.
"     * e   Same as |:map-<expr>|.
"     * r   {rhs} may be remapped.
"     *     If this letter is not included,
"     *     {rhs} will be never remapped.
"     * s   Same as |:map-<silent>|.
"     * u   Same as |:map-<unique>|.
"     * x   After executing {rhs}, leave the
"     *     submode.  This matters only for
"     *     |submode#map()|.
"   Dictionary: each key/value represents a option (quoted from :help maparg()).
"     * "lhs"      The {lhs} of the mapping.
"     * "rhs"      The {rhs} of the mapping as typed.
"     * "silent"   1 for a |:map-silent| mapping, else 0.
"     * "noremap"  1 if the {rhs} of the mapping is not remappable.
"     * "expr"     1 for an expression mapping (|:map-<expr>|).
"     * "buffer"   1 for a buffer local mapping (|:map-local|).
"     * "nowait"   Do not wait for other, longer mappings.
"                  (|:map-<nowait>|).
"     * NOTE: "mode" and "sid" is not supported in karakuri.vim
"


function! karakuri#current() abort
  " TODO
endfunction

function! karakuri#restore_options() abort
  " TODO
endfunction

function! karakuri#enter_with(submode, modes, options, lhs, ...) abort
  let builder = karakuri#builder(a:submode).enter_with()
  let builder = builder.mode(a:modes).option(a:options).lhs(a:lhs)
  if a:0
    let builder = builder.rhs(a:1)
  endif
  call builder.exec()
endfunction

function! karakuri#leave_with(submode, modes, options, lhs) abort
  let builder = karakuri#builder(a:submode).leave_with()
  let builder = builder.mode(a:modes).option(a:options).lhs(a:lhs)
  call builder.exec()
endfunction

function! karakuri#map(submode, modes, options, lhs, rhs) abort
  let builder = karakuri#builder(a:submode).map()
  let builder = builder.mode(a:modes).option(a:options).lhs(a:lhs).rhs(a:rhs)
  call builder.exec()
endfunction

function! karakuri#unmap(submode, modes, options, lhs) abort
  let builder = karakuri#builder(a:submode).unmap()
  let builder = builder.mode(a:modes).option(a:options).lhs(a:lhs).rhs(a:rhs)
  call builder.exec()
endfunction


" The entrance to core logic:
"
" * karakuri#builder(submode : String) : Builder

function! karakuri#builder(submode) abort
  " TODO
endfunction


function! s:SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
let s:SIDP = s:SID()

function! s:method(obj_name, method_name) abort
  let a:scope[a:obj_name][a:method_name] = function('<SNR>' . s:SIDP . '_' . a:obj_name . '_' . a:method_name)
endfunction


" Map interface object:
"
" * MapUI.mode(modes : Modes) : MapUI
" * MapUI.lhs(lhs : String) : MapUI
" * MapUI.rhs(rhs : String) : MapUI
" * MapUI.silent(b : Bool) : MapUI
" * MapUI.expr(b : Bool) : MapUI
" * MapUI.buffer(b : Bool) : MapUI
" * MapUI.nowait(b : Bool) : MapUI
"
" * MapUI.timeout(b : Bool) : MapUI
" * MapUI.timeoutlen(msec : Number) : MapUI
" * MapUI.showmode(b : Bool) : MapUI
" * MapUI.inherit(b : Bool) : MapUI
" * MapUI.keep_leaving_key(b : Bool) : MapUI
" * MapUI.keyseqs_to_leave(keyseqs : List) : MapUI
" * MapUI.always_show_submode(b : Bool) : MapUI
"
" * MapUI.exec() : MapUI

let s:MapUI = {}

function! s:MapUI_mode(modes) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'mode')

function! s:MapUI_lhs(lhs) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'lhs')

function! s:MapUI_rhs(rhs) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'rhs')

function! s:MapUI_silent(b) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'silent')

function! s:MapUI_expr(b) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'expr')

function! s:MapUI_buffer(b) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'buffer')

function! s:MapUI_nowait(b) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'nowait')

function! s:MapUI_timeout(b) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'timeout')

function! s:MapUI_timeoutlen(msec) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'timeoutlen')

function! s:MapUI_showmode(b) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'showmode')

function! s:MapUI_inherit(b) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'inherit')

function! s:MapUI_keep_leaving_key(b) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'keep_leaving_key')

function! s:MapUI_keyseqs_to_leave(keyseqs) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'keyseqs_to_leave')

function! s:MapUI_always_show_submode(b) abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'always_show_submode')

function! s:MapUI_exec() abort dict
  " TODO
endfunction
call s:method(s:, 'MapUI', 'exec')


" Builder object:
"   karakuri#builder() returns this object.
"   This object provides accesses to each object
"   which defines submode mappings.
"
" * Builder.enter_with() : EnterWith
"     EnterWith is a MapUI
" * Builder.leave_with() : LeaveWith
"     LeaveWith is a MapUI
" * Builder.map() : Mapper
"     Mapper is a MapUI
" * Builder.unmap() : Unmapper
"     Unmapper is a MapUI

let s:Builder = {}

function! s:Builder_enter_with() abort dict
  return deepcopy(s:EnterWith)
endfunction
call s:method(s:, 'Builder', 'enter_with')

function! s:Builder_leave_with() abort dict
  return deepcopy(s:LeaveWith)
endfunction
call s:method(s:, 'Builder', 'leave_with')

function! s:Builder_map() abort dict
  return deepcopy(s:Mapper)
endfunction
call s:method(s:, 'Builder', 'map')

function! s:Builder_unmap() abort dict
  return deepcopy(s:Unmapper)
endfunction
call s:method(s:, 'Builder', 'unmap')

let s:EnterWith = s:MapUI
let s:LeaveWith = s:MapUI
let s:Mapper = s:MapUI
let s:Unmapper = s:MapUI


finish

" Simplified processes:
"
" 1. {enter-with-lhs}
" 2. <Plug>karakuri.enter_with_rhs({submode})
" 3. <Plug>karakuri.init({submode})
" 4. <Plug>karakuri.in({submode})
"   4.1. timeout -> Go to "5. <call-fallback-func>"
"   4.2. User types a key {map-lhs}
"     4.2.1. <Plug>karakuri.in({submode}){map-lhs} is defined:
"       4.2.1.1. {map-lhs} is <leave-with-keyseqs> -> Go to "6. Finalization"
"       4.2.1.2. {map-lhs} is not <leave-with-keyseqs>
"         4.2.1.2.1. <Plug>karakuri.map_rhs({submode})
"         4.2.1.2.2. <Plug>karakuri.prompt({submode})
"         4.2.1.2.3. Go to "4. <Plug>karakuri.in({submode})"
"     4.2.2. <Plug>karakuri.in({submode}){map-lhs} is NOT defined:
"       4.2.2.1. Go to "5. <call-fallback-func>"
" 5. <call-fallback-func>
"   5.1. getchar(1) is true ({map-lhs} was typed but not matched)
"     5.1.1. 'keep_leaving_key' is false -> getchar(0)
"     5.1.2. 'inherit' is true -> feedkeys("\<Plug>karakuri.in(winsize)", 'm')
"     5.1.3. Go to "6. Finalization"
"   5.2. getchar(1) is false (timeout)
"     5.2.1. Go to "6. Finalization"
" 6. Finalization
"   6.1. <call-finalize-func>
"   6.2.  Go to parent mode.

" Mapping definitions:
"
" {mode}map {enter-with-lhs} <Plug>karakuri.enter_with_rhs({submode})<Plug>karakuri.init({submode})<Plug>karakuri.in({submode})
" {mode}map <Plug>karakuri.in({submode}){map-lhs} <Plug>karakuri.map_rhs({submode})<Plug>karakuri.prompt({submode})<Plug>karakuri.in({submode})

" {mode}{nore}map {options} <Plug>karakuri.enter_with_rhs({submode}) {enter-with-rhs}
" {mode}{nore}map {options} <Plug>karakuri.map_rhs({submode}) {map-rhs}

" {mode}noremap <expr> <Plug>karakuri.init({submode}) <call-init-func>

" {mode}noremap <expr> <Plug>karakuri.in({submode})<leave-with-keyseqs> <call-finalize-func>
"   or <leave-with-keyseqs> is undefined:
" {mode}noremap <expr> <Plug>karakuri.in({submode})<Esc> <call-finalize-func>

" {mode}noremap <expr> <Plug>karakuri.in({submode}) <call-fallback-func>

" {mode}noremap <expr> <Plug>karakuri.prompt({submode}) <call-prompt-func>



" nnoremap <script> <C-w>> <SID>(winsize-init)<SID>(winsize-mode)>
" nnoremap <script> <C-w>< <SID>(winsize-init)<SID>(winsize-mode)<
" nnoremap <script> <C-w>+ <SID>(winsize-init)<SID>(winsize-mode)+
" nnoremap <script> <C-w>- <SID>(winsize-init)<SID>(winsize-mode)-
" nnoremap <script> <SID>(winsize-mode)> <C-w>><SID>(winsize-prompt)<SID>(winsize-mode)
" nnoremap <script> <SID>(winsize-mode)< <C-w><<SID>(winsize-prompt)<SID>(winsize-mode)
" nnoremap <script> <SID>(winsize-mode)+ <C-w>+<SID>(winsize-prompt)<SID>(winsize-mode)
" nnoremap <script> <SID>(winsize-mode)- <C-w>-<SID>(winsize-prompt)<SID>(winsize-mode)

" 初期化処理
nnoremap <silent> <SID>(winsize-init) :<C-u>call <SID>winsize_init()<CR>

" 終了処理
" <Esc> を明示的に押された場合のみサブモードを終了
nnoremap <silent> <SID>(winsize-mode)<Esc> :<C-u>call <SID>winsize_finalize()<CR>

" フォールバック：サブモードで定義していないマッピングが押された場合の処理
nnoremap <silent> <SID>(winsize-mode)      :<C-u>call <SID>winsize_fallback()<CR>

" プロンプトをコマンドラインに表示
nnoremap <silent> <SID>(winsize-prompt) :<C-u>call <SID>winsize_prompt()<CR>

function! s:winsize_prompt() abort
  redraw
  echohl ModeMsg
  echo '-- Submode: winsize --'
  echohl None
endfunction

" winsize サブモードではタイムアウトなしに設定することにする
function! s:winsize_init() abort
  let s:winsize_options = {}
  let s:winsize_options.timeout = &timeout
  let &timeout = 0
  " let s:winsize_options.timeoutlen = &timeoutlen
  " let &timeoutlen = ...
endfunction

function! s:winsize_finalize() abort
  " サブモードで定義されていないマッピングが押された場合はサブモードを抜けた後に実行しない
  call getchar(0)
  if exists('s:winsize_options')
    let &timeout = get(s:winsize_options, 'timeout', &timeout)
    " let &timeoutlen = get(s:winsize_options, 'timeoutlen', &timeoutlen)
  endif
  " プロンプトをクリア
  echo ' '
  redraw
endfunction

" サブモードで定義していないマッピングが押されたら
" ノーマルモードのマッピングを実行した後サブモードに戻ってくる
function! s:winsize_fallback() abort
  if getchar(1)
    call s:winsize_finalize()
  else
    call feedkeys("\<SNR>" . s:SID() . "_(winsize-mode)", 'm')
  endif
endfunction

function! s:SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
