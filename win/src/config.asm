; CONFIG.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include stdio.inc
include stdlib.inc
include string.inc
include malloc.inc
include process.inc
include io.inc
include doszip.inc
include tview.inc
include config.inc
include wsub.inc
include confirm.inc
include ltype.inc

.data

__srcfile   LPSTR 0
__srcpath   LPSTR 0
__outfile   LPSTR 0
__outpath   LPSTR 0
__CFBase    LPINI 0

entryname   LPSTR 0
mainswitch  dd 0            ; program switch
dzexitcode  dd 0            ; return code (23 if exec)
numfblock   dd MAXFBLOCK    ; number of file pointers allocated

;;;;;;;;;-------------------------------
    ; Configuration file (DZCONFIG)
    ;-------------------------------
config          label S_CONFIG
version         dd DOSZIP_VERSION
cflag           dd _C_DEFAULT
console         dd CON_DEFAULT
fsflag          dd IO_SEARCHSUB or _T_PROMPTONREP or IO_SEARCHCASE
tvflag          dd _TV_HEXOFFSET or _TV_USEMLINE
tiflags         dd _T_TEDEFAULT
titabsize       dd 8
ffflag          dd 2
compresslevel   dd 9
panelsize       dd 6    ; Alt-Up/Down
fcb_indexa      dd 0
cel_indexa      dd 0
fcb_indexb      dd 0
cel_indexb      dd 0
path_a          WSUB <_W_DEFAULT,0,MAXFBLOCK>
path_b          WSUB <_W_DEFAULT or _W_PANELID,0,MAXFBLOCK>
opfilter        FILTER <-1,0,0,0,0,'*.*'>
at_foreground   db 0x07,0x07,0x0F,0x07,0x08,0x08,0x07,0x07
                db 0x08,0x07,0x0A,0x0B,0x0F,0x0B,0x0B,0x0B
at_background   db 0x00,0x00,0x00,0x10,0x30,0x10,0x30,0x00
                db 0x10,0x10,0x00,0x00,0x00,0x00,0x07,0x07
mklist          MKLST <0,0,0,-1,0>

history         PHISTORY NULL
searchstring    char_t 256 dup(0)
replacestring   char_t 256 dup(0)
cp_selectmask   char_t 128 dup(0)
filelist_bat    char_t "filelist.bat", _MAX_PATH-12 dup(0)
format_lst      char_t "%f\n", 256-4 dup(0)
findfilemask    char_t "*.*", _MAX_PATH-3 dup(0)
findfilepath    char_t _MAX_PATH dup(0)

cpanel          PPANEL spanela
panela          PPANEL spanela
panelb          PPANEL spanelb

doskey_bindex   db 0
doskey_isnext   db 0

;-S_DZDATA-END--------------------------------------------------

_bufin label byte
;;;;;;;;;;;;;;;;;-----------------------------------------------
        ; _bufin 4096 byte. Includes a default .INI file
        ;-----------------------------------------------
    db 128 dup(0)
default_ini label byte
incbin <dz_ini.txt>
    db 0
if ($ - _bufin) le 1000h
    db 1000h - ($ - _bufin) dup('x')
endif

DZ_INIFILE  char_t DOSZIP_INIFILE,0 ; config file

align size_t

config_table_x LPDWORD \
        config.c_cflag,
        config.c_console,
        config.c_fsflag,
        config.c_tvflag,
        config.c_teflag,
        config.c_titabsize,
        config.c_ffflag,
        config.c_comprlevel,
        config.c_panelsize,
        config.c_fcb_indexa,
        config.c_cel_indexa,
        config.c_fcb_indexb,
        config.c_cel_indexb,
        config.c_apath,
        config.c_bpath,
        config.c_color,
        config.c_color[0x04],
        config.c_color[0x08],
        config.c_color[0x0C],
        config.c_color[0x10],
        config.c_color[0x14],
        config.c_color[0x18],
        config.c_color[0x1C],
        config.c_list.flag,
        config.c_list.offspath,
        config.c_list.offs,
        config.c_list.handle,
        config.c_list.count,
        config.c_filter.flag,
        config.c_filter.max_date,
        config.c_filter.min_date,
        config.c_filter.max_size,
        config.c_filter.min_size,
        0

config_table_p LPSTR \
        config.c_apath.mask,
        config.c_apath.file,
        config.c_apath.arch,
        config.c_apath.path,
        config.c_bpath.mask,
        config.c_bpath.file,
        config.c_bpath.arch,
        config.c_bpath.path,
        0

config_table_s LPSTR \
        config.c_filter.minclude,
        config.c_filter.mexclude,
        searchstring,
        replacestring,
        cp_selectmask,
        filelist_bat,
        format_lst,
        findfilemask,
        findfilepath,
        default_arc,
        default_zip,
        0

    .code

