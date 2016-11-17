scriptencoding utf-8

"
" Simplified processes:
"
" 1. {enter-with-lhs}
" 2. <Plug>karakuri.enter_with_rhs({submode},{enter-with-lhs})
" 3. <Plug>karakuri.init({submode}) (<call-init-func>)
" 3.1. Save vim options
" 3.2. Set current submode (karakuri#current())
" 4. <Plug>karakuri.in({submode})
"   4.1. timeout -> Go to "5. <call-fallback-func>"
"   4.2. User types a key {map-lhs}
"     4.2.1. <Plug>karakuri.in({submode}){map-lhs} is defined:
"       4.2.1.1. {map-lhs} is <leave-with-keyseqs> -> Go to "6. Finalization"
"       4.2.1.2. {map-lhs} is not <leave-with-keyseqs>
"         4.2.1.2.1. <Plug>karakuri.map_rhs({submode},{map-lhs})
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
"   6.1.1. Restore saved vim options
"   6.1.2. Clear current submode (karakuri#current())
"   6.2.  Go to parent mode.
"
" ==============================================================================
"
" Mapping definitions:
"
" enter_with() defines:
"   * {mode}map {enter-with-lhs} <Plug>karakuri.enter_with_rhs({submode},{enter-with-lhs})<Plug>karakuri.init({submode})<Plug>karakuri.in({submode})
"   * {mode}{nore}map {options} <Plug>karakuri.enter_with_rhs({submode},{enter-with-lhs}) {enter-with-rhs}
"   If the global options are updated:
"     * {mode}noremap <expr> <Plug>karakuri.init({submode}) <call-init-func>
"
" map() defines:
"   * {mode}map <Plug>karakuri.in({submode}){map-lhs} <Plug>karakuri.map_rhs({submode},{map-lhs})<Plug>karakuri.prompt({submode})<Plug>karakuri.in({submode})
"   * {mode}{nore}map {options} <Plug>karakuri.map_rhs({submode},{map-lhs}) {map-rhs}
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
"     * {mode}noremap <expr> <Plug>karakuri.in({submode}){leave-with-lhs} <call-finalize-func>
"     * (same mappings for {leave-with-lhs-2}, {leave-with-lhs-3}, ...
"   Else:
"     * {mode}noremap <expr> <Plug>karakuri.in({submode}){default-keyseqs-to-leave} <call-finalize-func>
"
" unmap() *undefines*:
"   * TODO
"

"
" Variables
"

let s:running_submodes = []

"
" Utilities
"

if v:version >=# 800
  let s:JSON_ENCODE = 'json_encode'
  let s:JSON_DECODE = 'json_decode'
else
  let s:JSON_ENCODE = 'eval'
  let s:JSON_DECODE = 'string'
endif

let s:TYPE_NUMBER = 0
let s:TYPE_STRING = 1
let s:TYPE_FUNCREF = 2
let s:TYPE_LIST = 3
let s:TYPE_DICT = 4
let s:TYPE_FLOAT = 5
if v:version >=# 800
  let s:TYPE_BOOLEAN = 6
  let s:TYPE_NONE = 7
  let s:TYPE_JOB = 8
  let s:TYPE_CHANNEL = 9
endif
let s:TYPE_OF = []
let s:TYPE_OF += ['Number']
let s:TYPE_OF += ['String']
let s:TYPE_OF += ['Funcref']
let s:TYPE_OF += ['List']
let s:TYPE_OF += ['Dictionary']
let s:TYPE_OF += ['Float']
if v:version >=# 800
  let s:TYPE_OF += ['Boolean']
  let s:TYPE_OF += ['None']
  let s:TYPE_OF += ['Job']
  let s:TYPE_OF += ['Channel']
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

function! s:validate_named_func(submode, F) abort
  call s:validate(a:submode, a:F, s:TYPE_FUNCREF)
  try
    call eval(string(a:F))
  catch /E129/
    call s:throw(a:submode,
    \ 'Expected named funcref value but got ' .
    \ 'unnamed funcref (it can be created by funcref(), or lambda).'
    \)
  endtry
endfunction

