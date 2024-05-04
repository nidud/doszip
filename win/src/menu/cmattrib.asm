; CMATTRIB.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include string.inc
include wsub.inc

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

StringToTime proc private lpTime:LPSTR, lpDate:LPSTR

   .new FileTime:FILETIME
   .new SystemTime:SYSTEMTIME
   .new FatTime:uint_t
   .new FatDate:uint_t

    StringToSystemTimeA(lpTime, &SystemTime)
    StringToSystemDateA(lpDate, &SystemTime)
    SystemTimeToFileTime(&SystemTime, &FileTime)
    LocalFileTimeToFileTime(&FileTime, &FileTime)
    FileTimeToDosDateTime(&FileTime, &FatDate, &FatTime)

    mov eax,FatTime
    mov edx,FatDate
    shl edx,16
    and eax,0xFFFF
    or  eax,edx
    ret

StringToTime endp


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

            FileTimeToStringA([rbx].TOBJ.data[ID_ACCESSTIME], &[rdi].WIN32_FIND_DATA.ftLastAccessTime)
            FileDateToStringA([rbx].TOBJ.data[ID_ACCESSDATE], &[rdi].WIN32_FIND_DATA.ftLastAccessTime)
            FileTimeToStringA([rbx].TOBJ.data[ID_CREATETIME], &[rdi].WIN32_FIND_DATA.ftCreationTime)
            FileDateToStringA([rbx].TOBJ.data[ID_CREATEDATE], &[rdi].WIN32_FIND_DATA.ftCreationTime)
            FileTimeToStringA([rbx].TOBJ.data[ID_MODTIME], &[rdi].WIN32_FIND_DATA.ftLastWriteTime)
            FileDateToStringA([rbx].TOBJ.data[ID_MODDATE], &[rdi].WIN32_FIND_DATA.ftLastWriteTime)

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
                    .if flag & _A_SUBDIR
                        mov flag,edx
                        setfattr(name, 0)
                        mov edx,flag
                    .endif
                    setfattr(name, edx)
                .endif

                .ifd osopen(name, _A_NORMAL, M_WRONLY, A_OPEN) != -1

                    mov esi,eax
                    setftime(esi,
                        StringToTime([rbx].TOBJ.data[ID_MODTIME], [rbx].TOBJ.data[ID_MODDATE]))
                    setftime_create(esi,
                        StringToTime([rbx].TOBJ.data[ID_CREATETIME], [rbx].TOBJ.data[ID_CREATEDATE]))
                    setftime_access(esi,
                        StringToTime([rbx].TOBJ.data[ID_ACCESSTIME], [rbx].TOBJ.data[ID_ACCESSDATE]))
                    _close(esi)
                .endif
            .endif
        .endif
        dlclose(rbx)
    .endif
    ret

cmfileattrib endp

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
            strlen(&[rdi].FBLK.name)
            add rax,FBLK
            add rdi,rax
            mov zip_central.crc,[rdi+4]
            mov zip_central.csize,[rdi+8]
            mov zip_central.off_local,[rdi]
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

cmzipattrib endp


cmattrib proc

    mov rax,cpanel
    .switch
      .case !panel_curobj(rax)
      .case ecx & _FB_ROOTDIR
        .endc
      .case ecx & _FB_ARCHIVE
        mov rcx,cpanel
        cmzipattrib([rcx].PANEL.wsub, rdx)
       .endc
    .default
        cmfileattrib(rax, rdx, ecx)
       .endc
    .endsw
    ret

cmattrib endp

    END

