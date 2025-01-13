; IOST.ASM--
; Copyright (C) 2015 Doszip Developers

include iost.inc
include io.inc
include alloc.inc
include stdio.inc
include errno.inc
include conio.inc
include dos.inc
include confirm.inc
include string.inc
ifdef __TE__
include clip.inc
include tinfo.inc
tiseekst PROTO
tiofread PROTO
endif
ifdef __MEMVIEW__
externdef tvmem_size: DWORD
externdef tvmem_offs: DWORD
endif
ifdef __ZIP__
extrn	odecrypt: near
endif
extrn	CP_ENOMEM:BYTE
extrn	IDD_Search:DWORD
extrn	searchstring:BYTE

	PUBLIC	STDI
	PUBLIC	STDO
	PUBLIC	crctab
	PUBLIC	oupdate

	.data
	STDI	S_IOST <0,0,0,8000h,0,0,0,0,0,0>
	STDO	S_IOST <0,0,0,8000h,0,0,0,0,0,0>
	oupdate p? 0
	crctab	dd 000000000h, 077073096h, 0EE0E612Ch, 0990951BAh
		dd 0076DC419h, 0706AF48Fh, 0E963A535h, 09E6495A3h
		dd 00EDB8832h, 079DCB8A4h, 0E0D5E91Eh, 097D2D988h
		dd 009B64C2Bh, 07EB17CBDh, 0E7B82D07h, 090BF1D91h
		dd 01DB71064h, 06AB020F2h, 0F3B97148h, 084BE41DEh
		dd 01ADAD47Dh, 06DDDE4EBh, 0F4D4B551h, 083D385C7h
		dd 0136C9856h, 0646BA8C0h, 0FD62F97Ah, 08A65C9ECh
		dd 014015C4Fh, 063066CD9h, 0FA0F3D63h, 08D080DF5h
		dd 03B6E20C8h, 04C69105Eh, 0D56041E4h, 0A2677172h
		dd 03C03E4D1h, 04B04D447h, 0D20D85FDh, 0A50AB56Bh
		dd 035B5A8FAh, 042B2986Ch, 0DBBBC9D6h, 0ACBCF940h
		dd 032D86CE3h, 045DF5C75h, 0DCD60DCFh, 0ABD13D59h
		dd 026D930ACh, 051DE003Ah, 0C8D75180h, 0BFD06116h
		dd 021B4F4B5h, 056B3C423h, 0CFBA9599h, 0B8BDA50Fh
		dd 02802B89Eh, 05F058808h, 0C60CD9B2h, 0B10BE924h
		dd 02F6F7C87h, 058684C11h, 0C1611DABh, 0B6662D3Dh
		dd 076DC4190h, 001DB7106h, 098D220BCh, 0EFD5102Ah
		dd 071B18589h, 006B6B51Fh, 09FBFE4A5h, 0E8B8D433h
		dd 07807C9A2h, 00F00F934h, 09609A88Eh, 0E10E9818h
		dd 07F6A0DBBh, 0086D3D2Dh, 091646C97h, 0E6635C01h
		dd 06B6B51F4h, 01C6C6162h, 0856530D8h, 0F262004Eh
		dd 06C0695EDh, 01B01A57Bh, 08208F4C1h, 0F50FC457h
		dd 065B0D9C6h, 012B7E950h, 08BBEB8EAh, 0FCB9887Ch
		dd 062DD1DDFh, 015DA2D49h, 08CD37CF3h, 0FBD44C65h
		dd 04DB26158h, 03AB551CEh, 0A3BC0074h, 0D4BB30E2h
		dd 04ADFA541h, 03DD895D7h, 0A4D1C46Dh, 0D3D6F4FBh
		dd 04369E96Ah, 0346ED9FCh, 0AD678846h, 0DA60B8D0h
		dd 044042D73h, 033031DE5h, 0AA0A4C5Fh, 0DD0D7CC9h
		dd 05005713Ch, 0270241AAh, 0BE0B1010h, 0C90C2086h
		dd 05768B525h, 0206F85B3h, 0B966D409h, 0CE61E49Fh
		dd 05EDEF90Eh, 029D9C998h, 0B0D09822h, 0C7D7A8B4h
		dd 059B33D17h, 02EB40D81h, 0B7BD5C3Bh, 0C0BA6CADh
		dd 0EDB88320h, 09ABFB3B6h, 003B6E20Ch, 074B1D29Ah
		dd 0EAD54739h, 09DD277AFh, 004DB2615h, 073DC1683h
		dd 0E3630B12h, 094643B84h, 00D6D6A3Eh, 07A6A5AA8h
		dd 0E40ECF0Bh, 09309FF9Dh, 00A00AE27h, 07D079EB1h
		dd 0F00F9344h, 08708A3D2h, 01E01F268h, 06906C2FEh
		dd 0F762575Dh, 0806567CBh, 0196C3671h, 06E6B06E7h
		dd 0FED41B76h, 089D32BE0h, 010DA7A5Ah, 067DD4ACCh
		dd 0F9B9DF6Fh, 08EBEEFF9h, 017B7BE43h, 060B08ED5h
		dd 0D6D6A3E8h, 0A1D1937Eh, 038D8C2C4h, 04FDFF252h
		dd 0D1BB67F1h, 0A6BC5767h, 03FB506DDh, 048B2364Bh
		dd 0D80D2BDAh, 0AF0A1B4Ch, 036034AF6h, 041047A60h
		dd 0DF60EFC3h, 0A867DF55h, 0316E8EEFh, 04669BE79h
		dd 0CB61B38Ch, 0BC66831Ah, 0256FD2A0h, 05268E236h
		dd 0CC0C7795h, 0BB0B4703h, 0220216B9h, 05505262Fh
		dd 0C5BA3BBEh, 0B2BD0B28h, 02BB45A92h, 05CB36A04h
		dd 0C2D7FFA7h, 0B5D0CF31h, 02CD99E8Bh, 05BDEAE1Dh
		dd 09B64C2B0h, 0EC63F226h, 0756AA39Ch, 0026D930Ah
		dd 09C0906A9h, 0EB0E363Fh, 072076785h, 005005713h
		dd 095BF4A82h, 0E2B87A14h, 07BB12BAEh, 00CB61B38h
		dd 092D28E9Bh, 0E5D5BE0Dh, 07CDCEFB7h, 00BDBDF21h
		dd 086D3D2D4h, 0F1D4E242h, 068DDB3F8h, 01FDA836Eh
		dd 081BE16CDh, 0F6B9265Bh, 06FB077E1h, 018B74777h
		dd 088085AE6h, 0FF0F6A70h, 066063BCAh, 011010B5Ch
		dd 08F659EFFh, 0F862AE69h, 0616BFFD3h, 0166CCF45h
		dd 0A00AE278h, 0D70DD2EEh, 04E048354h, 03903B3C2h
		dd 0A7672661h, 0D06016F7h, 04969474Dh, 03E6E77DBh
		dd 0AED16A4Ah, 0D9D65ADCh, 040DF0B66h, 037D83BF0h
		dd 0A9BCAE53h, 0DEBB9EC5h, 047B2CF7Fh, 030B5FFE9h
		dd 0BDBDF21Ch, 0CABAC28Ah, 053B39330h, 024B4A3A6h
		dd 0BAD03605h, 0CDD70693h, 054DE5729h, 023D967BFh
		dd 0B3667A2Eh, 0C4614AB8h, 05D681B02h, 02A6F2B94h
		dd 0B40BBE37h, 0C30C8EA1h, 05A05DF1Bh, 02D02EF8Dh

	cp_search	db 'Search',0
	cp_notfoundmsg	db "Search string not found: '%s'",0
	cp_stlsearch	db 'Search for the string:',0
	hexstring	db 128 dup(?)
	hexstrlen	dw 0

	.code

