; CURSOR.ASM--
; Copyright (C) 2015 Doszip Developers

include conio.inc

.code

cursoroff PROC _CType PUBLIC
	push	ax
	push	cx
	mov	cx,CURSOR_HIDDEN
	mov	ax,0103h
	int	10h
	pop	cx
	pop	ax
	ret
cursoroff ENDP

cursoron PROC _CType PUBLIC
	push	ax
	push	cx
	mov	cx,CURSOR_NORMAL
	mov	ah,1
	int	10h
	pop	cx
	pop	ax
	ret
cursoron ENDP

cursorx PROC _CType PUBLIC
	push	bx
	mov	bh,0
	mov	ah,3
	int	10h
	xor	ax,ax
	mov	al,dl
	mov	dl,dh
	mov	dh,0
	pop	bx
	ret
cursorx ENDP

cursory PROC _CType PUBLIC
	push	bx
	mov	bh,0
	mov	ah,3
	int	10h
	xor	ax,ax
	mov	al,dh
	pop	bx
	ret
cursory ENDP

gotoxy	PROC _CType PUBLIC x:size_t, y:size_t
	push	bx
	mov	dh,BYTE PTR y
	mov	dl,BYTE PTR x
	mov	bh,0
	mov	ah,2
	int	10h
	pop	bx
	ret
gotoxy	ENDP

cursorget PROC _CType PUBLIC USES bx cursor:DWORD
	mov	ah,3
	mov	bh,0
	int	10h
	xor	ax,ax
	les	bx,cursor
	mov	es:[bx],dx
	mov	es:[bx+2],cx
	cmp	cx,CURSOR_HIDDEN
	je	@F
	inc	ax
      @@:
	ret
cursorget ENDP

cursorset PROC _CType PUBLIC USES ax cursor:DWORD
	push	bx
	push	cx
	push	dx
	les	bx,cursor
	mov	cx,es:[bx].S_CURSOR.cr_type
	push	es:[bx].S_CURSOR.cr_xy
	mov	ah,1
	mov	bh,0
	int	10h
	pop	dx
	mov	ah,2
	int	10h
	pop	dx
	pop	cx
	pop	bx
	ret
cursorset ENDP

	END
