; DRVEXIST.ASM--
; Copyright (C) 2015 Doszip Developers

include dir.inc
include dos.inc
include errno.inc

	option dotname

	.data
	 stdpath db "C:\NUL",0

	.code

_disk_exist PROC _CType PUBLIC disk:size_t

	mov	ax,disk
	add	al,'A'
	mov	cp_stdpath,al
	mov	sys_erflag,0
	mov	sys_erdrive,0
	mov	sys_ercode,0
	mov	ax,4E00h
	mov	dx,offset cp_stdpath
	mov	cx,07Fh
	int	21h	; hard error if not exist..
	jnc	.1
	cmp	ax,18	; No more files to be found
	jne	.0
	mov	cx,sys_ercode
	or	cl,sys_erflag
	or	cl,sys_erdrive
	test	cx,cx
	jnz	.0
	mov	al,cp_stdpath
	mov	stdpath,al
	mov	ax,4E00h
	mov	dx,offset stdpath
	mov	cx,07Fh
	int	21h
	jc	.0
.1:
	mov	ax,1
.2:
	test	ax,ax
	ret
.0:
	call	osmaperr
	xor	ax,ax
	jmp	.2

_disk_exist ENDP

	END
