; CMDETAIL.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc

    .code

cmdetail proc private

    mov rdx,[rcx].PANEL.wsub
    mov eax,[rdx].WSUB.flag
    and eax,not _W_WIDEVIEW
    xor eax,_W_DETAIL
    mov [rdx].WSUB.flag,eax
    panel_redraw(rcx)
    ret

cmdetail endp

cmadetail proc
    mov rcx,panela
    cmdetail()
    ret
cmadetail endp

cmbdetail proc
    mov rcx,panelb
    cmdetail()
    ret
cmbdetail endp

cmcdetail proc
    mov rcx,cpanel
    cmdetail()
    ret
cmcdetail endp

    END
