; _IOINIT.ASM--
; Copyright (C) 2015 Doszip Developers

include io.inc
include dos.inc
include errno.inc
include conio.inc

extrn	_psp:WORD
PUBLIC	_nfile
PUBLIC	_osfile

.data

_nfile	dw _NFILE_
_osfile db FH_OPEN or FH_DEVICE or FH_TEXT
	db FH_OPEN or FH_DEVICE or FH_TEXT
	db FH_OPEN or FH_DEVICE or FH_TEXT
	db _NFILE_ - 3 dup(0)

	.code

osopen	PROC _CType PUBLIC fname:DWORD, attrib:size_t, mode:size_t, action:size_t
	push	si
	push	di
	push	ds
ifdef __LFN__
	stc
	cmp	_ifsmgr,0
	mov	ax,716Ch
endif
	lds	si,fname
	mov	bx,mode
	mov	cx,attrib
	mov	dx,action
ifdef __LFN__
	jnz	osopen_21h
endif
	mov	ax,6C00h	; DOS 4.0+ - EXTENDED OPEN/CREATE
	test	BYTE PTR ss:console,CON_DOSIO
	jz	osopen_21h
	mov	ah,3Dh		; DOS 2+ - OPEN EXISTING FILE
	mov	al,bl
	test	dl,A_TRUNC or A_CREATE
	xchg	dx,si
	jz	osopen_21h
	dec	ah		; DOS 2+ - CREATE OR TRUNCATE FILE
	test	si,A_TRUNC
	jnz	osopen_21h
	mov	ah,43h		; Create a new file - test if exist
	int	21h
	jnc	osopen_error_exist
	mov	ah,3Ch
	mov	cx,attrib
	cmp	al,2		; file not found
	je	osopen_21h
	mov	si,dx		; Windows for Workgroups bug
	mov	dx,action
	mov	ax,6C00h
    osopen_21h:
	int	21h
	pop	ds
	jc	osopen_error
	cmp	ax,_nfile
	jnb	osopen_error_ebadf
	mov	bx,ax
	or	BYTE PTR [bx+_osfile],FH_OPEN
    osopen_end:
	pop	di
	pop	si
	ret
    osopen_error_ebadf:
	push	ax
	sub	ax,ax
	mov	doserrno,ax	; no OS error
	mov	al,EBADF
	mov	errno,ax
	call	close
	jmp	osopen_user_error
    osopen_error_exist:
	pop	ds
	mov	ax,50h		; file exists
    osopen_error:
	call	osmaperr
    osopen_user_error:
	mov	ax,-1
	jmp	osopen_end
osopen	ENDP

close	PROC _CType PUBLIC handle:size_t
	push	ax
	mov	ax,handle
	.if ax < 3 || ax > _nfile
	    mov errno,EBADF
	    mov doserrno,0
	    sub ax,ax
	.else
	    push bx
	    mov bx,ax
	    mov _osfile[bx],0
	    mov ah,3Eh
	    int 21h
	    pop bx
	    .if CARRY?
		call osmaperr
	    .else
		sub ax,ax
	    .endif
	.endif
	pop dx
	ret
close	ENDP

access	PROC _CType PUBLIC fname:DWORD, amode:size_t
	.if getfattr(fname) != -1
	    .if amode == 2 && ax & _A_RDONLY
		mov ax,-1
	    .else
		sub ax,ax
	    .endif
	.endif
	ret
access	ENDP

lseek	PROC _CType PUBLIC handle:size_t, offs:DWORD, pos:size_t
	mov ax,4200h
	add ax,pos
	mov bx,handle
	mov cx,WORD PTR offs+2
	mov dx,WORD PTR offs
	int 21h
	.if CARRY?
	  @@:
	    call osmaperr
	    cwd
	.elseif ax == -1 && dx == -1
	    xor cx,cx
	    mov dx,cx
	    mov ax,4200h
	    int 21h
	    mov ax,ER_NEGATIVE_SEEK
	    jmp @B
	.endif
	ret
lseek	ENDP

osread	PROC _CType PUBLIC h:size_t, b:DWORD, z:size_t
	stc
	push	ds
	mov	ax,3F00h
	mov	bx,h
	mov	cx,z
	lds	dx,b
	int	21h
	pop	ds
	jc	osread_error
    osread_end:
	ret
    osread_error:
	call	osmaperr
	sub	ax,ax
	jmp	osread_end
	ret
