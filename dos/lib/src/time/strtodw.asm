; STRTODW.ASM--
; Copyright (C) 2015 Doszip Developers

include time.inc
include stdlib.inc

.code

strtodw PROC _CType PUBLIC USES si di bx string:DWORD

    les di,string
    mov si,es
    .if atol(si::di)
        mov bx,ax
        mov es,si
        mov al,es:[di]
        .while ( al >= '0' && al <= '9' )
            inc di
            mov al,es:[di]
        .endw
        inc di
        atol(si::di)
        push ax
        mov es,si
        mov al,es:[di]
        .while ( al >= '0' && al <= '9' )
            inc di
            mov al,es:[di]
        .endw
        inc di
        atol(si::di)
        pop dx ; default: dd.mm.yy??
        .if dos_dateformat == DFORMAT_JAPAN
           xchg ax,bx   ; yy??/mm/dd
        .elseif dos_dateformat == DFORMAT_USA
            xchg ax,dx  ; mm/dd/yy??
        .endif
        .if ax < 1900 ; AX = yy??
            .if ax < 80
                add ax,100
            .endif
            add ax,1900
        .endif
        sub ax,DT_BASEYEAR
        shl ax,9
        shl dx,5  ; DX = mm
        or  ax,dx
        or  ax,bx ; BX = dd
    .endif
    ret
strtodw ENDP

    END
