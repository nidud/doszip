; CMATTRIB.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include string.inc
include wsub.inc
include stdlib.inc
include winnls.inc

.enumt AttribIDD : TOBJ {
    ID_DIALOG,
    ID_RDONLY,
    ID_HIDDEN,
    ID_SYSTEM,
    ID_ARCHIVE,
    ID_CREATEDATE,
    ID_CREATETIME,
    ID_MODDATE,
    ID_MODTIME,
    ID_ACCESSDATE,
    ID_ACCESSTIME,
    ID_SET,
    ID_CANCEL
    }

.code

 assume rbx:ptr SYSTEMTIME

StringToSystemDate proc uses rbx string:string_t, lpSystemTime:ptr SYSTEMTIME

   .new v0:int_t,v1,wc
    ldr rbx,lpSystemTime
    ldr rcx,string
    mov rdx,rcx
    .repeat
       movzx eax,char_t ptr [rdx]
       add rdx,char_t
    .until ( eax > '9' || eax < '0' )
    mov wc,eax
    mov string,rdx
    mov v0,atol(rcx)
    mov v1,atol(string)
    mov rcx,string
    .repeat
       movzx eax,char_t ptr [rcx]
       add rcx,char_t
    .until ( eax > '9' || eax < '0' )
    atol(rcx)
    mov ecx,v0
    mov edx,v1
    .if ( g_DateFormat == 2 )       ; YMD
        mov [rbx].wYear,cx
        mov [rbx].wMonth,dx
        mov [rbx].wDay,ax
    .elseif ( g_DateFormat == 0 )   ; MDY
        mov [rbx].wYear,ax
        mov [rbx].wMonth,cx
        mov [rbx].wDay,dx
    .else
        mov [rbx].wYear,ax          ; DMY
        mov [rbx].wMonth,dx
        mov [rbx].wDay,cx
    .endif
    mov [rbx].wDayOfWeek,0
    mov rax,rbx
    ret
    endp

StringToSystemTime proc uses rbx string:string_t, lpSystemTime:ptr SYSTEMTIME

    ldr rcx,string
    ldr rbx,lpSystemTime
    mov rdx,rcx
    .repeat
        movzx eax,char_t ptr [rdx]
        add rdx,char_t
    .until ( eax > '9' || eax < '0' )
    mov string,rdx
    atol(rcx)
    mov [rbx].wHour,ax
    atol(string)
    mov [rbx].wMinute,ax
    mov rcx,string
    .repeat
        movzx eax,char_t ptr [rcx]
        add rcx,char_t
    .until ( eax > '9' || eax < '0' )
    atol(rcx)
    mov [rbx].wSecond,ax
    mov [rbx].wMilliseconds,0
    mov rax,rbx
    ret
    endp

    assume rbx:nothing

FileTimeToString proc string:string_t, ft:ptr FILETIME
   .new st_utc:SYSTEMTIME, st_local
    FileTimeToSystemTime(ft, &st_utc)
    SystemTimeToTzSpecificLocalTime(NULL, &st_utc, &st_local)
    SystemTimeToString(string, &st_local)
    ret
    endp

FileDateToString proc string:string_t, ft:ptr FILETIME
   .new st_utc:SYSTEMTIME, st_local
    FileTimeToSystemTime(ft, &st_utc)
    SystemTimeToTzSpecificLocalTime(NULL, &st_utc, &st_local)
    SystemDateToString(string, &st_local)
    ret
    endp

StringToTime proc private ft:LPFILETIME, lpTime:LPSTR, lpDate:LPSTR
   .new st_utc:SYSTEMTIME
   .new st_local:SYSTEMTIME
    StringToSystemTime(lpTime, &st_local)
    StringToSystemDate(lpDate, &st_local)
    .ifd TzSpecificLocalTimeToSystemTime(NULL, &st_local, &st_utc)
        .return SystemTimeToFileTime(&st_utc, ft)
    .endif
    .return( FALSE )
    endp


