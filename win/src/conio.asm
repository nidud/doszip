; CONIO.ASM--
;
; Copyright (c) The Doszip Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include conio.inc
include stdio.inc
include stdlib.inc
include malloc.inc
include dzstr.inc
include time.inc
include errno.inc
include syserr.inc
include ltype.inc
include process.inc
include doszip.inc
include winuser.inc
include winnls.inc

public time_id

.template BoxChars
    Vertical    dw ?
    Horizontal  dw ?
    TopLeft     dw ?
    TopRight    dw ?
    BottomLeft  dw ?
    BottomRight dw ?
   .ends

    .data
     tdialog        PDOBJ NULL
     tdllist        PLOBJ NULL
     thelp          DPROC NULL
     tgetevent      DPROC getevent
     tdidle         DPROC tdummy
     tupdate        DPROC tdummy
     clipboard      LPSTR NULL
     TI             PTEDIT NULL
     _scrrow        UINT 24   ; Screen rows - 1
     _scrcol        UINT 80   ; Screen columns
     _scrmin        COORD <80,25>
     _scrmax        COORD <80,25>
     _scrrc         RECT <0,0,0,0>
     _consolecp     UINT 0
     _shift         UINT 0
     _focus         UINT 1
     keyshift       LPDWORD _shift
     keybstack      UINT MAXKEYSTACK dup(0)
     keybcount      UINT 0
     keybmouse_x    UINT 0
     keybmouse_y    UINT 0
     clipbsize      UINT 0
     OldConsoleMode UINT 0
     console_dl     DOBJ <>
     console_cu     CURSOR <>
     result         UINT 0
     time_id        UINT 61
     keybchar       BYTE 0
     keybcode       BYTE 0
     keybstate      BYTE 0
     wcvisible      BYTE 0
     ;
     ; These are characters used as valid identifiers
     ;
     idchars db '0123456789_?@abcdefghijklmnopqrstuvwxyz',0

     scancode byte \
        02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh, ; 1..0
        3Bh,3Ch,3Dh,3Eh,3Fh,40h,41h,42h,43h,44h, ; F1..F10
        47h,  ; HOME
        48h,  ; UP
        49h,  ; PGUP
        4Bh,  ; LEFT
        4Dh,  ; RIGHT
        4Fh,  ; END
        50h,  ; DOWN
        51h,  ; PGDN
        52h,  ; INS
        53h,  ; DEL
        0Fh,  ; Ctrl-Tab 0F00 --> 9400
        85h,  ; F11
        86h,  ; F12
        0
     scanshift byte \
        02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,
        54h,55h,56h,57h,58h,59h,5Ah,5Bh,5Ch,5Dh,
        47h,48h,49h,4Bh,4Dh,4Fh,50h,51h,52h,53h,
        0Fh,9Eh,9Fh
     scanctrl byte \
        02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,
        5Eh,5Fh,60h,61h,62h,63h,64h,65h,66h,67h,
        77h,8Dh,84h,73h,74h,75h,91h,76h,92h,93h,
        94h,0A8h,0A9h
     scanalt byte \
        78h,79h,7Ah,7Bh,7Ch,7Dh,7Eh,7Fh,80h,81h,
        68h,69h,6Ah,6Bh,6Ch,6Dh,6Eh,6Fh,70h,71h,
        47h,98h,49h,9Bh,9Dh,4Fh,0A0h,51h,52h,53h,
        0Fh,0B2h,0B3h
     _scancodes byte \  ;  A - Z
        1Eh,30h,2Eh,20h,12h,21h,22h,23h,17h,24h,25h,26h,32h,
        31h,18h,19h,10h,13h,1Fh,14h,16h,2Fh,11h,2Dh,15h,2Ch

     _scbuffersize db 2

    .code

tdummy proc private
    xor eax,eax
    ret
tdummy endp

_wherex proc private

  local ci:CONSOLE_SCREEN_BUFFER_INFO

    .ifd GetConsoleScreenBufferInfo(_confh, addr ci)

        movzx eax,ci.dwCursorPosition.X
        movzx edx,ci.dwCursorPosition.Y
    .endif
    ret

_wherex endp

_gotoxy proc x:int_t, y:int_t

    mov eax,y
    shl eax,16
    mov ax,word ptr x
    SetConsoleCursorPosition(_confh, eax)
    ret

_gotoxy endp

_cursoron proc

  local cu:CONSOLE_CURSOR_INFO

    mov cu.dwSize,CURSOR_NORMAL
    mov cu.bVisible,1
    SetConsoleCursorInfo(_confh, &cu)
    ret

_cursoron endp

_cursoroff proc uses rax

  local cu:CONSOLE_CURSOR_INFO

    mov cu.dwSize,CURSOR_NORMAL
    mov cu.bVisible,0
    SetConsoleCursorInfo(_confh, &cu)
    ret

_cursoroff endp

_getcursor proc uses rbx cursor:PCURSOR

  local ci:CONSOLE_SCREEN_BUFFER_INFO

    mov rbx,cursor

    .ifd GetConsoleScreenBufferInfo(_confh, &ci)

        mov eax,ci.dwCursorPosition
        mov dword ptr [rbx].CURSOR.x,eax
    .endif

    GetConsoleCursorInfo(_confh, rbx)
    mov eax,[rbx].CURSOR.bVisible
    ret

_getcursor endp

_setcursor proc uses rax Cursor:PCURSOR

    mov rax,Cursor
    mov eax,dword ptr [rax].CURSOR.x

    SetConsoleCursorPosition(_confh, eax)
    SetConsoleCursorInfo(_confh, Cursor)
    ret

_setcursor endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

getxya proc private x:uint_t, y:uint_t

  local Attribute:uint_t
  local NumberOfAttributesRead:uint_t

    movzx ecx,byte ptr y
    shl   ecx,16
    mov   cl,byte ptr x   ; COORD

    .ifd ReadConsoleOutputAttribute(_confh, &Attribute, 1, ecx, &NumberOfAttributesRead)

        mov eax,Attribute
        and eax,0xFF
    .endif
    ret

getxya endp

getxyc proc x:uint_t, y:uint_t

  local Character:uint_t
  local NumberOfCharsRead:uint_t

    movzx ecx,byte ptr y
    shl   ecx,16
    mov   cl,byte ptr x

    .ifd ReadConsoleOutputCharacterW(_confh, &Character, 1, ecx, &NumberOfCharsRead)

        mov eax,Character
        and eax,0xFFFF
    .endif
    ret

getxyc endp

scputa proc x:uint_t, y:uint_t, l:uint_t, a:uint_t

  local NumberOfAttrsWritten:uint_t

    movzx ecx,byte ptr a
    movzx eax,byte ptr x
    movzx edx,byte ptr y
    shl   edx,16
    mov   dx,ax

    FillConsoleOutputAttribute(_confh, cx, l, edx, &NumberOfAttrsWritten)
    ret

scputa endp

scputfg proc uses rbx x:uint_t, y:uint_t, l:uint_t, a:uint_t

    mov ebx,a
    and bl,0x0F
    .repeat
        getxya(x, y)
        and al,0xF0
        or  al,bl
        scputa(x, y, 1, eax)
        inc x
        dec l
    .untilz
    ret

scputfg endp

scputc proc x:uint_t, y:uint_t, l:uint_t, c:uint_t

  local NumberOfCharsWritten:uint_t

    ldr eax,x
    ldr edx,y
    ldr ecx,c

    movzx eax,al
    movzx edx,dl
    shl   edx,16
    or    edx,eax

    FillConsoleOutputCharacterW(_confh, cx, l, edx, &NumberOfCharsWritten)
    ret

scputc endp

scputw proc x:uint_t, y:uint_t, l:uint_t, w:uint_t

    ldr eax,w
    .if eax & 0x00FF0000
        shr eax,16
        scputa(x, y, l, eax)
    .endif
    scputc(x, y, l, w)
    ret

scputw endp

scputs proc uses rsi rdi rbx x:uint_t, y:uint_t, a:uint_t, maxlen:uint_t, string:LPSTR

    ldr ebx,maxlen
    .if ( ebx == 0 )
        dec ebx
    .endif

    .for ( edi = x, rsi = string : ebx && byte ptr [rsi] : ebx--, edi++ )

        _utftow(rsi)
        add rsi,rcx
        .if ( eax == 10 )

            inc y
            mov edi,x
            dec edi
           .continue
        .elseif ( eax == 9 )

            add edi,4
            and edi,-4
            dec edi
           .continue
        .endif
        scputc(edi, y, 1, ax)
        .if ( byte ptr a )

            scputa(edi, y, 1, a)
        .endif
    .endf
    sub rsi,string
    mov eax,esi
    ret

scputs endp

scputf proc __Cdecl x:int_t, y:int_t, a:int_t, l:int_t, format:LPSTR, argptr:vararg

    vsprintf( &_bufin, format, &argptr )
    scputs(x, y, a, l, &_bufin)
    ret

scputf endp

scgetws proc uses rbx x:uint_t, y:uint_t, l:uint_t

  local rc:SMALL_RECT
  local b:ptr

    movzx eax,byte ptr x
    movzx edx,byte ptr y
    mov   rc.Left,ax
    mov   rc.Top,dx
    mov   ebx,l

    .ifs ebx < 0
        not ebx
        mov l,ebx
        add edx,ebx
        dec edx
        shl ebx,16
        mov bx,1
    .else
        add eax,ebx
        add ebx,10000h
    .endif

    mov rc.Right,ax
    mov rc.Bottom,dx
    mov eax,l
    shl eax,2

    .if malloc(eax)

        mov b,rax
        ReadConsoleOutputW(_confh, b, ebx, 0, &rc)
        mov rax,b
    .endif
    ret

scgetws endp

scputws proc x:uint_t, y:uint_t, l:uint_t, wp:ptr

  local rc:SMALL_RECT

    movzx eax,byte ptr x
    movzx edx,byte ptr y
    mov rc.Top,dx
    mov rc.Left,ax
    mov ecx,l
    .ifs ecx < 0
        not ecx
        mov l,ecx
        add edx,ecx
        dec edx
        shl ecx,16
        mov cx,1
    .else
        add eax,ecx
        add ecx,10000h
    .endif
    mov rc.Right,ax
    mov rc.Bottom,dx
    WriteConsoleOutputW(_confh, wp, ecx, 0, &rc)
    free(wp)
    ret

scputws endp

scenter proc uses rsi x:uint_t, y:uint_t, l:uint_t, s:LPSTR

    ldr rsi,s
    .ifd strlen(rsi) > l
        add rsi,rax
        mov eax,l
        sub rsi,rax
    .else
        mov ecx,eax
        mov eax,l
        sub eax,ecx
        shr eax,1
        add x,eax
        sub l,eax
    .endif
    scputs(x, y, 0, l, rsi)
    ret

scenter endp


scpath proc uses rsi rbx x:int_t, y:int_t, maxlen:int_t, string:LPSTR

   .new b[8]:byte
   .new count:int_t = 0

    ldr esi,maxlen
    ldr rbx,string

    .ifd ( _utfslen(rbx) > esi )

        mov ecx,[rbx]
        lea rdx,b
        add eax,4
        mov count,4

        .if ( ch == ':' )

            mov [rdx],cx
            add rdx,2
            add eax,2
            add count,2
        .endif
        mov ecx,'\..\'
        mov [rdx],ecx
        sub eax,esi
        .for ( rdx = &_lookuptrailbytes : eax : eax-- )

            movzx ecx,byte ptr [rbx]
            movzx ecx,byte ptr [rdx+rcx]
            lea rbx,[rbx+rcx+1]
        .endf
        scputs( x, y, 0, count, &b )
        add x,count
        sub esi,eax
    .endif
    scputs( x, y, 0, esi, rbx )
    add eax,count
    ret

scpath endp


scpathl proc uses rsi rdi rbx x:uint_t, y:uint_t, maxlen:uint_t, string:LPSTR

   .new pcx:int_t = 0
   .new len:int_t
   .new lbuf[TIMAXSCRLINE]:wchar_t

    ldr     rbx,string
    movzx   esi,byte ptr maxlen
    mov     eax,' '
    lea     rdi,lbuf
    mov     rdx,rdi
    mov     ecx,esi
    rep     stosw
    mov     rdi,rdx

    .ifd _utfslen(rbx) > esi

        mov ecx,[rbx]
        add eax,4

        .if ch == ':'

            mov [rdi],cl
            mov [rdi+2],ch
            add rdi,4
            add eax,2
        .endif
        mov ecx,eax
        mov ax,'.\'
        mov [rdi],al
        mov [rdi+2],ah
        mov [rdi+4],ah
        mov [rdi+6],al
        add rdi,8
        sub ecx,esi
        .for ( rdx = &_lookuptrailbytes : ecx : ecx-- )

            movzx eax,byte ptr [rbx]
            movzx eax,byte ptr [rdx+rax]
            lea rbx,[rbx+rax+1]
        .endf
    .endif

    .while ( byte ptr [rbx] )

        _utftow(rbx)
        add rbx,rcx
        stosw
    .endw

    movzx eax,byte ptr x
    movzx edx,byte ptr y
    shl   edx,16
    mov   dx,ax

    WriteConsoleOutputCharacterW(_confh, &lbuf, esi, edx, &pcx)
    mov eax,pcx
    ret

scpathl endp

scgetword proc uses rsi rdi rbx linebuf:LPSTR

   .new count:int_t
    mov edi,_wherex()       ; get cursor x,y pos
    mov ebx,edx
    inc edi                 ; to start of line..

    .repeat

        dec edi             ; moving left seeking a valid character
        .break .ifz

        getxyc(edi, ebx)
        idtestal()
        .continue .ifz

        getxyc(&[rdi-1], ebx)
        idtestal()
    .untilz

    mov rsi,linebuf
    mov count,MAXCOLS
    xor eax,eax

    .repeat

        getxyc(edi, ebx)
        inc edi
        idtestal()
        .break .ifz

        mov [rsi],al
        inc rsi
        dec count
    .untilz

    mov byte ptr [rsi],0
    mov rdx,linebuf
    xor eax,eax
    .if al != [rdx]
        mov rax,rdx
    .endif
    ret

idtestal:

    push rdi
    push rcx
    push rax
    .if al >= 'A' && al <= 'Z'
        or al,0x20
    .endif
    lea   rdi,idchars
    mov   ecx,sizeof(idchars)
    repne scasb
    cmp   byte ptr [rdi-1],0
    pop   rax
    pop   rcx
    pop   rdi
    retn

scgetword endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wcputxg proc private

    add rcx,2
    .repeat
        and [rcx],ah
        or  [rcx],al
        add rcx,4
        dec edx
    .until !edx
    ret

wcputxg endp

wcputa proc private p:PCHAR_INFO, l:uint_t, attrib:uint_t

    ldr eax,attrib
    and eax,0xFF
    ldr rcx,p
    ldr edx,l
    wcputxg()
    ret

wcputa endp

wcputbg proc private p:PCHAR_INFO, l:uint_t, attrib:uint_t

    ldr eax,attrib
    mov ah,0x0F
    and al,0xF0
    ldr rcx,p
    ldr edx,l
    wcputxg()
    ret

wcputbg endp

wcputfg proc private p:PCHAR_INFO, l:uint_t, attrib:uint_t

    ldr eax,attrib
    mov ah,0x70
    and al,0x0F
    ldr rcx,p
    ldr edx,l
    wcputxg()
    ret

wcputfg endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rcbprc proc rc:TRECT, p:PCHAR_INFO, cols:uint_t

    mov     eax,cols
    mul     rc.y
    movzx   edx,rc.x
    add     eax,edx
    shl     eax,2
    add     rax,p
    ret

rcbprc endp

rcmemsize proc private rc:TRECT, shade:uint_t

    movzx eax,rc.col
    movzx edx,rc.row
    mov   ecx,eax
    mul   dl
    shl   eax,2

    .if ( shade )

        ; ( ( col + ( row * 2 ) - 2 ) * 4 )

        lea ecx,[rcx+rdx*2-2]
        shl ecx,2
        add eax,ecx
    .endif
    ret

rcmemsize endp

rcalloc proc rc:TRECT, shade:UINT

    malloc(rcmemsize(rc, shade))
    ret

rcalloc endp

