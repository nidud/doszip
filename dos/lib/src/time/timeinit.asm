; TIMEINIT.ASM--
; Copyright (C) 2015 Doszip Developers

include dos.inc
include time.inc

public		dos_dateformat
public		date_separator
public		time_separator
externdef	cp_datefrm:byte
externdef	cp_timefrm:byte

.data
dos_dateformat db DFORMAT_EUROPE
date_separator db '.'
time_separator db ':'

.code

dwexpand PROC _CType
	mov dx,ax
	mov cx,ax
	and ax,001Fh ; dd
	shr dx,5
	and dx,000Fh ; mm
	shr cx,9     ; yy
	add cx,DT_BASEYEAR
	.if cx >= 2000
	    sub cx,2000
	.else
	    sub cx,1900
	.endif
	ret
dwexpand ENDP

timeinit PROC PRIVATE
LOCAL	country_info[64]:byte
	push	ds
	push	ss
	pop	ds
	mov	country_info,DFORMAT_EUROPE
	lea	dx,country_info
	mov	ax,3800h
	stc
	int	21h
	pop	ds
	jc	toend
	mov	al,country_info
	mov	dos_dateformat,al
	cmp	al,DFORMAT_EUROPE
	je	toend
	mov	al,'/'
	cmp	_osmajor,2
	ja	dos_2_11
	cmp	_osminor,11
	jb	dos_2_10
dos_2_11:
	mov	al,country_info[0x0D]
	mov	time_separator,al
	mov	cp_timefrm[3],al ; "%2u:%02u"
	mov	al,country_info[0x0B]
	mov	date_separator,al
dos_2_10:
	mov	cp_datefrm[3],al ; "%2u.%02u.%02u"
	mov	cp_datefrm[8],al
toend:
	ret
timeinit ENDP

pragma_init timeinit, 4

	END
