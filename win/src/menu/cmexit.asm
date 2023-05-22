; CMEXIT.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include conio.inc

    .code

cmquit proc
    mov mainswitch,0
    mov dzexitcode,1
    ret
cmquit endp

cmexit proc
    .if config.c_cflag & _C_CONFEXIT
	.if !rsmodal(IDD_DZExit)
	    .return
	.endif
    .endif
    cmquit()
    ret
cmexit endp

    END