function! s:validate_non_empty_string(submode, str) abort
  call s:validate(a:submode, a:str, s:TYPE_STRING)
  if a:str ==# ''
    call s:throw(a:submode,
    \ 'Expected non-empty String value but got ' .
    \ 'empty string value.'
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
  let a:scope[a:obj_name][a:method_name] =
  \ function('<SNR>' . s:SIDP . '_' . a:obj_name . '_' . a:method_name)
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
  \       substitute(a:args.lhs, '|', '<Bar>', 'g')
  \       substitute(a:args.rhs, '|', '<Bar>', 'g')
endfunction

function! s:create_unmap(args) abort
  execute a:args.mode . 'unmap'
  \       substitute(a:args.lhs, '|', '<Bar>', 'g')
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
  return s:current_submode
endfunction

function! karakuri#restore_options() abort
  while !empty(s:running_submodes)
    let r = remove(s:running_submodes, -1)
    call s:on_leaving_submode(r.submode, r.vim_options, r.on_finalize)
  endwhile
endfunction

function! karakuri#enter_with(submode, modes, options, lhs, ...) abort
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
  let map = karakuri#builder(a:submode).leave_with()
  let map = map.mode(a:modes).lhs(a:lhs)
  if a:options !=# ''
    let map = s:Map__parse_options(map, a:options)
  endif
  call map.exec()
endfunction

function! karakuri#map(submode, modes, options, lhs, rhs) abort
  let map = karakuri#builder(a:submode).map()
  let map = map.mode(a:modes).lhs(a:lhs).rhs(a:rhs)
  if a:options !=# ''
    let map = s:Map__parse_options(map, a:options)
  endif
  call map.exec()
endfunction

function! karakuri#unmap(submode, modes, options, lhs) abort
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
"         * Map._map
"         * Map._local
"     * _global : Dictionary = { <option properties> ... }
"       * 'inherit'
"       * 'keep_leaving_key'
"       * 'keyseqs_to_leave'
"       * 'always_show_submode'
"       * 'on_init'
"       * 'on_prompt'
"       * 'on_timeout'
"       * 'on_finalize'
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
"       * Global option
"     * Builder.keep_leaving_key(b : Bool) : Builder
"       * Global option
"     * Builder.keyseqs_to_leave(keyseqs : List[String]) : Builder
"       * Global option
"     * Builder.always_show_submode(b : Bool) : Builder
"       * Global option
"     * Builder.on_init(f : Funcref) : Builder
"       * Global option
"       * f = (ctx: Dictionary) => Unit
"         * ctx = {submode: String}
"     * Builder.on_prompt(f : Funcref) : Builder
"       * Global option, Return value is echoed to command-line
"       * f = (ctx: Dictionary) => String
"         * ctx = {submode: String}
"     * Builder.on_timeout(f : Funcref) : Builder
"       * Global option
"       * f = (ctx: Dictionary) => Unit
"         * ctx = {submode: String}
"     * Builder.on_finalize(f : Funcref) : Builder
"       * Global option
"       * f = (ctx: Dictionary) => Unit
"         * ctx = {submode: String}
"

function! s:default_prompt_func(submode) abort
  return '-- Submode: ' . a:submode . ' --'
endfunction

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
\ 'always_show_submode': 0,
\ 'on_init': [],
\ 'on_prompt': [function('s:default_prompt_func')],
\ 'on_timeout': [],
\ 'on_finalize': []
\}

function! s:Builder__new(submode) abort
  let builder = deepcopy(s:Builder)
  let builder._submode = a:submode
  let builder._env = []
  let builder._global = {}
  return builder
endfunction

" Push current map to 'Builder._env'
function! s:Builder__push_map(this, map) abort
  if has_key(a:map, '_map')
    let mapenv = {'map_type': a:map._map_type}
    let mapenv = extend(mapenv, a:map._map, 'error')
    let mapenv = extend(mapenv, a:map._local, 'error')
    let a:this._env += [mapenv]
  endif
endfunction

" Construct new map
function! s:Builder__construct(this, map, map_type) abort
  let a:map._map_type = a:map_type
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

function! s:Builder_on_init(F) abort dict
  call s:validate_named_func(self._submode, a:F)
  let self._global.on_init = get(self._global, 'on_init', []) + [a:F]
  return self
