; DIR.ASM--
; Copyright (C) 2015 Doszip Developers

include dir.inc
include dos.inc
include conio.inc
include string.inc
include errno.inc

ATTRIB_ALL	equ 0B7h ;37h
ATTRIB_FILE	equ 0F7h ;27h

extrn	IDD_DriveNotReady:DWORD
extrn	cp_stdmask: BYTE

	PUBLIC	cp_stdpath
	PUBLIC	cp_stdmask
	PUBLIC	fp_maskp
	PUBLIC	fp_directory
	PUBLIC	fp_fileblock
	PUBLIC	scan_fblock

.data
	fp_maskp	dd ?
	fp_directory	p? ?
	fp_fileblock	p? ?
	scan_fblock	S_WFBLK <?>
	scan_curpath	db WMAXPATH dup(?)
	scan_curfile	db WMAXPATH dup(?)
	cp_stdpath	db 'C:\'
	cp_stdmask	db '*.*',0
	cp_selectdisk	db 'Select disk',0
	stdpath		db "C:\NUL",0
	PButton		db '&A',0

.code

chdir PROC _CType PUBLIC directory:DWORD
    ifdef __LFN__
	cmp	_ifsmgr,0
    endif
	push	ds
	lds	dx,directory
	mov	ah,3Bh
    ifdef __LFN__
	je	@F
	stc
	mov	ax,713Bh
      @@:
    endif
	int	21h
	pop	ds
	jc	chdir_err
	xor	ax,ax
    chdir_end:
	ret
    chdir_err:
	call	osmaperr
	jmp	chdir_end
chdir ENDP

mkdir	PROC _CType PUBLIC directory:DWORD
    ifdef __LFN__
	cmp	_ifsmgr,0
    endif
	push	ds
	lds	dx,directory
	mov	ah,39h
    ifdef __LFN__
	je	@F
	stc
	mov	ax,7139h
      @@:
    endif
	int	21h
	pop	ds
	jc	mkdir_err
	xor	ax,ax
    mkdir_end:
	ret
    mkdir_err:
	call	osmaperr
	jmp	mkdir_end
mkdir	ENDP

rmdir	PROC _CType PUBLIC directory:DWORD
    ifdef __LFN__
	cmp	_ifsmgr,0
    endif
	push	ds
	lds	dx,directory
	mov	ah,3Ah
    ifdef __LFN__
	jz	@F
	stc
	mov	ax,713Ah
      @@:
    endif
	int	21h
	pop	ds
	jc	rmdir_err
	xor	ax,ax
    rmdir_end:
	ret
    rmdir_err:
	call	osmaperr
	jmp	rmdir_end
rmdir	ENDP

getdrv	PROC _CType PUBLIC
	mov	ah,19h
	int	21h
	mov	ah,0
	ret
getdrv	ENDP

chdrv	PROC _CType PUBLIC drv:WORD
	mov	dx,drv
	mov	ah,0Eh
	int	21h
	ret
chdrv	ENDP

_disk_type PROC _CType PUBLIC USES dx bx disk:size_t
	mov	dx,disk
	cmp	dl,1
	ja	_disk_type_hdd
	mov	ah,15h		; GET DISK TYPE
	int	13h
	jc	_disk_type_NODISK
	test	ah,ah
	jz	_disk_type_NODISK
	mov	bx,disk		; remapped B drive ?
	cmp	bl,1
	jne	_disk_type_FLOPPY
	inc	bx
	mov	ax,440Eh
	int	21h		; IOCTL - GET LOGICAL DRIVE MAP
	test	al,al
	jz	_disk_type_FLOPPY
	jmp	_disk_type_NODISK
    _disk_type_hdd:
	mov	bx,dx
	inc	bx
	mov	ax,4409h	; IOCTL - CHECK IF BLOCK DEVICE REMOTE
	int	21h
	jc	_disk_type_NODISK
	test	dh,80h		; bit 15: drive is SUBSTituted
	jnz	_disk_type_SUBST
	test	dh,10h		; bit 12: drive is remote
	jnz	_disk_type_NETWORK
	jmp	_disk_type_LOCAL
    _disk_type_SUBST:
	mov	ax,_DISK_SUBST
	jmp	_disk_type_end
    _disk_type_NETWORK:
	mov	ax,_DISK_NETWORK
	jmp	_disk_type_end
    _disk_type_LOCAL:
	mov	ax,_DISK_LOCAL
	jmp	_disk_type_end
    _disk_type_FLOPPY:
	mov	ax,_DISK_FLOPPY
	jmp	_disk_type_end
    _disk_type_NODISK:
	sub	ax,ax
    _disk_type_end:
	test	ax,ax
	ret
