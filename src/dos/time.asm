; TIME.ASM--
; Copyright (C) 2015 Doszip Developers

include dos.inc
include time.inc
include mouse.inc
include conio.inc
include stdlib.inc
include keyb.inc

STARTDAY	equ 5
STARTYEAR	equ 0
MAXYEAR		equ 3000

USE_MDALTKEYS	= 1

PUBLIC		wcputnum	; Output Number to WORD *
public		dos_dateformat
public		date_separator
public		time_separator
externdef	cp_datefrm:byte
externdef	cp_timefrm:byte

.data
	dos_dateformat	db DFORMAT_EUROPE
	date_separator	db '.'
	time_separator	db ':'
	_day		db 33
	_sec		db 61

;******** Resource begin CALENDAR *
;	{ 0x005C,   0,	 0, {42, 2,29,10} },
;******** Resource data	 *******************
CALENDAR_RC label WORD
	dw	00283h	; Alloc size
	dw	0005Ch,00000h,0022Ah,00A1Dh,03AF0h,0F02Fh,0293Ah,01DF0h
	dw	0F02Fh,02974h,01DF0h,0F02Fh,0DF1Dh,04D20h,06E6Fh,05420h
	dw	06575h,05720h,06465h,05420h,07568h,04620h,06972h,05320h
	dw	07461h,05320h,06E75h,02020h,01BF0h,0F0C4h,020AFh,01DF0h
	dw	02FDCh
;	68 byte
IDD_CALENDAR dd _DATA:CALENDAR_RC

;	public	IDD_CALENDAR

;******** Resource end	 CALENDAR *

;******** Resource begin CALENDAR2 *
;	{ 0x0010,   0,	 0, {45,12,14, 1} },
;******** Resource data	 *******************
CALENDAR2_RC label WORD
	dw	0002Ch	; Alloc size
	dw	00010h,00000h,00C2Dh,0010Eh,00EF0h,0F007h,0200Eh,00707h
;	18 byte
;******** Resource end	 CALENDAR2 *

	cp_jan	db "January",0
	cp_feb	db "February",0
	cp_mar	db "March",0
	cp_apr	db "April",0
	cp_may	db "May",0
	cp_jun	db "June",0
	cp_jul	db "July",0
	cp_aug	db "August",0
	cp_sep	db "September",0
	cp_oct	db "October",0
	cp_nov	db "November",0
	cp_dec	db "December",0
	cp_month label size_t
		dw offset cp_jan
		dw offset cp_feb
		dw offset cp_mar
		dw offset cp_apr
		dw offset cp_may
		dw offset cp_jun
		dw offset cp_jul
		dw offset cp_aug
		dw offset cp_sep
		dw offset cp_oct
		dw offset cp_nov
		dw offset cp_dec
	keylocal label size_t
		dw MOUSECMD
		dw KEY_ESC
		dw KEY_HOME
		dw KEY_RIGHT
		dw KEY_LEFT
		dw KEY_UP
		dw KEY_DOWN
		dw KEY_PGUP
		dw KEY_PGDN
		dw KEY_CTRLPGUP
		dw KEY_CTRLPGDN
		dw KEY_ENTER
		dw KEY_ALTX
	ifdef USE_MDALTKEYS
		dw KEY_ALTUP
		dw KEY_ALTDN
		dw KEY_ALTLEFT
		dw KEY_ALTRIGHT
	endif
	keyproc label size_t
		dw event_mouse
		dw event_ESC
		dw event_HOME
		dw event_nextday
		dw event_prevday
		dw event_UP
		dw event_DOWN
		dw event_prevmnd
		dw event_nextmnd
		dw event_prevyear
		dw event_nextyear
		dw event_ENTER
		dw event_ESC
	ifdef USE_MDALTKEYS
		dw event_ALTUP
		dw event_ALTDN
		dw event_ALTLEFT
		dw event_ALTRIGHT
	endif
	keycount = (($ - offset keyproc) / size_l)
	mnd_table  db 31,28,31,30,31,30,31,31,30,31,30,31
	keypos	   db 1,5,9,13,17,21,25
	format_s_d db '%s %d',0
	format_2d  db '%2d',0

	DLG_Calendar	dd ?
	DLG_Calendar2	dd ?
	xpos		dw ?
	ypos		dw ?
	year		dw ?
	month		dw ?
	day		dw ?
	week_day	dw ?
	days_in_month	dw ?
	current_year	dw ?
	current_month	dw ?
	calender	dw ?
	result		dw ?

