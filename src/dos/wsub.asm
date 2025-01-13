; WSUB.ASM--
; Copyright (C) 2015 Doszip Developers

include io.inc
include dir.inc
include dos.inc
include alloc.inc
include string.inc
include conio.inc
include errno.inc
include stdlib.inc
include iost.inc
include fblk.inc
include wsub.inc

externdef configpath:BYTE
externdef IDD_DirectoryNotFound:DWORD
externdef IDD_WOpenFile:DWORD
externdef copy_jump:WORD

	PUBLIC	drvinfo

	.data

drvinfo S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'A:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'B:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'C:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'D:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'E:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'F:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'G:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'H:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'I:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'J:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'K:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'L:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'M:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'N:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'O:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'P:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'Q:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'R:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'S:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'T:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'U:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'V:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'W:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'X:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'Y:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'Z:'>
	S_DISK <_A_VOLID or _A_ROOTDIR,0,0,0,'[:'>

	cp_erinitsub db 'Error init directory',10,'%s',0
	s_flag	dw ?
	o_list	dd ?
	o_wsub	dd ?
	f_open	db ?
	dialog	dd ?
	cp_save db 'Save',0

	.code

wsopen	PROC _CType PUBLIC USES bx wsub:DWORD
	les	bx,wsub
	mov	ax,es:[bx].S_WSUB.ws_maxfb
	shl	ax,2
	push	ax
	invoke	malloc,ax
	pop	cx
	les	bx,wsub
	stom	es:[bx].S_WSUB.ws_fcb
	jz	wsopen_end
	invoke	memzero,dx::ax,cx
	inc	ax
    wsopen_end:
	ret
wsopen	ENDP

wsfree	PROC _CType PUBLIC USES si di bx wsub:DWORD
	les	bx,wsub
	mov	si,es:[bx].S_WSUB.ws_count
	sub	ax,ax
	cmp	ax,WORD PTR es:[bx].S_WSUB.ws_fcb
	mov	es:[bx].S_WSUB.ws_count,ax
	je	wsfree_end
	mov	di,ax
	jmp	wsfree_next
    wsfree_loop:
	dec	si
	les	dx,[bx].S_WSUB.ws_fcb
	mov	ax,si
	shl	ax,2
	add	dx,ax
	sub	ax,ax
	xchg	bx,dx
	mov	cx,es:[bx+2]
	mov	es:[bx+2],ax
	xchg	ax,es:[bx]
	xchg	bx,dx
	test	ax,ax
	je	wsfree_next
	invoke	free,cx::ax
	inc	di
    wsfree_next:
	test	si,si
	jnz	wsfree_loop
	mov	ax,di
    wsfree_end:
	ret
wsfree	ENDP

wsclose PROC _CType PUBLIC wsub:DWORD
	invoke	wsfree,wsub
	push	ax
	push	bx
	mov	bx,WORD PTR wsub
	pushm	[bx].S_WSUB.ws_fcb
	mov	WORD PTR [bx].S_WSUB.ws_fcb,0
	call	free
	pop	bx
	pop	ax
	ret
wsclose ENDP

wsfblk	PROC _CType PUBLIC wsub:DWORD, index:size_t
	mov	ax,index
	push	bx
	les	bx,wsub
	cmp	es:[bx],ax
	jle	wsfblk_err
	les	bx,es:[bx].S_WSUB.ws_fcb
	shl	ax,2
	add	bx,ax		; ZF - clear
	les	bx,es:[bx]
	mov	cx,es:[bx]	; CX fblk.flag
	mov	dx,es		; DX:AX fblk
	mov	ax,bx
    wsfblk_end:
	pop	bx
	ret
    wsfblk_err:
	sub	ax,ax
	cwd
	jmp	wsfblk_end
wsfblk	ENDP

ifdef __LFN__

wscdroom PROC _CType PRIVATE wsub:DWORD
local	vol[32]:BYTE
	xor	ax,ax
	cmp	al,_ifsmgr
	jz	wscdroom_end
	les	bx,wsub
	invoke	wvolinfo,es:[bx].S_WSUB.ws_path,addr vol
	test	ax,ax
	jnz	wscdroom_end
	cmp	vol,al
	je	wscdroom_cdroom
	cmp	WORD PTR vol,'DC'
	jne	wscdroom_end
	cmp	WORD PTR vol+2,'SF'
	jne	wscdroom_end
    wscdroom_cdroom:
	or	di,_W_CDROOM
    wscdroom_end:
	ret
