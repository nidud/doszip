; TVIEW.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT
;
; Change history:
; 2016-03-09 - fixed CR/LF read
; 2013-09-19 - tview.asm -- 32 bit
; 2013-03-06 - added Memory View (doszip)
; 12/28/2011 - removed Binary View (doszip)
;        - removed Class View (doszip)
;        - removed View Memory (doszip)
;        - added zoom function (F11)
; 08/02/2010 - added Class View
; 10/10/2009 - fixed bug in Clipboard
; 10/10/2009 - new malloc() and free()
; 11/15/2008 - added function Seek
; 11/13/2008 - Moved Binary View to F4
;        - added switch /M, view memory [00000..FFFFF]
; 09/10/2008 - Divide error in putinfo(percent)
;        - command END  in dump text (F2) moves to top of file
;        - command UP   in dump text (F2) moves to top of file
;        - command PGUP in dump text (F2) moves to top of file
;        - command END  in hex view  (F4) offset not aligned
;        - command END  in HEX and BIN -- last offset + 1 < offset
;        - added short key Ctrl+End -- End of line (End right)
;        - added IO Bit Stream
; 04/20/2007 - added switch /O<offset>
; 03/15/2007 - fixed Short-Key ESC on zero byte files
; 03/12/2007 - added Binary View
; 2004-06-27 - tview.asm -- 16 bit
; 1998-02-10 - tview.c
;

include malloc.inc
include string.inc
include stdio.inc
include stdlib.inc
include io.inc
include wsub.inc
include direct.inc
include errno.inc
include conio.inc
include time.inc
include tview.inc
include doszip.inc

define MAXLINE  0x8000
define MAXLINES 256
ifdef _WIN64
define FSIZE <STDI.fsize>
else
define FSIZE <STDI.fsize_l>
endif

.enumt TVCOPY:TOBJ {
    ID_TVCOPY,
    ID_START,
    ID_SIZE,
    ID_FILENAME,
    ID_CLIPBOARD,
    ID_HEXOUTPUT,
    ID_COPY,
    ID_CANCEL
    }

    .data
     QuickMenuKeys UINT \
        KEY_F5,
        KEY_F7,
        KEY_F2,
        KEY_F4,
        KEY_F6,
        KEY_ESC
     UseClipboard BYTE 0
     rsrows BYTE 24

    .code

    option proc:private

HexOutput proc uses rsi rdi rbx off:UINT, len:UINT

   .new result:LPSTR = NULL
   .new c:int_t
   .new p:LPSTR

    imul eax,len,16
    inc eax
    mov ecx,10+16*3+2+16+2
    mul ecx
    inc eax
    .if ( malloc(eax) == NULL )
        .return
    .endif
    mov rdi,rax
    mov result,rax

    .while len

        add rdi,sprintf(rdi, "%08X  ", off)
        mov ebx,16
        add off,ebx
        xor esi,esi
        lea rdx,[rdi+16*3+2]
        mov p,rdx

        .while ebx && esi < len

            .if esi == 8
                strcpy(rdi, "| ")
                add rdi,2
            .endif
            .if ogetc() == -1

                .break( 1 )
            .endif
            mov c,eax
            sprintf(rdi, "%02X", eax)
            add rdi,3
            mov byte ptr [rdi-1],' '
            mov eax,c
            .if eax < ' '
                mov eax,'.'
            .endif
            sprintf(p, "%c", eax)
            dec ebx
            inc p
            inc esi
        .endw
        sub len,esi
        mov eax,'    '
        .while esi < 16
            .if esi == 8
                stosw
            .endif
            stosw
            stosb
            inc esi
        .endw
        mov rdi,p
        mov eax,0x0A0D
        stosw
    .endw
    mov byte ptr [rdi],0
    mov rdx,rdi
    sub rdx,result
    mov rax,result
    ret

HexOutput endp

