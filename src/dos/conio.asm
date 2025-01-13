; CONIO.ASM--
; Copyright (C) 2015 Doszip Developers

include conio.inc
include alloc.inc
include mouse.inc
include io.inc
include stdio.inc
include string.inc

_FG_DEACTIVE	equ 8

SHADE		STRUC
sh_cols		dw ?
sh_boff		dw ?
sh_soff		dw ?
sh_xcount	dw ?
sh_wcount	dw ?
SHADE		ENDS

rcm		STRUC
scp		dd ?
xcn		dw ?
ycn		dw ?
wcn		dw ?
scn		dw ?
base		dd ?	; (R|E)BP -- sizeof(locals)
ifdef __64__
		dd ?
endif
ifndef __COMPACT__
		dw ?
endif
ifdef __CDECL__
rect		dd ?
wchr		dd ?
shade		dw ?
else
shade		dw ?
wchr		dd ?
rect		dd ?
endif
rcm		ENDS

A_rc	equ <[bp+rcm.rect-rcm.base]>
A_wp	equ <[bp+rcm.wchr-rcm.base]>
A_sh	equ <[bp+rcm.shade-rcm.base]>
L_scp	equ <[bp+rcm.scp-rcm.base]>
L_xcn	equ <WORD PTR [bp+rcm.xcn-rcm.base]>
L_ycn	equ <WORD PTR [bp+rcm.ycn-rcm.base]>
L_wcn	equ <WORD PTR [bp+rcm.wcn-rcm.base]>
L_scn	equ <WORD PTR [bp+rcm.scn-rcm.base]>

externdef at_background:BYTE
externdef at_foreground:BYTE

.data
 wcvisible db 0
 frametypes label BYTE
	db 'ÚÄ¿³ÀÙ'
	db 'ÉÍ»ºÈ¼'
	db 'ÂÄÂ³ÁÁ'
	db 'ÃÄ´³Ã´'

.code

__wputs PROC PUBLIC	; ES:DI word buffer (or screen)
	push	si	; DS:SI string
	push	di	; CL max byte output
	cld?		; CH attrib for &Text if set
	test	cl,cl	; DX length of line (word count)
	jnz	putstr_loop
	dec	cl	; AH attrib or 0
	jmp	putstr_loop
    putstr_tab:
	add	di,16
	and	di,not 15
	jmp	putstr_loop
    putstr_line:
	pop	di
	add	di,dx
	push	di
    putstr_loop:
	lodsb
	test	al,al
	jz	putstr_end
	cmp	al,10
	je	putstr_line
	cmp	al,9
	je	putstr_tab
	cmp	al,'&'
	je	putstr_color
	test	ah,ah
	jz	putstr_noat
	stosw
	jmp	putstr_next
    putstr_noat:
	stosb
	inc	di
    putstr_next:
	dec	cl
	jnz	putstr_loop
    putstr_end:
	mov	ax,si
	pop	di
	pop	si
	sub	ax,si
	ret
    putstr_color:
	test	ch,ch
	jz	putstr_noat
	mov	es:[di][1],ch
	jmp	putstr_loop
__wputs ENDP

wcputw	PROC _CType PUBLIC USES ax cx di b:DWORD, l:size_t, w:size_t
	cld?
	push	es
	mov	ax,w
	mov	cx,l
	les	di,b
	.if ah
	    rep stosw
	.else
	    .repeat
		stosb
		inc di
	    .untilcxz
	.endif
	pop	es
	ret
wcputw	ENDP

wcputxg PROC PUBLIC
	push	cx
	inc	bx
      @@:
	and	es:[bx],ah
	or	es:[bx],al
	add	bx,2
	dec	cx
	jnz	@B
	pop	cx
	ret
wcputxg ENDP

wcputa	PROC _CType PUBLIC USES cx bx wp:DWORD, l:size_t, attrib:size_t
	les	bx,wp
	mov	ax,attrib
	mov	cx,l
	and	ax,00FFh
	call	wcputxg
	ret
wcputa	ENDP

wcputbg PROC _CType PUBLIC USES cx bx wp:DWORD, l:size_t, attrib:size_t
	mov	ax,attrib
	mov	ah,0Fh
	and	al,70h
	mov	cx,l
	les	bx,wp
	call	wcputxg
	ret
wcputbg ENDP

wcputfg PROC _CType PUBLIC USES cx bx wp:DWORD, l:size_t, attrib:size_t
	mov	ax,attrib
	mov	ah,70h
	and	al,0Fh
	mov	cx,l
	les	bx,wp
	call	wcputxg
	ret
wcputfg ENDP

wcputs	PROC _CType PUBLIC USES cx dx si di p:DWORD,
	l:size_t, max:size_t, string:DWORD
	push	ds
	les	di,p
	mov	dl,BYTE PTR l
	mov	dh,0
	add	dx,dx
	mov	cl,BYTE PTR max
	mov	ch,es:[di]+1
	and	ch,0F0h
	.if ch == at_background[B_Menus]
	    or ch,at_foreground[F_MenusKey]
	.elseif ch == at_background[B_Dialog]
	    or ch,at_foreground[F_DialogKey]
	.else
	    sub ch,ch
	.endif
	lds	si,string
	mov	ah,0
	call	__wputs
	pop	ds
	ret
wcputs	ENDP

wcputf	PROC _CDecl PUBLIC b:DWORD, l:size_t, max:size_t, format:DWORD, argptr:VARARG
	invoke ftobufin,format,addr argptr
	invoke wcputs,b,l,max,addr _bufin
	ret
wcputf	ENDP