INIAlloc proc

    .if malloc(S_INI)

        mov ecx,0
        mov [rax].S_INI.flags,ecx
        mov [rax].S_INI.entry,rcx
        mov [rax].S_INI.value,rcx
        mov [rax].S_INI.next,rcx
    .endif
    ret

INIAlloc endp


INIAddEntry proc private uses rsi rdi rbx cf:LPINI, string:LPSTR

   .new p:LPINI

    xor edi,edi
    mov rsi,string

    movzx eax,byte ptr [rsi]
    lea rbx,_ltype
    .while ( byte ptr [rbx+rax] & _SPACE )

        inc rsi
        mov al,[rsi]
    .endw

    .if ( al == ';' )

        .return .if !INIAlloc()

        mov rdi,rax
        strtrim(rsi)
        mov [rdi].S_INI.flags,INI_COMMENT
        mov [rdi].S_INI.entry,_strdup(rsi)
        mov rax,rdi

    .elseif strchr(rsi, '=')

        mov byte ptr [rax],0
        lea rdi,[rax+1]

        movzx eax,byte ptr [rdi]
        .while ( byte ptr [rbx+rax] & _SPACE )

            inc rdi
            mov al,[rdi]
        .endw

        .return .ifd !strtrim(rsi)
        mov rbx,rax
        .return .ifd !strtrim(rdi)
        lea rbx,[rbx+rax+2]

        .if INIGetEntry(cf, rsi)

            mov rax,[rcx].S_INI.next
            .if !rdx
                mov rdx,cf
                mov [rdx].S_INI.value,rax
            .else
                mov [rdx].S_INI.next,rax
            .endif
            mov p,rcx
            free([rcx].S_INI.entry)
            free(p)
        .endif
        .return .if !INIAlloc()

        xchg rbx,rax
        .return .if !malloc(eax)

        mov [rbx].S_INI.entry,rax
        strcat(strcat(strcpy(rax, rsi), "="), rdi)
        strchr(rax, '=')
        mov byte ptr [rax],0
        inc rax
        mov [rbx].S_INI.value,rax

        mov rax,rbx
        mov [rax].S_INI.flags,INI_ENTRY
    .endif

    mov rdx,cf
    mov rcx,[rdx].S_INI.value
    .if rcx
        .while [rcx].S_INI.next
            mov rcx,[rcx].S_INI.next
        .endw
        mov [rcx].S_INI.next,rax
    .else
        mov [rdx].S_INI.value,rax
    .endif
    ret

INIAddEntry endp


INIRead proc uses rsi rdi rbx ini:LPINI, file:LPSTR

  local i_fh, i_bp:LPSTR, i_i, i_c, o_bp:LPSTR, o_i, o_c

    .ifd osopen(file, _A_NORMAL, M_RDONLY, A_OPEN) != -1

        mov i_fh,eax
        mov i_bp,alloca(_PAGESIZE_*2)
        add rax,_PAGESIZE_
        mov o_bp,rax
        xor eax,eax
        mov i_i,eax
        mov i_c,eax
        mov o_i,eax
        mov o_c,eax
        .if rax == ini
            mov ini,INIAlloc()
        .endif
        mov rbx,ini

        .while 1

            mov eax,i_i
            .if eax == i_c

                .break .ifd !osread(i_fh, i_bp, _PAGESIZE_)

                mov i_c,eax
                xor eax,eax
                mov i_i,eax
            .endif

            inc i_i
            add rax,i_bp
            movzx eax,byte ptr [rax]

            mov rdi,o_bp
            mov edx,o_i
            inc o_i
            mov [rdi+rdx],ax

            .if eax == 10 || edx == _PAGESIZE_ - 2

                mov o_i,0
                mov al,[rdi]

                .switch al

                  .case 10
                  .case 13
                    .endc
                  .case '['
                    inc rdi
                    .if strchr(rdi, ']')

                        mov byte ptr [rax],0
                        .break .if !INIAddSection(ini, rdi)
                        mov rbx,rax
                    .endif
                    .endc
                  .default
                    INIAddEntry(rbx, rdi)
                .endsw
            .endif
        .endw
        _close(i_fh)
        mov rax,ini
    .else
        xor eax,eax
    .endif
    ret

INIRead endp


    assume rsi:ptr S_INI
    assume rdi:ptr S_INI

