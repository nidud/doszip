; MATH.ASM--
; Copyright (C) 2015 Doszip Developers

include libc.inc
include math.inc

PUBLIC	__I4D
PUBLIC	__U4D
PUBLIC	__U4M
PUBLIC	__I4M

.code

__U4M:	; dx:ax * cx:bx
__I4M:
_mul32	PROC _CType PUBLIC
	push	bp
	push	si
	push	di
	push	ax
	push	dx
	push	dx
	mul	bx	; 1L * 2L
	mov	si,dx
	mov	di,ax
	pop	ax
	mul	cx	; 1H * 2H
	mov	bp,dx
	xchg	bx,ax
	pop	dx
	mul	dx	; 1H * 2L
	add	si,ax
	adc	bx,dx
	pop	ax
	mul	cx	; 1L * 2H
	add	si,ax
	adc	bx,dx
	adc	bp,0
	mov	cx,bp
	mov	dx,si
	mov	ax,di
	pop	di
	pop	si
	pop	bp
	ret	; cx:bx:dx:ax
_mul32	ENDP

__U4D:	; dx:ax / cx:bx
__I4D:
_div32	PROC _CType PUBLIC
	test	cx,cx
	jnz	DIV_01
	test	dx,dx
	jz	DIV_00
	test	bx,bx
	jnz	DIV_01
DIV_00: div	bx
	mov	bx,dx
	xor	dx,dx
	mov	cx,dx
	ret
DIV_01: push	bp
	push	si
	push	di
	mov	bp,cx
	mov	cx,32
	xor	si,si
	xor	di,di
DIV_02: shl	ax,1
	rcl	dx,1
	rcl	si,1
	rcl	di,1
	cmp	di,bp
	jb	DIV_04
	ja	DIV_03
	cmp	si,bx
	jb	DIV_04
DIV_03: sub	si,bx
	sbb	di,bp
	inc	ax
DIV_04: dec	cx
	jnz	DIV_02
	mov	cx,di
	mov	bx,si
	pop	di
	pop	si
	pop	bp
	ret
_div32	ENDP

_shr32	proc public
	; DX:AX >> CX
	.while dx && cx
	    shr ax,1
	    shr dx,1
	    jnc @F
	    or ah,80h
	  @@:
	    dec cx
	.endw
	.if cx
	    shr ax,cl
	.endif
	ret
_shr32 endp

	END
