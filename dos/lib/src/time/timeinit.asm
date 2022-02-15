; TIMEINIT.ASM--
; Copyright (C) 2015 Doszip Developers

include time.inc

public		dos_dateformat
externdef	cp_datefrm:byte

.data
dos_dateformat db DFORMAT_EUROPE

.code

timeinit PROC PRIVATE
LOCAL	country_info[64]:byte
	push	ds
	push	ss
	pop	ds
	mov	country_info,DFORMAT_EUROPE
	lea	dx,country_info
	mov	ax,3800h
	int	21h
	pop	ds
	jc	toend
	mov	al,country_info
	mov	dos_dateformat,al
	cmp	al,DFORMAT_EUROPE
	je	toend
	push	bx
	lea	bx,cp_datefrm
	mov	al,'/'
	mov	[bx+3],al ; "%2u.%02u.%02u"
	mov	[bx+8],al
	pop	bx
toend:
	ret
timeinit ENDP

pragma_init timeinit, 4

	END
