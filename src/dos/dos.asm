; DOS.ASM--
; Copyright (C) 2015 Doszip Developers

include dos.inc
include math.inc
include errno.inc
include io.inc
include dir.inc
include string.inc
include conio.inc

extrn	envtemp:DWORD

	.code

ER_INVALID_FUNCTION		equ 1
ER_FILE_NOT_FOUND		equ 2
ER_PATH_NOT_FOUND		equ 3
ER_TOO_MANY_OPEN_FILES		equ 4
ER_ACCESS_DENIED		equ 5
ER_INVALID_HANDLE		equ 6
ER_ARENA_TRASHED		equ 7
ER_NOT_ENOUGH_MEMORY		equ 8
ER_INVALID_BLOCK		equ 9
ER_BAD_ENVIRONMENT		equ 10
ER_BAD_FORMAT			equ 11
ER_INVALID_ACCESS		equ 12
ER_INVALID_DATA			equ 13
ER_INVALID_DRIVE		equ 15
ER_CURRENT_DIRECTORY		equ 16
ER_NOT_SAME_DEVICE		equ 17
ER_NO_MORE_FILES		equ 18
ER_WRITE_PROTECT		equ 19
ER_NOT_ENOUGH_QUOTA		equ 24
ER_LOCK_VIOLATION		equ 33
ER_SHARINGBUF_EXCEEDED		equ 36
ER_BAD_NETPATH			equ 53
ER_NETWORK_ACCESS_DENIED	equ 65
ER_BAD_NET_NAME			equ 67
ER_FILE_EXISTS			equ 80
ER_CANNOT_MAKE			equ 82
ER_FAIL_I24			equ 83
ER_INVALID_PARAMETER		equ 87
ER_NO_PROC_SLOTS		equ 89
ER_DRIVE_LOCKED			equ 108
ER_BROKEN_PIPE			equ 109
ER_DISK_FULL			equ 112
ER_INVALID_TARGET_HANDLE	equ 114
ER_INVALID_LEVEL		equ 124
ER_WAIT_NO_CHILDREN		equ 128
ER_CHILD_NOT_COMPLETE		equ 129
ER_DIRECT_ACCESS_HANDLE		equ 130
ER_NEGATIVE_SEEK		equ 131
ER_SEEK_ON_DEVICE		equ 132
ER_DIR_NOT_EMPTY		equ 145
ER_NOT_LOCKED			equ 158
ER_BAD_PATHNAME			equ 161
ER_MAX_THRDS_REACHED		equ 164
ER_LOCK_FAILED			equ 167
ER_ALREADY_EXISTS		equ 183
ER_INVALID_CODESEG		equ 188
ER_LOOP_IN_RELOC_CHAIN		equ 202
ER_FILENAME_EXCED_RANGE		equ 206
ER_NESTING_NOT_ALLOWED		equ 215

	PUBLIC	convbuf
ifdef __LFN__
	PUBLIC	_ifsmgr
endif
	PUBLIC	dos_errlist
	PUBLIC	sys_errlist

	PUBLIC	CP_DOSER04
	PUBLIC	CP_DOSER20
	PUBLIC	CP_ENOMEM
	PUBLIC	CP_UNKNOWN
	PUBLIC	CP_ENOENT
	PUBLIC	CP_ENOSYS

.data
 T1	dd ?
 convbuf db 270 dup(0)
ifdef __LFN__
_ifsmgr db ?	; 71h
	db ?
