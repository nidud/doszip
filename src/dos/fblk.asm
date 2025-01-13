; CPDATEFR.ASM--
; Copyright (C) 2015 Doszip Developers

include dos.inc
include time.inc
include alloc.inc
include string.inc
include conio.inc
include wsub.inc
include fblk.inc

PUBLIC	cp_datefrm
PUBLIC	cp_dotdot
PUBLIC	cp_timefrm
PUBLIC	fbcolor

.data
cp_datefrm	db "%2u.%02u.%02u",0
cp_dotdot	db "..",0
cp_timefrm	db "%2u:%02u",0

.code

fbcolor PROC _CType
	.if ax & _A_SELECTED
	    mov al,at_foreground[F_Panel]
	.elseif ax & _A_UPDIR
	    mov al,at_foreground[F_Desktop]
	.elseif ax & _A_SYSTEM
	    mov al,at_foreground[F_System]
	.elseif ax & _A_HIDDEN
	    mov al,at_foreground[F_Hidden]
	.elseif ax & _A_SUBDIR
	    mov al,at_foreground[F_Subdir]
	.else
	    mov al,at_foreground[F_Files]
	.endif
	or al,at_background[B_Panel]
	ret
fbcolor ENDP

fbffirst PROC _CType PUBLIC fcb:DWORD, count:size_t
	xor	dx,dx
	jmp	fbffirst_init
    fbffirst_loop:
	mov	ax,dx
	shl	ax,2
	push	bx
	les	bx,fcb
	add	bx,ax
	les	bx,es:[bx]
	mov	cx,es:[bx]
	mov	ax,bx
	pop	bx
	test	cx,_A_SELECTED
	jz	fbffirst_next
	mov	dx,es
	jmp	fbffirst_end
    fbffirst_next:
	inc	dx
    fbffirst_init:
	cmp	count,dx
	jg	fbffirst_loop
	xor	ax,ax
	mov	dx,ax
    fbffirst_end:
	ret
fbffirst ENDP

fbinvert PROC _CType PUBLIC fblk:DWORD
	sub ax,ax
	les bx,fblk
	.if !es:[bx].S_FBLK.fb_flag & _A_UPDIR
	    xor es:[bx].S_FBLK.fb_flag,_A_SELECTED
	    inc ax
	.endif
	ret
fbinvert ENDP

fbselect PROC _CType PUBLIC fblk:DWORD
	sub ax,ax
	les bx,fblk
	.if !es:[bx].S_FBLK.fb_flag & _A_UPDIR
	    or es:[bx].S_FBLK.fb_flag,_A_SELECTED
	    inc ax
	.endif
	ret
fbselect ENDP

fballoc PROC _CType PUBLIC USES bx fname:PTR BYTE, ftime:DWORD, fsize:DWORD, flag:size_t
	invoke strlen,fname
	add ax,S_FBLK
	.if malloc(ax)
	    add ax,S_FBLK.fb_name
	    invoke strcpy,dx::ax,fname
	    sub ax,S_FBLK.fb_name
	    mov bx,ax
	    mov cx,flag
	    mov es:[bx].S_FBLK.fb_flag,cx
	    movmx es:[bx].S_FBLK.fb_time,ftime
	    movmx es:[bx].S_FBLK.fb_size,fsize
	    mov ax,bx
	.endif
	ret
fballoc ENDP

fballocff PROC _CType PUBLIC USES bx ffblk:DWORD, flag:size_t
	les bx,ffblk
	sub cx,cx
	mov cl,BYTE PTR es:[bx].S_FFBLK.ff_attrib
	or  cx,flag
	.if fballoc(addr es:[bx].S_FFBLK.ff_name,DWORD PTR es:[bx].S_FFBLK.ff_ftime,
	    es:[bx].S_FFBLK.ff_fsize,cx)
	    mov bx,ax
	    .if WORD PTR es:[bx].S_FBLK.fb_name == '..' && es:[bx].S_FBLK.fb_name[2] == 0
		or es:[bx].S_FBLK.fb_flag,_A_UPDIR
	    .endif
	    .if !(cl & _A_SUBDIR)
		add ax,S_FBLK.fb_name
		.if cl & _A_SYSTEM or _A_HIDDEN
		    inc ax
		.endif
		invoke strlwr,dx::ax
		mov ax,bx
	    .endif
	.endif
	ret
fballocff ENDP

fballocwf PROC _CType PUBLIC USES di bx wfblk:DWORD, flag:size_t
	les bx,wfblk
	mov  di,bx
	mov  ax,flag
	or   al,es:[bx]
	and  al,_A_FATTRIB
	mov  cx,ax
	add  bx,S_WFBLK.wf_name
	lodm es:[di].S_WFBLK.wf_time
	.if cl & _A_SUBDIR
	    lodm es:[di].S_WFBLK.wf_timecreate
	.endif
	.if fballoc(es::bx,dx::ax,es:[di].S_WFBLK.wf_sizeax,cx)
	    .if cl & _A_SUBDIR && \
		WORD PTR es:[bx].S_FBLK.fb_name == '..' && \
		BYTE PTR es:[bx].S_FBLK.fb_name[2] == 0
		or es:[bx].S_FBLK.fb_flag,_A_UPDIR
	    .endif
	.endif
	ret
fballocwf ENDP

fbupdir PROC _CType PUBLIC flag:size_t
	call	dostime
	mov	cx,flag
	or	cx,_A_UPDIR or _A_SUBDIR
	invoke	fballoc,addr cp_dotdot,dx::ax,0,cx
	ret
fbupdir ENDP

	END
