scriptencoding utf-8


let s:TYPE_NUMBER = 0
let s:TYPE_STRING = 1
let s:TYPE_FUNCREF = 2
let s:TYPE_LIST = 3
let s:TYPE_DICT = 4
let s:TYPE_FLOAT = 5
if v:version >== 800
  let s:TYPE_BOOLEAN = 6
  let s:TYPE_NONE = 7
  let s:TYPE_JOB = 8
  let s:TYPE_CHANNEL = 9
endif
let s:TYPE_OF = []
let s:TYPE_OF[0] = 'Number'
let s:TYPE_OF[1] = 'String'
let s:TYPE_OF[2] = 'Funcref'
let s:TYPE_OF[3] = 'List'
let s:TYPE_OF[4] = 'Dictionary'
let s:TYPE_OF[5] = 'Float'
if v:version >== 800
  let s:TYPE_OF[6] = 'Boolean'
  let s:TYPE_OF[7] = 'None'
  let s:TYPE_OF[8] = 'Job'
  let s:TYPE_OF[9] = 'Channel'
endif

function! s:validate(submode, value, type) abort
  let given_type = type(a:value)
  if given_type isnot a:type
    call s:throw(a:submode,
    \ 'Expected ' . s:TYPE_OF[a:type] . ' value but got ' .
    \ s:TYPE_OF[given_type] . ' value.'
    \)
  endif
endfunction

function! s:throw(submode, msg) abort
  throw 'karakuri: ' . a:submode . ': ' . a:msg
endfunction

function! s:SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
let s:SIDP = s:SID()

function! s:method(obj_name, method_name) abort
  let a:scope[a:obj_name][a:method_name] = function('<SNR>' . s:SIDP . '_' . a:obj_name . '_' . a:method_name)
endfunction



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
" Options = String
"   String: each character represents a option (quoted from help of kana/vim-submode).
"     * b   Same as |:map-<buffer>|.
"     * e   Same as |:map-<expr>|.
"     * r   {rhs} may be remapped.
"     *     If this letter is not included,
"     *     {rhs} will be never remapped.
"     * s   Same as |:map-<silent>|.
"     * u   Same as |:map-<unique>|.
"     * x   After executing {rhs}, leave the
"           submode.  This matters only for
"           |submode#map()|.
"       * NOTE: Also in karakuri.vim, this option is supported but you can use
"         Builder.keep_leaving_key(v:true)
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
"

function! karakuri#builder(submode) abort
  let builder = deepcopy(s:Builder)
  let Builder._submode = a:submode
  return builder
endfunction


" Map interface object:
"
" Properties:
"   * _submode: submode
"   * _local: {<same property keys as method names> ...}
"   * _prototype: {<same property keys as method names> ...}
"
" Methods:
"   * MapUI.mode(modes : Modes) : MapUI
"   * MapUI.lhs(lhs : String) : MapUI
"   * MapUI.rhs(rhs : String) : MapUI
"   * MapUI.silent(b : Bool) : MapUI
"   * MapUI.noremap(b : Bool) : MapUI
"   * MapUI.expr(b : Bool) : MapUI
"   * MapUI.buffer(b : Bool) : MapUI
"   * MapUI.nowait(b : Bool) : MapUI
"
"   * MapUI.timeout(b : Bool) : MapUI
"   * MapUI.timeoutlen(msec : Number) : MapUI
"   * MapUI.showmode(b : Bool) : MapUI
"   * MapUI.inherit(b : Bool) : MapUI
"   * MapUI.keep_leaving_key(b : Bool) : MapUI
"   * MapUI.keyseqs_to_leave(keyseqs : List) : MapUI
"   * MapUI.always_show_submode(b : Bool) : MapUI
"
"   * MapUI.exec() : MapUI
"

let s:MAP_UI_DEFAULT_OPTIONS = {
\ 'silent': 0,
\ 'noremap': 1,
\ 'expr': 0,
\ 'buffer': 0,
\ 'nowait': 0,
\ 'timeout': 1,
\ 'timeoutlen': 1000,
\ 'showmode': 1,
\ 'inherit': 0,
\ 'keep_leaving_key': 0,
\ 'keyseqs_to_leave': ['<Esc>'],
\ 'always_show_submode': 0
\}

function! s:MapUI_new(builder, ...) abort
  let ui = deepcopy(s:MapUI)
  let ui._submode = a:builder._submode
  let ui._local = {}
  if a:0 && type(a:1) is s:TYPE_DICT
  \ && has_key(a:1, 'prototype') && type(a:1.prototype) is s:TYPE_DICT
    let ui._prototype = a:1.prototype
  else
    let ui._prototype = {}
  endif
  return ui
endfunction