wscdroom ENDP

endif

wssetflag PROC _CType PUBLIC USES di bx wsub:DWORD
	les	bx,wsub
	les	bx,es:[bx].S_WSUB.ws_flag
	mov	di,es:[bx]
	and	di,not _W_NETWORK
	mov	es:[bx],di
	add	bx,S_PATH.wp_path
	mov	ax,es:[bx]
	cmp	ah,':'
	jne	wssetflag_net?
	mov	ah,0
	sub	al,'A'
	invoke	_disk_type,ax
	les	bx,wsub
	cmp	ax,_DISK_FLOPPY
	jne	wssetflag_net
	or	di,_W_FLOPPY
	jmp	wssetflag_set
    wssetflag_net:
	cmp	ax,_DISK_NETWORK
	jne	wssetflag_sub
	or	di,_W_NETWORK
	mov	ax,3
	jmp	wssetflag_cd
    wssetflag_sub:
	cmp	ax,_DISK_SUBST
	jne	wssetflag_loc
	mov	ax,2
    wssetflag_cd:
  ifdef __LFN__
	push	ax
	invoke	wscdroom,wsub
	pop	ax
  endif
	jmp	wssetflag_set
    wssetflag_loc:
	and	ax,1
	jmp	wssetflag_end
    wssetflag_net?:
	mov	al,0
	cmp	ah,'\'
	jne	wssetflag_loc
	mov	ax,3
	or	di,_W_NETWORK
    wssetflag_set:
	les	bx,wsub ; @v2.18
	les	bx,es:[bx].S_WSUB.ws_flag
	mov	es:[bx],di
    wssetflag_end:
	ret
wssetflag ENDP

wsinit	PROC _CType PUBLIC USES di si bx wsub:DWORD
	les	di,wsub
	mov	ax,':'
	les	bx,es:[di].S_WSUB.ws_path
	cmp	es:[bx],ah
	jz	wsinit_get
	cmp	es:[bx]+1,al
	je	wsinit_str
    wsinit_get:
	call	getdrv
	jmp	wsinit_init
    wsinit_str:
	mov	al,es:[bx]
	sub	ax,'A'
    wsinit_init:
	invoke	_disk_init,ax
	invoke	chdrv,ax
	mov	ax,':'
	les	di,wsub
	les	bx,es:[di].S_WSUB.ws_path
	cmp	es:[bx],ah
	jz	wsinit_path
	cmp	es:[bx][1],al
	jnz	wsinit_flag
	invoke	chdir,es::bx
	test	ax,ax
	jz	wsinit_flag
    wsinit_path:
	les	di,wsub
	invoke	fullpath,es:[di].S_WSUB.ws_path,0
    wsinit_flag:
	invoke	wssetflag,wsub
	mov	dx,ax
	test	ax,ax
	jnz	wsinit_05
	les	di,wsub
	invoke	ermsg,0,addr cp_erinitsub,es:[di].S_WSUB.ws_path
	jmp	wsinit_loc
    wsinit_05:
	cmp	ax,1
	je	wsinit_end
	cmp	ax,3		; network
	mov	ax,1
	je	wsinit_end
    wsinit_loc:
	invoke	wslocal,wsub
    wsinit_end:
	ret
wsinit	ENDP

wsmkdir PROC _CType PUBLIC path:PTR BYTE
	.if mkdir(path)
	    invoke ermkdir,path
	.else
	    inc ax
	.endif
	ret
wsmkdir ENDP

wsopenarch PROC _CType PUBLIC USES bx wsub:DWORD
local	arcname[WMAXPATH]:BYTE
	les bx,wsub
	invoke strfcat,addr arcname,es:[bx].S_WSUB.ws_path,es:[bx].S_WSUB.ws_file
	.if osopen(dx::ax,_A_ARCH,M_RDONLY,A_OPEN) == -1
	    invoke eropen,addr arcname
	.endif
	ret
wsopenarch ENDP

wsffirst PROC _CType PUBLIC wsub:DWORD
	push	bx
	les	bx,wsub
	invoke	fbffirst,es:[bx].S_WSUB.ws_fcb,es:[bx].S_WSUB.ws_count
	pop	bx
	ret
wsffirst ENDP

