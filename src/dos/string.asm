; STRING.ASM--
; Copyright (C) 2015 Doszip Developers

include string.inc
include dir.inc

	.code

memcpy PROC _CType PUBLIC USES si di s1:PTR BYTE, s2:PTR BYTE, count:size_t
	push	ds
	les	di,s1
	lds	si,s2
	mov	cx,count
	mov	ax,di
	mov	dx,WORD PTR s1+2
	rep	movsb
	pop	ds
	ret
memcpy ENDP

memmove PROC _CType PUBLIC USES si di s1:PTR BYTE, s2:PTR BYTE, cnt:size_t
	push	ds
	les	di,s1
	lds	si,s2
	mov	cx,cnt
	mov	dx,WORD PTR s1+2
	mov	ax,di
	cld?
	cmp	ax,si
	jbe	@F
	std
	add	si,cx
	add	di,cx
	sub	si,1
	sub	di,1
      @@:
	rep	movsb
	cld
	pop	ds
	ret
memmove ENDP

strcat PROC _CType PUBLIC USES si di s1:PTR BYTE, s2:PTR BYTE
	push	ds
	cld?
	mov	al,0
	les	di,s1
	lds	si,s2
	mov	cx,-1
	repne	scasb
	dec	di
      @@:
	mov	al,[si]
	mov	es:[di],al
	inc	di
	inc	si
	test	al,al
	jnz	@B
	lodm	s1
	pop	ds
	ret
strcat ENDP

strchr	PROC _CType PUBLIC USES di s1:PTR BYTE, char:size_t
	sub	ax,ax
	mov	dx,ax
	les	di,s1
      @@:
	mov	al,es:[di]
	test	al,al
	jz	@F
	inc	di
	cmp	al,BYTE PTR char
	jne	@B
	mov	dx,es
	mov	ax,di
	dec	ax
      @@:
	ret
strchr	ENDP

strcmp	PROC _CType PUBLIC USES si di s1:PTR BYTE, s2:PTR BYTE
	push	ds
	lds	si,s2
	les	di,s1
	mov	al,-1
      @@:
	test	al,al
	jz	@F
	mov	al,[si]
	inc	si
	mov	ah,es:[di]
	inc	di
	cmp	ah,al
	je	@B
	sbb	al,al
	sbb	al,-1
      @@:
	cbw
	pop	ds
	ret
strcmp ENDP

strcpy	PROC _CType PUBLIC USES si di s1:PTR BYTE, s2:PTR BYTE
	push	ds
	cld?
	sub	al,al
	mov	cx,-1
	les	di,s2
	repne	scasb
	les	di,s1
	lds	si,s2
	mov	ax,di
	not	cx
	shr	cx,1
	rep	movsw
	jc	strcpy_mov
    strcpy_end:
	mov	dx,WORD PTR s1+2
	pop	ds
	ret
    strcpy_mov:
	movsb
	jmp strcpy_end
strcpy	ENDP

stricmp PROC _CType PUBLIC USES si di s1:PTR BYTE, s2:PTR BYTE
	push	ds
	les	di,s1
	lds	si,s2
	mov	al,-1
      @@:
	test	al,al
	jz	@F
	mov	al,[si]
	mov	ah,es:[di]
	inc	si
	inc	di
	cmp	ah,al
	je	@B
	cmpaxi
	je	@B
	sbb	al,al
	sbb	al,-1
      @@:
	cbw
	pop	ds
	ret
stricmp ENDP

strlen	PROC _CType PUBLIC USES di string:PTR BYTE
	cld?
	mov	al,0
	les	di,string
	mov	cx,-1
	repne	scasb
	mov	ax,cx
	not	ax
	dec	ax
	ret
strlen	ENDP

strlwr PROC _CType PUBLIC USES si string:PTR BYTE
	push	ds
	lds	si,string
      @@:
	mov	al,[si]
	test	al,al
	jz	@F
	sub	al,'A'
	cmp	al,'Z' - 'A' + 1
	sbb	al,al
	and	al,'a' - 'A'
	xor	[si],al
	inc	si
	jmp	@B
      @@:
	lodm	string
	pop	ds
	ret
strlwr	ENDP