oupdcrc PROC PUBLIC
	push	ax
	push	di
	les	bx,[si]
	add	bx,dx		; update from read offset
ifdef __3__
	mov cx,ax		; size to update
	mov edx,[si].S_IOST.ios_bb ; current CRC value
	.while cx
	    movzx ax,dl
	    xor al,es:[bx]
	    shl ax,2
	    mov di,ax
	    shr edx,8
	    xor edx,[di+crctab]
	    inc bx
	    dec cx
	.endw
	mov [si].S_IOST.ios_bb,edx
else
	push si
	mov dx,WORD PTR [si].S_IOST.ios_bb
	mov cx,WORD PTR [si].S_IOST.ios_bb+2
	mov si,ax
	.while si
	    mov ah,0
	    mov al,dl
	    xor al,es:[bx]
	    shl ax,2
	    mov di,ax
	    mov dl,dh
	    mov dh,cl
	    mov cl,ch
	    mov ch,0
	    xor dx,WORD PTR [di+crctab]
	    xor cx,WORD PTR [di+crctab+2]
	    inc bx
	    dec si
	.endw
	pop si
	mov WORD PTR [si].S_IOST.ios_bb,dx
	mov WORD PTR [si].S_IOST.ios_bb+2,cx
endif
	pop di
	pop ax
	ret
oupdcrc ENDP

openfile PROC _CType PUBLIC fname:DWORD, mode:size_t, action:size_t
	invoke	osopen,fname,_A_NORMAL,mode,action
	cmp	ax,-1
	je	openfile_err
    openfile_end:
	ret
    openfile_err:
	invoke	eropen,fname
	jmp	openfile_end
openfile ENDP

ogetouth PROC _CType PUBLIC filename:DWORD
	invoke	osopen,filename,_A_NORMAL,M_WRONLY,A_CREATE
	cmp	ax,-1
	jne	ogetouth_end
	cmp	errno,EEXIST
	jne	ogetouth_err
	test	confirmflag,CFDELETEALL
	jnz	ogetouth_confirm
    ogetouth_trunc:
	invoke	_dos_setfileattr,filename,0
	invoke	openfile,filename,M_WRONLY,A_TRUNC
	jmp	ogetouth_end
    ogetouth_confirm:
	invoke	confirm_delete,filename,0
	cmp	ax,1
	je	ogetouth_trunc	; delete --> trunc
	cmp	ax,2
	je	ogetouth_del	; delete all --> clear flag, trunc
	cmp	ax,3
	je	ogetouth_nul	; jump --> return 0
	mov	ax,-1		; Cancel --> return -1
	jmp	ogetouth_end
    ogetouth_del:
	and	confirmflag,not CFDELETEALL
	jmp	ogetouth_trunc
    ogetouth_nul:
	xor	ax,ax
    ogetouth_end:
	ret
    ogetouth_err:
	invoke	eropen,filename ; -1
	jmp	ogetouth_end
ogetouth ENDP

oinitst PROC _CType PUBLIC USES bx io:DWORD, bsize:size_t
	mov	bx,WORD PTR io
	mov	dx,[bx].S_IOST.ios_file
	invoke	memzero,io,S_IOST
	mov	[bx].S_IOST.ios_file,dx
	dec	ax
	mov	dx,ax
	stom	[bx].S_IOST.ios_bb	; CRC to FFFFFFFFh
	mov	ax,bsize
	test	ax,ax
	jz	oinitbufin
	mov	[bx].S_IOST.ios_size,ax
	invoke	malloc,ax
	jz	@F
	cmp	[bx].S_IOST.ios_size,-1
	jne	@F
	xor	ax,ax
	inc	dx
      @@:
	stom	[bx].S_IOST.ios_bp
	test	dx,dx
	ret
    oinitbufin:
	mov	[bx].S_IOST.ios_c,ax
	mov	[bx].S_IOST.ios_i,ax
	mov	[bx].S_IOST.ios_size,1000h
	mov	[bx].S_IOST.ios_flag,IO_STRINGB
	mov	ax,offset _bufin
	mov	dx,ds
	jmp	@B