.code

getday	PROC _CType PUBLIC USES cx
	mov	ah,2Ah
	int	21h
	mov	ah,0
	mov	al,dl
	ret
getday	ENDP

getmnd	PROC _CType PUBLIC USES cx
	mov	ah,2Ah
	int	21h
	mov	ah,0
	mov	al,dh
	ret
getmnd	ENDP

getyear PROC _CType PUBLIC USES cx
	mov	ah,2Ah
	int	21h
	mov	ax,cx
	ret
getyear ENDP

dostime PROC _CType PUBLIC
	push	cx
	mov	ah,2Ah
	int	21h
	mov	ax,cx
	sub	ax,DT_BASEYEAR
	shl	ax,9
	xchg	ax,dx
	mov	cl,al
	mov	al,ah
	xor	ah,ah
	shl	ax,5
	xchg	ax,dx
	or	ax,dx
	or	al,cl
	push	ax
	mov	ah,2Ch	; CH = hour
	int	21h	; CL = minute
	xor	ax,ax	; DH = second
	mov	al,dh
	shr	ax,1
	mov	dx,ax	; second/2
	mov	al,ch
	mov	ch,ah
	shl	cx,5
	shl	ax,11
	or	ax,cx
	or	ax,dx	; hhhhhmmmmmmsssss
	pop	dx
	pop	cx
	ret
dostime ENDP

dosdate PROC _CType PUBLIC
	call dostime
	mov  ax,dx
	ret
dosdate ENDP

putedxal PROC PUBLIC
	aam
	add	ax,3030h
	mov	es:[bx],ah
	inc	bx
	mov	es:[bx],al
	inc	bx
	ret
putedxal ENDP

wcputnum PROC
	aam		; AH := AL / 10
	add ax,3030h	; AL := AL mod 10
	mov es:[bx],ah	; AX := AX + '00'
	mov es:[bx+2],al
	ret
wcputnum ENDP

dwtostr PROC _CType PUBLIC USES bx cx buf:DWORD, date:size_t

	mov	ax,date
	les	bx,buf
	call	dwexpand
	.if dos_dateformat == DFORMAT_JAPAN
	    xchg ax,cx ; yy/mm/dd
	.elseif dos_dateformat == DFORMAT_USA
	    xchg ax,dx ; mm/dd/yy
	.endif
	call	putedxal
	mov	al,date_separator
	mov	es:[bx],al
	inc	bx
	mov	ax,dx
	call	putedxal
	mov	al,date_separator
	mov	es:[bx],al
	inc	bx
	mov	ax,cx
	call	putedxal
	mov	byte ptr es:[bx],0
	mov	dx,es
	mov	ax,WORD PTR buf
	ret

dwtostr ENDP

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

dwtolstr PROC _CType PUBLIC uses bx string:DWORD, date:size_t

	.if dos_dateformat == DFORMAT_JAPAN
	    add word ptr string,2
	.endif
	invoke dwtostr, string, date
	mov bx,ax
	.if dos_dateformat == DFORMAT_JAPAN
	    sub bx,2 ; xxyy/mm/dd
	.else
	    add bx,6
	    mov ax,es:[bx]
	    mov es:[bx+2],ax ; dd.mm.xxyy
	    mov byte ptr es:[bx+4],0
	.endif
	mov ax,date
	shr ax,9
	add ax,DT_BASEYEAR
	.if ax >= 2000
	    mov WORD PTR es:[bx],'02'
	.else
	    mov WORD PTR es:[bx],'91'
	.endif
	mov dx,es
	mov ax,WORD PTR string
	ret

dwtolstr ENDP