CopySection proc uses rsi rdi rbx loffs:size_t, curcol:UINT

    .if !rsopen(IDD_TVCopy)

        .return
    .endif

    mov rbx,rax
    .if UseClipboard
        or [rbx].TOBJ.flag[ID_CLIPBOARD],_O_FLAGB
    .endif
    mov edx,curcol
    add rdx,loffs
    mov curcol,0
    lea rax,@CStr("%08Xh")
    .if !( tvflag & _TV_HEXOFFSET )
        lea rax,@CStr("%u")
    .endif
    sprintf([rbx].TOBJ.data[ID_START], rax, rdx)
    dlinit(rbx)

    .if rsevent(IDD_TVCopy, rbx)

        mov UseClipboard,0
        .if [rbx].TOBJ.flag[ID_CLIPBOARD] & _O_FLAGB
            mov UseClipboard,1
        .endif
        .if strtolx([rbx].TOBJ.data[ID_START]) < FSIZE

            .if ( oseek(eax, SEEK_SET) != -1 )

                mov rdi,rax
                xor eax,eax
                .if UseClipboard

                    .if strtolx([rbx].TOBJ.data[ID_SIZE])

                        mov esi,eax
                        .if [rbx].TOBJ.flag[ID_HEXOUTPUT] & _O_FLAGB

                            mov rdi,HexOutput(edi, eax)
                            mov esi,edx
                        .else
                            oread()
                            xor edi,edi
                        .endif
                        .if rax
                            ClipboardCopy(rax, esi)
                            ClipboardFree()
                            free(rdi)
                        .endif
                    .endif

                .elseif ioinit(&STDO, 0x8000)

                    .if ogetouth([rbx].TOBJ.data[ID_FILENAME], M_WRONLY) != -1

                        mov STDO.file,eax
                        strtolx([rbx].TOBJ.data[ID_SIZE])
                        .if [rbx].TOBJ.flag[ID_HEXOUTPUT] & _O_FLAGB

                            mov rdi,HexOutput(edi, eax)
                            oswrite(STDO.file, rdi, edx)
                            free(rdi)
                        .else
                          ifdef _WIN64
                            iocopy(&STDO, &STDI, rax)
                          else
                            xor edx,edx
                            iocopy(&STDO, &STDI, edx::eax)
                          endif
                            ioflush(&STDO)
                        .endif
                        ioclose(&STDO)
                    .else
                        iofree(&STDO)
                    .endif
                .endif
            .endif
        .endif
    .endif
    dlclose(rbx)
    mov eax,curcol
    ret

CopySection endp

cmmcopy proc uses rsi rdi rbx

  local lb[256]:byte

    mov rdx,IDD_TVQuickMenu
    mov eax,keybmouse_x
    mov esi,eax
    mov [rdx].RIDD.rc.x,al
    mov ebx,keybmouse_y
    mov [rdx].RIDD.rc.y,bl

    .if rsmodal(rdx)

        .if eax != 1

            lea rcx,QuickMenuKeys
            PushEvent([rcx+rax*4-8])
        .else
            lea rdi,lb
            .while esi < _scrcol
                getxyc(esi, ebx)
                stosb
                inc esi
            .endw
            xor eax,eax
            stosb
            lea rdi,lb
            .if strtrim(rdi)

                ClipboardCopy(rdi, eax)
                ClipboardFree()
                stdmsg("Copy", "%s\n\nis copied to clipboard", rdi)
            .endif
        .endif
    .endif
    ret

cmmcopy endp

update_dialog proc

    .if ( tvflag & _TV_USESLINE )
        lea rax,@CStr("Hex  ")
        .if ( tvflag & _TV_HEXVIEW )
            lea rax,@CStr("Ascii")
        .endif
        scputs(35, _scrrow, 0, 5, rax)
        lea rax,@CStr("Unwrap")
        .if ( tvflag & _TV_WRAPLINES )
            lea rax,@CStr("Wrap  ")
        .endif
        scputs(13, _scrrow, 0, 6, rax)
        lea rax,@CStr("Dec")
        .if ( tvflag & _TV_HEXOFFSET )
            lea rax,@CStr("Hex  ")
        .endif
        scputs(54, _scrrow, 0, 3, rax)
    .endif
    ret

update_dialog endp

mouse_scroll proc

   .new n:UINT

    xor ecx,ecx
    .repeat

        .break .if edx < 8

        .if edx > edi
            inc ecx
            .break
        .endif

        mov ebx,esi
        sub ebx,9
        .if eax < ebx
            add ecx,2
            .break
        .endif

        add ebx,9+10
        .if eax > ebx
            add ecx,3
            .break
        .endif

        .if edx == 12
            add ecx,2
            .if eax > esi
                inc ecx
            .endif
            .break
        .endif

        .if edx >= 11 && edx <= 13

            mov ebx,esi
            sub ebx,4
            .if eax < ebx
                add ecx,2
                .break
            .endif

            add ebx,4+5
            .if eax > 45
                add ecx,3
                .break
            .endif
        .endif

        .break .if edx < 12
        .ifnz
            inc ecx
            .break
        .endif
        ret
    .until 1

    inc ecx
    mov n,ecx
    mov ebx,esi
    sub ebx,3

    .if eax >= ebx
        add ebx,3+3
        .if eax >= ebx
            mov ecx,_scrcol
            dec ecx
            sub ecx,eax
            mov eax,ecx
        .else
            xor eax,eax
        .endif
    .endif

    shl eax,2
    .if edx > 12
        mov ecx,_scrrow
        sub ecx,edx
        mov edx,ecx
    .else
        .ifz
            xor edx,edx
        .endif
    .endif

    shl edx,2
    mov ecx,n
    ret

mouse_scroll endp

mouse_scroll_proc proc uses rsi rdi rbx

    mov esi,_scrcol
    mov edi,_scrrow
    inc edi
    shr esi,1
    shr edi,1
    mov ebx,mousey()
    mousex()
    mov edx,ebx
    mouse_scroll()
    ret

mouse_scroll_proc endp

tview_update proc
    xor eax,eax
    ret
tview_update endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

