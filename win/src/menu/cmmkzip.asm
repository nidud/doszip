; CMMKZIP.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include io.inc
include string.inc
include wsub.inc

    .data
     default_zip char_t "default.zip", 128-11 dup(0)

    .code

cmmkzip proc uses rsi rdi

  local path[_MAX_PATH]:byte

    lea rdi,path
    .if cpanel_state()

	.ifd tgetline("Create archive", strcpy(rdi, &default_zip), 40, 256 or 8000h)

	    .if byte ptr [rdi]

		.ifsd ogetouth(rdi, M_WRONLY) > 0

		    mov esi,eax
		    strcpy(&default_zip, rdi)

		    mov rax,cpanel
		    mov rdx,[rax].PANEL.wsub
		    mov rax,[rdx].WSUB.arch
		    mov byte ptr [rax],0
		    mov eax,[rdx].WSUB.flag
		    and eax,not _W_ARCHIVE
		    or	eax,_W_ARCHZIP
		    mov [rdx].WSUB.flag,eax
		    mov rcx,[rdx].WSUB.file
		    strcpy(rcx, &path)

		    mov rdx,rdi
		    mov eax,06054B50h
		    stosd
		    xor eax,eax
		    mov ecx,5
		    rep stosd

		    oswrite(esi, rdx, ZEND)
		    _close(esi)
		    mov _diskflag,1
		.endif
	    .endif
	.endif
    .endif
    ret

cmmkzip endp

    END