wcpath	PROC _CType PUBLIC USES bx b:DWORD, l:size_t, p:DWORD
	push	ds
	push	si
	lds	si,b
	invoke	strlen,p
	mov	cx,ax
	mov	dx,WORD PTR p
	mov	ax,WORD PTR b
	cmp	cx,l
	jbe	wcpath_end
	mov	bx,dx
	add	dx,cx
	mov	cx,l
	sub	dx,cx
	add	dx,4
	cmp	BYTE PTR es:[bx][1],':'
	jne	@F
	mov	ax,es:[bx]
	mov	[si],al
	mov	[si+2],ah
	mov	ax,si
	add	si,4
	mov	bh,es:[bx+2]
	mov	bl,'.'
	add	ax,4
	add	dx,2
	sub	cx,2
	jmp	wcpath_set
      @@:
	mov	bx,'/.'
    wcpath_set:
	mov	[si],bh
	mov	[si+2],bl
	mov	[si+4],bl
	mov	[si+6],bh
	add	ax,8
	sub	cx,4
    wcpath_end:
	pop	si
	pop	ds
	ret
wcpath	ENDP

wcenter PROC _CType PUBLIC USES ax cx dx si di wp:DWORD, l:size_t, string:DWORD
	push ds
	push es
	invoke wcpath,wp,l,string
	.if cx
	    les di,wp
	    lds si,string
	    mov si,dx
	    .if di == ax
		mov ax,l
		sub ax,cx
		and al,not 1
		add di,ax
	    .else
		mov di,ax
	    .endif
	    .repeat
		movsb
		inc di
	    .untilcxz
	.endif
	pop es
	pop ds
	ret
wcenter ENDP

wctitle PROC _CType PUBLIC p:DWORD, l:size_t, string:DWORD
	mov	al,' '
	mov	ah,at_background[B_Title]
	or	ah,at_foreground[F_Title]
	invoke	wcputw,p,l,ax
	invoke	wcenter,p,l,string
	ret
wctitle ENDP

wcpbutt PROC _CType PUBLIC USES si di bx wp:DWORD,
	l:size_t, x:size_t, string:DWORD
	cld
	push	ds
	mov	cx,x
	mov	ah,at_background[B_PushButt]
	or	ah,at_foreground[F_Title]
	mov	al,' '
	les	di,wp
	mov	bx,di
	mov	dx,di
	rep	stosw
	mov	ax,es:[di]
	mov	al,'Ü'
	and	ah,11110000B
	or	ah,at_foreground[F_PBShade]
	stosw
	add	dx,l
	add	dx,l
	add	dx,2
	mov	di,dx
	mov	cx,x
	mov	al,'ß'
	rep	stosw
	mov	ah,at_background[B_PushButt]
	or	ah,at_foreground[F_TitleKey]
	lds	si,string
	mov	di,bx
	add	di,4
    wcpbutt_loop:
	lodsb
	or	al,al
	jz	wcpbutt_end
	cmp	al,'&'
	jz	wcpbutt_01
	stosb
	inc	di
	jmp	wcpbutt_loop
    wcpbutt_01:
	lodsb
	or	al,al
	jz	wcpbutt_end
	stosw
	jmp	wcpbutt_loop
    wcpbutt_end:
	lodm	wp
	pop	ds
	ret
wcpbutt ENDP

wcstline:
	push	bx
	mov	bx,0150h
	mov	ch,_scrrow
	mov	cl,0
	invoke	rcxchg,bx::cx,dx::ax
	pop	bx
	ret

wcpushst PROC _CType PUBLIC USES bx wc:DWORD, cp:DWORD
	cmp	wcvisible,1
	jne	wcpushst_00
	lodm	wc
	call	wcstline
    wcpushst_00:
	mov	al,' '
	mov	ah,at_background[B_Menus]
	or	ah,at_foreground[F_Menus]
	invoke	wcputw,wc,80,ax
	les	bx,wc
	mov	BYTE PTR es:[bx][36],179
	add	bx,2
	invoke	wcputs,es::bx,80,80,cp
	lodm	wc
	call	wcstline
	mov	wcvisible,1
	ret
wcpushst ENDP

wcpopst PROC _CType PUBLIC wp:DWORD
	lodm	wp
	call	wcstline
	xor	wcvisible,1
	ret
wcpopst ENDP

rcunzipat_04:
	mov	ah,al
	and	ax,0FF0h
	shr	al,4
	mov	bh,0
	mov	bl,al
	mov	al,ss:[bx+at_background]
	mov	bl,ah
	or	al,ss:[bx+at_foreground]
	ret

rsunzipat PROC PUBLIC
	push	bx
    rcunzipat_00:
	lodsb
	mov	dl,al
	and	dl,0F0h
	cmp	dl,0F0h
	jne	rcunzipat_01
	mov	ah,al
	lodsb
	and	ax,0FFFh
	mov	dx,ax
	lodsb
	call	rcunzipat_04
      @@:
	stosb
	inc	di
	dec	dx
	jz	rcunzipat_02
	dec	cx
	jnz	@B
	jmp	rcunzipat_end
    rcunzipat_01:
	call	rcunzipat_04
	stosb
	inc	di
    rcunzipat_02:
	dec	cx
	jnz	rcunzipat_00
    rcunzipat_end:
	pop	bx
	ret
rsunzipat ENDP

