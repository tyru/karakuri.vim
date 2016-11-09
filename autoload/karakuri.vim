scriptencoding utf-8

"
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
"
" ==============================================================================
"
" Mapping definitions:
"
" enter_with() defines:
"   * {mode}map {enter-with-lhs} <Plug>karakuri.enter_with_rhs({submode})<Plug>karakuri.init({submode})<Plug>karakuri.in({submode})
"   * {mode}{nore}map {options} <Plug>karakuri.enter_with_rhs({submode}) {enter-with-rhs}
" If '<Plug>karakuri.leave_with_keyseqs_exist({submode})' was NOT defined (*1):
"   * {mode}noremap <expr> <Plug>karakuri.in({submode})<default-keyseqs-to-leave> <call-finalize-func>
"
" map() defines:
"   * {mode}map <Plug>karakuri.in({submode}){map-lhs} <Plug>karakuri.map_rhs({submode})<Plug>karakuri.prompt({submode})<Plug>karakuri.in({submode})
"   * {mode}{nore}map {options} <Plug>karakuri.map_rhs({submode}) {map-rhs}
" If '<Plug>karakuri.leave_with_keyseqs_exist({submode})' was NOT defined (*1):
"   * {mode}noremap <expr> <Plug>karakuri.in({submode})<default-keyseqs-to-leave> <call-finalize-func>

" leave_with() defines:
"   * {mode}{nore}map <expr> <Plug>karakuri.in({submode})<leave-with-lhs> <call-finalize-func>
"   * {mode}noremap <Plug>karakuri.leave_with_keyseqs_exist({submode}) {dummy}
" leave_with() undefines (if it was defined) (*1):
"   * {mode}noremap <expr> <Plug>karakuri.in({submode})<default-keyseqs-to-leave>
"
" When one of above methods is called at first, it defines (*1):
"   * {mode}noremap <expr> <Plug>karakuri.init({submode}) <call-init-func>
"   * {mode}noremap <expr> <Plug>karakuri.in({submode}) <call-fallback-func>
"   * {mode}noremap <expr> <Plug>karakuri.prompt({submode}) <call-prompt-func>
"
" unmap() *undefines*:
"   * TODO
"
" *1 : (TODO) These checks can be omitted when multiple mappings
"      are defined like the following:
"
"        call s:unredo
"          \.enter_with().mode('n').lhs('g-').rhs('g-')
"          \.enter_with().mode('n').lhs('g+').rhs('g+')
"          \.map().mode('n').lhs('-').rhs('g-')
"          \.map().mode('n').lhs('+').rhs('g+')
"          \.exec()
"

"
" Variables
"

" Key: {submode}, Value: saved old values in <call-init-func>.
let s:saved_options = {}
" Key: {submode}, Value: List of String that holds local values in submode.
" The values are set by Builder via Map.timeout(), and so on.
let s:local_options = {}

"
" Utilities
"

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
let s:TYPE_OF[s:TYPE_NUMBER] = 'Number'
let s:TYPE_OF[s:TYPE_STRING] = 'String'
let s:TYPE_OF[s:TYPE_FUNCREF] = 'Funcref'
let s:TYPE_OF[s:TYPE_LIST] = 'List'
let s:TYPE_OF[s:TYPE_DICT] = 'Dictionary'
let s:TYPE_OF[s:TYPE_FLOAT] = 'Float'
if v:version >== 800
  let s:TYPE_OF[s:TYPE_BOOLEAN] = 'Boolean'
  let s:TYPE_OF[s:TYPE_NONE] = 'None'
  let s:TYPE_OF[s:TYPE_JOB] = 'Job'
  let s:TYPE_OF[s:TYPE_CHANNEL] = 'Channel'
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

function! s:method(scope, obj_name, method_name) abort
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
  call s:validate(a:submode, a:submode, s:TYPE_STRING)
  call s:validate(a:submode, a:modes, s:TYPE_STRING)
  call s:validate(a:submode, a:options, s:TYPE_STRING)
  call s:validate(a:submode, a:lhs, s:TYPE_STRING)
  if a:0
    call s:validate(a:submode, a:1, s:TYPE_STRING)
  endif

  let map = karakuri#builder(a:submode).enter_with()
  let map = map.mode(a:modes).lhs(a:lhs)
  if a:options !=# ''
    let map = s:Map__parse_options(map, a:options)
  endif
  if a:0
    let map = map.rhs(a:1)
  endif
  call map.exec()
