; CMMKDIR.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include stdlib.inc
include errno.inc
include winnls.inc

    .code

cmmkdir proc uses rsi rdi rbx

   .new wbuf[_MAX_PATH]:wchar_t
   .new path[_MAX_PATH]:char_t
   .new size:int_t

    lea rbx,path
    mov rax,cpanel
    mov rsi,[rax].PANEL.wsub
    mov edi,[rsi].WSUB.flag

    .if !( edi & _W_ROOTDIR )

        .if panel_state(rax)

            mov byte ptr [rbx],0
            .ifd tgetline("Make directory", rbx, 40, _MAX_PATH)

                .ifd strlen(rbx)

                    inc eax
                    mov size,eax
                    .ifd MultiByteToWideChar(_consolecp, 0, rbx, size, &wbuf, _MAX_PATH)

                        mov ecx,eax
                        .ifd WideCharToMultiByte(CP_UTF8, 0, &wbuf, ecx, rbx, _MAX_PATH, NULL, NULL)

                            mov _diskflag,1
                            .if ( edi & _W_ARCHZIP )
                                wsmkzipdir(rsi, rbx)
                            .elseifd _wmkdir(&wbuf)
                                ermkdir(rbx)
                            .endif
                        .endif
                    .endif
                .endif
            .endif
        .endif
    .endif
    ret

cmmkdir endp

    end