oinitst ENDP

ofreest PROC _CType PUBLIC USES bx io:DWORD
	mov	bx,WORD PTR io
	sub	ax,ax
	mov	dx,WORD PTR [bx].S_IOST.ios_bp+2
	cmp	WORD PTR [bx].S_IOST.ios_bp,ax
	mov	WORD PTR [bx].S_IOST.ios_bp,ax
	mov	WORD PTR [bx].S_IOST.ios_bp+2,ax
	jne	@F
	dec	dx
      @@:
	invoke	free,dx::ax
	mov	ax,ER_MEM
	ret
ofreest ENDP

oopen	PROC _CType PUBLIC USES si file:DWORD, mode:size_t
	.if mode
	    invoke ogetouth,file
	    mov si,offset STDO
	.else
	    invoke openfile,file,M_RDONLY,A_OPEN
	    mov si,offset STDI
	.endif
	cmp ax,1	; -1 or 0 (error/cancel)
	jl  @F
	mov [si].S_IOST.ios_file,ax
	invoke oinitst,ds::si,[si].S_IOST.ios_size
	.if ZERO?
	    invoke close,[si].S_IOST.ios_file
	    invoke ermsg,0,addr CP_ENOMEM
	    dec ax
	.else
	    mov ax,[si].S_IOST.ios_file
	.endif
      @@:
	ret
oopen	ENDP

oclose	PROC _CType PUBLIC io:DWORD
	mov	bx,WORD PTR io
	push	[bx].S_IOST.ios_file
	mov	[bx].S_IOST.ios_file,-1
	invoke	ofreest,io
	call	close
	ret
oclose	ENDP

oread	PROC PUBLIC
	les	bx,STDI.ios_bp
	mov	dx,STDI.ios_i
	add	bx,dx
	mov	cx,STDI.ios_c
	sub	cx,dx
	cmp	cx,ax
	jb	oread_01
	mov	ax,cx
    oread_00:
	test	ax,ax
	ret
    oread_01:
	push	ax
	call	ofread
	pop	ax
	jz	oread_02
	mov	cx,STDI.ios_c
	sub	cx,STDI.ios_i
	cmp	cx,ax
	jae	oread
    oread_02:
	xor	ax,ax
	jmp	oread_00
oread	ENDP

owrite	PROC PUBLIC
	push si
	push di
	mov di,es
	mov si,bx
	mov dx,STDO.ios_i
	mov ax,STDO.ios_size
	sub ax,dx
	.if ax < cx
	    .repeat
		mov al,es:[si]
		call oputc
		mov es,di
		.break .if ZERO?
		inc si
	    .untilcxz
	    test ax,ax
	.else
	    add STDO.ios_i,cx
	    mov ax,WORD PTR STDO.ios_bp+2
	    add dx,WORD PTR STDO.ios_bp
	    push ds
	    mov ds,di
	    xchg di,dx
	    mov es,ax
	    cld?
	    rep movsb
	    mov es,dx
	    pop ds
	.endif
	mov bx,si
	pop di
	pop si
	ret
owrite	ENDP

ogetc	PROC PUBLIC
	mov	ax,STDI.ios_i
	cmp	ax,STDI.ios_c
	je	ogetc_read
    ogetc_do:
	inc	STDI.ios_i
	les	bx,STDI
	add	bx,ax		; es:0 == zero flag set
	inc	ax
	mov	ah,0
	mov	al,es:[bx]
    ogetc_end:
	ret
    ogetc_read:
	push	cx
	push	dx
	call	ofread
	pop	dx
	pop	cx
	mov	ax,STDI.ios_i
	jnz	ogetc_do
	mov	ax,-1
	jmp	ogetc_end
ogetc	ENDP

oputc	PROC PUBLIC USES bx
	mov	bx,STDO.ios_i
	cmp	bx,STDO.ios_size
	je	oputc_flush
    oputc_ok:
	les	bx,STDO.ios_bp
	add	bx,STDO.ios_i
	inc	STDO.ios_i
	mov	es:[bx],al
	mov	ax,1
    oputc_eof:
	ret
    oputc_flush:
	push	cx
	push	dx
	push	ax
	call	oflush
	pop	ax
	pop	dx
	pop	cx
	jnz	oputc_ok
	xor	ax,ax
	jmp	oputc_eof
oputc	ENDP

otell	PROC PUBLIC
	mov	ax,WORD PTR STDO.ios_total
	mov	dx,WORD PTR STDO.ios_total+2
	add	ax,STDO.ios_i
	adc	dx,0
	ret
otell	ENDP

oflush	PROC _CType PUBLIC USES si
	mov	si,offset STDO
	mov	ax,[si].S_IOST.ios_i
	test	ax,ax
	jz	oflush_01
	mov	dx,[si].S_IOST.ios_flag
	test	dx,IO_USECRC
	jnz	oflush_crc
  ifdef __TE__
	test	dx,IO_CLIPBOARD
	jnz	oflush_clipcopy
  endif
    oflush_write:
	invoke	oswrite,[si].S_IOST.ios_file,[si].S_IOST.ios_bp,[si].S_IOST.ios_i
    oflush_clip:
	cmp	ax,[si].S_IOST.ios_i
	jne	oflush_error
	add	WORD PTR [si].S_IOST.ios_total,ax
	adc	WORD PTR [si].S_IOST.ios_total[2],0
	sub	ax,ax
	mov	[si].S_IOST.ios_c,ax
	mov	[si].S_IOST.ios_i,ax
	test	[si].S_IOST.ios_flag,IO_USEUPD
	jnz	oflush_update
    oflush_01:
	inc	ax
    oflush_end:
	ret
    oflush_update:
	inc	ax
	push	ax
	call	oupdate
	dec	ax
	jmp	oflush_01
    oflush_error:
	or	[si].S_IOST.ios_flag,IO_ERROR
	xor	ax,ax
	jmp	oflush_end
    oflush_crc:
	xor	dx,dx
	call	oupdcrc
	jmp	oflush_write
  ifdef __TE__
    oflush_clipcopy:
	invoke	ClipboardCopy,[si].S_IOST.ios_bp,ax
	xor	ax,ax
	jmp	oflush_end
  endif
