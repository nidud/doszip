; CMCOPY.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include io.inc
include wsub.inc
include errno.inc
include time.inc
include string.inc
include malloc.inc
include stdlib.inc
include progress.inc

    .data
     copy_jump      dd 0
     copy_filecount dd 0
     copy_subdcount dd 0
     copy_flag      db 0
     copy_fast      db 0

    .code


error_diskfull proc private

    ermsg(0, "%s\n%s\n\n%s", "There was an error while copying",
            __outfile, _sys_errlist[ENOSPC*size_t])
    ret

error_diskfull endp


error_copy proc private

    .if ( errno == ENOSPC )
        error_diskfull()
    .else
        ermsg(0, "%s\n%s", "There was an error while copying", __outfile)
    .endif
    ret

error_copy endp


getcopycount proc private uses rsi rdi rbx

   .new count:int_t

    mov rbx,cpanel
    mov rbx,[rbx].PANEL.wsub
    mov count,[rbx].WSUB.count
    mov rdi,[rbx].WSUB.fcb

    .while count

        mov rbx,[rdi]
        add rdi,size_t
        mov eax,[rbx]

        .if eax & _FB_SELECTED

            .if eax & _A_SUBDIR

                inc copy_subdcount
                .if recursive(&[rbx].FBLK.name, __srcpath, __outpath)

                    mov copy_flag,_COPY_RECURSIV
                   .break
                .endif
            .else
                inc copy_filecount
            .endif
        .endif
        dec count
    .endw

    mov eax,copy_filecount
    add eax,copy_subdcount
    ret

getcopycount endp


cpyevent_filter proc

    cmfilter()

    mov rcx,tdialog
    mov ecx,[rcx].DOBJ.rc
    add ecx,0x0510
    mov dl,ch
    mov eax,' '
    .if filter
        mov eax,U_BULLET_OPERATOR
    .endif
    scputc(ecx, edx, 1, eax)
    mov eax,_C_NORMAL
    ret

cpyevent_filter endp


confirm_copy proc private uses rsi rdi rbx fblk:PFBLK, docopy:int_t

  .new x:int_t
  .new y:int_t

    ldr esi,docopy
    mov eax,config.c_cflag
    mov ecx,_C_CONFCOPY
    mov rdi,IDD_DZCopy
    .if !rsi
        mov ecx,_C_CONFMOVE
        mov rdi,IDD_DZMove
    .endif

    and eax,ecx
    .ifz
        inc eax
    .elseif rsopen(rdi)

        mov rbx,rax
        .if rsi
            mov filter,0
            mov [rbx+3*TOBJ].TOBJ.tproc,&cpyevent_filter
        .endif

        dlshow(rbx)

        movzx   eax,[rbx].DOBJ.rc.x
        movzx   edx,[rbx].DOBJ.rc.y
        add     eax,9
        add     edx,2
        mov     x,eax
        mov     y,edx
        mov     rsi,__outpath
        mov     [rbx+TOBJ].TOBJ.count,WMAXPATH/16
        mov     rax,fblk
        mov     eax,[rax].FBLK.flag

        .if ( eax & _FB_SELECTED )

            mov eax,copy_filecount
            add eax,copy_subdcount
            scputf(x, y, 0, 0, "%d file(s) to", eax)

        .else

            scputc(x, y, 1, 0x27)
            inc x
            mov rax,fblk
            add rax,FBLK.name
            add x,scpath(x, y, 38, rax)
            scputs(x, y, 0, 0, "' to")
            mov rax,fblk
            .if !( [rax].FBLK.flag & _A_SUBDIR )
                mov rsi,__outfile
            .endif
        .endif

        .if ( copy_flag & _COPY_OARCHIVE )
            mov rsi,__outfile
        .endif

        mov rax,[rbx].DOBJ.object
        mov [rax].TOBJ.data,rsi

        .if ( copy_flag & _COPY_IARCHIVE or _COPY_OARCHIVE )

            dlinit(rbx)
            mov rax,[rbx].DOBJ.object
            or [rax].TOBJ.flag,_O_STATE
        .endif

        mov esi,rsevent(rdi, rbx)
        dlclose(rbx)

        xor eax,eax
        .if esi
            inc eax
        .endif
    .endif
    ret

confirm_copy endp