rsunzipch PROC PUBLIC
	push	bx
    rsunzipch_00:
	lodsb
	mov	dl,al
	and	dl,0F0h
	cmp	dl,0F0h
	jnz	rsunzipch_01
	mov	ah,al
	lodsb
	and	ax,0FFFh
	mov	bx,ax
	lodsb
      @@:
	stosb
	inc	di
	dec	bx
	jz	rsunzipch_02
	dec	cx
	jnz	@B
	jmp	rsunzipch_end
    rsunzipch_01:
	stosb
	inc	di
    rsunzipch_02:
	dec	cx
	jnz	rsunzipch_00
    rsunzipch_end:
	pop	bx
	ret
rsunzipch ENDP

wcunzip PROC _CType PUBLIC USES si di  dest:DWORD, src:DWORD, wcount:size_t
	push	ds
	les	di,dest
	inc	di
	lds	si,src
	cld?
	mov	ax,wcount
	and	wcount,07FFh
	and	ax,8000h
	mov	cx,wcount
	jz	wcunzip_00
	call	rsunzipat
	jmp	wcunzip_01
    wcunzip_00:
	call	rsunzipch
    wcunzip_01:
	mov	di,WORD PTR dest
	mov	cx,wcount
	call	rsunzipch
	pop	ds
	ret
wcunzip ENDP

;-----------

__getxypm PROC PUBLIC
	HideMouseCursor
__getxypm ENDP

__getxyp PROC PUBLIC	; x,y (AL,AH) to DX:AX
	mov	dl,al
	mov	al,_scrcol
	mul	ah
	add	ax,ax
	xor	dh,dh
	add	ax,dx
	add	ax,dx
	mov	dx,_scrseg
	ret
__getxyp ENDP

getxyw	PROC _CType PUBLIC USES bx x:size_t, y:size_t
	push	dx
	mov	al,BYTE PTR x
	mov	ah,BYTE PTR y
	call	__getxypm
	mov	es,dx
	mov	bx,ax
	mov	ax,es:[bx]
	ShowMouseCursor
	pop	dx
	ret
getxyw	ENDP

getxyc	PROC _CType PUBLIC x:size_t, y:size_t
	invoke	getxyw,x,y
	mov	ah,0
	ret
getxyc	ENDP

getxya	PROC _CType PUBLIC x:size_t, y:size_t
	invoke getxyw,x,y
	mov al,ah
	mov ah,0
	ret
getxya	ENDP

getxyp	PROC _CType PUBLIC x:WORD, y:WORD
	mov	al,BYTE PTR x
	mov	ah,BYTE PTR y
	call	__getxyp
	ret
getxyp	ENDP

ifdef	__scputw__
__scputw PROC PUBLIC
	push	bx
	push	dx
	push	ax
	mov	bx,ax
	mov	ax,dx
	call	__getxypm
	invoke	wcputw,dx::ax,cx,bx
	ShowMouseCursor
	pop	ax
	pop	dx
	pop	bx
	ret
__scputw ENDP
endif

scputw	PROC _CType PUBLIC USES ax x,y,l,w:size_t
	push	dx
	mov	al,BYTE PTR x
	mov	ah,BYTE PTR y
	call	__getxypm
	invoke	wcputw,dx::ax,l,w
	ShowMouseCursor
	pop	dx
	ret
scputw	ENDP

scputc	PROC _CType PUBLIC x:size_t, y:size_t, l:size_t, char:size_t
	mov	al,BYTE PTR char
	mov	ah,0
	invoke	scputw,x,y,l,ax
	ret
scputc	ENDP

scputa	PROC _CType PUBLIC USES ax dx x:size_t, y:size_t, l:size_t, a:size_t
	mov	al,BYTE PTR x
	mov	ah,BYTE PTR y
	call	__getxypm
	invoke	wcputa,dx::ax,l,a
	ShowMouseCursor
	ret
scputa	ENDP

scputfg PROC _CType PUBLIC USES ax dx x:size_t, y:size_t, l:size_t, a:size_t
	mov	al,BYTE PTR x
	mov	ah,BYTE PTR y
	call	__getxypm
	invoke	wcputfg,dx::ax,l,a
	ShowMouseCursor
	ret
scputfg ENDP

scputs	PROC _CType PUBLIC USES si di x:size_t, y:size_t, a:size_t,
	l:size_t, string:DWORD
	push	es
	push	ds
	push	bx
	push	cx
	push	dx
	mov	al,BYTE PTR x
	mov	ah,BYTE PTR y
	call	__getxypm
	mov	es,dx
	mov	di,ax
	lds	si,string
	mov	ch,0
	mov	dh,0
	mov	cl,BYTE PTR l
	mov	dl,_scrcol
	add	dx,dx
	mov	ah,BYTE PTR a
	call	__wputs
	ShowMouseCursor
	pop	dx
	pop	cx
	pop	bx
	pop	ds
	pop	es
	ret
scputs	ENDP

scputf	PROC _CDecl PUBLIC USES dx cx x, y, a, l:size_t, f:DWORD, p:VARARG
	invoke ftobufin,f,addr p
	invoke scputs,x,y,a,l,addr _bufin
	ret
scputf	ENDP

scpath	PROC _CType PUBLIC USES si di x,y,l:size_t, string:DWORD
	push	ds
	push	es
	push	dx
	push	cx
	mov	al,BYTE PTR x
	mov	ah,BYTE PTR y
	call	__getxypm
	push	ax
	mov	di,ax
	mov	si,dx
	invoke	wcpath,dx::ax,l,string
	xchg	si,dx
	test	cx,cx
	jz	scpath_end
	mov	es,dx
	mov	di,ax
	lds	ax,string
	cld?
      @@:
	movsb
	inc	di
	dec	cx
	jnz	@B
    scpath_end:
	ShowMouseCursor
	pop	dx
	mov	ax,di
	sub	ax,dx
	shr	ax,1
	pop	cx
	pop	dx
	pop	es
	pop	ds
	ret