oflush	ENDP

ofread	PROC _CType PUBLIC USES si di
	mov	si,STDI.ios_flag
  ifdef __MEMVIEW__
	test	si,IO_MEMREAD
	jnz	ofread_memory
  endif
  ifdef __TE__
	test	si,IO_LINEBUF
	jnz	ofread_linebuf
  endif
	mov	di,STDI.ios_c
	sub	di,STDI.ios_i
	jnz	ofread_copy
    ofread_read:
	xor	ax,ax
	mov	STDI.ios_i,ax
	mov	STDI.ios_c,di
	mov	cx,STDI.ios_size
	sub	cx,di
	lodm	STDI.ios_bp
	add	ax,di
	invoke	osread,STDI.ios_file,dx::ax,cx
	add	STDI.ios_c,ax
	add	ax,di
	jz	ofread_end
	and	si,IO_UPDTOTAL or IO_USECRC or IO_USEUPD or IO_CRYPT
	jnz	ofread_user
    ofread_end:
	test	ax,ax
	ret
  ifdef __MEMVIEW__
    ofread_memory:
	call	iomemread
	jmp	ofread_end
  endif
  ifdef __TE__
    ofread_linebuf:
	call	tiofread
	jmp	ofread_end
  endif
    ofread_user:
  ifdef __ZIP__
	test	si,IO_CRYPT
	jz	@F
	call	odecrypt
    @@:
  endif
	test	si,IO_UPDTOTAL
	jz	ofread_crc
	add	WORD PTR STDI.ios_total,ax
	adc	WORD PTR STDI.ios_total+2,0
    ofread_crc:
	test	si,IO_USECRC
	jz	ofread_progress
	mov	dx,di
	mov	si,offset STDI
	call	oupdcrc
	mov	si,STDI.ios_flag
    ofread_progress:
	test	si,IO_USEUPD
	jz	ofread_end
      ifdef __CDECL__
	push	0
	push	ax
      else
	push	ax
	push	0
      endif
	call	oupdate
	dec	ax
	pop	ax
	jnz	ofread_error
	jmp	ofread_end
    ofread_copy:
	cmp	di,STDI.ios_c
	je	ofread_eof
	lodm	STDI.ios_bp
	add	ax,STDI.ios_i
	invoke	memcpy,STDI.ios_bp,dx::ax,di
	jmp	ofread_read
    ofread_error:
	call	osmaperr
	or	STDI.ios_flag,IO_ERROR
    ofread_eof:
	xor	ax,ax
	jmp	ofread_end
ofread	ENDP

ifdef __MEMVIEW__

iomemread PROC PRIVATE
  ifdef __3__
	mov	eax,tvmem_size
	cmp	eax,STDI.ios_offset
	jbe	iomemread_02
	mov	eax,STDI.ios_offset
	push	STDI.ios_bp
	mov	dx,ax
	and	dx,000Fh
	and	al,0F0h
	shl	eax,12
	mov	ax,dx
	push	eax
	mov	ecx,STDI.ios_offset
	xor	eax,eax
	mov	STDI.ios_i,ax
	cmp	ax,STDI.ios_c
	mov	ax,STDI.ios_size
	mov	STDI.ios_c,ax
	jz	@F
	add	ecx,eax
	cmp	ecx,tvmem_size
	jbe	@F
	sub	ecx,eax
	mov	eax,tvmem_size
	sub	eax,ecx
	mov	STDI.ios_c,ax
	add	ecx,eax
      @@:
	mov	STDI.ios_offset,ecx
	push	STDI.ios_c
	call	memcpy
	mov	ax,1
	ret
    iomemread_02:
	mov	STDI.ios_offset,eax
  else
	lodm	tvmem_size
	cmp	dx,WORD PTR STDI.ios_offset+2
	jne	@F
	cmp	ax,WORD PTR STDI.ios_offset
      @@:
	jbe	iomemread_02
	pushm	STDI.ios_bp
	lodm	STDI.ios_offset
	mov	bx,ax
	and	bx,000Fh
	shl	dx,12
	shr	ax,4
	or	dx,ax
	push	dx
	push	bx
	xor	ax,ax
	mov	STDI.ios_i,ax
	cmp	ax,STDI.ios_c
	mov	dx,WORD PTR STDI.ios_offset+2
	mov	cx,WORD PTR STDI.ios_offset
	mov	ax,STDI.ios_size
	mov	STDI.ios_c,ax
	jz	@F
	add	cx,ax
	adc	dx,0
	cmp	dx,WORD PTR tvmem_size+2
	jbe	@F
	mov	dx,WORD PTR STDI.ios_offset+2
	mov	cx,WORD PTR STDI.ios_offset
	mov	ax,WORD PTR tvmem_size
	mov	bx,WORD PTR tvmem_size+2
	sub	ax,cx
	sbb	bx,dx
	mov	STDI.ios_c,ax
	add	cx,ax
	adc	dx,bx
      @@:
	mov	WORD PTR STDI.ios_offset,cx
	mov	WORD PTR STDI.ios_offset+2,dx
	push	STDI.ios_c
	call	memcpy
	mov	ax,1
	ret
    iomemread_02:
	stom	STDI.ios_offset
  endif
	xor	ax,ax
	mov	STDI.ios_i,ax
	mov	STDI.ios_c,ax
	ret
iomemread ENDP

endif

