; CONFIRM.ASM--
; Copyright (C) 2015 Doszip Developers

include dos.inc
include conio.inc
include confirm.inc

ID_DELETE	equ 1	; return 1
ID_DELETEALL	equ 2	; return 1 + update confirmflag
ID_SKIPFILE	equ 3	; return 0
ID_CANCEL	equ 0	; return -1

extrn	IDD_ConfirmContinue:DWORD
extrn	IDD_ConfirmDelete:DWORD

	PUBLIC	confirmflag

	.data
	confirmflag	dw -1
	cp_delselected	db "   You have selected %d file(s)",10
			db "Do you want to delete all the files",0
	cp_delflag	db "  Do you still wish to delete it?",0

	.code

confirm_continue PROC _CType PUBLIC msg:PTR BYTE
  local dialog:DWORD
	.if rsopen(IDD_ConfirmContinue)
	    stom dialog
	    invoke dlshow,dx::ax
	    lodm msg
	    .if ax
		push bx
		les bx,dialog
		mov cl,es:[bx][5]
		mov bl,es:[bx][4]
		add cl,02h
		add bl,04h
		invoke scpath,bx,cx,34,dx::ax
		pop bx
	    .endif
	    invoke dlmodal,dialog
	.endif
	ret
confirm_continue ENDP

;
; ret:	0 Cancel
;	1 Delete
;	2 Delete All
;	3 Jump
;
confirm_delete PROC _CType PUBLIC USES bx info:PTR BYTE, selected:size_t
local	DLG_ConfirmDelete:DWORD
	.if rsopen(IDD_ConfirmDelete)
	    stom DLG_ConfirmDelete
	    invoke dlshow,dx::ax
	    les bx,DLG_ConfirmDelete
	    sub ax,ax
	    mov al,es:[bx][4]
	    mov dx,ax
	    mov al,es:[bx][5]
	    mov bx,ax
	    add bx,2		; y
	    add dx,12		; x
	    mov ax,selected
	    .if ax > 1 && ax < 8000h
		invoke scputf,dx,bx,0,0,addr cp_delselected,ax
	    .else
		push dx
		.if ax == -2
		    scputf(dx,bx,0,0,
			"The following file is marked System.\n\n%s",
			addr cp_delflag)
		.elseif ax == -1
		    sub dx,2
		    scputf(dx,bx,0,0,
			"The following file is marked Read only.\n\n  %s",
			addr cp_delflag)
		.else
		    add dx,6
		    scputf(dx,bx,0,0,"Do you wish to delete")
		.endif
		pop dx
		inc bx
		sub dx,9
		invoke scenter,dx,bx,53,info
	    .endif
	    invoke beep,50,6
	    invoke rsevent,IDD_ConfirmDelete,DLG_ConfirmDelete
	    invoke dlclose,DLG_ConfirmDelete
	    mov ax,dx
	.endif
	ret
confirm_delete ENDP

confirm_delete_file PROC _CType PUBLIC USES si fname:PTR BYTE, flag:size_t
	mov ax,flag
	mov dx,confirmflag
	.if al & _A_RDONLY && dl & CFREADONY
	    mov ax,-1
	    mov si,not (CFREADONY or CFDELETEALL)
	.elseif al & _A_SYSTEM && dl & CFSYSTEM
	    mov ax,-2
	    mov si,not (CFSYSTEM or CFDELETEALL)
	.elseif dl & CFDELETEALL
	    xor ax,ax
	    mov si,not CFDELETEALL
	.else
	    mov ax,1
	    jmp @F
	.endif
	.if confirm_delete(fname,ax) == ID_DELETEALL
	    and confirmflag,si
	    mov ax,1
	.elseif ax == ID_SKIPFILE
	    xor ax,ax
	.elseif ax != ID_DELETE
	    mov ax,-1
	.endif
      @@:
	ret
confirm_delete_file ENDP

confirm_delete_sub PROC _CType PUBLIC path:PTR BYTE
	mov ax,1
	.if confirmflag & CFDIRECTORY
	    .if confirm_delete(path,1) == ID_DELETEALL
		and confirmflag,not (CFDIRECTORY or CFDELETEALL)
		mov ax,1
	    .elseif ax == ID_SKIPFILE
		mov ax,-1
	    .elseif ax != ID_DELETE
		xor ax,ax
	    .endif
	.endif
	ret
confirm_delete_sub ENDP

	END