strtotw PROC _CType PUBLIC USES bx si di string:DWORD
	sub ax,ax
	les bx,string
	.repeat
	    mov al,es:[bx]
	    inc bx
	.until al > '9' || al < '0'
	.if al
	    mov ax,WORD PTR string+2
	    push ax
	    push bx
	    push ax
	    push WORD PTR string
	    mov WORD PTR string,bx
	    call atol
	    mov si,ax
	    call atol
	    mov di,ax
	    les bx,string
	    sub ax,ax
	    .repeat
		mov al,es:[bx]
		inc bx
	    .until al > '9' || al < '0'
	    .if al
		push WORD PTR string+2
		    push bx
		call atol
		shr ax,1
		shl di,5
		shl si,11
		or ax,si
		or ax,di
	    .endif
	.endif
	ret
strtotw ENDP

strtodw PROC _CType PUBLIC USES si di bx string:DWORD

    les di,string
    mov si,es
    .if atol(si::di)
	mov bx,ax
	mov es,si
	mov al,es:[di]
	.while ( al >= '0' && al <= '9' )
	    inc di
	    mov al,es:[di]
	.endw
	inc di
	atol(si::di)
	push ax
	mov es,si
	mov al,es:[di]
	.while ( al >= '0' && al <= '9' )
	    inc di
	    mov al,es:[di]
	.endw
	inc di
	atol(si::di)
	pop dx ; default: dd.mm.yy??
	.if dos_dateformat == DFORMAT_JAPAN
	   xchg ax,bx	; yy??/mm/dd
	.elseif dos_dateformat == DFORMAT_USA
	    xchg ax,dx	; mm/dd/yy??
	.endif
	.if ax < 1900 ; AX = yy??
	    .if ax < 80
		add ax,100
	    .endif
	    add ax,1900
	.endif
	sub ax,DT_BASEYEAR
	shl ax,9
	shl dx,5  ; DX = mm
	or  ax,dx
	or  ax,bx ; BX = dd
    .endif
    ret
strtodw ENDP

tupdtime PROC _CType PUBLIC
	.if console & CON_UTIME
	    mov ax,2C00h
	    int 21h
	    .if dh != _sec
		mov _sec,dh
		HideMouseCursor
		mov ax,_scrseg
		mov es,ax
		sub bx,bx
		mov bl,_scrcol
		sub bl,5
		.if console & CON_LTIME
		    sub bl,3
		.endif
		add bx,bx
		mov al,ch
		call wcputnum
		mov al,time_separator
		mov es:[bx+4],al
		.if console & CON_LTIME
		    mov es:[bx+10],al
		.endif
		.if ah == '0'
		    mov BYTE PTR es:[bx],' '
		.endif
		add bx,6
		mov al,cl
		call wcputnum
		.if console & CON_LTIME
		    add bx,6
		    mov al,dh
		    call wcputnum
		.endif
		ShowMouseCursor
	    .endif
	.endif
	ret
tupdtime ENDP

tupddate PROC _CType PUBLIC
	.if console & CON_UDATE
	    mov ax,2A00h
	    int 21h
	    .if dl != _day
		mov _day,dl
		HideMouseCursor
		mov ax,_scrseg
		mov es,ax
		sub bx,bx
		mov bl,_scrcol
		sub bl,14
		.if console & CON_LTIME
		    sub bl,3
		.endif
		sub cx,2000
		.if dos_dateformat == DFORMAT_JAPAN
		    xchg dl,cl ; yy??/mm/dd
		.elseif dos_dateformat == DFORMAT_USA
		    xchg dl,dh ; mm/dd/yy??
		.endif
		.if console & CON_LDATE
		    sub bl,2
		    add bx,bx
		    .if dos_dateformat == DFORMAT_JAPAN
			mov BYTE PTR es:[bx],'2'
			mov BYTE PTR es:[bx+2],'0'
			add bx,4
		    .endif
		    mov al,dl
		    call wcputnum
		    add bx,6
		    mov al,date_separator
		    mov es:[bx-2],al
		    mov al,dh
		    call wcputnum
		    add bx,6
		    mov al,date_separator
		    mov es:[bx-2],al
		    .if dos_dateformat != DFORMAT_JAPAN
			mov BYTE PTR es:[bx],'2'
			mov BYTE PTR es:[bx+2],'0'
			add bx,4
		    .endif
		    mov al,cl
		    call wcputnum
		.else
		    add bx,bx
		    mov al,dl
		    call wcputnum
		    mov al,date_separator
		    mov es:[bx+4],al
		    mov es:[bx+10],al
		    .if ah == '0'
			mov BYTE PTR es:[bx],' '
		    .endif
		    add bx,6
		    mov al,dh
		    call wcputnum
		    add bx,6
		    mov al,cl
		    call wcputnum
		.endif
		ShowMouseCursor
	    .endif
	.endif
	ret