rcread proc uses rbx rsi rdi rc:TRECT, p:PCHAR_INFO

  local bz:COORD
  local sr:SMALL_RECT

    movzx   eax,rc.col
    movzx   edx,rc.row
    movzx   ecx,rc.y
    mov     bz.X,ax
    mov     bz.Y,dx
    mov     sr.Top,cx
    lea     ecx,[rcx+rdx-1]
    mov     sr.Bottom,cx
    movzx   ecx,rc.x
    mov     sr.Left,cx
    lea     eax,[rcx+rax-1]
    mov     sr.Right,ax

    .ifd !ReadConsoleOutputW(_confh, p, bz, 0, &sr)

        mov     sr.Bottom,sr.Top
        mov     rdi,p
        movzx   ebx,bz.Y
        mov     bz.Y,1
        movzx   esi,bz.X
        shl     esi,2
        .repeat
            .break .ifd !ReadConsoleOutputW(_confh, rdi, bz, 0, &sr)
            inc sr.Bottom
            inc sr.Top
            add rdi,rsi
            dec ebx
        .until !ebx
        xor eax,eax
        .if !ebx
            inc eax
        .endif
    .endif
    ret

rcread endp

rcwrite proc uses rsi rdi rbx rc:TRECT, p:PCHAR_INFO

  local bz:COORD
  local sr:SMALL_RECT

    movzx   eax,rc.col
    movzx   edx,rc.row
    movzx   ecx,rc.y
    mov     bz.X,ax
    mov     bz.Y,dx
    mov     sr.Top,cx
    lea     ecx,[rcx+rdx-1]
    mov     sr.Bottom,cx
    movzx   ecx,rc.x
    mov     sr.Left,cx
    lea     eax,[rcx+rax-1]
    mov     sr.Right,ax

    .ifd !WriteConsoleOutputW(_confh, p, bz, 0, &sr)

        mov     sr.Bottom,sr.Top
        mov     rdi,p
        movzx   ebx,bz.Y
        mov     bz.Y,1
        movzx   esi,bz.X
        shl     esi,2
        .repeat
            .break .ifd !WriteConsoleOutputW(_confh, rdi, bz, 0, &sr)
            inc sr.Bottom
            inc sr.Top
            add rdi,rsi
            dec ebx
        .until !ebx
        xor eax,eax
        .if !ebx
            inc eax
        .endif
    .endif
    ret

rcwrite endp

rcxchg proc private uses rsi rdi rbx rc:TRECT, p:PCHAR_INFO

   .new b:ptr
    movzx eax,rc.row
    mul rc.col
    mov ebx,eax
    shl eax,2
    .if malloc(eax)

        mov b,rax
        .ifd rcread(rc, rax)

            rcwrite(rc, p)
            mov rdi,p
            mov rsi,b
            mov ecx,ebx
            rep movsd
        .endif
        mov ebx,eax
        free( b )
        mov eax,ebx
    .endif
    ret

rcxchg endp

rcshade proc private uses rbx rc:TRECT, wp:PCHAR_INFO, shade:int_t

   .new b:TRECT, r:TRECT

    mov b,rc
    mov r,eax
    shr eax,16
    mov r.col,2
    dec r.row
    inc r.y
    add r.x,al
    add b.y,ah
    mov b.row,1
    add b.x,2

    movzx eax,rc.col
    mul rc.row
    lea rbx,[rax*4]
    add rbx,wp

    .if ( shade )

        rcread(b, rbx)
        movzx eax,b.col
        rcread(r, &[rbx+rax*4])

        movzx edx,b.col
        add dl,r.row
        add dl,r.row
        .for ( rax = rbx : edx : edx--, rax += 4 )

            mov byte ptr [rax+2],0x08
        .endf
    .endif
    rcxchg(b, rbx)
    movzx eax,b.col
    rcxchg(r, &[rbx+rax*4])
    ret

rcshade endp

rchide proc rc:TRECT, flag:uint_t, p:PCHAR_INFO

    ldr eax,flag
    and eax,_D_DOPEN or _D_ONSCR
    .ifnz
        .if ( eax & _D_ONSCR )
            .ifd rcxchg(rc, p)
                .if ( flag & _D_SHADE )
                    rcshade(rc, p, 0)
                .endif
                mov eax,1
            .endif
        .endif
    .endif
    ret

rchide endp

rcshow proc rc:TRECT, flag:uint_t, p:PCHAR_INFO

    ldr eax,flag
    and eax,_D_DOPEN or _D_ONSCR
    .ifnz
        .if !( eax & _D_ONSCR )
            .ifd rcxchg(rc, p)
                .if ( flag & _D_SHADE )
                    rcshade(rc, p, 1)
                .endif
                mov eax,1
            .endif
        .endif
    .endif
    ret

rcshow endp

rcopen proc rc:TRECT, flag:uint_t, attrib:uint_t, title:string_t, p:ptr

    ldr eax,flag
    .if !( eax & _D_MYBUF )

        and eax,_D_SHADE
        .if !rcalloc(rc, eax)
            .return
        .endif
        mov p,rax
    .endif
    rcread(rc, p)

    mov edx,flag
    and edx,_D_CLEAR or _D_BACKG or _D_FOREG
    .ifnz

        movzx eax,rc.row
        mul rc.col
        mov ecx,attrib

        .switch edx
          .case _D_CLEAR : wcputw (p, eax, ' ') : .endc
          .case _D_COLOR : wcputa (p, eax, ecx) : .endc
          .case _D_BACKG : wcputbg(p, eax, ecx) : .endc
          .case _D_FOREG : wcputfg(p, eax, ecx) : .endc
          .default
            shl ecx,16
            mov cl,' '
            wcputw(p, eax, ecx)
        .endsw

        mov rax,title
        .if rax

            movzx edx,rc.col
            wctitle(p, edx, rax)
        .endif
    .endif
    mov rax,p
    ret

rcopen endp


rcmoveu proc private uses rsi rdi rbx rc:TRECT, p:PCHAR_INFO, flag:uint_t

  local x:uint_t, lines:uint_t, l:uint_t, lp:ptr

    movzx eax,rc.y
    .if eax > 1

        movzx   esi,rc.row
        dec     eax
        add     esi,eax
        mov     edi,eax
        mov     al,rc.x
        mov     x,eax
        mov     al,rc.col
        mov     l,eax

        .if rcalloc(rc, 0)

            mov rbx,rax
            rcread(rc, rax)
            mov lp,scgetws(x, edi, l)
            dec rc.y
            rcwrite(rc, rbx)
            free(rbx)

            mov     ebx,l
            shl     ebx,2
            movzx   eax,rc.row
            dec     eax
            mov     lines,eax
            mul     ebx
            mov     rdi,p
            add     rdi,rax

            memxchg(lp, rdi, ebx)
            scputws(x, esi, l, rax)

            mov rsi,rdi
            sub rsi,rbx

            .while lines

                memxchg(rsi, rdi, ebx)
                sub rdi,rbx
                sub rsi,rbx
                dec lines
            .endw
        .endif
    .endif
    mov eax,rc
    ret

rcmoveu endp

rcmoved proc private uses rsi rdi rbx rc:TRECT, p:PCHAR_INFO, flag:uint_t

  local x,l,lp:ptr

    movzx eax,rc.y
    movzx edx,rc.row
    mov   esi,eax
    add   eax,edx

    .if _scrrow >= eax

        mov edi,eax
        mov al,rc.x
        mov x,eax
        mov al,rc.col
        mov l,eax

        .if rcalloc( rc, 0 )

            mov rbx,rax
            rcread(rc, rax)
            mov lp,scgetws(x, edi, l)
            inc rc.y
            rcwrite(rc, rbx)
            free(rbx)

            mov ebx,l
            shl ebx,2
            memxchg( lp, p, ebx )
            scputws( x, esi, l, rax )
            movzx esi,rc.row
            dec esi
            mov rdi,p

            .while esi

                memxchg(rdi, &[rdi+rbx], ebx)
                add rdi,rbx
                dec esi
            .endw
        .endif
    .endif
    mov eax,rc
    ret

rcmoved endp

rcmover proc private uses rsi rdi rbx rc:TRECT, p:PCHAR_INFO, flag:uint_t

  local x,y,l,b:ptr

    movzx eax,rc.x
    movzx edx,rc.col
    mov   esi,eax
    add   eax,edx

    .if _scrcol > eax

        mov edi,eax
        mov al,rc.x
        mov x,eax
        mov al,rc.y
        mov y,eax
        mov al,rc.row
        not eax
        mov l,eax

        .if rcalloc(rc, 0)

            mov rbx,rax
            rcread(rc, rax)
            mov b,scgetws(edi, y, l)
            inc rc.x
            rcwrite(rc, rbx)
            free(rbx)

            movzx ebx,rc.col
            dec   ebx
            movzx edx,rc.row
            mov   rsi,p
            mov   rdi,b

            .repeat
                mov     ecx,[rsi]
                mov     eax,[rdi]
                mov     [rdi],ecx
                push    rdi
                mov     rdi,rsi
                add     rsi,4
                mov     ecx,ebx
                rep     movsd
                pop     rdi
                mov     [rsi-4],eax
                add     rdi,4
                dec     edx
            .until !edx
            scputws(x, y, l, b)
        .endif
    .endif
    mov eax,rc
    ret

rcmover endp

rcmovel proc private uses rsi rdi rbx rc:TRECT, p:PCHAR_INFO, flag:uint_t

  local x,y,l,r,z,b:ptr

    ldr ecx,rc
    mov eax,ecx

    .if al

        movzx   eax,al
        lea     edx,[rax-1]
        mov     z,edx
        mov     x,eax
        mov     al,ch
        mov     y,eax
        mov     al,rc.row
        mov     r,eax
        not     eax
        mov     l,eax
        movzx   eax,rc.col
        mul     r
        shl     eax,2

        .if malloc(eax)

            mov rbx,rax
            rcread(rc, rax)
            mov b,scgetws(z, y, l)
            dec rc.x
            rcwrite(rc, rbx)
            free(rbx)

            movzx   ebx,rc.col
            lea     eax,[rbx-1]
            mov     z,eax
            shl     ebx,3
            mov     edx,r
            shl     eax,2
            mov     rsi,p
            add     rsi,rax
            mov     rdi,b

            std
            .repeat
                mov     ecx,[rsi]
                mov     eax,[rdi]
                mov     [rdi],ecx
                push    rdi
                mov     rdi,rsi
                sub     rsi,4
                mov     ecx,z
                rep     movsd
                pop     rdi
                mov     [rsi+4],eax
                add     rsi,rbx
                add     rdi,4
                dec     edx
            .until !edx
            cld

            movzx   eax,rc.col
            add     eax,x
            dec     eax

            scputws(eax, y, l, b)
        .endif
    .endif
    mov eax,rc
    ret

rcmovel endp

rcmsmove proc private uses rsi rdi rbx rc:PTRECT, p:PCHAR_INFO, flag:uint_t

  local xpos,ypos
  local relx,rely
  local cursor:CURSOR

    ldr rdi,rc
    mov ebx,[rdi]
    .if flag & _D_SHADE

        rcshade(ebx, p, 0)
    .endif

    mov ypos,mousey()
    mov edx,eax
    mov xpos,mousex()
    sub al,bl
    mov relx,eax
    sub dl,bh
    mov rely,edx

    _getcursor(&cursor)
    _cursoroff()

    .while mousep() == 1

        xor esi,esi
        .ifd mousex() > xpos

            mov esi,1

        .elseif CARRY?

            .if bl

                mov esi,2
            .endif
        .endif

        .if !esi

            .ifd mousey() > ypos

                mov esi,3

            .elseif CARRY?

                .if bh != 1

                    mov esi,4
                .endif
            .endif
        .endif

        mov ecx,flag
        and ecx,not _D_SHADE

        .switch pascal esi
        .case 1: rcmover(ebx, p, ecx)
        .case 2: rcmovel(ebx, p, ecx)
        .case 3: rcmoved(ebx, p, ecx)
        .case 4: rcmoveu(ebx, p, ecx)
        .endsw

        .if esi
            mov ebx,eax
            mov edx,eax
            mov eax,rely
            add al,dh
            mov ypos,eax
            mov eax,relx
            add al,dl
            mov xpos,eax
        .endif
    .endw

    _setcursor(&cursor)
    .if flag & _D_SHADE

        rcshade(ebx, p, 1)
    .endif
    mov [rdi],ebx
    ret

rcmsmove endp

rcframe proc uses rsi rdi rbx rc:TRECT, wp:PCHAR_INFO, lsize:uint_t, type:uint_t

   .new ft:BoxChars
   .new cols:byte
   .new rows:byte

    ; BOX_SINGLE

    mov ft.Vertical,    U_LIGHT_VERTICAL
    mov ft.Horizontal,  U_LIGHT_HORIZONTAL
    mov eax,type
    and eax,0xFF
    .switch pascal eax
    .case BOX_CLEAR
        lea rdi,ft
        mov ecx,sizeof(ft) / 2
        mov eax,' '
        rep stosw
    .case BOX_DOUBLE
        mov ft.Vertical,    U_DOUBLE_VERTICAL
        mov ft.Horizontal,  U_DOUBLE_HORIZONTAL
        mov ft.TopLeft,     U_DOUBLE_DOWN_AND_RIGHT
        mov ft.TopRight,    U_DOUBLE_DOWN_AND_LEFT
        mov ft.BottomLeft,  U_DOUBLE_UP_AND_RIGHT
        mov ft.BottomRight, U_DOUBLE_UP_AND_LEFT
    .case BOX_SINGLE_VERTICAL
        mov ft.TopLeft,     U_LIGHT_DOWN_AND_HORIZONTAL
        mov ft.TopRight,    U_LIGHT_DOWN_AND_HORIZONTAL
        mov ft.BottomLeft,  U_LIGHT_UP_AND_HORIZONTAL
        mov ft.BottomRight, U_LIGHT_UP_AND_HORIZONTAL
    .case BOX_SINGLE_HORIZONTAL
        mov ft.TopLeft,     U_LIGHT_VERTICAL_AND_RIGHT
        mov ft.TopRight,    U_LIGHT_VERTICAL_AND_LEFT
        mov ft.BottomLeft,  U_LIGHT_VERTICAL_AND_RIGHT
        mov ft.BottomRight, U_LIGHT_VERTICAL_AND_LEFT
    .case BOX_SINGLE_ARC
        mov ft.TopLeft,     U_LIGHT_ARC_DOWN_AND_RIGHT
        mov ft.TopRight,    U_LIGHT_ARC_DOWN_AND_LEFT
        mov ft.BottomLeft,  U_LIGHT_ARC_UP_AND_RIGHT
        mov ft.BottomRight, U_LIGHT_ARC_UP_AND_LEFT
    .default
        mov ft.TopLeft,     U_LIGHT_DOWN_AND_RIGHT
        mov ft.TopRight,    U_LIGHT_DOWN_AND_LEFT
        mov ft.BottomLeft,  U_LIGHT_UP_AND_RIGHT
        mov ft.BottomRight, U_LIGHT_UP_AND_LEFT
    .endsw

    mov     eax,lsize
    mul     rc.y
    mov     edi,eax
    movzx   eax,rc.x
    add     edi,eax
    shl     edi,2
    add     rdi,wp

    mov     al,rc.col
    sub     al,2
    mov     cols,al
    mov     al,rc.row
    sub     al,2
    mov     rows,al

    mov     eax,type
    shr     eax,8
    and     eax,0xFF
    mov     edx,lsize
    shl     edx,2
    lea     rbx,[rdi+rdx]
    shl     eax,16
    mov     ax,ft.TopLeft

    .ifnz

        stosd
        mov     ax,ft.Horizontal
        movzx   ecx,cols
        rep     stosd
        mov     ax,ft.TopRight
        stosd
        mov     ax,ft.Vertical
        movzx   ecx,cols

        .for (  : rows : rows-- )

            mov     [rbx],eax
            mov     [rbx+rcx*4+4],eax
            add     rbx,rdx
        .endf

        mov     rdi,rbx
        mov     ax,ft.BottomLeft
        stosd
        mov     ax,ft.Horizontal
        movzx   ecx,cols
        rep     stosd
        mov     ax,ft.BottomRight
        stosd

    .else

        mov     [rdi],ax
        mov     ax,ft.Horizontal
        add     rdi,4

        .for ( cl = 0 : cl < cols : cl++, rdi += 4 )

            mov [rdi],ax
        .endf

        mov     ax,ft.TopRight
        mov     [rdi],ax
        mov     ax,ft.Vertical
        movzx   ecx,cols

        .for ( : rows : rows-- )

            mov rdi,rbx
            add rbx,rdx
            mov [rdi],ax
            mov [rdi+rcx*4+4],ax
        .endf

        mov     rdi,rbx
        mov     ax,ft.BottomLeft
        mov     [rdi],ax
        add     rdi,4
        mov     ax,ft.Horizontal

        .for ( cl = 0 : cl < cols : cl++, rdi += 4 )

            mov [rdi],ax
        .endf
        mov     ax,ft.BottomRight
        mov     [rdi],ax
    .endif
    ret

