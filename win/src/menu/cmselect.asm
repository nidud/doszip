; CMSELECT.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include string.inc

    .code

cmselect proc uses rsi rdi

    .if !cp_selectmask

	strcpy(&cp_selectmask, &cp_stdmask)
    .endif

    .if tgetline("Select files", &cp_selectmask, 12, 32+8000h)

	.if cp_selectmask

	    .if panel_state(cpanel)

		mov rdi,[rax].PANEL.wsub
		mov esi,[rax].PANEL.fcb_count
		mov rdi,[rdi].WSUB.fcb

		.while esi

		    mov rax,[rdi]

		    .if cmpwarg(&[rax].FBLK.name, &cp_selectmask)

			fblk_select([rdi])
		    .endif

		    add rdi,PFBLK
		    dec esi
		.endw

		panel_putitem(cpanel, 0)
		mov eax,1
	    .endif
	.endif
    .endif
    ret
cmselect endp

cmdeselect proc uses rsi rdi

    .if !cp_selectmask

	strcpy(&cp_selectmask, &cp_stdmask)
    .endif

    .if tgetline("Deselect files", &cp_selectmask, 12, 32+8000h)

	.if cp_selectmask

	    .if panel_state(cpanel)

		mov rdi,[rax].PANEL.wsub
		mov esi,[rax].PANEL.fcb_count
		mov rdi,[rdi].WSUB.fcb

		.while esi

		    mov rax,[rdi]
		    add rax,FBLK.name

		    .if cmpwarg(rax, &cp_selectmask)

			mov rax,[rdi]
			and [rax].FBLK.flag,not _FB_SELECTED
		    .endif
		    add rdi,PFBLK
		    dec esi
		.endw

		panel_putitem(cpanel, 0)
		mov eax,1
	    .endif
	.endif
    .endif
    ret
cmdeselect endp

cminvert proc uses rsi rdi

    .if panel_state(cpanel)

	mov rdi,[rax].PANEL.wsub
	mov esi,[rax].PANEL.fcb_count
	mov rdi,[rdi].WSUB.fcb

	.while esi

	    fblk_invert([rdi])
	    add rdi,PFBLK
	    dec esi
	.endw

	panel_putitem(cpanel, 0)
	mov eax,1
    .endif
    ret
cminvert endp

    END
