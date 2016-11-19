scriptencoding utf-8

"
" Variables
"

let s:running_submodes = []

let s:V = vital#karakuri#new()
let s:State = s:V.import('Mapping.State')
unlet s:V


" The entrance to core logic:
"
" * karakuri#builder(submode : String) : Builder
"

function! karakuri#builder(submode) abort
  return s:State.builder(a:submode)
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
    call s:on_leaving_submode(r.submode, r.vim_options, r.on_finalize)
  endwhile
endfunction

function! karakuri#enter_with(submode, modes, options, lhs, ...) abort
  let map = karakuri#builder(a:submode).enter_with()
  let map = map.mode(a:modes).lhs(a:lhs)
  if a:options !=# ''
    let map = map.parse_compat_options(a:options)
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
    let map = map.parse_compat_options(a:options)
  endif
  call map.exec()
endfunction

function! karakuri#map(submode, modes, options, lhs, rhs) abort
  let map = karakuri#builder(a:submode).map()
  let map = map.mode(a:modes).lhs(a:lhs).rhs(a:rhs)
  if a:options !=# ''
    let map = map.parse_compat_options(a:options)
  endif
  call map.exec()
endfunction

function! karakuri#unmap(submode, modes, options, lhs) abort
  let map = karakuri#builder(a:submode).unmap()
  let map = map.mode(a:modes).lhs(a:lhs)
  if a:options !=# ''
    let map = map.parse_compat_options(a:options)
  endif
  call map.exec()
endfunction