rcframe endp

rcpush proc private lines:UINT

    mov eax,_scrcol
    mov ah,byte ptr lines
    shl eax,16
    rcopen(eax, 0, 0, 0, 0)
    ret

rcpush endp

rcunzip proc private uses rsi rdi rbx rc:TRECT, dst:PCHAR_INFO, src:ptr

   .new count:int_t

    movzx eax,rc.col
    mul rc.row
    mov count,eax

    mov rsi,src
    mov rdi,dst
    mov ecx,count
    decompress()
    mov rdi,dst
    inc rdi
    mov ecx,count
    decompress()
    mov rdi,dst
    add rdi,2
    mov ecx,count
    decompress()
    mov rdi,dst
    add rdi,3
    mov ecx,count
    decompress()
    ret

decompress:

    .repeat
        lodsb
        mov dl,al
        and dl,0xF0
        .if dl == 0xF0
            mov ah,al
            lodsb
            and eax,0xFFF
            mov ebx,eax
            lodsb
            .if ebx
                .repeat
                    stosb
                    add rdi,3
                    dec ebx
                   .break .ifz
                .untilcxz
            .endif
            .break .if !ecx
        .else
            stosb
            add rdi,3
        .endif
    .untilcxz
    retn

rcunzip endp

rcunzipat proc private uses rsi rdi rbx rc:TRECT, p:PCHAR_INFO

   .new count:int_t

    movzx eax,rc.col
    mul rc.row
    mov count,eax

    ldr rbx,p
    lea rdi,at_foreground
    lea rsi,at_background

    .for ( ecx = 0 : ecx < count : ecx++ )

        mov     al,[rbx+rcx*4+2]
        mov     ah,al
        and     eax,0x0FF0
        shr     al,4
        movzx   edx,al
        mov     al,[rsi+rdx]
        mov     dl,ah
        or      al,[rdi+rdx]
        mov     [rbx+rcx*4+2],al
    .endf
    ret

rcunzipat endp

ifdef __BMP__

rczip proc uses rsi rdi rbx rc:TRECT, dst:ptr, src:PCHAR_INFO

   .new count:int_t

    movzx eax,rc.col
    mul rc.row
    mov count,eax

    mov rdi,dst
    mov rsi,src
    mov ecx,count
    compress()
    mov rsi,src
    inc rsi
    mov ecx,count
    compress()
    mov rsi,src
    add rsi,2
    mov ecx,count
    compress()
    mov rsi,src
    add rsi,3
    mov ecx,count
    compress()
    mov rax,rdi
    sub rax,dst
    ret

    option dotname

compress:

    mov     al,[rsi]
    mov     dl,al
    mov     dh,al
    and     dh,0xF0
    cmp     al,[rsi+4]
    jnz     .1
    mov     ebx,0xF001
    jmp     .3
.1:
    cmp     dh,0xF0
    jnz     .7
    mov     eax,0x01F0
    jmp     .6
.2:
    inc     ebx
    bt      ebx,16
    jc      .9
    add     rsi,4
    mov     al,[rsi]
    cmp     al,[rsi+4]
    jne     .4
.3:
    dec     ecx
    jnz     .2
.4:
    mov     eax,ebx
    cmp     ebx,0xF002
    jnz     .5
    cmp     dh,0xF0
    jz      .5
    mov     al,dl
    stosb
    jmp     .7
.9:
    dec     ebx
    inc     ecx
    jmp     .4
.5:
    xchg    ah,al
.6:
    stosw
    mov     al,dl
.7:
    stosb
    test    ecx,ecx
    jz      .8
    add     rsi,4
    dec     ecx
    jnz     compress
.8:
    retn

rczip endp

endif


__wcpath proc private uses rbx b:PCHAR_INFO, l:dword, p:LPSTR

    mov ecx,strlen( p )
    mov rdx,p
    mov rax,b

    .repeat

        .break .if ecx <= l

        mov ebx,[rdx]
        add rdx,rcx
        mov ecx,l
        sub rdx,rcx
        add rdx,4
        .if bh == ':'
            mov [rax],bl
            mov [rax+4],bh
            shr ebx,8
            mov bl,'.'
            add rax,8
            add rdx,2
            sub ecx,2
        .else
            mov bx,'/.'
        .endif
        mov [rax],bh
        mov [rax+4],bl
        mov [rax+8],bl
        mov [rax+12],bh
        add rax,16
        sub ecx,4
    .until 1
    ret

__wcpath endp

wcpath proc uses rbx b:PCHAR_INFO, l:uint_t, p:LPSTR

    __wcpath(b, l, p)

    .if ecx

        mov rbx,rax
        xor eax,eax
        .repeat
            mov al,[rdx]
            mov [rbx],ax
            add rbx,4
            add rdx,1
        .untilcxz
    .endif
    ret

wcpath endp

wcenter proc uses rbx wp:PCHAR_INFO, l:uint_t, string:LPSTR

    ldr rbx,wp
    __wcpath(rbx, l, string)

    .if ecx

        .if rbx == rax

            mov eax,l
            sub eax,ecx
            shr eax,1
            lea rax,[rbx+rax*4]
        .endif
        mov rbx,rax
        xor eax,eax
        .repeat
            mov al,[rdx]
            mov [rbx],ax
            add rbx,4
            add rdx,1
        .untilcxz
    .endif
    ret

wcenter endp

wcpbutt proc uses rsi rdi rbx wp:PCHAR_INFO, l:uint_t, x:uint_t, string:LPSTR

    ldr rdi,wp
    ldr ecx,x

    xor eax,eax
    mov al,at_background[B_PushButt]
    or  al,at_foreground[F_Title]
    shl eax,16
    mov al,' '
    mov rbx,rdi
    mov rdx,rdi
    rep stosd

    mov eax,[rdi+2]
    and eax,11110000B
    or  al,at_foreground[F_PBShade]
    shl eax,16
    mov ax,U_LOWER_HALF_BLOCK
    stosd

    mov ecx,l
    inc ecx
    shl ecx,2
    lea rdi,[rdx+rcx]
    mov ecx,x
    mov ax,U_UPPER_HALF_BLOCK
    rep stosd

    mov rsi,string
    mov rdi,rbx
    add rdi,8
    xor eax,eax
    mov al,at_background[B_PushButt]
    or  al,at_foreground[F_TitleKey]
    shl eax,16

    .while 1

        lodsb
        .break .if !al

        .if al != '&'

            mov [rdi],al
            add rdi,4
            .continue(0)
        .else
            lodsb
            .break .if !al
            stosd
        .endif
    .endw
    mov rax,wp
    ret

wcpbutt endp

wcstline proc private

    mov ecx,_scrcol
    mov ch,1
    shl ecx,16
    mov ch,byte ptr _scrrow
    rcxchg(ecx, rax)
    ret

wcstline endp

wcpushst proc uses rbx wc:PCHAR_INFO, cp:LPSTR

    .if wcvisible == 1

        ldr rax,wc
        wcstline()
    .endif

    movzx eax,at_background[B_Menus]
    or    al,at_foreground[F_KeyBar]
    shl   eax,16
    mov   al,' '

    wcputw(wc, _scrcol, eax)
    mov rbx,wc
    mov word ptr [rbx+18*4],U_LIGHT_VERTICAL
    add rbx,4
    wcputs(rbx, _scrcol, cp)
    mov rax,wc
    wcstline()
    mov wcvisible,1
    ret

wcpushst endp

wcpopst proc wp:PCHAR_INFO

    mov rax,wp
    wcstline()
    xor wcvisible,1
    ret

wcpopst endp

wcputw proc p:PCHAR_INFO, l:uint_t, w:uint_t

    ldr eax,w
    ldr rcx,p
    ldr edx,l
    .if eax & 0x00FF0000
        xchg rcx,rdx
        xchg rdx,rdi
        rep  stosd
        mov  rdi,rdx
    .else
        .repeat
            mov [rcx],ax
            add rcx,4
            dec edx
        .until !edx
    .endif
    ret

wcputw endp


wcputs proc uses rsi rdi rbx p:PCHAR_INFO, m:uint_t, string:LPSTR

    ldr rsi,string
    ldr rdi,p
    ldr ebx,m

    .if !bl
        dec bl
    .endif
    .while ( bl && byte ptr [rsi] )

        _utftow(rsi)
        add rsi,rcx
        .if bh
            movzx ecx,bh
            mov [rdi+2],cx
        .endif
        mov [rdi],ax
        add rdi,4
        dec bl
    .endw
    ret

wcputs endp

wcputf proc __Cdecl b:PCHAR_INFO, m:uint_t, format:LPSTR, argptr:VARARG

    vsprintf( &_bufin, format, &argptr )
    wcputs(b, m, addr _bufin)
    ret

wcputf endp

wctitle proc p:PCHAR_INFO, l:dword, string:LPSTR

    movzx   eax,at_background[B_Title]
    or      al,at_foreground[F_Title]
    shl     eax,16
    mov     al,' '

    wcputw(p, l, eax)
    wcenter(p, l, string)
    ret

wctitle endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClipboardFree proc

    free(clipboard)
    xor eax,eax
    mov clipbsize,eax
    mov clipboard,rax
    ret

ClipboardFree endp

ClipboardCopy proc uses rsi rdi rbx string:LPSTR, len:UINT

    mov edi,len
    ClipboardFree()
    mov eax,console
ifdef _WIN95
    and eax,CON_WIN95 or CON_CLIPB
    .if eax == CON_CLIPB
else
    and eax,CON_CLIPB
    .if eax
endif
        .ifd OpenClipboard(0)

            EmptyClipboard()
            inc edi

            .if GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, edi)

                dec edi
                mov rsi,rax
                mov rbx,memcpy(GlobalLock(rax), string, edi)
                mov byte ptr [rbx+rdi],0
                GlobalUnlock(rsi)
                SetClipboardData(CF_TEXT, rbx)
                mov eax,edi
            .endif
            mov edi,eax
            CloseClipboard()
            mov eax,edi
        .endif
    .else
        inc edi
        .if malloc(edi)

            dec edi
            memcpy(rax, string, edi)
            mov byte ptr [rax+rdi],0
            mov clipboard,rax
            mov clipbsize,edi
        .endif
        mov eax,edi
    .endif
    ret

ClipboardCopy endp

ClipboardPaste proc uses rbx
    mov eax,console
ifdef _WIN95
    and eax,CON_WIN95 or CON_CLIPB
    .if eax == CON_CLIPB
else
    and eax,CON_CLIPB
    .if eax
endif
        .ifd IsClipboardFormatAvailable(CF_TEXT)

            .ifd OpenClipboard(0)

                .if GetClipboardData(CF_TEXT)

                    mov rbx,rax
                    .ifd strlen(rax)

                        mov clipbsize,eax
                        inc eax
                        .if malloc(eax)

                            strcpy(rax, rbx)
                            mov clipboard,rax
                        .else
                            xor eax,eax
                        .endif
                    .endif
                .endif

                mov rbx,rax
                CloseClipboard()
                mov rax,rbx
            .endif
        .endif
    .elseif clipbsize
        mov rax,clipboard
    .else
        xor eax,eax
    .endif
    mov ecx,clipbsize
    ret

ClipboardPaste endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    assume rbx:PDOBJ

dlopen proc uses rbx dobj:PDOBJ, at:uint_t, ttl:LPSTR

    ldr rbx,dobj
    ldr edx,at
    and edx,0xFF
    mov [rbx].wp,rcopen([rbx].rc, [rbx].flag, edx, ttl, [rbx].wp)

    .if rax

        or  [rbx].flag,_D_DOPEN
        mov eax,1
    .endif
    ret

dlopen endp

dlshow proc uses rbx dobj:PDOBJ

    ldr rbx,dobj
    .ifd rcshow([rbx].rc, [rbx].flag, [rbx].wp)

        or [rbx].flag,_D_ONSCR
    .endif
    ret

dlshow endp

dlhide proc uses rbx dobj:PDOBJ

    ldr rbx,dobj
    .ifd rchide([rbx].rc, [rbx].flag, [rbx].wp)

        and [rbx].flag,not _D_ONSCR
    .endif
    ret

dlhide endp

dlclose proc uses rbx dobj:PDOBJ

   .new prevret:int_t = eax
   .new retval:int_t = 0

    ldr rbx,dobj

    .if ( [rbx].flag & _D_DOPEN )

        inc retval

        .if ( [rbx].flag & _D_ONSCR )

            inc retval
            rcwrite([rbx].rc, [rbx].wp)
            .if ( [rbx].flag & _D_SHADE )

                rcshade([rbx].rc, [rbx].wp, 0)
            .endif
        .endif

        and [rbx].flag,not (_D_DOPEN or _D_ONSCR)
        .if !( [rbx].flag & _D_MYBUF )

            free([rbx].wp)
            mov [rbx].wp,0
        .endif

        .if ( [rbx].flag & _D_RCNEW )

            free(rbx)
        .endif
    .endif
     mov edx,prevret
    .return( retval )

dlclose endp

    assume rbx:nothing

dlinit proc uses rsi rdi rbx td:PDOBJ

  local object:PTOBJ, wp:PCHAR_INFO, window:ptr

    ldr rbx,td
    mov edi,[rbx]

    .if ( edi & _D_ONSCR )

        mov wp,[rbx].DOBJ.wp
        .if ( rcalloc([rbx].DOBJ.rc, 0) == NULL )

            .return
        .endif

        mov [rbx].DOBJ.wp,rax
        rcread( [rbx].DOBJ.rc, rax)
    .endif

    .new flags:int_t  = edi
    .new count:byte   = [rbx].DOBJ.count
    .new rc:TRECT     = [rbx].DOBJ.rc
    .new p:PCHAR_INFO = [rbx].DOBJ.wp

    .for ( rbx = [rbx].DOBJ.object : count : count--, rbx += TOBJ )

        movzx   eax,rc.col
        mov     rdi,rcbprc([rbx].TOBJ.rc, p, eax)
        movzx   eax,[rbx].TOBJ.flag
        and     eax,0x000F

        .switch eax
        .case _O_PBUTT
            movzx ecx,[rbx].TOBJ.rc.col
            .repeat
                mov ah,[rdi+2]
                mov al,ah
                and al,0x0F
                .if ( [rbx].TOBJ.flag & _O_DEACT )
                    .if !al
                        and ah,0x70
                        or  ah,0x08
                        mov [rdi+2],ah
                    .endif
                .elseif al == 8
                    and ah,0x70
                    mov [rdi+2],ah
                .endif
                add rdi,4
            .untilcxz
            .endc
        .case _O_RBUTT
            mov eax,' '
            .if ( [rbx].TOBJ.flag & _O_RADIO )
                mov eax,U_BULLET_OPERATOR
            .endif
            mov [rdi+4],ax
           .endc
        .case _O_CHBOX
            mov eax,' '
            .if ( [rbx].TOBJ.flag & _O_FLAGB )
                mov eax,'x'
            .endif
            mov [rdi+4],ax
           .endc

        .case _O_XCELL
            .for ( ecx = 0 : cl < [rbx].TOBJ.rc.col : ecx++ )
                mov word ptr [rdi+rcx*4],' '
            .endf
            mov rsi,[rbx].TOBJ.data
            .if rsi
                add rdi,4
                movzx edx,[rbx].TOBJ.rc.col
                sub edx,2
                wcpath(rdi, edx, rsi)
            .endif
            .endc

        .case _O_TEDIT
            mov edx,U_MIDDLE_DOT
            .for ( ecx = 0 : cl < [rbx].TOBJ.rc.col : ecx++ )
                mov [rdi+rcx*4],dx
            .endf
            mov rsi,[rbx].TOBJ.data
            .if rsi
                .for ( eax = 0, ecx = 0 : cl < [rbx].TOBJ.rc.col : ecx++ )

                    mov al,[rsi+rcx]
                    .break .if !al
                    mov [rdi+rcx*4],ax
                .endf
            .endif
            .endc
        .case _O_MENUS
            .if ( [rbx].TOBJ.flag & _O_FLAGB )
                mov word ptr [rdi-4],0x00BB
            .elseif ( [rbx].TOBJ.flag & _O_RADIO )
                mov word ptr [rdi-4],U_BULLET_OPERATOR
            .endif
            .endc
        .endsw
    .endf

    .if ( flags & _D_ONSCR )

        mov rbx,td
        rcwrite([rbx].DOBJ.rc, [rbx].DOBJ.wp)
        free([rbx].DOBJ.wp)
        mov [rbx].DOBJ.wp,wp
    .endif
    ret