scpath	ENDP

scenter PROC _CType PUBLIC USES dx x,y,l:size_t,s:DWORD
	mov	al,BYTE PTR x
	mov	ah,BYTE PTR y
	call	__getxypm
	invoke	wcenter,dx::ax,l,s
	ShowMouseCursor
	ret
scenter ENDP

rcbprc	PROC _CType PUBLIC USES bx rc:DWORD, wbuf:DWORD, cols:size_t
	mov	ax,cols
	add	ax,ax
	mov	bx,WORD PTR rc
	mul	bh
	mov	dl,bl
	mov	dh,0
	add	ax,dx
	add	ax,dx
	add	ax,WORD PTR wbuf
	mov	dx,WORD PTR wbuf+2
	ret
rcbprc	ENDP

rcsprc	PROC _CType PUBLIC rc:DWORD
	mov	al,_scrcol
	mul	rc.S_RECT.rc_y
	add	ax,ax
	xor	dx,dx
	mov	dl,rc.S_RECT.rc_x
	add	ax,dx
	add	ax,dx
	mov	dx,_scrseg
	ret
rcsprc	ENDP

rcxyrow PROC _CType PUBLIC rc:DWORD, x:size_t, y:size_t
	push	dx
	mov	al,BYTE PTR y
	mov	ah,BYTE PTR x
	mov	dl,rc.S_RECT.rc_x
	mov	dh,rc.S_RECT.rc_y
	cmp	ah,dl
	jb	rcxyrow_01
	cmp	al,dh
	jb	rcxyrow_01
	add	dl,rc.S_RECT.rc_col
	cmp	ah,dl
	jae	rcxyrow_01
	mov	ah,dh
	add	dh,rc.S_RECT.rc_row
	cmp	al,dh
	jae	rcxyrow_01
	sub	al,ah
	inc	al
	mov	ah,0
    rcxyrow_00:
	pop	dx
	ret
    rcxyrow_01:
	sub	ax,ax
	jmp	rcxyrow_00
rcxyrow ENDP

rcmemsize PROC _CType PUBLIC USES dx rc:DWORD, dflag:size_t
	mov ax,WORD PTR rc+2
	mov dx,ax
	mul ah
	add ax,ax
	.if BYTE PTR dflag & _D_SHADE
	    add dl,dh
	    add dl,dh
	    mov dh,0
	    sub dx,2
	    add ax,dx
	.endif
	ret
rcmemsize ENDP

rcalloc PROC _CType PUBLIC rc:DWORD, sh:size_t
	invoke rcmemsize,rc,sh
	invoke malloc,ax
	ret
rcalloc ENDP

rcread	PROC _CType PUBLIC USES bx si di rc:DWORD, wc:DWORD
local	lsize:	WORD
	push	ds
	xor	ax,ax
	mov	al,_scrcol
	add	ax,ax
	mov	lsize,ax
	HideMouseCursor
	invoke	rcsprc,rc
	mov	ds,dx
	mov	dx,ax
	les	di,wc
	mov	bx,di
	xor	ax,ax
	mov	cx,ax
	mov	al,rc.S_RECT.rc_col
	mov	ah,rc.S_RECT.rc_row
	cld?
    rcread_loop:
	mov	si,dx
	add	dx,lsize
	mov	cl,al
	rep	movsw
	dec	ah
	jnz	rcread_loop
	ShowMouseCursor
	mov	dx,es
	mov	ax,bx
	pop	ds
	ret
rcread	ENDP

rcwrite PROC _CType PUBLIC USES si di bx rc:DWORD, wc:DWORD
local lsize:WORD
	push	ds
	HideMouseCursor
	mov	ah,0
	mov	al,_scrcol
	add	ax,ax
	mov	lsize,ax
	invoke	rcsprc,rc
	mov	es,dx
	mov	dx,ax
	lds	si,wc
	mov	bx,si
	xor	ax,ax
	mov	cx,ax
	mov	al,rc.S_RECT.rc_col
	mov	ah,rc.S_RECT.rc_row
	cld?
    rcwrite_loop:
	mov	di,dx
	add	dx,lsize
	mov	cl,al
	rep	movsw
	dec	ah
	jnz	rcwrite_loop
	ShowMouseCursor
	mov	dx,ds
	mov	ax,bx
	pop	ds
	ret
rcwrite ENDP

rcxchg PROC _CType PUBLIC USES si di bx cx rc:DWORD, wc:DWORD
local lsize:size_t
	push	ds
	HideMouseCursor
	mov	ah,0
	mov	al,_scrcol
	add	ax,ax
	mov	lsize,ax
	invoke	rcsprc,rc
	mov	es,dx
	mov	di,ax
	mov	dx,ax
	mov	bx,WORD PTR [rc+2]
	lds	si,wc
	mov	ch,0
	cld?
    rcxchg_loopl:
	mov	di,dx
	add	dx,lsize
	mov	cl,bl
    rcxchg_loopc:
	mov	ax,es:[di]
	movsw
	mov	[si-2],ax
	dec	cx
	jnz	rcxchg_loopc
	dec	bh
	jnz	rcxchg_loopl
	ShowMouseCursor
	pop	ds
	ret
rcxchg	ENDP