wsvolid PROC _CType PRIVATE USES bx wsub:DWORD
	local	path[WMAXPATH]:BYTE
	local	ff:S_FFBLK
	mov	bx,WORD PTR wsub
	invoke	strfcat,addr path,[bx].S_WSUB.ws_path,addr cp_stdmask
	invoke	findfirst,addr path,addr ff,_A_VOLID
	test	ax,ax
	jnz	@F
	test	ff.ff_attrib,_A_VOLID
	jz	@F
	mov	al,path
	or	al,20h
	sub	al,'a'
	mov	ah,S_DISK
	mul	ah
	mov	bx,ax
	mov	drvinfo[bx].di_name[2],' '
	invoke	strcpy,addr drvinfo[bx].di_name[3],addr ff.ff_name
      @@:
	ret
wsvolid ENDP

compare PROC _CType PRIVATE USES si di bx a:DWORD, b:DWORD
	les	si,a
	les	si,es:[si]
	mov	ax,WORD PTR es:[si].S_FBLK.fb_name
	cmp	ax,'..'
	jne	@F
	mov	al,es:[si].S_FBLK.fb_name[2]
	test	al,al
	jnz	@F
	jmp	below
     @@:
	mov	ax,es:[si]
	mov	bx,es
	les	di,b
	les	di,es:[di]
	mov	dx,es:[di]
	and	dx,_A_SUBDIR
	and	ax,_A_SUBDIR
	mov	cx,s_flag
	jz	l1
	test	dx,dx
	jz	l1
	test	cx,_W_SORTSUB
	jnz	l2
	mov	cx,_W_SORTNAME
	jmp	l3
l1:	or	ax,dx
	jz	l2
	mov	cx,_W_SORTSUB
	jmp	l3
l2:	and	cx,_W_SORTSIZE
l3:	cmp	cx,_W_SORTTYPE
	je	ftype
	cmp	cx,_W_SORTDATE
	je	fdate
	cmp	cx,_W_SORTSIZE
	je	fsize
	cmp	cx,_W_SORTSUB
	je	subdir
	jmp	fname
ftype:	add	di,S_FBLK.fb_name
	add	si,S_FBLK.fb_name
	push	es
	invoke	strext,es::di
	push	ax
	invoke	strext,bx::si
	pop	dx
	pop	es
	jz	@F
	test	dx,dx
	jz	above
	push	es
	invoke	stricmp,bx::ax,es::dx
	pop	es
	jz	ftequ
	jmp	toend
     @@:
	test	dx,dx
	jnz	below
ftequ:	invoke	stricmp,bx::si,es::di
	jmp	toend
fdate:	mov	ax,es
	mov	es,bx
	mov	dx,WORD PTR es:[si].S_FBLK.fb_time[2]
	mov	cx,WORD PTR es:[si].S_FBLK.fb_time
	mov	es,ax
	cmp	dx,WORD PTR es:[di].S_FBLK.fb_time[2]
	jb	above
	ja	below
	cmp	cx,WORD PTR es:[di].S_FBLK.fb_time
	jb	above
	ja	below
	jmp	fname
fsize:	mov	ax,es
	mov	es,bx
	mov	cx,WORD PTR es:[si].S_FBLK.fb_size[2]
	mov	es,ax
	cmp	cx,WORD PTR es:[di].S_FBLK.fb_size[2]
	jb	above
	ja	below
	mov	es,bx
	mov	cx,WORD PTR es:[si].S_FBLK.fb_size
	mov	es,ax
	cmp	cx,WORD PTR es:[di].S_FBLK.fb_size
	jb	above
	ja	below
	jmp	fname
subdir: test	es:[di].S_FBLK.fb_flag,_A_SUBDIR
	jnz	above
below:	mov	ax,-1
	jmp	toend
above:	mov	ax,1
	jmp	toend
fname:	add	di,S_FBLK.fb_name
	add	si,S_FBLK.fb_name
	invoke	stricmp,bx::si,es::di
toend:	ret
compare ENDP

wssort	PROC _CType PUBLIC wsub:DWORD
	push	bx
	les	bx,wsub
	mov	cx,es:[bx].S_WSUB.ws_count
	mov	ax,WORD PTR es:[bx].S_WSUB.ws_fcb
	mov	dx,WORD PTR es:[bx].S_WSUB.ws_fcb[2]
	les	bx,es:[bx].S_WSUB.ws_flag
	mov	bx,es:[bx]
	mov	s_flag,bx
	mov	bx,compare
	invoke	qsort,dx::ax,cx,4,cs::bx
	pop	bx
	ret
