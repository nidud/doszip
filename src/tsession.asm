include malloc.inc
include conio.inc
include io.inc
include direct.inc
include config.inc
include wsub.inc

    .code

TIOpenSession proc uses rsi rdi pCFINI:LPINI, Section:LPSTR
  local file:CFBLK
    .if INIGetSection(ldr(pCFINI), ldr(Section))
        mov rdi,rax
        .while CFReadFileName(rdi, &file, 1)
            mov rdi,rax
            .break .if !topen(file.name, file.flag)
            mov tinfo,rax
            free(file.name)
            assume rsi:PTINFO
            mov rsi,tinfo
            mov eax,file.tabz
            .if eax
                mov [rsi].tabsize,eax
            .endif
            mov [rsi].loffs,file.loff
            mov [rsi].yoffs,file.yoff
            mov [rsi].xoffs,file.xoff
            mov [rsi].boffs,file.boff
        .endw
        mov rax,tinfo
    .endif
    ret
    endp

TISaveSession proc uses rsi rdi rbx __ini:LPINI, section:LPSTR
  local buffer[1024]:sbyte
    .if tigetfile(tinfo)
        mov rsi,rax
        mov rdi,rdx
        mov rax,__ini
        .if rax
            .if INIAddSection(rax, section)
                mov rbx,rax
                INIDelEntries(rax)
                .while rsi
                    mov ecx,[rsi].flags
                    and ecx,_T_TECFGMASK
                    INIAddEntryX( rbx, "0=%X,%X,%X,%X,%X,%X,%s", [rsi].loffs, [rsi].yoffs,
                        [rsi].boffs, [rsi].xoffs, [rsi].tabsize, ecx, [rsi].file )
                    .break .if rsi == rdi
                    mov rsi,[rsi].next
                    .break .if !tistate(rsi)
                .endw
            .endif
        .endif
    .endif
    ret
    endp
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
    endp


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
    endp


topensession proc
  local cu:CURSOR
    _getcursor(&cu)
    tloadfiles()
    xor eax,eax
    tmodal()
    _setcursor(&cu)
    mov eax,_TI_CONTINUE
    ret
    endp


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
    endp

    END