init_copy proc uses rsi rdi rbx fblk:PFBLK, docopy:UINT

    xor eax,eax
    mov copy_fast,al
    mov copy_jump,eax       ; set if skip file (jump)
    mov copy_flag,al        ; type of copy
    mov copy_filecount,eax  ; selected files
    mov copy_subdcount,eax

    .if !cpanel_gettarget() ; get __outpath

        ermsg(0, "You need two file panels to use this command")
       .return
    .endif

    mov rsi,rax         ; ESI = target path
    panel_getb()
    mov rdi,[rax].PANEL.wsub ; EDI = target directory
    mov rax,cpanel
    mov rax,[rax].PANEL.wsub

    .if [rax].WSUB.flag & _W_ROOTDIR

        notsup()
       .return
    .endif

    mov eax,[rdi].WSUB.flag
    and eax,_W_ARCHIVE
    .ifnz
        .if [rdi].WSUB.count == 1
            inc copy_fast
        .endif
        and eax,_W_ARCHEXT
        mov eax,_COPY_OARCHIVE or _COPY_OEXTFILE
        .ifz
            mov eax,_COPY_OARCHIVE or _COPY_OZIPFILE
            .if byte ptr docopy == 0
                ;
                ; moving files to archive..
                ;
                notsup()
               .return
            .endif
        .endif
    .endif

    mov copy_flag,al
    mov rbx,__outpath
    strcpy(rbx, rsi)
    mov rax,cpanel
    mov rax,[rax].PANEL.wsub
    strcpy(__srcpath, [rax].WSUB.path)
    mov rax,fblk
    add rax,FBLK.name
    strfcat(__srcfile, __srcpath, rax)

    .if copy_flag & _COPY_OARCHIVE

        strfcat(__outfile, rbx, [rdi].WSUB.file)
        strcpy(rbx, [rdi].WSUB.arch)
        dostounix(rax)
    .else
        strfcat(__outfile, rbx, strfn(__srcfile))
    .endif

    mov rax,fblk
    mov esi,[rax].FBLK.flag
    .if esi & _FB_SELECTED

        .if !getcopycount()       ; copy/move selected files

            mov al,copy_flag
           .return
        .endif
        or copy_flag,_COPY_SELECTED

    .elseif esi & _A_SUBDIR

        add rax,FBLK.name
        mov copy_subdcount,1    ; copy/move one directory
        .if recursive(rax, __srcpath, rbx)
            or copy_flag,_COPY_RECURSIV
        .endif
    .else
        mov copy_filecount,1    ; copy/move one file
    .endif

    mov eax,copy_filecount
    add eax,copy_subdcount
   .return .ifz

    mov rax,fblk
    mov eax,[rax].FBLK.flag
    and eax,_FB_ARCHIVE
    .ifnz
        .if eax & _FB_ARCHEXT
            mov eax,_COPY_IARCHIVE or _COPY_IEXTFILE
        .else
            mov eax,_COPY_IARCHIVE or _COPY_IZIPFILE
        .endif
    .endif
    or copy_flag,al

    .if !confirm_copy(fblk, docopy)
        .return
    .endif

    .if copy_flag & _COPY_IARCHIVE
        and copy_flag,not _COPY_RECURSIV
    .else
        .if !strcmp(__outfile, __srcfile)

           .return ermsg(0, "You can't copy a file to itself")
        .endif
    .endif

    .if copy_flag & _COPY_RECURSIV

       .return ermsg(0, "You tried to recursively copy or move a directory")
    .endif

    .if !( copy_flag & _COPY_OARCHIVE )

        .if getfattr(rbx) == -1

            .if _mkdir(rbx)

                ermkdir(rbx)
               .return( 0 )
            .endif
        .endif
    .endif
    setconfirmflag()
    mov eax,1
    ret

init_copy endp


