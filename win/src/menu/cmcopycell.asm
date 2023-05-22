; CMCOPYCELL.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include string.inc
include io.inc

    .code

ccedit proc private uses rsi rdi copy:int_t ; rename or copy current file to a new name

    .if panel_curobj(cpanel)

	mov rdi,rdx
	.if !( ecx & _FB_UPDIR or _FB_ROOTDIR )

	    .if ( ecx & _FB_ARCHIVE )

		notsup()
	    .else


		strcpy(__outfile, strcpy(__srcfile, rax))

		.if ( byte ptr [rax] != 0 )

		    mov rax,cpanel
		    mov rsi,[rax].PANEL.xl
		    movzx eax,[rsi].XCEL.rc.col
		    movzx ecx,[rsi].XCEL.rc.x
		    movzx edx,[rsi].XCEL.rc.y
		    scputw(ecx, edx, eax, 0x00070020)

		    .if dledit(__outfile, [rsi].XCEL.rc, _MAX_PATH-1, 0) != KEY_ESC

			.if strcmp(__outfile, __srcfile)

			    mov rax,__outfile
			    mov al,[rax]
			    .if al
				.if copy

				    mov eax,[rdi]
				    .if !( eax & _FB_ARCHIVE )

					copyfile([rdi].FBLK.size, [rdi].FBLK.time, eax)
				    .endif
				.else
				    rename(__srcfile, __outfile)
				.endif
			    .endif
			.endif
		    .endif
		.endif
		mov rax,cpanel
		.if dlclose([rax].PANEL.xl)
		    pcell_show(cpanel)
		.endif
		mov eax,1
	    .endif
	.else
	    xor eax,eax
	.endif
    .endif
    ret

ccedit endp

cmcopycell proc
    ccedit(1)
    ret
cmcopycell endp

cmrename proc
    ccedit(0)
    ret
cmrename endp

    END
