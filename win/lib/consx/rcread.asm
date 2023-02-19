; RCREAD.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include consx.inc
include malloc.inc

    .code
if 0
rcascii proc

    and eax,0xFFFF
    .switch pascal eax
    .case 0x2500 : mov ax,'Ä'
    .case 0x2502 : mov ax,'³'
    .case 0x250C : mov ax,'Ú'
    .case 0x2510 : mov ax,'¿'
    .case 0x2514 : mov ax,'À'
    .case 0x2518 : mov ax,'Ù'
    .case 0x251C : mov ax,'Ã'
    .case 0x2524 : mov ax,'´'
    .case 0x252C : mov ax,'Â'
    .case 0x2534 : mov ax,'Á'
    .case 0x253C : mov ax,'Å'
    .case 0x2550 : mov ax,'Í'
    .case 0x2551 : mov ax,'º'
    .case 0x2554 : mov ax,'É'
    .case 0x2557 : mov ax,'»'
    .case 0x255A : mov ax,'È'
    .case 0x255D : mov ax,'¼'
    .case 0x2563 : mov ax,'¹'
    .case 0x2580 : mov ax,'ß'
    .case 0x2584 : mov ax,'Ü'
    .case 0x2588 : mov ax,'Û'
    .case 0x2593 : mov ax,'²'
    .case 0x2592 : mov ax,'±'
    .case 0x2591 : mov ax,'°'
    .case 0x00BB : mov ax,'¯' ; 226B
    .case 0x2022 : mov ax,0xF9 ; bullet
    .case 0x25BA : mov ax,0x10 ; triagrt
    .case 0x25C4 : mov ax,0x11 ; triaglf
    .case 0x25BC : mov ax,0x1F ; triagdn
    .case 0x00B7 : mov ax,0xFA ; middle dot
    .endsw
    ret

rcascii endp
endif
    option cstack:on

rcreadc proc uses ebx esi edi buf:PVOID, bsize, pRrect:PVOID

  local bz:COORD, rc:SMALL_RECT

    mov eax,bsize
    mov bz,eax
    mov edx,pRrect
    mov eax,dword ptr [edx]
    mov dword ptr rc,eax
    mov eax,dword ptr [edx+4]
    mov dword ptr rc+4,eax

    .if !ReadConsoleOutput(hStdOutput, buf, bz, 0, &rc)

        mov     ax,rc.Top
        mov     rc.Bottom,ax
        mov     edi,buf
        movzx   ebx,bz.y
        mov     bz.y,1
        movzx   esi,bz.x
        shl     esi,2

        .repeat
            .break .if !ReadConsoleOutput(hStdOutput, edi, bz, 0, &rc)
            inc rc.Bottom
            inc rc.Top
            add edi,esi
            dec ebx
        .until !ebx

        xor eax,eax
        .if !ebx
            inc eax
        .endif
    .endif
    ret
rcreadc endp

rcread  proc uses ebx esi edi rc, wc:PVOID

  local col,buf
  local bz:COORD
  local rect:SMALL_RECT

    movzx   eax,rc.S_RECT.rc_col
    mov     col,eax
    mov     bz.x,ax
    movzx   eax,rc.S_RECT.rc_row
    mov     bz.y,ax
    mov     ebx,eax
    movzx   eax,rc.S_RECT.rc_y
    mov     rect.Top,ax
    mov     al,rc.S_RECT.rc_x
    mov     rect.Left,ax
    mov     eax,ebx
    add     ax,rect.Top
    dec     eax
    mov     rect.Bottom,ax
    mov     eax,col
    add     ax,rect.Left
    dec     eax
    mov     rect.Right,ax
    mov     eax,ebx
    mul     col
    shl     eax,2
    mov     buf,alloca(eax)

    .if rcreadc(buf, bz, &rect)

        mov esi,buf
        mov edi,wc
        .repeat
            mov ecx,col
            .repeat
                lodsw
                ;rcascii()
                stosb
                lodsw
                stosb
            .untilcxz
            dec ebx
        .until !ebx

        inc ebx
        mov eax,ebx
    .endif
    ret

rcread endp

    END
