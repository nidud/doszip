; DWTOLSTR.ASM--
; Copyright (C) 2015 Doszip Developers

include time.inc

.code

dwtolstr PROC _CType PUBLIC uses bx string:DWORD, date:size_t

    invoke dwtostr, string, date

    add ax,6
    mov bx,ax
    mov ax,es:[bx]
    mov es:[bx+2],ax ; dd.mm.[..]yy
    mov byte ptr es:[bx+4],0
    mov ax,date
    shr ax,9
    add ax,DT_BASEYEAR
    .if ax >= 2000
        mov WORD PTR es:[bx],'02'
    .else
        mov WORD PTR es:[bx],'91'
    .endif
    mov dx,es
    mov ax,WORD PTR string
    ret

dwtolstr ENDP

    END