dlinit endp

    option proc:private

;    assume rsi:PDOBJ
    assume rdx:PTEDIT

getline proc uses rsi rdi

    mov rdx,TI
    mov rax,[rdx].base

    .if rax

        mov     rsi,rax
        mov     rdi,rax
        mov     ecx,[rdx].bcol   ; terminate line
        xor     eax,eax     ; set length of line
        mov     [rdi+rcx-1],al
        mov     ecx,-1
        repne   scasb
        not     ecx
        dec     ecx
        dec     rdi
        mov     [rdx].bcount,ecx
        sub     ecx,[rdx].bcol   ; clear rest of line
        neg     ecx
        rep     stosb
        mov     ecx,[rdx].bcount
        mov     rax,[rdx].base
    .endif
    ret

getline endp


curlptr proc uses rbx

    .if getline()

        mov ebx,[rdx].boffs
        add ebx,[rdx].xoffs
        add rax,rbx
    .endif
    ret

curlptr endp

event_home proc

    .if !getline()

        .return(_TE_CMFAILED)
    .endif
    xor eax,eax
    mov [rdx].boffs,eax
    mov [rdx].xoffs,eax
    ret

event_home endp

event_toend proc

    event_home()
    .if !getline()
        .return(_TE_CMFAILED)
    .endif

    .ifd stripend(rax)

        mov eax,[rdx].cols
        dec eax
        .ifs ecx <= eax
            mov eax,ecx
        .endif
        mov [rdx].xoffs,eax
        mov ecx,[rdx].bcount
        sub ecx,[rdx].cols
        inc ecx
        xor eax,eax
        .ifs eax <= ecx
            mov eax,ecx
        .endif
        mov [rdx].boffs,eax
        add eax,[rdx].xoffs
        .if eax > [rdx].bcount
            dec [rdx].boffs
        .endif
    .endif
    xor eax,eax
    ret

event_toend endp

event_left proc

    xor eax,eax
    .if eax != [rdx].xoffs
        dec [rdx].xoffs
    .elseif eax != [rdx].boffs
        dec [rdx].boffs
    .else
        mov eax,_TE_CMFAILED
        .if [rdx].flags & _TE_DLEDIT
            mov eax,_TE_RETEVENT
        .endif
    .endif
    ret

event_left endp

event_right proc uses rbx

    mov rcx,curlptr()
    mov ebx,[rdx].xoffs
    sub rcx,rbx

    mov al,[rax]
    .if al

        mov eax,[rdx].cols
        dec eax

        .if eax > [rdx].xoffs

            inc [rdx].xoffs
           .return( 0 )
        .endif
    .endif

    mov rbx,rdx
    strlen(rcx)
    mov rdx,rbx

    .if eax >= [rdx].cols

        inc [rdx].boffs
       .return( 0 )
    .endif
    mov eax,_TE_CMFAILED
    .if [rdx].flags & _TE_DLEDIT
        mov eax,_TE_RETEVENT
    .endif
    ret

event_right endp

event_delete proc uses rbx

    .if curlptr()

        stripend(rax)
        curlptr()

        .if ecx && byte ptr [rax]

            dec [rdx].bcount
            mov rcx,rax
            mov rbx,rdx
            strcpy(rcx, &[rax+1])
            mov rdx,rbx
            or [rdx].flags,_TE_MODIFIED
           .return(_TE_CONTINUE)
        .endif
    .endif
    tinocando()
    ret

event_delete endp

event_backsp proc

    .if getline()

        mov eax,[rdx].xoffs
        add eax,[rdx].boffs
        .if !eax || !ecx
            tinocando()
        .else
            event_left()
            curlptr()
            .ifd stripend(rax)
                event_delete()
            .endif
        .endif
    .endif
    ret

event_backsp endp


event_add proc uses rbx

    mov ebx,eax
    .if !getline()
        .return tinocando()
    .endif
    movzx eax,bl
    lea rcx,_ltype

    .if ( byte ptr [rcx+rax] & _CONTROL )

        .if ( !eax || !( [rdx].flags & _TE_USECONTROL ) )

            .return( _TE_RETEVENT )
        .endif
    .endif

    mov eax,[rdx].bcount
    inc eax

    .if ( eax < [rdx].bcol )

        .ifd tiincx(rdx)

            inc [rdx].bcount

            .if getline()

                or [rdx].flags,_TE_MODIFIED
                mov eax,[rdx].boffs
                add eax,[rdx].xoffs
                add rax,[rdx].base
                dec rax
                strshr(rax, ebx)
               .return( 0 )
            .endif
        .endif
    .endif
    mov eax,[rdx].bcol
    dec eax
    mov [rdx].bcount,eax
    tinocando()
    ret

event_add endp

setcursor proc

  local cursor:CURSOR

    mov rdx,TI
    mov eax,[rdx].xpos
    add eax,[rdx].xoffs
    mov ecx,[rdx].ypos
    mov cursor.x,ax
    mov cursor.y,cx
    mov cursor.bVisible,1
    mov cursor.dwSize,CURSOR_NORMAL
    _setcursor(&cursor)
    ret

setcursor endp

ti_event proc uses rsi rbx

    mov rdx,TI
    mov ecx,[rdx].flags

    .switch eax

    .case _TE_CONTINUE
        xor eax,eax ; _TI_CONTINUE - continue edit
       .endc

    .case KEY_CTRLRIGHT

        .endc .if !curlptr()

        mov rdx,rax ; to end of word
        mov rcx,rax
        xor eax,eax
        lea rbx,_ltype

        .repeat
            mov al,[rcx]
            inc rcx
        .until !( byte ptr [rbx+rax] & _LABEL or _DIGIT )
        .endc .if !al

        .repeat         ; to start of word
            mov al,[rcx]
            inc rcx
           .endc .if !al
        .until ( byte ptr [rbx+rax] & _LABEL or _DIGIT )

        dec rcx
        sub rcx,rdx
        mov rdx,TI
        mov eax,[rdx].boffs
        add eax,[rdx].xoffs
        add eax,ecx
        .endc .if ( eax > [rdx].bcount )

        sub eax,[rdx].boffs
        mov ecx,[rdx].cols
        .if eax >= ecx
            dec ecx
            sub eax,ecx
            add [rdx].boffs,eax
            mov [rdx].xoffs,ecx
        .else
            mov [rdx].xoffs,eax
        .endif
        mov eax,_TE_CONTINUE
       .endc

    .case KEY_CTRLLEFT

        .endc .if !getline()

        mov rcx,rax
        mov eax,[rdx].boffs
        add eax,[rdx].xoffs
        .endc .ifz

        lea rdx,[rax+rcx-1]
        movzx eax,byte ptr [rdx]
        lea rbx,_ltype

        .while ( rcx < rdx && !( byte ptr [rbx+rax] & _LABEL or _DIGIT ) )

            dec rdx
            mov al,[rdx]
        .endw
        .while ( rcx < rdx && ( byte ptr [rbx+rax] & _LABEL or _DIGIT ) )

            dec rdx
            mov al,[rdx]
        .endw

        .if !( byte ptr [rbx+rax] & _LABEL or _DIGIT )

            mov al,[rdx+1]
            .if ( byte ptr [rbx+rax] & _LABEL or _DIGIT )

                inc rdx
            .endif
        .endif

        mov  rax,TI
        xchg rax,rdx
        mov ebx,[rdx].boffs
        add ebx,[rdx].xoffs
        add rcx,rbx
        sub rcx,rax

        .if ( ecx > [rdx].xoffs )

            sub ecx,[rdx].xoffs
            mov [rdx].xoffs,0
            sub [rdx].boffs,ecx
        .else
            sub [rdx].xoffs,ecx
        .endif
        mov eax,_TE_CONTINUE
       .endc

    .case KEY_LEFT
        event_left()
       .endc
    .case KEY_RIGHT
        event_right()
       .endc
    .case KEY_HOME
        event_home()
       .endc
    .case KEY_END
        event_toend()
       .endc
    .case KEY_BKSP
        event_backsp()
       .endc
    .case KEY_DEL
        event_delete()
       .endc

    .case MOUSECMD
        mov ecx,keybmouse_x
        mov eax,[rdx].xpos

        .if ecx >= eax

            add eax,[rdx].cols
            .if ecx < eax

                mov eax,[rdx].ypos
                .if eax == keybmouse_y

                    mov ebx,ecx
                    mov rsi,rdx
                    .if getline()
                        strlen(rax)
                    .endif
                    mov ecx,ebx
                    mov rdx,rsi
                    sub ecx,[rdx].xpos
                    .ifs ecx <= eax
                        mov eax,ecx
                    .endif
                    mov [rdx].xoffs,eax
                    setcursor()
                    msloop()
                    xor eax,eax
                   .endc
                .endif
            .endif
        .endif

    .case KEY_UP
    .case KEY_DOWN
    .case KEY_PGUP
    .case KEY_PGDN
    .case KEY_CTRLPGUP
    .case KEY_CTRLPGDN
    .case KEY_CTRLHOME
    .case KEY_CTRLEND
    .case KEY_CTRLUP
    .case KEY_CTRLDN
    .case KEY_MOUSEUP
    .case KEY_MOUSEDN
    .case KEY_ENTER
    .case KEY_KPENTER
    .case KEY_ESC
        mov eax,_TE_RETEVENT ; return current event (keystroke)
       .endc
    .case KEY_TAB
        .if !( ecx & _TE_USECONTROL )

            mov eax,_TE_RETEVENT ; return current event (keystroke)
           .endc
        .endif
        mov eax,9
    .default
        event_add()
       .endc
    .endsw
    ret

ti_event endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClipIsSelected proc

    mov rdx,TI
    mov eax,[rdx].clip_eo
    sub eax,[rdx].clip_so
    ret

ClipIsSelected endp

ClipSet proc

    mov rdx,TI
    mov eax,[rdx].xoffs
    add eax,[rdx].boffs
    mov [rdx].clip_so,eax
    mov [rdx].clip_eo,eax
    ret

ClipSet endp

ClipDelete proc uses rsi rbx

    .ifd ClipIsSelected()

        mov ebx,[rdx].clip_so
        mov esi,[rdx].xoffs
        add esi,[rdx].boffs

        .if esi < ebx

            .repeat
                .break .ifd !tiincx(rdx)
                inc esi
            .until ( ebx == esi )
            inc esi

        .elseif ( esi > ebx )

            .repeat
                .break .ifd !tidecx(rdx)
                dec esi
            .until ( ebx == esi )
            inc esi
        .endif

        or [rdx].flags,_TE_MODIFIED
        mov eax,[rdx].clip_so
        mov esi,[rdx].clip_eo
        add rax,[rdx].base
        add rsi,[rdx].base

        strcpy(rax, rsi)
        getline()
        ClipSet()
        mov eax,1
    .endif
    ret

ClipDelete endp

ClipCC proc uses rsi rdi cut:int_t

    mov rsi,TI
    mov edi,cut ; Copy == 0, Cut == 1

    .repeat

        .ifd ClipIsSelected() ; get size of selection

            mov rdx,TI
            mov eax,[rdx].clip_so
            add rax,[rdx].base
            mov ecx,[rdx].clip_eo
            sub ecx,[rdx].clip_so
            .break .ifd !ClipboardCopy(rax, ecx)
            .if edi
                ClipDelete()
            .endif
        .endif
        ClipSet()
    .until 1
    xor eax,eax
    ret

ClipCC endp

ClipCopy proc
    ClipCC(0)
    ret
ClipCopy endp

ClipCut proc
    ClipCC(1)
    ret
ClipCut endp

ClipPaste proc uses rsi rdi rbx

   .new x:uint_t
   .new b:uint_t

    mov rdx,TI

    .if ( [rdx].flags & _TE_OVERWRITE )
        ClipDelete()
    .else
        ClipSet()
    .endif

    .if ClipboardPaste()

        mov rdx,TI
        mov rdi,rax
        mov esi,ecx ; clipbsize
        mov x,[rdx].xoffs
        mov b,[rdx].boffs

        .repeat
            movzx eax,byte ptr [rdi]
            .break .if !eax
            inc rdi
            .break .ifd event_add() != _TE_CONTINUE
            dec esi
        .untilz
        ClipboardFree()

        mov rdx,TI
        mov [rdx].boffs,b
        mov [rdx].xoffs,x
    .endif
    ClipSet()
    xor eax,eax
    ret

ClipPaste endp

ClipEvent proc uses rsi rdi rbx

    mov esi,eax

    .ifd !ClipIsSelected()

        ClipSet() ; reset clipboard if not selected
    .endif

    .switch esi
    .case KEY_CTRLINS
    .case KEY_CTRLC
        ClipCopy()
       .endc
    .case KEY_CTRLV
        ClipPaste()
       .endc
    .case KEY_CTRLDEL
        ClipCut()
       .endc
    .default

        mov rax,keyshift
        mov eax,[rax]
        .if eax & SHIFT_KEYSPRESSED

            .switch esi
            .case KEY_INS     ; Shift-Insert -- Paste()
                .gotosw(1:KEY_CTRLV)
            .case KEY_DEL     ; Shift-Del -- Cut()
                .gotosw(1:KEY_CTRLDEL)
            .case KEY_HOME
            .case KEY_LEFT
            .case KEY_RIGHT
            .case KEY_END

                mov eax,esi ; consume event, return null
                ti_event()
                .if ( eax == _TE_CMFAILED || eax == _TE_RETEVENT )

                    .return( 0 )
                .endif

                mov rbx,TI
                mov eax,[rbx].TEDIT.boffs
                add eax,[rbx].TEDIT.xoffs

                .if ( eax >= [rbx].TEDIT.clip_so )

                    .if ( esi == KEY_RIGHT )

                        mov edx,eax
                        dec edx
                        .if ( edx == [rbx].TEDIT.clip_so )

                            .if ( edx != [rbx].TEDIT.clip_eo )

                                mov [rbx].TEDIT.clip_so,eax
                               .return( 0 )
                            .endif
                        .endif
                    .endif
                    mov [rbx].TEDIT.clip_eo,eax
                   .return( 0 )
                .endif
                mov [rbx].TEDIT.clip_so,eax
               .return( 0 )
            .endsw
        .endif

        .if esi == KEY_DEL     ; Delete selected text ?

            .ifd !ClipDelete()

                ClipSet()      ; set clipboard to cursor
                mov eax,esi    ; return event
               .endc
            .endif
            xor eax,eax
           .endc
        .endif

        xor ecx,ecx
        .switch esi
        .case KEY_ESC
        .case MOUSECMD
        .case KEY_BKSP
        .case KEY_ENTER
        .case KEY_KPENTER
        .case KEY_TAB
            inc ecx
        .default
            mov eax,esi
            .if !al
                inc ecx
            .endif
            .endc
        .endsw
        .if !ecx
            ClipDelete()
        .endif
        ClipSet()           ; set clipboard to cursor
        mov eax,esi         ; return event
    .endsw
    ret

ClipEvent endp

putline proc uses rsi rdi rbx

  local ci[MAXCOLS]:dword, bz:COORD, rc:SMALL_RECT, cols:int_t

    setcursor()

    lea rdi,ci
    mov rdx,TI
    mov ecx,[rdx].cols
    mov eax,[rdx].clrc
    mov cols,ecx
    rep stosd

    mov rsi,[rdx].base
    strlen(rsi)
    mov rdx,TI

    .if ( eax > [rdx].boffs )

        mov edi,[rdx].boffs
        add rsi,rdi

        .for ( rdi = &ci, ebx = 0 : byte ptr [rsi] && ebx < cols : ebx++, rsi++, rdi+=4 )

            .ifd !MultiByteToWideChar(_consolecp, 0, rsi, 1, rdi, 1)

                mov al,[rsi]
                mov [rdi],al
            .endif
        .endf
        mov rdx,TI
    .endif

    mov edi,[rdx].boffs
    mov ecx,[rdx].clip_eo

    .if edi < ecx

        sub ecx,edi
        xor eax,eax
        .if ecx >= cols

            mov ecx,cols
        .endif
        .if [rdx].clip_so >= edi

            mov eax,[rdx].clip_so
            sub eax,edi
            .if eax <= ecx
                sub ecx,eax
            .else
                xor ecx,ecx
            .endif
        .endif
        .if ecx

            lea rdi,ci
            lea rdi,[rdi+rax*4+2]
            mov al,at_background[B_Inverse]
            .repeat
                mov [rdi],al
                add rdi,4
            .untilcxz
        .endif
    .endif

    mov ecx,cols
    mov bz.X,cx
    mov eax,[rdx].xpos
    mov rc.Left,ax
    add eax,ecx
    dec eax
    mov rc.Right,ax
    mov eax,[rdx].ypos
    mov rc.Top,ax
    mov rc.Bottom,ax
    mov bz.Y,1
    WriteConsoleOutputW(_confh, &ci, bz, 0, &rc)
    ret

