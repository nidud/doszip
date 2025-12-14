; TWTOSTR.ASM--
; Copyright (C) 2015 Doszip Developers

include time.inc

.code

twtostr PROC _CType PUBLIC USES cx string:DWORD, timew:size_t
	push	bx
	les	bx,string
	mov	cl,time_separator
	mov	ax,timew
	shr	ax,11
	and	ax,001Fh
	call	putedxal
	mov	es:[bx],cl
	inc	bx
	mov	ax,timew
	shr	ax,5
	and	ax,003Fh
	call	putedxal
	mov	es:[bx],cl
	inc	bx
	mov	ax,timew
	and	ax,001Fh
	shl	ax,1
	call	putedxal
	mov	byte ptr es:[bx],0
	mov	dx,es
	mov	ax,WORD PTR string
	pop	bx
	ret
twtostr ENDP

	END
