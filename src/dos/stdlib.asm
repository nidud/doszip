; STDLIB.ASM--
; Copyright (C) 2015 Doszip Developers

include stdlib.inc
include string.inc
include alloc.inc
include dos.inc
include dir.inc

extrn	envpath: DWORD
extrn	envseg:WORD
extrn	envlen:WORD
extrn	_psp:WORD
extrn	C0_argc:WORD
extrn	C0_argv:DWORD

	PUBLIC	_argc
	PUBLIC	_argv

	.data
	_argc	dw ?
	_argv	dd ?

	__setargv__ label WORD
	PUBLIC	__setargv__

	_ip	dw ?
	_si	dw ?
	_di	dw ?

	.code

atol PROC _CType PUBLIC USES bx cx si di string:PTR BYTE
	push	es
	les	bx,string
	sub	cx,cx
      @@:
	mov	cl,es:[bx]
	inc	bx
	cmp	cl,' '
	je	@B
	push	cx
	cmp	cl,'-'
	je	@F
	cmp	cl,'+'
	jne	atol_set
      @@:
	mov	cl,es:[bx]
	inc	bx
    atol_set:
	sub	ax,ax
	sub	dx,dx
    atol_loop:
	sub	cl,'0'
	jc	@F
	cmp	cl,9
	ja	@F
	mov	si,dx
	mov	di,ax
ifdef __16__
	shl	ax,1
	rcl	dx,1
	shl	ax,1
	rcl	dx,1
	shl	ax,1
	rcl	dx,1
else
	shl	dx,3
	shld	ax,dx,3
endif
	add	ax,di
	adc	dx,si
	add	ax,di
	adc	dx,si
	add	ax,cx
	adc	dx,0
	mov	cl,es:[bx]
	inc	bx
	jmp	atol_loop
      @@:
	pop	cx
	cmp	cl,'-'
	je	atol_neg
    atol_end:
	pop	es
	ret
    atol_neg:
	neg	ax
	neg	dx
	sbb	ax,0
	jmp	atol_end
atol	ENDP

getenvp PROC _CType PUBLIC USES si di bx enval:PTR BYTE
	push	ds
	mov	es,envseg
	lds	si,enval
	mov	al,[si]
	call	ftolower
	mov	bl,al
	mov	cx,7FFFh
	xor	ax,ax
	mov	di,ax
	cld
    getenvp_00:
	mov	al,es:[di]
	call	ftolower
	cmp	al,bl
	je	getenvp_02
    getenvp_01:
	mov	al,0
	repnz	scasb
	test	cx,cx
	jz	getenvp_null
	cmp	es:[di],al
	jne	getenvp_00
	jmp	getenvp_null
    getenvp_02:
	push	cx
	call	strcmpi
	mov	si,cx
	pop	cx
	jz	getenvp_03
	cmp	ah,'%'
	je	getenvp_04
    getenvp_03:
	cmp	ax,'='
	je	getenvp_04
	mov	si,dx
	mov	al,[si]
	call	ftolower
	mov	bl,al
	jmp	getenvp_01
    getenvp_04:
	mov	di,si
	cmp	al,'='
	jne	getenvp_01
	inc	di
	mov	ax,di
	mov	dx,es
	jmp	getenvp_end
    getenvp_null:
	xor	ax,ax
	cwd
    getenvp_end:
	pop	ds
	ret
getenvp ENDP

expenviron PROC _CType PUBLIC USES si di bx string:PTR BYTE ; [128]
local envl:WORD
local environ[132]:BYTE
local expanded[132]:BYTE
	mov di,WORD PTR string
	.repeat
	    mov ax,WORD PTR string+2
	    .break .if !strchr(ax::di,'%'); get start of [%]environ%
	    mov si,ax
	    inc ax
	    .break .if !strchr(dx::ax,'%'); get end of %environ[%]
	    mov di,ax
	    sub ax,si
	    inc ax	; = length of %environ%
	    mov envl,ax
	    .if ax < 128
		lea bx,environ
		invoke strnzcpy,ss::bx,dx::si,ax ; copy %environ% to stack
		inc ax
		.if getenvp(dx::ax)
		    lea bx,expanded
		    invoke strnzcpy,ss::bx,dx::ax,128
		    invoke strlen,dx::ax
		    mov bx,ax
		    invoke strlen,string
		    add ax,bx
		    sub ax,envl
		    .if ax < 128
			mov cx,di
			sub cx,si
			inc cx ; xchg %environ% with value
			invoke strxchg,string,addr environ,addr expanded,cx
			invoke strlen,addr expanded
			add ax,si
			dec ax
			mov di,ax ; move to end of %environ%
		    .endif
		.endif
	    .endif
	    inc di
	.until 0
	ret
