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
call karakuri#builder('undo/redo')
  \.keep_leaving_key(v:false)
  \.always_show_submode(v:true)
  \.enter_with().mode('n').lhs('g-').rhs('g-')
  \.enter_with().mode('n').lhs('g+').rhs('g+')
  \.map().mode('n').lhs('-').rhs('g-')
  \.map().mode('n').lhs('+').rhs('g+')
  \.exec()