wssort	ENDP

wsreadff PROC pascal PRIVATE USES si di wsub:DWORD, attrib:WORD
local path[WMAXPATH]:BYTE
local ff:S_FFBLK
	invoke	wsvolid,wsub
	lea	di,ff
	les	bx,wsub
	invoke	strfcat,addr path,es:[bx].S_WSUB.ws_path,addr cp_stdmask
	invoke	findfirst,dx::ax,ss::di,attrib
    wsreadff_skip:
	test	ax,ax
	jnz	wsreadff_loop
	test	BYTE PTR [di].S_FFBLK.ff_attrib,_A_VOLID
	jnz	@F
	mov	dx,WORD PTR [di].S_FFBLK.ff_name
	cmp	dx,'.'
	je	@F
	cmp	dx,'..'
	jne	wsreadff_loop
      @@:
	invoke	findnext,ss::di
	jmp	wsreadff_skip
    wsreadff_loop:
	test	ax,ax
	jnz	wsreadff_end
	test	BYTE PTR [di].S_FFBLK.ff_attrib,_A_SUBDIR
	jnz	@F
	les	bx,wsub
	invoke	cmpwarg,addr ss:[di].S_FFBLK.ff_name,es:[bx].S_WSUB.ws_mask
	jz	wsreadff_next
      @@:
if 0 ; @v2.42
	    les bx,wsub
	    les bx,es:[bx].S_WSUB.ws_flag
	    mov ax,es:[bx]
	    and ax,7F00h
	    invoke fballocff, ss::di, ax
	    .break .if !ax
endif
	invoke	fballocff,ss::di,0
	test	ax,ax
	jz	wsreadff_end
	les	bx,wsub
	mov	cx,es:[bx].S_WSUB.ws_count
	les	bx,es:[bx].S_WSUB.ws_fcb
	shl	cx,2
	add	bx,cx
	stom	es:[bx]
	les	bx,wsub
	inc	es:[bx].S_WSUB.ws_count
	mov	ax,es:[bx].S_WSUB.ws_count
	cmp	ax,es:[bx].S_WSUB.ws_maxfb
	jnb	wsreadff_end
    wsreadff_next:
	invoke	findnext,ss::di
	jmp	wsreadff_loop
    wsreadff_end:
	les	bx,wsub
	mov	ax,es:[bx]
	ret
wsreadff ENDP

wsreadwf PROC _CType PRIVATE USES bx si di wsub:DWORD, attrib:size_t
local path[WMAXPATH]:BYTE
local wf:S_WFBLK
	invoke	wsvolid,wsub
	lea	di,wf
	mov	bx,WORD PTR wsub
	invoke	strfcat,addr path,[bx].S_WSUB.ws_path,addr cp_stdmask
	invoke	wfindfirst,addr path,ss::di,attrib
	mov	si,ax
	inc	ax
	jz	wsreadwf_end
	sub	ax,ax
    wsreadwf_loop1:
	test	ax,ax
	jnz	wsreadwf_loop2
	test	BYTE PTR wf,_A_VOLID
	jnz	@F
	; @v2.42 - this failed in v2.36..2.41, subdirs A,B,.. skipped
	mov	dx,'.'
	cmp	WORD PTR wf.wf_name,dx
	je	@F
	cmp	WORD PTR wf.wf_name[1],dx
	jne	wsreadwf_loop2
      @@:
	invoke	wfindnext,ss::di,si
	jmp	wsreadwf_loop1
    wsreadwf_loop2:
	test	ax,ax
	jnz	wsreadwf_close
	test	BYTE PTR wf,_A_SUBDIR
	jnz	@F
	invoke	cmpwarg,addr wf.wf_name,[bx].S_WSUB.ws_mask
	jz	wsreadwf_next
      @@:
if 0 ; @v2.42
	mov	ax,WORD PTR [bx].S_WSUB.ws_flag
	xchg	bx,ax
	mov	bx,[bx]
	xchg	bx,ax
	and	ax,7F00h
	invoke	fballocwf,ss::di,ax
