
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

let s:pwid = -1
if has('nvim')
    let s:bufnr = -1
endif
function! popsyntax#open_popup() abort
    let cword = expand('<cword>')
    if cword != ''
        let popup_text = s:get_syntax_text()
        if exists('g:popsyntax_match_enable') && g:popsyntax_match_enable
            let popup_text += s:get_match_info()
        endif
        if has('popupwin')
            if s:pwid < 0
                let s:pwid = popup_create(popup_text, #{
                            \ maxheight: 3,
                            \ close: 'none',
                            \ line: 'cursor+1',
                            \ col: 'cursor',
                            \ pos: 'topleft',
                            \})
            else
                call popup_settext(s:pwid, popup_text)
                call popup_setoptions(s:pwid, #{
                            \ line: 'cursor+1',
                            \ col: 'cursor',
                            \})
            endif

        elseif has('nvim')
            let width = 0
            for i in range(len(popup_text))
                if width < len(popup_text[i])
                    let width = len(popup_text[i])
                endif
            endfor
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
            if s:bufnr < 0
                let s:bufnr = nvim_create_buf(v:false, v:true)
            endif
            if s:pwid < 0
                let s:pwid = nvim_open_win(s:bufnr, v:false, config)
            else
                call nvim_win_set_config(s:pwid, config)
            endif
            call nvim_buf_set_lines(s:bufnr, 0, -1, 0, popup_text)
        endif
    else
        call popsyntax#close_popup()
    endif
endfunction

function! popsyntax#close_popup()
    if s:pwid < 0
        return
    endif
    if exists('*popup_close')
        if match(popup_list(), s:pwid) != -1
            call popup_close(s:pwid)
        endif
    elseif has('nvim')
        if (match(nvim_list_wins(),s:pwid)!=-1) && !empty(nvim_win_get_config(s:pwid)['relative'])
            call nvim_win_close(s:pwid, v:false)
        endif
    endif
    let s:pwid = -1
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
    if has('gui_running') || (has('termguicolors') && &termguicolors)
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

function! s:get_syntax_text() abort
    if has('gui_running') || (has('termguicolors') && &termguicolors)
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
        " let popup_text = [s_info, link_info]
        call add(popup_text, link_info)
    endif
    return popup_text
endfunction

function! s:get_match_info() abort
    let match_info = []
    let cword = expand('<cword>')
    let matches = getmatches()
    for m in matches
        if has_key(m, 'pattern')
            if cword =~# m.pattern
                let info = printf('match (pattern)|| %s', m.group)
                call add(match_info, info)
            endif
        elseif has_key(m, 'pos1')
            if len(m.pos1) == 1
                if m.pos1[0] == line('.')
                    let info = printf('match (pos)|| %s', m.group)
                    call add(match_info, info)
                endif
            elseif len(m.pos1) == 3
                if m.pos1 == [line('.'), col('.'), 1] " 1?
                    let info = printf('match (pos)|| %s', m.group)
                    call add(match_info, info)
                endif
            endif
        endif
    endfor
    return match_info
endfunction

function! popsyntax#popsyntax_on() abort
    augroup popsyntax
        autocmd!
        autocmd CursorMoved * call popsyntax#open_popup()
        autocmd InsertEnter * call popsyntax#close_popup()
        autocmd TabEnter * call popsyntax#open_popup()
        autocmd TabLeave * call popsyntax#close_popup()
    augroup end
endfunction

function! popsyntax#popsyntax_off() abort
    call popsyntax#close_popup()
    augroup popsyntax
        autocmd!
    augroup end
endfunction