expenviron ENDP

isexec	PROC _CType PUBLIC	; (char *filename);
ifdef __3__
	.if strrchr(dx::ax,'.')
	    mov bx,ax
	    mov eax,es:[bx+1]
	    or	eax,'   '
	    .if eax == 'tab'
		mov ax,1
	    .elseif eax == 'moc'
		mov ax,2
	    .elseif eax == 'exe'
		mov ax,3
	    .else
		sub ax,ax
	    .endif
	.endif
	ret
else
	invoke	strrchr,dx::ax,'.'
	jz	isexec_NOT
	mov	es,dx
	inc	ax
	mov	bx,ax
	mov	dx,'  '
	mov	ax,es:[bx]
	mov	bx,es:[bx+2]
	or	ax,dx
	or	bx,dx
	cmp	ax,'ab'
	je	isexec_BAT
	cmp	ax,'oc'
	je	isexec_COM
	cmp	ax,'xe'
	je	isexec_EXE
    isexec_NOT:
	xor	ax,ax
    isexec_END:
	ret
    isexec_EXE:
	cmp	bx,' e'
	jne	isexec_NOT
	mov	ax,3	; 3 = EXE
	jmp	isexec_END
    isexec_COM:
	cmp	bx,' m'
	jne	isexec_NOT
	mov	ax,2	; 2 = COM
	jmp	isexec_END
    isexec_BAT:
	cmp	bx,' t'
	jne	isexec_NOT
	mov	ax,1	; 1 = BAT
	jmp	isexec_END
endif
isexec	ENDP

mkbstring PROC _CType PUBLIC qw_buf:PTR BYTE, qw_h:DWORD, qw_l:DWORD
	invoke qwtobstr,qw_h,qw_l
	invoke strcpy,qw_buf,dx::ax
	push bx
ifdef __3__
	mov eax,qw_h
	mov edx,qw_l
	.if eax || edx
	    shl eax,22
	    shr edx,10
	    or eax,edx
	    mov edx,1
	    .repeat
		.break .if eax < 10000
		shr eax,10
		inc edx
	    .until 0
	    mov bx,dx
	    shld edx,eax,16
	    or dx,bx
	.endif
else
	mov bx,WORD PTR qw_h
	mov dx,WORD PTR qw_l
	mov ax,WORD PTR qw_h+2
	or  ax,bx
	.if ax || dx
	    shr dx,10	; cx:dx qw_l
	    mov ax,WORD PTR qw_l+2
	    mov cx,ax
	    shl ax,6
	    or	dx,ax
	    shr cx,10
	    shl bx,6	; bx::0 qw_h
	    or cx,bx
	    mov ax,dx
	    mov dx,1
	    .repeat
		.break .if !cx && ax < 10000
		mov bx,cx
		shr cx,10
		shl bx,6
		shr ax,10
		or  ax,bx
		inc dx
	    .until 0
	.endif
endif
	pop bx
	ret
mkbstring ENDP

qsort	PROC _CType PUBLIC USES si di bx p:DWORD, n:WORD, w:WORD, compare:DWORD
	mov	ax,n
	cmp	ax,1
	ja	@F
	jmp	toend
     @@:
	dec	ax
	mul	w
	les	si,p
	mov	di,ax
	add	di,si
	push	0