RCInitShade PROC pascal PRIVATE rc:DWORD, wp:DWORD, rb:DWORD
	HideMouseCursor
	mov bx,WORD PTR rb
	sub ax,ax
	mov dx,ax
	mov cx,ax
	mov al,_scrcol
	add ax,ax
	mov [bx].SHADE.sh_wcount,ax
	mov ax,dx
	mov cl,rc.S_RECT.rc_row
	mov al,rc.S_RECT.rc_col
	mov [bx].SHADE.sh_xcount,ax
	mov [bx].SHADE.sh_cols,dx
	add al,rc.S_RECT.rc_x
	inc al
	cmp al,_scrcol
	ja  rcshade_init_01
	je  @F
	inc [bx].SHADE.sh_cols
      @@:
	inc [bx].SHADE.sh_cols
    rcshade_init_01:
	les di,wp
	mov al,rc.S_RECT.rc_col
	mul cl
	add ax,ax
	add di,ax
	mov [bx].SHADE.sh_boff,di
	invoke rcsprc,rc
	add ax,[bx].SHADE.sh_wcount
	add ax,[bx].SHADE.sh_xcount
	add ax,[bx].SHADE.sh_xcount
	inc ax
	mov [bx].SHADE.sh_soff,ax
	mov ds,dx
	mov dx,ax
	mov ah,_FG_DEACTIVE
	ret
RCInitShade ENDP

rcsetshade PROC _CType PUBLIC USES si di cx dx rc:DWORD, wp:DWORD
local	sh:SHADE
	push ds
	push bx
	invoke RCInitShade,rc,wp,addr sh
	.repeat
	    mov si,dx
	    add dx,sh.sh_wcount
	    .if sh.sh_cols >= 1
		mov al,[si]
		mov es:[di],al
		mov [si],ah
		.if !ZERO?
		    mov al,[si+2]
		    mov es:[di+1],al
		    mov [si+2],ah
		.endif
	    .endif
	    add di,2
	.untilcxz
	mov cx,sh.sh_xcount
	dec cx
	jz  rcsetshade_end
	dec cx
	jz  rcsetshade_end
	mov ah,_FG_DEACTIVE
	std
	sub si,2
      @@:
	movsb
	mov [si+1],ah
	dec si
	add di,2
	dec cx
	jnz @B
	cld
    rcsetshade_end:
	ShowMouseCursor
	pop bx
	pop ds
	ret
rcsetshade ENDP

rcclrshade PROC _CType PUBLIC USES si di rc:DWORD, wp:DWORD
local	sh:SHADE
	push ds
	push bx
	invoke RCInitShade,rc,wp,addr sh
    rcclrshade_00:
	mov si,dx
	add dx,sh.sh_wcount
	cmp sh.sh_cols,1
	jb  rcclrshade_01
	mov ax,es:[di]
	mov [si],al
	je  rcclrshade_01
	mov [si+2],ah
    rcclrshade_01:
	add di,2
	dec cx
	jnz rcclrshade_00
	mov cx,sh.sh_xcount
	dec cx
	jz  rcclrshade_end
	dec cx
	jz  rcclrshade_end
    rcclrshade_02:
	sub si,2
	mov al,es:[di]
	mov [si],al
	inc di
	dec cx
	jnz rcclrshade_02
    rcclrshade_end:
	ShowMouseCursor
	pop bx
	pop ds
	ret
rcclrshade ENDP

rcshow	PROC _CType PUBLIC rect:DWORD, flag:size_t, wp:DWORD
	mov	ax,flag
	and	ax,_D_DOPEN
	jz	rcshow_end
	test	BYTE PTR flag,_D_ONSCR
	jnz	@F
	invoke	rcxchg,rect,wp
	test	BYTE PTR flag,_D_SHADE
	jz	@F
	invoke	rcsetshade,rect,wp
      @@:
	mov	ax,1
    rcshow_end:
	ret
rcshow	ENDP

rchide	PROC _CType PUBLIC rect:DWORD, fl:size_t, wp:DWORD
	mov ax,fl
	.if ax & _D_DOPEN or _D_ONSCR
	    .if ax & _D_ONSCR
		invoke rcxchg,rect,wp
		.if fl & _D_SHADE
		    invoke rcclrshade,rect,wp
		.endif
	    .endif
	    mov ax,1
	.else
	    xor ax,ax
	.endif
	ret
rchide	ENDP

rcopen	PROC _CType PUBLIC rect:DWORD,flag:WORD,attrib:WORD,ttl:DWORD,wp:DWORD
	test	flag,_D_MYBUF
	jnz	@F
	invoke	rcalloc,rect,flag
	stom	wp
	jnz	@F
	jmp	rcopen_end
      @@:
	invoke	rcread,rect,wp
	mov	dx,flag
	and	dx,_D_CLEAR or _D_BACKG or _D_FOREG
	jz	rcopen_end
	mov	al,rect.S_RECT.rc_row
	mov	ah,0
	mul	rect.S_RECT.rc_col
	mov	cx,attrib
	cmp	dx,_D_CLEAR
	je	rcopen_clear
	cmp	dx,_D_COLOR
	je	rcopen_color
	cmp	dx,_D_BACKG
	je	rcopen_background
	cmp	dx,_D_FOREG
	je	rcopen_foreground
	mov	ch,cl
	mov	cl,' '
	invoke	wcputw,wp,ax,cx
	jmp	rcopen_title
    rcopen_clear:
	invoke	wcputw,wp,ax,' '
	jmp	rcopen_title
    rcopen_color:
	invoke	wcputa,wp,ax,cx
	jmp	rcopen_title
    rcopen_background:
	invoke	wcputbg,wp,ax,cx
	jmp	rcopen_title
    rcopen_foreground:
	invoke	wcputfg,wp,ax,cx
    rcopen_title:
	sub	ax,ax
	cmp	WORD PTR ttl,ax
	jz	rcopen_end
	mov	al,rect.S_RECT.rc_col
	invoke	wctitle,wp,ax,ttl
    rcopen_end:
	lodm	wp
	test	ax,ax
	ret
