; DWTOSTR.ASM--
; Copyright (C) 2015 Doszip Developers

include time.inc

.code

dwtostr PROC _CType PUBLIC USES bx cx buf:DWORD, date:size_t

    les bx,buf
    mov ax,date
    mov cx,'/'
    .if dos_dateformat == DFORMAT_EUROPE
        mov cl,'.'
        and ax,001Fh ; dd.mm.yy
    .else
        shr ax,5
        and ax,000Fh ; mm/dd/yy
    .endif
    putedxal()
    mov es:[bx],cl
    inc bx
    mov ax,date
    .if dos_dateformat == DFORMAT_EUROPE
        shr ax,5
        and ax,000Fh ; mm
    .else
        and ax,001Fh ; dd
    .endif
    putedxal()
    mov es:[bx],cl
    inc bx
    mov ax,date
    shr ax,9
    add ax,DT_BASEYEAR
    .if ax >= 2000
        sub ax,2000
    .else
        sub ax,1900
    .endif
    putedxal()
    mov es:[bx],ch
    mov dx,es
    mov ax,WORD PTR buf
    ret

dwtostr ENDP

    END