recurse:
	mov	cx,w
	mov	ax,di
	add	ax,cx
	sub	ax,si
	jz	@F
	sub	dx,dx
	div	cx
	shr	ax,1
	mul	cx
     @@:
	add	ax,si
	mov	bx,ax

	mov	ax,WORD PTR p[2]
	push	bx
	push	ax
	push	si
	push	ax
	push	bx
	call	compare
	pop	bx
	cmp	ax,0
	jle	@F
	mov	ax,WORD PTR p[2]
	invoke	memxchg,ax::bx,ax::si,w
     @@:
	mov	ax,WORD PTR p[2]
	push	bx
	push	ax
	push	si
	push	ax
	push	di
	call	compare
	pop	bx
	cmp	ax,0
	jle	@F
	mov	ax,WORD PTR p[2]
	invoke	memxchg,ax::di,ax::si,w
     @@:
	mov	ax,WORD PTR p[2]
	push	bx
	push	ax
	push	bx
	push	ax
	push	di
	call	compare
	pop	bx
	cmp	ax,0
	jle	@F
	mov	ax,WORD PTR p[2]
	invoke	memxchg,ax::bx,ax::di,w
     @@:
	mov	WORD PTR p,si
	mov	n,di
lup:
	mov	ax,w
	add	WORD PTR p,ax
	cmp	WORD PTR p,di
	jae	@F
	mov	ax,WORD PTR p[2]
	push	bx
	push	ax
	push	WORD PTR p
	push	ax
	push	bx
	call	compare
	pop	bx
	cmp	ax,0
	jle	lup
     @@:
	mov	ax,w
	sub	n,ax
	cmp	n,bx
	jbe	@F
	mov	ax,WORD PTR p[2]
	push	bx
	push	ax
	push	n
	push	ax
	push	bx
	call	compare
	pop	bx
	cmp	ax,0
	jg	@B
     @@:
	mov	ax,WORD PTR p
	cmp	n,ax
	jb	break
	mov	dx,WORD PTR p[2]
	mov	cx,n
	invoke	memxchg,dx::ax,dx::cx,w
	cmp	bx,n
	jne	lup
	mov	bx,WORD PTR p
	jmp	lup
break:
	mov	ax,w
	add	n,ax
     @@:
	mov	ax,w
	sub	n,ax
	cmp	n,si
	jbe	recursion
	mov	ax,WORD PTR p[2]
	push	bx
	push	ax
	push	n
	push	ax
	push	bx
	call	compare
	pop	bx
	test	ax,ax
	jz	@B
recursion:
	mov	ax,n
	sub	ax,si
	mov	cx,di
	sub	cx,WORD PTR p
	cmp	ax,cx
	jl	lower
	cmp	si,n
	jae	@F
	pop	ax
	push	si
	push	n
	inc	ax
	push	ax
     @@:
	cmp	WORD PTR p,di
	jae	pending
	mov	si,WORD PTR p
	jmp	recurse
lower:
	cmp	WORD PTR p,di
	jae	@F
	pop	ax
	push	WORD PTR p
	push	di
	inc	ax
	push	ax
     @@:
	cmp	si,n
	jae	pending
	mov	di,n
	jmp	recurse
pending:
	pop	ax
	test	ax,ax
	jz	toend
	dec	ax
	pop	di
	pop	si
	push	ax
	jmp	recurse
toend:
	ret
qsort	ENDP

qwtobstr PROC _CType PUBLIC USES si di odx:DWORD, oax:DWORD
local	result[128]:BYTE
	invoke	qwtostr,odx,oax
	invoke	strrev,dx::ax
	mov	si,ax
	lea	di,result
	sub	dx,dx
      @@:
	lodsb
	stosb
	test	al,al
	jz	@F
	inc	dl
	cmp	dl,3
	jne	@B
	mov	al,' '
	stosb
	sub	dl,dl
	jmp	@B
      @@:
	cmp	BYTE PTR [di-2],' '
	jne	@F
	mov	[di-2],dh
      @@:
	invoke	strrev,addr result
	ret
qwtobstr ENDP

ifndef	__16__