rcopen	ENDP

rcclose PROC _CType PUBLIC rect:DWORD, fl:size_t, wp:DWORD
	mov ax,fl
	.if ax & _D_DOPEN
	    .if ax & _D_ONSCR
		invoke rchide,rect,fl,wp
		mov ax,fl
	    .endif
	    .if !(ax & _D_MYBUF)
		invoke free,wp
	    .endif
	.endif
	mov ax,fl
	and ax,_D_DOPEN
	ret
rcclose ENDP

rcpush	PROC _CType PUBLIC lines:size_t
	mov	ah,BYTE PTR lines
	mov	al,_scrcol
	mov	dx,ax
	sub	ax,ax
	invoke	rcopen,dx::ax,0,0,0,0
	ret
rcpush	ENDP

rcmove PROC _CType PUBLIC USES di pRECT:DWORD, wp:DWORD, flag:size_t, x:size_t, y:size_t
local	rc:DWORD
	les di,pRECT
	movmx rc,es:[di]
	push es
	.if rchide(rc,flag,wp)
	    mov al,BYTE PTR x
	    mov ah,BYTE PTR y
	    mov rc.S_RECT.rc_x,al
	    mov rc.S_RECT.rc_y,ah
	    mov ax,flag
	    and ax,not _D_ONSCR
	    invoke rcshow,rc,ax,wp
	.endif
	pop es
	lodm rc
	stom es:[di]
	ret
rcmove	ENDP

rcstosw:
	.if ah
	    stosw
	.else
	    stosb
	    inc di
	.endif
	dec cl
	jnz rcstosw
	ret

rcframe PROC _CType PUBLIC USES si di bx cx dx rc:DWORD,
	wstr:DWORD, lsize:size_t, ftype:size_t
local	tmp[16]:BYTE
	cld?
	mov ax,ftype		; AL = Type [0,6,12,18]
	and ax,00FFh		; AH = Attrib
	add ax,offset frametypes
	mov si,ax		;------------------------
	lodsw			; [BP-2] UL 'Ú'
	mov [bp-2],ax		; [BP-1] HL 'Ä'
	lodsw			; [BP-4] UR '¿'
	mov [bp-4],ax		; [BP-3] VL '³'
	lodsw			; [BP-6] LL 'À'
	mov [bp-6],ax		; [BP-5] LR 'Ù'
	mov ax,lsize		;------------------------
	mov cl,al		; line size - 80 on screen
	add al,al
	mul rc.S_RECT.rc_y
	sub dx,dx
	mov dl,rc.S_RECT.rc_x
	add ax,dx
	add ax,dx
	les di,wstr
	add di,ax
	mov ah,0
	mov al,rc.S_RECT.rc_col
	sub al,2
	mov ch,al
	add ax,ax
	mov [bp-10],ax
	mov ax,ftype
	mov dl,rc.S_RECT.rc_row
	mov si,dx
	mov dl,cl
	add dx,dx
	mov bx,di
	mov cl,1
	mov al,[bp-2]	; Upper Left 'Ú'
	call rcstosw
	mov al,[bp-1]	; Horizontal Line 'Ä'
	mov cl,ch
	call rcstosw
	inc cl
	mov al,[bp-4]	; Upper Right '¿'
	call rcstosw
	.if si > 1
	    .if si != 2
		sub si,2
		.repeat
		    add bx,dx
		    mov di,bx
		    inc cl
		    mov al,[bp-3]	; Vertical Line '³'
		    call rcstosw
		    add di,[bp-10]
		    inc cl
		    call rcstosw
		    dec si
		.until !si
	    .endif
	    add bx,dx
	    mov di,bx
	    mov cl,1
	    mov al,[bp-6]	; Lower Left 'À'
	    call rcstosw
	    mov al,[bp-1]	; Horizontal Line 'Ä'
	    mov cl,ch
	    call rcstosw
	    inc cl
	    mov al,[bp-5]	; Lower Right 'Ù'
	    call rcstosw
	.endif
	ret
rcframe ENDP

ifdef __MOUSE__

rcmsmove PROC _CType PUBLIC USES di pRECT:DWORD, wp:DWORD, fl:size_t
local rc:DWORD
local xpos:size_t
local ypos:size_t
local relx:size_t
local rely:size_t
local cursor:S_CURSOR
	les di,pRECT
	movmx rc,es:[di]
	.if fl & _D_SHADE
	    invoke rcclrshade,rc,wp
	.endif
	call	mousey
	mov	ypos,ax
	mov	dx,ax
	call	mousex
	mov	xpos,ax
	mov	cx,WORD PTR rc
	sub	al,cl
	mov	relx,ax
	sub	dl,ch
	mov	rely,dx
	invoke	cursorget,addr cursor
	call	cursoroff
	.repeat
	    .if mousep() == 1	; KEY_MSLEFT
		call mousex
		cmp ax,xpos
		je @F
		ja rcmsmove_right
		cmp rc.S_RECT.rc_x,0
		jne rcmsmove_left
	      @@:
		call mousey
		cmp ax,ypos
		je @F
		ja rcmsmove_dn
		cmp rc.S_RECT.rc_y,1
		jne rcmsmove_up
	      @@:
		.continue
	      rcmsmove_up:
		mov ax,rcmoveup
		jmp rcmsmove_do
	      rcmsmove_dn:
		mov ax,rcmovedn
		jmp rcmsmove_do
	      rcmsmove_right:
		mov ax,rcmoveright
		jmp rcmsmove_do
	      rcmsmove_left:
		mov ax,rcmoveleft
	      rcmsmove_do:
		mov	cx,fl
		and	cx,not _D_SHADE
	      ifdef __CDECL__
		push	cx
		pushm	wp
		pushm	rc
	      else
		pushm	rc
		pushm	wp
		push	cx
	      endif
		pushl	cs
		call	ax
		mov	WORD PTR rc,ax
		mov	dx,ax
		mov	ax,rely
		add	al,dh
		mov	ypos,ax
		mov	ax,relx
		add	al,dl
		mov	xpos,ax
		ShowMouseCursor
	    .else
		.break
	    .endif
	.until 0
	invoke cursorset,addr cursor
	.if fl & _D_SHADE
	    invoke rcsetshade,rc,wp
	.endif
	les di,pRECT
	lodm rc
	stom es:[di]
	ret