INIWrite proc uses rsi rdi rbx ini:LPINI, file:LPSTR

    .new fp:LPFILE

    .if ( fopen(file, "wt") != NULL )

        mov fp,rax
        mov _diskflag,1

        mov rsi,ini
        .while rsi

            .if [rsi].flags == INI_SECTION

                fprintf(fp, "\n[%s]\n", [rsi].entry)
            .endif
            mov rdi,[rsi].value
            .while rdi

                .if [rdi].flags == INI_ENTRY

                    fprintf(fp, "%s=%s\n", [rdi].entry, [rdi].value)
                .elseif [rdi].flags == INI_COMMENT

                    fprintf(fp, "%s\n", [rdi].entry)
                .else
                    fprintf(fp, ";%s\n", [rdi].entry)
                .endif
                mov rdi,[rdi].next
            .endw
            mov rsi,[rsi].next
        .endw
        fclose(fp)
        mov eax,1
    .endif
    ret

INIWrite endp

INIAddEntryX proc __Cdecl ini:LPINI, format:LPSTR, argptr:VARARG

    .ifd vsprintf( &_bufin, format, &argptr )

        INIAddEntry(ini, &_bufin)
    .endif
    ret

INIAddEntryX endp

INIAddSection proc uses rsi ini:LPINI, section:LPSTR

    .if !INIGetSection(ini, section)

        .if INIAlloc()

            mov rsi,rax
            mov [rsi].S_INI.flags,INI_SECTION
            mov [rsi].S_INI.entry,_strdup(section)
            mov rax,ini
            .if rax
                .while [rax].S_INI.next
                    mov rax,[rax].S_INI.next
                .endw
                mov [rax].S_INI.next,rsi
            .endif
            mov rax,rsi
        .endif
    .endif
    ret

INIAddSection endp

INIDelEntries proc uses rsi ini:LPINI

    mov rax,ini
    mov rsi,[rax].S_INI.value
    mov [rax].S_INI.value,0

    .while rsi

        .if [rsi].entry
            free([rsi].entry)
        .endif
        mov rax,rsi
        mov rsi,[rsi].next
        free(rax)
    .endw
    mov rax,ini
    ret

INIDelEntries endp


INIDelSection proc private uses rbx ini:LPINI, section:LPSTR

    .if INIGetSection(ini, section)

        .if rdx

            mov rcx,[rax].S_INI.next
            mov [rdx].S_INI.next,rcx
        .endif
        mov rbx,[INIDelEntries(rax)].S_INI.entry
        free(rbx)

        .if ( rbx == ini )

            mov [rbx].S_INI.flags,0
            mov [rbx].S_INI.entry,0
        .else
            free(rbx)
        .endif
        mov rax,ini
    .endif
    ret

INIDelSection endp


INIGetEntry proc uses rsi rdi ini:LPINI, entry:LPSTR

    mov rdx,ini
    xor edi,edi
    xor eax,eax

    .if rdx && [rdx].S_INI.flags & INI_SECTION

        mov rax,[rdx].S_INI.value

        .while rax

            .if [rax].S_INI.flags & INI_ENTRY

                mov rsi,rax
                mov rdx,[rax].S_INI.entry
                mov rcx,entry

                .while 1

                    mov al,[rcx]
                    mov ah,[rdx]
                    .break .if !al

                    add rcx,1
                    add rdx,1
                    or  eax,0x2020
                    .break .if al != ah
                .endw

                .if al == ah

                    mov rdx,rdi ; mother
                    mov rcx,rsi ; entry
                    ;
                    ; return value
                    ;
                    mov rax,[rsi].S_INI.value
                   .break
                .endif
                mov rax,rsi
            .endif
            mov rdi,rax
            mov rax,[rax].S_INI.next
        .endw
    .endif
    ret

INIGetEntry endp


INIGetEntryID proc ini:LPINI, entry:UINT

    mov eax,entry ; 0..99
    .while  al > 9
        add ah,1
        sub al,10
    .endw
    .if ah
        xchg    al,ah
        or  ah,'0'
    .endif
    or  al,'0'
    mov entry,eax
    INIGetEntry(ini, &entry)
    ret

INIGetEntryID endp


INIGetSection proc uses rsi rdi ini:LPINI, section:LPSTR

    mov rax,ini
    xor edi,edi

    .while rax

        .if [rax].S_INI.flags & INI_SECTION

            mov rsi,rax
            .ifd !strcmp([rsi].entry, section)

                mov rdx,rdi
                mov rax,rsi
               .break
            .endif
            mov rax,rsi
        .endif
        mov rdi,rax
        mov rax,[rax].S_INI.next
    .endw
    ret

INIGetSection endp


INIClose proc uses rsi rdi rbx ini:LPINI

    mov rsi,ini
    .while rsi

        .if [rsi].entry

            free([rsi].entry)
        .endif
        mov rdi,[rsi].value
        .while rdi

            .if [rdi].entry

                free([rdi].entry)
            .endif
            mov rax,rdi
            mov rdi,[rdi].next
            free(rax)
        .endw
        mov rax,rsi
        mov rsi,[rsi].next
        free(rax)
    .endw
    ret

INIClose endp

    assume rsi:nothing
    assume rdi:nothing