qwtostr PROC _CType PUBLIC USES esi edi ebx odx:DWORD, oax:DWORD
local	result[128]:BYTE
	lea	di,result+40
	mov	result[40],0
	mov	edx,odx
	mov	eax,oax
    qwtostr_mul:
	push	edi
	mov	ebx,10
	test	edx,edx
	jnz	qwtostr_64
	div	ebx
	mov	ebx,edx
	sub	edx,edx
	jmp	qwtostr_break
    qwtostr_64:
	mov	ecx,64
	sub	esi,esi
	mov	edi,esi
    qwtostr_lup:
	shl	eax,1
	rcl	edx,1
	rcl	esi,1
	rcl	edi,1
	cmp	edi,0
	jb	qwtostr_next
	ja	qwtostr_sub
	cmp	esi,ebx
	jb	qwtostr_next
    qwtostr_sub:
	sub	esi,ebx
	sbb	edi,0
	inc	eax
    qwtostr_next:
	dec	ecx
	jnz	qwtostr_lup
	mov	ebx,esi
    qwtostr_break:
	pop	edi
	add	ebx,'0'
	dec	di
	mov	[di],bl
	lea	cx,result
	cmp	di,cx
	jbe	qwtostr_end
	mov	cx,dx
	or	cx,ax
	jnz	qwtostr_mul
    qwtostr_end:
	mov	ax,di
	mov	dx,ss
	ret
qwtostr ENDP

else

	.data

string_01	db '1',0
string_02	db '52',0
string_03	db '904',0
string_04	db '3556',0
string_05	db '758401',0
string_06	db '1277761',0
string_07	db '54534862',0
string_08	db '927694924',0
string_09	db '3767491786',0
string_10	db '777261159901',0
string_11	db '1444068129571',0
string_12	db '56017679474182',0
string_13	db '940737269953054',0
string_14	db '3972973049575027',0
string_15	db '796486064051292511',0
string_16	db '1615590737044764481',0

str_off		dw string_01
		dw string_02
		dw string_03
		dw string_04
		dw string_05
		dw string_06
		dw string_07
		dw string_08
		dw string_09
		dw string_10
		dw string_11
		dw string_12
		dw string_13
		dw string_14
		dw string_15
		dw string_16

	.code

qwtostr PROC _CType PUBLIC USES si di bx odx:DWORD, oax:DWORD
local	result[128]:BYTE
	mov	ax,ss
	mov	es,ax
	lea	di,result
	mov	cx,20
	mov	al,'0'
	cld?
	rep	stosb
	mov	dx,WORD PTR oax
	mov	ax,dx
	and	ax,15
	add	al,'0'
	lea	di,result
	cmp	al,'9'
	jle	@F
	add	al,246
	inc	result[1]
      @@:
	stosb
	call	DO_QWORD
	lea	dx,result
	mov	ax,3000h
	mov	cx,19
	mov	di,dx
	add	di,19
	std
      @@:
	cmp	[di],ah
	jne	@F
	stosb
	dec	cx
	jnz	@B
      @@:
	cld
	mov	si,di
	mov	di,dx
      @@:
	mov	al,[di]
	movsb
	mov	[si-1],al
	sub	si,2
	cmp	di,si
	jb	@B
	lea	ax,result
	mov	dx,ss
	ret
    DO_QWORD:
	mov	si,dx
	mov	dx,WORD PTR oax[2]
	mov	cx,0704h
	mov	bx,offset str_off
	call	DO_DWORD
	mov	cx,0800h
	mov	si,WORD PTR odx
	mov	dx,WORD PTR odx[2]
    DO_DWORD:
	mov	ax,si
	shr	ax,cl
	and	ax,15
	jz	DWORD_01
      @@:
	call	ADD_STRING
	dec	ax
	jnz	@B
    DWORD_01:
	add	cl,4
	cmp	cl,16
	jb	@F
	mov	si,dx
	xor	cl,cl
      @@:
	add	bx,2
	dec	ch
	jnz	DO_DWORD
	retn
    ADD_STRING:
	push	ax
	push	si
	push	cx
	mov	si,[bx]
	lea	di,result
	mov	cx,17
	add	BYTE PTR [di],6
	call	FIX_BYTE
	inc	di
      @@:
	lodsb
	test	al,al
	jz	@F
	add	al,-48
	add	[di],al
	call	FIX_BYTE
	inc	di
	dec	cx
	jnz	@B
      @@:
	call	FIX_BYTE
	pop	cx
	pop	si
	pop	ax
	retn
    FIX_BYTE:
	mov	ax,[di]
	cmp	al,'9'
	jle	@F
	add	al,246
	inc	ah
	mov	[di],ax
      @@:
	retn
