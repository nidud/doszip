include malloc.inc
include string.inc
include io.inc
include direct.inc
include time.inc
include stdlib.inc
include wsub.inc
include config.inc
include conio.inc
include errno.inc
include doszip.inc
include filter.inc
include progress.inc
include confirm.inc

ZSUB    STRUC
wsub    WSUB <>
index   SINT ?
result  SINT ?
ZSUB    ENDS

define WMAXPATH             2048
define MAXFINDHANDLES       20
define ERROR_NO_MORE_FILES  18
define WSSIZE               (WMAXPATH + _MAX_PATH*3)
define DC_MAXOBJ            5000 ; Max number of files in one subdir (recursive)
define ZIP_CENTRALID        0x02014B50 ; signature central file
define ZIP_ENDSENTRID       0x06054B50 ; signature end central

    .data
     fp_maskp       LPSTR NULL
     fp_directory   FPDIR NULL
     fp_fileblock   FPBLK NULL
     scan_fblock    PWIN32_FIND_DATAA NULL
     scan_curpath   LPSTR NULL
     scan_curfile   LPSTR NULL
     o_list         PLOBJ NULL
     o_wsub         PWSUB NULL
     dialog         PDOBJ NULL
     _attrib        UINT MAXFINDHANDLES dup(0)
     wsortflag      UINT 0
     a_open         UINT 0
     zip_attrib     UINT 0
     zip_flength    UINT 0
     zip_local      LZIP <0>
     zip_central    CZIP <0>
     zip_endcent    ZEND <0,0,0,0,0,0,0,0>
     ocentral       IOST <>
     key0           UINT 0
     key1           UINT 0
     key2           UINT 0
     arc_pathz      UINT 0
     password       SBYTE 80 dup(0)
     cp_stdmask     SBYTE "*.*",0
     cp_ziptemp     SBYTE ".$$$",0
     cp_emarchive   SBYTE "Error in archive",0

    .code

    option dotname

fballoc proc uses rbx fname:LPSTR, ftime:dword, fsize:qword, flag:dword

    .if malloc(&[strlen(fname)+FBLK])

        mov rbx,rax
        add rax,FBLK.name
        strcpy(rax, fname)
        mov eax,flag
        mov [rbx].FBLK.flag,eax
        mov eax,ftime
        mov [rbx].FBLK.time,eax
        mov eax,dword ptr fsize[0]
        mov dword ptr [rbx].FBLK.size,eax
        mov eax,dword ptr fsize[4]
        mov dword ptr [rbx].FBLK.size[4],eax
        mov rax,rbx
    .endif
    ret

fballoc endp


fbffirst proc private fcb:PVOID, count:UINT

    xor edx,edx
    xor eax,eax
    .while edx < count

        mov rax,fcb
        mov rax,[rax+rdx*PFBLK]
        mov ecx,[rax].FBLK.flag
        .break .if ecx & _FB_SELECTED
        inc edx
        xor eax,eax
    .endw
    ret

fbffirst endp

fbinvert proc fblk:PFBLK

    mov rax,fblk
    .if ![rax].FBLK.flag & _FB_UPDIR
        xor [rax].FBLK.flag,_FB_SELECTED
    .else
        xor eax,eax
    .endif
    ret

fbinvert endp

fbselect proc fblk:PFBLK

    mov rax,fblk
    .if !( [rax].FBLK.flag & _FB_UPDIR )
        or [rax].FBLK.flag,_FB_SELECTED
    .else
        xor eax,eax
    .endif
    ret

fbselect endp

fbupdir proc flag

  local ts:SYSTEMTIME

    GetLocalTime(&ts)
    SystemTimeToTime(&ts)
    mov ecx,flag
    or  ecx,_FB_UPDIR or _A_SUBDIR
    fballoc("..", eax, 0, ecx)
    ret

fbupdir endp

fbcolor proc uses rsi rdi fp:PFBLK

    mov rsi,fp
    .while 1

        .if !( [rsi].FBLK.flag & _A_SUBDIR )
            lea rdi,[rsi].FBLK.name
            .if strext(rdi)
                lea rdi,[rax+1]
            .endif
            .if CFGetSection("FileColor")
                .if INIGetEntry(rax, rdi)
                    .if strtolx(rax) <= 15
                        shl eax,4
                        .if al != at_background[B_Panel]
                            shr eax,4
                           .break
                        .endif
                    .endif
                .endif
            .endif
        .endif

        mov eax,[rsi].FBLK.flag
        .switch
          .case eax & _FB_SELECTED
            mov al,at_foreground[F_Panel]
            .break
          .case eax & _FB_UPDIR
            mov al,7
            .break
          .case eax & _FB_ROOTDIR
          .case eax & _A_SYSTEM
            mov al,at_foreground[F_System]
            .break
          .case eax & _A_HIDDEN
            mov al,at_foreground[F_Hidden]
            .break
          .case eax & _A_SUBDIR
            mov al,at_foreground[F_Subdir]
            .break
          .default
            mov al,at_foreground[F_Files]
            .break
        .endsw
    .endw
    or al,at_background[B_Panel]
    movzx eax,al
    ret

fbcolor endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wsfindnext proc private uses rsi rdi ff:PWIN32_FIND_DATA, handle:HANDLE

    .new wf:WIN32_FIND_DATAW
    .while FindNextFileW(handle, &wf)

        mov eax,wf.dwFileAttributes
        and eax,0xFF
        mov ecx,_attrib
        not cl
        and eax,ecx
        .ifz
            mov rdi,ff
            lea rsi,wf
            mov ecx,WIN32_FIND_DATA.cFileName / 4
            rep movsd
            lea rcx,[rdi+260]
            lea rdx,[rsi+520]
            .repeat
                lodsw
                stosb
            .until !al
            mov rdi,rcx
            mov rsi,rdx
            .repeat
                lodsw
                stosb
            .until !al
            .return( 0 )
        .endif
    .endw
    osmaperr()
    ret

wsfindnext endp

scan_directory proc uses rsi rdi rbx flag:UINT, directory:LPSTR

   .new result:int_t = 0

    mov rdi,scan_fblock
    .if ( flag & 1 )
        mov result,fp_directory(directory)
    .endif

    .if ( result == 0 )

        add strlen(directory),scan_curpath
        mov rbx,rax

        .if wsfindfirst(strfcat(scan_curpath, directory, &cp_stdmask), rdi, ATTRIB_ALL) != -1

            mov rsi,rax
            .if !wsfindnext(rdi, rsi)

                .while !wsfindnext(rdi, rsi)

                    .if ( [rdi].WIN32_FIND_DATA.dwFileAttributes & _A_SUBDIR )

                        strcpy(&[rbx+1], &[rdi].WIN32_FIND_DATA.cFileName)
                        mov result,scan_directory(flag, scan_curpath)
                        .break .if eax
                    .endif
                .endw
            .endif
            wscloseff(rsi)
            mov byte ptr [rbx],0
        .endif
        mov eax,result
        .if ( !eax && !( flag & 1 ) )
            fp_directory(directory)
        .endif
    .endif
    ret

scan_directory endp

scan_files proc uses rsi rdi rbx directory:LPSTR

    xor edi,edi
    mov rbx,scan_fblock

    .if wsfindfirst(strfcat(scan_curfile, directory, fp_maskp), rbx, ATTRIB_FILE) != -1

        mov rsi,rax
        .repeat
            .if !( [rbx].WIN32_FIND_DATA.dwFileAttributes & _A_SUBDIR )

                mov edi,fp_fileblock(directory, rbx)
               .break .if eax
            .endif
        .until wsfindnext(rbx, rsi)
        wscloseff(rsi)
    .endif
    mov eax,edi
    ret

scan_files endp


scansub proc directory:LPSTR, mask:LPSTR, flag:UINT

    mov fp_maskp,mask
    scan_directory(flag, directory)
    ret

scansub endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wsffirst proc wsub:PWSUB

    ldr rax,wsub
    fbffirst([rax].WSUB.fcb, [rax].WSUB.count)
    ret

wsffirst endp

    assume rsi:PWSUB

wsopen proc uses rsi rdi wsub:PWSUB

    ldr rsi,wsub

    .if !( [rsi].flag & _W_MALLOC )

        .if !malloc(WSSIZE)

            .return
        .endif

        memset(rax, 0, WSSIZE)
        mov [rsi].path,rax
        add rax,WMAXPATH
        mov [rsi].arch,rax
        add rax,_MAX_PATH
        mov [rsi].file,rax
        add rax,_MAX_PATH
        mov [rsi].mask,rax
        xor eax,eax
        mov [rsi].count,eax
        mov [rsi].fcb,rax
        or  [rsi].flag,_W_MALLOC
    .endif

    free([rsi].fcb)
    imul edi,[rsi].maxfb,size_t
    mov [rsi].fcb,malloc(edi)
    .if rax
        memset(rax, 0, edi)
        mov eax,1
    .endif
    ret

wsopen endp

wssetflag proc private uses rsi rdi wsub:PWSUB

    ldr rsi,wsub
    mov edi,[rsi].flag
    and edi,not _W_NETWORK
    mov [rsi].flag,edi
    mov rax,[rsi].path
    mov eax,[rax]
    .repeat
        .if ah == '\'
            mov eax,3
            or  edi,_W_NETWORK
           .break
        .endif
        .if ah != ':'
            xor eax,eax
           .break
        .endif
        or  al,20h
        sub al,'a' - 1
        movzx eax,al
        .switch _disk_type(eax)
        .case _DISK_SUBST
            mov eax,2
        .case DRIVE_CDROM
            or edi,_W_CDROOM
           .break
        .case DRIVE_REMOVABLE
            or edi,_W_REMOVABLE
           .break
        .case DRIVE_REMOTE
            or edi,_W_NETWORK or _W_CDROOM
            mov eax,3
           .break
        .endsw
        and eax,1
    .until 1
    mov [rsi].flag,edi
    ret

