
let s:popsyntax_on = 0
function! popsyntax#popsyntax_toggle() abort
    if s:popsyntax_on == 0
        let s:popsyntax_on = 1
        call popsyntax#popsyntax_on()
    else
        let s:popsyntax_on = 0
        call popsyntax#popsyntax_off()
    endif
endfunction

let s:pwid = 0
function! popsyntax#open_popup() abort
    let cword = expand('<cword>')
    if s:pwid > 0
        if exists('*popup_close')
            call popup_close(s:pwid)
        elseif has('nvim')
            call nvim_win_close(s:pwid, v:false)
        endif
        let s:pwid = 0
    endif
    if cword != ''
        if has('gui_running')
            let trm = 'gui'
        else
            let trm = 'cterm'
        endif

        let baseSyn = s:get_syn_attr(s:get_syn_id(0))
        let s_info = "name: " . baseSyn.name
        if baseSyn.termfg != ''
            let s_info .= "   ".trm."fg: " . baseSyn.termfg
        endif
        if baseSyn.termbg != ''
            let s_info .= "   ".trm."bg: " . baseSyn.termbg
        endif
        if baseSyn.termopt != ''
            let s_info .= "   ".trm.": " . baseSyn.termopt
        endif
        let popup_text = [s_info]

        if s:get_syn_id(0) != s:get_syn_id(1)
            let linkedSyn = s:get_syn_attr(s:get_syn_id(1))
            let link_info = "=> name: " . linkedSyn.name
            if linkedSyn.termfg != ""
                let link_info .= "   ".trm."fg: " . linkedSyn.termfg
            endif
            if linkedSyn.termbg != ""
                let link_info .= "   ".trm."bg: " . linkedSyn.termbg
            endif
            if linkedSyn.termopt != ""
                let link_info .= "   ".trm.": " . linkedSyn.termopt
            endif
            " let s_info = '   '.s_info
            let popup_text = [s_info, link_info]
        endif

        if exists('*popup_create')
            let s:pwid = popup_create(popup_text, #{
                        \ maxheight: 3,
                        \ close: 'click',
                        \ line: 'cursor-1',
                        \ col: 'cursor',
                        \ pos: 'botleft',
                        \})

        elseif has('nvim')
            let width = len(popup_text[0])
            if len(popup_text)==2 && width<len(popup_text[1])
                let width = len(popup_text[1])
            endif
            let config = {
                        \ 'relative': 'cursor',
                        \ 'anchor': 'NW',
                        \ 'row': 1,
                        \ 'col': 0,
                        \ 'height': len(popup_text),
                        \ 'width': width,
                        \ 'style': 'minimal',
                        \ 'focusable': v:false,
                        \ }
            let bufnr = nvim_create_buf(v:false, v:true)
            let s:pwid = nvim_open_win(bufnr, v:false, config)
            let winnr = win_id2win(s:pwid)
            execute winnr.'windo call append(0, popup_text)'
            execute winnr.'windo normal! gg'
            execute winnr.'windo wincmd p'

        endif
    endif
endfunction

function! s:get_syn_id(transparent) abort
  let synid = synID(line("."), col("."), 1)
  if a:transparent
    return synIDtrans(synid)
  else
    return synid
  endif
endfunction

function! s:get_syn_attr(synid) abort
  let name = synIDattr(a:synid, "name")
  if has('gui_running')
      let termfg = synIDattr(a:synid, "fg#", "gui")
      let termbg = synIDattr(a:synid, "bg#", "gui")
      let trm = 'gui'
  else
      let termfg = synIDattr(a:synid, "fg", "cterm")
      let termbg = synIDattr(a:synid, "bg", "cterm")
      let trm = 'cterm'
  endif

  let termopt = ''
  let termopts = ['bold', 'italic', 'reverse', 'inverse', 'standout', 'underline', 'undercurl', 'strike']
  for topt in termopts
      if synIDattr(a:synid, topt, trm) == '1'
          let termopt .= topt.','
      endif
  endfor
  if len(termopt) > 0
      let termopt = termopt[:-2]
  endif

  return {
        \ "name": name,
        \ "termfg": termfg,
        \ "termbg": termbg,
        \ 'termopt': termopt,
        \ }
endfunction

function! popsyntax#popsyntax_on() abort
    augroup popsyntax
        autocmd!
        autocmd CursorMoved * call popsyntax#open_popup()
    augroup end
endfunction

function! popsyntax#popsyntax_off() abort
    if exists('*popup_close')
        call popup_close(s:pwid)
    elseif has('nvim')
        call nvim_win_close(s:pwid, v:false)
    endif
    let s:pwid = 0
    augroup popsyntax
        autocmd!
    augroup end
endfunction

