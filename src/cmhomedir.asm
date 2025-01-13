; CMHOMEDIR.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc

    .code

cmhomedir proc  ; Ctrl-Home

    .if panel_state(cpanel)

        mov rdx,[rax].PANEL.wsub
        mov eax,[rdx].WSUB.flag
        or  eax,_W_ROOTDIR
        and eax,not _W_ARCHIVE
        mov [rdx].WSUB.flag,eax
        mov rax,[rdx].WSUB.arch
        mov byte ptr [rax],0

        panel_read(cpanel)
        panel_putitem(cpanel, 0)
    .endif
    ret

cmhomedir endp

    END