wssetflag endp

wslocal proc private wsub:PWSUB

    ldr rcx,wsub
    .if _getcwd([rcx].WSUB.path, WMAXPATH)
        wssetflag(wsub)
    .endif
    ret

wslocal endp

wsinit proc uses rsi rdi rbx wsub:PWSUB

   .new path:DWORD
    ldr rdi,wsub
    mov rsi,[rdi].WSUB.path

    .if byte ptr [rsi] == 0
        GetCurrentDirectory(WMAXPATH, rsi)
    .endif

    .if SetCurrentDirectory(rsi)

        .if GetCurrentDirectory(WMAXPATH, rsi)

            movzx eax,word ptr [rsi]
            .if ah == ':'
                .if al <= 'z' && al >= 'a'
                    sub al,'a' - 'A'
                .endif
                shl eax,8
                mov al,'='
                mov path,eax
                SetEnvironmentVariable(&path, rsi)
            .endif
        .endif
    .endif

    .if !wssetflag(rdi)

        ermsg(0, "Error init directory\n%s", [rdi].WSUB.path)
        wslocal(rdi)

    .elseif ( eax != 1 && eax != 3 )

        wslocal(rdi)
    .endif
    ret

wsinit endp

wsfree proc uses rsi rdi rbx wsub:PWSUB

    xor eax,eax
    ldr rcx,wsub
    mov edi,[rcx].WSUB.count
    mov [rcx].WSUB.count,eax
    mov rsi,[rcx].WSUB.fcb
    .if rsi

        mov ebx,edi
        .while edi

            free([rsi])
            xor eax,eax
            mov [rsi],rax
            add rsi,size_t
            dec rdi
        .endw
        mov eax,ebx
    .endif
    ret

wsfree endp

wsclose proc uses rsi rdi wsub:PWSUB

    ldr rsi,wsub
    mov edi,wsfree(rsi)
    free([rsi].fcb)
    .if [rsi].flag & _W_MALLOC

        free([rsi].path)
    .endif
    xor eax,eax
    mov [rsi].flag,eax
    mov [rsi].fcb,rax
    mov eax,edi
    ret

wsclose endp

wsextend proc uses rsi rdi rbx wsub:PWSUB

    ldr rsi,wsub
    mov edi,[rsi].maxfb
    add edi,edi

    .if malloc( &[rdi*size_t] )

        mov rbx,rax
        lea ecx,[rdi*size_t]
        mov edx,edi
        mov rdi,rax
        xor eax,eax
        rep stosb

        mov edi,edx
        mov ecx,[rsi].maxfb

        memcpy(rbx, [rsi].fcb, &[rcx*size_t])
        free([rsi].fcb)

        mov [rsi].fcb,rbx
        mov [rsi].maxfb,edi
        mov eax,edi
    .endif
    ret

wsextend endp

    assume rsi:nothing

wschdrv proc wsub:PWSUB, drive:UINT

  local lpFileName:DWORD,     ; name of file to find path for
        lpBuffer[512]:sbyte,  ; path buffer
        lpFilePart:LPSTR      ; filename in path

    mov eax,drive
    add eax,'.:@'
    mov lpFileName,eax

    .if GetFullPathName(&lpFileName, 512, &lpBuffer, &lpFilePart)

        mov rcx,wsub
        and [rcx].WSUB.flag,not (_W_ARCHIVE or _W_ROOTDIR)
        strcpy([rcx].WSUB.path, &lpBuffer)
        wssetflag(wsub)
    .endif
    ret

wschdrv endp

wsfblk proc wsub:PWSUB, index:UINT

    ldr eax,index
    ldr rdx,wsub

    .ifs [rdx].WSUB.count <= eax
        xor eax,eax
    .else
        imul eax,eax,size_t
        add  rax,[rdx].WSUB.fcb  ; EDX wsub
        mov  rax,[rax]           ; EAX fblk
        mov  ecx,[rax].FBLK.flag ; ECX fblk.flag
    .endif
    ret

wsfblk endp

wsfindfirst proc uses rsi rdi rbx fmask:LPSTR, fblk:PWIN32_FIND_DATA, attrib:UINT

   .new h:HANDLE
    ;
    ; @v3.31 - single file fails in FindFirstFileW
    ;
    xor ebx,ebx
    ldr rax,fmask
    mov ax,[rax]

ifdef _WIN95
    .if ah == ':' && !( console & CON_WIN95 )
else
    .if ah == ':'
endif
        inc ebx
        mov rcx,alloca(WMAXPATH + sizeof(WIN32_FIND_DATAW))
        mov rdi,rax
        mov rsi,fmask
        mov eax,'\'
        stosw
        stosw
        mov al,'?'
        stosw
        mov al,'\'
        stosw
        .repeat
            lodsb
            stosw
        .until !al
        lea rsi,[rcx+WMAXPATH]
        mov [rsi].WIN32_FIND_DATAW.cFileName,ax
        mov [rsi].WIN32_FIND_DATAW.cAlternateFileName,ax
        FindFirstFileW(rcx, rsi)
    .else
        FindFirstFileA(fmask, fblk)
    .endif

    .if rax != -1

        mov h,rax
        .if ebx

            mov rdi,fblk
            mov ecx,WIN32_FIND_DATA.cFileName / 4
            rep movsd
            lea rcx,[rdi+260]
            lea rdx,[rsi+520]
            .repeat
                lodsw
                stosb
            .until !al
            mov rdi,rcx
            mov rsi,rdx
            .repeat
                lodsw
                stosb
            .until !al
        .endif

        lea rdx,_attrib
        lea rcx,[rdx+4]
        memmove(rcx, rdx, 4 * (MAXFINDHANDLES - 1))
        mov rcx,fblk
        mov eax,attrib
        mov _attrib,eax
        mov rax,h
    .else
        osmaperr()
    .endif
    ret

wsfindfirst endp

wscloseff proc handle:HANDLE

    memcpy(&_attrib, &_attrib[4], 4 * (MAXFINDHANDLES - 1))
    .if FindClose(handle)
        xor eax,eax
    .else
        osmaperr()
    .endif
    ret

wscloseff endp

wsreadwf proc private uses rsi rdi rbx wsub:PWSUB, attrib:uint_t

  local path[WMAXPATH]:byte, wf:WIN32_FIND_DATA, fsize:qword

    lea rdi,wf
    ldr rbx,wsub

    .ifd wsfindfirst(strfcat(&path, [rbx].WSUB.path, &cp_stdmask), rdi, attrib) != -1

        mov rsi,rax
        xor eax,eax
        mov edx,'.'

        .while ( byte ptr [rdi] & _A_VOLID ||
                 word ptr [rdi].WIN32_FIND_DATA.cFileName == dx ||
                 word ptr [rdi].WIN32_FIND_DATA.cFileName[1] == dx )

            .break .if wsfindnext(rdi, rsi)
            mov edx,'.'
        .endw

        .while !eax

            inc eax
            .if !( byte ptr [rdi] & _A_SUBDIR )

                cmpwarg( &[rdi].WIN32_FIND_DATA.cFileName, [rbx].WSUB.mask )
            .endif

            .if eax

                mov eax,[rdi].WIN32_FIND_DATA.nFileSizeLow
                mov dword ptr fsize,eax
                mov eax,[rdi].WIN32_FIND_DATA.nFileSizeHigh
                mov dword ptr fsize[4],eax
                mov ecx,[rdi].WIN32_FIND_DATA.dwFileAttributes
                lea rax,[rdi].WIN32_FIND_DATA.ftLastWriteTime
                .if ecx & _A_SUBDIR
                    lea rax,[rdi].WIN32_FIND_DATA.ftCreationTime
                .endif
                FileTimeToTime(rax)
                mov edx,[rdi].WIN32_FIND_DATA.dwFileAttributes
                and edx,_A_FATTRIB
                lea rcx,[rdi].WIN32_FIND_DATA.cFileName
                .if ( !( [rbx].WSUB.flag & _W_LONGNAME) &&
                      console & CON_IOSFN && [rdi].WIN32_FIND_DATA.cAlternateFileName )

                    lea rcx,[rdi].WIN32_FIND_DATA.cAlternateFileName
                .endif
                .break .if !fballoc(rcx, eax, fsize, edx)
                mov ecx,[rbx].WSUB.count
                mov rdx,[rbx].WSUB.fcb
                mov [rdx+rcx*size_t],rax
                inc ecx
                mov [rbx].WSUB.count,ecx
                .if ecx >= [rbx].WSUB.maxfb
                    .break .if !wsextend(rbx)
                .endif
            .endif
            wsfindnext(rdi, rsi)
        .endw
        wscloseff(rsi)
    .endif
    mov eax,[rbx].WSUB.count
    ret

wsreadwf endp

define _A_STDFILES (_A_ARCH or _A_RDONLY or _A_SYSTEM or _A_SUBDIR or _A_NORMAL)
define _A_ALLFILES (_A_STDFILES or _A_HIDDEN)

