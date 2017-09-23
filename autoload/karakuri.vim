scriptencoding utf-8

"
" Variables
"

let s:running_submodes = []

let s:V = vital#karakuri#new()
let s:State = s:V.import('Mapping.State')
unlet s:V


"
" Utilities
"

function! s:push_running_submode(ctx) abort
  let s:running_submodes += [a:ctx]
endfunction

function! s:pop_running_submode(ctx) abort
  if !empty(s:running_submodes) &&
  \ a:ctx.submode ==# s:running_submodes[-1].submode
    call remove(s:running_submodes, -1)
  else
    call s:throw(a:ctx.submode, 'submode of top of the stack is mismatch: '
    \          . 's:running_submodes = ' . string(s:running_submodes))
  endif
endfunction

function! s:throw(submode, msg) abort
  throw 'karakuri: ' . a:submode . ': ' . a:msg
endfunction

function! s:SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
let s:SIDP = s:SID()
delfunction s:SID


" karakuri#define(submode : String, def : Dictionary) : Unit
"   Define {def} as {submode}'s definition.
"   It creates set of mappings.
"   If {submode}'s definition exists already, it will be overwritten.

function! karakuri#define(submode, def) abort
  call s:State.define(a:submode, a:def)
        \.on_init(function('<SNR>' . s:SIDP . '_push_running_submode'))
        \.on_finalize(function('<SNR>' . s:SIDP . '_pop_running_submode'))
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
  if !empty(s:running_submodes)
    return s:running_submodes[-1].submode
  endif
endfunction

function! karakuri#restore_options() abort
  while !empty(s:running_submodes)
    let r = remove(s:running_submodes, -1)
    call s:State.on_leaving_submode(r.submode, r.vim_options, r.on_finalize)
  endwhile
endfunction

function! karakuri#enter_with(submode, modes, options, lhs, ...) abort
  let map = {'mode': a:modes, 'lhs': a:lhs}
  if a:options !=# ''
    call extend(map, s:parse_compat_options(a:options))
  endif
  if a:0
    let map.rhs = a:1
  endif
  call karakuri#define(a:submode, {'enter_with': [map]})
endfunction

function! karakuri#leave_with(submode, modes, options, lhs) abort
  let map = {'mode': a:modes, 'lhs': a:lhs}
  if a:options !=# ''
    call extend(map, s:parse_compat_options(a:options))
  endif
  call karakuri#define(a:submode, {'leave_with': [map]})
endfunction

function! karakuri#map(submode, modes, options, lhs, rhs) abort
  let map = {'mode': a:modes, 'lhs': a:lhs, 'rhs': a:rhs}
  if a:options !=# ''
    call extend(map, s:parse_compat_options(a:options))
  endif
  call karakuri#define(a:submode, {'map': [map]})
endfunction

function! karakuri#unmap(submode, modes, options, lhs) abort
  let map = {'mode': a:modes, 'lhs': a:lhs}
  if a:options !=# ''
    call extend(map, s:parse_compat_options(a:options))
  endif
  call karakuri#define(a:submode, {'unmap': [map]})
endfunction


let s:COMPAT_OPTIONS = {
\ 'b': {'buffer': 1},
\ 'e': {'expr': 1},
\ 'r': {'noremap': 0},
\ 's': {'silent': 1},
\ 'u': {'unique': 1},
\ 'x': {'keep_leaving_key': 1}
\}

function! s:parse_compat_options(options) abort
  let opts = {}
  for c in split(a:options, '\zs')
    call extend(opts, get(s:COMPAT_OPTIONS, c, {}))
  endfor
  return opts
endfunction
