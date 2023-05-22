; CMQUICKSEARCH.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include io.inc
include string.inc

; (PG)UP,DOWN:	Move
; ESC,TAB,ALTX: Quit
; ENTER:	Quit
; BKSP:		Search from start
; insert char:	Search from current pos.

;SKIPSUBDIR = 1 ; Exclude directories in search

    .data

cp_quicksearch	db '&Quick Search: ',1Ah,'   ',0

    .code

psearch proc private uses rsi rdi rbx cname:string_t, l:int_t, direction:int_t

  local fcb:ptr, cindex:int_t, lindex:int_t

    ldr rbx,cpanel	; current index
    mov esi,[rbx].PANEL.fcb_index
    add esi,[rbx].PANEL.cel_index
    mov lindex,esi
    mov cindex,esi
    mov edi,[rbx].PANEL.fcb_count
    mov rbx,[rbx].PANEL.wsub
    mov fcb,[rbx].WSUB.fcb

    .if !direction	; if (direction == 0) search from start

	mov lindex,edi	; (case BKSP)
	mov esi,edi
    .endif

    .while  1

	.if ( esi >= edi )

	    xor esi,esi
	    mov edi,lindex
	    mov lindex,esi
	   .continue .if edi

	    xor eax,eax
	   .break
	.endif

	mov rbx,fcb
	mov rbx,[rbx+rsi*size_t]
      ifdef SKIPSUBDIR
	.if !( byte ptr [rbx] & _A_SUBDIR )
      endif
	.if !_strnicmp(cname, &[rbx].FBLK.name, l)

	    mov rbx,cpanel
	    dlclose([rbx].PANEL.xl)
	    panel_setid(rbx, esi)
	    panel_putitem(rbx, 0)
	    pcell_show(rbx)
	    mov eax,1
	   .break
	.endif
      ifdef SKIPSUBDIR
	.endif
      endif
	inc esi
    .endw
    mov edx,cindex
    ret

psearch endp

cmquicksearch proc uses rsi rdi rbx

   .new cursor:CURSOR
   .new stline[256]:CHAR_INFO
   .new fname[256]:char_t
   .new key:int_t

    .if cpanel_state()

	_getcursor(&cursor)
	_cursoron()
	wcpushst(&stline, &cp_quicksearch)

	lea rbx,fname
	mov esi,15		; SI = x
	mov edi,_scrrow		; DI = y
	_gotoxy(esi, edi)	; cursor to (x,y)

	.repeat
	    tupdate()
	    .switch getkey()	; get key
	    .case 0
	    .case KEY_ESC
	    .case KEY_TAB
	    .case KEY_ALTX
		.endc
	    .case KEY_ENTER
	    .case KEY_KPENTER
		lea eax,[rsi-15]
		psearch(rbx, eax, 1)
	      ifdef SKIPSUBDIR
		xor eax,eax
	      else
		.if eax
		    mov rcx,cpanel
		    mov eax,[rcx].PANEL.fcb_index
		    add eax,[rcx].PANEL.cel_index
		    .if eax == edx
			inc eax
		    .else
			xor eax,eax
		    .endif
		.endif
	      endif
		.endc
	    .case KEY_LEFT
	    .case KEY_RIGHT
	    .case KEY_UP
	    .case KEY_PGUP
	    .case KEY_DOWN
	    .case KEY_PGDN
	    .case KEY_HOME
	    .case KEY_END
		panel_event(cpanel, eax)
		xor eax,eax
	       .endc
	    .case KEY_BKSP
		;
		; delete char and search from start
		;
		.ifs ( esi > 15 )

		    dec esi
		    mov edx,edi
		    scputw(esi, edi, 2, ' ')
		    _gotoxy(esi, edi)
		    xor eax,eax
		    mov ecx,15
		    jmp event_back
		.endif
		xor eax,eax
		.endc

	    .default
		movzx eax,al
		mov [rbx+rsi-15],al
		mov ecx,14

	       event_back:
		mov key,eax
		mov edx,esi
		sub edx,ecx
		.if psearch(rbx, edx, eax)
		    .if key
			scputw(esi, edi, 1, key)
			.ifs ( esi < 78 )
			    inc esi
			    _gotoxy(esi, edi)
			.endif
		    .endif
		.endif
		xor eax,eax
	    .endsw
	.until eax
	wcpopst(&stline)
	_setcursor(&cursor)
    .endif
    .return( 0 )

cmquicksearch endp

    END