strnicmp PROC _CType PUBLIC USES si di s1:PTR BYTE, s2:PTR BYTE, count:size_t
	push	ds
	lds	si,s1
	les	di,s2
	mov	cx,count
	inc	cx
      @@:
	dec	cx
	jz	@F
	mov	al,[si]
	mov	ah,es:[di]
	inc	si
	inc	di
	test	al,al
	jz	@F
	cmp	ah,al
	je	@B
	cmpaxi
	je	@B
      @@:
	sub	al,ah
	cbw
	pop	ds
	ret
strnicmp ENDP

strrchr PROC _CType PUBLIC USES di s1:PTR BYTE, char:size_t
	les	di,s1
	sub	ax,ax
	mov	dx,ax
	cld?
	mov	cx,-1
	repne	scasb
	not	cx
	dec	di
	std
	mov	al,BYTE PTR char
	repne	scasb
	mov	al,0
	jne	@F
	mov	dx,es
	mov	ax,di
	inc	ax
      @@:
	cld
	test	ax,ax
	ret
strrchr ENDP

strrev	PROC _CType PUBLIC USES cx si di string:PTR BYTE
	push	ds
	cld?
	lds	si,string
	les	di,string
	mov	al,0
	mov	cx,-1
	repnz	scasb
	cmp	cx,-2
	je	strrev_02
	sub	di,2
	xchg	si,di
	jmp	strrev_01
    strrev_00:
	mov	al,[di]
	movsb
	mov	[si-1],al
	sub	si,2
    strrev_01:
	cmp	di,si
	jc	strrev_00
    strrev_02:
	lodm	string
	pop	ds
	ret
strrev	ENDP

;---------

atohex PROC _CType PUBLIC USES si di string:PTR BYTE
	mov	di,WORD PTR string
	invoke	strlen,string
	test	ax,ax
	jz	atohex_end
	cmp	ax,64
	jnb	atohex_end
	dec	ax
	mov	si,di
	add	si,ax
	add	ax,ax
	add	di,ax
	mov	BYTE PTR es:[di][2],0
    atohex_loop:
	mov	al,es:[si]
	mov	ah,al
	shr	al,4
	and	ah,15
	add	ax,'00'
	cmp	al,'9'
	jbe	atohex_01
	add	al,7
    atohex_01:
	cmp	ah,'9'
	jbe	atohex_02
	add	ah,7
    atohex_02:
	mov	es:[di],ax
	dec	si
	sub	di,2
	cmp	di,si
	jae	atohex_loop
    atohex_end:
	lodm	string
	ret
atohex ENDP

cmpwarg PROC _CType PUBLIC USES si di filep:PTR BYTE, maskp:PTR BYTE
	push	ds
	lds	si,filep
	les	di,maskp
	xor	ax,ax
    cmpwarg_next:
	mov	al,[si]
	mov	ah,es:[di]
	inc	si
	inc	di
	cmp	ah,'*'
	je	cmpwarg_star
	test	al,al
	jz	cmpwarg_zero
	test	ah,ah
	jz	cmpwarg_zero
	cmp	ah,'?'
	je	cmpwarg_next
	cmp	ah,'.'
	je	cmpwarg_04
	cmp	al,'.'
	je	cmpwarg_fail
	or	ax,2020h
	cmp	ah,al
	je	cmpwarg_next
	jmp	cmpwarg_fail
    cmpwarg_zero:
	test	ax,ax
	jnz	cmpwarg_fail
    cmpwarg_ok:
	mov	ax,1
    cmpwarg_end:
	test	ax,ax
	pop	ds
	ret
    cmpwarg_04:
	cmp	al,'.'
	je	cmpwarg_next
    cmpwarg_fail:
	xor	ax,ax
	jmp	cmpwarg_end
    cmpwarg_star:
	mov	ah,es:[di]
	test	ah,ah
	jz	cmpwarg_ok	; find '.' --> '*' | '*abc' | '*.txt'
	inc	di
	cmp	ah,'.'
	jne	cmpwarg_star
	xor	dx,dx		; found
    cmpwarg_type:
	test	al,al
	jz	cmpwarg_test
	cmp	al,ah
	je	cmpwarg_dxsi
    cmpwarg_lods:
	mov	al,[si]
	inc	si
	jmp	cmpwarg_type
    cmpwarg_dxsi:
	mov	dx,si
	jmp	cmpwarg_lods
    cmpwarg_test:
	test	dx,dx
	mov	si,dx
	jnz	cmpwarg_next
	mov	ah,es:[di]
	inc	di
	cmp	ah,'*'
	je	cmpwarg_star
	jmp	cmpwarg_zero