endif
	invoke	fballocwf,ss::di,0
	test	ax,ax
	jz	wsreadwf_close
	mov	cx,[bx].S_WSUB.ws_count
	shl	cx,2
	les	bx,[bx].S_WSUB.ws_fcb
	add	bx,cx
	stom	es:[bx]
	mov	bx,WORD PTR wsub
	inc	[bx].S_WSUB.ws_count
	mov	ax,[bx].S_WSUB.ws_count
	cmp	[bx].S_WSUB.ws_maxfb,ax
	jbe	wsreadwf_close
    wsreadwf_next:
	invoke	wfindnext,ss::di,si
	jmp	wsreadwf_loop2
    wsreadwf_close:
	invoke	wcloseff,si
    wsreadwf_end:
	mov	ax,[bx]
	ret
wsreadwf ENDP

wsread PROC _CType PUBLIC USES bx wsub:DWORD
	invoke	wsfree,wsub
ifdef __ROT__
	les	bx,wsub
	les	bx,es:[bx].S_WSUB.ws_path
	mov	cx,es:[bx+2]
	mov	ax,_A_ROOTDIR
	test	cl,cl
	jz	@F
	cmp	cx,'\'
	je	@F
	cmp	cx,'/'
	je	@F
	xor	ax,ax
      @@:
else
	xor	ax,ax
endif
	invoke	fbupdir,ax
	jz	wsreadsub_end
	les	bx,wsub
	inc	es:[bx].S_WSUB.ws_count
	les	bx,es:[bx].S_WSUB.ws_fcb
	stom	es:[bx]
	les	bx,wsub
	les	bx,es:[bx].S_WSUB.ws_mask
	mov	ax,'*'
	cmp	es:[bx],ah
	jne	@F
	mov	es:[bx]+2,ax
	mov	es:[bx],al
	mov	BYTE PTR es:[bx][1],'.'
      @@:
	les	bx,wsub
	les	bx,es:[bx].S_WSUB.ws_flag
	mov	dx,es:[bx]
	mov	ax,_A_ALLFILES
	test	dx,_W_HIDDEN
	jnz	@F
	mov	ax,_A_STDFILES
      @@:
ifdef __LFN__
	.if dx & _W_LONGNAME
	    invoke wsreadwf,wsub,ax
	.else
	    invoke wsreadff,wsub,ax
	.endif
else
	invoke wsreadff,wsub,ax
endif
    wsreadsub_end:
	les	bx,wsub
	mov	ax,es:[bx]
	ret
wsread ENDP

wslocal PROC _CType PUBLIC USES bx wsub:DWORD
	les bx,wsub
	.if fullpath(es:[bx].S_WSUB.ws_path,0)
	    invoke wssetflag,wsub
	.endif
	ret
wslocal ENDP

wschdrv PROC _CType PUBLIC USES bx wsub:DWORD, drv:size_t
	les	bx,wsub
	les	bx,es:[bx].S_WSUB.ws_flag
	and	es:[bx].S_PATH.wp_flag,not (_W_ARCHIVE or _W_ROOTDIR)
	invoke	chdrv,drv
	invoke	wslocal,wsub
	ret
wschdrv ENDP

MakeDirectory PROC _CType PUBLIC USES si di directory:DWORD
	.if filexist(directory) != 2
	    .if rsopen(IDD_DirectoryNotFound)
		mov si,dx
		mov di,ax
		invoke dlshow,dx::ax
		mov ax,es:[bx+4]
		add ax,0204h
		mov dl,ah
		invoke scpath,ax,dx,22,directory
		.if dlmodal(si::di)
		    invoke wsmkdir,directory
		    inc ax
		.endif
	    .endif
	.endif
	ret
MakeDirectory ENDP

wgetfile PROC _CType PUBLIC USES si fmask:PTR BYTE, flag:size_t
local	path[WMAXPATH]:BYTE
	mov	si,WORD PTR fmask
	add	si,2
	invoke	strfcat,addr path,addr configpath,ds::si
	invoke	MakeDirectory,dx::ax
	test	ax,ax
	jz	@F
	invoke	wdlgopen,addr path,fmask,flag
	jz	@F
	mov	si,ax
	.if flag & 1
	    invoke openfile,dx::ax,M_RDONLY,A_OPEN
	.else
	    invoke ogetouth,dx::ax
	.endif
	inc	ax
	jz	@F
	dec	ax
     @@:
	mov	dx,si
	ret
wgetfile ENDP