tupddate ENDP

days_in_feb:
	push	dx
	push	bx
	test	cx,cx
	jz	days_in_feb_29
	mov	ax,cx
	and	al,3
	jnz	@F
	mov	ax,cx
	mov	bx,100
	xor	dx,dx
	div	bx
	or	dx,dx
	jnz	days_in_feb_29
      @@:
	mov	bx,400
	mov	ax,cx
	xor	dx,dx
	div	bx
	test	dx,dx
	jz	days_in_feb_29
	mov	ax,28
    days_in_feb_end:
	pop	bx
	pop	dx
	ret
    days_in_feb_29:
	mov	ax,29
	jmp	days_in_feb_end

days_in_mnd:
	cmp	bx,2
	je	days_in_feb
	mov	ah,0
	mov	al,mnd_table[bx-1]
	ret

weekday_jan1:
	push	bp
	push	si
	push	di
	xor	bp,bp
	mov	si,STARTDAY
	mov	di,cx
	mov	cx,STARTYEAR
    weekday_jan1_loop:
	cmp	cx,di
	jnb	weekday_jan1_break
	call	days_in_feb
	cmp	ax,29
	jne	@F
	add	si,1
	adc	bp,0
      @@:
	inc	cx
	add	si,1
	adc	bp,0
	jmp	weekday_jan1_loop
    weekday_jan1_break:
	push	dx
	mov	dx,bp
	mov	ax,si
	mov	si,7
	div	si
	mov	ax,dx
	pop	dx
	mov	cx,di
	pop	di
	pop	si
	pop	bp
	ret

getweekday:
	call	weekday_jan1
	push	si
	push	di
	mov	si,ax
	mov	di,bx
	mov	bx,1
      @@:
	cmp	bx,di
	jnb	@F
	call	days_in_mnd
	add	si,ax
	inc	bx
	jmp	@B
      @@:
	push	dx
	mov	di,7
	xor	dx,dx
	mov	ax,si
	div	di
	mov	ax,dx
	pop	dx
	pop	di
	pop	si
	ret

getcurdate:	; GET SYSTEM DATE
	call	getday
	mov	day,ax
	call	getmnd
	mov	month,ax
	call	getyear
	mov	year,ax
	mov	dx,day
	mov	cx,ax
	mov	ax,month
	mov	bx,ax
	call	getweekday
	mov	week_day,ax
	call	days_in_mnd
	mov	days_in_month,ax
	ret

incyear:
	mov	cx,year
	cmp	cx,MAXYEAR
	je	@F
	inc	cx
	ret
      @@:
	mov	cx,STARTYEAR
	ret

decyear:
	mov	cx,year
	test	cx,cx
	jz	@F
	dec	cx
	ret
      @@:
	mov	cx,MAXYEAR
	ret