endfunction
call s:method(s:, 'Builder', 'on_init')

function! s:Builder_on_prompt(F) abort dict
  call s:validate_named_func(self._submode, a:F)
  let self._global.on_prompt = get(self._global, 'on_prompt', []) + [a:F]
  return self
endfunction
call s:method(s:, 'Builder', 'on_prompt')

function! s:Builder_on_timeout(F) abort dict
  call s:validate_named_func(self._submode, a:F)
  let self._global.on_timeout = get(self._global, 'on_timeout', []) + [a:F]
  return self
endfunction
call s:method(s:, 'Builder', 'on_timeout')

function! s:Builder_on_finalize(F) abort dict
  call s:validate_named_func(self._submode, a:F)
  let self._global.on_finalize = get(self._global, 'on_finalize', []) + [a:F]
  return self
endfunction
call s:method(s:, 'Builder', 'on_finalize')


" Map:
"
"   Properties:
"     * _builder : Builder =  Builder object
"     * _map_type: <map_type> : String
"       * One of 'enter_with', 'leave_with', 'map', 'unmap'
"     * _map : Dictionary = { <map properties> ... }
"       * 'modes'
"       * 'lhs'
"       * 'rhs'
"       * 'silent'
"       * 'noremap'
"       * 'expr'
"       * 'buffer'
"       * 'unique'
"       * 'nowait'
"     * _local : Dictionary = { <option properties> ... }
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
"     * Map.remap(b : Bool) : Map
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

function! s:Map__new(builder, map_type) abort
  let map = deepcopy(s:Map)
  let map._builder = a:builder
  " 'map[a:map_type]' method checks if '_map' key exists.
  " let map._map = {}
  return map[a:map_type]()
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
    \ 'rhs': printf(join(['<Plug>karakuri.enter_with_rhs(%s,%s)',
    \                     '<Plug>karakuri.init(%s)',
    \                     '<Plug>karakuri.in(%s)'], ''),
    \               a:submode, lhs, a:submode, a:submode)
    \})
    " <Plug>karakuri.enter_with_rhs({submode},{enter-with-lhs})
    call s:create_map({
    \ 'mode': mode,
    \ 'mapcmd': (noremap ? 'noremap' : 'map'),
    \ 'options': options,
    \ 'lhs': printf('<Plug>karakuri.enter_with_rhs(%s,%s)', a:submode, lhs),
    \ 'rhs': rhs
    \})
    " <Plug>karakuri.init({submode})
    call s:Map__update_init_mapping(a:this, mode)
  endfor
endfunction

