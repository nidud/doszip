; EMM.ASM--
; Copyright (C) 2015 Doszip Developers

include alloc.inc
include string.inc

PUBLIC	dzemm

conventional	equ 0
expanded	equ 1
emmpage		equ 4000h

S_EMM		STRUC
dlength		dd ? ; region length in bytes
src_type	db ? ; source memory type
src_handle	dw ? ; 0000h if conventional memory
src_off		dw ? ; within page if EMS, segment if convent
src_seg		dw ? ; segment or logical page (EMS)
des_type	db ? ; destination memory type
des_handle	dw ? ;
des_off		dw ? ; in page
des_seg		dw ? ; or page
S_EMM		ENDS

	.data

emmstate	db 0
dzemm		db 0

	.code

emmalloc PROC _CType PUBLIC pages:word
	push	bx
	mov	bx,pages
	mov	ah,43h
	int	67h
	pop	bx
	test	ah,ah
	jz	@F
	mov	dx,-1
@@:
	mov	ax,dx
	ret
emmalloc ENDP

emmfree PROC _CType PUBLIC handle
	mov	dx,handle	; DX EMM handle
	mov	ah,45h	; RELEASE HANDLE AND MEMORY
	int	67h
	test	ah,ah
	mov	ax,0
	jz	@F
	dec	ax
@@:
	ret
emmfree ENDP

emmversion PROC _CType PUBLIC
	sub ax,ax
	.if emmstate != al
	    mov ah,46h
	    int 67h
	    .if ah
		sub ax,ax
	    .endif
	.endif
	ret
emmversion ENDP

emmnumfreep PROC _CType PUBLIC
	push bx
	.if emmversion()
	    .if dzemm
		mov ax,1024
	    .else
		mov ah,42h	; BX = number of unallocated pages
		int 67h		; DX = total number of pages
		.if ah
		    sub ax,ax
		.else
		    mov ax,bx
		.endif
	    .endif
	.endif
	pop bx
	ret
emmnumfreep ENDP

emmread PROC _CType PUBLIC dest:DWORD, emhnd:size_t, wpage:size_t
local emm:S_EMM
	push	si
	mov	WORD PTR emm.dlength+2,0
	mov	WORD PTR emm.dlength,emmpage
	mov	emm.des_type,conventional
	mov	emm.des_handle,0
	mov	ax,WORD PTR dest
	mov	emm.des_off,ax
	mov	ax,WORD PTR dest+2
	mov	emm.des_seg,ax
	mov	emm.src_type,expanded
	mov	ax,emhnd
	mov	emm.src_handle,ax
	mov	emm.src_off,0
	mov	ax,wpage
	mov	emm.src_seg,ax
	mov	ax,5700h
	lea	si,emm
	int	67h
	mov	al,ah
	mov	ah,0
	pop	si
	ret
emmread ENDP

emmwrite PROC _CType PUBLIC src:DWORD, emhnd:size_t, wpage:size_t
local emm:S_EMM
	push	si
	mov	WORD PTR emm.dlength+2,0
	mov	WORD PTR emm.dlength,emmpage
	mov	emm.src_type,conventional
	mov	emm.src_handle,0
	mov	ax,WORD PTR src
	mov	emm.src_off,ax
	mov	ax,WORD PTR src+2
	mov	emm.src_seg,ax
	mov	emm.des_type,expanded
	mov	ax,emhnd
	mov	emm.des_handle,ax
	mov	emm.des_off,0
	mov	ax,wpage
	mov	emm.des_seg,ax
	mov	ax,5700h
	lea	si,emm
	int	67h
	mov	al,ah
	mov	ah,0
	pop	si
	ret
emmwrite ENDP

emminit:
	mov	ah,35h
	mov	al,67h
	int	21h
	mov	bx,10
	mov	ax,es:[bx]
	cmp	ax,'ME'
	jne	@F
	mov	ax,es:[bx+2]
	cmp	ax,'XM'
	jne	@F
	mov	ah,46h		; get EMM version
	int	67h
	test	ah,ah
	jnz	@F
	cmp	al,40h		; 4.0
	jb	@F
	inc	emmstate
	mov	ax,4000h	; get DZEMM state
	int	67h		; return AX = 0001
	dec	ax
	jnz	@F
	inc	dzemm
      @@:
	ret

pragma_init emminit, 6

	END