parse_line proc uses rsi rbx offs:ptr, curcol:UINT

   .new screen:LPSTR = rdi

    xor  esi,esi
    ldr  rax,offs
    mov  rbx,[rax]

    .while 1

        .break .ifd ogetc() == -1

        inc rbx
        .if al == 10 || al == 13

            .break .ifd ogetc() == -1

            inc rbx
            .if al != 10 && al != 13
                dec rbx
                dec STDI.index
            .endif
            xor eax,eax
           .break
        .endif

        .if al == 9

            mov eax,esi
            add eax,curcol
            add eax,8
            and eax,-8
            sub eax,esi
            sub eax,curcol
            add esi,eax
            add rdi,rax
        .else
            .if !al
                mov al,' '
            .endif
            mov [rdi],al
            inc rdi
            inc esi
        .endif

        .if esi == _scrcol

            .break .ifd ogetc() == -1

            inc rbx
            .if al == 10 || al == 13

                .break .ifd ogetc() == -1

                inc rbx
                .if al != 10 && al != 13
                    dec rbx
                    dec STDI.index
                .endif
            .endif
            xor eax,eax
           .break
        .else
            mov eax,0
           .break .ifnb
        .endif
    .endw

    mov rdi,screen
    mov rdx,offs
    mov [rdx],rbx

    .if eax == 0

        mov ebx,_scrcol
        add rdi,rbx
    .endif
    ret

parse_line endp

seek proto watcall offs:size_t {
      ifdef _WIN64
        ioseek(&STDI, rax, SEEK_SET)
      else
        xor edx,edx
        ioseek(&STDI, edx::eax, SEEK_SET)
      endif
      }

previous_line proc uses rsi rdi rbx offs:ptr, loffs:ptr, sttable:ptr, stcount:UINT,
    screen:ptr, curcol:UINT

  local tmp:size_t

    ldr rsi,offs
    ldr rdi,loffs

    mov rax,[rdi]
    mov [rsi],rax

    .if ( rax == 0 )

        .return
    .endif

    .if ( rax > FSIZE )

        mov rax,FSIZE
        mov [rdi],rax
       .return
    .endif

    mov edx,16
    .if ( tvflag & _TV_HEXVIEW )
        .if rax <= rdx
            xor eax,eax
        .else
            sub rax,rdx
        .endif
        .return
    .endif

    mov eax,stcount
    mov rbx,sttable
    mov rax,[rbx+rax*size_t]

    .if ( rax < [rsi] )

        mov rax,[rsi]
        .if ( seek(rax) == -1 )

           .return( 0 )
        .endif

        .if ( oungetc() == -1 )

           .return( 0 )
        .endif

        dec size_t ptr [rsi]
        mov ebx,0x8000

        .if ( al == 13 || al == 10 )

            .if ( oungetc() == -1 )

               .return( 0 )
            .endif
            dec size_t ptr [rsi]
        .endif

        .while 1

            .if ( oungetc() == -1 )

               .break
            .endif
            dec size_t ptr [rsi]
            dec rbx

            .break .ifz
            .break .if al == 13
            .break .if al == 10
        .endw

        mov rax,[rsi]
        inc rax
       .return
    .endif

    mov rax,[rsi]
    mov ecx,stcount
    mov rbx,sttable
    dec rcx

    .while 1

        lea rdx,[rbx+rcx*size_t]
        .break .if rax > [rdx]

        .if !rcx

            .return( rcx )
        .endif
        dec rcx
    .endw

    mov rax,[rdx]
    .if !( tvflag & _TV_WRAPLINES )

        .return
    .endif

    mov rdx,[rsi]
    .if rax > rdx

        .return( 0 )
    .endif

    sub rdx,rax
    .if rdx >= 0x8000

        add rax,rdx
        mov ecx,_scrcol
        sub rax,rcx
    .endif

    mov [rsi],rax
    mov rbx,rax
    .if ( seek(rax) == -1 )

        .return( rbx )
    .endif

    .while 1

        mov rdi,screen
        .break .if parse_line(rsi, curcol)

        mov rax,[rsi]
        mov rcx,loffs
        .break .if rax >= [rcx]
        mov rbx,rax
    .endw
    mov rax,rbx
    ret

previous_line endp

    option proc:public

putscreenb proc uses rsi rdi rbx y:int_t, row:int_t, lp:ptr

  local bz:COORD, rect:SMALL_RECT, lbuf[TIMAXSCRLINE]:CHAR_INFO

    mov rsi,lp
    mov ebx,row
    mov eax,_scrcol
    mov bz.X,ax
    mov bz.Y,1
    mov rect.Left,0
    dec eax
    mov rect.Right,ax

    .repeat
        lea rdi,lbuf
        mov ecx,_scrcol
        movzx eax,at_background[B_TextView]
        or  al,at_foreground[F_TextView]
        shl eax,16
        .repeat
            lodsb
            .if ( al == 179 )
                mov ax,0x2502
                stosd
                mov ah,0
            .else
                stosd
            .endif
        .untilcxz
        mov eax,y
        add eax,row
        sub eax,ebx
        mov rect.Top,ax
        mov rect.Bottom,ax
        .break .if !WriteConsoleOutputW(_confh, &lbuf, bz, 0, &rect)
        dec ebx
    .untilz
    ret