endfunction

function! karakuri#leave_with(submode, modes, options, lhs) abort
  call s:validate(a:submode, a:submode, s:TYPE_STRING)
  call s:validate(a:submode, a:modes, s:TYPE_STRING)
  call s:validate(a:submode, a:options, s:TYPE_STRING)
  call s:validate(a:submode, a:lhs, s:TYPE_STRING)

  let map = karakuri#builder(a:submode).leave_with()
  let map = map.mode(a:modes).lhs(a:lhs)
  if a:options !=# ''
    let map = s:Map__parse_options(map, a:options)
  endif
  call map.exec()
endfunction

function! karakuri#map(submode, modes, options, lhs, rhs) abort
  call s:validate(a:submode, a:submode, s:TYPE_STRING)
  call s:validate(a:submode, a:modes, s:TYPE_STRING)
  call s:validate(a:submode, a:options, s:TYPE_STRING)
  call s:validate(a:submode, a:lhs, s:TYPE_STRING)
  call s:validate(a:submode, a:rhs, s:TYPE_STRING)

  let map = karakuri#builder(a:submode).map()
  let map = map.mode(a:modes).lhs(a:lhs).rhs(a:rhs)
  if a:options !=# ''
    let map = s:Map__parse_options(map, a:options)
  endif
  call map.exec()
endfunction

function! karakuri#unmap(submode, modes, options, lhs) abort
  call s:validate(a:submode, a:submode, s:TYPE_STRING)
  call s:validate(a:submode, a:modes, s:TYPE_STRING)
  call s:validate(a:submode, a:options, s:TYPE_STRING)
  call s:validate(a:submode, a:lhs, s:TYPE_STRING)

  let map = karakuri#builder(a:submode).unmap()
  let map = map.mode(a:modes).lhs(a:lhs).rhs(a:rhs)
  if a:options !=# ''
    let map = s:Map__parse_options(map, a:options)
  endif
  call map.exec()
endfunction


" The entrance to core logic:
"
" * karakuri#builder(submode : String) : Builder
"

function! karakuri#builder(submode) abort
  if a:submode ==# ''
    call s:throw('', 'Submode cannot be empty.')
  endif
  return s:Builder__new(a:submode)
endfunction


" Builder:
"   Builder interface object.
"   karakuri#builder() returns this object.
"
"   Properties:
"     * _submode : String = submode
"     * _env : List[Map] = [<_map> ...]
"     * _options : Dictionary[String,Any] = {map_type: <map_type>, <same property keys as method names> ...}
"
"   Methods:
"     * Builder.enter_with() : EnterWith
"         EnterWith is a Map
"     * Builder.leave_with() : LeaveWith
"         LeaveWith is a Map
"     * Builder.map() : Mapper
"         Mapper is a Map
"     * Builder.unmap() : Unmapper
"         Unmapper is a Map
"
"     * Builder.timeout(b : Bool) : Builder
"       * Local to map
"       * TODO: Currently it's implemented as global option.
"         Move to Map class
"     * Builder.timeoutlen(msec : Number) : Builder
"       * Local to map
"       * TODO: Currently it's implemented as global option.
"         Move to Map class
"     * Builder.showmode(b : Bool) : Builder
"       * Local to map
"       * TODO: Currently it's implemented as global option.
"         Move to Map class
"     * Builder.inherit(b : Bool) : Builder
"       * Global
"     * Builder.keep_leaving_key(b : Bool) : Builder
"       * Global
"     * Builder.keyseqs_to_leave(keyseqs : List[String]) : Builder
"       * Global
"     * Builder.always_show_submode(b : Bool) : Builder
"       * Global
"