rcmsmove ENDP
endif ; __MOUSE__

InitRCMove:
	pop	ax
	push	si
	push	di
	push	bx
	push	ds
	push	ax
	mov	ah,0
	mov	al,dh
	mov	L_ycn,ax
	mov	al,dl
	mov	L_xcn,ax
	add	ax,ax
	mov	L_wcn,ax
	mov	al,_scrcol
	add	ax,ax
	mov	L_scn,ax
	invoke	rcsprc,A_rc
	stom	L_scp
	.if A_sh & _D_SHADE
	    invoke rcclrshade,A_rc,A_wp
	.endif
	HideMouseCursor
	cld?
	ret
ExitRCMove:
	pop	ax
	pop	ds
	pop	bx
	pop	di
	pop	si
	push	ax
	ShowMouseCursor
	.if A_sh & _D_SHADE
	    invoke rcsetshade,A_rc,A_wp
	.endif
	lodm A_rc
	ret

rcmoveup PROC _CType PUBLIC rc:DWORD, wp:DWORD, flag:size_t
local rci[rcm.base]:BYTE
	lodm rc
	.if ah > 1
	    call InitRCMove
	    mov ax,L_scn
	    sub WORD PTR L_scp,ax
	    dec rc.S_RECT.rc_y
	    lds si,wp
	    mov ax,L_xcn
	    mov dx,L_ycn
	    mul dl
	    add ax,ax
	    add ax,si
	    sub ax,L_wcn
	    mov si,ax
	    les di,L_scp
	    mov ax,L_ycn
	    mov dx,L_scn
	    mul dx
	    add di,ax
	    xor bx,bx
	    mov cx,L_xcn
	    .repeat
		push cx
		push si
		push di
		mov cx,L_ycn
		mov dx,[bx+si]
		cmp cx,1
		je @F
		.repeat
		    push bx
		    sub bx,L_wcn
		    mov ax,[bx+si]
		    pop bx
		    mov [bx+si],ax
		  @@:
		    mov ax,es:[bx+di]
		    mov es:[bx+di],dx
		    mov dx,ax
		    sub di,L_scn
		    sub si,L_wcn
		.untilcxz
		mov ax,es:[bx+di]
		mov es:[bx+di],dx
		add si,L_wcn
		mov [bx+si],ax
		add bx,2
		pop di
		pop si
		pop cx
	    .untilcxz
	    call ExitRCMove
	.endif
	ret
rcmoveup ENDP

rcmovedn PROC _CType PUBLIC rc:DWORD, wp:DWORD, flag:size_t
local rci[rcm.base]:BYTE
	lodm rc
	.if _scrrow > ah
	    call InitRCMove
	    inc rc.S_RECT.rc_y
	    mov ax,L_scn
	    add WORD PTR L_scp,ax
	    mov ax,WORD PTR L_scp+2
	    mov es,ax
	    mov di,WORD PTR L_scp
	    xor bx,bx
	    mov cx,L_xcn
	    .repeat
		push cx
		lds si,wp
		mov di,WORD PTR L_scp
		sub di,L_scn
		mov cx,L_ycn
		mov dx,[bx+si]
		.repeat
		    mov ax,es:[bx+di]
		    mov es:[bx+di],dx
		    push ax
		    mov dx,bx
		    add bx,L_wcn
		    mov ax,[bx+si]
		    mov bx,dx
		    mov [bx+si],ax
		    add di,L_scn
		    add si,L_wcn
		    pop dx
		.untilcxz
		mov ax,es:[bx+di]
		mov es:[bx+di],dx
		sub si,L_wcn
		mov [bx+si],ax
		add bx,2
		pop cx
	    .untilcxz
	    call ExitRCMove
	.endif
	ret
rcmovedn ENDP

rcmoveright PROC _CType PUBLIC rc:DWORD, wp:DWORD, flag:size_t
local rci[rcm.base]:BYTE
	lodm rc
	.if _scrcol > al
	    call InitRCMove
	    inc rc.S_RECT.rc_x
	    add WORD PTR L_scp,2
	    les di,wp
	    mov ax,WORD PTR L_scp+2
	    mov ds,ax
	    mov dx,WORD PTR L_scp
	    mov cx,L_ycn
	    .repeat
		mov si,dx
		add dx,L_scn
		push cx
		mov cx,L_xcn
		mov bx,es:[di]
		.repeat
		    mov ax,[si-2]
		    mov [si-2],bx
		    mov bx,ax
		    mov ax,[si]
		    add si,2
		    mov ax,es:[di+2]
		    mov es:[di],ax
		    add di,2
		.untilcxz
		mov ax,[si-2]
		mov [si-2],bx
		mov es:[di-2],ax
		pop cx
	    .untilcxz
	    call ExitRCMove
	.endif
	ret
rcmoveright ENDP