putscreenb endp

continuesearch proc uses rsi lpOffset:ptr

  local buffer[256]:CHAR_INFO

    lea rsi,buffer
    xor eax,eax
    .if al != searchstring
        wcpushst(rsi, "Search for the string:")
        mov edx,_scrcol
        sub edx,24
        scputs(24, _scrrow, 0, edx, &searchstring)
        mov rax,lpOffset
        mov eax,[rax]
ifdef _WIN64
        ioseek(&STDI, rax, SEEK_SET)
else
        xor edx,edx
        ioseek(&STDI, edx::eax, SEEK_SET)
endif
        .if eax

            .if osearch()

                mov rcx,lpOffset
                mov [rcx],eax
ifdef _WIN64
                mov STDI.offs,rax
else
                mov STDI.offs_l,eax
                mov STDI.offs_h,edx
endif
                mov eax,1
            .else
                notfoundmsg()
            .endif
        .else
            notfoundmsg()
        .endif
        xchg rax,rsi
        wcpopst(rax)
        mov eax,esi
    .endif
    ret

continuesearch endp


tview proc uses rsi rdi rbx filename:LPSTR, offs:size_t

  local \
    loffs       :size_t,
    dlgobj      :DOBJ,
    dialog      :PDOBJ,     ; main dialog pointer
    rowcnt      :UINT,      ; max lines
    lcount      :UINT,      ; lines on screen
    scount      :UINT,      ; bytes on screen
    maxcol      :UINT,      ; max linesize on screen
    curcol      :UINT,      ; current line offset (col)
    screen      :LPSTR,     ; screen buffer
    menusline   :PDOBJ,
    statusline  :PDOBJ,
    savedupdate :DPROC,
    cursor      :CURSOR,    ; cursor (old)
    cnt         :UINT,
    bsize       :UINT,      ; buffer size
    stcount     :UINT,      ; line count
    x           :UINT,
    y           :UINT,
    state       :UINT,
    ltable[MAXLINES]:size_t,; line offset in file
    stable[MAXLINES]:size_t ; offset of first <MAXLINES> lines

    mov STDI.flag,0
    mov esi,STDI.flag
    lea rdi,stable
    xor eax,eax
    mov ecx,MAXLINES*2+13
    rep stosd
    mov curcol,eax
    mov loffs,offs

    mov eax,_scrrow
    inc al
    mov rsrows,al
    .if tvflag & _TV_USEMLINE
        dec al
    .endif
    .if tvflag & _TV_USESLINE
        dec al
    .endif
    mov rowcnt,eax ; adapt to current screen size
    add eax,2
    mul _scrcol
    .if !malloc(eax)
        .return( 1 )
    .endif
    mov screen,rax

    .ifsd ( ioopen(&STDI, filename, M_RDONLY, OO_MEMBUF) <= 0 )

        free(screen)
       .return( 0 )
    .endif

ifndef _WIN64
    xor eax,eax
    .if eax != STDI.fsize_h

        mov STDI.fsize_h,eax
        sub eax,2
        mov STDI.fsize_l,eax
    .endif