putline endp

modal proc uses rsi rdi

    xor esi,esi

    .repeat
        .if !esi
            getline()
            putline()
        .endif
        tgetevent()
        mov edi,ClipEvent()
        mov esi,ti_event()
    .until eax == _TE_RETEVENT
    getline()
    mov eax,edi ; return current event (keystroke)
    ret

modal endp

    option proc:public

define tclrascii 0xB7

dledit proc uses rdi rbx b:LPSTR, rc:TRECT, bz, oflag

  local t:TEDIT
  local cursor:CURSOR

    _getcursor(&cursor)

    lea rdi,t
    xor eax,eax
    mov ecx,TEDIT
    rep stosb
    mov rdi,TI
    lea rax,t
    mov TI,rax

    movzx eax,rc.x
    mov t.xpos,eax
    mov al,rc.y
    mov t.ypos,eax
    mov al,rc.col
    mov t.cols,eax
    mov eax,bz
    mov t.bcol,eax
    mov rax,b
    mov t.base,rax
    mov eax,oflag
    and eax,_O_CONTR or _O_DLGED
    or  eax,_TE_OVERWRITE
    mov t.flags,eax
    setcursor()
    .ifd !getxya(t.xpos, t.ypos)
        mov eax,0x07
    .endif
    shl eax,16
    mov al,tclrascii
    mov t.clrc,eax  ; save text color
    .if oflag & _O_DTEXT
        event_toend()
        mov eax,t.xoffs
        add eax,t.boffs
        mov t.clip_eo,eax
    .endif
    mov ebx,modal()
    putline()
    _setcursor(&cursor)
    mov eax,ebx
    mov TI,rdi
    ret

dledit endp

dledite proc uses rdi rbx t:PVOID, event

    mov rdi,TI
    mov rax,t
    mov TI,rax
    getline()
    putline()
    mov eax,event
    .if !eax
        tgetevent()
        mov event,eax
    .endif
    ClipEvent()
    mov ebx,ti_event()
    getline()
    putline()
    mov edx,ebx
    xor eax,eax
    .if edx == _TE_RETEVENT
        mov eax,event
    .endif
    mov TI,rdi
    ret

dledite endp

    assume rdx:nothing

PrevItem proc private uses rsi

    mov   rsi,tdialog
    movzx eax,[rsi].DOBJ.count
    movzx ecx,[rsi].DOBJ.index
    mov   edx,ecx
    imul  edx,edx,TOBJ
    add   rdx,[rsi].DOBJ.object

    .repeat

        .if ecx

            sub rdx,TOBJ
            .repeat

                .if !( [rdx].TOBJ.flag & _O_DEACT )

                    dec ecx
                    mov [rsi].DOBJ.index,cl
                    mov eax,1
                    .break(1)
                .endif
                sub rdx,TOBJ
            .untilcxz
            xor ecx,ecx
        .endif

        add cl,[rsi].DOBJ.count
        .ifnz

            movzx  eax,[rsi].DOBJ.index
            lea    edx,[rcx-1]
            imul   edx,edx,TOBJ
            add    rdx,[rsi].DOBJ.object

            .repeat

                .break .if eax > ecx

                .if !( [rdx].TOBJ.flag & _O_DEACT )

                    dec ecx
                    mov [rsi].DOBJ.index,cl
                    mov eax,1
                   .break( 1 )
                .endif
                sub rdx,TOBJ
            .untilcxz
        .endif
        xor eax,eax
    .until 1
    mov result,eax
    ret

PrevItem endp

NextItem proc private uses rsi

    mov     rsi,tdialog
    movzx   eax,[rsi].DOBJ.count
    movzx   ecx,[rsi].DOBJ.index
    lea     edx,[rcx+1]
    imul    edx,edx,TOBJ
    add     rdx,[rsi].DOBJ.object
    add     ecx,2

    .repeat

        .while ecx <= eax

            .if !( [rdx].TOBJ.flag & _O_DEACT )

                dec ecx
                mov [rsi].DOBJ.index,cl
                mov eax,1
               .break( 1 )
            .endif
            inc ecx
            add rdx,TOBJ
        .endw

        mov     rdx,[rsi].DOBJ.object
        movzx   eax,[rsi].DOBJ.index
        inc     eax
        mov     ecx,1

        .while ecx <= eax

            .if !( [rdx].TOBJ.flag & _O_DEACT )

                dec ecx
                mov [rsi].DOBJ.index,cl
                mov eax,1
               .break( 1 )
            .endif
            inc ecx
            add rdx,TOBJ
        .endw
        xor eax,eax
    .until 1
    mov result,eax
    ret

NextItem endp

MouseDelay proc private

    .ifd mousep()

        scroll_delay()
        scroll_delay()
        or eax,1
    .endif
    ret

MouseDelay endp

test_event proc private uses rsi rdi rbx cmd, extended

  local mx,my,n,i,x,x2,y,l,row,flag,c1,c2,c3,c4

    mov rsi,tdialog
    xor edi,edi
    xor ebx,ebx

    .if ( [rsi].DOBJ.count )

        mov     rcx,[rsi].DOBJ.object
        mov     bl,[rsi].DOBJ.index
        imul    ebx,ebx,TOBJ
        add     rbx,rcx
        movzx   edi,[rbx].TOBJ.flag
    .endif

    mov eax,cmd
    .switch eax
    .case KEY_ESC
    .case KEY_ALTX
        mov result,_C_ESCAPE
       .return

    .case KEY_ALTUP
    .case KEY_ALTDN
    .case KEY_ALTLEFT
    .case KEY_ALTRIGHT
        movzx ecx,[rsi].DOBJ.flag
        .if ( ecx & _D_DMOVE )

            mov rdi,[rsi].DOBJ.wp
            mov ebx,[rsi].DOBJ.rc

            .if ( ecx & _D_SHADE )

                rcshade(ebx, rdi, 0)
            .endif

            mov eax,cmd
            movzx ecx,[rsi].DOBJ.flag

            .switch pascal eax
            .case KEY_ALTUP:    rcmoveu(ebx, rdi, ecx)
            .case KEY_ALTDN:    rcmoved(ebx, rdi, ecx)
            .case KEY_ALTLEFT:  rcmovel(ebx, rdi, ecx)
            .case KEY_ALTRIGHT: rcmover(ebx, rdi, ecx)
            .endsw

            mov bx,ax
            mov word ptr [rsi].DOBJ.rc,ax
            .if [rsi].DOBJ.flag & _D_SHADE
                rcshade(ebx, rdi, 1)
            .endif
        .endif
        .return(0)

    .case KEY_ENTER
    .case KEY_KPENTER
        mov eax,_C_RETURN
        .if ( edi & _O_CHILD )

            mov rax,[rbx].TOBJ.tproc
            .if rax

                call rax
                mov edi,eax

                .if ( eax == _C_REOPEN )

                    mov bl,[rsi].DOBJ.index
                    dlinit(rsi)
                    mov [rsi].DOBJ.index,bl
                .endif
                mov eax,edi
            .endif
        .endif
        mov result,eax
       .return

    .case MOUSECMD

        mov mx,mousex()
        mov my,mousey()
        mov result,_C_NORMAL

        .ifd !rcxyrow([rsi].DOBJ.rc, mx, my)

            mov result,_C_ESCAPE
           .return
        .endif

        mov   row,eax
        mov   edi,[rsi].DOBJ.rc
        movzx eax,[rsi].DOBJ.count
        mov   rbx,[rsi].DOBJ.object
        mov   i,eax

        .while i

            mov eax,[rbx].TOBJ.rc
            add ax,di

            .ifd rcxyrow(eax, mx, my)

                xor eax,eax
                mov row,eax
                mov al,[rsi].DOBJ.count
                sub eax,i
                mov ebx,eax
                imul eax,eax,TOBJ
                add rax,[rsi].DOBJ.object
                mov rdi,rax
                mov ax,[rdi].TOBJ.flag
                mov flag,eax

                .if !( eax & _O_DEACT )

                    mov [rsi].DOBJ.index,bl
                    and eax,0x0F

                    .if ( al == _O_TBUTT || al == _O_PBUTT )

                        mov al,[rsi].DOBJ.rc.x
                        add al,[rdi].TOBJ.rc.x
                        mov x,eax

                        mov al,[rsi].DOBJ.rc.y
                        add al,[rdi].TOBJ.rc.y
                        mov y,eax

                        mov al,[rdi].TOBJ.rc.col
                        mov l,eax

                        add eax,x
                        dec eax
                        mov x2,eax
                        mov ebx,eax

                        mov c1,getxyc(x, y)
                        mov c2,getxyc(ebx, y)
                        scputc(x, y, 1, ' ')
                        scputc(x2, y, 1, ' ')

                        inc ebx
                        mov c3,getxyc(ebx, y)
                        sub ebx,l
                        inc ebx
                        mov eax,y
                        inc eax
                        mov c4,getxyc(ebx, eax)
                        mov eax,flag
                        and eax,0x0F
                        mov n,eax

                        .ifz

                            mov eax,y
                            inc eax
                            scputc(ebx, eax, l, ' ')

                            add ebx,l
                            dec ebx
                            scputc(ebx, y, 1, ' ')
                        .endif

                        msloop()

                        scputc(x, y, 1, c1)
                        scputc(x2, y, 1, c2)

                        .if ( n == 0 )

                            mov ebx,x
                            inc ebx
                            mov edx,y
                            inc edx
                            scputc(ebx, edx, l, c4)

                            add ebx,l
                            dec ebx
                            scputc(ebx, y, 1, c3)
                        .endif
                    .endif

                    mov eax,flag
                    .if ( eax & _O_DEXIT )
                        mov result,_C_ESCAPE
                    .endif

                    .if ( eax & _O_CHILD )

                        mov rax,[rdi].TOBJ.tproc
                        .if rax

                            call rax
                            mov result,eax

                            .if ( eax == _C_REOPEN )

                                mov bl,[rsi].DOBJ.index
                                dlinit(rsi)
                                mov [rsi].DOBJ.index,bl
                            .endif
                        .endif

                    .else

                        and eax,0x0F
                        .if ( al == _O_TBUTT ||
                              al == _O_PBUTT ||
                              al == _O_MENUS ||
                              al == _O_XHTML )

                            mov result,_C_RETURN
                        .endif
                    .endif

                .else

                    and eax,0x0F
                    .if ( al == _O_LLMSU )

                        mov rdx,tdllist
                        xor eax,eax

                        .repeat

                            .if ( eax != [rdx].LOBJ.count )

                                mov [rdx].LOBJ.celoff,eax
                                mov eax,[rdx].LOBJ.dlgoff
                                cmp al,[rsi].DOBJ.index
                                mov [rsi].DOBJ.index,al

                                .break .ifnz
                                .while test_event(KEY_UP, 1)
                                    .break .ifd !MouseDelay()
                                .endw
                            .endif
                            msloop()
                            mov eax,_C_NORMAL
                        .until 1

                    .elseif ( al == _O_LLMSD )

                        mov rdx,tdllist
                        xor eax,eax

                        .repeat

                            .if ( eax != [rdx].LOBJ.count )

                                mov [rdx].LOBJ.celoff,eax
                                mov eax,[rdx].LOBJ.dlgoff
                                cmp al,[rsi].DOBJ.index
                                mov [rsi].DOBJ.index,al

                                .break .ifnz
                                .while test_event(KEY_DOWN, 1)
                                    .break .ifd !MouseDelay()
                                .endw
                            .endif
                            msloop()
                            mov eax,_C_NORMAL
                        .until 1

                    .elseif ( al == _O_MOUSE )

                        .if ( flag & _O_CHILD )

                            mov rax,[rdi].TOBJ.tproc
                            .if rax

                                call rax
                                mov result,eax

                                .if eax == _C_REOPEN

                                    mov bl,[rsi].DOBJ.index
                                    dlinit(rsi)
                                    mov [rsi].DOBJ.index,bl
                                .endif
                            .endif
                        .endif
                    .endif
                .endif

                .break

            .endif

            add rbx,TOBJ
            dec i
        .endw

        mov eax,row
        .if eax == 1
            dlmove(rsi)
        .elseif eax
            msloop()
        .endif
        .return
    .endsw

    .if extended

        .switch eax
        .case KEY_LEFT
            .if ( edi & _O_LLIST )
                .gotosw(KEY_PGUP)
            .endif

            mov eax,edi
            and eax,0x0F
            .if ( al == _O_MENUS )

                mov result,0
               .return
            .endif

            movzx ecx,[rsi].DOBJ.index
            .if !ecx

                mov result,ecx
               .return
            .endif

            mov rdx,rbx
            mov eax,[rdx].TOBJ.rc
            sub rdx,TOBJ ; prev object

            .repeat

                .if ( ah == [rdx].TOBJ.rc.y && al > [rdx].TOBJ.rc.x )

                    .if !( [rdx].TOBJ.flag & _O_DEACT)

                        dec ecx
                        mov [rsi].DOBJ.index,cl
                        mov result,1
                       .return
                    .endif
                .endif
                sub rdx,TOBJ
            .untilcxz

        .case KEY_UP

            .if ebx

                .if ( edi & _O_LLIST )

                    xor eax,eax
                    mov rdx,tdllist

                    .if ( eax == [rdx].LOBJ.celoff )

                        .if ( eax != [rdx].LOBJ.index )

                            mov ecx,[rdx].LOBJ.dlgoff
                            .if [rsi].DOBJ.index == cl

                                dec [rdx].LOBJ.index
                                mov rax,rsi
                                call [rdx].LOBJ.lproc
                               .return
                            .endif

                            mov [rdx].DOBJ.index,cl
                            inc eax
                        .endif
                        .return
                    .endif
                .endif
                PrevItem()
            .endif
            .return

        .case KEY_RIGHT

            mov result,0
            .if ( edi & _O_LLIST )
                .gotosw(KEY_PGDN)
            .endif

            mov eax,edi
            and eax,0x0F

            .return .if al == _O_MENUS
            .return .if !ebx

            inc    result
            lea    rdx,[rbx+TOBJ]
            movzx  ecx,[rsi].DOBJ.index
            inc    ecx
            mov    eax,[rbx].TOBJ.rc

            .while ( cl < [rsi].DOBJ.count )

                .if ( ah == [rdx].TOBJ.rc.y && al < [rdx].TOBJ.rc.x )

                    .if !( [rdx].TOBJ.flag & _O_DEACT )

                        mov [rsi].DOBJ.index,cl
                       .return
                    .endif
                .endif
                inc ecx
                add rdx,TOBJ
            .endw

        .case KEY_DOWN

            .if !( edi & _O_LLIST )

                NextItem()
               .return
            .endif

            mov rdx,tdllist
            mov eax,[rdx].LOBJ.dcount
            mov ecx,[rdx].LOBJ.celoff
            dec eax

            .if ( eax != ecx )

                mov eax,ecx
                add eax,[rdx].LOBJ.index
                inc eax

                .if ( eax < [rdx].LOBJ.count )

                    NextItem()
                   .return
                .endif
            .endif

            mov eax,[rdx].LOBJ.dlgoff
            add eax,ecx
            mov ah,[rsi].DOBJ.index
            mov [rsi].DOBJ.index,al

            .if ( al != ah )

                mov result,_C_NORMAL
               .return
            .endif

            mov eax,[rdx].LOBJ.count
            sub eax,[rdx].LOBJ.index
            sub eax,[rdx].LOBJ.dcount

            .ifng

                mov result,0
               .return
            .endif

            inc [rdx].LOBJ.index
            mov rax,rsi
            call [rdx].LOBJ.lproc
            mov result,eax
           .return

        .case KEY_HOME

            mov result,_C_NORMAL
            xor eax,eax

            .if !( edi & _O_LLIST )

                mov ecx,edi
                and ecx,0x0F
               .return .if ( cl != _O_MENUS )
            .endif

            .ifnz

                mov  rdx,tdllist
                mov  [rdx].LOBJ.index,eax
                mov  [rdx].LOBJ.celoff,eax
                mov  ebx,[rdx].LOBJ.dlgoff
                mov  rax,rsi
                call [rdx].LOBJ.lproc
                mov eax,ebx
            .endif
            mov [rsi].DOBJ.index,al
            NextItem()
            PrevItem()
           .return

        .case KEY_END

            mov result,_C_NORMAL
            .if !( edi & _O_LLIST )

                mov eax,edi
                and eax,0x0F

                .if ( al == _O_MENUS )

                    mov al,[rsi].DOBJ.count
                    dec al
                    mov [rsi].DOBJ.index,al
                    PrevItem()
                    NextItem()
                .endif
                .return
            .endif

            mov rdx,tdllist
            mov eax,[rdx].LOBJ.count

            .if ( eax < [rdx].LOBJ.dcount )

                mov eax,[rdx].LOBJ.numcel
                dec eax
                mov [rdx].LOBJ.celoff,eax
                add eax,[rdx].LOBJ.dlgoff
                mov [rsi].DOBJ.index,al
               .return
            .endif

            mov result,0
            sub eax,[rdx].LOBJ.dcount

            .if ( eax != [rdx].LOBJ.index )

                mov [rdx].LOBJ.index,eax
                mov eax,[rdx].LOBJ.dcount
                dec eax
                mov [rdx].LOBJ.celoff,eax
                add eax,[rdx].LOBJ.dlgoff

                mov [rsi].DOBJ.index,al
                mov rax,rsi
                call [rdx].LOBJ.lproc
                mov result,eax
            .endif
            .return

        .case KEY_TAB

            .if ( edi & _O_LLIST )

                mov rdx,tdllist
                mov eax,[rdx].LOBJ.dlgoff
                add eax,[rdx].LOBJ.dcount
                mov [rsi].DOBJ.index,al
                mov result,_C_NORMAL
               .return
            .endif
            NextItem()
           .return

        .case KEY_PGUP

            .if !( edi & _O_LLIST )

                mov eax,edi
                and eax,0x0F

                .if ( al != _O_MENUS )

                    mov result,_C_NORMAL
                   .return
                .endif
            .endif

            mov rdx,tdllist
            xor eax,eax

            .if ( eax == [rdx].LOBJ.celoff )

                .if ( eax != [rdx].LOBJ.index )

                    mov eax,[rdx].LOBJ.dcount
                    .if ( eax > [rdx].LOBJ.index )
                        .gotosw(KEY_HOME)
                    .endif
                    sub [rdx].LOBJ.index,eax
                    mov rax,rsi
                    call [rdx].LOBJ.lproc
                    mov result,eax
                   .return
                .endif
            .else

                mov [rdx].LOBJ.celoff,eax
                mov eax,[rdx].LOBJ.dlgoff
                mov rdx,tdialog
                mov [rdx].DOBJ.index,al
            .endif
            mov result,_C_NORMAL
           .return

        .case KEY_PGDN

            .if !( edi & _O_LLIST )

                mov eax,edi
                and eax,0x0F
                .if ( al != _O_MENUS )

                    mov result,_C_NORMAL
                   .return
                .endif
            .endif

            mov rdx,tdllist
            mov eax,[rdx].LOBJ.dcount
            dec eax

            .if ( eax != [rdx].LOBJ.celoff )

                mov eax,[rdx].LOBJ.numcel
                add eax,[rdx].LOBJ.dlgoff
                dec eax
                mov [rsi].DOBJ.index,al
                mov result,_C_NORMAL
               .return
            .endif

            add eax,[rdx].LOBJ.celoff
            add eax,[rdx].LOBJ.index
            inc eax

            .if ( eax >= [rdx].LOBJ.count )
                .gotosw(KEY_END)
            .endif

            mov eax,[rdx].LOBJ.dcount
            add [rdx].LOBJ.index,eax
            mov rax,rsi
            call [rdx].LOBJ.lproc
            mov result,eax
           .return
        .endsw
    .endif

    .repeat

        .break .if !eax

        mov     rdx,tdialog
        movzx   ecx,[rdx].DOBJ.count
        mov     rdx,[rdx].DOBJ.object

        .if ( eax == KEY_F1 )

            xor eax,eax
            mov rdx,tdialog

            .if ( [rdx].DOBJ.flag & _D_DHELP )

                .if ( thelp )

                    call thelp
                    mov eax,_C_NORMAL
                .endif
            .endif
            .break
        .endif

        .if ( ecx == 0 )

            xor eax,eax
           .break
        .endif

        xor ebx,ebx
        xor esi,esi

        .repeat

            .if ( [rdx].TOBJ.flag & _O_GLCMD )

                mov rbx,[rdx].TOBJ.data
            .endif

            push rax

            .if ( [rdx].TOBJ.flag & _O_DEACT || [rdx].TOBJ.ascii == 0 )

                xor eax,eax
            .else

                and al,0xDF
                .if ( [rdx].TOBJ.ascii == al )

                    or al,1
                .else

                    mov     al,[rdx].TOBJ.ascii
                    and     al,0xDF
                    sub     al,'A'
                    push    rdx
                    push    rbx
                    lea     rbx,_scancodes
                    movzx   edx,al
                    cmp     ah,[rbx+rdx]
                    pop     rbx
                    pop     rdx
                    setz    al
                    test    al,al
                .endif
            .endif

            pop rax

            .ifnz

                test    [rdx].TOBJ.flag,_O_PBKEY
                mov     eax,esi
                mov     rdx,tdialog
                mov     [rdx].DOBJ.index,al
                mov     eax,_C_RETURN
                .break( 1 ) .ifnz
                mov     eax,_C_NORMAL
                .break( 1 )
            .endif

            add rdx,TOBJ
            inc esi

        .untilcxz

        .if rbx

            mov rdx,rbx
            .while ( [rdx].GLCMD.key )

                .if ( [rdx].GLCMD.key == eax )

                    [rdx].GLCMD.cmd()
                   .break( 1 )
                .endif
                add rdx,GLCMD
            .endw
        .endif
        xor eax,eax
    .until 1
    mov result,eax
    ret