oseekst:
  ifdef __MEMVIEW__
	test	[si].S_IOST.ios_flag,IO_MEMREAD
	jz	@F
	cmp	cx,SEEK_CUR
	je	oseekst_fail
	cmp	cx,SEEK_END
	jne	oseekst_end
	lodm	tvmem_offs
	add	ax,WORD PTR tvmem_size
	adc	dx,WORD PTR tvmem_size+2
	jmp	oseekst_end
      @@:
  endif
  ifdef __TE__
	test	[si].S_IOST.ios_flag,IO_LINEBUF
	jz	@F
	jmp	tiseekst;oseekst_linebuf
      @@:
  endif
	cmp	cx,SEEK_CUR
	jne	@F
	test	dx,dx
	jnz	@F
	mov	dx,[si].S_IOST.ios_c
	sub	dx,[si].S_IOST.ios_i
	cmp	dx,ax
	mov	dx,0
	jb	@F
	add	[si].S_IOST.ios_i,ax
	ret
      @@:
	invoke	lseek,[si].S_IOST.ios_file,dx::ax,cx
	cmp	dx,-1
	jne	oseekst_end
	cmp	ax,-1
	je	oseekst_fail
    oseekst_end:
	stom	[si].S_IOST.ios_offset
	sub	ax,ax
	mov	[si].S_IOST.ios_i,ax
	mov	[si].S_IOST.ios_c,ax
	inc	ax
	ret
    oseekst_fail:
	sub	ax,ax
	ret
if 0
  ifdef __TE__
    oseekst_linebuf:
	push	dx
	mov	[si].S_IOST.ios_l,cx
	mov	[si].S_IOST.ios_c,0
	call	tiofread
	pop	ax
	jz	oseekst_fail
	cmp	[si].S_IOST.ios_c,ax
	ja	oseekst_linebuf_end
	inc	cx
	xor	dx,dx
	jmp	oseekst_linebuf
    oseekst_linebuf_end:
	mov	[si].S_IOST.ios_i,ax
	inc	ax
	ret
  endif
endif

oseekl	PROC _CType PUBLIC USES si offs:DWORD, from:size_t
	mov	si,offset STDI
	mov	cx,from
	lodm	offs
	call	oseekst
	ret
oseekl	ENDP

oseek	PROC _CType PUBLIC offs:DWORD, from:size_t
	invoke	oseekl,offs,from
	jz	@F
    ifdef __TE__
	test	STDI.ios_flag,IO_LINEBUF
	jnz	@F
    endif
	call	ofread
      @@:
	ret
oseek	ENDP

ocopy	PROC _CType PUBLIC len:DWORD
ifdef __3__
	push	esi
	mov	eax,len
	test	eax,eax
	jnz	@F
    ocopy_success:
	sub	ax,ax
	inc	ax
    ocopy_end:
	pop	esi
	ret
      @@:
	mov	esi,eax
      @@:
	mov	ax,STDI.ios_c
	sub	ax,STDI.ios_i
	jz	@F
	call	ogetc
	jz	ocopy_end
	call	oputc
	jz	ocopy_end
	dec	esi
	jz	ocopy_success
	jmp	@B
      @@:
	call	oflush		; flush STDO
	jz	ocopy_end	; do block copy of bytes left
	push	STDO.ios_size
	push	STDO.ios_bp
	mov	eax,STDI.ios_bp
	mov	STDO.ios_bp,eax
	mov	ax,STDI.ios_size
	mov	STDO.ios_size,ax
      @@:
	call	ofread
	jz	ocopy_eof
	movzx	eax,STDI.ios_c	; count
	cmp	eax,esi
	jae	ocopy_last
	sub	esi,eax
	mov	STDO.ios_i,ax
	mov	STDI.ios_i,ax
	call	oflush
	jnz	@B
    ocopy_exit:
	mov	dx,ax
	pop	eax
	mov	STDO.ios_bp,eax
	pop	ax
	mov	STDO.ios_size,ax
	mov	ax,dx
	jmp	ocopy_end
    ocopy_last:
	mov	STDI.ios_i,si
	mov	STDO.ios_i,si
	call	oflush
	jmp	ocopy_exit
    ocopy_eof:
	mov	eax,esi
	test	eax,eax
	jnz	ocopy_exit
	inc	ax
	jmp	ocopy_exit
else
	push	si
	push	di
	mov	di,WORD PTR len
	mov	si,WORD PTR len+2
	test	si,si
	jnz	ocopy_start
	test	di,di
	jnz	ocopy_start	; copy zero byte -- ok
    ocopy_success:
	xor	ax,ax
	inc	ax
	jmp	ocopy_end
    ocopy_start:
	mov	ax,STDI.ios_c	; flush inbuf
	sub	ax,STDI.ios_i
	or	si,si
	jnz	ocopy_bigbuf
	cmp	ax,di
	jae	ocopy_inbuf
    ocopy_bigbuf:
	test	ax,ax
	jz	ocopy_block
    ocopy_inbuf:
	call	ogetc
	jz	ocopy_end
	call	oputc
	jz	ocopy_end
	sub	di,ax
	sbb	si,0
	mov	ax,si
	or	ax,di
	jz	ocopy_success	; success if zero (inbuf > len)
	mov	ax,STDI.ios_i
	cmp	ax,STDI.ios_c
	jne	ocopy_inbuf	; do byte copy from STDI to STDO
    ocopy_block:
	call	oflush		; flush STDO
	jz	ocopy_end	; do block copy of bytes left
	push	STDO.ios_size
	pushm	STDO.ios_bp
	movmx	STDO.ios_bp,STDI.ios_bp
	mov	ax,STDI.ios_size
	mov	STDO.ios_size,ax
    ocopy_next:
	call	ofread
	jz	ocopy_eof
	mov	ax,STDI.ios_c	; count
	test	si,si
	jnz	ocopy_more
	cmp	ax,di
	jae	ocopy_last
    ocopy_more:
	sub	di,ax
	sbb	si,0
	mov	STDO.ios_i,ax	; fill STDO
	mov	STDI.ios_i,ax	; flush STDI
	call	oflush		; flush STDO
	jnz	ocopy_next	; copy next block
    ocopy_exit:
	mov	dx,ax
	pop	ax
	mov	WORD PTR STDO.ios_bp,ax
	pop	ax
	mov	WORD PTR STDO.ios_bp+2,ax
	pop	ax
	mov	STDO.ios_size,ax
	mov	ax,dx
    ocopy_end:
	pop	di
	pop	si
	ret
    ocopy_last:
	mov	STDI.ios_i,di
	mov	STDO.ios_i,di
	call	oflush
	jmp	ocopy_exit
    ocopy_eof:
	xor	ax,ax
	test	si,si
	jnz	ocopy_exit
	test	di,di
	jnz	ocopy_exit
	inc	ax
	jmp	ocopy_exit