let s:MAP_UI_DEFAULT_OPTIONS = {
\ 'silent': 0,
\ 'noremap': 1,
\ 'expr': 0,
\ 'buffer': 0,
\ 'unique': 0,
\ 'nowait': 0,
\ 'timeout': 1,
\ 'timeoutlen': 1000,
\ 'showmode': 1,
\ 'inherit': 0,
\ 'keep_leaving_key': 0,
\ 'keyseqs_to_leave': ['<Esc>'],
\ 'always_show_submode': 0
\}

function! s:Builder__new(submode) abort
  let builder = deepcopy(s:Builder)
  let builder._submode = a:submode
  let builder._env = []
  let builder._options = {}
  return builder
endfunction

function! s:Builder__push_map(this, map, map_type) abort
  if has_key(a:map, '_map')
    let map = extend(copy(a:map._map), {'map_type': a:map_type}, 'error')
    let a:this._env += [map]
  endif
  let a:map._map = {}
endfunction


let s:Builder = {}

function! s:Builder_enter_with() abort dict
  return s:Map__new(self, 'enter_with')
endfunction
call s:method(s:, 'Builder', 'enter_with')

function! s:Builder_leave_with() abort dict
  return s:Map__new(self, 'leave_with')
endfunction
call s:method(s:, 'Builder', 'leave_with')

function! s:Builder_map() abort dict
  return s:Map__new(self, 'map')
endfunction
call s:method(s:, 'Builder', 'map')

function! s:Builder_unmap() abort dict
  return s:Map__new(self, 'unmap')
endfunction
call s:method(s:, 'Builder', 'unmap')

function! s:Builder_timeout(b) abort dict
  let self._options.timeout = !!a:b
endfunction
call s:method(s:, 'Builder', 'timeout')

function! s:Builder_timeoutlen(msec) abort dict
  call s:validate(self._submode, a:msec, s:TYPE_NUMBER)
  let self._options.timeoutlen = !!a:b
  return self
endfunction
call s:method(s:, 'Builder', 'timeoutlen')

function! s:Builder_showmode(b) abort dict
  let self._options.showmode = !!a:b
  return self
endfunction
call s:method(s:, 'Builder', 'showmode')

function! s:Builder_inherit(b) abort dict
  let self._options.inherit = !!a:b
  return self
endfunction
call s:method(s:, 'Builder', 'inherit')

function! s:Builder_keep_leaving_key(b) abort dict
  let self._options.keep_leaving_key = !!a:b
  return self
endfunction
call s:method(s:, 'Builder', 'keep_leaving_key')

function! s:Builder_keyseqs_to_leave(keyseqs) abort dict
  call s:validate(self._submode, a:keyseqs, s:TYPE_LIST)
  let self._options.keyseqs_to_leave = a:keyseqs
  return self
endfunction
call s:method(s:, 'Builder', 'keyseqs_to_leave')

function! s:Builder_always_show_submode(b) abort dict
  let self._options.always_show_submode = !!a:b
  return self
endfunction
call s:method(s:, 'Builder', 'always_show_submode')


" Map:
"
"   Properties:
"     * _builder : Builder =  Builder object
"     * _map : Dictionary[String,Any] = {map_type: <map_type>, <same property keys as method names> ...}
"       * map_type : String = One of 'enter_with', 'leave_with', 'map', 'unmap'
"
"   Methods:
"     * Map.enter_with() : EnterWith
"     * Map.leave_with() : LeaveWith
"     * Map.map() : Mapper
"     * Map.unmap() : Unmapper
"
"     * Map.mode(modes : Modes) : Map
"     * Map.lhs(lhs : String) : Map
"     * Map.rhs(rhs : String) : Map
"     * Map.silent(b : Bool) : Map
"     * Map.noremap(b : Bool) : Map
"     * Map.expr(b : Bool) : Map
"     * Map.buffer(b : Bool) : Map
"     * Map.unique(b : Bool) : Map
"     * Map.nowait(b : Bool) : Map
"
"     * Map.exec() : Unit
"
"     * Option methods:
"       * Map.timeout(b : Bool) : Map
"         * Local to map
"         * TODO: Currently it's implemented as global option
"       * Map.timeoutlen(msec : Number) : Map
"         * Local to map
"         * TODO: Currently it's implemented as global option
"       * Map.showmode(b : Bool) : Map
"         * Local to map
"         * TODO: Currently it's implemented as global option
"       * Map.inherit(b : Bool) : Map
"         * Global
"       * Map.keep_leaving_key(b : Bool) : Map
"         * Global
"       * Map.keyseqs_to_leave(keyseqs : List[String]) : Map
"         * Global
"       * Map.always_show_submode(b : Bool) : Map
"         * Global
"