putdate:
	push	si
	push	di
	mov	ax,year
	mov	dx,month
	cmp	ax,current_year
	jne	@F
	cmp	dx,current_month
	je	putdate_day
      @@:
	mov	current_month,dx
	mov	current_year,ax
	mov	ax,xpos
	mov	dx,ypos
	add	al,3
	add	dl,10
	invoke	scputw,ax,dx,14,0020h
	mov	bx,month
	dec	bx
	shl	bx,size_l/2
	mov	bx,cp_month[bx]
	invoke	scputf,ax,dx,0,0,addr format_s_d,ss::bx,year
	mov	bx,xpos
	mov	dx,ypos
	add	dl,3
	mov	cx,6
	mov	ax,20h
	mov	ah,at_background[B_Dialog]
	or	ah,at_foreground[F_Dialog]
      @@:
	invoke	scputw,bx,dx,29,ax
	inc	dl
	dec	cx
	jnz	@B
    putdate_day:
	xor	si,si
	mov	di,3
    putdate_loop:
	cmp	si,days_in_month
	jnb	putdate_end
	xor	cx,cx
    putdate_xloop:
	cmp	cx,7
	jnb	putdate_yloop
	mov	ax,3		; first line
	cmp	week_day,cx	; week day
	ja	@F
	cmp	di,ax
	je	putdate_putday
      @@:
	cmp	di,ax
	jna	putdate_next
	cmp	si,days_in_month	; days in month
	jae	putdate_next
    putdate_putday:
	inc	si
	push	cx
	push	di
	mov	bx,cx
	mov	cl,at_background[B_Dialog]
	mov	al,at_foreground[F_DialogKey]
	cmp	si,day
	je	@F
	mov	al,at_foreground[F_Dialog]
      @@:
	or	cl,al
	mov	al,keypos[bx]
	mov	bx,di
	add	bx,ypos
	add	ax,xpos
	mov	di,ax
	invoke	scputf,ax,bx,cx,2,addr format_2d,si
	call	getday
	cmp	ax,si
	jne	@F
	call	getmnd
	cmp	ax,month
	jne	@F
	call	getyear
	cmp	ax,year
	jne	@F
	mov	al,4;at_foreground[B_Error]
	or	al,at_background[B_Dialog]
	invoke	scputa,di,bx,2,ax
      @@:
	pop	di
	pop	cx
    putdate_next:
	inc	cx
	jmp	putdate_xloop
    putdate_yloop:
	add	di,1
	cmp	di,10
	jb	putdate_loop
    putdate_end:
	pop	di
	pop	si
	ret

setdate:
	mov	day,dx
	mov	month,bx
	mov	year,cx
	call	getweekday
	mov	week_day,ax
	call	days_in_mnd
	mov	days_in_month,ax
	call	putdate
	ret

ifdef USE_MDALTKEYS
event_ALTUP:
	mov	ax,rcmoveup
	jmp	DLMOVE_MOVE
event_ALTDN:
	mov	ax,rcmovedn
	jmp	DLMOVE_MOVE
event_ALTLEFT:
	mov	ax,rcmoveleft
	jmp	DLMOVE_MOVE
event_ALTRIGHT:
	mov	ax,rcmoveright
DLMOVE_MOVE:
	push	ax
	invoke	dlhide,DLG_Calendar2
	pop	ax
	les	bx,DLG_Calendar
	pushm	es:[bx].S_DOBJ.dl_rect
	pushm	es:[bx].S_DOBJ.dl_wp
	push	es:[bx].S_DOBJ.dl_flag
	pushl	cs
	call	ax
	les	bx,DLG_Calendar
	mov	WORD PTR es:[bx].S_DOBJ.dl_rect,ax
	mov	BYTE PTR xpos,al
	mov	BYTE PTR ypos,ah
	add	ax,0A03h
	les	bx,DLG_Calendar2
	mov	WORD PTR es:[bx].S_DOBJ.dl_rect,ax
	invoke	dlshow,DLG_Calendar2
	ret
endif

event_ENTER:
	mov	ax,1
	mov	result,ax

event_ESC:
	inc	BYTE PTR calender
	ret

event_HOME:
	call	getcurdate
	jmp	putdate

event_nextday:
	mov	dx,day
	inc	dx
	cmp	dx,days_in_month
	ja	event_nextmnd
	mov	day,dx
	jmp	putdate

event_prevday:
	mov	dx,day
	cmp	dx,1
	je	@F
	mov	cx,year
	mov	bx,month
	dec	dx
	jmp	setdate
      @@:
	call	event_prevmnd
	mov	ax,days_in_month
	mov	day,ax
	jmp	putdate