wsread proc uses rbx wsub:PWSUB

    ldr rbx,wsub
    wsfree(rbx)

    mov rax,[rbx].WSUB.path
    movzx eax,word ptr [rax+2]
    mov edx,_FB_ROOTDIR

    .if ( al && eax != '\' && eax != '/' )
        xor edx,edx
    .endif

    .if fbupdir(edx)

        inc [rbx].WSUB.count
        mov rdx,[rbx].WSUB.fcb
        mov [rdx],rax
        mov rdx,[rbx].WSUB.mask
        mov eax,'*'
        .if [rdx] == ah
            mov [rdx+2],ax
            mov [rdx],al
            mov byte ptr [rdx][1],'.'
        .endif
        mov edx,[rbx].WSUB.flag
        mov eax,_A_ALLFILES
        .if !( edx & _W_HIDDEN )
            mov eax,_A_STDFILES
        .endif
        wsreadwf(rbx, eax)
    .endif
    mov eax,[rbx].WSUB.count
    ret

wsread endp

wscopyremove proc file:LPSTR

    ioclose(&STDO)
    remove(file)
    or eax,-1
    ret

wscopyremove endp

wscopyopen proc srcfile:LPSTR, outfile:LPSTR

    mov errno,0
    .if !ioopen(&STDO, outfile, M_WRONLY, OO_MEM64K)
        mov copy_jump,1
    .elseif eax != -1

        ioopen(&STDI, srcfile, M_RDONLY, OO_MEM64K)
        or STDI.IOST.flag,IO_USECRC

        .if eax == -1

            eropen(srcfile)
            wscopyremove(outfile)
        .endif
    .endif
    ret

wscopyopen endp

compare proc private uses rsi rdi rbx a:PFBLK, b:PFBLK

    ldr rax,b
    mov rdi,[rax]
    mov edx,[rdi].FBLK.flag
    ldr rax,a
    mov rsi,[rax]
    mov ecx,[rsi].FBLK.flag

    mov eax,dword ptr [rsi].FBLK.name
    and eax,0x00FFFFFF

    cmp eax,'..'
    je  .9
    mov eax,ecx
    and edx,_A_SUBDIR
    and eax,_A_SUBDIR
    mov ecx,wsortflag
    jz  .1
    test edx,edx
    jz  .1
    test ecx,_W_SORTSUB
    jnz .2
    mov ecx,_W_SORTNAME
    jmp .3
.1:
    or  eax,edx
    jz  .2
    mov ecx,_W_SORTSUB
    jmp .3
.2:
    and ecx,_W_SORTSIZE
.3:
    cmp ecx,_W_SORTTYPE
    je  .4
    cmp ecx,_W_SORTDATE
    je  .6
    cmp ecx,_W_SORTSIZE
    je  .7
    cmp ecx,_W_SORTSUB
    je  .8
    jmp .N
.4:
    mov rbx,strext(&[rdi].FBLK.name)
    and rax,strext(&[rsi].FBLK.name)
    jz  .5
    and rbx,rbx
    jz  .A
    and eax,_stricmp(rax, rbx)
    jz  .N
    jmp .C
.5:
    and rbx,rbx
    jnz .9
    jmp .N
.6:
    mov ecx,[rsi].FBLK.time
    cmp ecx,[rdi].FBLK.time
    jb  .A
    ja  .9
    jmp .N
.7:
    mov ecx,dword ptr [rsi].FBLK.size[4]
    cmp ecx,dword ptr [rdi].FBLK.size[4]
    jb  .A
    ja  .9
    mov ecx,dword ptr [rsi].FBLK.size
    cmp ecx,dword ptr [rdi].FBLK.size
    jb  .A
    ja  .9
    jmp .N
.8:
    test [rdi].FBLK.flag,_A_SUBDIR
    jnz .A
.9:
    mov eax,-1
    jmp .C
.A:
    mov eax,1
    jmp .C
.N:
    add rdi,FBLK.name
    add rsi,FBLK.name
    _stricmp(rsi, rdi)
.C:
    ret

compare endp

wssort proc uses rsi rdi rbx wsub:PWSUB

   .new n:size_t
   .new p:PFBLK
   .new level:int_t = 0

    ldr rdx,wsub
    mov wsortflag,[rdx].WSUB.flag
    mov eax,[rdx].WSUB.count
    mov rsi,[rdx].WSUB.fcb
    mov p,rsi
    mov n,rax

    .if eax > 1

        dec eax
        lea rdi,[rsi+rax*size_t]

        .while 1

            lea rax,[rdi+size_t] ; middle from (hi - lo) / 2
            sub rax,rsi
            .ifnz
                xor edx,edx
                mov ecx,size_t
                div ecx
                shr eax,1
                mul ecx
            .endif
            lea rbx,[rsi+rax]
ifdef _WIN64
            sub rsp,0x20
endif
            .ifsd compare( rsi, rbx ) > 0

                mov rax,[rbx]
                mov rcx,[rsi]
                mov [rbx],rcx
                mov [rsi],rax
            .endif

            .ifsd compare( rsi, rdi ) > 0

                mov rax,[rdi]
                mov rcx,[rsi]
                mov [rdi],rcx
                mov [rsi],rax
            .endif

            .ifsd compare( rbx, rdi ) > 0

                mov rax,[rdi]
                mov rcx,[rbx]
                mov [rdi],rcx
                mov [rbx],rax
            .endif

            mov p,rsi
            mov n,rdi

            .while 1

                add p,size_t
                .if p < rdi
                    .continue .ifsd compare( p, rbx ) <= 0
                .endif

                .while 1

                    sub n,size_t
                    .break .if n <= rbx
                    .break .ifsd compare( n, rbx ) <= 0
                .endw

                mov rdx,n
                mov rax,p
                .break .if rdx < rax

                mov rcx,[rax]
                mov rax,[rdx]
                mov [rdx],rcx
                mov rcx,p
                mov [rcx],rax
                .if rbx == rdx

                    mov rbx,rcx
                .endif
            .endw

            add n,size_t
            .while 1

                sub n,size_t
                .break .if n <= rsi
                .break .ifd compare( rbx, n )
            .endw
ifdef _WIN64
            add rsp,0x20
endif
            mov rdx,p
            mov rax,n
            sub rax,rsi
            mov rcx,rdi
            sub rcx,rdx

            .ifs rax < rcx

                mov rcx,n

                .if rdx < rdi

                    push rdx
                    push rdi
                    inc level
                .endif

                .if rsi < rcx

                    mov rdi,rcx
                    .continue
                .endif
            .else
                mov rcx,n

                .if rsi < rcx

                    push rsi
                    push rcx
                    inc level
                .endif

                .if rdx < rdi

                    mov rsi,rdx
                    .continue
                .endif
            .endif

            .break .if !level
            dec level
            pop rdi
            pop rsi
        .endw
    .endif
    ret

wssort endp

wsearch proc uses rsi rdi wsub:PWSUB, string:LPSTR

    ldr rax,wsub
    mov esi,[rax].WSUB.count
    mov rdi,[rax].WSUB.fcb

    .repeat
        mov eax,-1
        .break .if !esi
        dec esi
        mov rax,[rdi]
        add rax,FBLK.name
        add rdi,size_t
        .continue(0) .if _stricmp(string, rax)
        mov rax,wsub
        mov eax,[rax].WSUB.count
        sub eax,esi
        dec eax
    .until 1
    ret

wsearch endp

ID_CNT      equ 13
ID_OK       equ ID_CNT
ID_EXIT     equ ID_CNT+1
ID_FILE     equ ID_CNT+2
ID_PATH     equ ID_CNT+3
ID_L_UP     equ ID_CNT+4
ID_L_DN     equ ID_CNT+5
O_PATH      equ ID_PATH*TOBJ+DOBJ
O_FILE      equ ID_FILE*TOBJ+DOBJ

    option proc:private

init_list proc uses rsi rdi rbx

   .new fp:PFBLK
   .new i:int_t = ID_CNT

    mov rbx,o_list
    mov [rbx].LOBJ.numcel,0
    imul eax,[rbx].LOBJ.index,size_t
    add rax,[rbx].LOBJ.list
    mov rdi,dialog
    mov ebx,[rdi].DOBJ.rc
    add ebx,[rdi].DOBJ.rc[TOBJ]
    mov rdi,[rdi].DOBJ.object
    mov rsi,rax

    .repeat

        mov rax,[rsi]
        add rsi,size_t
        or  [rdi].TOBJ.flag,_O_STATE

        .if rax

            mov fp,rax
            mov al,[rax]
            and al,_A_SUBDIR
            mov al,at_foreground[F_Dialog]
            .ifnz
                mov al,at_foreground[F_Inactive]
            .endif
            mov dl,bh
            scputfg(ebx, edx, 28, eax)
            inc bh

            mov rax,fp
            add rax,FBLK.name
            and [rdi].TOBJ.flag,not _O_STATE
            mov rdx,o_list
            inc [rdx].LOBJ.numcel
        .endif
        mov [rdi].TOBJ.data,rax
        add rdi,TOBJ
        dec i
    .untilz
    ret

init_list endp

event_list proc

    init_list()
    dlinit(dialog)
    mov eax,_C_NORMAL
    ret

event_list endp

read_wsub proc

    xor eax,eax
    mov rdx,o_list
    mov [rdx].LOBJ.index,eax
    mov [rdx].LOBJ.count,eax
    mov [rdx].LOBJ.numcel,eax
    wsread(o_wsub)
    mov rdx,o_list
    mov [rdx].LOBJ.count,eax
    .if eax > 1
        wssort(o_wsub)
    .endif
    ret

read_wsub endp

event_file proc uses rbx

    mov rax,dialog
    mov rbx,[rax].TOBJ.data[O_FILE]
    .if ( a_open & _WSAVE )
        .if !strrchr(rbx, '*')
            .if !strrchr(rbx, '?')
                .return(_C_NORMAL)
            .endif
        .endif
        .if ( a_open & _WLOCK )
            .return(_C_NORMAL)
        .endif
    .endif
    mov rcx,o_wsub
    strnzcpy([rcx].WSUB.mask, rbx, 32-1)
    read_wsub()
    event_list()
    .if ( wsearch(o_wsub, rbx) == -1 )
        .return(_C_NORMAL)
    .endif
    .return(_C_RETURN)

event_file endp

event_path proc

    read_wsub()
    event_list()
   .return(_C_NORMAL)

event_path endp

case_files proc uses rsi rdi rbx

    mov rbx,o_list
    mov eax,[rbx].LOBJ.index
    add eax,[rbx].LOBJ.celoff
    imul eax,eax,size_t
    add rax,[rbx].LOBJ.list
    mov rdi,[rax]
    mov eax,[rdi]

    .if !( al & _A_SUBDIR )

        mov rbx,dialog
        mov [rbx].DOBJ.index,ID_FILE
        lea rax,[rdi].FBLK.name
        strcpy([rbx].TOBJ.data[O_FILE], rax)

        .if ( event_file() == _C_RETURN )
            inc eax
        .else
            xor eax,eax
        .endif

    .else

        mov rbx,o_wsub
        .if ( eax & _FB_UPDIR )

            .if strfn([rbx].WSUB.path)

                mov rsi,rax
                xor eax,eax
                mov [rsi-1],al
                mov rbx,o_list
                mov [rbx].LOBJ.celoff,eax

                event_path()

                .if ( wsearch(o_wsub, rsi) != -1 )

                    .if ( eax < ID_CNT )

                        mov rcx,dialog
                        mov [rcx].DOBJ.index,al
                    .else
                        mov [rbx].LOBJ.index,eax
                    .endif
                    event_list()
                    xor eax,eax
                .endif
            .endif
        .else
            mov rcx,dialog
            mov [rcx].DOBJ.index,0
            lea rax,[rdi].FBLK.name
            strfcat([rbx].WSUB.path, 0, rax)
            event_path()
            xor eax,eax
        .endif
    .endif
    ret

case_files endp

    option proc:public

wdlgopen proc uses rsi rdi rbx path:LPSTR, mask:LPSTR, save:UINT

  local wsub:WSUB
  local list:LOBJ

    mov a_open,save
    mov o_wsub,&wsub
    mov o_list,&list

    mov rdi,rax
    mov ecx,LOBJ
    xor eax,eax
    rep stosb

    mov wsub.flag,eax
    mov wsub.maxfb,5000

    .if wsopen(o_wsub)

        strcpy(wsub.mask, mask)
        strcpy(wsub.path, path)
        xor edi,edi

        .if rsopen(IDD_WOpenFile)

            mov rbx,rax
            mov dialog,rax
            dlshow(rax)

            mov rax,wsub.path
            mov [rbx].TOBJ.data[O_PATH],rax
            mov [rbx].TOBJ.count[O_PATH],16
            strcpy([rbx].TOBJ.data[O_FILE], wsub.mask)
            mov [rbx].TOBJ.tproc[O_FILE],&event_file
            mov [rbx].TOBJ.tproc[O_PATH],&event_path
            mov list.lproc,&event_list
            mov list.dcount,ID_CNT
            mov list.celoff,ID_CNT
            mov rax,wsub.fcb
            mov list.list,rax

            .if a_open & _WSAVE

                mov dl,[rbx].DOBJ.rc.y
                mov cl,[rbx].DOBJ.rc.x
                add cl,21
                scputs(ecx, edx, 0, 0, "Save")
            .endif

            read_wsub()
            init_list()
            dlinit(rbx)

            .while dllevent(rbx, &list)

                .if eax <= ID_CNT

                    case_files()
                .else
                    strfcat(wsub.path, 0, [rbx].TOBJ.data[O_FILE])
                    mov rdi,rax
                    .if ( a_open & _WSAVE && !( a_open & _WNEWFILE ) )

                        .if !strext(rax)

                            mov rax,mask
                            inc rax
                            strcat(rdi, rax)
                        .endif
                    .endif
                    .break
                .endif
            .endw
            dlclose(rbx)
        .endif
        wsclose(&wsub)
        mov rax,rdi
    .endif
    ret

wdlgopen endp

wgetfile proc path:LPSTR, fmask:LPSTR, flag

    .if flag & _WLOCAL

        _getcwd(path, _MAX_PATH)

    .else

        mov rax,fmask
        add rax,2
        .if filexist(strfcat(path, _pgmpath, rax)) != 2
            strpath(path)
        .endif
    .endif

    .if wdlgopen(path, fmask, flag)

        strcpy(path, rax)
        .if flag & _WSAVE
            ogetouth(rax, M_WRONLY)
        .else
            openfile(rax, M_RDONLY, A_OPEN)
        .endif
        .if eax == -1
            xor eax,eax
        .endif
    .endif
    ret

wgetfile endp

wedit proc fcb:PFBLK, count:int_t

    .while fbffirst(fcb, count)

    and [rax].FBLK.flag,not _FB_SELECTED
    .if !( ecx & _FB_ARCHIVE or _A_SUBDIR )

        add rax,FBLK.name
        topen(rax, 0)
       .break .ifz
    .endif
    .endw
    panel_redraw(cpanel)
    xor eax,eax
    tmodal()
    ret

wedit endp

    option proc:private

zip_renametemp proc

    ioclose(&STDI)
    ioclose(&STDO)

    .if ( filexist(rdi) == 1 ) ; 1 file, 2 subdir

        remove(rsi)
        rename(rdi, rsi) ; 0 or -1
    .else
        mov eax,-1
    .endif
    ret

zip_renametemp endp

update_keys proc

    lea     rcx,crctab
    mov     edx,key0
    xor     eax,edx
    and     eax,0xFF
    shr     edx,8
    xor     edx,[rcx+rax*4]
    mov     key0,edx
    and     edx,0xFF
    add     edx,key1
    mov     eax,134775813
    mul     edx
    inc     eax
    mov     key1,eax
    shr     eax,24
    mov     edx,key2
    xor     al,dl
    shr     edx,8
    xor     edx,[rcx+rax*4]
    mov     key2,edx
    ret

update_keys endp

decryptbyte proc

    mov     ecx,key2
    or      ecx,2
    mov     edx,ecx
    xor     edx,1
    mov     eax,ecx
    mul     edx
    shr     eax,8
    ret

decryptbyte endp

init_keys proc uses rsi

    mov key0,0x12345678
    mov key1,0x23456789
    mov key2,0x34567890

    .for ( rsi = &password : byte ptr [rsi] : )

        lodsb
        update_keys()
    .endf
    ret

init_keys endp

decrypt proc uses rsi rbx

    .for ( rbx = STDI.base, esi = 0 : esi < STDI.cnt  : esi++ )

        decryptbyte()
        xor [rbx+rsi],al
        mov al,[rbx+rsi]
        update_keys()
    .endf
    ret

decrypt endp

test_password proc uses rsi rdi string:LPSTR

  local b[12]:byte

    init_keys()

    lea rax,b
    mov rdi,rax
    mov rsi,string
    mov ecx,3
    rep movsd

    .for ( rdi = rax, esi = 0 : esi < 12 : esi++ )

        decryptbyte()
        xor [rdi+rsi],al
        mov al,[rdi+rsi]
        update_keys()
    .endf

    mov cx,zip_local.time
    .if !( zip_attrib & _FB_ZEXTLOCHD )
        mov cx,word ptr zip_local.crc[2]
    .endif

    xor eax,eax
    .if ( ch == [rdi+11] )

        .for ( edi = STDI.cnt,  edi -= 12,
               rsi = STDI.base, rsi += 12 : edi : edi--, rsi++ )

            decryptbyte()
            xor [rsi],al
            mov al,[rsi]
            update_keys()
        .endf
        mov eax,1
    .endif
    ret

test_password endp

zip_decrypt proc uses rsi rdi

  local b[12]:byte

    .for ( rdi = &b, esi = 0 : esi < 12 : esi++ )

        ogetc()
        stosb
    .endf

    .if !test_password(&b)

        mov password,al
        .if tgetline("Enter password", &password, 32, 80)

            xor eax,eax
            .if al != password

                test_password(&b)
            .endif
        .endif
    .endif
    ret

zip_decrypt endp

getendcentral proc wsub:PWSUB, zend:PZEND

    mov STDI.file,wsopenarch(wsub)
    inc eax
    jz  toend

    ioseek(&STDI, 0, SEEK_END)
    cmp eax,-1
    jz  error

    mov zip_flength,eax
    cmp eax,ZEND
    jb  error

    oungetc()
    cmp eax,-1
    jz  error
    cmp STDI.index,ZEND-1
    jb  toend
    sub STDI.index,ZEND-2
@@:
    oungetc()
    cmp eax,-1
    jz toend
    cmp al,'P'
    jne @B

    oread(ZEND)
    test rax,rax
    jz  toend
    cmp DWORD PTR [rax],ZIP_ENDSENTRID
    jne @B

    memcpy(zend, rax, ZEND)
    mov eax,1
toend:
    ret
error:
    _close(STDI.file)
    xor eax,eax
    jmp toend

getendcentral endp

zip_allocfblk proc uses rsi rdi rbx

    mov edi,eax
    mov rsi,entryname
    strlen(rsi)
    add rax,FBLK
    mov rbx,rax
    add eax,12
    .if !malloc(eax)
        .return
    .endif
    mov rcx,rbx
    mov rbx,rax
    movzx eax,zip_central.ext_attrib
    and eax,_A_FATTRIB
    or  eax,zip_attrib
    mov [rbx],eax

    .if ( edi == 2 )

        .if ( zip_central.version_made || !( zip_central.ext_attrib & _A_SUBDIR ) )

            mov eax,_A_SUBDIR
            or  eax,zip_attrib
            mov [rbx],eax
        .endif
    .else
        mov DWORD PTR [rbx].FBLK.size[4],0
        mov eax,zip_central.fsize
        mov DWORD PTR [rbx].FBLK.size,eax
    .endif

    mov rdi,rcx
    mov ax,zip_central.date
    shl eax,16
    mov ax,zip_central.time
    mov [rbx].FBLK.time,eax
    strcpy(&[rbx].FBLK.name, rsi)

    add rdi,rbx
    mov eax,zip_central.off_local
    mov [rdi],eax
    mov eax,zip_central.csize
    mov [rdi+4],eax
    mov eax,zip_central.crc
    mov [rdi+8],eax
    mov rax,rbx
    ret

zip_allocfblk endp

zip_readcentral proc uses rsi rdi

    .if !oread(CZIP)

        .return
    .endif
    mov rbx,rax
    xor eax,eax

    .if ( DWORD PTR [rbx] != ZIP_CENTRALID )

        .return
    .endif

    add STDI.index,CZIP
    dec rax
    mov edx,arc_pathz
    .if ( [rbx].CZIP.fnsize <= dx )

        .return
    .endif

    lea rdi,zip_central
    mov eax,ecx
    mov rsi,rbx
    mov ecx,CZIP/4
    rep movsd
    movsw

    movzx ecx,[rbx].CZIP.fnsize
    add rbx,CZIP
    sub eax,CZIP
    .if ( eax < ecx )

        .if !oread(ecx)

            .return
        .endif
        mov rbx,rax
        movzx ecx,zip_central.fnsize
    .endif

    .for ( rsi = rbx, rdi = entryname, ah = '\' : ecx : ecx-- )

        mov al,[rsi]
        mov [rdi],al
        inc rdi
        inc rsi
        .if ( al == '/' )
            mov [rdi-1],ah
        .endif
    .endf

    mov byte ptr [rdi],0
    movzx eax,zip_central.fnsize
    add STDI.index,eax
    mov ecx,eax
    mov eax,_FB_ARCHZIP or _A_ARCH

    .if ( zip_central.bitflag & 1 )

        or eax,_FB_ZENCRYPTED
    .endif
    .if ( zip_central.bitflag & 8 )

        or eax,_FB_ZEXTLOCHD
    .endif

    mov zip_attrib,eax
    .if ( byte ptr [rdi-1] == '\' )

        mov byte ptr [rdi-1],0
        or  zip_attrib,_A_SUBDIR
        dec zip_central.fnsize
    .endif

    movzx edi,zip_central.extsize
    add di,zip_central.cmtsize

    .ifnz
        .if !oread(edi)

            .return
        .endif
        mov rbx,rax
        add STDI.index,edi
    .endif
    mov eax,1
    ret

zip_readcentral endp

zip_testcentral proc uses rsi wsub:PWSUB

    mov rax,wsub
    mov rsi,entryname
    mov rax,[rax].WSUB.arch

    .if ( byte ptr [rax] )
        .if strncmp(rax, rsi, arc_pathz)

            .return(0)
        .endif
    .endif

    mov eax,arc_pathz
    .if ( eax )

        .if ( byte ptr [rsi+rax] != '\' )

            .return( 0 )
        .endif
        strcpy(rsi, &[rsi+rax+1])
    .endif

    .while( byte ptr [rsi] == ',' )

        strcpy(rsi, &[rsi+1])
    .endw

    .if strchr(rsi, '\')

        mov byte ptr [rax],0
        .ifd ( wsearch(wsub, rsi) == -1 )
            .return( 2 )
        .endif
        .return( 0 )
    .endif

    .ifd ( wsearch(wsub, rsi) == -1 )

        .return( 1 )
    .endif

    dec eax
    mov rdx,wsub
    mov rdx,[rdx].WSUB.fcb
    mov rdx,[rdx+rax*size_t]

    mov ax,zip_central.date
    shl eax,16
    mov ax,zip_central.time
    mov [rdx].FBLK.time,eax

    .if ( zip_central.version_made )

        .return( 0 )
    .endif

    mov eax,zip_attrib
    or  ax,zip_central.ext_attrib
    and eax,_A_FATTRIB
    mov [rdx],eax
    xor eax,eax
    ret

zip_testcentral endp

zip_findnext proc

    .new fnsize:SINT
    .while 1

        .if !zip_readcentral()

            .return
        .endif
        .if ( eax != -1 )

            zip_testcentral(rdi)
        .else

            movzx eax,[rbx].CZIP.extsize
            add ax,[rbx].CZIP.cmtsize
            add ax,[rbx].CZIP.fnsize
            mov fnsize,eax

            .if !oread(eax)

                .return
            .endif
            mov rbx,rax
            mov edx,fnsize
            add STDI.index,edx
            xor eax,eax
        .endif
        .break .if eax
    .endw
    zip_allocfblk()
    ret

zip_findnext endp

wzipread proc public uses rsi rdi rbx wsub:PWSUB

  local fblk:PFBLK

    xor eax,eax
    mov STDI.index,eax
    mov STDI.cnt,eax
    mov STDI.flag,eax
    mov STDI.size,0x10000
    mov STDI.base,alloca( 0x10000 )
    mov rax,wsub
    mov arc_pathz,strlen( [rax].WSUB.arch )
    mov rdi,wsub
    wsfree(rdi)
    .ifs ( getendcentral(rdi, &zip_endcent) <= 0 )

        .return( -2 )
    .endif
    fbupdir( _FB_ARCHZIP )
    mov [rdi].WSUB.count,1
    mov rdx,[rdi].WSUB.fcb
    mov [rdx],rax
    oseek(zip_endcent.off_cent, SEEK_SET)

    .while zip_findnext()

        mov fblk,rax
        mov cl,[rax]
        .if !( cl & _A_SUBDIR )
            .if !cmpwarg(&[rax].FBLK.name, [rdi].WSUB.mask)

                free(fblk)
               .continue
            .endif
        .endif

        mov rcx,fblk
        mov eax,[rdi].WSUB.count
        mov rdx,[rdi].WSUB.fcb
        mov [rdx+rax*size_t],rcx
        inc eax
        mov [rdi].WSUB.count,eax
        .continue .if eax < [rdi].WSUB.maxfb
        .break .if !wsextend(rdi)
    .endw
    ioclose(&STDI)
    mov eax,[rdi].WSUB.count
    ret

wzipread endp

wzipfindentry proc uses rsi rdi fblk:PFBLK, ziph:SINT

    mov esi,ziph
    mov rdi,fblk
    strlen(&[rdi].FBLK.name)
    add rax,FBLK
    add rdi,rax
    _lseek(esi, [rdi], SEEK_SET)
    osread(esi, &zip_local, LZIP)

    .if ( eax != LZIP ||
          zip_local.pkzip != ZIPHEADERID ||
          zip_local.zipid != ZIPLOCALID )

        .return( 0 )
    .endif

    mov ax,zip_local.fnsize
    add ax,zip_local.extsize
    _lseek(esi, eax, SEEK_CUR)
    .if ( zip_local.flag & 8 )

        mov rax,fblk
        mov eax,[rdi+4]
        mov zip_local.crc,eax
        mov eax,[rdi+8]
        mov zip_local.csize,eax
    .endif
    mov eax,1
    ret

wzipfindentry endp

zip_unzip proc watcall private uses rsi zip_handle:int_t, out_handle:int_t

    mov STDI.file,zip_handle
    mov STDO.file,out_handle
    mov esi,ER_MEM

    .repeat
        .repeat
            .break .if !ioinit(&STDO, WSIZE)
            .if !ioinit(&STDI, OO_MEM64K)
                iofree(&STDO)
                .break
            .endif
            mov esi,-1
            or  STDO.flag,IO_UPDTOTAL or IO_USEUPD or IO_USECRC
            .repeat
                .if zip_attrib & _FB_ZENCRYPTED

                    .break .if ogetc() == -1
                     dec STDI.index
                    .break .if !zip_decrypt()
                .endif
                movzx eax,zip_local.method
                .switch eax
                .case 0
                    or  STDI.flag,IO_USECRC
                    mov eax,zip_local.fsize
ifdef _WIN64
                    iocopy(&STDO, &STDI, rax)
else
                    sub edx,edx
                    iocopy(&STDO, &STDI, edx::eax)
endif
                    mov esi,eax
                    ioflush(&STDO)
                    dec esi
                   .endc
                .case 8
                    zip_inflate()
                    mov esi,eax
                   .endc
if 1
                .case 6
                    zip_explode()
                    mov esi,eax
                   .endc
endif
                .default
                    ermsg(&cp_warning, "%s\n'%02X'",
                        _sys_errlist[ENOSYS*size_t], zip_local.method)
                    mov esi,ERROR_INVALID_FUNCTION
                .endsw
            .until 1
            iofree(&STDI)
            iofree(&STDO)
        .until 1
        .if STDO.flag & IO_ERROR
            mov esi,ER_DISK
        .endif
        .break .if esi
        mov eax,STDO.crc
        not eax
        .break .if eax == zip_local.crc
        .break .if rsmodal(IDD_UnzipCRCError)
        mov esi,ER_CRCERR
    .until 1
    mov eax,esi
    ret

zip_unzip endp

wzipcopyfile proc uses rsi rdi rbx wsub:PWSUB, fblk:PFBLK, out_path:LPSTR

   .new handle:int_t
   .new name[_MAX_PATH*2]:char_t
   .new rc:int_t

    ldr rbx,fblk
    .if ( filter_fblk(rbx) == 0 )
        .return
    .endif
    .ifd ( wsopenarch(wsub) == -1 )
        .return(ER_NOZIP)
    .endif
    mov esi,eax
    .if ( wzipfindentry(rbx, eax) == 0 )
        _close(esi)
        ermsg(_sys_errlist[ENOENT*size_t], &[rbx].FBLK.name)
       .return(ER_FIND)
    .endif
    .if ( progress_set(&[rbx].FBLK.name, out_path, [rbx].FBLK.size) != 0 )
        mov ebx,eax
        _close(esi)
       .return(ebx)
    .endif
    lea rdi,name
    .ifsd ( ogetouth(strfcat(rdi, out_path, &[rbx].FBLK.name), M_WRONLY) <= 0 )
        mov ebx,eax
        _close(esi)
       .return(ebx)
    .endif

    mov handle,eax
    mov ecx,[rbx].FBLK.flag
    mov zip_attrib,ecx
    mov rc,zip_unzip(esi, eax)
    _close(esi)
    .if ( rc == 0 )

        setftime(handle, [rbx].FBLK.time)
        _close(handle)
        mov eax,[rbx].FBLK.flag
        and eax,_A_FATTRIB
        setfattr(rdi, eax)
       .return( 0 )
    .endif
    _close(handle)
    remove(rdi)
    mov eax,rc
    .switch eax
    .case ER_USERABORT
    .case ERROR_INVALID_FUNCTION
       .endc
    .case ER_DISK
    .case ER_MEM
        ermsg(_sys_errlist[ENOMEM*size_t], rdi)
       .endc
    .default
        mov rdx,_sys_errlist[EIO*size_t]
        mov ecx,errno
        .if ( ecx )
            lea rdx,_sys_errlist
            mov rdx,[rdx+rcx*size_t]
        .endif
        ermsg(&cp_emarchive, "%s\n\n%s", rdi, rdx)
    .endsw
    .return(rc)

wzipcopyfile endp

wzipcopypath proc uses rsi rdi rbx wsub:PWSUB, fblk:PFBLK, out_path:LPSTR

  local zs:ZSUB

    ldr rsi,wsub
    lea rdi,zs.wsub
    mov zs.wsub.flag,_W_SORTSIZE ;or _W_MALLOC
    mov zs.wsub.maxfb,DC_MAXOBJ

    .if !wsopen(rdi)

        .return( -1 )
    .endif

    mov rbx,[rdi].WSUB.path
    mov [rdi].WSUB.path,[rsi].WSUB.path
    mov [rdi].WSUB.file,[rsi].WSUB.file
    mov [rdi].WSUB.mask,[rsi].WSUB.mask
    lea rcx,[rbx+WMAXPATH]
    mov [rdi].WSUB.arch,rcx
    mov rax,fblk
    lea rax,[rax].FBLK.name
    mov rdx,[rsi].WSUB.arch

    .if ( byte ptr [rdx] )
        strfcat(rcx, rdx, rax)
    .else
        strcpy(rcx, rax)
    .endif

    mov rsi,rbx
    mov rbx,fblk
    strfcat(rsi, out_path, &[rbx].FBLK.name)

    .if ( _mkdir(rsi) != -1 )

        .if ( setfattr(rsi, 0) == 0 )

            mov rax,fblk
            mov eax,[rax].FBLK.flag
            and eax,_A_FATTRIB
            and eax,not _A_SUBDIR
            setfattr(rsi, eax)
        .endif
    .endif

    .if !progress_set(&[rbx].FBLK.name, out_path, 0)

        xor ebx,ebx
        .if ( wzipread(rdi) > 1 )

            wssort(rdi)
            .if ( [rdi].WSUB.maxfb == [rdi].WSUB.count )

                stdmsg(&cp_warning, &cp_emaxfb, eax, eax)
            .endif

            mov eax,[rdi].WSUB.count
            dec eax
            mov zs.index,eax
            mov zs.result,0

            .while ( zs.result == 0 && zs.index > 0 )

                mov eax,zs.index
                mov rbx,[rdi].WSUB.fcb
                mov rbx,[rbx+rax*size_t]

                .if ( [rbx].FBLK.flag & _A_SUBDIR )

                    mov zs.result,wzipcopypath(rdi, rbx, rsi)
                .else
                    .if progress_set(&[rbx].FBLK.name, out_path, [rbx].FBLK.size)

                        mov zs.result,eax
                       .break
                    .endif
                    mov zs.result,wzipcopyfile(rdi, rbx, rsi)
                .endif

                mov rbx,[rdi].WSUB.fcb
                mov eax,zs.index
                lea rbx,[rbx+rax*size_t]
                xor eax,eax
                mov rcx,[rbx]
                mov [rbx],rax
                free(rcx)
                dec zs.index
            .endw
            mov ebx,zs.result
        .endif
        mov [rdi].WSUB.path,rsi
        wsclose(rdi)
        mov eax,ebx
    .endif
    ret

wzipcopypath endp

zip_copylocal proc uses rsi rdi rbx exact_match:DWORD

   .new size:Q64 = {0}
   .new fnsize:int_t
   .new offset_local:int_t = -1
   .new extsize_local:int_t = 0

    mov edi,strlen(__outpath)
    xor esi,esi

    .while 1

        mov rbx,oread(ZEND)
        .if ( rax == 0 || WORD PTR [rbx] != ZIPHEADERID )

           .return( -1 )
        .endif

        mov eax,esi
        .break .if WORD PTR [rbx+2] != ZIPLOCALID

        lea eax,[rdi+LZIP]
        .repeat

            .if !oread(eax)

                dec rax
               .return
            .endif
            mov   rbx,rax
            movzx eax,[rbx].LZIP.fnsize
            add   eax,LZIP
           .continue( 0 ) .if ( ecx < eax )
        .until 1

        movzx ecx,[rbx].LZIP.extsize
        add eax,[rbx].LZIP.csize
        add eax,ecx
        mov size.q_l,eax

        xor eax,eax
        movzx ecx,[rbx].LZIP.fnsize
        .if ( esi || ( !exact_match && ecx <= edi ) || ( exact_match && edi != ecx ) )
            inc eax
        .else
            _strnicmp( __outpath, &[rbx+LZIP], edi )
        .endif

        .if eax

            .if !iocopy( &STDO, &STDI, size )

                dec rax
               .return
            .endif
            .continue
        .endif

        inc     esi
        movzx   eax,[rbx].LZIP.extsize
        mov     extsize_local,eax
        mov     ax,[rbx].LZIP.fnsize
        mov     fnsize,eax
        add     rbx,LZIP
        and     eax,0x01FF
        memcpy( entryname, rbx, eax )

        mov ebx,fnsize
        add rbx,rax
        mov BYTE PTR [rbx],0
        mov eax,STDO.total_l
        add eax,STDO.index
        mov offset_local,eax

        mov ecx,size.q_l
        add eax,ecx
        oseek( eax, SEEK_SET )
       .break .if eax == -1
    .endw
    mov edx,offset_local
    mov ecx,extsize_local
    ret

zip_copylocal endp

zip_copycentral proc uses rsi rdi rbx loffset:uint_t, lsize:uint_t, exact_match:int_t

   .new q:Q64

    mov edi,strlen(__outpath)
    xor esi,esi

    .while 1

        .break .if !oread(ZEND)
        .break .if [rax].CZIP.pkzip != ZIPHEADERID ; 'PK'  4B50h
        .if ( [rax].CZIP.zipid != ZIPCENTRALID )   ; 1,2   0201h

            .return( esi )
        .endif

        .break .if !oread(CZIP)
         movzx eax,[rax].CZIP.fnsize
         add   eax,CZIP
        .break .if !oread(eax)

        mov   rbx,rax
        mov   eax,CZIP              ; Central directory
        add   ax,[rbx].CZIP.fnsize  ; file name length (*this)
        add   ax,[rbx].CZIP.extsize
        movzx ecx,[rbx].CZIP.cmtsize
        add   eax,ecx               ; = size of this record
        mov   q.q_l,eax
        mov   q.q_h,0

        mov   eax,loffset           ; Update local offset if above
        .if ( [rbx].CZIP.off_local >= eax )

            mov eax,lsize
            sub [rbx].CZIP.off_local,eax
        .endif

        .if ( esi == 0 ) ; or already found --> deleted

            movzx eax,[rbx].CZIP.fnsize
            .if ( ( exact_match && edi == eax ) || ( !exact_match && edi <= eax ) )

                .if !_strnicmp(__outpath, &[rbx+CZIP], edi)

                    inc esi
                    .break .if ( oseek(q.q_l, SEEK_CUR) == -1 )
                    .continue
                .endif
            .endif
        .endif
        .break .if !iocopy(&STDO, &STDI, q)
    .endw
    mov eax,-1
    ret

zip_copycentral endp

zip_copyendcentral proc watcall uses rsi rdi srcfile:LPSTR, outfile:LPSTR

    mov rsi,srcfile
    mov rdi,outfile
    mov eax,STDO.total_l
    add eax,STDO.index
    sub eax,zip_endcent.off_cent
    mov zip_endcent.size_cent,eax

    .if oread(ZEND)

        memcpy(rax, &zip_endcent, ZEND)

        movzx eax,zip_endcent.comment_size
        add   eax,ZEND
ifdef _WIN64
        .if iocopy(&STDO, &STDI, rax)
else
        xor   edx,edx
        .if iocopy(&STDO, &STDI, edx::eax)
endif
            .if ioflush(&STDO)

                mov zip_flength,STDO.total_l
               .return zip_renametemp() ; 0 or -1
            .endif
        .endif
    .endif
    dec rax
    ret

zip_copyendcentral endp

define USE_DEFLATE 1

update_local proc

    mov eax,zip_central.off_local
    .if ( eax >= STDO.total_l )

        sub eax,STDO.total_l
        add rax,STDO.base
        memcpy(rax, &zip_local, LZIP)
    .elseif ioflush(&STDO)

        _lseek(STDO.file, zip_central.off_local, SEEK_SET)
        oswrite(STDO.file, &zip_local, LZIP)
        _lseek(STDO.file, 0, SEEK_END)
    .endif
    ret

update_local endp

initentry proc
                            ; EAX   offset file name buffer
    push rax                ; BX    time
    mov zip_local.time,bx   ; EDX   size
    mov zip_central.time,bx ; SI    attrib
    mov zip_local.date,di   ; DI    date
    mov zip_central.date,di
    mov eax,edx
    mov zip_local.fsize,eax
    mov zip_local.csize,eax
    mov zip_central.fsize,eax
    mov zip_central.csize,eax
    mov eax,esi
    and eax,_A_FATTRIB
    mov zip_central.ext_attrib,ax
    pop rax
    strcpy(rax, __outpath)
    .if !( esi & _A_SUBDIR )
        mov rbx,unixtodos(rax)
        dostounix(strfcat(rbx, 0, strfn(__srcfile)))
    .endif
    strlen(rax)
    mov zip_local.fnsize,ax
    mov zip_central.fnsize,ax
    ret

initentry endp

compress proc

    .if ( zip_local.fsize >= 2 && compresslevel )
if USE_DEFLATE
        mov STDI.size,0x8000
        zip_deflate( compresslevel )
endif
    .else
        mov eax,zip_local.fsize
ifdef _WIN64
        iocopy(&STDO, &STDI, rax)
else
        xor edx,edx
        iocopy(&STDO, &STDI, edx::eax)
endif
    .endif
    ret

compress endp

initcrc proc
if USE_DEFLATE
    movzx eax,file_method
    mov zip_local.method,ax
    mov zip_central.method,ax
endif
    mov eax,STDI.crc
    not eax
    mov zip_local.crc,eax
    mov zip_central.crc,eax
    ioclose(&STDI)
    ret
initcrc endp

popstdi proc
    memcpy(&STDI, rsi, IOST)
    xor eax,eax
    ret
popstdi endp

zip_clearentry proc private

    memset(&zip_local, 0, LZIP)
    memset(&zip_central, 0, CZIP)
    mov zip_local.pkzip,ZIPHEADERID
    mov zip_local.zipid,ZIPLOCALID
    mov BYTE PTR zip_local.version,20
    mov zip_central.pkzip,ZIPHEADERID
    mov zip_central.zipid,ZIPCENTRALID
    mov BYTE PTR zip_central.version_made,20
    mov BYTE PTR zip_central.version_need,10
    ret

zip_clearentry endp

zip_setprogress proc watcall size:UINT, name:LPSTR

    or  STDO.flag,IO_USEUPD or IO_UPDTOTAL
ifdef _WIN64
    progress_set(__outfile, rdx, rax)
else
    xor ecx,ecx
    progress_set(__outfile, rdx, ecx::eax)
endif
    ret

zip_setprogress endp

zip_displayerror proc

    mov rax,_sys_errlist[ENOSPC*size_t]
    mov rcx,_sys_errlist[ENOMEM*size_t]

    .if !( STDO.flag & IO_ERROR )

        mov edx,errno
        mov rax,rcx
        .if ( edx != ENOMEM )

            lea rax,cp_emarchive
            mov rcx,_sys_errlist[EIO*size_t]
            .if ( edx )

                lea rcx,_sys_errlist
                mov rcx,[rcx+rdx*size_t]
            .endif
        .endif
    .endif
    ermsg(rcx, rax)
    ret

zip_displayerror endp

zip_mkarchivetmp proc watcall buffer:LPSTR

    setfext(strcpy(rax, __outfile), &cp_ziptemp)
    ret

zip_mkarchivetmp endp

    option proc:public

wzipadd proc uses rsi rdi rbx fsize:uint64_t, ftime:uint_t, fattrib:uint_t

  .new ios:IOST
  .new ztemp[384]:char_t
  .new zpath[384]:char_t
  .new local_size:uint_t
  .new result_copyl:uint_t
  .new offset_local:uint_t
  .new deflate_begin:uint_t

    movzx edi,word ptr ftime+2
    mov esi,fattrib
    xor eax,eax
    mov errno,eax
if USE_DEFLATE
    mov file_method,al
endif
    ;
    ; Skip files > 4G...
    ;
    .return .if ( eax != dword ptr fsize[4] )

    .if ( copy_fast )

        lea rax,zpath
        movzx ebx,word ptr ftime
        mov edx,dword ptr fsize
        initentry()

        mov zip_local.crc,0
        mov zip_central.crc,0
        mov zip_central.off_local,0

        .if !( esi & _A_SUBDIR )

            mov eax,STDO.total_l
            add eax,STDO.index
            mov zip_central.off_local,eax
            ioopen(&STDI, __srcfile, M_RDONLY, OO_MEM64K)
if USE_DEFLATE
            mov STDI.size,0x8000
endif
            inc eax
            .ifz
                .return ; v2.33 continue if error open source
            .endif

            test eax,iowrite(&STDO, &zip_local, LZIP)
            jz error_2
            movzx ecx,zip_local.fnsize
            test eax,iowrite(&STDO, &zpath, ecx)
            jz error_2

            or  STDI.flag,IO_USECRC or IO_USEUPD or IO_UPDTOTAL
            mov eax,STDO.total_l
            add eax,STDO.index
            mov deflate_begin,eax
            test eax,compress()
            jz error_2
            initcrc()
        .endif

        mov eax,STDO.total_l
        add eax,STDO.index
        mov zip_endcent.off_cent,eax

        .if !( esi & _A_SUBDIR )

            sub eax,deflate_begin
            mov zip_local.csize,eax
            mov zip_central.csize,eax
            update_local()
        .endif

        test eax,iowrite(&ocentral, &zip_central, CZIP)
        jz error_1
        test eax,iowrite(&ocentral, &zpath, zip_central.fnsize)
        jz error_1
        inc zip_endcent.entry_cur
        inc zip_endcent.entry_dir
       .return( 0 )
    .endif

    ;--------------------------------------------------------------
    ; do slow copy
    ;--------------------------------------------------------------

    mov eax,zip_flength
    mov dword ptr progress_size,eax
    mov dword ptr progress_size[4],0
    zip_clearentry()

    strcpy(&zpath, __outpath)
    mov rax,__outpath
    movzx ebx,word ptr ftime
    mov edx,dword ptr fsize
    initentry()

    .ifd ( wscopyopen(__outfile, zip_mkarchivetmp(&ztemp)) == -1 )

        .return
    .endif

    mov eax,STDO.flag
    and eax,not IO_GLMEM
    or  eax,IO_USEUPD or IO_UPDTOTAL
    mov STDO.flag,eax
    mov local_size,0
    zip_copylocal( 1 )
    mov result_copyl,eax    ; result: 1 found, 0 not found, -1 error
    mov offset_local,edx    ; offset local directory if found
    mov ecx,eax
    inc eax
    jz  error_3
    mov eax,STDO.total_l
    add eax,STDO.index
    mov zip_central.off_local,eax

    .if ( ecx )

        mov ecx,zip_endcent.off_cent
        sub ecx,eax
        mov local_size,ecx
    .endif

    memcpy(&ios, &STDI, IOST)
    .if !( esi & _A_SUBDIR )
if USE_DEFLATE
        mov file_method,0
endif
        ioopen(&STDI, __srcfile, M_RDONLY, OO_MEM64K)
if USE_DEFLATE
        mov STDI.size,0x8000
endif
        .if ( eax == -1 )

            memcpy(&STDI, &ios, IOST)
            jmp skip ; v2.33 continue if error open source
        .endif
    .endif
    and eax,iowrite(&STDO, &zip_local, LZIP)
    jz  ersource
    movzx ecx,zip_local.fnsize
    and eax,iowrite(&STDO, __outpath, ecx)
    jz  ersource
    and STDI.flag,IO_GLMEM
    or  STDI.flag,IO_USECRC or IO_USEUPD or IO_UPDTOTAL
    and STDO.flag,not IO_USEUPD
    mov eax,STDO.total_l
    add eax,STDO.index
    mov deflate_begin,eax
    and eax,progress_set(__srcfile, __outfile, fsize)
    jnz ersource

    .if !( esi & _A_SUBDIR )

        .if !compress()
ersource:
            ioclose(&STDI)
            memcpy(&STDI, &ios, IOST)
            jmp error_3
        .endif
        initcrc()
        memcpy(&STDI, &ios, IOST)
        zip_setprogress(zip_flength, &ztemp)
    .endif

    mov eax,dword ptr STDO.total
    add eax,STDO.index
    mov zip_endcent.off_cent,eax
    sub eax,deflate_begin
    mov zip_local.csize,eax
    mov zip_central.csize,eax
    add DWORD PTR progress_size,eax
    adc DWORD PTR progress_size[4],0
    update_local()

    zip_copycentral(offset_local, local_size, 1)
    inc eax
    jz  error_4
    dec eax         ; if file or directory deleted
    .ifnz           ; -- ask user to overwrite

        dec zip_endcent.entry_dir
        dec zip_endcent.entry_cur
        inc confirm_delete_file(__outpath, zip_central.ext_attrib)
        jz  error_4     ; Cancel (-1)
        dec eax
        jz  skip        ; Jump (0)
    .else
        cmp result_copyl,eax
        jne error_4 ; found local, not central == error
    .endif

    and eax,iowrite(&STDO, &zip_central, CZIP)
    jz  error_4
    movzx ecx,zip_central.fnsize
    and eax,iowrite(&STDO, __outpath, ecx)
    jz  error_4
    inc zip_endcent.entry_cur
    inc zip_endcent.entry_dir
    inc zip_copyendcentral(__outfile, &ztemp)
    jz  error_4
success:
    strcpy(__outpath, &zpath)
    xor eax,eax
toend:
    ret
skip:
    ioclose(&STDI)
    wscopyremove(&ztemp)
    jmp success
error_2:
    ioclose(&STDI)
error_1:
    ioclose(&STDO)
    ioclose(&ocentral)
    remove(entryname)
    mov eax,-1
    jmp toend
error_4:
    xor eax,eax
error_3:
    mov edi,eax
    ioclose(&STDI)
    wscopyremove(&ztemp)
    mov eax,edi
    inc edi
    jz  toend
    zip_displayerror()
    mov eax,-1
    jmp toend

wzipadd endp

wsmkzipdir proc uses rbx wsub:PWSUB, directory:LPSTR

    ldr rbx,wsub
    mov rax,__srcfile
    mov byte ptr [rax],0

    strfcat(__outfile, [rbx].WSUB.path, [rbx].WSUB.file)
    strfcat(__outpath, [rbx].WSUB.arch, directory)
    dostounix(strcat(rax, "/"))
    wzipadd(0, clock(), _A_SUBDIR)
    ret

wsmkzipdir endp

wsopenarch proc wsub:PWSUB

  local arcname[1024]:byte

    mov rdx,wsub
    .if osopen(
        strfcat(
            &arcname,
            [rdx].WSUB.path,
            [rdx].WSUB.file),
        _A_ARCH,
        M_RDONLY, A_OPEN) == -1
        eropen(&arcname)
    .endif
    ret

wsopenarch endp

wzipcopy proc private wsub:PWSUB, fblk:PFBLK, out_path:LPSTR

    ldr rcx,wsub
    ldr rdx,fblk
    ldr rax,out_path

    .if ( [rdx].FBLK.flag & _A_SUBDIR )
        .return wzipcopypath(rcx, rdx, rax)
    .endif
    .return wzipcopyfile(rcx, rdx, rax)

wzipcopy endp

wsdecomp proc wsub:PWSUB, fblk:PFBLK, out_path:LPSTR

    ldr rax,fblk
    .if !( [rax].FBLK.flag & _FB_ARCHIVE )
        notsup()
        or eax,-1
    .else
        wzipcopy(wsub, fblk, out_path)
    .endif
    ret

wsdecomp endp

;
; This is the fast compression startup
;
; The stratagy is to have two buffered files open
; - one for the local directory (compressed data)
; - and one for the central directory
;

wzipopen proc uses rsi rdi rbx

  local arch[384]:char_t
  local size:Q64

    zip_clearentry()
    mov rsi,entryname
    strcpy(rsi, __outfile)  ; the <archive>.zip file (read)

    lea rax,arch
    mov rdi,rax
    zip_mkarchivetmp(rax)   ; the <archive>.$$$ file (write) - 8M
    ;
    ; the <centtmp.$$$> file (write) - 1M
    ;
    strcpy(strfn(rsi), "centtmp.$$$")
    ;
    ; open <archive> and <temp> file
    ;
    .ifsd ( wscopyopen(__outfile, rdi) > 0 )
        ;
        ; open the <centtmp.$$$> file
        ;
        .ifsd ( ioopen(&ocentral, rsi, M_RDWR, 0x100000) > 0 )

            zip_setprogress(zip_flength, &arch)

            mov size.q_h,0
            mov size.q_l,zip_endcent.off_cent

            .if iocopy(&STDO, &STDI, size)

                mov size.q_l,zip_endcent.size_cent
                .if iocopy(&ocentral, &STDI, size)

                    and STDO.flag,IO_GLMEM ; clear flag for compression
                    ioclose(&STDI)
                   .return( 1 )
                .endif
            .endif
            ioclose(&ocentral)
            remove(rsi)
        .endif
        wscopyremove(rdi)
        xor eax,eax
    .endif
    ret

wzipopen endp

;
; This is called when the copy loop ends
;
wzipclose proc uses rsi rdi rbx

  local arch[384]:BYTE
  local size:Q64

    mov esi,eax ; result
    lea rdi,arch
    zip_mkarchivetmp(rdi)

    test esi,esi ; error ?
    jnz error_1  ; then remove temp files


    ;
    ; get size of central directory
    ; and update end-central info
    ;
    mov zip_endcent.size_cent,iotell(&ocentral)
    zip_setprogress(eax, rdi) ; set progress for last copy

    .if ( ocentral.total_l )

        ioflush(&ocentral) ; flush the <ocentral.$$$> buffer
        ioseek(&ocentral, 0, SEEK_SET)
    .else
        mov ocentral.cnt,ocentral.index
        mov ocentral.index,0
    .endif
    mov size.q_h,0
    mov size.q_l,zip_endcent.size_cent
    and eax,iocopy(&STDO, &ocentral, size)
    jz  error_2
    and eax,iowrite(&STDO, &zip_endcent, ZEND)
    jz  error_2

    movzx esi,zip_endcent.comment_size
    .if ( esi )

        _close(ocentral.file) ; add zip-comment to the end
        mov ocentral.file,openfile(__outfile, M_RDONLY, A_OPEN)
        mov ebx,eax
        inc eax
        jz  error_2
        xor eax,eax
        sub rax,rsi
        inc _lseek(ebx, rax, SEEK_END)
        jz  error_2
        mov size.q_l,esi
        mov ocentral.cnt,0
        mov ocentral.index,0
        and eax,iocopy(&STDO, &ocentral, size)
        jz  error_2
    .endif

    and eax,ioflush(&STDO)  ; flush the <achive>.$$$ buffer
    jz  error_2
    ioclose(&ocentral)      ; close files
    ioclose(&STDO)

    mov rsi,__outfile
    cmp filexist(rdi),1     ; 1 file, 2 subdir
    jne error_1
    remove(rsi)             ; remove the <archive>.zip file
    rename(rdi, rsi)        ; rename <achive>.$$$ to <achive>.zip
toend:
    remove(entryname)       ; remove the <centtmp.$$$> file
    ret

error_2:
    ioclose(&ocentral)
error_1:
    wscopyremove(rdi)
    zip_displayerror()
    jmp toend
wzipclose endp

    assume rdi:PFBLK
    assume rbx:PWSUB

wzipdel proc uses rsi rdi rbx wsub:PWSUB, fblk:PFBLK

   .new size:Q64 = {0}

    ldr rbx,wsub
    ldr rdi,fblk

    xor esi,esi

    .while 1

        mov rcx,entryname

        .if ( !esi )

            mov ecx,[rdi].flag
            lea rax,[rdi].name
            .if cl & _A_SUBDIR
                confirm_delete_sub(rax)
            .else
                confirm_delete_file(rax, ecx)
            .endif
            .break .if !eax      ; 0: Skip file
            .break .if eax == -1 ; -1: Cancel

            strfcat(__srcfile, [rbx].path, [rbx].file)
            setfext(strcpy(__outfile, rax), &cp_ziptemp)
            strfcat(__outpath, [rbx].arch, &[rdi].name)
            dostounix(rax)

            .if ( [rdi].flag & _A_SUBDIR )
                strcat(rax, "/")
            .endif
            .ifd !strcmp(__srcfile, __outfile)

                erdelete(__outpath)
               .break
            .endif
            mov rcx,__outpath
        .endif

        mov size.q_l,zip_flength

        .break .ifd progress_set(rcx, __srcfile, size)
        .break .ifd wscopyopen(__srcfile, __outfile) == -1

        and STDO.flag,IO_GLMEM
        or  STDO.flag,IO_UPDTOTAL or IO_USEUPD
        .if eax
            ;
            ; copy compressed data to temp file
            ;
            ; 0: match directory\*.*
            ; 1: exact match -- file or directory/
            ;
            xor esi,1
            .ifd zip_copylocal(esi) != -1
                ;
                ; local offset to Central directory in DX
                ;
                mov eax,STDO.total_l
                add eax,STDO.index
                mov ecx,zip_endcent.off_cent
                mov zip_endcent.off_cent,eax
                sub ecx,eax
                xchg rcx,rdx

                .if zip_copycentral(ecx, edx, esi) == 1
                    ;
                    ; must be found..
                    ;
                    ;-------- End Central Directory
                    ;
                    dec zip_endcent.entry_dir
                    dec zip_endcent.entry_cur
                    and eax,zip_copyendcentral(__srcfile, __outfile)
                    jz next
                .endif
            .endif
        .endif
        ioclose(&STDI)
        wscopyremove(__outfile)
        xor esi,1
        mov eax,esi
        .if eax && !( [rdi].flag & _A_SUBDIR )
            erdelete(__outpath)
        .endif
        .break .if eax
next:
        .break .if !( [rdi].flag & _A_SUBDIR )
        mov esi,1
    .endw
    ret

wzipdel endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Install proc private

    mov scan_fblock,malloc(WIN32_FIND_DATA + 2 * WMAXPATH)
    add rax,WIN32_FIND_DATA
    mov scan_curfile,rax
    add rax,WMAXPATH
    mov scan_curpath,rax
    ret

Install endp

.pragma init(Install, 40)

    end