_disk_type ENDP

_disk_exist PROC _CType PUBLIC disk:size_t

	mov	ax,disk
	add	al,'A'
	mov	cp_stdpath,al
	mov	sys_erflag,0
	mov	sys_erdrive,0
	mov	sys_ercode,0
	mov	ax,4E00h
	mov	dx,offset cp_stdpath
	mov	cx,07Fh
	int	21h	; hard error if not exist..
	jnc	@1
	cmp	ax,18	; No more files to be found
	jne	@0
	mov	cx,sys_ercode
	or	cl,sys_erflag
	or	cl,sys_erdrive
	test	cx,cx
	jnz	@0
	mov	al,cp_stdpath
	mov	stdpath,al
	mov	ax,4E00h
	mov	dx,offset stdpath
	mov	cx,07Fh
	int	21h
	jc	@0
@1:
	mov	ax,1
@2:
	test	ax,ax
	ret
@0:
	call	osmaperr
	xor	ax,ax
	jmp	@2

_disk_exist ENDP

_disk_ready PROC _CType PUBLIC disk:size_t

	push	WORD PTR sys_erproc
	mov	WORD PTR sys_erproc,0
	mov	sys_erflag,0
	invoke	_disk_exist,disk
	pop	dx
	mov	WORD PTR sys_erproc,dx
	jnz	@F
	cmp	errno,ENOENT
	jne	@F
	test	sys_erflag,__ISDEVICE
	jnz	@F
	mov	sys_erflag,al
	mov	sys_erdrive,al
	mov	sys_ercode,ax
@@:
	ret

_disk_ready ENDP

_disk_test PROC _CType PUBLIC disk:size_t
	invoke _disk_type,disk
	.if ax != _DISK_NOSUCHDRIVE
	    invoke _disk_ready,disk
	    .if ax
		mov ax,1
	    .elseif errno != ENOENT
		mov ax,-1
	    .else
		.while 1
		    invoke _disk_retry,disk
		    .if ax
			invoke _disk_ready,disk
			.break .if ax
		    .else
			mov ax,-1
			.break
		    .endif
		.endw
	    .endif
	.endif
	ret
_disk_test ENDP

_disk_init PROC _CType PUBLIC USES di disk:size_t
	mov di,disk
	invoke _disk_test, di
	.if ax == _DISK_NOSUCHDRIVE || ax == -1
	    invoke beep,5,7
	    invoke _disk_select,addr cp_selectdisk
	    .if ax
		dec ax
		invoke _disk_init,ax
		mov di,ax
	    .endif
	.endif
	mov ax,di
	ret
_disk_init ENDP

_disk_retry PROC _CType PUBLIC USES di disk:size_t
local	dialog:DWORD
local	ypos:size_t
local	xpos:size_t
	invoke	rsopen,IDD_DriveNotReady
	jz	@F
	stom	dialog
	mov	di,ax
	mov	es,dx
	sub	ax,ax
	mov	al,es:[di][4]
	add	al,25
	mov	xpos,ax
	mov	al,es:[di][5]
	add	al,2
	mov	ypos,ax
	invoke	dlshow,dialog
	mov	ax,disk
	add	al,'A'
	invoke	scputc,xpos,ypos,1,ax
	sub	xpos,22
	add	ypos,2
	mov	di,errno
	shl	di,2
	lodm	sys_errlist[di]
	invoke	scputs,xpos,ypos,0,29,dx::ax
	invoke	dlmodal,dialog
	test	ax,ax
      @@:
	ret