endif
ocopy	ENDP

ogetl	PROC _CType PUBLIC filename:DWORD, buffer:DWORD, bsize:size_t
	mov WORD PTR STDI.ios_bp+2,ds
	mov WORD PTR STDI.ios_bp,offset _bufin
	mov STDI.ios_size,1000h
	mov STDI.ios_flag,IO_STRINGB
	mov ax,bsize
	mov STDI.ios_l,ax
	mov STDI.ios_c,0
	mov STDI.ios_i,0
	movmx STDI.ios_bb,buffer
	.if osopen(filename,0,M_RDONLY,A_OPEN) != -1
	    mov STDI.ios_file,ax
	.else
	    sub ax,ax
	.endif
	test ax,ax
	ret
ogetl	ENDP

ogets	PROC _CType PUBLIC
local	p:DWORD
	movmx	p,STDI.ios_bb
	mov	cx,STDI.ios_l
	sub	cx,2
	call	ogetc
	jz	ogets_end
      @@:
	cmp	al,0Dh
	je	ogets_0Dh
	cmp	al,0Ah
	je	ogets_eol
	test	al,al
	jz	ogets_end
	les	bx,p
	mov	es:[bx],al
	inc	WORD PTR p
	dec	cx
	jz	ogets_eol
	call	ogetc
	jnz	@B
    ogets_eol:
	inc	al
	jmp	ogets_end
    ogets_0Dh:
	call	ogetc
    ogets_end:
	les bx,p
	mov BYTE PTR es:[bx],0
	.if !ZERO?
	    lodm STDI.ios_bb
	.else
	    sub ax,ax
	    cwd
	.endif
	ret
ogets	ENDP

oprintf PROC _CDecl PUBLIC USES si format:DWORD, argptr:VARARG
	invoke	ftobufin,format,addr argptr
	mov	cx,ax
	mov	si,offset _bufin
	jmp	while_1
    lf:
	mov	ax,0Dh
	invoke	oputc
	jz	break
	inc	cx
	mov	ax,0Ah
	jmp	continue
    while_1:
	mov	al,[si]
	inc	si
	test	al,al
	jz	break
	cmp	al,0Ah
	je	lf
    continue:
	invoke	oputc
	jnz	while_1
    break:
	mov	ax,cx
	ret
oprintf ENDP

oungetc PROC _CType PUBLIC USES si di
	mov	si,offset STDI
	xor	ax,ax
	cmp	ax,[si].S_IOST.ios_i
	je	oungetc_02
    oungetc_00:
	dec	[si].S_IOST.ios_i
	mov	ax,[si].S_IOST.ios_i
	les	di,[si].S_IOST.ios_bp
	add	di,ax
	inc	ax		; es:0 and ax 0 = ZF set
	mov	ah,0
	mov	al,es:[di]
    oungetc_01:
	ret
    oungetc_02:
  ifdef __MEMVIEW__
	test	[si].S_IOST.ios_flag,IO_MEMREAD
	jnz	oungetc_10
  endif
  ifdef __TE__
	test	[si].S_IOST.ios_flag,IO_LINEBUF
	jnz	oungetc_lb
  endif
	invoke	lseek,[si].S_IOST.ios_file,0,SEEK_CUR
	cmp	dx,-1
	jne	oungetc_03
	cmp	ax,-1
	je	oungetc_eof	; current offset to DX:AX
    oungetc_03:
	mov	cx,[si].S_IOST.ios_c	; last read size to CX
	test	dx,dx		; >= current offset ?
	jnz	oungetc_04
	cmp	cx,ax
	ja	oungetc_error	; stream not align if above
	je	oungetc_eof	; EOF == top of file
	cmp	ax,[si].S_IOST.ios_size
	jne	oungetc_04
	cmp	dx,WORD PTR [si].S_IOST.ios_offset
	jne	oungetc_04
	cmp	dx,WORD PTR [si].S_IOST.ios_offset[2]
	je	oungetc_eof
    oungetc_04:
	sub	ax,cx		; adjust offset to start
	sbb	dx,0
	mov	cx,[si].S_IOST.ios_size
	jnz	oungetc_05
	cmp	cx,ax
	jae	oungetc_07
   oungetc_05:
	sub	ax,cx
	sbb	dx,0
   oungetc_06:
	push	cx
	invoke	oseek,dx::ax,SEEK_SET
	pop	ax
	jz	oungetc_eof
	cmp	ax,[si].S_IOST.ios_c
	ja	oungetc_error
	mov	[si].S_IOST.ios_c,ax
	mov	[si].S_IOST.ios_i,ax
	jmp	oungetc_00
    oungetc_07:
	mov	cx,ax
	xor	ax,ax
	mov	dx,ax
	jmp	oungetc_06
    oungetc_error:
	or	[si].S_IOST.ios_flag,IO_ERROR
    oungetc_eof:
	mov	ax,-1
	xor	si,si
	jmp	oungetc_01
  ifdef __MEMVIEW__
    oungetc_10:
	lodm	[si].S_IOST.ios_offset
	add	ax,[si].S_IOST.ios_c
	adc	dx,0
	jmp	oungetc_03
  endif
  ifdef __TE__
    oungetc_lb:
	cmp	[si].S_IOST.ios_l,ax	; first line ?
	je	oungetc_eof
	inc	[si].S_IOST.ios_c
	sub	[si].S_IOST.ios_l,2
	call	tiofread
	jz	oungetc_eof
	mov	ax,[si].S_IOST.ios_c
	mov	[si].S_IOST.ios_i,ax
	jmp	oungetc_00
  endif