function! s:MapUI_get(this, key) abort
  return has_key(a:this._local, a:key) ? a:this._local[a:key] :
  \       has_key(a:this._prototype, a:key) ? a:this._prototype[a:key] :
  \       has_key(s:MAP_UI_DEFAULT_OPTIONS, a:key) ? s:MAP_UI_DEFAULT_OPTIONS[a:key] :
  \       s:throw(a:this._submode, "Required key '" . a:key . "' was not given.")
endfunction


let s:MapUI = {}

function! s:MapUI_mode(modes) abort dict
  call s:validate(self._submode, a:modes, s:TYPE_STRING)
  let pos = match(a:modes, '[^nvoicsxl]')
  if pos isnot -1
    call s:throw(self._submode, "Invalid character '" . a:modes[pos] . "' in the argument of .mode().")
  endif
  let self._local.modes = a:modes
endfunction
call s:method(s:, 'MapUI', 'mode')

function! s:MapUI_lhs(lhs) abort dict
  call s:validate(self._submode, a:lhs, s:TYPE_STRING)
  let self._local.lhs = a:lhs
endfunction
call s:method(s:, 'MapUI', 'lhs')

function! s:MapUI_rhs(rhs) abort dict
  call s:validate(self._submode, a:rhs, s:TYPE_STRING)
  let self._local.rhs = a:rhs
endfunction
call s:method(s:, 'MapUI', 'rhs')

function! s:MapUI_silent(b) abort dict
  let self._local.silent = !!a:b
endfunction
call s:method(s:, 'MapUI', 'silent')

function! s:MapUI_noremap(b) abort dict
  let self._local.noremap = !!a:b
endfunction
call s:method(s:, 'MapUI', 'noremap')

function! s:MapUI_expr(b) abort dict
  let self._local.expr = !!a:b
endfunction
call s:method(s:, 'MapUI', 'expr')

function! s:MapUI_buffer(b) abort dict
  let self._local.buffer = !!a:b
endfunction
call s:method(s:, 'MapUI', 'buffer')

function! s:MapUI_nowait(b) abort dict
  let self._local.nowait = !!a:b
endfunction
call s:method(s:, 'MapUI', 'nowait')

function! s:MapUI_timeout(b) abort dict
  let self._local.timeout = !!a:b
endfunction
call s:method(s:, 'MapUI', 'timeout')

function! s:MapUI_timeoutlen(msec) abort dict
  call s:validate(self._submode, a:msec, s:TYPE_NUMBER)
  let self._local.timeoutlen = !!a:b
endfunction
call s:method(s:, 'MapUI', 'timeoutlen')

function! s:MapUI_showmode(b) abort dict
  let self._local.showmode = !!a:b
endfunction
call s:method(s:, 'MapUI', 'showmode')

function! s:MapUI_inherit(b) abort dict
  let self._local.inherit = !!a:b
endfunction
call s:method(s:, 'MapUI', 'inherit')

function! s:MapUI_keep_leaving_key(b) abort dict
  let self._local.keep_leaving_key = !!a:b
endfunction
call s:method(s:, 'MapUI', 'keep_leaving_key')

function! s:MapUI_keyseqs_to_leave(keyseqs) abort dict
  call s:validate(self._submode, a:keyseqs, s:TYPE_LIST)
  let self._local.keyseqs_to_leave = a:keyseqs
endfunction
call s:method(s:, 'MapUI', 'keyseqs_to_leave')

function! s:MapUI_always_show_submode(b) abort dict
  let self._local.always_show_submode = !!a:b
endfunction
call s:method(s:, 'MapUI', 'always_show_submode')

function! s:MapUI_exec() abort dict
  let modes = s:MapUI_get(self, 'modes')
  let mapcmd = (s:MapUI_get(self, 'noremap') ? 'noremap' : 'map')
  let args = []
  if s:MapUI_get(self, 'silent')
    let args += ['<silent>']
  endif
  if s:MapUI_get(self, 'expr')
    let args += ['<expr>']
  endif
  if s:MapUI_get(self, 'buffer')
    let args += ['<buffer>']
  endif
  if s:MapUI_get(self, 'nowait')
    let args += ['<nowait>']
  endif
  let args += [s:MapUI_get(self, 'lhs'), s:MapUI_get(self, 'rhs')]
  for mode in split(modes, '\zs')
    execute join([mode . mapcmd] + args)
  endfor
endfunction
call s:method(s:, 'MapUI', 'exec')


" Builder object:
"   karakuri#builder() returns this object.
"   This object provides accesses to each object
"   which defines submode mappings.
"
" Properties:
"   * _submode: submode
"
" Methods:
"   * Builder.enter_with(options : Dictionary) : EnterWith
"       EnterWith is a MapUI
"   * Builder.leave_with(options : Dictionary) : LeaveWith
"       LeaveWith is a MapUI
"   * Builder.map(options : Dictionary) : Mapper
"       Mapper is a MapUI
"   * Builder.unmap(options : Dictionary) : Unmapper
"       Unmapper is a MapUI
"