qwtostr ENDP
endif

strtol	PROC _CType PUBLIC USES bx string:PTR BYTE
	push	es
	les	bx,string	; '128'		- long
	mov	ah,'9'		; '128 C:\file' - long
      @@:			; '100h'	- hex
	mov	al,es:[bx]	; 'f3 22'	- hex
	inc	bx
	test	al,al
	jz	strtol_long
	cmp	al,' '
	je	strtol_long
	cmp	al,ah
	jbe	@B
	invoke	xtol,string
    strtol_end:
	pop	es
	ret
    strtol_long:
	invoke	atol,string
	jmp	strtol_end
strtol	ENDP

xtol	PROC _CType PUBLIC USES bx cx string:PTR BYTE
	les	bx,string
	sub	ax,ax
	mov	cx,ax
	mov	dx,ax
    xtol_do:
	mov	al,es:[bx]
	or	al,20h
	inc	bx
	cmp	al,'0'
	jb	xtol_end
	cmp	al,'f'
	ja	xtol_end
	cmp	al,'9'
	ja	xtol_ch
	sub	al,'0'
	jmp	xtol_add
    xtol_ch:
	cmp	al,'a'
	jb	xtol_end
	sub	al,87
    xtol_add:
	shl	dx,4
	push	cx
	shr	ch,4
	or	dl,ch
	pop	cx
	shl	cx,4
	add	cx,ax
	adc	dx,0
	jmp	xtol_do
    xtol_end:
	mov	ax,cx
	ret
xtol	ENDP

bpPath	equ <[bp-256]>
bpFile	equ <[bp-128]>

searchp PROC _CType PUBLIC USES si di bx fname:PTR BYTE
local path[256]:BYTE
	les	bx,fname
	test	bx,bx
	jz	searchp_nul
	mov	al,es:[bx]
	test	al,al
	jz	searchp_nul
	cmp	al,'.'
	jz	searchp_nul
	cmp	al,'\'
	jne	searchp_do
    searchp_nul:
	xor	ax,ax
	mov	dx,ax
	jmp	searchp_end
    searchp_do:
	invoke	strcpy,addr bpFile,es::bx
	mov	si,ax
	invoke	strlen,dx::ax
	mov	di,si
	add	di,ax
	cmp	ax,5
	jb	searchp_02
	mov	al,'.'
	cmp	al,[di-4]
	jne	searchp_02
	mov	ax,si
	mov	dx,ss
	call	isexec
	cmp	ax,2
	jae	searchp_03
    searchp_02:
	mov	BYTE PTR [di],'.'
	inc	di
	mov	bx,di
	mov	WORD PTR [di],'OC'
	mov	WORD PTR [di+2],'M'
	call	file_exist
	je	searchp_05
	mov	WORD PTR [di],'XE'
	mov	WORD PTR [di+2],'E'
	call	file_exist
	je	searchp_05
	call	search
	jnz	searchp_end
	mov	WORD PTR [bx],'OC'
	mov	WORD PTR [bx+2],'M'
	jmp	searchp_04
    searchp_03:
	call	file_exist
	je	searchp_05
    searchp_04:
	call	search
	jmp	searchp_end
    searchp_05:
	mov	ax,bp
	sub	ax,128
	mov	dx,ss
    searchp_end:
	ret
search:
	push	bx
	invoke	fullpath,addr bpPath,0
	call	init_file
	les	di,envpath
    search_test:
	invoke	filexist,addr bpPath
	cmp	ax,1
	je	search_found
	cmp	BYTE PTR es:[di],';'
	jnz	search_nul?
	inc	di
    search_nul?:
	cmp	ah,es:[di]
	jz	search_nul
	xor	bx,bx
	lea	si,bpPath
    search_cpy:
	mov	al,es:[bx][di]
	test	al,al
	jz	search_eof
	cmp	al,';'
	je	search_eof
	mov	[bx+si],al
	inc	bx
	jmp	search_cpy
    search_found:
	mov	ax,bp
	sub	ax,256
	mov	dx,ss
	jmp	search_end
    search_nul:
	xor	ax,ax
	mov	dx,ax
    search_end:
	test	ax,ax
	pop	bx
	retn
    search_eof:
	add	di,bx
	mov	[bx+si],ah
	call	init_file
	jmp	search_test