endif

    .if !( STDI.flag & IO_MEMBUF )

        mov STDI.cnt,0x8000
        mov STDI.size,0x8000
    .endif


    mov al,at_background[B_TextView]
    or  al,at_foreground[F_TextView]
    .if ( dlscreen(&dlgobj, eax) == NULL )

        free(screen)
        ioclose(&STDI)
       .return( 1 )
    .endif

    mov dialog,rax
    dlshow(rax)

    mov menusline,rsopen(IDD_TVMenusline)
    mov statusline,rsopen(IDD_TVStatusline)
    mov eax,_scrcol
    mov edx,_scrrow
    mov rcx,menusline
    mov rbx,statusline
    mov [rcx].DOBJ.rc.col,al
    mov [rbx].DOBJ.rc.col,al
    mov [rbx].DOBJ.rc.y,dl
    dlshow(rcx)
    .if ( tvflag & _TV_USESLINE )
        dlshow(rbx)
    .endif

    scpathu(1, 0, 41, filename)
    mov ecx,_scrcol
    sub ecx,38
    mov edx,dword ptr STDI.fsize
    scputf(ecx, 0, 0, 0, "%12u byte", edx)
    mov ecx,_scrcol
    sub ecx,5
    mov x,ecx
    scputs(ecx, 0, 0, 0, "100%")
    sub x,14
    scputs(x, 0, 0, 0, "col")

    .if !( tvflag & _TV_USEMLINE )

        dlhide(menusline)
    .endif

    _getcursor(&cursor)
    _gotoxy(0, 1)
    _cursoroff()

    mov savedupdate,tupdate
    mov tupdate,&tview_update
    update_dialog()
    msloop()

    mov rbx,offs
    ;
    ; offset of first <MAXLINES> lines
    ;
    lea rdi,stable
    xor eax,eax
    xor esi,esi
    mov [rdi],rax
    add rdi,size_t
    mov offs,rax
    mov stcount,1

    .ifd ( seek(rax) != -1 )

        .repeat

            .if ( ogetc() == -1 )

                mov rax,offs
                mov [rdi],rax
                mov [rdi+size_t],rax
                inc stcount
               .break
            .endif
            inc offs
            inc esi
            .if esi == MAXLINE
                xor esi,esi
                mov eax,10
            .endif
            .if eax == 10
                mov rax,offs
                mov [rdi],rax
                add rdi,size_t
                inc stcount
            .endif
        .until stcount > MAXLINES-3
        dec stcount
    .endif

    mov state,1
    .while 1

        .if state == 2

            update_dialog()
        .endif

        .if state

            mov scount,0

            mov esi,1
            mov rax,loffs
            lea rdi,ltable
            mov [rdi],rax
            mov rbx,rax
            mov offs,rax

            .repeat

                mov ecx,tvflag
                .if ecx & _TV_HEXVIEW

                    .if seek(rax) == -1

                        inc eax
                       .break
                    .endif

                    xor ecx,ecx
                    .repeat

                        add rbx,16
                        .if rbx > FSIZE

                            mov rbx,FSIZE
                           .break
                        .endif
                        mov [rdi+rsi*size_t],rbx
                        inc esi
                        inc ecx
                    .until ecx >= rowcnt

                .else

                    .if ecx & _TV_WRAPLINES

                        mov eax,esi
                       .break
                    .endif

                    lea rdx,stable
                    mov ecx,stcount
                    .repeat
                        .break .if rax == [rdx]
                        add rdx,size_t
                    .untilcxz

                    .if ecx

                        .repeat

                            add rdx,size_t
                            mov rbx,[rdx]
                            mov [rdi+rsi*size_t],rbx
                            inc esi

                            .if ( esi > rowcnt )

                                dec rsi
                                mov rax,rsi
                               .break( 1 )
                            .endif
                        .untilcxz

                        .if ( rbx == FSIZE )

                            dec rsi
                            mov rax,rsi
                           .break
                        .endif
                    .endif
                    .if ( seek(rbx) == -1 )

                        xor eax,eax
                       .break
                    .endif

                    mov x,0
                    .while 1

                        .if ( ogetc() == -1 )

                           .break
                        .endif
                        inc rbx
                        inc x
                        .if x == MAXLINE
                            mov x,0
                            mov eax,10
                        .endif

                        .if ( eax == 10 )

                            mov [rdi+rsi*size_t],rbx
                            .if esi >= rowcnt

                                mov eax,esi
                               .break( 1 )
                            .endif
                            inc esi
                        .endif
                    .endw
                .endif
                mov [rdi+rsi*size_t],rbx
                mov [rdi+rsi*size_t+size_t],rbx
                mov eax,esi
            .until 1

            mov lcount,esi
            mov offs,rbx

            .if eax

                mov eax,_scrcol
                mul rowcnt
                mov ecx,eax
                mov rdi,screen
                mov eax,' '
                rep stosb
                mov offs,loffs
                .if ( seek(rax) == -1 )

                    xor eax,eax
                .endif
            .endif
            mov eax,1
            .ifz
                xor eax,eax
            .endif

            .if tvflag & _TV_HEXVIEW

                .repeat

                    .break .if !eax
                    .break .if ogetc() == -1

                    dec STDI.index
                    mov cnt,STDI.cnt
                    mov eax,rowcnt
                    shl eax,4
                    .if eax <= STDI.cnt
                        mov STDI.cnt,eax
                    .endif
                    xor ecx,ecx
                    mov scount,STDI.cnt
                    mov rsi,screen

                    .repeat

                        mov x,ecx
                        lea rbx,ltable
                        mov rbx,[rbx+rcx*size_t]
                        lea rdx,@CStr("%010u  ")
                        .if ( tvflag & _TV_HEXOFFSET )
                            lea rdx,@CStr("%010X  ")
                        .endif
                        sprintf(rsi, rdx, rbx)

                        lea rdi,[rsi+12]
                        mov edx,STDI.cnt
                        mov eax,16
                        .if edx >= eax
                            mov edx,eax
                        .endif
                        .break .if !edx

                        sub STDI.cnt,edx
                        mov rbx,rdi
                        add rbx,51

                        mov ecx,edx
                        xor edx,edx
                        .repeat
                            .if edx == 8
                                mov al,179
                                stosb
                                inc rdi
                            .endif
                            mov eax,STDI.index
                            .break .if rax >= FSIZE
                            add rax,STDI.base
                            mov al,[rax]
                            inc STDI.index
                            mov [rbx],al
                            .if !al
                                mov byte ptr [rbx],' '
                            .endif
                            mov ah,al
                            and eax,0x0FF0
                            shr al,4
                            or  eax,0x3030
                            .if ah > 0x39
                                add ah,7
                            .endif
                            .if al > 0x39
                                add al,7
                            .endif
                            stosw
                            inc rdi
                            inc rbx
                            inc edx
                        .untilcxz
                        mov ecx,_scrcol
                        add rsi,rcx
                        mov ecx,x
                        inc ecx
                    .until ecx >= lcount
                    mov STDI.cnt,cnt
                    mov eax,1
                .until 1

            .elseif tvflag & _TV_WRAPLINES

                .repeat

                    .break .if !rax

                    xor eax,eax
                    mov rdi,screen
                    mov bsize,eax
                    mov lcount,eax

                    .repeat

                        mov eax,bsize
                        inc bsize
                        .break .if eax >= rowcnt


                        mov eax,lcount
                        inc lcount
                        lea rdx,ltable
                        lea rdx,[rdx+rax*size_t]
                        mov rax,offs
                        mov [rdx],rax

                    .until parse_line(&offs, curcol)

                    mov rax,offs
                    sub rax,loffs
                    mov scount,eax
                    or  eax,1
                .until 1

            .else

                .repeat

                    .break .if !rax

                    mov edx,maxcol
                    mov eax,lcount
                    lea rdi,ltable

                    .while eax

                        mov rcx,[rdi+rax*size_t]
                        dec eax
                        sub rcx,[rdi+rax*size_t]
                        .if rcx > rdx
                            mov rdx,rcx
                        .endif
                    .endw

                    mov maxcol,edx
                    mov rdi,screen
                    mov bsize,0

                    .while 1

                        mov eax,bsize
                        inc bsize
                        .break .if eax >= lcount

                        lea rdx,ltable
                        lea rdx,[rdx+rax*size_t]
                        mov rax,[rdx+size_t]
                        sub rax,[rdx]
                        add scount,eax

                        .if eax <= curcol

                            mov eax,_scrcol
                            add rdi,rax
                        .else
                            mov eax,curcol
                            add rax,[rdx]
                           .break( 1 ) .if seek(rax) == -1
                           .break .if parse_line(&offs, curcol)
                        .endif
                    .endw
                    or eax,1
                .until 1
            .endif

            .if eax

                .if tvflag & _TV_USEMLINE

                    mov eax,scount
                    add rax,loffs
                    .ifz
                        mov eax,100
                    .else
                        mov ecx,100
                        mul rcx
                        mov rcx,FSIZE
                        div rcx
                        and eax,007Fh
                        .if eax > 100
                            mov eax,100
                        .endif
                    .endif
                    mov ecx,_scrcol
                    sub ecx,5
                    mov x,ecx
                    scputf(ecx, 0, 0, 0, "%3d", eax)
                    sub x,10
                    scputf(x, 0, 0, 0, "%-8d", curcol)
                .endif
                mov rax,FSIZE
                .if rax
                    xor eax,eax
                    .if tvflag & _TV_USEMLINE
                        inc eax
                    .endif
                    putscreenb(eax, rowcnt, screen)
                .endif
            .endif
            mov state,0
        .endif

         tgetevent()
        .switch eax
        .case MOUSECMD
            .if mousep() == 2
                cmmcopy()
               .endc
            .endif
            .endc .if !eax
            mousey()
            inc eax
            .if ( !( tvflag & _TV_USESLINE ) || al != rsrows )
                mouse_scroll_proc()
                xor eax,eax
                .switch pascal ecx
                .case 1
                    mov eax,KEY_UP
                .case 2
                    mov eax,KEY_DOWN
                .case 3
                    mov edx,eax
                    mov eax,KEY_LEFT
                .case 4
                    mov edx,eax
                    mov eax,KEY_RIGHT
                .endsw
                .if eax
                    mov x,edx
                    PushEvent(eax)
                    Sleep(x)
                .endif
                .endc
            .endif
            msloop()
            mousex()
            .if al < 9
                .gotosw(KEY_F1)
            .endif
            .endc .ifz
            .if al < 20
                .gotosw(KEY_F2)
            .endif
            .endc .ifz
            .if al < 31
                .gotosw(KEY_F3)
            .endif
            .endc .ifz
            .if al < 41
                .gotosw(KEY_F4)
            .endif
            .endc .ifz
            .if al < 50
                .gotosw(KEY_F5)
                .endc
            .endif
            .endc .ifz
            .if al < 58
                .gotosw(KEY_F6)
            .endif
            .endc .ifz
            .if al < 66
                .gotosw(KEY_F7)
            .endif
            .endc .if al <= 70
            .if al < 80
                .gotosw(KEY_F10)
            .endif
            msloop()
           .endc
        .case KEY_F1
            rsmodal(IDD_TVHelp)
           .endc
        .case KEY_F2
            .endc .if FSIZE == 0
            .if !( tvflag & _TV_HEXVIEW )
                xor tvflag,_TV_WRAPLINES
                mov state,2
            .endif
            .endc
        .case KEY_F3
            and STDI.flag,not IO_SEARCHMASK
            mov eax,fsflag
            and eax,IO_SEARCHMASK
            or  STDI.flag,eax
            xor eax,eax
            .if FSIZE >= 16
                .if cmsearchidd(STDI.flag)
                    mov STDI.flag,edx
                    and edx,IO_SEARCHCUR or IO_SEARCHSET
                    mov x,edx
                    continuesearch(&loffs)
                    mov edx,x
                    or  STDI.flag,edx
                .endif
            .endif
            and fsflag,not IO_SEARCHMASK
            mov ecx,STDI.flag
            and STDI.flag,not (IO_SEARCHSET or IO_SEARCHCUR)
            and ecx,IO_SEARCHMASK
            or  fsflag,ecx
            .if eax
                mov state,1
            .endif
            .endc
        .case KEY_F4
            .endc .if FSIZE == 0
            mov eax,tvflag
            mov edx,eax
            and eax,not _TV_HEXVIEW
            .if !( edx & _TV_HEXVIEW )
                or eax,_TV_HEXVIEW
            .endif
            mov tvflag,eax
            .if !( al & _TV_HEXVIEW )
                mov eax,curcol
                .if rax <= loffs
                    sub loffs,rax
                .endif
            .else
                mov eax,curcol
                add loffs,rax
                xor eax,eax
                mov curcol,eax
            .endif
            mov state,2
           .endc
        .case KEY_F5
            mov curcol,CopySection(loffs, curcol)
           .endc
        .case KEY_F6
           .endc .if FSIZE == 0
            xor tvflag,_TV_HEXOFFSET
            mov state,2
           .endc
        .case KEY_F7
            .if rsopen(IDD_TVSeek)
                mov rbx,rax
                mov edx,curcol
                add rdx,loffs
                mov curcol,0
                lea rax,@CStr("%08Xh")
                .if !( tvflag & _TV_HEXOFFSET )
                    lea rax,@CStr("%u")
                .endif
                sprintf([rbx].TOBJ.data[TOBJ], rax, rdx)
                dlinit(rbx)
                mov x,rsevent(IDD_TVSeek, rbx)
                mov y,strtolx([rbx].TOBJ.data[TOBJ])
                dlclose(rbx)
                mov eax,y
                .if ( x && rax <= FSIZE )
                    mov loffs,rax
                    mov state,1
                .endif
            .endif
            .endc
        .case KEY_F10
        .case KEY_ESC
        .case KEY_ALTX
            .break
        .case KEY_ALTF5
        .case KEY_CTRLB
            dlhide(dialog)
            .while !getkey()
            .endw
            dlshow(dialog)
           .endc
        .case KEY_CTRLM
            xor tvflag,_TV_USEMLINE
            .if tvflag & _TV_USEMLINE
                dlshow(menusline)
                dec rowcnt
            .else
                dlhide(menusline)
                inc rowcnt
            .endif
            mov state,1
           .endc
        .case KEY_CTRLS
            xor tvflag,_TV_USESLINE
            .if tvflag & _TV_USESLINE
                dlshow(statusline)
                dec rowcnt
            .else
                dlhide(statusline)
                inc rowcnt
            .endif
            mov state,2
           .endc
        .case KEY_F11
            .if !( tvflag & _TV_USESLINE or _TV_USEMLINE )
                PushEvent(KEY_CTRLS)
               .gotosw(KEY_CTRLM)
            .endif
            .if tvflag & _TV_USEMLINE
                PushEvent(KEY_CTRLM)
            .endif
            .if tvflag & _TV_USESLINE
                .gotosw(KEY_CTRLS)
            .endif
            .endc

            ;--

        .case KEY_CTRLE
        .case KEY_UP
            previous_line(&offs, &loffs, &stable, stcount, screen, curcol)
            .if rax != loffs
                mov loffs,rax
                mov state,1
            .endif
            .endc
        .case KEY_CTRLX
        .case KEY_DOWN
            .if tvflag & _TV_HEXVIEW
                mov eax,scount
                add rax,loffs
                inc rax
                .endc .if rax >= FSIZE
                add rax,15
                .if rax >= FSIZE
                    .gotosw(KEY_END)
                .endif
                add loffs,16
            .else
                mov eax,lcount
                .endc .if eax < rowcnt
                mov rax,ltable[size_t]
                mov loffs,rax
            .endif
            mov state,1
           .endc
        .case KEY_CTRLR
        .case KEY_PGUP
            mov ecx,tvflag
            mov rax,loffs
            .endc .if !rax
            .if ecx & _TV_HEXVIEW
                mov eax,rowcnt
                shl eax,4
                .if rax < loffs
                    sub loffs,rax
                .else
                    xor eax,eax
                    mov loffs,rax
                .endif
                mov state,1
            .else
                .if !( tvflag & _TV_WRAPLINES ) || rax != FSIZE

                    mov edi,1
                    .repeat

                        previous_line(&offs, &loffs, &stable, stcount, screen, curcol)
                        .break .if rax == loffs
                        mov loffs,rax
                        inc edi
                    .until edi == rowcnt
                .else
                    mov edi,rowcnt
                    dec edi
                    .repeat
                        previous_line(&offs, &loffs, &stable, stcount, screen, curcol)
                        mov loffs,rax
                        dec edi
                    .untilz
                .endif
                mov state,1
            .endif
            .endc
        .case KEY_CTRLC
        .case KEY_PGDN
            mov eax,scount
            add rax,loffs
            inc rax
            .if rax < FSIZE

                .if ( tvflag & _TV_HEXVIEW )

                    mov rbx,rax
                    mov eax,rowcnt
                    shl eax,4
                    add rbx,rax
                    .if rbx >= FSIZE
                       .gotosw(KEY_END)
                    .endif
                    add loffs,rax
                    mov state,1
                   .endc
                .endif
                mov eax,lcount
                .if ( eax == rowcnt )

                    dec eax
                    lea rbx,ltable
                    mov rax,[rbx+rax*size_t]
                    .if rax >= FSIZE
                        .gotosw(KEY_END)
                    .endif
                    mov loffs,rax
                    mov state,1
                .endif
            .endif
            .endc
        .case KEY_LEFT
            .if !( tvflag & _TV_HEXVIEW or _TV_WRAPLINES )
                mov eax,curcol
                .if eax
                    dec curcol
                    mov state,1
                .endif
            .endif
            .endc
        .case KEY_RIGHT
            .if !(tvflag & _TV_HEXVIEW or _TV_WRAPLINES)
                mov eax,curcol
                .if eax < maxcol
                    inc curcol
                    mov state,1
                .endif
            .endif
            .endc
        .case KEY_HOME
            xor eax,eax
            mov loffs,rax
            mov curcol,eax
            mov state,1
           .endc
        .case KEY_END
            mov rcx,FSIZE
            mov edx,rowcnt
            .if ( tvflag & _TV_HEXVIEW )
                mov eax,edx
                shl eax,4
                inc eax
                .if rax < rcx
                    sub rax,rcx
                    not rax
                    add rax,18
                    and rax,-16
                    mov loffs,rax
                    mov state,1
                .endif
                .endc
            .endif
            mov eax,lcount
            .if eax >= edx
                mov eax,scount
                add rax,loffs
                inc rax
                .if rax < rcx
                    mov loffs,rcx
                    .if ( !( tvflag & _TV_WRAPLINES ) || rax != FSIZE )
                        mov edi,1
                        .repeat
                            previous_line(&offs, &loffs, &stable, stcount, screen, curcol)
                            .break .if rax == loffs
                            mov loffs,rax
                            inc edi
                        .until edi == rowcnt
                    .else
                        mov edi,rowcnt
                        dec edi
                        .repeat
                            previous_line(&loffs, &loffs, &stable, stcount, screen, curcol)
                            mov loffs,rax
                            dec edi
                        .untilz
                    .endif
                .endif
            .endif
            mov state,1
           .endc
        .case KEY_MOUSEUP
            PushEvent(KEY_UP)
            PushEvent(KEY_UP)
            PushEvent(KEY_UP)
           .endc
        .case KEY_MOUSEDN
            PushEvent(KEY_DOWN)
            PushEvent(KEY_DOWN)
            PushEvent(KEY_DOWN)
           .endc
        .case KEY_CTRLLEFT
            .endc .if tvflag & _TV_HEXVIEW or _TV_WRAPLINES
             xor eax,eax
             or  eax,curcol
             .endc .ifz
             .if eax >= _scrcol
                sub eax,_scrcol
             .else
                xor eax,eax
             .endif
             mov curcol,eax
             mov state,1
            .endc
        .case KEY_CTRLRIGHT
            .endc .if tvflag & _TV_HEXVIEW or _TV_WRAPLINES
            mov edx,maxcol
            mov eax,curcol
            .endc .if eax >= edx
            add eax,_scrcol
            .if eax > edx
                mov eax,edx
            .endif
            mov curcol,eax
            mov state,1
           .endc
        .case KEY_SHIFTF3
        .case KEY_CTRLL
            .if continuesearch(&loffs)
                .gotosw(KEY_CTRLHOME)
            .endif
            .endc
        .case KEY_CTRLEND
           .endc .if tvflag & _TV_HEXVIEW or _TV_WRAPLINES
            mov eax,maxcol
           .endc .if eax < _scrcol
            sub eax,20
            mov curcol,eax
            mov state,1
           .endc
        .case KEY_CTRLHOME
            xor eax,eax
            mov curcol,eax
            mov state,1
           .endc
        .endsw
    .endw

    ioclose(&STDI)
    free(screen)
    dlclose(statusline)
    dlclose(menusline)
    dlclose(dialog)
    _setcursor(&cursor)
    mov tupdate,savedupdate
    xor eax,eax
    mov STDI.flag,eax
    ret

tview endp

    end
