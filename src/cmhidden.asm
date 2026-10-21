; CMHIDDEN.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc

    .code

cmahidden proc
    xor config.c_apath.flag,_W_HIDDEN
    panel_update(panela)
    ret
    endp

cmbhidden proc
    xor config.c_bpath.flag,_W_HIDDEN
    panel_update(panelb)
    ret
    endp

cmchidden proc
    .if ( cpanel == panela )
        cmahidden()
    .else
        cmbhidden()
    .endif
    ret
    endp

    END