function! s:Map__new(builder, init) abort
  let map = deepcopy(s:Map)
  let map._builder = a:builder
  " 'map[a:init]' method checks if '_map' key exists.
  " let map._map = {}
  return map[a:init]()
endfunction

function! s:Map__parse_options(map, options) abort
  let map = a:map
  if a:options =~# 'b'
    let map = map.buffer(1)
  endif
  if a:options =~# 'e'
    let map = map.expr(1)
  endif
  if a:options =~# 'r'
    let map = map.noremap(0)
  endif
  if a:options =~# 's'
    let map = map.silent(1)
  endif
  if a:options =~# 'u'
    let map = map.unique(1)
  endif
  if a:options =~# 'x'
    let map = map.keep_leaving_key(1)
  endif
  return map
endfunction

function! s:Map__get(this, map, key) abort
  return has_key(a:map, a:key) ? a:map[a:key] :
  \       has_key(s:MAP_UI_DEFAULT_OPTIONS, a:key) ? s:MAP_UI_DEFAULT_OPTIONS[a:key] :
  \       s:throw(a:this._builder._submode, "Required key '" . a:key . "' was not given.")
endfunction

function! s:Map__create_base_mappings(this, submode, mode) abort
  let init_lhs = printf('<Plug>karakuri.init(%s)', a:submode)
  if maparg(init_lhs, a:mode, 0) !=# ''
    " Skip if it's defined already
    return
  endif
  " <Plug>karakuri.init({submode})
  call s:Map__create_map(a:this, {
  \ 'modes': a:mode,
  \ 'mapcmd': 'noremap',
  \ 'options': '<expr>',
  \ 'lhs': init_lhs
  \ 'rhs': printf('<SID>on_entering_submode(%s)', string(a:submode))
  \})
  " <Plug>karakuri.in({submode})
  let in_lhs = printf('<Plug>karakuri.in(%s)', a:submode)
  call s:Map__create_map(a:this, {
  \ 'modes': a:mode,
  \ 'mapcmd': 'noremap',
  \ 'options': '<expr>',
  \ 'lhs': in_lhs
  \ 'rhs': printf('<SID>on_fallback_action(%s)', string(a:submode))
  \})
  " <Plug>karakuri.prompt({submode})
  let prompt_lhs = printf('<Plug>karakuri.prompt(%s)', a:submode)
  call s:Map__create_map(a:this, {
  \ 'modes': a:mode,
  \ 'mapcmd': 'noremap',
  \ 'options': '<expr>',
  \ 'lhs': prompt_lhs
  \ 'rhs': printf('<SID>on_prompt_action(%s)', string(a:submode))
  \})
endfunction