endif
 errnotable label BYTE
	db EINVAL
	db ENOENT
	db ENOENT
	db EMFILE
	db EACCES
	db EBADF
	db ENOMEM
	db ENOMEM
	db ENOMEM
	db E2BIG
	db ENOEXEC
	db EINVAL
	db EINVAL
	db ENOENT
	db EACCES
	db EXDEV
	db ENOENT
	db EACCES
	db ENOENT
	db EACCES
	db ENOENT
	db EEXIST
	db EACCES
	db EACCES
	db EINVAL
	db EAGAIN
	db EACCES
	db EPIPE
	db ENOSPC
	db EBADF
	db EINVAL
	db ECHILD
	db ECHILD
	db EBADF
	db EINVAL
	db EACCES
	db ENOTEMPTY
	db EACCES
	db ENOENT
	db EAGAIN
	db EACCES
	db EEXIST
	db ENOENT
	db EAGAIN
	db ENOMEM

 doserrtable label BYTE
	db ER_INVALID_FUNCTION
	db ER_FILE_NOT_FOUND
	db ER_PATH_NOT_FOUND
	db ER_TOO_MANY_OPEN_FILES
	db ER_ACCESS_DENIED
	db ER_INVALID_HANDLE
	db ER_ARENA_TRASHED
	db ER_NOT_ENOUGH_MEMORY
	db ER_INVALID_BLOCK
	db ER_BAD_ENVIRONMENT
	db ER_BAD_FORMAT
	db ER_INVALID_ACCESS
	db ER_INVALID_DATA
	db ER_INVALID_DRIVE
	db ER_CURRENT_DIRECTORY
	db ER_NOT_SAME_DEVICE
	db ER_NO_MORE_FILES
	db ER_LOCK_VIOLATION
	db ER_BAD_NETPATH
	db ER_NETWORK_ACCESS_DENIED
	db ER_BAD_NET_NAME
	db ER_FILE_EXISTS
	db ER_CANNOT_MAKE
	db ER_FAIL_I24
	db ER_INVALID_PARAMETER
	db ER_NO_PROC_SLOTS
	db ER_DRIVE_LOCKED
	db ER_BROKEN_PIPE
	db ER_DISK_FULL
	db ER_INVALID_TARGET_HANDLE
	db ER_INVALID_HANDLE
	db ER_WAIT_NO_CHILDREN
	db ER_CHILD_NOT_COMPLETE
	db ER_DIRECT_ACCESS_HANDLE
	db ER_NEGATIVE_SEEK
	db ER_SEEK_ON_DEVICE
	db ER_DIR_NOT_EMPTY
	db ER_NOT_LOCKED
	db ER_BAD_PATHNAME
	db ER_MAX_THRDS_REACHED
	db ER_LOCK_FAILED
	db ER_ALREADY_EXISTS
	db ER_FILENAME_EXCED_RANGE
	db ER_NESTING_NOT_ALLOWED
	db ER_NOT_ENOUGH_QUOTA


CP_DOSER00	db "Write-protection violation attempted",0
CP_DOSER01	db "Unknown unit for driver",0
CP_DOSER02	db "Drive not ready",0
CP_DOSER03	db "Unknown command given to driver",0
CP_DOSER04	db "Data error (bad CRC)",0
CP_DOSER05	db "Bad device driver request structure length",0
CP_DOSER06	db "Seek error",0
CP_DOSER07	db "Unknown media type",0
CP_DOSER08	db "Sector not found",0
CP_DOSER09	db "Printer out of paper..",0
CP_DOSER10	db "Write fault",0
CP_DOSER11	db "Read fault",0
CP_DOSER12	db "General failure",0
CP_DOSER13	db "Sharing violation",0
CP_DOSER14	db "Lock violation",0
CP_DOSER15	db "Invalid disk change",0
CP_DOSER16	db "FCB unavailable",0
CP_DOSER17	db "Sharing buffer overflow",0
CP_DOSER18	db "Code page mismatch",0
CP_DOSER19	db "Out of input",0
CP_DOSER20	db "Insufficient disk space",0