function! s:Map__create_mappings_of_leave_with(this, submode, mapenv) abort
  let modes = s:Map__get_option(a:this, a:mapenv, 'modes')
  let lhs = s:Map__get_option(a:this, a:mapenv, 'lhs')
  for mode in split(modes, '\zs')
    " <Plug>karakuri.leave_with_keyseqs({submode})
    let leave_with_keyseqs = printf('<Plug>karakuri.leave_with_keyseqs(%s)', a:submode)
    let old_rhs = maparg(leave_with_keyseqs, mode, 0)
    let rhs_list = old_rhs !=# '' ? {s:JSON_DECODE}(old_rhs) : []
    call s:create_map({
    \ 'mode': mode,
    \ 'mapcmd': 'noremap',
    \ 'options': '',
    \ 'lhs': leave_with_keyseqs,
    \ 'rhs': {s:JSON_ENCODE}(rhs_list + [lhs])
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
    \ 'lhs': printf('<Plug>karakuri.in(%s)%s', a:submode, lhs),
    \ 'rhs': printf(join(['<Plug>karakuri.map_rhs(%s,%s)',
    \                     '<Plug>karakuri.prompt(%s)',
    \                     '<Plug>karakuri.in(%s)'], ''),
    \               a:submode, lhs, a:submode, a:submode)
    \})
    " <Plug>karakuri.map_rhs({submode},{map-lhs})
    call s:create_map({
    \ 'mode': mode,
    \ 'mapcmd': (noremap ? 'noremap' : 'map'),
    \ 'options': options,
    \ 'lhs': printf('<Plug>karakuri.map_rhs(%s,%s)', a:submode, lhs),
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
  let vim_options = s:Map__build_vim_options(a:this)
  call s:create_map({
  \ 'mode': a:mode,
  \ 'mapcmd': 'noremap',
  \ 'options': '<expr>',
  \ 'lhs': printf('<Plug>karakuri.init(%s)', submode),
  \ 'rhs': printf('<SID>on_entering_submode(%s,%s,%s,%s)',
  \               string(submode), string(a:mode),
  \               string(options), string(vim_options))
  \})
endfunction

function! s:Map__build_vim_options(this) abort
  let vim_options = {}
  for name in ['timeout', 'timeoutlen', 'showmode']
    if has_key(a:this._local, name)
      let vim_options[name] = a:this._local[name]
    endif
  endfor
  return vim_options
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
  call s:Builder__push_map(self._builder, self)
  call s:Builder__construct(self._builder, self, 'enter_with')
  return self
endfunction
call s:method(s:, 'Map', 'enter_with')

function! s:Map_leave_with() abort dict
  call s:Builder__push_map(self._builder, self)
  call s:Builder__construct(self._builder, self, 'leave_with')
  return self
endfunction
call s:method(s:, 'Map', 'leave_with')

function! s:Map_map() abort dict
  call s:Builder__push_map(self._builder, self)
  call s:Builder__construct(self._builder, self, 'map')
  return self
endfunction
call s:method(s:, 'Map', 'map')

function! s:Map_unmap() abort dict
  call s:Builder__push_map(self._builder, self)
  call s:Builder__construct(self._builder, self, 'unmap')
  return self
endfunction
call s:method(s:, 'Map', 'unmap')

function! s:Map_mode(modes) abort dict
  call s:validate_non_empty_string(self._builder._submode, a:modes)
  let pos = match(a:modes, '[^nvoicsxl]')
  if pos isnot -1
    call s:throw(self._builder._submode, "Invalid character '" . a:modes[pos] . "' in the argument of .mode().")
  endif
  let self._map.modes = a:modes
  return self
endfunction
call s:method(s:, 'Map', 'mode')

function! s:Map_lhs(lhs) abort dict
  call s:validate_non_empty_string(self._builder._submode, a:lhs)
  let self._map.lhs = a:lhs
  return self
endfunction
call s:method(s:, 'Map', 'lhs')

function! s:Map_rhs(rhs) abort dict
  call s:validate(self._builder._submode, a:rhs, s:TYPE_STRING)
  let self._map.rhs = a:rhs !=# '' ? a:rhs : '<Nop>'
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

function! s:Map_remap(b) abort dict
  let self._map.noremap = !a:b
  return self
endfunction
call s:method(s:, 'Map', 'remap')

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
  call s:Builder__push_map(self._builder, self)
  for map in self._builder._env
    call s:Map__create_mappings_of_{map.map_type}(self, self._builder._submode, map)
  endfor
endfunction
call s:method(s:, 'Map', 'exec')


" <call-init-func>
function! s:on_entering_submode(submode, mode, options, vim_options) " abort
  " Call on_init() callbacks.
  let ctx = {'submode': a:submode}
  for Init_func in get(a:options, 'on_init', s:MAP_UI_DEFAULT_OPTIONS.on_init)
    call Init_func(ctx)
  endfor
  " Save vim options
  let saved_vim_options = {}
  for name in keys(a:vim_options)
    let saved_vim_options[name] = [bufnr('%'), getbufvar('%', '&' . name)]
    call setbufvar('%', '&' . name, a:vim_options[name])
  endfor
  " Save scope-local variables for:
  " * karakuri#current()
  " * karakuri#restore_options()
  let on_finalize =
  \ get(a:options, 'on_finalize', s:MAP_UI_DEFAULT_OPTIONS.on_finalize)
  let s:running_submodes += [{
  \ 'submode': a:submode,
  \ 'vim_options': saved_vim_options,
  \ 'on_finalize': on_finalize
  \}]

  " <Plug>karakuri.in({submode})
  call s:create_map({
  \ 'mode': a:mode,
  \ 'mapcmd': 'noremap',
  \ 'options': '<expr>',
  \ 'lhs': printf('<Plug>karakuri.in(%s)', a:submode),
  \ 'rhs': printf('<SID>on_fallback_action(%s,%s,%s)',
  \               string(a:submode),
  \               string(saved_vim_options),
  \               string(a:options))
  \})

  " <Plug>karakuri.prompt({submode})
  let on_prompt =
  \ get(a:options, 'on_prompt', s:MAP_UI_DEFAULT_OPTIONS.on_prompt)
  call s:create_map({
  \ 'mode': a:mode,
  \ 'mapcmd': 'noremap',
  \ 'options': '<expr>',
  \ 'lhs': printf('<Plug>karakuri.prompt(%s)', a:submode),
  \ 'rhs': printf('<SID>on_prompt_action(%s,%s)',
  \               string(a:submode), string(on_prompt))
  \})

  " If '<Plug>karakuri.leave_with_keyseqs({submode})' was defined:
  "   Define <Plug>karakuri.in({submode}){leave-with-lhs}
  " Else:
  "   Define <Plug>karakuri.in({submode}){default-keyseqs-to-leave}
  let exist_lhs = printf('<Plug>karakuri.leave_with_keyseqs(%s)', a:submode)
  let leave_lhs = maparg(exist_lhs, a:mode, 0)
  if leave_lhs !=# ''
    let leave_lhs_list = {s:JSON_DECODE}(leave_lhs)
  else
    let leave_lhs_list = deepcopy(s:MAP_UI_DEFAULT_OPTIONS.keyseqs_to_leave)
  endif
  for leave_lhs in leave_lhs_list
    call s:create_map({
    \ 'mode': a:mode,
    \ 'mapcmd': 'noremap',
    \ 'options': '<expr>',
    \ 'lhs': printf('<Plug>karakuri.in(%s)%s', a:submode, leave_lhs),
    \ 'rhs': printf('<SID>on_leaving_submode(%s,%s,%s)',
    \               string(a:submode),
    \               string(saved_vim_options),
    \               string(on_finalize))
    \})
  endfor

  return ''
endfunction

" <call-finalize-func>
function! s:on_leaving_submode(submode, saved_vim_options, on_finalize) " abort
  " Restore vim options
  for name in keys(a:saved_vim_options)
    let [buf, value] = a:saved_vim_options[name]
    call setbufvar(buf, '&' . name, value)
  endfor
  " Clear scope-local variables
  call remove(s:running_submodes, -1)
  " Clear command-line
  redraw
  echo ' '
  " Call on_finalize() callbacks.
  let ctx = {'submode': a:submode}
  for Finalize_func in a:on_finalize
    call Finalize_func(ctx)
  endfor

  return ''
endfunction

" <call-fallback-func>
function! s:on_fallback_action(submode, saved_vim_options, options) " abort
  if getchar(1)
    " {map-lhs} was typed but not matched
    if !get(a:options, 'keep_leaving_key', s:MAP_UI_DEFAULT_OPTIONS.keep_leaving_key)
      call getchar(0)
    endif
    if get(a:options, 'inherit', s:MAP_UI_DEFAULT_OPTIONS.inherit)
      call feedkeys(printf("\<Plug>karakuri.in(%s)", a:submode), 'm')
    endif
  else
    " Timeout
    " Call on_timeout() callbacks.
    let ctx = {'submode': a:submode}
    for Timeout_func in get(a:options, 'on_timeout', s:MAP_UI_DEFAULT_OPTIONS.on_timeout)
      call Timeout_func(ctx)
    endfor
  endif
  let on_finalize = get(a:options, 'on_finalize', s:MAP_UI_DEFAULT_OPTIONS.on_finalize)
  call s:on_leaving_submode(a:submode, a:saved_vim_options, on_finalize)

  return ''
endfunction

" <call-prompt-func>
function! s:on_prompt_action(submode, on_prompt) " abort
  redraw
  echohl ModeMsg
  " Call on_prompt() callbacks.
  let ctx = {'submode': a:submode}
  for Prompt_func in a:on_prompt
    call Prompt_func(ctx)
  endfor
  echohl None
  return ''
endfunction

