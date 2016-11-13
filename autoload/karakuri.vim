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
"     5.1.2. 'inherit' is true -> feedkeys("\<Plug>karakuri.in({submode})", 'm')
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
"   If the global options are updated:
"     * {mode}noremap <expr> <Plug>karakuri.init({submode}) <call-init-func>
"
" map() defines:
"   * {mode}map <Plug>karakuri.in({submode}){map-lhs} <Plug>karakuri.map_rhs({submode})<Plug>karakuri.prompt({submode})<Plug>karakuri.in({submode})
"   * {mode}{nore}map {options} <Plug>karakuri.map_rhs({submode}) {map-rhs}
"   If the global options are updated:
"     * {mode}noremap <expr> <Plug>karakuri.init({submode}) <call-init-func>

" leave_with() defines:
"   * {mode}noremap <Plug>karakuri.leave_with_keyseqs({submode}) {leave-with-lhs}
"   If the global options are updated:
"     * {mode}noremap <expr> <Plug>karakuri.init({submode}) <call-init-func>
"
" <call-init-func> defines:
"   * {mode}noremap <expr> <Plug>karakuri.in({submode}) <call-fallback-func>
"   * {mode}noremap <expr> <Plug>karakuri.prompt({submode}) <call-prompt-func>
"   If '<Plug>karakuri.leave_with_keyseqs({submode})' was defined:
"     * {mode}{nore}map <expr> <Plug>karakuri.in({submode}){leave-with-lhs} <call-finalize-func>
"   Else:
"     * {mode}noremap <expr> <Plug>karakuri.in({submode}){default-keyseqs-to-leave} <call-finalize-func>
"
" unmap() *undefines*:
"   * TODO
"

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

function! s:get_option(submode, global, local, name) abort
  return has_key(a:local, a:name) ? a:local[a:name] :
  \       has_key(a:global, a:name) ? a:global[a:name] :
  \       has_key(s:MAP_UI_DEFAULT_OPTIONS, a:name) ? s:MAP_UI_DEFAULT_OPTIONS[a:name] :
  \       s:throw(a:submode, "Required key '" . a:name . "' was not given.")
endfunction

function! s:create_map(args) abort
  execute a:args.mode . a:args.mapcmd
  \       a:args.options
  \       a:args.lhs
  \       a:args.rhs
endfunction

function! s:create_unmap(args) abort
  execute a:args.mode . 'unmap' a:args.lhs
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
"     * _env : List[Map] = [ <MapEnv> ... ]
"       * <MapEnv> : All merged properties of (conflict must NOT be occurred):
"         * { map_type: <map_type> }
"           * <map_type> : String = One of 'enter_with', 'leave_with', 'map', 'unmap'
"         * Map._map
"         * Map._local
"     * _global : Dictionary[String,Any] = { <option properties> ... }
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
  let builder._global = {}
  return builder
endfunction

function! s:Builder__push_map(this, map, map_type) abort
  if has_key(a:map, '_map')
    let mapenv = {'map_type': a:map_type}
    let mapenv = extend(mapenv, deepcopy(a:map._map), 'error')
    let mapenv = extend(mapenv, deepcopy(a:map._local), 'error')
    let a:this._env += [mapenv]
  endif
  let a:map._map = {}
  let a:map._local = {}
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

function! s:Builder_inherit(b) abort dict
  let self._global.inherit = !!a:b
  return self
endfunction
call s:method(s:, 'Builder', 'inherit')

function! s:Builder_keep_leaving_key(b) abort dict
  let self._global.keep_leaving_key = !!a:b
  return self
endfunction
call s:method(s:, 'Builder', 'keep_leaving_key')

function! s:Builder_keyseqs_to_leave(keyseqs) abort dict
  call s:validate(self._submode, a:keyseqs, s:TYPE_LIST)
  let self._global.keyseqs_to_leave = a:keyseqs
  return self
endfunction
call s:method(s:, 'Builder', 'keyseqs_to_leave')

function! s:Builder_always_show_submode(b) abort dict
  let self._global.always_show_submode = !!a:b
  return self
endfunction
call s:method(s:, 'Builder', 'always_show_submode')


" Map:
"
"   Properties:
"     * _builder : Builder =  Builder object
"     * _map : Dictionary[String,Any] = { <map properties> ... }
"       * 'modes'
"       * 'lhs'
"       * 'rhs'
"       * 'silent'
"       * 'noremap'
"       * 'expr'
"       * 'buffer'
"       * 'unique'
"       * 'nowait'
"     * _local : Dictionary[String,Any] = { <option properties> ... }
"       * 'timeout'
"       * 'timeoutlen'
"       * 'showmode'
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
"       * Map.timeoutlen(msec : Number) : Map
"         * Local to map
"       * Map.showmode(b : Bool) : Map
"         * Local to map
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