test_event endp

dlpbuttevent proc private uses rsi rdi rbx

   .new cursor:CURSOR
   .new x:uint_t, y:uint_t, x2:uint_t

    _getcursor(&cursor)
    _cursoron()

    mov   rsi,tdialog
    movzx eax,[rsi].DOBJ.index
    imul  edi,eax,TOBJ
    add   rdi,[rsi].DOBJ.object
    movzx eax,[rsi].DOBJ.rc.x
    add   al,[rdi].TOBJ.rc.x
    mov   x,eax
    add   al,[rdi].TOBJ.rc.col
    dec   eax
    mov   x2,eax
    mov   al,[rsi].DOBJ.rc.y
    add   al,[rdi].TOBJ.rc.y
    mov   y,eax

    mov al,byte ptr [rdi].TOBJ.flag
    and al,0x0F
    .if al != _O_TBUTT
        _cursoroff()
    .else
        mov eax,x
        inc eax
        _gotoxy(eax, y)
    .endif
    mov ebx,getxyc(x, y)
    mov edi,getxyc(x2, y)
    scputc(x, y, 1, U_RIGHT_TRIANGLE)
    scputc(x2, y, 1, U_LEFT_TRIANGLE)
    mov esi,tgetevent()
    scputc(x, y, 1, ebx)
    scputc(x2, y, 1, edi)
    _setcursor(&cursor)
    mov eax,esi
    ret

dlpbuttevent endp

dlradioevent proc private uses rsi rdi

    local cursor:CURSOR
    local x,y

    _getcursor(&cursor)
    _cursoron()

    mov   rsi,tdialog
    movzx eax,[rsi].DOBJ.index
    imul  edi,eax,TOBJ
    add   rdi,[rsi].DOBJ.object
    movzx eax,[rsi].DOBJ.rc.x
    add   al,[rdi].TOBJ.rc.x
    inc   eax
    mov   x,eax
    mov   al,[rsi].DOBJ.rc.y
    add   al,[rdi].TOBJ.rc.y
    mov   y,eax

    _gotoxy(x, eax)
    .repeat

        .repeat

            .ifd tgetevent() == MOUSECMD

                .ifd mousey() != y
                    mov eax,MOUSECMD
                    .break(1)
                .endif
                mousex()
                mov edx,x
                dec edx
                .if eax < edx
                    mov eax,MOUSECMD
                    .break(1)
                .endif
                add edx,2
                .if eax > edx
                    mov eax,MOUSECMD
                    .break(1)
                .endif
            .elseif eax != KEY_SPACE

                .break(1)
            .endif

            mov ax,[rdi].TOBJ.flag
            and eax,_O_RADIO
            .repeat
                .ifz
                    movzx ecx,[rsi].DOBJ.count
                    .break .if !ecx

                    mov rdx,[rsi].DOBJ.object
                    .repeat
                        .break .if [rdx].TOBJ.flag & _O_RADIO
                        add rdx,TOBJ
                    .untilcxz
                    .break .ifz
                    and [rdx].TOBJ.flag,not _O_RADIO
                    or  [rdi].TOBJ.flag,_O_RADIO
                    mov cx,[rdx+4]
                    add cx,[rsi+4]
                    mov dl,ch
                    inc ecx
                    scputc(ecx, edx, 1, ' ')
                    scputc(x, y, 1, U_BULLET_OPERATOR)
                .endif
                msloop()
            .until 1
        .until [rdi].TOBJ.flag & _O_EVENT
        mov eax,KEY_SPACE
    .until 1
    mov esi,eax
    _setcursor(&cursor)
    mov eax,esi
    ret

dlradioevent endp

dlcheckevent proc uses rsi rdi

    local cursor:CURSOR
    local x,y

    _getcursor(&cursor)
    _cursoron()

    mov   rsi,tdialog
    movzx eax,[rsi].DOBJ.index
    imul  edi,eax,TOBJ
    add   rdi,[rsi].DOBJ.object
    movzx eax,[rsi].DOBJ.rc.x
    add   al,[rdi].TOBJ.rc.x
    inc   eax
    mov   x,eax
    mov   al,[rsi].DOBJ.rc.y
    add   al,[rdi].TOBJ.rc.y
    mov   y,eax
    _gotoxy(x, eax)

    .repeat
        .repeat
            mov esi,tgetevent()
            .if esi == MOUSECMD

                mousey()
                .break(1) .if eax != y
                mousex()
                mov edx,x
                dec edx
                .break(1) .if eax < edx
                add edx,2
                .break(1) .if eax > edx

            .elseif esi != KEY_SPACE

                .break(1)
            .endif

            xor [rdi].TOBJ.flag,_O_FLAGB
            mov eax,' '
            .if [rdi].TOBJ.flag & _O_FLAGB
                mov eax,'x'
            .endif
            scputc(x, y, 1, eax)
            msloop()
        .until [rdi].TOBJ.flag & _O_EVENT
        mov esi,KEY_SPACE
    .until 1
    _setcursor(&cursor)
    mov eax,esi
    ret

dlcheckevent endp

dlxcellevent proc uses rsi rdi rbx

    local xlbuf[MAXCOLS]:CHAR_INFO

    mov   rsi,tdialog
    movzx eax,[rsi].DOBJ.index
    imul  edi,eax,TOBJ
    add   rdi,[rsi].DOBJ.object

    .if [rsi].DOBJ.count

        _cursoroff()
    .endif

    .if [rdi].TOBJ.flag & _O_LLIST

        movzx eax,[rsi].DOBJ.index
        mov rdx,tdllist

        .if eax >= [rdx].LOBJ.dlgoff
            sub eax,[rdx].LOBJ.dlgoff
            .if eax < [rdx].LOBJ.numcel
                mov [rdx].LOBJ.celoff,eax
            .endif
        .endif
    .endif

    mov ebx,[rdi].TOBJ.rc
    add bx,word ptr [rsi].DOBJ.rc
    rcread(ebx, &xlbuf)
    mov al,at_background[B_Inverse]
    movzx ecx,[rdi].TOBJ.rc.col
    wcputbg(&xlbuf, ecx, eax)
    rcxchg(ebx, &xlbuf)

    .repeat

        tgetevent()
        .switch eax

          .case KEY_MOUSEUP
            mov eax,KEY_UP
            .if [rdi].TOBJ.flag & _O_LLIST

                PushEvent(eax)
                PushEvent(eax)
            .endif
            .endc

          .case KEY_MOUSEDN
            mov eax,KEY_DOWN
            .if [rdi].TOBJ.flag & _O_LLIST

                PushEvent(eax)
                PushEvent(eax)
            .endif
            .endc

          .case MOUSECMD

            mov edx,mousey()
            .ifd rcxyrow(ebx, mousex(), edx)

                mov al,[rdi].TOBJ.rc.col
                mov cl,bh
                mousewait(ebx, ecx, eax)

                movzx eax,[rdi].TOBJ.flag
                and eax,0x0F
                cmp eax,_O_XHTML
                mov eax,KEY_ENTER
                .ifnz

                    mov esi,10
                    .repeat
                        Sleep(16)
                        .break .ifd mousep()
                        dec esi
                    .untilz

                    .ifd mousep()

                        mov edx,mousey()
                        .continue(0) .ifd !rcxyrow(ebx, mousex(), edx)
                        mov eax,KEY_ENTER
                    .endif
                .endif
            .else
                mov eax,MOUSECMD
            .endif

          .default
            .continue(0) .if !eax
            .endc
        .endsw
    .until 1
    mov esi,eax
    rcwrite(ebx, &xlbuf)
    mov eax,esi
    ret

dlxcellevent endp

dlteditevent proc private uses rsi rbx

    mov   rdx,tdialog
    mov   si,[rdx+4]
    movzx eax,[rdx].DOBJ.index
    imul  ecx,eax,TOBJ
    add   rcx,[rdx].DOBJ.object
    mov   eax,[rcx].TOBJ.rc
    add   ax,si
    movzx ebx,[rcx].TOBJ.flag
    movzx edx,[rcx].TOBJ.count
    shl   edx,4
    dledit([rcx].TOBJ.data, eax, edx, ebx)
    ret

dlteditevent endp

dlmenusevent proc private uses rsi rdi rbx

    local cursor:CURSOR
    local xlbuf[MAXCOLS]:CHAR_INFO

    _getcursor(&cursor)
    _cursoroff()

    mov   rsi,tdialog
    movzx eax,[rsi].DOBJ.index
    imul  edi,eax,TOBJ
    add   rdi,[rsi].DOBJ.object

    .if [rdi].TOBJ.data

        mov al,at_background[B_Menus]
        or  al,at_foreground[F_KeyBar]
        shl eax,16
        mov al,' '
        mov ebx,_scrrow
        scputw(20, ebx, 60, eax)
        scputs(20, ebx, 0, 60, [rdi].TOBJ.data)
    .endif

    mov ebx,[rdi].TOBJ.rc
    add bx,word ptr [rsi].DOBJ.rc
    rcread(ebx, &xlbuf)
    movzx eax,at_background[B_InvMenus]
    movzx ecx,[rdi].TOBJ.rc.col
    wcputbg(&xlbuf, ecx, eax)
    rcxchg(ebx, &xlbuf)

    .ifd tgetevent() == KEY_MOUSEUP
        mov eax,KEY_UP
    .elseif eax == KEY_MOUSEDN
        mov eax,KEY_DOWN
    .endif
    mov esi,eax
    rcwrite(ebx, &xlbuf)
    _setcursor(&cursor)
    mov eax,esi
    ret

dlmenusevent endp