copyfile proc uses rsi rdi file_size:qword, t:dword, attrib:UINT

    xor esi,esi
    ;----------------
    ; open the files
    ;----------------
    .ifs wscopyopen(__srcfile, __outfile) > 0
        ;---------------
        ; copy the file
        ;---------------
        or STDI.flag,IO_USECRC
        or STDO.flag,IO_USECRC or IO_UPDTOTAL or IO_USEUPD
        mov esi,iocopy(&STDO, &STDI, file_size)
        .if eax
            ioflush(&STDO)  ; flush the stream
        .endif
        ioclose(&STDI)  ; test CRC value

        mov eax,STDO.crc
        .if eax != STDI.crc

            ioclose(&STDO)
            mov rax,_sys_errlist[EIO*size_t]
            mov edx,errno
            .if edx
                lea rax,_sys_errlist
                mov rax,[rax+rdx*size_t]
            .endif
            ermsg(0, "%s\n'%s'", "There was an error while copying", rax)

        .elseif !esi

            ioclose(&STDO)
            error_copy()
            wscopyremove(__outfile) ; -1

        .else

            progress_update(file_size)
            ;
            ; return user break (ESC) in ESI
            ;
            mov esi,eax
            setftime(STDO.file, t)
            ioclose(&STDO)
            ;
            ; remove RDONLY if CD-ROOM - @v2.18
            ;
            mov eax,attrib
            .if al & _A_RDONLY && cflag & _C_CDCLRDONLY

                mov rdx,cpanel
                mov rdx,[rdx].PANEL.wsub
                mov edx,[rdx].WSUB.flag
                .if edx & _W_CDROOM
                    xor al,_A_RDONLY
                .endif
            .endif
            and eax,_A_FATTRIB
            setfattr(__outfile, eax)
            mov eax,esi
        .endif
    .endif
    ;
    ; return 1: ok, -1: error, 0: jump (if exist)
    ;
    ret

copyfile endp


fblk_copyfile proc private uses rbx fblk:PFBLK, skip_outfile:UINT

    ldr rbx,fblk
    .if filter_fblk(rbx)

        strfcat(__srcfile, __srcpath, &[rbx].FBLK.name)
        .if ( !skip_outfile && !( copy_flag & _COPY_OARCHIVE ) )

            strfcat(__outfile, __outpath, &[rbx].FBLK.name)
        .endif

        .if !progress_set(&[rbx].FBLK.name, __outpath, [rbx].FBLK.size)

            mov edx,[rbx].FBLK.flag
            .if edx & _FB_ARCHIVE
                mov rcx,cpanel
                wsdecomp([rcx].PANEL.wsub, rbx, __outpath)
            .elseif copy_flag & _COPY_OARCHIVE
                wzipadd([rbx].FBLK.size, [rbx].FBLK.time, edx)
            .else
                copyfile([rbx].FBLK.size, [rbx].FBLK.time, edx)
            .endif
        .endif
    .endif
    ret

fblk_copyfile endp


fp_copyfile proc uses rsi rdi rbx directory:LPSTR, wblk:PWIN32_FIND_DATA

   .new q:Q64

    ldr rbx,wblk
    .if filter_wblk(rbx)

        strfcat(__srcfile, directory, &[rbx].WIN32_FIND_DATA.cFileName)
        .if !(copy_flag & _COPY_OARCHIVE)

            strfcat(__outfile, __outpath, &[rbx].WIN32_FIND_DATA.cFileName)
        .endif
        mov q.q_h,[rbx].WIN32_FIND_DATA.nFileSizeHigh
        mov q.q_l,[rbx].WIN32_FIND_DATA.nFileSizeLow
        .if !progress_set(&[rbx].WIN32_FIND_DATA.cFileName, __outpath, q)

            FileTimeToTime(&[rbx].WIN32_FIND_DATA.ftLastWriteTime)
            mov edx,[rbx].WIN32_FIND_DATA.dwFileAttributes
            and edx,_A_FATTRIB
            .if copy_flag & _COPY_OARCHIVE
                wzipadd(q, eax, edx)
            .else
                copyfile(q, eax, edx)
            .endif
        .endif
    .endif
    ret

fp_copyfile endp


fp_copydirectory proc uses rsi rdi rbx directory:LPSTR

   .new path:LPSTR = alloca(WMAXPATH)

    mov rbx,rax
    mov rsi,directory
    add rsi,strlen(__srcpath)

    .if byte ptr [rsi] == '\'
        inc rsi
    .endif
    strcpy(rbx, __outpath)

    .if ( copy_flag & _COPY_OARCHIVE )

        mov rcx,__outpath
        .if byte ptr [rcx]
            strcat(rcx, "/")
        .endif
        dostounix(strcat(strcat(__outpath, rsi), "/"))

        mov rcx,__srcfile
        mov byte ptr [rcx],0

        .if ( cflag & _C_ZINCSUBDIR )

            mov esi,clock()
            wzipadd(0, esi, getfattr(directory))
        .endif

    .elseif !_mkdir(strfcat(__outpath, 0, rsi))

        .if !setfattr(__outpath, 0)

            getfattr(directory)
            and eax,not _A_SUBDIR
            setfattr(__outpath, eax)
        .endif
    .endif
    mov esi,scan_files(directory)
    strcpy(__outpath, rbx)
    mov eax,esi
    ret

