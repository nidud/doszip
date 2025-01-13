; CMLONG.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc

    .code

cmlong proc fastcall private panel:PPANEL
    mov rdx,[rcx].PANEL.wsub
    xor [rdx].WSUB.flag,_W_LONGNAME
    panel_update(rcx)
    ret
cmlong endp

cmalong proc
    .return cmlong(panela)
cmalong endp

cmblong proc
    .return cmlong(panelb)
cmblong endp

cmclong proc
    .return cmlong(cpanel)
cmclong endp

    END