osread	ENDP

oswrite PROC _CType PUBLIC h:size_t, b:DWORD, z:size_t
	push	ds
	push	bx
	lds	dx,b
	mov	bx,h
	mov	cx,z
	mov	ax,4000h
	int	21h
	pop	bx
	pop	ds
	jc	oswrite_error
	cmp	ax,cx
	jne	oswrite_ersize
    oswrite_end:
	ret
    oswrite_ersize:
	mov	ax,ER_DISK_FULL
    oswrite_error:
	call	osmaperr
	xor	ax,ax
	jmp	oswrite_end
	ret
oswrite ENDP

write PROC _CType PUBLIC USES di si bx h:size_t, b:DWORD, l:size_t
local lb[1026]:BYTE
local count:size_t
local result:size_t
	mov ax,l
	mov bx,h
	.if ax
	    .if bx < _NFILE_
		.if [bx+_osfile] & FH_APPEND
		    invoke lseek,h,0,SEEK_END
		.endif
		sub ax,ax
		mov result,ax
		mov count,ax
		.if [bx+_osfile] & FH_TEXT
		    les si,b
		  write_04:
		    mov ax,si
		    sub ax,WORD PTR b
		    .if ax < l
			lea di,lb
		      @@:
			lea dx,lb
			mov ax,di
			sub ax,dx
			.if ax < 1024
			    mov ax,si
			    sub ax,WORD PTR b
			    .if ax < l
				mov al,es:[si]
				.if al == 10
				    mov BYTE PTR [di],13
				    inc di
				.endif
				mov [di],al
				inc si
				inc di
				inc count
				jmp @B
			    .endif
			.endif
			lea ax,lb
			mov dx,di
			sub dx,ax
			invoke oswrite,h,addr lb,dx
			.if ax
			    lea cx,lb
			    mov dx,di
			    sub dx,cx
			    cmp ax,dx
			    jb	write_11
			    jmp write_04
			.endif
			jmp write_09
		    .endif
		    jmp write_11
		.endif
		invoke oswrite,h,b,l
		test ax,ax
		jz write_09
		mov result,0
		mov count,ax
	    .else
		sub ax,ax
		mov doserrno,ax
		mov errno,EBADF
		dec ax
	    .endif
	.endif
    write_15:
	ret
    write_09:
	inc	result
    write_11:
	mov	ax,count
	test	ax,ax
	jnz	write_15
	cmp	ax,result
	jne	write_13
	cmp	doserrno,5	; access denied
	jne	write_12
	mov	errno,EBADF
    write_12:
	mov	ax,-1
	jmp	write_15
    write_13:
	test	[bx+_osfile],FH_DEVICE
	jz	write_14
	les	bx,b
	cmp	BYTE PTR es:[bx],26
	jne	write_14
	sub	ax,ax
	jmp	write_15
    write_14:
	mov	errno,ENOSPC
	mov	doserrno,0
	mov	ax,-1
	jmp	write_15
write	ENDP

readword PROC _CType PUBLIC file:DWORD
local result:DWORD
	.if osopen(file,0,M_RDONLY,A_OPEN) != -1
	    push ax
	    mov cx,ax
	    invoke osread,cx,addr result,4
	    pop cx
	    push ax
	    invoke close,cx
	    pop ax
	.else
	    dec ax
	.endif
	.if ax > 1
	    lodm result
	.else
	    sub ax,ax
	    mov dx,ax
	.endif
	ret
readword ENDP

_ioinit PROC PRIVATE
	push	di
	push	si
	cmp	_nfile,5
	jbe	ioinit_03
	mov	es,_psp
	mov	di,29
	mov	si,offset _osfile
	mov	cx,5
	add	si,cx
    ioinit_00:
	mov	al,es:[di]
	cmp	al,0FFh
	je	ioinit_01
	or	BYTE PTR [si],(FH_TEXT or FH_OPEN)
	mov	ax,4400h
	mov	bx,cx
	int	21h
	and	dx,128
	jz	ioinit_02
	or	BYTE PTR [si],FH_DEVICE
	jmp	ioinit_02
    ioinit_01:
	mov	BYTE PTR [si],0
    ioinit_02:
	inc	si
	inc	di
	inc	cx
	cmp	cx,_nfile
	jb	ioinit_00
    ioinit_03:
	pop	si
	pop	di
	ret
_ioinit ENDP

pragma_init _ioinit, 1

	END
