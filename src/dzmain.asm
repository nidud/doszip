; DZMAIN.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include stdio.inc
include stdlib.inc
include string.inc
include malloc.inc
include io.inc
include process.inc
include config.inc
include wsub.inc
include progress.inc

config_create proto

    .data

    panel_A dd 0
    panel_B dd 0

    .code

    option proc:private

ioupdate proc stream:PIOST
    ;
    ; This is called on each flush (copy)
    ;
    ldr rcx,stream
    .ifd progress_update([rcx].IOST.total)
        xor eax,eax ; User break (ESC)
    .else
        mov eax,1
    .endif
    ret

ioupdate endp

test_path proc

    xor eax,eax     ; validate path in ESI
    mov cx,[rsi]    ; path in EDI used if fail
    .if cl
        .if cx == '\\'

            .if ( console & CON_NETCFG )
                inc eax
            .endif

        .elseif ch == ':'

            movzx eax,cl
            or  al,' '
            sub al,'a' - 1

            .ifd _disk_exist(eax)

                .ifd filexist(rsi) == 2
                    ;
                    ; disk and path exist
                    ;
                    ; if exist, remove trailing slash from path
                    ;
                    .if strrchr(rsi, '\')

                        mov ecx,'\'
                        .if [rax] == cx && byte ptr [rax-1] != ':'
                            mov [rax],ch
                        .endif
                    .endif
                    mov eax,1
                .else
                    xor eax,eax
                .endif
            .endif
        .endif
    .endif
    .if !eax
        strcpy(rsi, rdi)
        xor eax,eax
    .endif
    ret
test_path endp

    option  proc: PUBLIC

doszip_init proc uses rsi rdi rbx argv:LPSTR

  local result:SINT
  local p:LPSTR
  local fb:FBLK

    mov __srcfile,malloc(5*WMAXPATH)  ; directory buffers
    add rax,WMAXPATH
    mov __srcpath,rax
    add rax,WMAXPATH
    mov __outfile,rax   ; target
    add rax,WMAXPATH
    mov __outpath,rax
    add rax,WMAXPATH
    mov entryname,rax   ; archive->name

    wsopen(addr path_a) ; panels
    wsopen(addr path_b)

    mov rdi,strcpy(__srcfile, _pgmpath)
    SetEnvironmentVariable("DZ", rdi)

    mov rbx,strfn(rdi)
    .ifd !strcmp(rbx, "bin")
        mov byte ptr [rbx-1],0
    .endif
    SetEnvironmentVariable("ASMCDIR", rdi)


    mov byte ptr [rdi+2],0
    SetEnvironmentVariable("DZDRIVE", rdi)
    mov byte ptr [rdi],0

    mov rbx,_pgmpath
    ;
    ; Create and read the DZ.INI file
    ;
    .ifd !filexist(strfcat(__srcfile, rbx, addr DZ_INIFILE))
        ;
        ; virgin call..
        ;
        config_create()
        and cflag,not _C_DELHISTORY
    .endif

    CFRead(__srcfile)

    ;
    ; Read section [Environ]
    ;
    xor edi,edi
    mov result,edi
    mov rsi,__srcfile
    .if CFGetSection("Environ")

        mov rbx,rax

        .while INIGetEntryID(rbx, edi)

            strcpy(rsi, rax)
            inc edi
            expenviron(rsi)
            .break .if !strchr(rsi, '=')
            mov byte ptr [rax],0
            inc rax
            mov p,rax
            strtrim(rsi)
            strstart(p)
            SetEnvironmentVariable(rsi, rax)
        .endw
    .endif

    ;
    ; Read section [Path]
    ;
    xor edi,edi
    mov [rsi],edi

    .if CFGetSection("Path")

        mov rbx,rax

        .while INIGetEntryID(rbx, edi)

            mov p,rax
            strcat(strcat(rsi, ";"), p)
            inc edi
        .endw

        .if [rsi] != al

            inc rsi
            expenviron(rsi)
            SetEnvironmentVariable("PATH", rsi)
        .endif
    .endif

    config_read()

    mov eax,console
    and eax,CON_NTCMD
    CFGetComspec(eax)

    and config.c_apath.flag,not _W_ARCHEXT
    and config.c_bpath.flag,not _W_ARCHEXT
    ;
    ; argv is .ZIP file or directory
    ;
    mov rbx,argv

    .if ebx == 1 ; -cmd

        and config.c_apath.flag,not _W_VISIBLE
        and config.c_bpath.flag,not _W_VISIBLE
        or  cflag,_C_COMMANDLINE
        and cflag,not _C_STATUSLINE
        and cflag,not _C_MENUSLINE

    .elseif rbx

        .ifd filexist(rbx) == 1

            mov fb.name,strfn(rbx)
            lea rdi,fb
            .ifd _aisexec(rbx)

                jmp isexec
            .endif

            readword(rbx)

            .if ax == 4B50h

                mov eax,_W_ARCHZIP
            .elseif warctest(rbx, eax) == 1
                mov eax,_W_ARCHEXT
            .else
                xor eax,eax
            .endif

            .if eax

                and config.c_apath.flag,not (_W_ARCHIVE or _W_ROOTDIR)
                and config.c_bpath.flag,not (_W_ARCHIVE or _W_ROOTDIR)
                or  eax,_W_VISIBLE
                or  config.c_apath.flag,eax
                mov rax,config.c_apath.arch
                mov byte ptr [rax],0
                mov rdi,fb.name
                strcpy(config.c_apath.file, rdi)

                .if rdi != rbx

                    mov byte ptr [rdi-1],0
                    jmp chdir_arg
                .endif
                and cflag,not _C_PANELID
                _getcwd(config.c_apath.path, WMAXPATH)
            .endif

        .elseif eax

         chdir_arg:

            and cflag,not _C_PANELID
            mov eax,':'

            .if [rbx+1] == al

                mov al,[rbx]
                or  al,20h
                sub al,'a' - 1

                _chdrive(eax)
            .endif
            _chdir(rbx)
         .else

         isexec:

            .ifd _aisexec(rbx)

                .if CFAddSection("Load")

                    mov rdi,rax
                    INIDelEntries(rdi)
                    INIAddEntryX(rdi, "0=%s", rbx)
                    inc result
                .endif
            .endif
        .endif
    .endif

    ;
    ; Read section [Load]
    ;
    .if CFGetSection("Load")

        CFExecute(rax)
    .endif

    mov thelp,&cmhelp
    mov oupdate,&ioupdate

;   ConsolePush()
    mov tdidle,&ConsoleIdle
ifdef __CI__
    CodeInfo()
endif
ifdef __BMP__
    CaptureScreen()
endif
    .if CFGetSection(".consolesize")

        .if INIGetEntryID(rax, 8)

            .if byte ptr [rax] == '1'

                xor cflag,_C_EGALINE
                PushEvent(KEY_ALTF9)
            .endif
        .endif
    .endif
    mov eax,result
    ret

doszip_init endp

doszip_open proc uses rsi rdi rbx

  local path[_MAX_PATH]:sbyte

    mov dzexitcode,0
    mov mainswitch,0

    setconfirmflag()

    .if cflag & _C_DELTEMP

        removetemp(addr cp_ziplst)
        and cflag,not _C_DELTEMP
    .endif
    ;
    ; Init panels
    ;
    mov spanela.fcb_index,config.c_fcb_indexa
    mov spanelb.fcb_index,config.c_fcb_indexb
    mov spanela.cel_index,config.c_cel_indexa
    mov spanelb.cel_index,config.c_cel_indexb

    xor eax,eax
    lea rdi,cp_stdmask
    mov rcx,config.c_apath.mask
    .if [rcx] == al

        strcpy(config.c_apath.mask, rdi)
    .endif

    mov rcx,config.c_bpath.mask
    .if byte ptr [rcx] == 0

        strcpy(config.c_bpath.mask, rdi)
    .endif
    ;
    ; Init Desktop
    ;
    .if console & CON_IMODE || _scrcol < 80

        apimode()
    .endif

    apiopen()
    mov tupdate,&apiidle
    apiidle()
    or console,CON_SLEEP
    _cursoroff()
    prect_open_ab()

    lea rcx,spanelb
    .if rcx == cpanel

        lea rcx,spanela
    .endif
    panel_openmsg(rcx)

    mov rdi,_pgmpath
    mov rsi,path_a.path
    .ifd !test_path()

        and path_a.flag,not _W_ARCHIVE
    .endif

    mov rsi,path_b.path
    .ifd !test_path()

        and path_b.flag,not _W_ARCHIVE
    .endif

    .if cflag & _C_COMMANDLINE

        _cursoron()
    .endif

    panel_open_ab()
    config_open()
    ret

doszip_open endp

doszip_hide proc

    .if cflag & _C_AUTOSAVE

        config_save()
    .endif

    apiclose()
    mov panel_B,prect_hide(panelb)
    mov panel_A,prect_hide(panela)
    ret

doszip_hide endp

doszip_show proc

    apiopen()
    .if panel_A
        redraw_panel(panela)
    .endif
    .if panel_B
        redraw_panel(panelb)
    .endif
    ret

doszip_show endp

tdummy proc private
    xor eax,eax
    ret
tdummy endp

doszip_close proc

    mov tupdate,&tdummy
    .if cflag & _C_AUTOSAVE

        config_save()
    .endif
    panel_close(panela)
    panel_close(panelb)
    apiclose()
    _gotoxy(0, com_info.ypos)
    xor eax,eax
    ret

doszip_close endp

    END