cmfileattrib proc private uses rsi rdi rbx name:LPSTR, fblk:PFBLK, flag:UINT

  local ft:FILETIME

    mov rdi,scan_fblock
    .if rsopen(IDD_DZFileAttributes)

        mov rbx,rax
        mov al,_O_FLAGB
        mov edx,flag
        .if dl & _A_RDONLY
            or [rbx+ID_RDONLY],al
        .endif
        .if dl & _A_HIDDEN
            or [rbx+ID_HIDDEN],al
        .endif
        .if dl & _A_SYSTEM
            or [rbx+ID_SYSTEM],al
        .endif
        .if dl & _A_ARCH
            or [rbx+ID_ARCHIVE],al
        .endif

        .if wsfindfirst(name, rdi, 0x00FF) != -1

            wscloseff(rax)

            FileTimeToString([rbx].TOBJ.data[ID_ACCESSTIME], &[rdi].WIN32_FIND_DATA.ftLastAccessTime)
            FileDateToString([rbx].TOBJ.data[ID_ACCESSDATE], &[rdi].WIN32_FIND_DATA.ftLastAccessTime)
            FileTimeToString([rbx].TOBJ.data[ID_CREATETIME], &[rdi].WIN32_FIND_DATA.ftCreationTime)
            FileDateToString([rbx].TOBJ.data[ID_CREATEDATE], &[rdi].WIN32_FIND_DATA.ftCreationTime)
            FileTimeToString([rbx].TOBJ.data[ID_MODTIME], &[rdi].WIN32_FIND_DATA.ftLastWriteTime)
            FileDateToString([rbx].TOBJ.data[ID_MODDATE], &[rdi].WIN32_FIND_DATA.ftLastWriteTime)

            dlinit(rbx)
            dlshow(rbx)

            movzx ecx,[rbx].DOBJ.rc.x
            movzx edx,[rbx].DOBJ.rc.y
            add ecx,19
            add edx,2
            scpath(ecx, edx, 21, name)

            .ifd dlevent(rbx)

                mov al,_O_FLAGB
                xor edx,edx
                .if [rbx+ID_RDONLY] & al
                    or dl,_A_RDONLY
                .endif
                .if [rbx+ID_SYSTEM] & al
                    or dl,_A_SYSTEM
                .endif
                .if [rbx+ID_ARCHIVE] & al
                    or dl,_A_ARCH
                .endif
                .if [rbx+ID_HIDDEN] & al
                    or dl,_A_HIDDEN
                .endif
                mov al,byte ptr flag
                and al,_A_ARCH or _A_SYSTEM or _A_HIDDEN or _A_RDONLY
                .if al != dl
                    mov edi,edx
                    mov rsi,_utftows(name)
                    .if ( flag & _A_SUBDIR )
                        _wsetfattr(rsi, 0)
                    .endif
                    _wsetfattr(rsi, edi)
                .endif
                .ifd ( osopen(name, _FA_NORMAL, M_WRONLY, A_OPEN) != -1 )
                    mov esi,eax
                    .ifd ( _get_osfhandle(eax) != -1 )
                        mov rdi,rax
                        mov _diskflag,1
                        .ifd StringToTime(&ft, [rbx].TOBJ.data[ID_MODTIME], [rbx].TOBJ.data[ID_MODDATE])
                            SetFileTime(rdi, NULL, NULL, &ft)
                        .endif
                        .ifd StringToTime(&ft, [rbx].TOBJ.data[ID_ACCESSTIME], [rbx].TOBJ.data[ID_ACCESSDATE])
                            SetFileTime(rdi, NULL, &ft, NULL)
                        .endif
                        .ifd StringToTime(&ft, [rbx].TOBJ.data[ID_CREATETIME], [rbx].TOBJ.data[ID_CREATEDATE])
                            SetFileTime(rdi, &ft, NULL, NULL)
                        .endif
                    .endif
                    _close(esi)
                .endif
            .endif
        .endif
        dlclose(rbx)
    .endif
    ret
    endp

