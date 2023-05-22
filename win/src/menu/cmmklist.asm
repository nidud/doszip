; CMMKLIST.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT
;
; Make List File from selection set
;
include doszip.inc
include string.inc
include io.inc
include stdio.inc
include stdlib.inc
include wsub.inc
include progress.inc

.enumt MKListIDD : TOBJ {
    ID_DIALOG,
    ID_APPEND,
    ID_UNIX,
    ID_EXLCD,
    ID_EXLDRV,
    ID_EXLFILE,
    ID_LIST,
    ID_FORMAT,
    ID_OK,
    ID_CANCEL,
    ID_FILTER
    }

    .data
     cp_ziplst char_t "ziplst",0
     mklsubcnt uint_t 0
     GCMD_mklist GLCMD \
        { KEY_F3, event_LOAD },
        { 0,      0          }

    .code

event_LOAD proc private uses rsi rdi rbx

  local string[256]:byte

    mov rbx,tdialog
    mov al,[rbx].DOBJ.index
    .if al != 5 && al != 6

        mov [rbx].DOBJ.index,5
    .endif

    mov esi,tools_idd(128, &string, "MKList")
    msloop()

    .if ( esi && esi != MOUSECMD )

        mov rsi,[rbx].TOBJ.data[ID_FORMAT]
        lea rdi,string

        .if strchr(rdi, '@')

            xchg rdi,rax
            mov byte ptr [rdi],0
            .if ( rax != rdi )

                strcpy([rbx].TOBJ.data[ID_LIST], rax)
            .endif
            inc rdi
        .endif
        strcpy(rsi, rdi)
        dlinit(rbx)
    .endif
    mov eax,_C_NORMAL
    ret

event_LOAD endp


event_help proc private

    view_readme(HELPID_11)
    ret

event_help endp


event_filter proc private

    cmfilter()

    mov rdx,tdialog
    mov cx,[rdx+4]
    add cx,0x0A1C
    mov dl,ch
    mov eax,' '
    .if filter
        mov eax,U_BULLET_OPERATOR
    .endif
    scputw(ecx, edx, 1, eax)
    mov eax,_C_NORMAL
    ret

event_filter endp


mklistidd proc uses rsi rdi rbx

    .if rsopen(IDD_DZMKList)

        mov rbx,rax
        mov rsi,thelp
        mov thelp,&event_help

        tosetbitflag([rbx].DOBJ.object, 5, _O_FLAGB, mklist.flag)
        mov [rbx].TOBJ.tproc[ID_FILTER],&event_filter
        mov rdi,[rbx].TOBJ.data[ID_LIST]
        mov [rbx].TOBJ.data[ID_APPEND],&GCMD_mklist
        strcpy([rbx].TOBJ.data[ID_FORMAT], &format_lst)
        strcpy(rdi, &filelist_bat)
        xor eax,eax
        mov mklist.offs,eax
        dlinit(rbx)

        .if dlevent(rbx)

            xor eax,eax
            mov mklist.count,eax
            or  mklist.flag,_MKL_MACRO
            togetbitflag([rbx].DOBJ.object, 5, _O_FLAGB)
            mov ah,byte ptr mklist.flag
            and ah,_MKL_MASK
            or  al,ah
            mov byte ptr mklist.flag,al
            strcpy(&format_lst, [rbx].TOBJ.data[ID_FORMAT])
            strcpy(&filelist_bat, rdi)

            .if ( mklist.flag & _MKL_APPEND )

                .if filexist(rdi)

                    mov ecx,eax
                    xor eax,eax

                    .if ( ecx == 1 )

                        .if openfile(rdi, M_WRONLY, A_OPEN)

                            mov mklist.handle,eax
                            _lseek(eax, 0, SEEK_END)
                            mov eax,1
                        .endif
                    .endif
                .else
                    mov mklist.handle,ogetouth(rdi, M_WRONLY)
                .endif
            .else
                mov mklist.handle,ogetouth(rdi, M_WRONLY)
            .endif
        .endif
        .if ( eax == -1 )
            xor eax,eax
        .endif
        mov thelp,rsi
        mov edi,eax
        dlclose(rbx)
        mov eax,edi
    .endif
    ret

mklistidd endp


