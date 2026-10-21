; CMUPDATE.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc

    .code

cmaupdate proc
    panel_reread(panela)
    ret
    endp

cmbupdate proc
    panel_reread(panelb)
    ret
    endp

cmcupdate proc
    panel_reread(cpanel)
    ret
    endp

    END
