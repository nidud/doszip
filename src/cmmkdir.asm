; CMMKDIR.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include stdlib.inc
include errno.inc
include winnls.inc

    .code

cmmkdir proc uses rsi rdi rbx

   .new path[1024]:char_t
   .new wbuf[512]:wchar_t
   .new size:int_t

    lea rbx,path
    mov rax,cpanel
    mov rsi,[rax].PANEL.wsub
    mov edi,[rsi].WSUB.flag

    .if !( edi & _W_ROOTDIR )

        .if panel_state(rax)

            .if ( edi & _W_NETWORK ) ; v3.95: network directory
                lea rbx,[rbx+strlen(strcpy(rbx, [rsi].WSUB.path))+1]
                mov byte ptr [rbx-1],'\'
            .endif
            mov byte ptr [rbx],0
            .ifd tgetline("Make directory", rbx, 40, _MAX_PATH)

                .if ( byte ptr [rbx] )
                    .if ( edi & _W_NETWORK )
                        lea rbx,path
                    .endif
                    strlen(rbx)
                    inc eax
                    mov size,eax
                    .ifd MultiByteToWideChar(_consolecp, 0, rbx, size, &wbuf, 1024)
                        mov ecx,eax
                        .ifd WideCharToMultiByte(CP_UTF8, 0, &wbuf, ecx, rbx, 1024, NULL, NULL)
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