CP_NOERROR	db 'No '
CP_ERROR	db 'Error',0
CP_EPERM	db "Operation not permitted",0
CP_ENOENT	db "No such file or directory",0
CP_ESRCH	db "No such process",0
CP_EINTR	db "Interrupted function call",0
CP_EIO		db "Input/output error",0
CP_ENXIO	db "No such device or address",0
CP_E2BIG	db "Arg list too long",0
CP_ENOEXEC	db "Exec format error",0
CP_EBADF	db "Bad file descriptor",0
CP_ECHILD	db "No child processes",0
CP_EAGAIN	db "Resource temporarily unavailable",0
CP_ENOMEM	db "Not enough space",0
CP_EACCES	db "Permission denied",0
CP_EFAULT	db "Bad address",0
CP_EBUSY	db "Resource device",0
CP_EEXIST	db "File exists",0
CP_EXDEV	db "Improper link",0
CP_ENODEV	db "No such device",0
CP_ENOTDIR	db "Not a directory",0
CP_EISDIR	db "Is a directory",0
CP_EINVAL	db "Invalid argument",0
CP_ENFILE	db "Too many open files in system",0
CP_EMFILE	db "Too many open files",0
CP_ENOTTY	db "Inappropriate I/O control operation",0
CP_EFBIG	db "File too large",0
CP_ENOSPC	db "No space left on device",0
CP_ESPIPE	db "Invalid seek",0
CP_EROFS	db "Read-only file system",0
CP_EMLINK	db "Too many links",0
CP_EPIPE	db "Broken pipe",0
CP_EDOM		db "Domain error",0
CP_ERANGE	db "Result too large",0
CP_EDEADLK	db "Resource deadlock avoided",0
CP_ENAMETOOLONG db "Filename too long",0
CP_ENOLCK	db "No locks available",0
CP_ENOSYS	db "Function not implemented",0
CP_ENOTEMPTY	db "Directory not empty",0
CP_EILSEQ	db "Illegal byte sequence",0
CP_UNKNOWN	db "Unknown error",0

align 2
dos_errlist label DWORD
	dd CP_DOSER00
	dd CP_DOSER01
	dd CP_DOSER02
	dd CP_DOSER03
	dd CP_DOSER04
	dd CP_DOSER05
	dd CP_DOSER06
	dd CP_DOSER07
	dd CP_DOSER08
	dd CP_DOSER09
	dd CP_DOSER10
	dd CP_DOSER11
	dd CP_DOSER12
	dd CP_DOSER13
	dd CP_DOSER14
	dd CP_DOSER15
	dd CP_DOSER16
	dd CP_DOSER17
	dd CP_DOSER18
	dd CP_DOSER19
	dd CP_DOSER20

sys_errlist label DWORD
	dd CP_NOERROR
	dd CP_EPERM
	dd CP_ENOENT
	dd CP_ESRCH
	dd CP_EINTR
	dd CP_EIO
	dd CP_ENXIO
	dd CP_E2BIG
	dd CP_ENOEXEC
	dd CP_EBADF
	dd CP_ECHILD
	dd CP_EAGAIN
	dd CP_ENOMEM
	dd CP_EACCES
	dd CP_EFAULT
	dd CP_UNKNOWN
	dd CP_EBUSY
	dd CP_EEXIST
	dd CP_EXDEV
	dd CP_ENODEV
	dd CP_ENOTDIR
	dd CP_EISDIR
	dd CP_EINVAL
	dd CP_ENFILE
	dd CP_EMFILE
	dd CP_ENOTTY
	dd CP_UNKNOWN
	dd CP_EFBIG
	dd CP_ENOSPC
	dd CP_ESPIPE
	dd CP_EROFS
	dd CP_EMLINK
	dd CP_EPIPE
	dd CP_EDOM
	dd CP_ERANGE
	dd CP_UNKNOWN
	dd CP_EDEADLK
	dd CP_UNKNOWN
	dd CP_ENAMETOOLONG
	dd CP_ENOLCK
	dd CP_ENOSYS
	dd CP_ENOTEMPTY
	dd CP_EILSEQ
	dd CP_UNKNOWN

;sys_nerr dw (($ - offset sys_errlist) / 4)

shortname db 14 dup(?)

.code