wsearch PROC _CType PUBLIC USES si di bx wsub:DWORD, string:PTR BYTE
	les	bx,wsub
	mov	cx,es:[bx].S_WSUB.ws_count
	mov	si,WORD PTR es:[bx].S_WSUB.ws_fcb+2
	mov	di,WORD PTR es:[bx].S_WSUB.ws_fcb
      @@:
	mov	ax,-1
	test	cx,cx
	jz	@F
	dec	cx
	mov	es,si
	les	bx,es:[di]
	add	di,4
	invoke	stricmp,string,addr es:[bx].S_FBLK.fb_name
	jnz	@B
	mov	dx,es
	les	bx,wsub
	mov	ax,es:[bx].S_WSUB.ws_count
	sub	ax,cx
	dec	ax
      @@:
	ret
wsearch ENDP

wscopy_remove PROC _CType PUBLIC ; AX: offset of file to remove
	push	ds
	push	ax
	invoke	oclose,addr STDO
	call	remove
	mov	ax,-1
	ret
wscopy_remove ENDP

wscopy_open PROC _CType PUBLIC USES si di
	mov	si,ax		; AX: offset srcfile
	mov	di,dx		; DX: offset outfile
	mov	errno,0
	invoke	oopen,ds::dx,M_WRONLY
	cmp	ax,-1		; -1 == error
	je	wscopy_open_end
	test	ax,ax		;  0 == jump
	jz	wscopy_open_jmp
	invoke	oopen,ds::si,M_RDONLY
	cmp	ax,-1
	je	wscopy_open_error
    wscopy_open_end:
	ret
    wscopy_open_jmp:
	mov	copy_jump,1
	jmp	wscopy_open_end
    wscopy_open_error:
	invoke	eropen,ds::si
	mov	ax,di
	call	wscopy_remove
	jmp	wscopy_open_end
wscopy_open ENDP

ID_CNT	equ 13
ID_OK	equ ID_CNT
ID_EXIT equ ID_CNT+1
ID_FILE equ ID_CNT+2
ID_PATH equ ID_CNT+3
ID_L_UP equ ID_CNT+4
ID_L_DN equ ID_CNT+5
O_PATH	equ ID_PATH*16+16
O_FILE	equ ID_FILE*16+16

FLAG_OPEN equ 1
FLAG_LOCK equ 2

init_list:
	push	si
	push	di
	push	bp
	push	bx
	push	ds
	cld?
	mov	cx,ID_CNT
	mov	bx,WORD PTR o_list
	mov	[bx].S_LOBJ.ll_numcel,0
	mov	ax,[bx].S_LOBJ.ll_index
	shl	ax,2
	add	ax,WORD PTR [bx].S_LOBJ.ll_list
	mov	dx,WORD PTR [bx].S_LOBJ.ll_list+2
	mov	bp,bx
	les	di,dialog
	mov	bx,es:[di]+4
	add	bx,es:[di]+20
	lea	di,[di].S_TOBJ.to_data[16]
	mov	ds,dx
	mov	si,ax
    event_list_loop:
	lodsw
	or	BYTE PTR es:[di]-7,80h
	test	ax,ax
	jz	event_list_null
	push	es
	push	di
	push	cx
	les	di,[si-2]
	push	ss
	pop	ds
	mov	cx,28
	mov	al,es:[di]
	and	al,_A_SUBDIR
	mov	al,at_foreground[F_Dialog]
	jz	event_list_fg
	mov	al,at_foreground[F_Inactive]
    event_list_fg:
	push	dx
	mov	dl,bh
	invoke	scputfg,bx,dx,cx,ax
	pop	dx
	inc	bh
	mov	ds,dx
	mov	ax,di
	pop	cx
	pop	di
	pop	es
	add	ax,S_FBLK.fb_name
	and	BYTE PTR es:[di]-7,not 80h
	inc	[bp].S_LOBJ.ll_numcel
    event_list_null:
	stosw
	movsw
	add	di,12
	dec	cx
	jnz	event_list_loop
	pop	ds
	pop	bx
	pop	bp
	pop	di
	pop	si
	ret

event_list:
	call	init_list
	invoke	dlinit,dialog
	mov	ax,_C_NORMAL
	retx

read_wsub:
	push	bx
	sub	ax,ax
	mov	bx,WORD PTR o_list
	mov	[bx].S_LOBJ.ll_index,ax
	mov	[bx].S_LOBJ.ll_count,ax
	mov	[bx].S_LOBJ.ll_numcel,ax
	invoke	wsread,o_wsub
	mov	[bx].S_LOBJ.ll_count,ax
	pop	bx
	ret

