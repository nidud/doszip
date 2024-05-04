; CMMKDIR.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include errno.inc

    .code

cmmkdir proc uses rsi rdi rbx

  local path[512]:byte

    lea rbx,path
    mov rax,cpanel
    mov rsi,[rax].PANEL.wsub
    mov edi,[rsi].WSUB.flag

    .if !( edi & _W_ROOTDIR )

	.if panel_state(rax)

	    mov byte ptr [rbx],0
	    .ifd tgetline("Make directory", rbx, 40, 512)

		xor eax,eax
		.if [rbx] != al

		    .if edi & _W_ARCHZIP

			wsmkzipdir(rsi, rbx)

		    .elseif _mkdir(rbx)

			ermkdir(rbx)
		    .endif
		.endif
	    .endif
	.endif
    .endif
    ret

cmmkdir endp

    end