event_UP:
	mov	ax,7
	cmp	day,ax
	jbe	event_prevday
	sub	day,ax
	jmp	putdate

event_DOWN:
	mov	ax,day
	add	ax,7
	cmp	ax,days_in_month
	ja	event_nextday
	mov	day,ax
	jmp	putdate

event_prevmnd:
	mov	dx,1
	mov	bx,month
	mov	cx,year
	cmp	bx,1
	je	@F
	dec	bx
	jmp	setdate
    @@:
	mov	bx,12
	call	decyear
	jmp	setdate

event_nextmnd:
	mov	bx,month
	cmp	bx,12
	je	event_nextyear
	mov	dx,1
	mov	cx,year
	inc	bx
	jmp	setdate

event_prevyear:
	mov	dx,1
	mov	bx,dx
	call	decyear
	jmp	setdate

event_nextyear:
	mov	dx,1
	mov	bx,dx
	call	incyear
	jmp	setdate

event_mouse:
  ifdef __MOUSE__
	call	mousex
	mov	dx,ax
	call	mousey
	les	bx,DLG_Calendar
	invoke	rcxyrow,DWORD PTR es:[bx].S_DOBJ.dl_rect,dx,ax
	test	ax,ax
	jz	event_ESC
	invoke	dlhide,DLG_Calendar2
	invoke	dlmove,DLG_Calendar
	les	bx,DLG_Calendar
	sub	ax,ax
	mov	al,es:[bx]+4
	mov	dl,al
	mov	xpos,ax
	mov	al,es:[bx]+5
	mov	ypos,ax
	mov	ah,al
	mov	al,dl
	add	ax,0A03h
	les	bx,DLG_Calendar2
	mov	es:[bx]+4,ax
	invoke	dlshow,DLG_Calendar2
  else
	xor	ax,ax
  endif
	ret

modal:	cmp	BYTE PTR calender,0
	je	@F
	ret
      @@:
	call	tgetevent
	mov	cx,keycount
	xor	bx,bx
      @@:
	cmp	ax,keylocal[bx]
	je	@F
	add	bx,size_l
	dec	cx
	jnz	@B
	jmp	modal
      @@:
	call	keyproc[bx]
	jmp	modal

cmcalendar PROC _CType PUBLIC USES bx
	xor	ax,ax
	mov	calender,ax
	mov	current_year,ax
	mov	current_month,ax
	mov	result,ax
	invoke	rsopen,addr CALENDAR_RC
	stom	DLG_Calendar
	jz	cmcalendar_end
	mov	bx,ax
	sub	ax,ax
	mov	al,es:[bx][4]
	mov	xpos,ax
	mov	al,es:[bx][5]
	mov	ypos,ax
	invoke	dlshow,DLG_Calendar
	invoke	rsopen,addr CALENDAR2_RC
	stom	DLG_Calendar2
	invoke	dlshow,dx::ax
	call	getcurdate
	mov	dx,day
	mov	bx,month
	mov	cx,year
	call	setdate
  ifdef __MOUSE__
	call	msloop
  endif
	call	modal
	invoke	dlclose,DLG_Calendar2
	invoke	dlclose,DLG_Calendar
	mov	dx,day
	mov	bx,month
	mov	cx,year
    cmcalendar_end:
	mov	ax,result
	ret
cmcalendar ENDP


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
	mov	al,'.'
	je	europe
	mov	al,'/'
europe:
	cmp	_osmajor,2
	ja	dos_2_11
	cmp	_osminor,11
	jb	dos_2_10
dos_2_11:
	mov	al,country_info[0x0D]
	mov	time_separator,al
	mov	cp_timefrm[3],al ; "%2u:%02u"
	mov	al,country_info[0x0B]
dos_2_10:
	mov	date_separator,al
	mov	cp_datefrm[3],al ; "%2u.%02u.%02u"
	mov	cp_datefrm[8],al
toend:
	ret
timeinit ENDP

pragma_init timeinit, 8

	END
