; CMEDIT.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include io.inc
include time.inc
include doszip.inc
include stdlib.inc
include dzstr.inc

    .code

load_tedit proc uses rsi rbx file:LPSTR, etype:int_t

  local path[_MAX_PATH*2]:char_t

    lea rsi,path
    .if !strchr(strcpy(rsi, file), '.')

        strcat(rsi, ".")
    .endif

    .if !loadiniproc("Edit", rsi, etype)

        clrcmdl()

        .if panel_findnext(cpanel)

            mov rbx,cpanel
            mov rbx,[rbx].PANEL.wsub
            wedit([rbx].WSUB.fcb, [rbx].WSUB.count)
        .else
            .if byte ptr [rsi] == '"'

                inc rsi
                .if strrchr(rsi,'"')

                    mov byte ptr [rax],0
                .endif
            .endif
            mov rax,keyshift
            mov eax,[rax]
            .if al & KEY_CTRL   ; 2 (Ctrl)
                hedit(rsi, 0)
            .else
                tedit(rsi, 0)
            .endif
        .endif
        xor eax,eax
    .endif
    ret

load_tedit endp


zipadd proc private uses rsi rdi rbx archive:LPSTR, path:LPSTR, file:LPSTR

    ldr rsi,archive
    ldr rdi,path
    ldr rbx,file

    strpath(strcpy(__srcpath, strcpy(__srcfile, rbx)))
    strcpy(__outpath, rdi)
    strcpy(__outfile, rsi)

    .ifd ( osopen(rbx, _FA_NORMAL, M_RDONLY, A_OPEN) != -1 )

        mov esi,eax
        .ifd _filelength(eax)

            mov edi,eax
            _close(esi)

            clock()
            mov rcx,rbx
            mov ebx,eax
            getfattr(rcx)

ifdef _WIN64
            wzipadd(rdi, ebx, eax)
else
            xor ecx,ecx
            wzipadd(ecx::edi, ebx, eax)
endif
        .else
            _close(esi)
            dec eax
        .endif
    .endif
    ret

zipadd endp


editzip proc private uses rsi rdi rbx file:LPSTR

    ldr rbx,file
    mov edi,ecx
    mov rcx,rdx

    .ifd unzip_to_temp(rcx, rbx)

        mov esi,_diskflag
        _wsetfattr(_utftows(rax), 0)
        mov _diskflag,0
        tedit(rbx, 0)
        mov eax,_diskflag
        .if eax
            mov rax,cpanel
            mov rax,[rax].PANEL.wsub
            mov rdx,[rax].WSUB.arch
            mov rax,[rax].WSUB.file
            zipadd(rax, rdx, rbx)
        .else
            mov _diskflag,esi
        .endif
        _wremove(_utftows(rbx))
    .endif
    ret

editzip endp


cmedit proc

    .new fname[_MAX_PATH*2]:char_t

    .ifd ( TVGetCurrentFile(&fname) == 1 )
        .if ecx == eax
            mov ecx,4
        .endif
        load_tedit(&fname, ecx)
    .elseif ( eax == 2 )
        editzip(&fname)
    .endif
    ret

cmedit endp

cmhexedit proc

    mov rax,keyshift
    or  byte ptr [rax],KEY_CTRL
    cmedit()
    ret

cmhexedit endp


cmwindowlist proc

    .if tdlgopen() > 2

        mov tinfo,rax
        cmtmodal()
    .elseif eax == 1
        mov tinfo,rdx
        tclose()
    .elseif eax == 2
        tiflush(rdx)
    .endif
    ret

cmwindowlist endp

cmtmodal proc

    .ifd tistate(tinfo)
        tmodal()
    .else
        topensession()
    .endif
    ret

cmtmodal endp

    END