oungetc ENDP

ioseek:
	lodm	STDI.ios_bb	; current offset | line:offset
	mov	cx,STDI.ios_flag
	and	STDI.ios_flag,not (IO_SEARCHSET or IO_SEARCHCUR)
	test	cx,IO_SEARCHSET
	jz	@F
	sub	ax,ax
	mov	dx,ax
	jmp	ioseek_set
      @@:
	test	cx,IO_SEARCHCUR
	jnz	ioseek_set
	add	ax,1		; offset++ (continue)
	adc	dx,0
    ioseek_set:
	mov	di,ax
	mov	bp,dx
	invoke	oseek,dx::ax,SEEK_SET
	ret

seekbx:
	cmp	bx,STDI.ios_i
	ja	@F
	sub	di,bx
	sbb	bp,0
	sub	STDI.ios_i,bx
	ret
      @@:
	push	si
	mov	si,bx
      @@:
	call	oungetc
	sub	di,1
	sbb	bp,0
	dec	si
	jnz	@B
	pop	si
	ret

lodhex:
	mov	al,[si]
	test	al,al
	jz	lodhex_end
	inc	si
	cmp	al,'0'
	jb	lodhex
	cmp	al,'9'
	jbe	lodhex_ok
	or	al,20h
	cmp	al,'f'
	ja	lodhex
	sub	al,27h
    lodhex_ok:
	sub	al,'0'
	test	si,si
    lodhex_end:
	ret

searchfound:
	mov	ax,si
	sub	ax,dx
	inc	ax
	sub	di,ax
	sbb	bp,0
	mov	ax,di
	mov	dx,bp
	or	di,1
	ret

searchhex:
	push bp
	push si
	push di
	push bx
	.if (STDI.ios_flag & IO_LINEBUF)
	    sub ax,ax
	    jmp searchhex_end
	.endif
	call ioseek
	jz  searchhex_end
	xor cx,cx
	mov si,offset searchstring
	mov bx,offset hexstring
    searchhex_xtol:
	call lodhex
	jz searchhex_hexl
	mov ah,al
	call lodhex
	jnz searchhex_mkb
	xchg al,ah
    searchhex_mkb:
	shl ah,4
	or  al,ah
	mov [bx],al
	inc bx
	inc cx
	jmp searchhex_xtol
    searchhex_found:
	call searchfound
    searchhex_end:
	pop bx
	pop di
	pop si
	pop bp
	ret
    searchhex_hexl:
	mov hexstrlen,cx
    searchhex_scan:
	mov dl,hexstring
	mov cx,STDI.ios_l
	  @@:
	    call ogetc
	    jz searchhex_end
	    add di,1	; inc offset
	    adc bp,0
	    mov ah,al
	    sub ah,10
	    cmp ah,1
	    adc cx,0	; inc line
	    cmp al,dl
	    jne @B
	mov STDI.ios_l,cx
	mov si,offset hexstring
    searchhex_cmp:
	call	ogetc
	jz	searchhex_end
	add	di,1
	adc	bp,0
	inc	si
	mov	dx,offset hexstring
	mov	cx,si
	sub	cx,dx
	cmp	cx,hexstrlen
	je	searchhex_found
	cmp	al,[si]
	je	searchhex_cmp
	mov	bx,si
	sub	bx,dx
	call	seekbx
	jmp	searchhex_scan

search:
	sub ax,ax
	.if searchstring != al
	    .if STDI.ios_flag & IO_SEARCHHEX
		jmp searchhex
	    .endif
	    jmp searchtxt
	.endif
	ret

searchtxt:
	push bp
	push si
	push di
	call ioseek
	jz   searchtxt_end
    searchtxt_scan:
	sub cx,cx
	.if STDI.ios_flag & IO_SEARCHCASE
	    mov dl,searchstring
	  @@:
	    call ogetc
	    jz searchtxt_end
	    add di,1	; inc offset
	    adc bp,0
	    cmp al,10
	    je searchtxt_l12
	searchtxt_l11:
	    cmp al,dl
	    jne @B
	.else
	    mov al,searchstring
	    sub al,'A'
	    cmp al,'Z'-'A'+1
	    sbb ah,ah
	    and ah,'a'-'A'
	    add al,ah
	    add al,'A'
	    mov dl,al	; tolower(*searchstring)
	  @@:
	    call ogetc
	    jz searchtxt_end
	    add di,1
	    adc bp,0
	    cmp al,10
	    je searchtxt_l22
	searchtxt_l21:
	    sub al,'A'
	    cmp al,'Z'-'A'+1
	    sbb ah,ah
	    and ah,'a'-'A'
	    add al,ah
	    add al,'A'	; tolower(AL)
	    cmp al,dl
	    jne @B
	.endif
	.if !(STDI.ios_flag & IO_LINEBUF)
	    add STDI.ios_l,cx
	.endif
	mov si,offset searchstring
    searchtxt_cmp:
	call ogetc
	jz  searchtxt_end
	add di,1
	adc bp,0
	inc si
	mov dx,offset searchstring
	mov cl,al
	mov al,[si]
	test al,al
	jz searchtxt_found
	cmp al,cl
	je searchtxt_cmp
	.if !(STDI.ios_flag & IO_SEARCHCASE)
	    sub al,'A'
	    cmp al,'Z'-'A'+1
	    sbb ah,ah
	    and ah,'a'-'A'
	    add al,ah
	    add al,'A'	; tolower(AL)
	    xchg al,cl
	    sub al,'A'
	    cmp al,'Z'-'A'+1
	    sbb ah,ah
	    and ah,'a'-'A'
	    add al,ah
	    add al,'A'	; tolower(CL)
	    cmp al,cl
	    je searchtxt_cmp
	.endif
	mov	bx,si
	sub	bx,dx
	call	seekbx
	jmp	searchtxt_scan
    searchtxt_found:
	call	searchfound
    searchtxt_end:
	pop	di
	pop	si
	pop	bp
	ret
    searchtxt_l12:
	inc	cx
	jmp	searchtxt_l11
    searchtxt_l22:
	inc	cx
	jmp	searchtxt_l21

