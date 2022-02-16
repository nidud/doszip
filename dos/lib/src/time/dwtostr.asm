; DWTOSTR.ASM--
; Copyright (C) 2015 Doszip Developers

include time.inc

.code

dwtostr PROC _CType PUBLIC USES bx cx buf:DWORD, date:size_t

    mov ax,date
    les bx,buf
    dwexpand()
    .if dos_dateformat == DFORMAT_JAPAN
        xchg ax,cx ; yy/mm/dd
    .elseif dos_dateformat == DFORMAT_USA
        xchg ax,dx ; mm/dd/yy
    .endif
    putedxal()
    mov al,date_separator
    mov es:[bx],al
    inc bx
    mov ax,dx
    putedxal()
    mov al,date_separator
    mov es:[bx],al
    inc bx
    mov ax,cx
    putedxal()
    mov byte ptr es:[bx],0
    mov dx,es
    mov ax,WORD PTR buf
    ret

dwtostr ENDP

    END
