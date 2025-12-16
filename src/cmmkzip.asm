; CMMKZIP.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include io.inc
include string.inc
include syserr.inc
include wsub.inc

    .data
     default_zip char_t "default.zip", 128-11 dup(0)

    .code

cmmkzip proc uses rsi rdi rbx

  local path[_MAX_PATH]:byte

    mov eax,path_a.flag
    or  eax,path_b.flag
    .if ( eax & _W_ARCHIVE )
        .return( ermsg("Create archive", "Archive already open") )
    .endif

    lea rdi,path
    .if cpanel_state()

        .ifd tgetline("Create archive", strcpy(rdi, &default_zip), 40, 256 or 8000h)

            .if byte ptr [rdi]

                xor ebx,ebx
                .if strext(rdi)
                    mov eax,[rax]
                    or  eax,0x20202000
                    .if ( eax == ' z7.' )
                        .ifd ( warctest(NULL, 0xAFBC7A37) == 0 )
                            .return notsup()
                        .endif
                        inc ebx
                    .elseif ( eax != 'piz.' )
                        .ifd ( warctest(rdi, 0) == 0 )
                            .return notsup()
                        .endif
                        mov ebx,2
                    .endif
                .endif

                .ifsd ogetouth(rdi, M_WRONLY) > 0

                    mov esi,eax
                    strcpy(&default_zip, rdi)

                    mov rax,cpanel
                    mov rdx,[rax].PANEL.wsub
                    mov rax,[rdx].WSUB.arch
                    mov byte ptr [rax],0
                    mov eax,[rdx].WSUB.flag
                    and eax,not _W_ARCHIVE
                    .if ( ebx )
                        or eax,_W_ARCHEXT
                    .else
                        or eax,_W_ARCHZIP
                    .endif
                    mov [rdx].WSUB.flag,eax
                    mov rcx,[rdx].WSUB.file
                    strcpy(rcx, rdi)

                    mov rdx,rdi
                    mov eax,0x06054B50
                    mov ecx,5
                    .if ( ebx )
                        mov ecx,(32-12)/4
                        mov eax,0xAFBC7A37
                        stosd
                        mov eax,0x03001C27
                        stosd
                        mov eax,0x0FD59B8D
                    .endif
                    stosd
                    xor eax,eax
                    rep stosd
                    mov ecx,ZEND
                    .if ( ebx )
                        mov ecx,32
                    .endif
                    .if ( ebx < 2 )
                        oswrite(esi, rdx, ecx)
                    .endif
                    _close(esi)
                    mov _diskflag,1
                .endif
            .endif
        .endif
    .endif
    ret

cmmkzip endp

    END