cmpwarg ENDP

cmpwargs PROC _CType PUBLIC USES di filep:PTR BYTE, maskp:PTR BYTE
	les di,maskp
	.repeat
	    .if strchr(es::di,' ')
		mov di,ax
		mov BYTE PTR es:[di],0
		invoke cmpwarg,filep,dx::ax
		mov BYTE PTR es:[di],' '
		inc di
	    .else
		invoke cmpwarg,filep,es::di
		.break
	    .endif
	.until ax
	ret
cmpwargs ENDP

dostounix PROC _CType PUBLIC USES di string:PTR BYTE
	les	di,string
	mov	ah,'/'
      @@:
	mov	al,es:[di]
	inc	di
	test	al,al
	jz	@F
	cmp	al,'\'
	jne	@B
	mov	es:[di-1],ah
	jmp	@B
      @@:
	lodm	string
	ret
dostounix ENDP

hextoa	PROC _CType PUBLIC USES si di string:PTR BYTE
	les di,string
	mov  si,di
	.repeat
	    mov ax,[si]
	    inc si
	    .continue .if al == ' '
	    inc si
	    mov dl,ah
	    .break .if !al
	    sub ax,'00'
	    .if al > 9
		sub al,7
	    .endif
	    shl al,4
	    .if ah > 9
		sub ah,7
	    .endif
	    or	ah,al
	    mov es:[di],ah
	    inc di
	.until !dl
	sub  al,al
	mov  es:[di],al
	lodm string
	ret
hextoa ENDP

memxchg PROC _CType PUBLIC USES si di s1:PTR BYTE, s2:PTR BYTE, count:size_t
	push	ds
	les	di,s1
	lds	si,s2
	mov	cx,count
	cld?
      @@:
	mov	al,es:[di]
	movsb
	mov	[si-1],al
	dec	cx
	jnz	@B
	lodm	s1
	pop	ds
	ret
memxchg ENDP

memzero PROC _CType PUBLIC USES di s1:PTR BYTE, count:size_t
	mov	cx,count
	les	di,s1
	cld?
	sub	ax,ax
	rep	stosb
	ret
memzero ENDP

setfext PROC _CType PUBLIC path:PTR BYTE, ext:PTR BYTE
	.if strext(path)
	    xchg ax,bx
	    mov BYTE PTR es:[bx],0
	    mov bx,ax
	.endif
	invoke strcat,path,ext
	ret
setfext ENDP

strcmpi PROC PUBLIC
	push	si
	push	di
      @@:
	mov	ah,[si]
	mov	al,es:[di]
	test	ah,ah
	jz	@F
	cmpaxi
	jne	@F
	inc	si
	inc	di
	jmp	@B
      @@:
	mov	cx,di
	pop	di
	pop	dx
	ret
strcmpi ENDP

strext	PROC _CType PUBLIC string:PTR BYTE
	invoke	strfn,string
	push	ax
	invoke	strrchr,dx::ax,'.'
	pop	cx
	jz	@F
	cmp	ax,cx
	jne	@F
	sub	ax,ax
      @@:
	ret
strext	ENDP

strfcat PROC _CType PUBLIC USES si di s1:PTR BYTE, s2:PTR BYTE, s3:PTR BYTE
	push	ds
	sub	ax,ax
	les	di,s1
	mov	dx,di
	mov	cx,-1
	cld?
	cmp	WORD PTR s2,ax
	je	@F
	les	di,s2
	repne	scasb
	les	di,s1
	lds	si,s2
	not	cx
	rep	movsb
	jmp	strfcat_test
      @@:
	repne	scasb
    strfcat_test:
	dec	di
	cmp	di,dx
	je	strfcat_loop
	mov	BYTE PTR es:[di],'\'
	dec	di
	mov	al,es:[di]
	cmp	al,'\'
	je	@F
	cmp	al,'/'
	je	@F
	inc	di
      @@:
	inc	di
    strfcat_loop:
	lds	si,s3
      @@:
	mov	al,[si]
	mov	es:[di],al
	inc	di
	inc	si
	test	al,al
	jnz	@B
	mov	es:[di],al
	lodm	s1
	pop	ds
	ret
strfcat ENDP

