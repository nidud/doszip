; RCWRITE.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include consx.inc
include malloc.inc

    .code

rcunicode proc

    and eax,0xFF
    .switch pascal eax
    .case 'Ä' : mov ax,0x2500
    .case '³' : mov ax,0x2502
    .case 'Ú' : mov ax,0x250C
    .case '¿' : mov ax,0x2510
    .case 'À' : mov ax,0x2514
    .case 'Ù' : mov ax,0x2518
    .case 'Ã' : mov ax,0x251C
    .case '´' : mov ax,0x2524
    .case 'Â' : mov ax,0x252C
    .case 'Á' : mov ax,0x2534
    .case 'Å' : mov ax,0x253C
    .case 'Í' : mov ax,0x2550
    .case 'º' : mov ax,0x2551
    .case 'É' : mov ax,0x2554
    .case '»' : mov ax,0x2557
    .case 'È' : mov ax,0x255A
    .case '¼' : mov ax,0x255D
    .case '¹' : mov ax,0x2563
    .case 'ß' : mov ax,0x2580
    .case 'Ü' : mov ax,0x2584
    .case 'Û' : mov ax,0x2588
    .case '²' : mov ax,0x2593
    .case '±' : mov ax,0x2592
    .case '°' : mov ax,0x2591
    .case '¯' : mov ax,0x00BB ; 226B
    .case 0xF9: mov ax,0x2022 ; bullet
    .case 0x10: mov ax,0x25BA ; triagrt
    .case 0x11: mov ax,0x25C4 ; triaglf
    .case 0x1F: mov ax,0x25BC ; triagdn
    .case 0xFA: mov ax,0x00B7 ; middle dot
    .endsw
    ret

rcunicode endp

rcwrite proc uses esi edi ebx rc, wc:PVOID

  local y,col,row
  local bz:COORD, rect:SMALL_RECT, lbuf[TIMAXSCRLINE]:CHAR_INFO

    movzx   eax,rc.S_RECT.rc_col
    mov     col,eax
    mov     bz.x,ax
    mov     bz.y,1
    movzx   eax,rc.S_RECT.rc_row
    mov     row,eax
    movzx   eax,rc.S_RECT.rc_x
    mov     rect.Left,ax
    add     eax,col
    dec     eax
    mov     rect.Right,ax
    movzx   eax,rc.S_RECT.rc_y
    mov     y,eax
    lea     edi,lbuf
    xor     eax,eax
    mov     ecx,col
    rep     stosd
    mov     esi,wc
    mov     ebx,row

    .repeat
        lea edi,lbuf
        mov ecx,col
        .repeat
            mov ax,[esi]
            add esi,2
            mov [edi+2],ah
            rcunicode()
            mov [edi],ax
            add edi,CHAR_INFO
        .untilcxz
        mov eax,y
        add eax,row
        sub eax,ebx
        mov rect.Top,ax
        mov rect.Bottom,ax
        .break .if !WriteConsoleOutputW(hStdOutput, &lbuf, bz, 0, &rect)
        dec ebx
    .untilz
    ret

rcwrite endp

    option cstack:on

rcxchg proc uses esi edi ebx ecx rc, wc:PVOID

  local y, col, row, tmp
  local bz:COORD, rect:SMALL_RECT, lbuf[TIMAXSCRLINE]:CHAR_INFO

    movzx   eax,rc.S_RECT.rc_col
    mov     col,eax
    mov     bz.x,ax
    mov     al,rc.S_RECT.rc_row
    mov     row,eax
    mov     bz.y,ax
    mov     al,rc.S_RECT.rc_x
    mov     rect.Left,ax
    add     eax,col
    dec     eax
    mov     rect.Right,ax
    movzx   eax,rc.S_RECT.rc_y
    mov     y,eax
    mov     rect.Top,ax
    add     eax,row
    dec     eax
    mov     rect.Bottom,ax
    mov     eax,row
    mul     col
    shl     eax,2
    mov     tmp,alloca(eax)

    .repeat

        .break .if !rcreadc(tmp, bz, &rect)

        lea edi,lbuf
        xor eax,eax
        mov ecx,col
        rep stosd
        mov esi,wc
        mov ebx,row
        mov bz.y,1

        .repeat

            lea edi,lbuf
            mov ecx,col
            .repeat
                mov ax,[esi]
                mov [edi+2],ah
                rcunicode()
                mov [edi],ax
                add esi,2
                add edi,CHAR_INFO
            .untilcxz
            mov eax,y
            add eax,row
            sub eax,ebx
            mov rect.Top,ax
            mov rect.Bottom,ax
            .break .if !WriteConsoleOutputW(hStdOutput, &lbuf, bz, 0, &rect)
            dec ebx
        .untilz

        mov esi,tmp
        mov edi,wc
        mov ebx,row
        .repeat
            mov ecx,col
            .repeat
                mov al,[esi]
                mov ah,[esi+2]
                mov [edi],ax
                add edi,2
                add esi,4
            .untilcxz
            dec ebx
        .untilz

        mov eax,ebx
        inc eax
    .until 1
    ret

rcxchg endp

    END