fp_copydirectory endp


copydirectory proc private uses rsi rdi rbx fblk:PFBLK

   .new path:LPSTR = alloca(WMAXPATH)

    mov rsi,rax
    mov rdi,fblk
    lea rdi,[rdi].FBLK.name
    mov rbx,__outpath

    .if !progress_set(rdi, rbx, 0)

        .if !( copy_flag & _COPY_OARCHIVE )

            _mkdir(rbx)
        .endif

        strfcat(rsi, __srcpath, rdi)

        .if ( copy_flag & _COPY_OARCHIVE )

            .if ( copy_fast != 1 )

                mov rax,panela
                .if rax == cpanel
                    mov rax,panelb
                .endif

                ;-------------------------------------------
                ; if panel name is not found: use fast copy
                ;-------------------------------------------

                .if wsearch([rax].PANEL.wsub, rdi) == -1

                    inc copy_fast
                    .if wzipopen()

                        scansub(rsi, &cp_stdmask, 1)
                        dec copy_fast
                        wzipclose()
                    .else
                        dec copy_fast
                        dec rax
                    .endif
                    .return
                .endif
            .endif
        .endif
        scansub(rsi, &cp_stdmask, 1)
    .endif
    ret

copydirectory endp


copyselected proc private

    panel_getb()
    mov ecx,esi
    mov ebx,[rax].PANEL.fcb_index
    mov esi,[rax].PANEL.cel_index
    .repeat
        .if ecx & _FB_ARCHIVE
            mov rax,cpanel
            wsdecomp([rax].PANEL.wsub, rdi, __outpath)
        .elseif cl & _A_SUBDIR
            copydirectory(rdi)
        .else
            fblk_copyfile(rdi, 0)
        .endif
        .break .if eax
        cpanel_deselect(rdi)
        panel_findnext(cpanel)
        mov rdi,rdx
    .untilz
    mov edi,eax
    panel_getb()
    mov [rax].PANEL.cel_index,esi
    mov [rax].PANEL.fcb_index,ebx
    mov eax,edi
    ret

copyselected endp

cmcopy proc uses rsi rdi rbx

    .if cpanel_findfirst()

        mov rdi,rdx
        mov esi,ecx
        mov rcx,rdx

        .if init_copy(rcx, 1)

            mov al,copy_flag
            .if ( al & _COPY_IEXTFILE )

                mov rbx,cpanel
                mov rbx,[rbx].PANEL.wsub
                warccopy(rbx, rdi, __outpath, copy_subdcount)

            .elseif ( al & _COPY_OEXTFILE )

                panel_getb()
                mov rbx,rax
                mov rcx,[rbx].PANEL.wsub
                mov rbx,cpanel
                mov rbx,[rbx].PANEL.wsub
                warcadd(rcx, rbx, rdi)

            .else

                progress_open("Copy", "Copy")
                mov fp_fileblock,&fp_copyfile
                mov fp_directory,&fp_copydirectory
                .if copy_flag & _COPY_OARCHIVE
                    dostounix(__outpath)
                    .if copy_flag & _COPY_OZIPFILE && copy_fast
                        and eax,wzipopen()
                        jz done
                    .endif
                .endif
                .if esi & _FB_SELECTED
                    copyselected()
                .elseif esi & _A_SUBDIR
                    .if esi & _FB_ARCHIVE
                        mov rax,cpanel
                        wsdecomp([rax].PANEL.wsub, rdi, __outpath)
                    .else
                        copydirectory(rdi)
                    .endif
                .else
                    fblk_copyfile(rdi, 1)
                .endif
                .if copy_flag & _COPY_OZIPFILE && copy_fast
                    wzipclose()
                .endif
                done:
                progress_close()
            .endif
        .endif
    .endif
    mov copy_fast,0
    ret

cmcopy endp

    END