mklistadd proc uses rsi rdi rbx file:LPSTR

   .new path[_MAX_PATH]:char_t
   .new list[_MAX_PATH*2]:char_t

    lea rdi,path
    mov rbx,strcpy(rdi, file)
    inc mklist.count

    xor eax,eax
    xor ecx,ecx

    .if ( mklist.flag & _MKL_EXCL_DRV && byte ptr [rbx+1] == ':' )

        add ecx,2
    .endif
    add rbx,rcx

    .if ( mklist.flag & _MKL_EXCL_CD )

        mov edx,mklist.offspath
        add rbx,rdx
        sub rbx,rcx
    .endif

    .if ( mklist.flag & _MKL_UNIX )

        mov rbx,dostounix(rbx)
    .endif

    .if ( mklist.flag & _MKL_EXCL_FILE )

        strpath(rbx)
    .endif
    strcpy(rdi, rbx)
    mov rbx,strcpy(&list, &format_lst)

    .if !( mklist.flag & _MKL_MACRO )

        strcpy(rax, rdi)

    .else

        strxchg(rbx, "\\\\", "\x7\x1") ; unlikely combination 1 '\\'
        strxchg(rbx, "\\n", "\r\n")
        strxchg(rbx, "\\t", "\t")
        strxchg(rbx, "\\%", "\x7\x2")  ; unlikely combination 2 '\%'
        strxchg(rbx, "\x7\x1", "\\")
        strxchg(rbx, "%dz", _pgmpath)
        strxchg(rbx, "%f", rdi)

        mov rsi,strfn(rdi)
        mov rdi,strext(rax)

        .if ( rax == NULL )
            lea rax,@CStr("")
        .endif
        strxchg(rbx, "%ext", rax)

        xor eax,eax
        .if rdi
            mov [rdi],al
        .endif
        strxchg(rbx, "%n", rsi)

        lea rdi,path
        .if rsi != rdi
            mov rcx,rdi
            xor eax,eax
            mov [rsi-1],al
        .else
            lea rcx,@CStr("")
        .endif
        strxchg(rbx, "%p", rcx)

        xor eax,eax
        mov rcx,rdi
        mov edx,mklist.offspath
        add rdx,rdi
        .if rdx != rcx
            dec rdx
        .endif
        mov [rdx],al
        strxchg(rbx, "%cd", rcx)
        strxchg(rbx, "%s", &searchstring)

        mov eax,mklist.count
        dec eax
        sprintf(rdi, "%u", eax)
        strxchg(rbx, "%id", rdi)

        sprintf(rdi, "%u", mklist.offs)
        strxchg(rbx, "%o", rdi)
        strxchg(rbx, "\x7\x2", "%")
    .endif

    .if oswrite(mklist.handle, rbx, strlen(rbx))

        xor eax,eax
        .if !( mklist.flag & _MKL_MACRO )

            oswrite(mklist.handle, "\r\n", 2)
            sub eax,2
            .ifnz
                inc eax
            .endif
        .endif
    .else
        inc eax
    .endif
    ret

mklistadd endp


fp_mklist proc private path:LPSTR, wblk:ptr WIN32_FIND_DATA

    .if filter_wblk(wblk)

        mov rax,wblk
        .if !progress_set(0, strfcat(__srcfile, path, &[rax].WIN32_FIND_DATA.cFileName), 1)

            mklistadd(__srcfile)
        .endif
    .endif
    ret

fp_mklist endp


mksublist proc private uses rsi rdi zip_list:SINT, path:LPSTR

    or mklist.flag,_MKL_MACRO

    .if ( zip_list == 1 )

        or  mklist.flag,_MKL_EXCL_CD
        xor mklist.flag,_MKL_MACRO
        lea rax,cp_ziplst

    .else

        .if !mklistidd()
            .return
        .endif
        lea rax,filelist_bat
    .endif

    progress_open(rax, 0)
    strlen(path)

    mov rdx,path
    add rdx,rax
    .if ( byte ptr [rdx-1] != '\' )
        inc eax
    .endif
    mov mklist.offspath,eax
    mov fp_fileblock,&fp_mklist
    mov fp_directory,&scan_files

    .if cpanel_findfirst()

        .if ( ecx & _FB_ARCHEXT )

            mov mklist.offspath,0
        .endif

        .repeat

            mov edi,ecx
            mov rsi,rdx

            .break .if progress_set(0, strfcat(__outpath, path, rax), 1)

            .if ( edi & _A_SUBDIR )

                .if ( edi & _FB_ARCHIVE )

                    strcat(__outpath, "\\")
                    .if ( mklist.flag & _MKL_MASK )

                        mov rdx,cpanel
                        mov rdx,[rdx].PANEL.wsub
                        strcat(rax, [rdx].WSUB.mask)
                    .endif
                    mklistadd(rax)
                    inc mklsubcnt
                .else
                    .break .if scansub(__outpath, &cp_stdmask, 0)
                .endif
            .else
                .if filter_fblk(rsi)

                    mklistadd(__outpath)
                .endif
            .endif
            and [rsi].FBLK.flag,not _FB_SELECTED
            panel_findnext(cpanel)
        .untilz
    .endif
    mov esi,eax
    progress_close()
    _close(mklist.handle)
    mov eax,esi
    ret

mksublist endp


mkwslist proc private zip_list:SINT

    .if cpanel_findfirst()

        mov rax,cpanel
        mov rdx,[rax].PANEL.wsub
        mov eax,[rdx].WSUB.flag

        .if eax & _W_ARCHIVE
            mov rdx,[rdx].WSUB.arch
        .else
            mov rdx,[rdx].WSUB.path
        .endif
        mksublist(zip_list, rdx)
    .endif
    ret

mkwslist endp


cmmklist proc

    mkwslist(0)
    ret

cmmklist endp


mkziplst_open proc buffer:LPSTR

    mov mklist.handle,ogetouth(strfcat(buffer, envtemp, &cp_ziplst), M_WRONLY)
    .if eax
        inc eax
        .if eax
            or  cflag,_C_DELTEMP
            mov eax,1
        .endif
    .endif
    ret

mkziplst_open endp


mkziplst proc

    mov mklsubcnt,0
    mkwslist(1)
    mov edx,mklsubcnt
    ret

mkziplst endp

    END