function! s:Map__create_mappings_of_enter_with(this, submode, map) abort
  let modes = s:Map__get(a:this, a:map, 'modes')
  let noremap = s:Map__get(a:this, a:map, 'noremap')
  let options = s:Map__options_dict2str(a:this, a:map)
  let lhs = s:Map__get(a:this, a:map, 'lhs')
  let rhs = s:Map__get(a:this, a:map, 'rhs')
  let keyseqs_to_leave_list = s:Map__get(a:this, a:map, 'keyseqs_to_leave')
  for mode in split(modes, '\zs')
    " <Plug>karakuri.init({submode}), ...
    call s:Map__create_base_mappings(a:this, a:submode, mode)
    " {enter-with-lhs}
    call s:Map__create_map(a:this, {
    \ 'mode': mode,
    \ 'mapcmd': 'map',
    \ 'options': '',
    \ 'lhs': lhs,
    \ 'rhs': printf(join(['<Plug>karakuri.enter_with_rhs(%s)',
    \                     '<Plug>karakuri.init(%s)',
    \                     '<Plug>karakuri.in(%s)'], ''),
    \               a:submode, a:submode, a:submode)
    \})
    " <Plug>karakuri.enter_with_rhs({submode})
    call s:Map__create_map(a:this, {
    \ 'mode': mode,
    \ 'mapcmd': (noremap ? 'noremap' : 'map'),
    \ 'options': options,
    \ 'lhs': printf('<Plug>karakuri.enter_with_rhs(%s)', a:submode),
    \ 'rhs': rhs
    \})
    " <Plug>karakuri.in({submode})<default-keyseqs-to-leave>
    " (If '<Plug>karakuri.leave_with_keyseqs_exist({submode})' was NOT defined)
    let leave_with_keyseqs_exist_lhs =
    \   printf('<Plug>karakuri.leave_with_keyseqs_exist(%s)', a:submode)
    if maparg(leave_with_keyseqs_exist_lhs, mode, 0) ==# ''
      for leave_lhs in keyseqs_to_leave_list
        call s:Map__create_map(a:this, {
        \ 'mode': mode,
        \ 'mapcmd': 'noremap',
        \ 'options': '<expr>',
        \ 'lhs': printf('<Plug>karakuri.in(%s)%s', a:submode, leave_lhs),
        \ 'rhs': printf('<SID>on_leaving_submode(%s)', string(a:submode))
        \})
      endfor
    endif
  endfor
endfunction

function! s:Map__create_mappings_of_leave_with(this, submode, map) abort
  let modes = s:Map__get(a:this, a:map, 'modes')
  let noremap = s:Map__get(a:this, a:map, 'noremap')
  let options = s:Map__options_dict2str(a:this, a:map)
  let lhs = s:Map__get(a:this, a:map, 'lhs')
  for mode in split(modes, '\zs')
    " <Plug>karakuri.init({submode}), ...
    call s:Map__create_base_mappings(a:this, a:submode, mode)
    " <Plug>karakuri.in({submode})<leave-with-lhs>
    call s:Map__create_map(a:this, {
    \ 'mode': mode,
    \ 'mapcmd': 'noremap',
    \ 'options': '<expr>',
    \ 'lhs': printf('<Plug>karakuri.in(%s)%s', a:submode, lhs),
    \ 'rhs': printf('<SID>on_leaving_submode(%s)', string(a:submode))
    \})
    " <Plug>karakuri.in({submode})<default-keyseqs-to-leave>
    " (*Undefine* if it was defined)
    let keyseqs_to_leave = s:MAP_UI_DEFAULT_OPTIONS.keyseqs_to_leave[0]
    let keyseqs_to_leave_lhs = printf('<Plug>karakuri.in(%s)%s',
    \                                 a:submode, keyseqs_to_leave),
    if maparg(keyseqs_to_leave_lhs, mode, 0) !=# ''
      call s:Map__create_unmap(a:this, {
      \ 'mode': mode,
      \ 'lhs': keyseqs_to_leave_lhs
      \})
    endif
    " <Plug>karakuri.leave_with_keyseqs_exist({submode})
    call s:Map__create_map(a:this, {
    \ 'mode': mode,
    \ 'mapcmd': 'noremap',
    \ 'options': '',
    \ 'lhs': printf('<Plug>karakuri.leave_with_keyseqs_exist(%s)', a:submode),
    \ 'rhs': '[leave-with-keyseqs-exist]'
    \})
  endfor
endfunction