osmaperr PROC PUBLIC
	push	bx
	push	ds
	push	dx
	push	cx
	push	ss
	pop	ds
	mov	dx,ax
	mov	doserrno,ax
	sub	cx,cx
	jmp	osmaperr_loop
    osmaperr_next:
	mov	bx,cx
	cmp	dl,[bx+doserrtable]
	jnz	osmaperr_01
	sub	ax,ax
	mov	al,errnotable[bx]
	mov	errno,ax
	jmp	osmaperr_end
    osmaperr_01:
	inc	cx
    osmaperr_loop:
	cmp	cx,45
	jl	osmaperr_next
	cmp	dx,ER_WRITE_PROTECT
	jb	osmaperr_37
	cmp	dx,ER_SHARINGBUF_EXCEEDED
	ja	osmaperr_37
	mov	errno,EACCES
	jmp	osmaperr_end
    osmaperr_37:
	cmp	dx,ER_INVALID_CODESEG
	jb	osmaperr_22
	cmp	dx,ER_LOOP_IN_RELOC_CHAIN
	ja	osmaperr_22
	mov	errno,ENOEXEC
	jmp	osmaperr_end
    osmaperr_22:
	mov	errno,EINVAL
    osmaperr_end:
	pop	cx
	pop	dx
	pop	ds
	pop	bx
	mov	ax,-1
	ret
osmaperr ENDP

delay PROC _CType PUBLIC USES bx time:size_t
	push	si
	push	di
ifdef __3__
	movzx	eax,time
	mul	cs:T1
	shld	edx,eax,16
else
	lodm	cs:T1
	xor	cx,cx
	mov	bx,time
	call	_mul32
endif
	mov	si,dx
	mov	di,ax
	call	read_timer
	mov	bx,dx
	add	di,dx
	adc	si,0
	jmp	delay_02
    delay_loop:
	cmp	dx,bx
	jnb	delay_01
	or	si,si
	jz	delay_end
	sub	si,1
	sbb	di,0
    delay_01:
	mov	bx,dx
    delay_02:
	call	read_timer
	or	si,si
	jnz	delay_loop
	cmp	dx,di
	jb	delay_loop
    delay_end:
	pop	di
	pop	si
	ret
delay ENDP

beep	PROC _CType PUBLIC __hz:WORD, __time:WORD
	mov	ax,WORD PTR console
	and	ax,CON_UBEEP
	jz	@F
	mov	bx,__hz
	mov	dx,__time
	mov	ax,00B6h
	out	43h,al
	mov	ax,0
	out	42h,al
	mov	ax,bx
	out	42h,al
	mov	al,4Fh
	out	61h,al
	invoke	delay,dx
	mov	al,4Dh
	out	61h,al
      @@:
	ret
beep	ENDP

remove	PROC _CType PUBLIC file:DWORD
ifdef __LFN__
	push	si
	mov	al,_ifsmgr
	test	al,al
endif
	push	ds
	lds	dx,file
	mov	ah,41h
ifdef __LFN__
	jz	@F
	xor	si,si
	stc
	mov	ax,7141h
@@:
endif
	int	21h
	pop	ds
	jc	error
	xor	ax,ax
toend:
ifdef __LFN__
	pop	si
endif
	ret
error:
	call	osmaperr
	jmp	toend
remove	ENDP

rename	PROC _CType PUBLIC Oldname:DWORD, Newname:DWORD
ifdef __LFN__
	mov	dx,_osversion
	mov	ax,5600h	; DOS 2+ - RENAME FILE
	cmp	_ifsmgr,0
	je	@F
	mov	ax,43FFh	; MS-DOS 7.20 (Win98)
	mov	cl,56h
	cmp	dx,0207h
	je	@F
	mov	ax,7156h	; Windows95 - RENAME FILE
	cmp	dl,7
	je	@F
	cmp	dl,5
	je	@F
	mov	ax,5600h	; DOS 2+ - RENAME FILE
@@:
	stc
endif
	push	ds
	push	di
	lds	dx,Oldname
	les	di,Newname
	int	21h
	pop	di
	pop	ds
	jc	error
	xor	ax,ax
toend:
	ret
error:
	call	osmaperr
	jmp	toend
rename	ENDP

;
; int _dos_setfileattr(char *path, unsigned attrib);
;
; Return 0 on success, else DOS error code
;
_dos_setfileattr PROC _CType PUBLIC file:DWORD, attrib:size_t
	push	ds
ifdef __LFN__
	cmp	_ifsmgr,0
endif
	lds	dx,file
	mov	cx,attrib
	mov	ax,4301h
ifdef __LFN__
	jz	@F
	stc
	mov	ax,7143h
	mov	bl,1