__CFExpandCmd proc private uses rsi rdi ini:LPINI, buffer:LPSTR, file:LPSTR

   .new tmp:LPSTR = alloca(0x8000)

    mov rdi,rax
    mov rsi,rax

    .if strrchr(strcpy(rsi, strfn(file)), '.')

        .if byte ptr [rax+1] == 0

            mov byte ptr [rax],0
        .else

            lea rsi,[rax+1]
        .endif
    .endif

    .if INIGetEntry(ini, rsi)

        mov rsi,rax
        strcpy(rdi, rax)

        ExpandEnvironmentStrings(rsi, rdi, 0x8000 - 1)
        CFExpandMac(rdi, file)
        strxchg(rdi, ", ", "\r\n")
        strcpy(buffer, rdi)
    .endif
    ret

__CFExpandCmd endp

__CFGetComspec proc private uses rsi rdi rbx ini:LPINI, value:UINT

  local buffer[512]:byte

    mov esi,value
    mov comspec_type,esi

    __initcomspec()
    strcpy(__pCommandArg, "/C")

    .if esi

        .if INIGetSection(ini, &__comspec)

            mov rsi,rax
            lea rbx,buffer

            .if INIGetEntryID(rsi, 0)

                .ifd !_access(expenviron(strcpy(rbx, rax)), 0)

                    free(__pCommandCom)
                    mov __pCommandCom,_strdup(rbx)

                    mov rax,__pCommandArg
                    mov byte ptr [rax],0

                    .if INIGetEntryID(rsi, 1)

                        expenviron(strcpy(rbx, rax))
                        strncpy(__pCommandArg, rax, 64-1)
                    .endif
                .endif
            .endif
        .endif
    .endif
    mov rax,__pCommandCom
    ret

__CFGetComspec endp

CFError proc section:LPSTR, entry:LPSTR

    ermsg("Bad or missing Entry in .INI file",
        "Section: [%s]\nEntry: [%s]", section, entry)
    ret

CFError endp

CFRead proc file:LPSTR

    mov __CFBase,INIRead(__CFBase, file)
    ret

CFRead endp

CFReadFileName proc uses rsi rdi rbx ini:LPINI, index:PVOID, file_flag:UINT

  local buffer[1024]:sbyte

    mov rax,index
    mov ebx,[rax]
    xor edi,edi

    .while INIGetEntryID(ini, ebx)

        mov rsi,rax
        inc ebx

        mov rdi,index
        add rdi,4

        .while strchr(rsi, ',')

            mov rcx,rsi
            lea rsi,[rax+1]
            __xtol(rcx)
            stosd
        .endw
        xor edi,edi

        ExpandEnvironmentStrings(rsi, strcpy(&buffer, rsi), 1024)

        lea rsi,buffer
        .ifd filexist(rsi) == file_flag

            mov rdi,_strdup(rsi)
           .break
        .endif
    .endw

    mov rax,index
    mov [rax],ebx
    mov rax,rdi
    ret

CFReadFileName endp


CFWrite proc private file:LPSTR

    mov rax,__CFBase
    .if rax

        INIWrite(rax, file)
    .endif
    ret

CFWrite endp


CFGetSection proc section:LPSTR

    mov rax,__CFBase
    .if rax

        INIGetSection(rax, section)
    .endif
    ret

CFGetSection endp


CFGetSectionID proc section:LPSTR, id:UINT

    mov rax,__CFBase
    .if rax

        .if INIGetSection(rax, section)

            INIGetEntryID(rax, id)
        .endif
    .endif
    ret

CFGetSectionID endp


CFAddSection proc __section:LPSTR

    mov rax,__CFBase
    .if rax

        INIAddSection(rax, __section)
    .endif
    ret

CFAddSection endp


CFGetComspec proc value:UINT

    mov rax,__CFBase
    .if rax

        __CFGetComspec(rax, value)
    .endif
    ret

CFGetComspec endp


CFExpandCmd proc buffer:LPSTR, file:LPSTR, section:LPSTR

    mov rax,__CFBase
    .if rax

        .if INIGetSection(rax, section)

            __CFExpandCmd(rax, buffer, file)
        .endif
    .endif
    ret

CFExpandCmd endp


CFExecute proc uses rsi ini:LPINI

  local cmd[256]:byte

    xor esi,esi
    .while INIGetEntryID(ini, esi)

        mov rdx,rax
        system(strcpy(&cmd, rdx))
        inc esi
    .endw
    ret

CFExecute endp

;
; File macros:
;
;    !!     !
;    !:     Drive + ':'
;    !\     Long path
;    !      Long file name
;    .!     Long extension
;    .!~    Short extension
;    !~\    Short path
;    ~!     Short file name
;