let s:Builder = {}

function! s:Builder_enter_with(...) abort dict
  return call('s:MapUI_new', [self] + a:000)
endfunction
call s:method(s:, 'Builder', 'enter_with')

function! s:Builder_leave_with(...) abort dict
  return call('s:MapUI_new', [self] + a:000)
endfunction
call s:method(s:, 'Builder', 'leave_with')

function! s:Builder_map(...) abort dict
  return call('s:MapUI_new', [self] + a:000)
endfunction
call s:method(s:, 'Builder', 'map')

function! s:Builder_unmap(...) abort dict
  return call('s:MapUI_new', [self] + a:000)
endfunction
call s:method(s:, 'Builder', 'unmap')


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
" enter_with() defines:
"   * {mode}map {enter-with-lhs} <Plug>karakuri.enter_with_rhs({submode})<Plug>karakuri.init({submode})<Plug>karakuri.in({submode})
"   * {mode}{nore}map {options} <Plug>karakuri.enter_with_rhs({submode}) {enter-with-rhs}
" If leave_with() is not called yet:
"   * {mode}noremap <expr> <Plug>karakuri.in({submode})<Esc> <call-finalize-func>
"
" map() defines:
"   * {mode}map <Plug>karakuri.in({submode}){map-lhs} <Plug>karakuri.map_rhs({submode})<Plug>karakuri.prompt({submode})<Plug>karakuri.in({submode})
"   * {mode}{nore}map {options} <Plug>karakuri.map_rhs({submode}) {map-rhs}
" If leave_with() is not called yet:
"   * {mode}noremap <expr> <Plug>karakuri.in({submode})<leave-with-keyseqs> <call-finalize-func>

" leave_with() defines:
"   * {mode}noremap <expr> <Plug>karakuri.in({submode})<leave-with-rhs> <call-finalize-func>
" leave_with() undefines (if it was defined):
"   * {mode}noremap <expr> <Plug>karakuri.in({submode})<leave-with-keyseqs>
"
" When one of above methods is called at first, it defines:
"   * {mode}noremap <expr> <Plug>karakuri.init({submode}) <call-init-func>
"   * {mode}noremap <expr> <Plug>karakuri.in({submode}) <call-fallback-func>
"   * {mode}noremap <expr> <Plug>karakuri.prompt({submode}) <call-prompt-func>



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


" ============= Examples =============

" submode.vim compatible interface
call karakuri#enter_with('winsize', 'n', '', '<C-w>>', '<C-w>>')
call karakuri#enter_with('winsize', 'n', '', '<C-w><', '<C-w><')
call karakuri#enter_with('winsize', 'n', '', '<C-w>+', '<C-w>-')
call karakuri#enter_with('winsize', 'n', '', '<C-w>-', '<C-w>+')
call karakuri#map('winsize', 'n', '', '>', '<C-w>>')
call karakuri#map('winsize', 'n', '', '<', '<C-w><')
call karakuri#map('winsize', 'n', '', '+', '<C-w>-')
call karakuri#map('winsize', 'n', '', '-', '<C-w>+')

" Builder interface
let s:winsize = karakuri#builder('winsize')
call s:winsize.enter_with().mode('n').lhs('<C-w>>').rhs('<C-w>>').exec()
call s:winsize.enter_with().mode('n').lhs('<C-w><').rhs('<C-w><').exec()
call s:winsize.enter_with().mode('n').lhs('<C-w>+').rhs('<C-w>+').exec()
call s:winsize.enter_with().mode('n').lhs('<C-w>-').rhs('<C-w>-').exec()

" More fluent builder interface
call s:winsize.enter_with()
    \.mode('n').lhs('<C-w>>').rhs('<C-w>>').exec()
    \.mode('n').lhs('<C-w><').rhs('<C-w><').exec()
    \.mode('n').lhs('<C-w>+').rhs('<C-w>+').exec()
    \.mode('n').lhs('<C-w>-').rhs('<C-w>-').exec()

" 'prototype object' is returned by EnterWith.exec() so .exec() finds:
" * a left mapping is a normal mode mapping even without ".mode('n')"
" * a left mapping's timeout option is off even without ".timeout(0)"
call s:winsize.map({'prototype': {'mode': 'n', 'timeout': 0}})
    \.lhs('>').rhs('<C-w>>').exec()
    \.lhs('<').rhs('<C-w><').exec()
    \.lhs('+').rhs('<C-w>+').exec()
    \.lhs('-').rhs('<C-w>-').exec()
