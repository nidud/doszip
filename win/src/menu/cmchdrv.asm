; CMCHDRV.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include errno.inc

    .data

cp_selectdrv    db 'Select disk Panel '
cp_selectdrv_X  db 'A',0

    .code

cmchdrv proc private uses rsi rdi

    mov rsi,rax
    .if panel_state(rax)

        mov errno,0
        .if _disk_select(addr cp_selectdrv)

            mov edi,eax
            panel_sethdd(rsi, eax)
            msloop()
            mov eax,edi
        .endif
    .endif
    ret

cmchdrv endp

cmachdrv proc

    mov rax,panela
    mov cp_selectdrv_X,'A'
    cmchdrv()
    ret

cmachdrv endp

cmbchdrv proc

    mov rax,panelb
    mov cp_selectdrv_X,'B'
    cmchdrv()
    ret

cmbchdrv endp

    END