CFExpandMac proc uses rsi rdi rbx string:LPSTR, file:LPSTR

  local longpath:LPSTR,
        longfile:LPSTR,
        shortpath:LPSTR,
        shortfile:LPSTR,
        p:LPSTR,
        S2:UINT,
        S1:UINT,
        drive:UINT

    .if !strchr(string, '!')

        ; "<string> <file>"
        ; "<string> "<file name>""

        lea rbx,S1
        mov eax,'" '
        mov [rbx],eax
        mov rsi,strchr(file, ' ')

        .if !rax

            mov [rbx+1],al
        .endif

        strcat(strcat(string, rbx), file)

        .if rsi

            inc rbx
            strcat(rax, rbx)
        .endif
        .return
    .endif

    mov longpath,alloca(WMAXPATH*2)
    mov rdi,rax
    mov ecx,WMAXPATH*2
    add rax,WMAXPATH
    mov shortpath,rax
    xor eax,eax
    rep stosb

    GetFullPathName(file, WMAXPATH, strcpy(longpath, file), 0)

    xor eax,eax
    mov drive,eax
    mov rdi,longpath
    mov ebx,[rdi]

    .if bl != '\' && bh != ':'

        .return .ifd !GetCurrentDirectory(WMAXPATH, shortpath)

        strfcat(longpath, shortpath, file)
    .endif

    GetShortPathName(rdi, strcpy(shortpath, rdi), WMAXPATH)

    .if bh == ':'

        mov word ptr drive,bx
        strcpy(rdi, &[rdi+3])
        mov rcx,shortpath
        strcpy(rcx, &[rcx+3])
    .endif

    lea rsi,S1
    lea rdi,S2
    mov rbx,string

    ; remove <!!>

    mov dword ptr [rsi],"!!"
    mov dword ptr [rdi],"››"
    strxchg(rbx, rsi, rdi)

    ; xchg <!:> -- <<drive>:>

    mov byte ptr [rsi+1],':'
    strxchg(rbx, rsi, &drive)

    ; xchg <.!~> -- <Short extension>

    xor eax,eax
    mov [rdi],eax
    mov dword ptr [rsi],"~!."
    strext(shortpath)
    mov rdx,rdi
    .if rax
        mov rdx,rax
    .endif
    mov p,rdx
    strxchg(rbx, rsi, rdx)

    ; remove short extension

    mov rdx,p
    .if rdx != rdi

        mov byte ptr [rdx],0
    .endif

    ; xchg <.!> -- <Long extension>

    mov dword ptr [rsi],"!."
    strext(longpath)
    mov rdx,rdi
    .if rax
        mov rdx,rax
    .endif
    mov p,rdx
    strxchg(rbx, rsi, rdx)

    ; remove long extension

    mov rdx,p
    .if rdx != rdi

        mov byte ptr [rdx],0
    .endif

    mov shortfile,strfn(shortpath)
    .if rax == shortpath

        mov shortpath,rdi
    .else

        mov byte ptr [rax-1],0
    .endif

    mov longfile,strfn(longpath)
    .if rax == longpath

        mov longpath,rdi
    .else

        mov byte ptr [rax-1],0
    .endif

    ; xchg <!\> -- <Long path>

    mov dword ptr [rsi],"\!"
    strxchg(rbx, rsi, longpath)

    ; xchg <!~\> -- <Short path>

    mov dword ptr [rsi],"\~!"
    strxchg(rbx, rsi, shortpath)

    ; xchg <!~> -- <Short file>

    mov dword ptr [rsi],"!~"
    strxchg(rbx, rsi, shortfile)

    ; xchg <!> -- <Long file>

    mov dword ptr [rsi],"!"
    strxchg(rbx, rsi, longfile)

    ; xchg <››> -- <!>

    mov dword ptr [rsi],"››"
    mov dword ptr [rdi],"!"
    strxchg(rbx, rsi, rdi)
    ret

CFExpandMac endp


CFClose proc

    mov rax,__CFBase
    .if rax

        INIClose(rax)
        mov __CFBase,0
    .endif
    ret

CFClose endp


config_create proc uses rsi rdi

    xor edi,edi
    mov config.c_cel_indexa,5

    .if fopen(__srcfile, "wt")

        mov rsi,rax
        mov _diskflag,1

        fwrite(&default_ini, 1, strlen(&default_ini), rsi)
        mov edi,eax
        fclose(rsi)
    .endif
    mov eax,edi
    ret

config_create endp

config_read proc uses rsi rdi rbx

  local xoff, boff, yoff, loff, entry

ifdef _WIN95
    push console