_disk_retry ENDP

_disk_select PROC _CType PUBLIC USES si di bx msg:DWORD
local	disk:size_t
local	dobj:S_DOBJ
local	tobj[MAXDRIVES]:S_TOBJ
	sub	ax,ax
	mov	disk,ax
	mov	ax,sys_ercode
	or	al,sys_erflag
	or	al,sys_erdrive
	jnz	@F
	call	getdrv
	mov	disk,ax
      @@:
	xor	ax,ax
	mov	si,ax
	mov	dobj.dl_index,al
	mov	dobj.dl_count,al
	lea	di,tobj
	mov	WORD PTR dobj.dl_object,di
	mov	WORD PTR dobj.dl_object+2,ss
    _disk_loop:
	invoke	_disk_type,si
	jz	_disk_next
	sub	ax,ax
	mov	al,dobj.dl_count
	inc	dobj.dl_count
	mov	[di].S_TOBJ.to_flag,_O_PBKEY
	mov	bx,ax
	cmp	si,disk
	jne	@F
	mov	al,dobj.dl_count
	dec	al
	mov	dobj.dl_index,al
      @@:
	mov	ax,si
	add	al,'A'
	mov	[di+3],al
	mov	WORD PTR [di+8],offset PButton
	mov	[di+10],ds
	mov	BYTE PTR [di+6],5
	mov	BYTE PTR [di+7],1
	mov	ax,bx
	and	ax,7
	mov	dl,al
	shl	al,3
	sub	al,dl
	add	al,4
	mov	[di+4],al
	mov	ax,bx
	shr	ax,3
	shl	ax,1
	add	ax,2
	mov	[di+5],al
	add	di,16
    _disk_next:
	inc	si
	cmp	si,MAXDRIVES
	jb	_disk_loop
	mov	dobj.dl_flag,_D_STDDLG
	mov	dobj.dl_rect.rc_x,8
	mov	dobj.dl_rect.rc_y,9
	mov	dobj.dl_rect.rc_col,63
	sub	ax,ax
	mov	al,dobj.dl_count
	dec	ax
	mov	bx,ax
	shr	ax,3
	shl	ax,1
	add	al,5
	mov	dobj.dl_rect.rc_row,al
	mov	ax,bx
	cmp	ax,7
	ja	@F
	shl	ax,3
	sub	ax,bx
	add	ax,14
	mov	dobj.dl_rect.rc_col,al
	mov	cl,80
	sub	cl,al
	shr	cl,1
	mov	dobj.dl_rect.rc_x,cl
      @@:
	xor	di,di
	mov	bl,at_foreground[F_Dialog]
	or	bl,at_background[B_Dialog]
	invoke	dlopen,addr dobj,bx,msg
	jz	_disk_fail
	lea	si,tobj
      @@:
	sub	ax,ax
	mov	al,dobj.dl_count
	cmp	di,ax
	jae	@F
	mov	al,[si+3]
	mov	PButton+1,al
	mov	al,dobj.dl_rect.rc_col
	invoke	rcbprc,DWORD PTR [si].S_TOBJ.to_rect,dobj.dl_wp,ax
	sub	cx,cx
	mov	cl,dobj.dl_rect.rc_col
	sub	bx,bx
	mov	bl,[si].S_TOBJ.to_rect.rc_col
	invoke	wcpbutt,dx::ax,cx,bx,addr PButton
	inc	di
	add	si,16
	jmp	@B
      @@:
	invoke	dlmodal,addr dobj
	mov	di,ax
    _disk_fail:
	sub	ax,ax
	test	di,di
	jz	@F
	sub	ax,ax
	mov	al,dobj.dl_index
	shl	ax,4
	lea	bx,tobj
	add	bx,ax
	sub	ax,ax
	mov	al,[bx+3]
	sub	al,'@'
      @@:
	ret