function! s:Map__get_option(this, mapenv, name) abort
  return s:get_option(
  \         a:this._builder._submode,
  \         a:this._builder._global,
  \         a:mapenv,
  \         a:name)
endfunction

function! s:Map__create_mappings_of_enter_with(this, submode, mapenv) abort
  let modes = s:Map__get_option(a:this, a:mapenv, 'modes')
  let noremap = s:Map__get_option(a:this, a:mapenv, 'noremap')
  let options = s:Map__options_dict2str(a:this, a:mapenv)
  let lhs = s:Map__get_option(a:this, a:mapenv, 'lhs')
  let rhs = s:Map__get_option(a:this, a:mapenv, 'rhs')
  for mode in split(modes, '\zs')
    " {enter-with-lhs}
    call s:create_map({
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
    call s:create_map({
    \ 'mode': mode,
    \ 'mapcmd': (noremap ? 'noremap' : 'map'),
    \ 'options': options,
    \ 'lhs': printf('<Plug>karakuri.enter_with_rhs(%s)', a:submode),
    \ 'rhs': rhs
    \})
    " <Plug>karakuri.init({submode})
    call s:Map__update_init_mapping(a:this, mode)
  endfor
endfunction

function! s:Map__create_mappings_of_leave_with(this, submode, mapenv) abort
  let modes = s:Map__get_option(a:this, a:mapenv, 'modes')
  let noremap = s:Map__get_option(a:this, a:mapenv, 'noremap')
  let options = s:Map__options_dict2str(a:this, a:mapenv)
  let lhs = s:Map__get_option(a:this, a:mapenv, 'lhs')
  for mode in split(modes, '\zs')
    " <Plug>karakuri.leave_with_keyseqs({submode})
    let leave_with_keyseqs = printf('<Plug>karakuri.leave_with_keyseqs(%s)', a:submode)
    let old_rhs = maparg(leave_with_keyseqs, mode, 0)
    let rhs_list = old_rhs !=# '' ? eval(old_rhs) : []
    call s:create_map({
    \ 'mode': mode,
    \ 'mapcmd': 'noremap',
    \ 'options': '',
    \ 'lhs': leave_with_keyseqs,
    \ 'rhs': string(rhs_list + [lhs])
    \})
    " <Plug>karakuri.init({submode})
    call s:Map__update_init_mapping(a:this, mode)
  endfor
endfunction

function! s:Map__create_mappings_of_map(this, submode, mapenv) abort
  let modes = s:Map__get_option(a:this, a:mapenv, 'modes')
  let noremap = s:Map__get_option(a:this, a:mapenv, 'noremap')
  let options = s:Map__options_dict2str(a:this, a:mapenv)
  let lhs = s:Map__get_option(a:this, a:mapenv, 'lhs')
  let rhs = s:Map__get_option(a:this, a:mapenv, 'rhs')
  for mode in split(modes, '\zs')
    " <Plug>karakuri.in({submode}){map-lhs}
    call s:create_map({
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
    call s:create_map({
    \ 'mode': mode,
    \ 'mapcmd': (noremap ? 'noremap' : 'map'),
    \ 'options': options,
    \ 'lhs': printf('<Plug>karakuri.map_rhs(%s)', a:submode),
    \ 'rhs': rhs
    \})
    " <Plug>karakuri.init({submode})
    call s:Map__update_init_mapping(a:this, mode)
  endfor
endfunction

function! s:Map__create_mappings_of_unmap(this, submode, map) abort
  " TODO
endfunction

" <Plug>karakuri.init({submode})
" TODO: Early return if options are not changed
function! s:Map__update_init_mapping(this, mode) abort
  let submode = a:this._builder._submode
  let options = extend(copy(a:this._builder._global), a:this._local)
  call s:create_map({
  \ 'modes': a:mode,
  \ 'mapcmd': 'noremap',
  \ 'options': '<expr>',
  \ 'lhs': printf('<Plug>karakuri.init(%s)', submode),
  \ 'rhs': printf('<SID>on_entering_submode(%s, %s)',
  \               string(submode), string(options))
  \})
endfunction

function! s:Map__options_dict2str(this, mapenv) abort
  let str = ''
  if s:Map__get_option(a:this, a:mapenv, 'silent')
    let str .= '<silent>'
  endif
  if s:Map__get_option(a:this, a:mapenv, 'expr')
    let str .= '<expr>'
  endif
  if s:Map__get_option(a:this, a:mapenv, 'buffer')
    let str .= '<buffer>'
  endif
  if s:Map__get_option(a:this, a:mapenv, 'unique')
    let str .= '<unique>'
  endif
  if s:Map__get_option(a:this, a:mapenv, 'nowait')
    let str .= '<nowait>'
  endif
  return str
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
  let self._local.timeout = !!a:b
  return self
endfunction
call s:method(s:, 'Map', 'timeout')

function! s:Map_timeoutlen(msec) abort dict
  let self._local.timeoutlen = a:msec
  return self
endfunction
call s:method(s:, 'Map', 'timeoutlen')

function! s:Map_showmode(b) abort dict
  let self._local.showmode = !!a:b
  return self
endfunction
call s:method(s:, 'Map', 'showmode')

function! s:Map_exec() abort dict
  " TODO: Apply 'timeout', 'timeoutlen', 'showmode'
  for map in self._builder._env
    call s:Map__create_mappings_of_{map.map_type}(self, self._submode, map)
  endfor
endfunction
call s:method(s:, 'Map', 'exec')


" <call-init-func>
function! s:on_entering_submode(submode, options) " abort
  try
    " Save options
    let saved_options = {}
    for name in keys(a:options)
      let saved_options[name] = [bufnr('%'), getbufvar('%', '&' . name)]
    endfor

    " <Plug>karakuri.in({submode})
    let keep_leaving_key =
    \ get(a:options, 'keep_leaving_key', s:MAP_UI_DEFAULT_OPTIONS.keep_leaving_key)
    let inherit =
    \ get(a:options, 'inherit', s:MAP_UI_DEFAULT_OPTIONS.inherit)
    call s:create_map({
    \ 'modes': a:mode,
    \ 'mapcmd': 'noremap',
    \ 'options': '<expr>',
    \ 'lhs': printf('<Plug>karakuri.in(%s)', a:submode),
    \ 'rhs': printf('<SID>on_fallback_action(%s,%s,%d,%d)',
    \               string(a:submode),
    \               string(saved_options),
    \               !!keep_leaving_key,
    \               !!inherit)
    \})

    " <Plug>karakuri.prompt({submode})
    call s:create_map({
    \ 'modes': a:mode,
    \ 'mapcmd': 'noremap',
    \ 'options': '<expr>',
    \ 'lhs': printf('<Plug>karakuri.prompt(%s)', a:submode),
    \ 'rhs': printf('<SID>on_prompt_action(%s)', string(a:submode))
    \})

    " If '<Plug>karakuri.leave_with_keyseqs({submode})' was defined:
    "   Define <Plug>karakuri.in({submode}){leave-with-lhs}
    " Else:
    "   Define <Plug>karakuri.in({submode}){default-keyseqs-to-leave}
    let exist_lhs = printf('<Plug>karakuri.leave_with_keyseqs(%s)', a:submode)
    let leave_lhs = maparg(exist_lhs, mode, 0)
    if leave_lhs !=# ''
      let leave_lhs_list = eval(leave_lhs)
    else
      let leave_lhs_list = deepcopy(s:MAP_UI_DEFAULT_OPTIONS.keyseqs_to_leave)
    endif
    for leave_lhs in leave_lhs_list
      call s:create_map({
      \ 'mode': a:mode,
      \ 'mapcmd': 'noremap',
      \ 'options': '<expr>',
      \ 'lhs': printf('<Plug>karakuri.in(%s)%s', a:submode, leave_lhs),
      \ 'rhs': printf('<SID>on_leaving_submode(%s,%s)',
      \               string(a:submode), string(saved_options))
      \})
    endfor
  finally
    return ''
  endtry
endfunction

" <call-finalize-func>
function! s:on_leaving_submode(submode, saved_options) " abort
  try
    " Restore options
    for name in keys(a:saved_options)
      let [buf, value] = a:saved_options[name]
      call setbufvar(buf, '&' . name, value)
    endfor
  finally
    return ''
  endtry
endfunction

" <call-fallback-func>
function! s:on_fallback_action(submode, saved_options, keep_leaving_key, inherit) " abort
  try
    if getchar(1)
      if !a:keep_leaving_key
        call getchar(0)
      endif
      if a:inherit
        call feedkeys(printf("\<Plug>karakuri.in(%s)", a:submode), 'm')
      endif
    endif
    call s:on_leaving_submode(a:submode, a:saved_options)
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