dlevent proc uses rsi rdi rbx dialog:PDOBJ

    local prevdlg:PDOBJ     ; init tdialog
    local cursor:CURSOR     ; init cursor
    local event, dlexit


    mov prevdlg,tdialog
    mov tdialog,dialog
    mov rbx,tdialog
    movzx esi,[rbx].DOBJ.flag

    .repeat

        .if !( esi & _D_ONSCR )

            .break .ifd !dlshow(dialog)
        .endif

        _getcursor(&cursor)
        _cursoroff()

        movzx eax,[rbx].DOBJ.count
        .if eax

            mov  al,[rbx].DOBJ.index
            imul eax,eax,TOBJ
            add  rax,[rbx].DOBJ.object

            .if [rax].TOBJ.flag & _O_DEACT

                NextItem()
            .endif
            mov eax,1
        .endif

        .if !eax
            .while 1
                tgetevent()
                test_event(eax, 0)
                mov eax,result
                .break .if eax == _C_ESCAPE
                .break .if eax == _C_RETURN
            .endw
        .else

            msloop()
            xor edi,edi

            .repeat
                xor eax,eax
                mov result,eax

                mov al,[rbx].DOBJ.index
                imul eax,eax,TOBJ
                add rax,[rbx].DOBJ.object

                .if [rax].TOBJ.flag & _O_EVENT

                    call [rax].TOBJ.tproc
                .else
                    mov al,[rax]
                    and eax,0x0F
                    .switch eax
                      .case _O_TBUTT
                      .case _O_PBUTT: dlpbuttevent(): .endc
                      .case _O_RBUTT: dlradioevent(): .endc
                      .case _O_CHBOX: dlcheckevent(): .endc
                      .case _O_XCELL: dlxcellevent(): .endc
                      .case _O_TEDIT: dlteditevent(): .endc
                      .case _O_MENUS: dlmenusevent(): .endc
                      .case _O_XHTML: dlxcellevent(): .endc
                      .default
                        mov eax,KEY_ESC
                        .endc
                    .endsw
                .endif

                mov dlexit,eax
                mov event,eax
                mov ecx,test_event(eax, 1)
                mov eax,result
                .if eax == _C_ESCAPE
                    mov event,0
                    .break
                .elseif eax == _C_RETURN
                    xor eax,eax

                    mov al,[rbx].DOBJ.index
                    imul eax,eax,TOBJ
                    add rax,[rbx].DOBJ.object

                    .if [rax].TOBJ.flag & _O_DEXIT

                        mov event,0
                    .else
                        mov rdx,tdialog
                        movzx eax,[rdx].DOBJ.index
                        inc eax
                        mov event,eax
                    .endif
                    .break
                .elseif ecx == _O_MENUS && (event == KEY_LEFT || event == KEY_RIGHT)
                    inc edi
                .endif
            .until edi
        .endif

        _setcursor(&cursor)
        mov eax,event
    .until 1

    mov edx,eax
    mov tdialog,prevdlg
    mov eax,edx
    mov ecx,dlexit
    ret

dlevent endp

dllevent proc uses rbx ldlg:PDOBJ, listp:PLOBJ

    mov rbx,tdllist
    mov tdllist,listp
    dlevent(ldlg)
    mov tdllist,rbx
    ret

dllevent endp

dlmodal proc uses rbx dobj:PDOBJ

    mov ebx,dlevent(dobj)
    dlclose(dobj)
    mov eax,ebx
    ret

dlmodal endp

dlmove proc uses rbx dobj:PDOBJ

    ldr rbx,dobj
    mov cx,[rbx].DOBJ.flag
    and ecx,_D_DMOVE or _D_DOPEN or _D_ONSCR
    xor eax,eax

    .if ( ecx == _D_DMOVE or _D_DOPEN or _D_ONSCR )

        .ifd mousep()

            movzx ecx,[rbx].DOBJ.flag
            rcmsmove(&[rbx].DOBJ.rc, [rbx].DOBJ.wp, ecx)
            mov eax,1
        .endif
    .endif
    ret

dlmove endp

dlscreen proc dobj:PDOBJ, attrib

    mov rdx,dobj
    xor eax,eax
    mov [rdx],eax
    mov eax,_scrcol ; adapt to current screen
    mov ah,byte ptr _scrrow
    inc ah
    shl eax,16
    mov [rdx].DOBJ.rc,eax

    .if rcopen(eax, _D_CLEAR or _D_BACKG, attrib, 0, 0)

        mov rdx,dobj
        mov [rdx].DOBJ.wp,rax
        mov [rdx].DOBJ.flag,_D_DOPEN
        mov rax,rdx
    .endif
    ret

dlscreen endp

scroll_delay proc

    tupdate()
    Sleep(2)
    ret

scroll_delay endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    assume rdx:PTEDIT

tidecx proc uses rcx ti:PTEDIT

    mov rdx,ti
    mov eax,[rdx].boffs
    add eax,[rdx].xoffs

    .ifnz
        mov ecx,[rdx].boffs
        mov eax,[rdx].xoffs
        .if eax
            dec eax
        .else
            dec ecx
        .endif
        mov [rdx].xoffs,eax
        mov [rdx].boffs,ecx
        mov eax,1
    .endif
    ret

tidecx endp

tiincx proc uses rbx ti:PTEDIT

    mov rdx,ti
    mov eax,[rdx].boffs
    add eax,[rdx].xoffs
    inc eax
    .if eax >= [rdx].bcol
        xor eax,eax
    .else
        mov ebx,[rdx].boffs
        mov eax,[rdx].xoffs
        inc eax
        .if eax >= [rdx].cols
            mov eax,[rdx].cols
            dec eax
            inc ebx
        .endif
        mov [rdx].xoffs,eax
        mov [rdx].boffs,ebx
        mov eax,1
    .endif
    ret

tiincx endp

tinocando proc private

    .if console & CON_UBEEP

        ;Beep(9, 1)
        MessageBeep(MB_ICONHAND)
    .endif
    mov eax,_TE_CMFAILED ; operation fail (end of line/buffer)
    ret

tinocando endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rsopen proc uses rsi rdi rbx idd:PIDD

   .new dlg:PDOBJ
   .new flags:int_t
   .new size:int_t
   .new count:int_t
   .new rsize:int_t
   .new dsize:int_t
   .new rc:TRECT

    ldr rbx,idd
    mov rc,[rbx].RIDD.rc

    movzx eax,[rbx].RIDD.rc.col  ; rc_rows * rc_cols
    mul [rbx].RIDD.rc.row
    shl eax,2       ; DWORD size
    mov edi,eax

    .if ( [rbx].RIDD.flag & _D_SHADE )

        movzx eax,[rbx].RIDD.rc.col
        movzx edx,[rbx].RIDD.rc.row
        lea eax,[rax+rdx*2-2]
        shl eax,2
        add edi,eax
    .endif
    mov rsize,edi

    movzx   eax,[rbx].RIDD.count
    mov     count,eax
    inc     eax
    imul    eax,eax,TOBJ
    mov     dsize,eax

    .for ( ecx = 0, eax = 0, rsi = &[rbx+RIDD] : ecx < count : ecx++, rsi+=ROBJ )

        movzx edx,[rsi].ROBJ.count
        add eax,edx
    .endf
    shl eax,4
    add eax,rsize
    add eax,dsize
    mov size,eax

    .if ( malloc(eax) == NULL )

        .return
    .endif

    mov dlg,rax
    mov rdi,rax
    mov ecx,size
    xor eax,eax
    rep stosb

    mov rdi,dlg
    mov eax,dword ptr [rbx]
    mov flags,eax
    or  eax,_D_SETRC
    mov [rdi],eax
    mov [rdi].DOBJ.rc,[rbx].RIDD.rc
    mov eax,dsize
    add rax,rdi
    mov [rdi].DOBJ.wp,rax
    mov edx,rsize
    add edx,dsize
    add rdx,rdi

    add rbx,RIDD
    add rdi,DOBJ

    .if ( count )

        mov [rdi-DOBJ].DOBJ.object,rdi

        .for ( ecx = 0 : ecx < count : ecx++, rbx+=ROBJ, rdi+=TOBJ )

            mov [rdi],size_t ptr [rbx]
ifndef _WIN64
            mov [rdi].TOBJ.rc,[rbx].ROBJ.rc
endif
            movzx eax,[rdi].TOBJ.count
            .if ( eax )

                mov [rdi].TOBJ.data,rdx
                shl eax,4
                add rdx,rax
            .endif
        .endf
    .endif
    rcunzip(rc, rdi, rbx)
    .if ( flags & _D_RESAT )

        rcunzipat(rc, rdi)
    .endif
    mov rax,dlg
    ret

rsopen endp

rsevent proc uses rbx robj:PIDD, dobj:PDOBJ

    ldr rbx,dobj

    dlevent(rbx)
    mov edx,[rbx].DOBJ.rc
    mov rcx,robj
    mov [rcx].RIDD.rc,edx
    ret

rsevent endp

rsmodal proc uses rbx robj:PIDD

    ldr rbx,robj
    .if rsopen(rbx)

        xchg rbx,rax
        rsevent(rax, rbx)
        xchg rbx,rax
        dlclose(rax)
        mov eax,ebx
    .endif
    ret

rsmodal endp

rsreload proc uses rsi rdi rbx robj:PIDD, dobj:PDOBJ

    ldr rbx,dobj
    mov eax,[rbx]
    and eax,_D_DOPEN
    .ifnz

        mov     esi,dlhide(rbx)
        movzx   edi,[rbx].DOBJ.count
        inc     edi
        lea     edi,[rdi*8]
        add     rdi,robj

        rcunzip([rbx].DOBJ.rc, [rbx].DOBJ.wp, rdi)
        .if ( [rbx].DOBJ.flag & _D_RESAT )

            rcunzipat([rbx].DOBJ.rc, [rbx].DOBJ.wp)
        .endif
        dlinit(rbx)
        .if esi
            dlshow(rbx)
        .endif
    .endif
    ret

rsreload endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PushEvent proc Event:dword

    mov eax,Event
    mov ecx,keybcount
    .if ecx < MAXKEYSTACK-1

        inc keybcount
        lea rdx,keybstack
        mov [rdx+rcx*4],eax
    .endif
    ret

PushEvent endp

PopEvent proc private

    xor eax,eax
    .if eax != keybcount

        dec keybcount
        mov eax,keybcount
        lea rdx,keybstack
        mov eax,[rdx+rax*4]
    .endif
    mov edx,_shift
    ret

PopEvent endp

    assume rbx:ptr INPUT_RECORD

UpdateKeyEvent proc private uses rsi rbx pInput:ptr INPUT_RECORD

    xor esi,esi
    mov rbx,pInput
    movzx eax,[rbx].Event.KeyEvent.wVirtualKeyCode
    mov keybcode,al
    mov al,byte ptr [rbx].Event.KeyEvent.wVirtualScanCode
    movzx ecx,al
    mov al,byte ptr [rbx].Event.KeyEvent.uChar.AsciiChar
    mov keybchar,al
    mov edx,_shift
    mov eax,[rbx].Event.KeyEvent.dwControlKeyState
    and edx,not (SHIFT_SCROLL or SHIFT_NUMLOCK or SHIFT_CAPSLOCK \
            or SHIFT_ENHANCED or SHIFT_KEYSPRESSED)

    .if eax & SHIFT_PRESSED
        or edx,SHIFT_KEYSPRESSED
    .else
        and edx,not (SHIFT_LEFT or SHIFT_RIGHT)
    .endif
    .if eax & SCROLLLOCK_ON
        or edx,SHIFT_SCROLL
    .endif
    .if eax & NUMLOCK_ON
        or edx,SHIFT_NUMLOCK
    .endif
    .if eax & CAPSLOCK_ON
        or edx,SHIFT_CAPSLOCK
    .endif
    .if eax & ENHANCED_KEY
        or edx,SHIFT_ENHANCED
    .endif
    xchg edx,eax

    .if [rbx].Event.KeyEvent.bKeyDown

        mov keybstate,1
        or  eax,SHIFT_RELEASEKEY

        .switch ecx
          .case 2Ah
            .if eax & SHIFT_KEYSPRESSED
                or eax,SHIFT_LEFT
            .endif
            .endc
          .case 36h
            .if eax & SHIFT_KEYSPRESSED
                or eax,SHIFT_RIGHT
            .endif
            .endc
          .case 38h
            .if edx & RIGHT_ALT_PRESSED
                or eax,SHIFT_ALT
            .else
                or eax,SHIFT_ALTLEFT or SHIFT_ALT
            .endif
            .endc
          .case 1Dh
            .if edx & RIGHT_CTRL_PRESSED
                or eax,SHIFT_CTRL
            .else
                or eax,SHIFT_CTRLLEFT or SHIFT_CTRL
            .endif
            .endc
          .case 46h
            or eax,SHIFT_SCROLLKEY
            .endc
          .case 3Ah
            or eax,SHIFT_CAPSLOCKKEY
            .endc
          .case 45h
            or eax,SHIFT_NUMLOCKKEY
            .endc
          .case 57h
            mov esi,8500h   ; F11
            .endc
          .case 58h
            mov esi,8600h   ; F12
            .endc
          .default
            .if cl == 52h && keybcode == 2Dh
                or  eax,SHIFT_INSERTKEY
                xor eax,SHIFT_INSERTSTATE
                mov esi,5200h
            .else
                mov dl,keybchar
                mov dh,cl
                and edx,0000FFFFh
                mov esi,edx
            .endif
        .endsw
    .else
        mov keybstate,0
        and eax,not SHIFT_RELEASEKEY
        .switch ecx
          .case 2Ah
            .if eax & SHIFT_KEYSPRESSED
                and eax,not SHIFT_LEFT
            .endif
            .endc
          .case 36h
            .if eax & SHIFT_KEYSPRESSED
                and eax,not SHIFT_RIGHT
            .endif
            .endc
          .case 38h
            and eax,not (SHIFT_ALT or SHIFT_ALTLEFT)
            .endc
          .case 1Dh
            and eax,not (SHIFT_CTRL or SHIFT_CTRLLEFT)
            .endc
          .case 46h
            and eax,not SHIFT_SCROLLKEY
            .endc
          .case 3Ah
            and eax,not SHIFT_CAPSLOCKKEY
            .endc
          .case 45h
            and eax,not SHIFT_NUMLOCKKEY
            .endc
          .case 52h
            and eax,not SHIFT_INSERTKEY
        .endsw
    .endif

    mov _shift,eax
    mov eax,esi
    ret

UpdateKeyEvent endp

UpdateMouseEvent proc private uses rbx pInput:ptr INPUT_RECORD

    mov rbx,pInput
    movzx eax,[rbx].Event.MouseEvent.dwMousePosition.X
    mov keybmouse_x,eax
    mov ax,[rbx].Event.MouseEvent.dwMousePosition.Y
    mov keybmouse_y,eax
    mov edx,_shift
    and edx,not SHIFT_MOUSEFLAGS
    mov eax,[rbx].Event.MouseEvent.dwButtonState
    mov ecx,eax
    and eax,3h
    shl eax,16
    or  eax,edx
    mov edx,[rbx].Event.MouseEvent.dwEventFlags
    mov ebx,eax
    .if edx == MOUSE_WHEELED
        mov eax,KEY_MOUSEUP
        .ifs ecx <= 0
            mov eax,KEY_MOUSEDN
        .endif
        PushEvent(eax)
    .endif
    mov _shift,ebx
    ret

UpdateMouseEvent endp

parseshift proc private uses rsi

    lea rsi,scancode
    .while 1

        lodsb
        .break .if !al

        .if ah == al

            lea rax,scancode
            sub rsi,rax
            movzx eax,byte ptr [rsi+rdx-1]
            shl eax,8
           .break
        .endif
    .endw
    ret

parseshift endp

ReadEvent proc private uses rbx rdi rsi rcx

  local Count:dword, Input:INPUT_RECORD
  local buffer[256]:char_t

    xor edi,edi
    lea rbx,Input

    .ifd GetNumberOfConsoleInputEvents(_coninpfh, &Count)

        mov esi,Count
        .while esi

            ReadConsoleInput(_coninpfh, rbx, 1, &Count)
            .break .if !Count

            movzx eax,[rbx].EventType
            .switch eax
            .case KEY_EVENT
                .if ( _focus )
                    .ifd UpdateKeyEvent(rbx)
                        mov edi,eax
                    .endif
                .endif
                .endc
            .case MOUSE_EVENT
                .if ( _focus )
                    UpdateMouseEvent(rbx)
                .endif
               .endc
            .case WINDOW_BUFFER_SIZE_EVENT
                .if _scbuffersize
                    dec _scbuffersize
                .else
                    UpdateWindowSize(Input.Event.WindowBufferSizeEvent.dwSize)
                .endif
               .endc
            .case FOCUS_EVENT
                mov _focus,Input.Event.FocusEvent.bSetFocus
               .endc
            .endsw
            dec esi
        .endw
    .endif
    .if ( _focus == 0 )
        .return( 0 )
    .endif
    mov edx,_shift
    mov eax,edi
    .if edx & SHIFT_ALTLEFT
        mov al,0
    .endif

    .if ah && !al
        .if edx & SHIFT_RIGHT or SHIFT_LEFT
            lea rdx,scanshift
            parseshift()
        .elseif edx & SHIFT_CTRL or SHIFT_CTRLLEFT
            lea rdx,scanctrl
            parseshift()
        .elseif edx & SHIFT_ALT or SHIFT_ALTLEFT
            lea rdx,scanalt
            parseshift()
        .endif
    .elseif ah
        .if edx & SHIFT_ALT or SHIFT_ALTLEFT
            mov ah,0
        .endif
    .endif
    .if eax
        PushEvent(eax)
    .endif
    ret