_disk_select ENDP

fullpath PROC _CType PUBLIC buffer:DWORD, disk:size_t
	push	si
	push	ds
    ifdef __LFNx__
	mov	cx,console
	cmp	_ifsmgr,0
    endif
	lds	si,buffer
	add	si,3
	mov	dx,disk		; drive number (DL, 0 = default)
	mov	ah,47h
    ifdef __LFNx__
	je	@F
	test	cl,CON_NTCMD
	jz	@F
	stc
	mov	ax,7147h
      @@:
    endif
	int	21h
	pop	ds
	jnc	@F
	call	osmaperr
	inc	ax
	cwd
	jmp	fullpath_end
      @@:
	mov	ax,disk
	test	ax,ax
	jz	fullpath_get
	add	al,'@'
	jmp	fullpath_drv
    fullpath_get:
	call	getdrv
	add	al,'A'
    fullpath_drv:
	les	si,buffer
	mov	ah,':'
	mov	es:[si],ax
	mov	al,'\'
	mov	es:[si+2],al
	mov	dx,es
	mov	ax,si
    fullpath_end:
	pop	si
	ret
fullpath ENDP

recursive PROC _CType PUBLIC file_name:DWORD, src_path:DWORD, dst_path:DWORD
local tmp1[WMAXPATH]:BYTE
local tmp2[WMAXPATH]:BYTE
local p1:DWORD
local p2:DWORD
	mov	dx,ss
	lea	ax,tmp1
	stom	p1
	lea	ax,tmp2
	stom	p2
  ifdef __LFN__
	invoke	wlongpath,src_path,file_name
	invoke	strcpy,p1,dx::ax
	invoke	wlongpath,dst_path, 0
	invoke	strcpy,p2,dx::ax
  else
	invoke	strfcat,p1,src_path,file_name
	invoke	strcpy,p2,dst_path
  endif
	invoke	strfn,p1
	invoke	strfcat,p2,p2,dx::ax
	invoke	strlen,p1
	mov	bx,WORD PTR p1
	add	bx,ax
	mov	WORD PTR [bx],005Ch
	inc	ax
	invoke	strnicmp,p1,p2,ax
	test	ax,ax
	jz	recursive_end
	mov	ax,-1
    recursive_end:
	inc	ax
	ret
recursive ENDP

scan_init:
	mov	[bp-12],dx
	mov	[bp-10],ds
	mov	WORD PTR [bp-8],offset scan_fblock
	mov	[bp-6],ds
	xor	ax,ax
	mov	[bp-4],ax
	mov	[bp-16],ax
ifdef __LFN__
	cmp	_ifsmgr,al
	jne	@F
endif
	mov	ah,2Fh
	int	21h
	mov	[bp-16],es
	mov	[bp-14],bx
	lea	dx,[bp-62]
	mov	ah,1Ah
	int	21h
      @@:
	ret

scan_findfirst:
	mov dx,[bp-12]
      ifdef __LFN__
	.if _ifsmgr
	    mov ax,714Eh
	    mov si,1
	    les di,[bp-8]
	    stc
	    int 21h
	    jc scan_error
	    ret
	.endif
      endif
	mov ah,4Eh
	int 21h
	jnc scan_copy
	call restore_DTA
scan_error:
	call osmaperr
	cwd
	ret

scan_findnext:
ifdef __LFN__
	.if _ifsmgr
	    stc
	    mov ax,714Fh
	    mov bx,[bp-18]
	    mov si,1
	    les di,[bp-8]
	    int 21h
	    jnc @F
	    cmp ax,0057h
	    jne scan_error
	    mov ax,714Fh
	    int 21h
	    jc scan_error
	  @@:
	    sub ax,ax
	    ret
	.endif
endif
	mov ah,4Fh
	int 21h
	jc  scan_error
	jmp scan_copy

scan_close:
ifdef __LFN__
	.if _ifsmgr
	    mov bx,[bp-18]
	    mov ax,71A1h
	    int 21h
	    ret
	.endif