function! s:Map__create_mappings_of_map(this, submode, map) abort
  let modes = s:Map__get(a:this, a:map, 'modes')
  let noremap = s:Map__get(a:this, a:map, 'noremap')
  let options = s:Map__options_dict2str(a:this, a:map)
  let lhs = s:Map__get(a:this, a:map, 'lhs')
  let rhs = s:Map__get(a:this, a:map, 'rhs')
  let keyseqs_to_leave_list = s:Map__get(a:this, a:map, 'keyseqs_to_leave')
  for mode in split(modes, '\zs')
    " <Plug>karakuri.init({submode}), ...
    call s:Map__create_base_mappings(a:this, a:submode, mode)
    " <Plug>karakuri.in({submode}){map-lhs}
    call s:Map__create_map(a:this, {
    \ 'mode': mode,
    \ 'mapcmd': 'map',
    \ 'options': '',
    \ 'lhs': printf('<Plug>karakuri.in(%s)%s', a:submode, lhs)
    \ 'rhs': printf(join(['<Plug>karakuri.map_rhs(%s)',
    \                     '<Plug>karakuri.prompt(%s)',
    \                     '<Plug>karakuri.in(%s)'], ''),
    \               a:submode, a:submode, a:submode)
    \})
    " <Plug>karakuri.map_rhs({submode})
    call s:Map__create_map(a:this, {
    \ 'mode': mode,
    \ 'mapcmd': (noremap ? 'noremap' : 'map'),
    \ 'options': options,
    \ 'lhs': printf('<Plug>karakuri.map_rhs(%s)', a:submode),
    \ 'rhs': rhs
    \})
    " <Plug>karakuri.in({submode})<default-keyseqs-to-leave>
    " (If '<Plug>karakuri.leave_with_keyseqs_exist({submode})' was NOT defined)
    let leave_with_keyseqs_exist_lhs =
    \   printf('<Plug>karakuri.leave_with_keyseqs_exist(%s)', a:submode)
    if maparg(leave_with_keyseqs_exist_lhs, mode, 0) ==# ''
      for leave_lhs in keyseqs_to_leave_list
        call s:Map__create_map(a:this, {
        \ 'mode': mode,
        \ 'mapcmd': 'noremap',
        \ 'options': '<expr>',
        \ 'lhs': printf('<Plug>karakuri.in(%s)%s', a:submode, leave_lhs),
        \ 'rhs': printf('<SID>on_leaving_submode(%s)', string(a:submode))
        \})
      endfor
    endif
  endfor
endfunction

function! s:Map__create_mappings_of_unmap(this, submode, map) abort
  " TODO
endfunction

function! s:Map__options_dict2str(this, map) abort
  let str = ''
  if s:Map__get(a:this, a:map, 'silent')
    let str .= '<silent>'
  endif
  if s:Map__get(a:this, a:map, 'expr')
    let str .= '<expr>'
  endif
  if s:Map__get(a:this, a:map, 'buffer')
    let str .= '<buffer>'
  endif
  if s:Map__get(a:this, a:map, 'unique')
    let str .= '<unique>'
  endif
  if s:Map__get(a:this, a:map, 'nowait')
    let str .= '<nowait>'
  endif
  return str
endfunction

function! s:Map__create_map(this, args) abort
  execute a:args.mode . a:args.mapcmd
  \       a:args.options
  \       a:args.lhs
  \       a:args.rhs
endfunction

function! s:Map__create_unmap(this, args) abort
  execute a:args.mode . 'unmap' a:args.lhs
endfunction


let s:Map = {}

function! s:Map_enter_with() abort dict
  call s:Builder__push_map(self._builder, self, 'enter_with')
  return self
endfunction
call s:method(s:, 'Map', 'enter_with')

function! s:Map_leave_with() abort dict
  call s:Builder__push_map(self._builder, self, 'leave_with')
  return self
endfunction
call s:method(s:, 'Map', 'leave_with')

function! s:Map_map() abort dict
  call s:Builder__push_map(self._builder, self, 'map')
  return self
endfunction
call s:method(s:, 'Map', 'map')

function! s:Map_unmap() abort dict
  call s:Builder__push_map(self._builder, self, 'unmap')
  return self
endfunction
call s:method(s:, 'Map', 'unmap')

function! s:Map_mode(modes) abort dict
  call s:validate(self._submode, a:modes, s:TYPE_STRING)
  let pos = match(a:modes, '[^nvoicsxl]')
  if pos isnot -1
    call s:throw(self._submode, "Invalid character '" . a:modes[pos] . "' in the argument of .mode().")
  endif
  let self._map.modes = a:modes
  return self
endfunction
call s:method(s:, 'Map', 'mode')

function! s:Map_lhs(lhs) abort dict
  call s:validate(self._submode, a:lhs, s:TYPE_STRING)
  let self._map.lhs = a:lhs
  return self
