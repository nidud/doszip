; CMWIDEVIEW.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc

    .code

cmwideview proc fastcall private panel:PPANEL

    mov rdx,[rcx].PANEL.wsub
    mov eax,[rdx].WSUB.flag
    and eax,not _W_DETAIL
    xor eax,_W_WIDEVIEW
    mov [rdx].WSUB.flag,eax
    panel_redraw(rcx)
    ret

cmwideview endp

cmawideview proc
    .return cmwideview(panela)
cmawideview endp

cmbwideview proc
    .return cmwideview(panelb)
cmbwideview endp

cmcwideview proc
    .return cmwideview(cpanel)
cmcwideview endp

    END