cmzipattrib proc private uses rsi rdi rbx wsub:PWSUB, fblk:PFBLK

   .new x:int_t, y:int_t

    mov rdi,fblk
    mov ecx,[rdi].FBLK.flag

    .if !( cl & _A_SUBDIR )
        mov ebx,ecx

        .ifd wsopenarch(wsub) != -1

            mov esi,eax
            ;
            ; CRC, compressed size and local offset stored at end of FBLK
            ;
            mov zip_central.crc,[rdi+FBLK].ZINF.crc
            mov zip_central.csize,[rdi+FBLK].ZINF.csize
            mov zip_central.off_local,[rdi+FBLK].ZINF.offs
            ;
            ; seek to and read local offset
            ;
            _lseek(esi, rax, SEEK_SET)
            osread(esi, &zip_local, LZIP)
            mov edi,ebx ; FBLK.flag

            .if ( eax == LZIP &&
                  word ptr zip_local.zipid == ZIPLOCALID &&
                  word ptr zip_local.pkzip == ZIPHEADERID )

                mov ebx,osread(esi, entryname, zip_local.fnsize)
                _close(esi)

                .if ( bx == zip_local.fnsize )

                    add rbx,entryname
                    mov byte ptr [rbx],0

                    .if rsopen(IDD_DZZipAttributes)

                        mov rsi,rax
                        dlshow(rsi)

                        movzx ecx,[rsi].DOBJ.rc.x
                        movzx ebx,[rsi].DOBJ.rc.y
                        add ebx,1
                        add ecx,4
                        mov x,ecx
                        scpath(ecx, ebx, 54, entryname)

                        and edi,_A_FATTRIB
                        add ebx,3
                        add x,23

                        scputf(x, ebx, 0, 0,
                            "%08X\n%04X\n%04X\n%04X\n%04X\n%04X\n%08X\n%08X\n%08X\n%04X\n%04X\n\n\n%04X\n%08X\n%08X\n%08X\n",
                            dword ptr zip_local,
                            zip_local.version,  ; version needed to extract
                            zip_local.flag,     ; general purpose bit flag
                            zip_local.method,   ; compression method
                            zip_local.time,     ; last mod file time
                            zip_local.date,     ; last mod file date
                            zip_local.crc,      ; crc-32
                            zip_local.csize,    ; compressed size
                            zip_local.fsize,    ; uncompressed size
                            zip_local.fnsize,   ; file name length
                            zip_local.extsize,  ; extra field length
                            edi,
                            zip_central.off_local,
                            zip_central.csize,
                            zip_central.crc)

                        add ebx,7
                        add x,8
                        scputf(x, ebx, 0, 0, "%16u\n%16u\n%16u\n%16u\n",
                            zip_local.csize,    ; compressed size
                            zip_local.fsize,    ; uncompressed size
                            zip_local.fnsize,   ; file name length
                            zip_local.extsize ) ; extra field length

                        add ebx,6
                        add x,18
                        .if edi & _A_RDONLY
                            scputc(x, ebx, 1, 'x')
                        .endif
                        inc ebx
                        .if edi & _A_HIDDEN
                            scputc(x, ebx, 1, 'x')
                        .endif
                        inc ebx
                        .if edi & _A_SYSTEM
                            scputc(x, ebx, 1, 'x')
                        .endif
                        inc ebx
                        .if edi & _A_ARCH
                            scputc(x, ebx, 1, 'x')
                        .endif
                        dlevent(rsi)
                        dlclose(rsi)
                    .endif
                .else
                    xor eax,eax
                .endif
            .else
                _close(esi)
            .endif
        .endif
    .endif
    ret
    endp

cmattrib proc
    mov rax,cpanel
    .switch
      .case !panel_curobj(rax)
      .case ecx & _FB_ROOTDIR
        .endc
      .case ecx & _FB_ARCHZIP
        mov rcx,cpanel
        cmzipattrib([rcx].PANEL.wsub, rdx)
       .endc
    .default
        cmfileattrib(rax, rdx, ecx)
       .endc
    .endsw
    ret
    endp

    END

