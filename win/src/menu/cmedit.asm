; CMEDIT.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include string.inc
include io.inc
include time.inc
include doszip.inc
include stdlib.inc

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

    strpath(strcpy(__srcpath, strcpy(__srcfile, file)))
    strcpy(__outpath, path)
    strcpy(__outfile, archive)

    .if osopen(file, _A_NORMAL, M_RDONLY, A_OPEN) != -1
        mov esi,eax
        .if _filelength(eax)
            mov edi,eax
            _close(esi)
            mov ebx,clock()
            getfattr(file)
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


editzip proc private uses rsi rdi

    mov edi,ecx
    mov rcx,rdx
    .if unzip_to_temp(rcx, rbx)
        mov esi,_diskflag
        setfattr(rax, 0)
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
        remove(rbx)
    .endif
    ret

editzip endp


cmedit proc uses rbx

  local fname[_MAX_PATH*2]:byte

    lea rbx,fname

    .switch TVGetCurrentFile(rbx)
      .case 1
        .if ecx == eax
            mov ecx,4
        .endif
        load_tedit(rbx, ecx)
        .endc
      .case 2
        editzip()
    .endsw
    ret

cmedit endp


cmwindowlist proc

    .if tdlgopen() > 2
        mov tinfo,rax
    .else
        .if eax == 1
            mov tinfo,rdx
            tclose()
        .elseif eax == 2
            tiflush(rdx)
        .endif
        ret
    .endif

cmwindowlist endp

cmtmodal proc

    .if tistate(tinfo)
        tmodal()
    .else
        topensession()
    .endif
    ret

cmtmodal endp

    END
