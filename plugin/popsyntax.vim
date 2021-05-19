
if exists('g:loaded_popsyntax')
    finish
endif

let g:loaded_popsyntax = 1

command! PopSyntaxToggle call popsyntax#popsyntax_toggle()