endif

restore_DTA:
	mov	ax,[bp-16]
	test	ax,ax
	jz	@F
	push	ds
	mov	ds,ax
	mov	dx,[bp-14]
	mov	ah,1Ah
	int	21h
	pop	ds
      @@:
	ret

scan_copy:
	push	si
	les	di,[bp-8]
	mov	si,di
	mov	cx,S_WFBLK/2
	xor	ax,ax
	cld?
	rep	stosw
	mov	di,si
	lea	si,[bp-62]
	mov	al,[si].S_FFBLK.ff_attrib
	mov	[di],al
	movmx	[di].S_WFBLK.wf_time,[si].S_FFBLK.ff_ftime
	movmx	[di].S_WFBLK.wf_sizeax,[si].S_FFBLK.ff_fsize
	add	si,S_FFBLK.ff_name
	add	di,S_WFBLK.wf_name
	mov	cx,6
	rep	movsw
	mov	ax,cx
	stosb
	pop	si
	ret

scan_directory PROC _CType PUBLIC USES ds si di flag:WORD, path:PTR BYTE

  local locsp_d[62]:BYTE

	mov dx,offset scan_curpath
	call scan_init

	.if ( byte ptr flag & 1 )

	    pushm path
	    call fp_directory
	    mov [bp-4],ax
	    .if ax

		call restore_DTA
		jmp toend
	    .endif
	.endif

	invoke	strlen,path
	add	ax,offset scan_curpath
	mov	[bp-2],ax
	invoke	strfcat,[bp-12],path,addr cp_stdmask
	mov	cx,ATTRIB_ALL
	call	scan_findfirst
	cmp	ax,-1
	je	not_found
	mov	[bp-18],ax

	mov ax,word ptr scan_fblock.wf_name
	.if ( ax == '.' || ( ax == '..' && scan_fblock.wf_name[2] == 0 ) )

	    call scan_findnext
	    test ax,ax
	    jnz done
	.endif
	mov ax,word ptr scan_fblock.wf_name
	.if ( ax == '.' || ( ax == '..' && scan_fblock.wf_name[2] == 0 ) )

	    call scan_findnext
	    test ax,ax
	    jnz done
	.endif

	.while 1

	    .if ( byte ptr scan_fblock & _A_SUBDIR )

		mov	ax,[bp-2]
		inc	ax
		push	ds
		push	ax
		push	[bp-6]
		mov	ax,[bp-8]
		add	ax,S_WFBLK.wf_name
		push	ax
		call	strcpy
		invoke	scan_directory,flag,[bp-12]
		mov	[bp-4],ax
	       .break .if ax
	    .endif
	    call scan_findnext
	   .break .if ax
	.endw
done:
	call	scan_close
not_found:
	xor	ax,ax
	mov	bx,[bp-2]
	mov	[bx],al
toend:
	mov	ax,[bp-4]

	.if !( byte ptr flag & 1 )

	    pushm path
	    call fp_directory
	.endif
	ret

scan_directory ENDP

scan_files PROC _CType PUBLIC USES ds si di fpath:PTR BYTE
local locsp_f[62]:BYTE
	mov dx,offset scan_curfile
	call scan_init
	invoke strfcat,[bp-12],fpath,fp_maskp
	mov cx,ATTRIB_FILE
	call scan_findfirst
	.if ax != -1
	    mov [bp-18],ax
	    .repeat
		.if !(BYTE PTR scan_fblock & _A_SUBDIR)
		    pushm fpath
		    pushm [bp-8]
		    call fp_fileblock
		    mov [bp-4],ax
		    .break .if ax
		.endif
		call scan_findnext
	    .until ax
	    call scan_close
	.endif
	mov ax,[bp-4]
	ret
scan_files ENDP

scansub PROC _CType PUBLIC directory:DWORD, smask:DWORD, sflag:size_t
	movmx	fp_maskp,smask
	invoke	scan_directory,sflag,directory
	ret
scansub ENDP

	END
