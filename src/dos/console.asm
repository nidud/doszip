; CONSOLE.ASM--
; Copyright (C) 2015 Doszip Developers

include conio.inc
include keyb.inc
include mouse.inc

	PUBLIC	_scrcol
	PUBLIC	_scrrow
	PUBLIC	_scrseg
	PUBLIC	_egafastswitch
	PUBLIC	console_dl	; init screen
;	public	console_cu	; init cursor

	.data
	console_dl	S_DOBJ <?>
	console_cu	S_CURSOR <?>
	_scrcol		db 80
	_scrrow		db 24
	_scrseg		dw 0B800h
	_egafastswitch	db 0

	.code

conssetl PROC _CType PUBLIC l:size_t	; line: 0..max
local	cursor:S_CURSOR
local	rc:DWORD
local	wp:DWORD
	mov	ax,l
	cmp	al,_scrrow
	jne	@F
	cmp	_scrcol,80
	je	conssetl_end
      @@:
	HideMouseCursor
	cmp	_egafastswitch,0
	jne	@F
	mov	al,_scrcol
	mov	ah,50
	mov	WORD PTR rc,0
	mov	WORD PTR rc+2,ax	; save screen (args rcclose)
	invoke	rcpush,49
	stom	wp
      @@:
	invoke	cursorget,addr cursor
	mov	ax,0003h	; this clears the screen
	cmp	_scrseg,0B000h
	jne	@F
	mov	al,07h
      @@:
	or	al,_egafastswitch
	int	10h
	invoke	cursorset,addr cursor
	cmp	_egafastswitch,0
	jne	@F
	call	consinit
	invoke	rcclose,rc,_D_DOPEN or _D_ONSCR,wp
      @@:
	cmp	l,49
	jne	@F
	mov	ax,1202h	; set scanline to 400
	mov	bx,0030h
	int	10h
	mov	ax,1112h	; load 8x8 font
	xor	bx,bx
	int	10h
      @@:
	test	console,CON_COLOR
	jz	@F
	invoke	loadpal,addr at_palett
      @@:
	ShowMouseCursor
    conssetl_end:
	call	consinit
	ret
conssetl ENDP

consuser PROC _CType PUBLIC
local	cursor:S_CURSOR
local	dialog:S_DOBJ
	invoke	cursorget,addr cursor
	mov	al,_scrrow
	push	ax
	mov	al,console_dl.dl_rect.rc_row
	dec	al
	invoke	conssetl,ax
	call	cursoroff
	sub	ax,ax
	mov	dialog.dl_flag,_D_DOPEN
	mov	WORD PTR dialog.dl_rect,ax
	mov	dialog.dl_rect.rc_col,80
	mov	al,console_dl.dl_rect.rc_row
	mov	dialog.dl_rect.rc_row,al
	movmx	dialog.dl_wp,console_dl.dl_wp
	invoke	dlshow,addr dialog
      @@:
	call	getkey
	test	ax,ax
	jz	@B
	pop	ax
	invoke	conssetl,ax
	invoke	dlhide,addr dialog
	invoke	cursorset,addr cursor
	sub	ax,ax
	ret
consuser ENDP

InitScreenData:
	mov	ax,0040h
	mov	es,ax
	mov	bx,0063h
	mov	ax,es:[bx]
	and	ax,0FF0h
	cmp	ax,03B0h
	jne	@F
	mov	_scrseg,0B000h
      @@:
	mov	bx,004Ah	; screen columns [0040:004A]
	mov	al,es:[bx]
	mov	_scrcol,al
	mov	ah,al		; = ah
	mov	bl,84h		; screen rows minus one [0040:0084]
	mov	al,es:[bx]
	mov	_scrrow,al	; = al
	ret

InitConsole:
	mov	ah,12h		; EGA installation check
	mov	bx,0FF10h
	int	10h
	cmp	bh,0FFh
	je	@F
	mov	_egafastswitch,80h
      @@:
	mov	ah,0Fh		; Japheth - 28.08.11
	int	10h
	test	bh,bh		; Test if active display page is 0
	jz	@F
	mov	ax,0500h	; Set display page to 0
	int	10h
      @@:
	call	InitScreenData
	invoke	cursorget,addr console_cu
	mov	al,_scrrow	; save init screen
	inc	al
	invoke	rcpush,ax
	stom	console_dl.dl_wp
	mov	console_dl.dl_flag,_D_DOPEN
	mov	al,_scrrow
	inc	al
	mov	console_dl.dl_rect.rc_row,al
	mov	al,_scrcol
	mov	console_dl.dl_rect.rc_col,al
	call	getkey
	ret

ExitConsole:
	HideMouseCursor
	invoke	cursorset,addr console_cu
;	test	console,CON_COLOR
;	jz	@F
	test	console,CON_REVGA
	jz	@F
	call	resetpal
      @@:
	ret

consinit PROC _CType PUBLIC USES bx
	call	InitScreenData
	invoke	loadpal,addr at_palett
	ret
consinit ENDP

pragma_init InitConsole, 5
pragma_exit ExitConsole, 1

	END