@@:
endif
	int	21h
	pop	ds
	jc	error
	xor	ax,ax
toend:
	ret
error:
	call	osmaperr
	mov	ax,doserrno
	jmp	toend
_dos_setfileattr ENDP

;
; unsigned _dos_setftime(int handle, unsigned date, unsigned time);
;
; Return 0 on success, else DOS error code
;
_dos_setftime PROC _CType PUBLIC handle:size_t, datew:size_t, timew:size_t
	stc
	push	bx
	push	cx
	push	dx
	mov	ax,5701h
	mov	bx,handle
	mov	dx,datew
	mov	cx,timew
	int	21h
	pop	dx
	pop	cx
	pop	bx
	jc	error
	xor	ax,ax
    toend:
	ret
    error:
	call	osmaperr
	mov	ax,doserrno
	jmp	toend
_dos_setftime ENDP


getfattr PROC _CType PUBLIC file:DWORD
ifdef __LFN__
	cmp	_ifsmgr,0
endif
	push	ds
	push	bx
	lds	dx,file
	mov	ax,4300h
ifdef __LFN__
	jz	@F
	stc
	mov	ax,7143h
	mov	bl,0
      @@:
endif
	int	21h
	pop	bx
	pop	ds
	jc	error
	mov	ax,cx
      @@:
	ret
error:
	call	osmaperr
	jmp	@B
getfattr ENDP

getftime PROC _CType PUBLIC handle:size_t, ftime:PTR S_FTIME
	push	bx
	push	cx
	mov	bx,handle
	mov	ax,5700h
	int	21h
	jc	error
	mov	ax,cx
	les	bx,ftime
	stom	es:[bx]
	xor	ax,ax
    toend:
	pop	cx
	pop	bx
	ret
    error:
	call	osmaperr
	jmp	toend
getftime ENDP

filexist PROC _CType PUBLIC file:DWORD
	invoke	getfattr,file
	inc	ax
	jz	@F
	dec	ax		; 1 = file
	and	ax,_A_SUBDIR	; 2 = subdir
	shr	ax,4
	inc	ax
      @@:
	ret
filexist ENDP

findfirst PROC _CType PUBLIC USES bx file:DWORD, fblk:DWORD, attr:WORD
	push	ds
	mov	ah,2Fh
	int	21h
	push	es
	push	bx
	mov	ah,1Ah
	lds	dx,fblk
	int	21h
	mov	ah,4Eh
	mov	cx,attr
	lds	dx,file
	int	21h
	pushf
	pop	cx
	xchg	ax,bx
	mov	ah,1Ah
	pop	dx
	pop	ds
	int	21h
	push	cx
	popf
	pop	ds
	jc	error
	xor	ax,ax
toend:
	ret
error:
	call	osmaperr
	jmp	toend
findfirst ENDP

findnext PROC _CType PUBLIC USES bx fblk:DWORD
	push	ds
	mov	ah,2Fh
	int	21h
	push	es
	push	bx
	mov	ah,1Ah
	lds	dx,fblk
	int	21h
	mov	ah,4Fh
	int	21h
	pushf
	pop	cx
	xchg	ax,bx
	mov	ah,1Ah
	pop	dx
	pop	ds
	int	21h
	push	cx
	popf
	pop	ds
	jc	error
	xor	ax,ax
toend:
	ret
error:
	call	osmaperr
	jmp	toend
findnext ENDP

removefile PROC _CType PUBLIC file:DWORD
	invoke _dos_setfileattr,file,0
	invoke remove,file
	ret
removefile ENDP

removetemp PROC _CType PUBLIC path:DWORD
local nbuf[WMAXPATH]:BYTE
	invoke strfcat,addr nbuf,envtemp,path
	invoke removefile,dx::ax
	ret
removetemp ENDP



wfindnext PROC _CType PUBLIC ff:DWORD, handle:WORD
	push	si
	push	di
	push	bx
	stc
	mov	ax,714Fh
	mov	bx,handle
	mov	si,1
	les	di,ff
	int	21h
	jc	error
success:
	xor	ax,ax
toend:
	pop	bx
	pop	di
	pop	si
	ret