endif
    mov history,malloc(HISTORY)
    .if rax

        mov rdi,rax
        xor eax,eax
        mov ecx,HISTORY
        rep stosb
    .endif

    .if CFGetSection(".config")

        mov rbx,rax

        .if INIGetEntryID(rbx, 0)

            .ifd __xtol(rax) <= DOSZIP_VERSION && eax >= DOSZIP_MINVERS

                mov edi,1
                lea rsi,config_table_x
                .repeat
                    .if INIGetEntryID(rbx, edi)

                        __xtol(rax)
                        mov rcx,[rsi]
                        mov [rcx],eax
                    .endif
                    add edi,1
                    add rsi,size_t
                    mov rax,[rsi]
                .until !rax

                lea rsi,config_table_p
                mov rax,[rsi]
                .while rax
                    .if INIGetEntryID(rbx, edi)

                        mov rcx,[rsi]
                        mov rcx,[rcx]
                        strcpy(rcx, rax)
                    .endif
                    add edi,1
                    add rsi,size_t
                    mov rax,[rsi]
                .endw

                lea rsi,config_table_s
                mov rax,[rsi]
                .while rax
                    .if INIGetEntryID(rbx, edi)

                        mov rcx,[rsi]
                        strcpy(rcx, rax)
                    .endif
                    add edi,1
                    add rsi,size_t
                    mov rax,[rsi]
                .endw
            .endif
        .endif
    .endif

    .if CFGetSection(".directory")

        mov rdi,history
        .if rdi

            mov entry,0
            mov rbx,rax

            .while CFReadFileName(rbx, addr entry, 2)

                mov [rdi].DIRECTORY.path,rax
                mov eax,loff
                mov [rdi].DIRECTORY.flag,eax
                mov eax,yoff
                mov [rdi].DIRECTORY.fcb_index,eax
                mov eax,boff
                mov [rdi].DIRECTORY.cel_index,eax
                add rdi,DIRECTORY
            .endw
        .endif
    .endif

    .if CFGetSection(".doskey")

        mov rbx,rax
        mov rax,history
        .if rax

            lea rdi,[rax].HISTORY.doskey
            mov esi,MAXDOSKEYS
            mov entry,0

            .while INIGetEntryID(rbx, entry)

                mov [rdi],_strdup(rax)
                add rdi,size_t
                inc entry
                dec esi
               .break .ifz
            .endw
        .endif
    .endif

toend:
ifdef _WIN95
    pop eax
    and eax,CON_WIN95
    or  console,eax
endif
    ret
config_read endp

config_save proc uses rsi rdi rbx

  local boff, xoff, loff

    mov config.c_fcb_indexa,spanela.fcb_index
    mov config.c_cel_indexa,spanela.cel_index
    mov config.c_fcb_indexb,spanelb.fcb_index
    mov config.c_cel_indexb,spanelb.cel_index
    and config.c_apath.flag,not _W_VISIBLE
    .if prect_a.flag & _D_DOPEN
        or config.c_apath.flag,_W_VISIBLE
    .endif
    and config.c_bpath.flag,not _W_VISIBLE
    .if prect_b.flag & _D_DOPEN
        or config.c_bpath.flag,_W_VISIBLE
    .endif

    .if CFAddSection(".config")

        mov rbx,rax
        INIDelEntries(rax)

        xor edi,edi
        INIAddEntryX(rbx, "%d=%X", edi, DOSZIP_VERSION)

        or  fsflag,_T_PROMPTONREP
        and fsflag,not IO_SEARCHHEX

        inc edi
        lea rsi,config_table_x
        .while 1
            mov rax,[rsi]
            .break .if !rax
            mov eax,[rax]
            INIAddEntryX(rbx, "%d=%X", edi, eax)
            add edi,1
            add rsi,size_t
        .endw
        lea rsi,config_table_p
        .while 1
            mov rax,[rsi]
            .break .if !rax
            mov rax,[rax]
            INIAddEntryX(rbx, "%d=%s", edi, rax)
            add edi,1
            add rsi,size_t
        .endw
        lea rsi,config_table_s
        .while 1
            mov rax,[rsi]
            .break .if !rax
            INIAddEntryX(rbx, "%d=%s", edi, rax)
            add edi,1
            add rsi,size_t
        .endw
    .endif

    .if CFAddSection(".directory")

        .if !(cflag & _C_DELHISTORY)

            mov rbx,rax
            INIDelEntries(rax)

            mov rdi,history
            .if rdi

                xor esi,esi
                .while [rdi].DIRECTORY.path

                    INIAddEntryX(rbx, "%d=%X,%X,%X,%s", esi,
                        [rdi].DIRECTORY.flag,
                        [rdi].DIRECTORY.fcb_index,
                        [rdi].DIRECTORY.cel_index,
                        [rdi].DIRECTORY.path)

                    add rdi,DIRECTORY
                    inc esi
                    .break .if esi == MAXHISTORY
                .endw
            .endif
        .endif
    .endif

    .if CFAddSection(".doskey")

        .if !(cflag & _C_DELHISTORY)

            mov rbx,rax
            INIDelEntries(rax)

            mov rax,history
            .if rax

                lea rsi,[rax].HISTORY.doskey
                xor edi,edi

                .while edi < MAXDOSKEYS

                    mov rax,[rsi]
                    add rsi,size_t

                    .break .if !rax
                    .break .if byte ptr [rax] == 0

                    INIAddEntryX(rbx, "%d=%s", edi, rax)
                    inc edi
                .endw
            .endif
        .endif
    .endif

    INIDelSection(__CFBase, ".openfiles")
    TISaveSession(__CFBase, ".openfiles")
    CFWrite(strfcat(__srcfile, _pgmpath, addr DZ_INIFILE))
    mov eax,1
    ret