event_file:
	push	bx
	les	bx,dialog
	mov	dx,es
	mov	ax,WORD PTR es:[bx].S_TOBJ.to_data[O_FILE]
	mov	bx,WORD PTR o_wsub
	test	f_open,FLAG_OPEN
	jnz	event_file_open
	push	dx
	push	ax
	invoke	strrchr,dx::ax,'*'
	pop	ax
	pop	dx
	jnz	event_file_open?
	invoke	strrchr,dx::ax,'?'
	jz	event_file_ret
    event_file_open?:
	test	f_open,FLAG_LOCK
	jnz	event_file_continue
    event_file_open:
	push	ss
	push	bx
	push	dx
	push	ax
	invoke	strnzcpy,[bx].S_WSUB.ws_mask,dx::ax,32
	call	read_wsub
	pushl	cs
	call	event_list
	call	wsearch
	inc	ax
	jz	event_file_continue
    event_file_ret:
	mov	ax,_C_RETURN
    event_file_end:
	pop	bx
	retx
    event_file_continue:
	mov	ax,_C_NORMAL
	jmp	event_file_end

event_path:
	call	read_wsub
	pushl	cs
	call	event_list
	mov	ax,_C_NORMAL
	retx

case_files:
	push	si
	push	di
	push	bx
	mov	bx,WORD PTR o_list
	mov	ax,[bx].S_LOBJ.ll_index
	add	ax,[bx].S_LOBJ.ll_celoff
	shl	ax,2
	add	ax,WORD PTR [bx].S_LOBJ.ll_list
	mov	di,ax
	mov	ax,WORD PTR [bx].S_LOBJ.ll_list+2
	mov	es,ax
	les	di,es:[di]
	mov	si,es
	mov	ax,es:[di]
	test	al,_A_SUBDIR
	jnz	case_directory
	les	bx,dialog
	mov	es:[bx].S_DOBJ.dl_index,ID_FILE
	mov	dx,si
	lea	ax,[di].S_FBLK.fb_name
	invoke	strcpy,es:[bx].S_TOBJ.to_data[O_FILE],dx::ax
	pushl	cs
	call	event_file
	cmp	ax,_C_RETURN
	jne	case_files_continue
	inc	ax
	jmp	case_files_end
    case_files_continue:
	xor	ax,ax
    case_files_end:
	pop	bx
	pop	di
	pop	si
	ret
    case_directory:
	mov	bx,WORD PTR o_wsub
	and	ax,_A_UPDIR
	jz	case_directory_add
	invoke	strfn,[bx].S_WSUB.ws_path
	jz	case_files_continue
	mov	si,ax
	xor	ax,ax
	mov	[si-1],al
	mov	bx,WORD PTR o_list
	mov	[bx].S_LOBJ.ll_celoff,ax
	pushl	cs
	call	event_path
	invoke	wsearch,o_wsub,ds::si
	cmp	ax,-1
	je	case_files_continue
	;mov	bx,o_list
	cmp	ax,ID_CNT
	jnb	case_directory_index
	les	bx,dialog
	mov	es:[bx].S_DOBJ.dl_index,al
	jmp	case_directory_event
    case_directory_index:
	mov	[bx].S_LOBJ.ll_index,ax
    case_directory_event:
	pushl	cs
	call	event_list
	jmp	case_files_continue
    case_directory_add:
	push	bx
	les	bx,dialog
	mov	es:[bx].S_DOBJ.dl_index,al
	pop	bx
	mov	dx,si
	lea	ax,[di].S_FBLK.fb_name
	invoke	strfcat,[bx].S_WSUB.ws_path,0,dx::ax
	pushl	cs
	call	event_path
	jmp	case_files_continue