error:
	cmp	ax,57h
	jne	@F
	mov	ax,714Fh
	int	21h
	jnc	success
@@:
	call	osmaperr
	jmp	toend
wfindnext ENDP

wfindfirst PROC _CType PUBLIC fmask:DWORD, fblk:DWORD, attrib:WORD
	push	si
	push	di
	stc
	push	ds
	mov	ax,714Eh
	mov	si,1
	mov	cx,attrib
	les	di,fblk
	lds	dx,fmask
	int	21h
	pop	ds
	jc	error
toend:
	pop	di
	pop	si
	ret
error:
	call	osmaperr
	jmp	toend
wfindfirst ENDP

wcloseff PROC _CType PUBLIC handle:WORD
	mov	ax,71A1h
	mov	bx,handle
	int	21h
	sub	ax,ax
	ret
wcloseff ENDP

ifdef __LARGE__
argfile equ [bp+6]
argpath equ [bp+6+4]
else
argfile equ [bp+4]
argpath equ [bp+4+4]
endif

wconvert proc
	les	di,argfile
	mov	ax,WORD PTR argpath
	cmp	_ifsmgr,0
	jne	@F
	test	ax,ax
	jnz	@F
	cmp	BYTE PTR es:[di+1],':'
	je	@F
	invoke	fullpath,addr convbuf,0
	invoke	strfcat,addr convbuf,0,argfile
	jmp	done
@@:
	test	ax,ax
	jnz	@F
	test	di,di
	jz	@F
	invoke	strcpy,addr convbuf,argfile
	jmp	done
@@:
	push	ds
	push	offset convbuf
	pushm	argpath
	test	di,di
	jz	@F
	pushm	argfile
	call	strfcat
	jmp	done
@@:
	call	strcpy
done:
	mov	es,dx
	mov	si,ax
	mov	di,ax
ifdef __LFN__
	cmp	_ifsmgr,0
	je	@F
	mov	ax,7160h
	mov	cx,2
	int	21h
@@:
endif
	invoke	strfn,ds::di
	mov	di,ax
	ret
wconvert endp

wlongname PROC _CType PUBLIC USES si path:DWORD, file:DWORD
	push	ds
	push	di
	call	wconvert
	mov	dx,ds
	mov	ax,di
	pop	di
	pop	ds
	ret
wlongname ENDP

wlongpath PROC _CType PUBLIC USES si path:DWORD, file:DWORD
	push	ds
	push	di
	call	wconvert
	mov	dx,ds
	mov	ax,si
	pop	di
	pop	ds
	ret
wlongpath ENDP

wgetcwd PROC _CType PUBLIC path:DWORD, drive:WORD
	push	si
	push	ds
ifdef __LFN__
	mov	al,_ifsmgr
	test	al,al
endif
	mov	dx,drive
	lds	si,path
	mov	ah,47h
ifdef __LFN__
	jz	wgetcwd_21h
	stc
	mov	ax,7147h
    wgetcwd_21h:
endif
	int	21h
	pop	ds
	jc	wgetcwd_fail
	mov	ax,WORD PTR path
	mov	dx,WORD PTR path+2
    wgetcwd_end:
	pop	si
	ret
    wgetcwd_fail:
	call	osmaperr
	inc	ax
	cwd
	jmp	wgetcwd_end
wgetcwd ENDP

wfullpath PROC _CType PUBLIC buf:DWORD, drv:WORD
	push	WORD PTR buf+2
	mov	ax,WORD PTR buf
	add	ax,3
	push	ax
	push	drv
	call	wgetcwd
	or	ax,dx
	jz	wfullpath_02
	mov	ax,drv
	test	ax,ax
	jz	wfullpath_00
	add	al,'@'
	jmp	wfullpath_01
    wfullpath_00:
	call	getdrv
	add	al,'A'
    wfullpath_01:
	les	bx,buf
	mov	ah,':'
	mov	es:[bx],ax
	mov	al,'\'
	mov	es:[bx+2],al
	mov	dx,es
	mov	ax,bx
    wfullpath_02:
	ret
wfullpath ENDP

