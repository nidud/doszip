; INI.ASM--
; Copyright (C) 2015 Doszip Developers

include dir.inc
include string.inc
include stdio.inc
include iost.inc
include conio.inc

extrn	_argv:DWORD
extrn	configfile:BYTE

.data
cp_badentry	db "Bad or missing Entry in DZ.INI",0
cp_badentrymsg	db "Section: [%s]",10,"Entry: [%s]",10,0
entryid		db 0,0,0,0
extini		db ".ini",0

.code

inierror PROC _CType PUBLIC section:DWORD, entry:DWORD
	invoke ermsg,addr cp_badentry,addr cp_badentrymsg,section,entry
	test ax,ax
	ret
inierror ENDP

next_word:
	inc	di
first_word:
	mov	al,[di]
	cmp	al,' '
	je	next_word
	cmp	al,9
	je	next_word
	ret

inientry PROC _CType PUBLIC USES si di bx section:DWORD, entry:DWORD, inifile:DWORD
local	quote:BYTE
local	lbuf[WMAXPATH]:BYTE
	.if WORD PTR inifile
	    invoke strcpy,addr lbuf,inifile
	.else
	    les bx,_argv ; assume <program>.ini
	    invoke strcpy,addr lbuf,es:[bx]
	    invoke setfext,dx::ax,addr extini
	.endif
	lea di,lbuf
	invoke strlen,section
	mov si,ax
	.if ogetl(ss::di,ss::di,WMAXPATH-1)
	    .repeat
		call ogets
		.break .if ZERO?
		mov bx,si
		inc di
		.if lbuf == '[' && BYTE PTR [di+bx] == ']'
		    mov BYTE PTR [di+bx],0
		    .if !stricmp(section,ss::di)
			inc ax
			.break
		    .endif
		.endif
		dec di
	    .until 0
	    mov si,ax
	    .if ax
		sub si,si	; Result
		.repeat		; Section found, read entries
		    call ogets
		    .break .if !ax
		    lea di,lbuf
		    call first_word
		    .break .if al == '['
		    .continue .if !al || al == ';'
		    invoke strchr,ss::di,'='
		    .continue .if !ax
		    mov bx,ax
		    mov BYTE PTR [bx],0
		    invoke strtrim,ss::di
		    .continue .if !ax
		    invoke stricmp,ss::di,entry
		    .continue .if ax
		    mov di,bx
		    inc di
		    call first_word
		    invoke strtrim,ss::di
		    .break .if !ax
		    mov quote,0
		    mov si,di
		    cld?
		    .repeat
			lodsb
			.break .if !al
			.if al == '"'
			    xor quote,1
			.endif
			.break .if al == ';' && !quote
		    .until 0
		    sub ax,ax
		    mov [si-1],al
		    .if [di] == al
			sub si,si
		    .endif
		    .break
		.until 0
	    .endif
	    invoke oclose,addr STDI
	    .if si
		invoke strcpy,addr _bufin,ss::di
	    .else
		sub ax,ax
		mov dx,ax
	    .endif
	.endif
	ret
inientry ENDP

iniidtostr PROC _CType
     @@:
	cmp	al,10
	jb	@F
	inc	ah
	sub	al,10
	jmp	@B
     @@:
	test	ah,ah
	jz	@F
	xchg	al,ah
	or	ah,'0'
     @@:
	or	al,'0'
	mov	entryid[0],al
	mov	entryid[1],ah
	mov	entryid[2],0
	mov	ax,offset entryid
	mov	dx,ds
	ret
iniidtostr ENDP

inientryid PROC _CType PUBLIC section:DWORD, entry:size_t
	mov	ax,entry
	call	iniidtostr
	invoke	inientry,section,dx::ax,addr configfile
	ret
inientryid ENDP

	END