file_exist:
	invoke	filexist,addr bpFile
	cmp	ax,1
	retn
init_file:
	push	es
	invoke	strfcat,addr bpPath,0,addr bpFile
	pop	es
	retn
searchp ENDP

setargv_abort:
	jmp	abort

setargv:
	pop	ax		; return adress - only 2 byte on stack!!
	mov	_ip,ax
	mov	_si,si		; save SI and DI
	mov	_di,di
	mov	bp,_psp		; command line at _psp[0080]
	mov	es,bp
	mov	si,0080h
	sub	bx,bx
	cld?
	mov	bl,es:[si]	; BX to length of command line + 1
	inc	bx
	inc	si
	mov	dx,si
	mov	si,envlen	; program name - _argv[0]
	add	si,2
	mov	es,envseg
	mov	di,si
	mov	cx,007Fh
	xor	ax,ax
	repnz	scasb
	test	cx,cx
	jz	setargv_abort
	xor	cl,7Fh
	push	ax		; set end of buffer to 0
	mov	ax,cx		; total size: command + program
	add	ax,bx
	inc	ax
	and	ax,not 1
	mov	di,sp		; create buffer
	sub	di,ax
	jb	setargv_abort
	mov	sp,di
	push	es		; DS to envseg
	pop	ds
	push	ss		; ES to SS
	pop	es
	dec	cx
	rep	movsb		; copy .EXE name to stack
	sub	ax,ax
	stosb			; parse command line to args..
	mov	ds,bp		; DS to _psp
	xchg	dx,si		; SI to 0081
	xchg	cx,bx		; CX to size command line, BX to 0
	mov	dx,ax		; DX to 0
	inc	bx		; BX (_argc) to 1
	dec	cx
	jz	setargv_end
    setargv_loop:
	lodsb			; find first char
	cmp	al,' '		; space ?
	je	setargv_loop
	cmp	al,9		; tab ?
	je	setargv_loop
	cmp	al,0Dh
	je	setargv_break
	dec	si
	inc	bx		; _argc++
	mov	ah,' '		; assume ' ' as arg seperator
	mov	dl,ah
	lodsb			; first char
	cmp	al,'"'		; quote ?
	jne	@F
	mov	ah,al
	mov	dl,ah		; assume '"' as arg seperator
	lodsb
      @@:
	cmp	al,0Dh
	je	setargv_break
	stosb			; save char
	dec	cx
	jz	setargv_break	; end of command line ?
	lodsb
	.if al == '"' && al != ah
	    mov ah,al		; -arg"quoted text in argument"
	    jmp @B		; continue using '"' as arg seperator
	.endif
	cmp	al,ah		; arg loop..
	jne	@B
	cmp	ah,dl		; al == '"' or ' '
	mov	ah,dl		; if '"' then continue using ' '
	jne	@B
      @@:
	mov	al,0		; break if 0?
	cmp	[si],al
	je	setargv_break
	stosb
	dec	cx
	jnz	setargv_loop	; next argument
    setargv_break:
	sub	al,al
	stosb			; terminate last arg
    setargv_end:
	mov	ax,sp
	mov	cx,di
	sub	cx,ax
	push	ss		; restore DS
	pop	ds
	mov	_argc,bx	; set _argc
	mov	C0_argc,bx	; set C0_argc
	inc	bx
	add	bx,bx
	add	bx,bx
	mov	si,ax
	mov	bp,ax
	sub	bp,bx
	jb	setargv_abort
	mov	sp,bp
	mov	WORD PTR _argv,bp
	mov	WORD PTR _argv+2,ss
	mov	WORD PTR C0_argv,bp
	mov	WORD PTR C0_argv+2,ss
    setargv_06:
	test	cx,cx
	jz	setargv_08
	mov	[bp],si
	mov	[bp+2],ss
	add	bp,4
    setargv_07:
	lodsb
	test	al,al
	loopnz	setargv_07
	jz	setargv_06
    setargv_08:
	xor	ax,ax
	mov	[bp],ax
	mov	[bp+2],ax
	mov	si,_si
	mov	di,_di
	jmp	_ip

pragma_init setargv, 3

	END
