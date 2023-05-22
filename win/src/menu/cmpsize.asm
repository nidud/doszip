; CMPSIZE.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc

    .code

cmpsizeup proc

    mov rdx,panela
    mov rdx,[rdx].PANEL.dialog
    mov al,9
    .if cflag & _C_HORIZONTAL
        dec al
    .endif
    .if [rdx+7] != al

        inc byte ptr config.c_panelsize
        redraw_panels()
    .endif
    ret

cmpsizeup endp

cmpsizedn proc

    xor eax,eax
    .if eax != config.c_panelsize

        dec config.c_panelsize
        redraw_panels()
    .endif
    ret

cmpsizedn endp

    END