config_save endp

config_open proc

    TIOpenSession(__CFBase, ".openfiles")
    ;
    ; Remove section
    ;
    INIDelSection(__CFBase, ".openfiles")

    mov eax,1
    ret

config_open endp

setconfirmflag proc

    mov edx,CFSELECTED
    mov eax,config.c_cflag
    .if eax & _C_CONFDELETE
        or edx,CFDELETEALL
    .endif
    .if eax & _C_CONFDELSUB
        or edx,CFDIRECTORY
    .endif
    .if eax & _C_CONFSYSTEM
        or edx,CFSYSTEM
    .endif
    .if eax & _C_CONFRDONLY
        or edx,CFREADONY
    .endif
    mov confirmflag,edx
    ret

setconfirmflag endp

historymove proc private uses rsi rdi direction:int_t

  local tmpPath:DIRECTORY

    mov rax,history
    .if rax

        lea rdi,tmpPath
        mov rsi,rax
        mov ecx,DIRECTORY
        mov edx,DIRECTORY * (MAXHISTORY-1)

        .if !direction

            add rsi,rdx
            rep movsb
            mov rdi,rax
            mov rsi,rax
            add rsi,DIRECTORY
            mov ecx,edx
            xchg rsi,rdi
            dec edx
            add rsi,rdx
            add rdi,rdx
            inc edx
            std
            rep movsb
            lea rsi,tmpPath
            mov rdi,rax
            mov ecx,DIRECTORY
            cld
        .else
            rep movsb
            mov rdi,rax
            lea rsi,[rax+DIRECTORY]
            mov ecx,edx
            rep movsb
            lea rsi,tmpPath
            mov rdi,rax
            mov ecx,DIRECTORY
            add rdi,rdx
        .endif
        rep movsb
    .endif
    ret

historymove endp


historysave proc uses rsi

    mov rax,cpanel
    mov rax,[rax].PANEL.wsub
    mov edx,[rax].WSUB.flag
    xor eax,eax

    .if !( edx & _W_ARCHIVE or _W_ROOTDIR )

        lea rsi,_bufin

        .if _getcwd(rsi, _MAX_PATH)

            mov rax,history
            .if rax

                mov rax,[rax]
                .if rax

                    .ifd !strcmp(rsi, rax)

                        .return
                    .endif
                    xor eax,eax
                .endif

                historymove(eax)
                mov rsi,history
                mov rax,[rsi]
                free(rax)


                mov [rsi],_strdup(addr _bufin)
                mov rdx,cpanel
                mov eax,[rdx].PANEL.fcb_index
                mov [rsi].DIRECTORY.fcb_index,eax
                mov eax,[rdx].PANEL.cel_index
                mov [rsi].DIRECTORY.cel_index,eax
                mov rdx,[rdx]
                mov eax,[rdx]
                and eax,not _P_FLAGMASK
                mov [rsi].DIRECTORY.flag,eax
                inc eax
            .endif
        .endif
    .endif
    ret

historysave endp


DirectoryToCurrentPanel proc uses rsi rdi directory:PDIRECTORY

    mov rsi,directory
    xor eax,eax
    .if rsi

        .if rax != [rsi].DIRECTORY.path

            mov rdi,cpanel
            mov rdi,[rdi].PANEL.wsub
            mov edx,[rdi].WSUB.flag

            .if !( edx & _W_ARCHIVE or _W_ROOTDIR )

                mov eax,edx
                and eax,_P_FLAGMASK
                or  eax,[rsi].DIRECTORY.flag
                mov [rdi].WSUB.flag,eax
                mov eax,[rsi].DIRECTORY.fcb_index
                mov edx,[rsi].DIRECTORY.cel_index
                mov rcx,cpanel
                mov [rcx].PANEL.fcb_index,eax
                mov [rcx].PANEL.cel_index,edx

                cpanel_setpath([rsi].DIRECTORY.path)
                panel_redraw(cpanel)
                mov eax,1
            .endif
        .endif
    .endif
    ret

DirectoryToCurrentPanel endp


cmpathleft proc ; Alt-Left - Previous Directory

    historysave()
    historymove(1)
    .ifd !DirectoryToCurrentPanel(history)
        historymove(0)
    .endif
    ret

