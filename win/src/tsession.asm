include malloc.inc
include conio.inc
include io.inc
include direct.inc
include config.inc
include wsub.inc

    .code

TIOpenSession proc uses rsi rdi pCFINI:LPINI, Section:LPSTR

  local tflag,tabz,x,b,y,l,index

    .if INIGetSection(pCFINI, Section)

        mov rdi,rax
        xor eax,eax
        mov index,eax
        mov tflag,eax
        mov tabz,eax

        .while CFReadFileName(rdi, addr index, 1)

            mov rsi,rax
            .break .if !topen(rsi, tflag)

            mov tinfo,rax
            free(rsi)

            assume rsi:PTINFO

            mov rsi,tinfo
            mov eax,tabz
            .if eax

                mov [rsi].tabsize,eax
            .endif
            mov eax,l
            mov [rsi].loffs,eax
            mov eax,y
            mov [rsi].yoffs,eax
            mov eax,x
            mov [rsi].xoffs,eax
            mov eax,b
            mov [rsi].boffs,eax
        .endw
        mov rax,tinfo
    .endif
    ret

TIOpenSession endp

TISaveSession proc uses rsi rdi rbx __ini:LPINI, section:LPSTR

  local buffer[1024]:sbyte, handle:LPINI

    .if tigetfile(tinfo)

        mov rsi,rax
        mov rdi,rdx

        mov rax,__ini
        .if rax

            .if INIAddSection(rax, section)

                mov handle,rax

                INIDelEntries(rax)

                xor ebx,ebx
                .while rsi

                    mov ecx,[rsi].flags
                    and ecx,_T_TECFGMASK

                    INIAddEntryX( handle, "%d=%X,%X,%X,%X,%X,%X,%s", ebx,
                        [rsi].loffs,
                        [rsi].yoffs,
                        [rsi].boffs,
                        [rsi].xoffs,
                        [rsi].tabsize,
                        ecx,
                        [rsi].file )

                    inc ebx
                    .break .if rsi == rdi

                    mov rsi,[rsi].next
                    .break .if !tistate(rsi)
                .endw
            .endif
        .endif
    .endif
    ret

TISaveSession endp

    assume rsi:nothing

topenedi proc uses rsi fname:LPSTR

  local cursor:CURSOR

    .if INIRead(0, fname)

        mov rsi,rax

        .if INIGetSection(rsi, ".")

            _getcursor(&cursor)

            .if tistate(tinfo)

                tihide(tinfo)
            .endif

            TIOpenSession(rsi, ".")

            .if tistate(tinfo)

                tishow(tinfo)
                tmodal()
            .endif

            _setcursor(&cursor)
        .endif
        INIClose(rsi)
    .endif
    mov rax,tinfo
    ret

topenedi endp


tloadfiles proc uses rsi rdi rbx

  local path[_MAX_PATH]:byte

    .if wgetfile(&path, "*.edi", _WOPEN)

        _close(eax)

        .if INIRead(0, &path)

            mov rsi,rax

            .if INIGetSection(rsi, ".")

                .if tistate(tinfo)
                    tihide(tinfo)
                .endif
                TIOpenSession(rsi, ".")
                .if tistate(tinfo)
                    tishow(tinfo)
                .endif
            .endif
            INIClose(rsi)
        .endif
    .endif
    mov eax,_TI_CONTINUE
    ret

tloadfiles endp


topensession proc

  local cu:CURSOR

    _getcursor(&cu)
    tloadfiles()
    xor eax,eax
    tmodal()
    _setcursor(&cu)
    mov eax,_TI_CONTINUE
    ret

topensession endp


tsavefiles proc uses rsi

  local path[_MAX_PATH]:byte

    .if wgetfile(&path, "*.edi", _WSAVE)

        _close(eax)

        .if INIAlloc()

            mov rsi,rax

            TISaveSession(rsi, ".")
            INIWrite(rsi, &path)
            INIClose(rsi)
        .endif
    .endif
    mov eax,_TI_CONTINUE
    ret

tsavefiles endp

    END