wsetacdate PROC _CType PUBLIC USES di bx path:DWORD, acdate:WORD
	push	ds
	lds	dx,path
	mov	di,acdate
	stc
	mov	ax,7143h
	mov	bl,5
	int	21h
	pop	ds
	jc	wsetacdate_error
	xor	ax,ax
    wsetacdate_toend:
	ret
    wsetacdate_error:
	call	osmaperr
	jmp	wsetacdate_toend
wsetacdate ENDP

wsetcrdate PROC _CType PUBLIC USES si di bx path:DWORD, crdate:WORD, crtime:WORD
	push	ds
	lds	dx,path
	mov	cx,crtime
	mov	di,crdate
	xor	si,si
	stc
	mov	ax,7143h
	mov	bl,7
	int	21h
	pop	ds
	jc	wsetcrdate_error
	xor	ax,ax
    wsetcrdate_toend:
	ret
    wsetcrdate_error:
	call	osmaperr
	jmp	wsetcrdate_toend
wsetcrdate ENDP

wsetwrdate PROC _CType PUBLIC USES di bx path:DWORD, wrdate:WORD, wrtime:WORD
	push	ds
	lds	dx,path
	mov	cx,wrtime
	mov	di,wrdate
	stc
	mov	ax,7143h
	mov	bl,3
	int	21h
	pop	ds
	jc	wsetwrdate_error
	xor	ax,ax
    wsetwrdate_end:
	ret
    wsetwrdate_error:
	call	osmaperr
	jmp	wsetwrdate_end
wsetwrdate ENDP

wshortname PROC _CType PUBLIC path:DWORD
local wblk:S_WFBLK
	invoke	wfindfirst, path, addr wblk, 00FFh
	push	ax
	invoke	wcloseff, ax
	pop	ax
	inc	ax
	mov	ax,WORD PTR path
	mov	dx,WORD PTR path[2]
	jz	@F
	cmp	wblk.wf_shortname,0
	je	@F
	mov	shortname[12],0
	invoke	memcpy, addr shortname, addr wblk.wf_shortname, 12
@@:
	ret
wshortname ENDP

wvolinfo PROC _CType PUBLIC path:PTR BYTE, buffer:PTR BYTE
	push	ds
	push	di
	stc
	mov	ax,71A0h
	mov	cx,32
	les	di,buffer	; 32 byte 'FAT32','CDFS',...
	lds	dx,path		; 'C:\*.*'
	int	21h
	jc	@F
	xor	ax,ax		; return 0
@@:
	pop	di
	pop	ds
	ret
wvolinfo ENDP


dummy:	push	si
	push	di
	pop	di
	pop	si
	ret

read_timer proc
	pushf
	cli
	xor	ax,ax
	out	43h,al
	call	dummy
	in	al,40h
	mov	dl,al
	call	dummy
	in	al,40h
	mov	dh,al
	not	dx
	popf
	ret
read_timer endp

ifdef __LFN__

__initifs proc private
	push	di
	sub	sp,32
	mov	di,sp
	mov	ax,ss
	mov	es,ax
	mov	ah,19h
	int	21h
	add	al,'A'
	mov	ah,':'
	mov	[di],ax
	mov	ax,'\'
	mov	[di+2],ax
	mov	dx,di
	mov	cx,32
	mov	ax,71A0h
	stc
	int	21h
	jc	Install_02
	and	bh,40h
	jz	Install_02
	mov	_ifsmgr,71h
	mov	_ifsmgr+1,bh
    Install_02:
	add	sp,32
	pop	di
	ret
__initifs endp

endif

__inittimer proc private
	mov	cx,100
      @@:
	call	read_timer
	and	dx,1
	jz	@F
	dec	cx
	jnz	@B
	mov	WORD PTR cs:T1,2*1193
	mov	WORD PTR cs:T1+2,cx
	ret
      @@:
	mov	WORD PTR cs:T1,1193
	mov	WORD PTR cs:T1+2,dx
	ret
__inittimer endp

_TEXT	ENDS

ifdef __LFN__
pragma_init __initifs, 4
endif
pragma_init __inittimer, 9

	END
