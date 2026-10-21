; CMMINI.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc

    .code

cmamini proc
    panel_xormini(panela)
    ret
    endp
cmbmini proc
    panel_xormini(panelb)
    ret
    endp
cmcmini proc
    panel_xormini(cpanel)
    ret
    endp
cmvolinfo proc
    panel_xorinfo(cpanel)
    ret
    endp
cmavolinfo proc
    panel_xorinfo(panela)
    ret
    endp
cmbvolinfo proc
    panel_xorinfo(panelb)
    ret
    endp

    END