ReadEvent endp

    assume rbx:nothing

getkey proc

    ReadEvent()
    PopEvent()
    ret

getkey endp

getevent proc private

    .while !getkey()

        .break .ifd tdidle()
        .if _shift & SHIFT_MOUSEFLAGS
            .ifd mousep()
                mov eax,MOUSECMD
                .break
            .endif
        .endif
    .endw
    ret

getevent endp


mousex proc

    mov eax,keybmouse_x
    ret

mousex endp

mousey proc

    mov eax,keybmouse_y
    ret

mousey endp

mousep proc uses rcx rdx

    ReadEvent()
    mov eax,_shift
    shr eax,16
    and eax,3
    ret

mousep endp

mousewait proc x, y, l
    mov edx,x
    add edx,l
    .whiled mousep()
        .break .ifd mousey() != y
        .break .ifd mousex() < x
        .break .if eax > edx
    .endw
    ret
mousewait endp

msloop proc

    .repeat
    .until !mousep()
    ret

msloop endp

SetKeyState proc uses rsi rdi rax

    mov rdi,keyshift
    mov esi,[rdi]
    and esi,not 0x01FF030F

    GetKeyState(VK_LSHIFT)
    .if ah & 80h
        or esi,SHIFT_LEFT or SHIFT_KEYSPRESSED
    .endif
    GetKeyState(VK_RSHIFT)
    .if ah & 80h
        or esi,SHIFT_RIGHT or SHIFT_KEYSPRESSED
    .endif
    GetKeyState(VK_LCONTROL)
    .if ah & 80h
        or esi,SHIFT_CTRLLEFT
    .endif
    GetKeyState(VK_RCONTROL)
    .if ah & 80h
        or esi,SHIFT_CTRL
    .endif
    mov [rdi],esi
    ret

SetKeyState endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConsolePush proc uses rbx

  local ci:CONSOLE_SCREEN_BUFFER_INFO

    .ifd GetConsoleScreenBufferInfo(_confh, &ci)

        mov eax,ci.dwSize
        movzx ecx,ax
        mov _scrcol,ecx
        shr eax,16
        dec eax
        mov _scrrow,eax
        _getcursor(&console_cu)
        lea rbx,console_dl
        free([rbx].DOBJ.wp)
        mov eax,_scrrow
        mov ah,byte ptr _scrcol
        inc al
        mov [rbx].DOBJ.wp,rcpush(eax)
        mov [rbx].DOBJ.flag,_D_DOPEN
        mov eax,_scrrow
        inc eax
        mov [rbx].DOBJ.rc.row,al
        mov eax,_scrcol
        mov [rbx].DOBJ.rc.col,al
    .endif
    ret

ConsolePush endp

conssetl proc line:COORD ; min or max

  local bz:COORD
  local rc:SMALL_RECT
  local ci:CONSOLE_SCREEN_BUFFER_INFO
  local x:dword
  local y:dword

    .ifd !GetConsoleScreenBufferInfo(_confh, &ci)

        .return( 0 )
    .endif

    mov rc.Top,0
    mov rc.Left,0
    mov ax,line.X
    mov dx,line.Y
    mov bz.X,ax
    mov bz.Y,dx
    dec ax
    dec dx
    mov rc.Right,ax
    mov rc.Bottom,dx

    mov dx,ci.srWindow.Bottom
    sub dx,ci.srWindow.Top
    mov ax,ci.srWindow.Right
    sub ax,ci.srWindow.Left
    .if ( ax == rc.Right && dx == rc.Bottom )
        .return( 0 )
    .endif

    mov x,0
    mov y,0
    mov ax,line.X
    .if ( ax < _scrmax.X )
        mov x,_scrrc.left
        mov y,_scrrc.top
    .endif
    SetWindowPos(GetConsoleWindow(),0,x,y,0,0,SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOZORDER)

    _wherex()
    .if ( dx >= bz.Y )
        SetConsoleCursorPosition(_confh, 0)
    .endif
    inc _scbuffersize
    SetConsoleWindowInfo(_confh, 1, &rc)
    SetConsoleScreenBufferSize(_confh, bz)
    SetConsoleWindowInfo(_confh, 1, &rc)

    .ifd GetConsoleScreenBufferInfo(_confh, &ci)

        movzx   eax,ci.srWindow.Right
        sub     ax,ci.srWindow.Left
        inc     eax
        mov     _scrcol,eax
        movzx   eax,ci.srWindow.Bottom
        sub     ax,ci.srWindow.Top
        mov     _scrrow,eax
    .endif
    ret

conssetl endp

consuser proc

  local cursor:CURSOR

    _getcursor(&cursor)
    _setcursor(&console_cu)
    dlshow(&console_dl)
    .while !getkey()
    .endw
    dlhide(&console_dl)
    _setcursor(&cursor)
    xor eax,eax
    ret

consuser endp

ConsoleIdle proc

    .if console & CON_SLEEP

        Sleep(CON_SLEEP_TIME)

ifndef DEBUGX
        .if ( _focus == 0 )

            mov rax,keyshift
            and dword ptr [rax],not 0x00FF030F

            .while ( _focus == 0 )

                ReadEvent()
                Sleep(CON_SLEEP_TIME * 10)
               .break .ifd tupdate()
            .endw
        .endif
endif
    .endif

    tupdate()
    ret

ConsoleIdle endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

tupdtime proc uses rsi rdi rbx

  local ts:SYSTEMTIME
  local buf[64]:byte

    mov ebx,console
    xor eax,eax

    .if ebx & CON_UTIME or CON_UDATE

        mov buf,al
        mov ecx,sizeof(SYSTEMTIME)/4
        lea rdi,ts
        rep stosd
        mov edi,ebx
        GetLocalTime(&ts)

        mov eax,edi
        and eax,CON_UTIME or CON_LTIME
        cmp eax,CON_UTIME or CON_LTIME
        movzx eax,ts.wSecond
        .ifnz
            movzx eax,ts.wMinute
        .endif

        .if eax != time_id

            mov time_id,eax
            mov ebx,_scrcol
            inc ebx

            .if edi & CON_UTIME

                SystemTimeToStringA(&buf, &ts)
                .if !( edi & CON_LTIME )
                    mov buf[5],0
                    sub ebx,6
                .else
                    sub ebx,9
                .endif
                scputs(ebx, 0, 0, 0, &buf)
            .endif

            .if edi & CON_UDATE

                SystemDateToStringA(&buf, &ts)
                .if !( edi & CON_LDATE )
                    lea rsi,buf
                    mov al,[rsi+2]
                    .if ( al >= '0' && al <= '9' )
                        add rsi,2
                    .else
                        mov eax,[rsi+6]
                        shr eax,16
                        mov [rsi+6],eax
                    .endif
                    sub ebx,9
                .else
                    sub ebx,11
                .endif
                scputs(ebx, 0, 0, 0, &buf)
            .endif
        .endif
    .endif
    ret

tupdtime endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define MAXLINES 17

center_text proc private

    .if byte ptr [rdi]
        mul ecx
        lea eax,[rax*4+4*4]
        add rbx,rax
        sub ecx,8
        wcenter(rbx, ecx, rdi)
    .endif
    ret

center_text endp

msgbox proc private uses rsi rdi rbx dname:LPSTR, flag, string:LPSTR

  local dobj:DOBJ, tobj:TOBJ, cols:dword, lcnt:dword, foregr:byte, backgr:byte

    strlen(dname)
    xor esi,esi
    mov ebx,eax
    .if !strchr(string, 10)

        .ifd strlen(string) > ebx
            mov ebx,eax
        .endif
    .endif

    mov backgr,at_background[B_Title]
    mov foregr,at_background[F_Title]
    mov rdi,string
    .if byte ptr [rdi]

        .repeat

            .break .if !strchr( rdi, 10 )

            mov rdx,rax
            sub rdx,rdi
            .if edx >= ebx
                mov ebx,edx
            .endif
            inc esi
            inc rax
            mov rdi,rax
        .until esi == MAXLINES
    .endif

    .ifd strlen(rdi) >= ebx
        mov ebx,eax
    .endif

    mov dl,2
    mov dh,76
    .if bl && bl < 70
        mov dh,bl
        add dh,8
        mov dl,80
        sub dl,dh
        shr dl,1
    .endif
    .if dh < 40
        mov dx,2814h
    .endif

    mov eax,flag
    mov dobj.flag,ax
    mov dobj.rc.x,dl
    mov dobj.rc.y,7
    mov eax,esi
    add al,6
    mov dobj.rc.row,al
    mov dobj.rc.col,dh
    mov dobj.count,1
    mov dobj.index,0
    add al,7

    .if eax > _scrrow
        mov dobj.rc.y,1
    .endif

    lea rax,tobj
    mov dobj.object,rax
    mov tobj.flag,_O_PBUTT
    mov al,dh
    shr al,1
    sub al,3
    mov tobj.rc.x,al
    mov eax,esi
    add al,4
    mov tobj.rc.y,al
    mov tobj.rc.row,1
    mov tobj.rc.col,6
    mov tobj.ascii,'O'
    mov al,at_background[B_Dialog]
    or  al,at_foreground[F_Dialog]

    .if dobj.flag & _D_STERR
        mov at_background[B_Title],70h
        mov at_foreground[F_Title],00h
        mov al,at_background[B_Error]
        or  al,7
        or  tobj.flag,_O_DEXIT
    .endif

    mov dl,al
    .if dlopen(&dobj, edx, dname)

        mov rdi,string
        mov rsi,rdi
        movzx eax,dobj.rc.col
        mov cols,eax
        mov lcnt,2

        .repeat

            .break .if !byte ptr [rsi]
            strchr(rdi, 10)
            mov rsi,rax
            .break .if !rax
            mov byte ptr [rsi],0
            inc rsi
            mov ecx,cols
            mov eax,lcnt
            mov rbx,dobj.wp
            center_text()
            mov rdi,rsi
            inc lcnt
        .until lcnt == MAXLINES+2

        rcbprc(dword ptr tobj.rc, dobj.wp, cols)
        movzx ecx,tobj.rc.col
        wcpbutt(rax, cols, ecx, "&Ok")

        mov at_background[B_Title],backgr
        mov at_background[F_Title],foregr
        mov ecx,cols
        mov eax,lcnt
        mov rbx,dobj.wp
        center_text()
        dlmodal(&dobj)
    .endif
    ret

msgbox endp

ermsg proc __Cdecl wtitle:LPSTR, format:LPSTR, argptr:VARARG

    vsprintf( &_bufin, format, &argptr )
    mov rax,wtitle
    .if !rax
        lea rax,@CStr("Error")
    .endif
    msgbox(rax, _D_STDERR, &_bufin)
    xor eax,eax
    ret

ermsg endp

stdmsg proc __Cdecl wtitle:LPSTR, format:LPSTR, argptr:VARARG

    vsprintf( &_bufin, format, &argptr )
    msgbox(wtitle, _D_STDDLG, &_bufin)
    xor eax,eax
    ret

stdmsg endp

notsup proc

    ermsg(0, _sys_err_msg(ENOSYS))
    ret

notsup endp

errnomsg proc etitle:LPSTR, format:LPSTR, file:LPSTR

    mov rcx,_sys_err_msg(_get_errno(NULL))
    ermsg(etitle, format, file, rcx)
    mov eax,-1
    ret

errnomsg endp

eropen proc file:LPSTR

    errnomsg("Error open file", "Can't open the file:\n%s\n\n%s", file)
    ret

eropen endp

erdelete proc file:LPSTR

    errnomsg("Error delete", "Can't delete the file:\n%s\n\n%s", file)
    ret

erdelete endp

ermkdir proc directory:LPSTR

    errnomsg("Make directory", "Can't create the directory:\n%s\n\n%s", directory)
    ret

ermkdir endp

notfoundmsg proc uses rbx

    lea rbx,@CStr("Search string not found: '%s'")
    mov byte ptr [rbx+24],' '

    .ifd ( strlen(&searchstring) > 28 )

        mov byte ptr [rbx+24],10
    .endif
    stdmsg("Search", rbx, &searchstring)
    ret

notfoundmsg endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

tgetline proc uses rsi rdi dlgtitle:LPSTR, buffer:LPSTR, line_size, buffer_size

  local dobj:DOBJ, rc:TRECT

    mov dobj.flag,_D_STDDLG
    mov dobj.rc.row,5
    mov dobj.rc.y,5
    mov al,byte ptr line_size
    mov rc.col,al
    add al,8
    mov dobj.rc.col,al
    shr al,1
    mov ah,40
    sub ah,al
    mov dobj.rc.x,ah
    mov rc.row,1
    mov rc.x,4
    mov rc.y,2
    mov dl,at_background[B_Dialog]
    or  dl,at_foreground[F_Dialog]

    .if dlopen(&dobj, edx, dlgtitle)

        movzx eax,dobj.rc.col
        mov   rcx,rcbprc(rc, dobj.wp, eax)
        movzx edx,rc.col
        wcputa(rcx, edx, 0x07)

        dlshow(&dobj)
        msloop()

        xor eax,eax
        xor esi,esi
        xor edi,edi

        .while esi != KEY_ESC

            mov eax,rc
            add ax,word ptr dobj.rc
            mov ecx,buffer_size
            xor edx,edx

            .if ch & 80h
                mov edx,_O_DTEXT
                and ecx,7FFFh
            .endif

            mov esi,dledit(buffer, eax, ecx, edx)

            .if eax == KEY_ENTER || eax == KEY_KPENTER

                inc edi
                .break
            .endif

            .if eax == MOUSECMD

                .break .ifd !rcxyrow(dobj.rc, keybmouse_x, keybmouse_y)

                .if eax == 1

                    dlmove(&dobj)
                .endif
            .endif
        .endw
        dlclose(&dobj)
    .endif
    mov eax,edi
    ret

tgetline endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


__initcon proc private

   .new ci:CONSOLE_SCREEN_BUFFER_INFO
   .new size:COORD

    mov tgetevent,&getevent
    mov _consolecp,GetConsoleCP()

    GetConsoleMode(_coninpfh, &OldConsoleMode)
    GetWindowRect(GetConsoleWindow(), &_scrrc)

    mov eax,ENABLE_WINDOW_INPUT
    .if console & CON_MOUSE
        or eax,ENABLE_MOUSE_INPUT
    .endif
    SetConsoleMode(_coninpfh, eax)
    FlushConsoleInputBuffer(_coninpfh)

    .ifd GetConsoleScreenBufferInfo(_confh, &ci)

        mov eax,GetLargestConsoleWindowSize(_confh)
        and eax,-2
        .if ax > MAXCOLS
            mov ax,MAXCOLS
        .endif
        mov _scrmax,eax
        .if _scrmax.Y > MAXROWS
            mov _scrmax.Y,MAXROWS
        .endif

        movzx eax,ci.srWindow.Right
        sub ax,ci.srWindow.Left
        inc eax
        and eax,-2
        .if eax > MAXCOLS
            mov eax,MAXCOLS
        .elseif eax < MINCOLS
            mov eax,MINCOLS
        .endif
        mov _scrcol,eax
        mov size.X,ax

        movzx eax,ci.srWindow.Bottom
        sub ax,ci.srWindow.Top
        .if eax > MAXROWS
            mov eax,MAXROWS
        .elseif eax < MINROWS-1
            mov eax,MINROWS-1
        .endif
        mov _scrrow,eax
        inc eax
        mov size.Y,ax
        dec eax
        movzx edx,size.X
        dec edx
        mov ci.srWindow.Top,0
        mov ci.srWindow.Left,0
        mov ci.srWindow.Right,dx
        mov ci.srWindow.Bottom,ax
        SetConsoleWindowInfo(_confh, 1, &ci.srWindow)
        _wherex()
        .if ( dx >= size.Y )
            SetConsoleCursorPosition(_confh, 0)
        .endif
        inc _scbuffersize
        SetConsoleWindowInfo(_confh, 1, &ci.srWindow)
        SetConsoleScreenBufferSize(_confh, size)
        SetConsoleWindowInfo(_confh, 1, &ci.srWindow)
    .endif
    ret

__initcon endp

__exitcon proc private

    SetConsoleMode(_coninpfh, OldConsoleMode)
    ret

__exitcon endp

.pragma init(__initcon, 22)
.pragma exit(__exitcon, 9)

    end
