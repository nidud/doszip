; SCPUTWS.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include consx.inc
include malloc.inc

    .code

scputws proc uses esi edi ecx edx x, y, l, wp:PVOID

  local rect:SMALL_RECT
  local lbuf[TIMAXSCRLINE]:CHAR_INFO

    mov esi,wp
    lea edi,lbuf
    mov ecx,l
    .ifs ecx < 0
        not ecx
    .endif

    .repeat
        lodsb
        rcunicode()
        stosw
        xor eax,eax
        lodsb
        stosw
    .untilcxz
    free(wp)
    movzx eax,byte ptr x
    movzx edx,byte ptr y
    mov rect.Top,dx
    mov rect.Left,ax
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
    mov rect.Right,ax
    mov rect.Bottom,dx
    WriteConsoleOutputW(hStdOutput, &lbuf, ecx, 0, &rect)
    ret

scputws endp

    END