rcmoveleft PROC _CType PUBLIC rc:DWORD, wp:DWORD, flag:size_t
local rci[rcm.base]:BYTE
	lodm rc
	.if al
	    call InitRCMove
	    dec rc.S_RECT.rc_x
	    sub WORD PTR L_scp,2
	    les di,wp
	    lds dx,L_scp
	    mov cx,L_ycn
	    .repeat
		mov si,dx
		add dx,L_scn
		mov ax,[si]
		add si,2
		mov bx,es:[di]
		mov es:[di],ax
		add di,2
		push cx
		mov cx,L_xcn
		dec cx
		.if !cx
		    mov ax,[si]
		    mov [si],bx
		    mov [si-2],ax
		.else
		    .repeat
			mov ax,[si]
			mov [si-2],ax
			add si,2
			mov ax,bx
			mov bx,es:[di]
			mov es:[di],ax
			add di,2
		    .untilcxz
		    mov ax,[si]
		    mov [si-2],ax
		    mov [si],bx
		    add si,2
		.endif
		pop cx
	    .untilcxz
	    call ExitRCMove
	.endif
	ret
rcmoveleft ENDP

rsopen	PROC _CType PUBLIC USES di si idd:DWORD
local	result:size_t
	push	ds
	lds	si,idd
	mov	ax,[si+8]	; rc_rows * rc_cols
	mov	dx,ax
	mul	ah
	mov	WORD PTR idd,ax
	add	ax,ax		; WORD size
	mov	di,ax
	test	WORD PTR [si+2],_D_SHADE
	jz	rsopen_00
	add	dl,dh
	add	dl,dh
	mov	dh,0
	sub	dx,2
	add	di,dx
    rsopen_00:
	mov	ax,[si]
	invoke	malloc,ax
	mov	result,ax
	mov	es,dx
	mov	bx,di
	mov	di,ax
	mov	dx,ax
	mov	cx,[si]
	jz	rsopen_end
	sub	ax,ax
	shr	cx,1
	cld?
	rep	stosw
	mov	cx,dx
	mov	di,dx
	lodsw			; skip size
	; -- copy dialog
	lodsw			; .flag
	or	ax,_D_SETRC
	push	ax
	stosw			; .flag
	movsw			; .count + .index
	movsw
	movsw
	sub	ax,ax
	mov	al,BYTE PTR [si-6]
	inc	ax
	shl	ax,4		; * size of objects (16)
	add	ax,cx		; + adress
	stosw			; = .wp (off)
	mov	dx,ax
	mov	ax,es
	stosw			; .wp (seg)
	mov	ax,16+4
	stosw			; .object (off)
	mov	ax,es
	stosw			; .object (seg)
	; -- copy objects
	add	dx,bx		; end of wp = start of object alloc
	sub	bx,bx
	mov	bl,[si-6]
	inc	bx
	jmp	rsopen_04
    rsopen_01:
	movsw
	movsw
	movsw
	movsw
	sub	ax,ax
	mov	al,BYTE PTR [si-6]
	shl	ax,4		; * 16
	test	ax,ax
	jz	rsopen_02
	xchg	ax,dx		; offset of mem (.data)
	stosw
	add	dx,ax
	mov	ax,es
	stosw
	sub	ax,ax
	jmp	rsopen_03
    rsopen_02:
	stosw
	stosw
    rsopen_03:
	stosw
	stosw
    rsopen_04:
	dec	bx
	jnz	rsopen_01
	pop	ax
	push	di
	inc	di
	mov	cx,WORD PTR idd
	and	ax,_D_RESAT
	jz	rsopen_05
	call	rsunzipat
	jmp	rsopen_06
    rsopen_05:
	call	rsunzipch
    rsopen_06:
	pop	di
	mov	cx,WORD PTR idd
	call	rsunzipch
	mov	dx,es
	mov	ax,result
	test	ax,ax
    rsopen_end:
	pop	ds
	mov	bx,ax
	ret
rsopen	ENDP

rsevent PROC _CType PUBLIC robj:DWORD, dobj:DWORD
	invoke	dlevent,dobj
	push	es
	push	bx
	les	bx,dobj
	mov	dx,es:[bx+4]
	les	bx,robj
	mov	es:[bx+6],dx
	pop	bx
	pop	es
	ret
rsevent ENDP

rsmodal PROC _CType PUBLIC robj:DWORD
	invoke	rsopen,robj
	jz	@F
	push	dx
	push	ax
	invoke	rsevent,robj,dx::ax
	call	dlclose
	mov	ax,dx
	test	ax,ax
      @@:
	ret
rsmodal ENDP

rsreload PROC _CType PUBLIC USES bx robj:DWORD, dobj:DWORD
	les bx,dobj
	mov ax,es:[bx]
	and ax,_D_DOPEN
	.if ax
	    invoke dlhide,dobj
	    push ax
	    sub ax,ax
	    mov al,es:[bx].S_DOBJ.dl_count
	    inc ax
	    shl ax,3
	    add ax,2
	    add ax,WORD PTR robj
	    mov dx,WORD PTR robj+2
	    mov cx,ax
	    mov al,es:[bx].S_DOBJ.dl_rect.rc_col
	    mul es:[bx].S_DOBJ.dl_rect.rc_row
	    .if es:[bx].S_DOBJ.dl_flag & _D_RESAT
		or ax,8000h
	    .endif
	    xchg cx,ax
	    invoke wcunzip,es:[bx].S_DOBJ.dl_wp,dx::ax,cx
	    invoke dlinit,dobj
	    pop ax
	    .if ax
		invoke dlshow,dobj
	    .endif
	.endif
	ret
rsreload ENDP

	END