cmpathleft endp


cmpathright proc ; Alt-Right - Next Directory

    historysave()
    historymove(0)
    .ifd !DirectoryToCurrentPanel(history)
        historymove(1)
    .endif
    ret

cmpathright endp

doskeysave proc uses rbx

    .ifd strtrim(&com_base)

        mov rax,history
        .if ( rax == NULL )

            .return
        .endif

        lea rbx,[rax].HISTORY.doskey
        mov doskey_bindex,0
        mov doskey_isnext,0
        mov rax,[rbx]
        .if rax

            .ifd strcmp(&com_base, rax)

                free([rbx + LPSTR * (MAXDOSKEYS - 1)])
                memmove(&[rbx+LPSTR], rbx, LPSTR * (MAXDOSKEYS - 1))
            .else
                .return( 1 )
            .endif
        .endif
        _strdup(&com_base)
        mov [rbx],rax
        mov eax,1
    .endif
    ret

doskeysave endp


doskeytocommand proc private

    mov rax,history
    movzx ecx,doskey_bindex
    mov rax,[rax+rcx*LPSTR].HISTORY.doskey
    .if rax
        strcpy(&com_base, rax)
    .endif
    ret

doskeytocommand endp


CommandlineVisible proc private

    mov rax,DLG_Commandline
    mov eax,[rax]
    and eax,_D_ONSCR
    ret

CommandlineVisible endp


cmdoskeyup proc

    .ifd CommandlineVisible()

        mov eax,1
        .if doskey_isnext == al
            mov com_base,ah
        .else

            doskeytocommand()
            inc doskey_bindex
            .if ( doskey_bindex >= MAXDOSKEYS )
                mov doskey_bindex,0
            .endif
        .endif
        comevent(KEY_END)
        mov eax,1
        mov doskey_isnext,ah
    .endif
    ret

cmdoskeyup endp


cmdoskeydown proc

    .ifd CommandlineVisible()

        xor eax,eax
        .if doskey_isnext == al

            mov com_base,al
        .else
            .if doskey_bindex == al
                mov doskey_bindex,MAXDOSKEYS-1
            .else
                dec doskey_bindex
            .endif
            doskeytocommand()
        .endif
        comevent(KEY_END)
        mov eax,1
        mov doskey_isnext,al
    .endif
    ret

cmdoskeydown endp


history_event_list proc watcall uses rsi rbx dlg:PDOBJ, lst:PLOBJ

    mov rbx,dlg
    mov rax,[rbx].DOBJ.object
    mov rsi,rax
    mov ecx,[rdx].LOBJ.dcount

    .repeat
        or  [rax].TOBJ.flag,_O_STATE
        add rax,TOBJ
    .untilcxz
    mov ecx,[rdx].LOBJ.numcel
    mov eax,[rdx].LOBJ.index
    mov rdx,[rdx].LOBJ.list
    lea rdx,[rdx+rax*size_t]

    .while ecx
        mov rax,[rdx]
        .break .if !rax
        mov [rsi].TOBJ.data,rax
        and [rsi].TOBJ.flag,not _O_STATE
        add rdx,size_t
        add rsi,TOBJ
        dec ecx
    .endw
    dlinit(rbx)
    mov eax,1
    ret

history_event_list endp


cmhistory proc uses rdi rbx

  local ll:LOBJ

    .ifd CommandlineVisible()

        .if rsopen(IDD_DZHistory)

            mov rbx,rax
            lea rdi,ll
            xor eax,eax
            mov ecx,LOBJ
            rep stosb

            mov ll.lproc,&history_event_list
            mov ll.dcount,16

            mov rdx,history
            add rdx,HISTORY.doskey
            mov ll.list,rdx
            mov ecx,MAXDOSKEYS
            xor edi,edi

            .repeat
                .if rax != [rdx]
                    inc edi
                .endif
                add rdx,size_t
            .untilcxz

            mov ll.count,edi
            .if edi > 16
                mov edi,16
            .endif

            mov ll.numcel,edi
            mov al,doskey_bindex
            mov [rbx].DOBJ.index,al

            .if al >= 16
                mov [rbx].DOBJ.index,cl
            .endif

            lea rdx,ll
            mov tdllist,rdx
            history_event_list(rbx, rdx)
            dlshow(rbx)
            mov edi,rsevent(IDD_DZHistory, rbx)
            dlclose(rbx)

            mov eax,edi
            .if eax
                dec  eax
                mov  doskey_bindex,al
                inc  eax
                imul eax,eax,TOBJ
                strcpy(&com_base, [rbx+rax].TOBJ.data)
                comevent(KEY_END)
                mov eax,1
            .endif
        .endif
    .endif
    ret

cmhistory endp

    END