notfoundmsg:
	mov cp_notfoundmsg+24,' '
	invoke strlen,addr searchstring
	cmp ax,29
	jb @F
	mov cp_notfoundmsg+24,10
      @@:
	invoke stdmsg,addr cp_search,addr cp_notfoundmsg,addr searchstring
	ret

continuesearch PROC _CType PUBLIC
local	StatusLine[160]:BYTE
	sub ax,ax
	.if searchstring
	    invoke wcpushst,addr StatusLine,addr cp_stlsearch
	    mov al,_scrrow
	    invoke scputs,24,ax,0,80-24,addr searchstring
	    invoke oseekl,STDI.ios_bb,SEEK_SET
	    .if ax
		.if STDI.ios_flag & IO_SEARCHHEX
		    call searchhex
		.else
		    call searchtxt
		.endif
		.if !ZERO?
		    stom STDI.ios_bb
		    mov ax,1
		    jmp @F
		.endif
	    .endif
	    call notfoundmsg
	    xor ax,ax
	  @@:
	    push ax
	    invoke wcpopst,addr StatusLine
	    pop ax
	.endif
	ret
continuesearch ENDP

osearch PROC _CType PUBLIC USES bx h:size_t,fsize:DWORD,buf:DWORD,bsize:size_t,flag:size_t
	mov	ax,h
	mov	STDI.ios_file,ax
	invoke	lseek,ax,0,SEEK_CUR
	cmp	dx,-1
	jne	@F
	cmp	ax,-1
	je	osearch_err
      @@:
	stom	STDI.ios_bb
	sub	ax,ax
	mov	STDI.ios_c,ax
	mov	STDI.ios_i,ax
	movmx	STDI.ios_size,bsize
	movmx	STDI.ios_bp,buf
	mov	ax,flag
	or	ax,IO_SEARCHCUR
	mov	STDI.ios_flag,ax
	call	search
	jnz	osearch_end
    osearch_err:
	mov	ax,-1
	mov	dx,ax
    osearch_end:
	mov	cx,STDI.ios_l
	ret
osearch ENDP

cmsearchidd PROC _CType PRIVATE USES si bx sflag:size_t
local DLG_Search:DWORD
	invoke	rsopen,IDD_Search
	stom	DLG_Search
	jz	cmsearchidd_nul
	mov	es,dx
	mov	bx,ax
	mov	es:[bx].S_TOBJ.to_count[1*16],128 shr 4
	mov	WORD PTR es:[bx].S_TOBJ.to_data[1*16],offset searchstring
	mov	WORD PTR es:[bx].S_TOBJ.to_data[1*16+2],ds
	mov	ax,sflag
	mov	dl,_O_FLAGB
	test	ax,IO_SEARCHCASE
	jz	cmsearchidd_hex?
	or	es:[bx][2*16],dl
    cmsearchidd_hex?:
	test	ax,IO_SEARCHHEX
	jz	cmsearchidd_cur?
	or	es:[bx][3*16],dl
    cmsearchidd_cur?:
	mov	dl,_O_RADIO
	test	ax,IO_SEARCHCUR
	jz	cmsearchidd_rset
	or	es:[bx][6*16],dl
	jmp	cmsearchidd_event
    cmsearchidd_nul:
	xor	ax,ax
	jmp	cmsearchidd_end
    cmsearchidd_rset:
	or	es:[bx][7*16],dl
    cmsearchidd_event:
	invoke	dlinit,DLG_Search
	invoke	rsevent,IDD_Search,DLG_Search
	test	ax,ax
	jz	cmsearchidd_nul
	mov	ax,sflag
	and	ax,not IO_SEARCHMASK
	mov	dl,_O_FLAGB
	test	es:[bx][2*16],dl
	jz	cmsearchidd_hex
	or	ax,IO_SEARCHCASE
    cmsearchidd_hex:
	test	es:[bx][3*16],dl
	jz	cmsearchidd_cur
	or	ax,IO_SEARCHHEX
    cmsearchidd_cur:
	test	BYTE PTR es:[bx][6*16],_O_RADIO
	jz	cmsearchidd_set
	or	ax,IO_SEARCHCUR
	jmp	cmsearchidd_toend
    cmsearchidd_set:
	or	ax,IO_SEARCHSET
    cmsearchidd_toend:
	mov	dx,ax
	sub	ax,ax
	cmp	searchstring,al
	je	cmsearchidd_end
	inc	ax
    cmsearchidd_end:
	mov	si,dx
	invoke	dlclose,DLG_Search
	mov	ax,dx
	mov	dx,si
	test	ax,ax
	ret
cmsearchidd ENDP

cmdsearch PROC _CType PUBLIC offs:DWORD
	sub	ax,ax
	cmp	ax,WORD PTR offs+2
	jne	cmdsearch_00
	cmp	WORD PTR offs,16
	jb	cmdsearch_end
    cmdsearch_00:
	invoke	cmsearchidd,STDI.ios_flag
	jz	cmdsearch_end
	mov	STDI.ios_flag,dx
	and	dx,IO_SEARCHCUR or IO_SEARCHSET
	push	dx
	call	continuesearch
	pop	dx
	or	STDI.ios_flag,dx
    cmdsearch_end:
	ret
cmdsearch ENDP

	END