wdlgopen PROC _CType PUBLIC USES si di bx apath:PTR BYTE, amask:PTR BYTE, asave:size_t
local	wsub:	S_WSUB
local	path:	S_PATH
local	list:	S_LOBJ
	mov	ax,asave
	mov	f_open,al
	mov	dx,ss
	mov	es,dx
	cld?
	lea	di,list
	mov	WORD PTR o_list+2,ss
	mov	WORD PTR o_list,di
	mov	cx,(S_LOBJ + S_PATH)/2
	sub	ax,ax
	rep	stosw
	mov	si,di
	mov	wsub.ws_count,ax
	mov	wsub.ws_maxfb,5000
	mov	WORD PTR o_wsub,di
	mov	ax,dx
	mov	WORD PTR o_wsub+2,ax
	mov	WORD PTR wsub.ws_flag+2,ax
	mov	WORD PTR wsub.ws_mask+2,ax
	mov	WORD PTR wsub.ws_path+2,ax
	mov	WORD PTR wsub.ws_file+2,ax
	mov	WORD PTR wsub.ws_arch+2,ax
	lea	ax,path.wp_flag
	mov	WORD PTR wsub.ws_flag,ax
	lea	ax,path.wp_mask
	mov	WORD PTR wsub.ws_mask,ax
	lea	ax,path.wp_path
	mov	WORD PTR wsub.ws_path,ax
	lea	ax,path.wp_file
	mov	WORD PTR wsub.ws_file,ax
	lea	ax,path.wp_arch
	mov	WORD PTR wsub.ws_arch,ax
	invoke	strcpy,wsub.ws_mask,amask
	invoke	strcpy,wsub.ws_path,apath
	sub	di,di
	invoke	wsopen,addr wsub
	jz	wdlgopen_end
	invoke	rsopen,IDD_WOpenFile
	mov	si,dx
	jz	wdlgopen_wsclose
	stom	dialog
	invoke	dlshow,dx::ax
	les	bx,dialog
	lodm	wsub.ws_path
	stom	es:[bx].S_TOBJ.to_data[O_PATH]
	mov	es:[bx].S_TOBJ.to_count[O_PATH],16
	invoke	strcpy,es:[bx].S_TOBJ.to_data[O_FILE],wsub.ws_mask
	movl	ax,cs
	movl	WORD PTR list.ll_proc+2,ax
	movl	WORD PTR es:[bx].S_TOBJ.to_proc[O_FILE+2],ax
	movl	WORD PTR es:[bx].S_TOBJ.to_proc[O_PATH+2],ax
	mov	WORD PTR list.ll_proc,offset event_list
	mov	WORD PTR es:[bx].S_TOBJ.to_proc[O_FILE],offset event_file
	mov	WORD PTR es:[bx].S_TOBJ.to_proc[O_PATH],offset event_path
	mov	list.ll_dcount,ID_CNT
	mov	list.ll_celoff,ID_CNT
	movmx	list.ll_list,wsub.ws_fcb
	test	f_open,FLAG_OPEN
	jnz	wdlgopen_open
	mov	dl,es:[bx]+5
	mov	al,es:[bx]+4
	add	al,21
	invoke	scputs,ax,dx,0,0,addr cp_save
    wdlgopen_open:
  ifdef __LFN__
	cmp	_ifsmgr,0
	je	wdlgopen_read
	mov	path.wp_flag,_W_LONGNAME
    wdlgopen_read:
  endif
	call	read_wsub
	call	init_list
	invoke	dlinit,dialog
    wdlgopen_event:
	invoke	dllevent,dialog,addr list
	jz	wdlgopen_twclose
	cmp	ax,ID_CNT
	ja	wdlgopen_break
	call	case_files
	jz	wdlgopen_event
    wdlgopen_break:
	les	bx,dialog
	invoke	strfcat,wsub.ws_path,0,es:[bx].S_TOBJ.to_data[O_FILE]
	mov	di,ax
	test	f_open,FLAG_LOCK
	jz	wdlgopen_twclose
	invoke	strrchr,dx::ax,'.'
	jnz	wdlgopen_twclose
    wdlgopen_addext:
	lodm	amask
	inc	ax
	invoke	strcat,ss::di,dx::ax
    wdlgopen_twclose:
	invoke	dlclose,dialog
    wdlgopen_wsclose:
	invoke	wsclose,addr wsub
	mov	ax,di
	mov	dx,ax
	test	ax,ax
	jz	wdlgopen_end
	mov	dx,ss
    wdlgopen_end:
	ret
wdlgopen ENDP


Init20: call	dostime
	push	bx
	xor	cx,cx
	mov	bx,offset drvinfo
      @@:
	stom	[bx].S_DISK.di_time
	mov	WORD PTR [bx].S_DISK.di_sizeax,cx
	add	bx,S_DISK
	inc	cx
	cmp	cx,MAXDRIVES
	jb	@B
	pop	bx
	ret

pragma_init Init20, 11

	END