strfn	PROC _CType PUBLIC USES di s1:PTR BYTE
	les	di,s1
	sub	ax,ax
	mov	cx,ax
	dec	cx
	cld?
	repne	scasb
	not	cx
      @@:
	dec	di
	mov	al,es:[di]
	cmp	al,'/'
	je	@F
	cmp	al,'\'
	je	@F
	dec	cx
	jnz	@B
      @@:
	lodm	s1
	cmp	di,ax
	je	@F
	cmp	BYTE PTR es:[di],0
	je	@F
	mov	ax,di
	inc	ax
      @@:
	ret
strfn ENDP

strnzcpy PROC _CType PUBLIC USES si di s1:PTR BYTE, s2:PTR BYTE, count:size_t
	push	ds
	lds	si,s2
	les	di,s1
	sub	ax,ax
	mov	cx,count
	cmp	cx,2
	jb	toend
	dec	cx
	cld?
      @@:
	movsb
	dec	cx
	jz	@F
	cmp	[si-1],al
	jne	@B
      @@:
	mov	es:[di],al
toend:
	lodm	s1
	pop	ds
	ret
strnzcpy ENDP

strpath PROC _CType PUBLIC USES di s1:PTR BYTE
	invoke	strfn,s1
	mov	di,ax
	lodm	s1
	cmp	ax,di
	je	@F
	dec	di
      @@:
	mov	BYTE PTR es:[di],0
	ret
strpath ENDP

strstart PROC _CType PUBLIC USES di string:PTR BYTE
	les	di,string
	mov	dx,es
      @@:
	mov	al,es:[di]
	inc	di
	test	al,al
	jz	@F
	cmp	al,' '
	je	@B
	cmp	al,9
	je	@B
      @@:
	mov	ax,di
	dec	ax
	ret
strstart ENDP

strtrim PROC _CType PUBLIC USES di string:PTR BYTE
	les	di,string
	mov	dx,es
	sub	ax,ax
	cld?
	mov	cx,-1
	repne	scasb
	not	cx
	dec	di
	mov	al,' '
      @@:
	dec	di
	dec	cx
	jz	@F
	cmp	es:[di],al
	ja	@F
	mov	es:[di],ah
	jmp	@B
      @@:
	mov	ax,di
	sub	ax,WORD PTR string
	inc	ax
	ret
strtrim ENDP

strxchg PROC _CType PUBLIC USES si di strb:PTR BYTE, ostr:PTR BYTE, nstr:PTR BYTE, olen:size_t
local convb[1024]:BYTE
	push	ds
    strxchg_00:
	les	di,strb
	lds	si,ostr
	sub	al,al
	cmp	al,[si]
	je	strxchg_03
    strxchg_01:
	mov	al,[si]
	mov	ah,al
	sub	al,'A'
	cmp	al,'Z' - 'A' + 1
	sbb	al,al
	and	al,'a' - 'A'
	xor	ah,al
    strxchg_02:
	mov	al,es:[di]
	test	al,al
	jz	strxchg_03
	mov	dl,al
	sub	al,'A'
	cmp	al,'Z' - 'A' + 1
	sbb	al,al
	and	al,'a' - 'A'
	xor	dl,al
	mov	al,dl
	inc	di
	cmp	al,ah
	jne	strxchg_02
	inc	si
	call	strcmpi
	mov	si,WORD PTR ostr
	jnz	strxchg_01
	mov	dx,es
	mov	ax,di
	dec	ax
	jmp	strxchg_04
    strxchg_03:
	sub	ax,ax
	mov	dx,es
	mov	ax,WORD PTR strb
    strxchg_04:
	jnz	strxchg_05
	pop	ds
	ret
    strxchg_05:
	mov	si,ax
	mov	BYTE PTR [si],0
	invoke	strcpy,addr convb,strb
	invoke	strcat,dx::ax,nstr
	add	si,olen
	mov	cx,WORD PTR strb+2
	invoke	strcat,dx::ax,cx::si
	mov	si,ax
	add	si,WMAXPATH-1
	mov	BYTE PTR [si],0
	invoke	strcpy,strb,dx::ax
	jmp	strxchg_00
strxchg ENDP

unixtodos PROC _CType PUBLIC USES si string:PTR BYTE
	push	ds
	lds	si,string
	mov	ah,'\'
      @@:
	mov	al,[si]
	inc	si
	test	al,al
	jz	@F
	cmp	al,'/'
	jne	@B
	mov	[si-1],ah
	jmp	@B
      @@:
	lodm	string
	pop	ds
	ret
unixtodos ENDP

	END