endfunction
call s:method(s:, 'Map', 'lhs')

function! s:Map_rhs(rhs) abort dict
  call s:validate(self._submode, a:rhs, s:TYPE_STRING)
  let self._map.rhs = a:rhs
  return self
endfunction
call s:method(s:, 'Map', 'rhs')

function! s:Map_silent(b) abort dict
  let self._map.silent = !!a:b
  return self
endfunction
call s:method(s:, 'Map', 'silent')

function! s:Map_noremap(b) abort dict
  let self._map.noremap = !!a:b
  return self
endfunction
call s:method(s:, 'Map', 'noremap')

function! s:Map_expr(b) abort dict
  let self._map.expr = !!a:b
  return self
endfunction
call s:method(s:, 'Map', 'expr')

function! s:Map_buffer(b) abort dict
  let self._map.buffer = !!a:b
  return self
endfunction
call s:method(s:, 'Map', 'buffer')

function! s:Map_unique(b) abort dict
  let self._map.unique = !!a:b
  return self
endfunction
call s:method(s:, 'Map', 'unique')

function! s:Map_nowait(b) abort dict
  let self._map.nowait = !!a:b
  return self
endfunction
call s:method(s:, 'Map', 'nowait')

function! s:Map_timeout(b) abort dict
  call self._builder.timeout(a:b)
  return self
endfunction
call s:method(s:, 'Map', 'timeout')

function! s:Map_timeoutlen(msec) abort dict
  call self._builder.timeoutlen(a:b)
  return self
endfunction
call s:method(s:, 'Map', 'timeoutlen')

function! s:Map_showmode(b) abort dict
  call self._builder.showmode(a:b)
  return self
endfunction
call s:method(s:, 'Map', 'showmode')

function! s:Map_inherit(b) abort dict
  call self._builder.inherit(a:b)
  return self
endfunction
call s:method(s:, 'Map', 'inherit')

function! s:Map_keep_leaving_key(b) abort dict
  call self._builder.keep_leaving_key(a:b)
  return self
endfunction
call s:method(s:, 'Map', 'keep_leaving_key')

function! s:Map_keyseqs_to_leave(keyseqs) abort dict
  call self._builder.keyseqs_to_leave(a:keyseqs)
  return self
endfunction
call s:method(s:, 'Map', 'keyseqs_to_leave')

function! s:Map_always_show_submode(b) abort dict
  call self._builder.always_show_submode(a:b)
  return self
endfunction
call s:method(s:, 'Map', 'always_show_submode')

function! s:Map_exec() abort dict
  for map in self._env
    call s:Map__create_mappings_of_{map.map_type}(self, self._submode, map)
  endfor
endfunction
call s:method(s:, 'Map', 'exec')


let s:OPTION_NAMES = [
\ 'timeout',
\ 'timeoutlen',
\ 'showmode',
\ 'inherit',
\ 'keep_leaving_key',
\ 'keyseqs_to_leave',
\ 'always_show_submode'
\]

" <call-init-func>
function! s:on_entering_submode(submode, option_names) " abort
  try
    let s:saved_options[a:submode] = {}
    for name in a:option_names
      let s:saved_options[a:submode][name] = getbufvar('%', '&' . name)
    endfor
  finally
    return ''
  endtry
endfunction

" <call-finalize-func>
function! s:on_leaving_submode(submode) " abort
  try
    " TODO
  finally
    return ''
  endtry
endfunction

" <call-fallback-func>
function! s:on_fallback_action(submode) " abort
  try
    " TODO
  finally
    return ''
  endtry
endfunction

" <call-prompt-func>
function! s:on_prompt_action(submode) " abort
  try
    redraw
    echohl ModeMsg
    echo '-- Submode:' a:submode '--'
    echohl None
  finally
    return ''
  endtry
endfunction


finish



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
call s:unredo
  \.enter_with().mode('n').lhs('g-').rhs('g-')
  \.enter_with().mode('n').lhs('g+').rhs('g+')
  \.map().mode('n').lhs('-').rhs('g-')
  \.map().mode('n').lhs('+').rhs('g+')
  \.exec()
