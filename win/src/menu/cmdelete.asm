; CMDELETE.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include io.inc
include stdlib.inc
include string.inc
include errno.inc
include progress.inc
include confirm.inc

    .data
     __spath string_t 0

    .code

    option proc:private

open_progress proc

    setconfirmflag()
    progress_open("Delete", 0)
    ret

open_progress endp


remove_file proc uses rbx directory:LPSTR, filename:LPSTR, attrib:UINT

    .new path[2048]:char_t

    .ifd !progress_set(filename, directory, 0)

        .ifd ( confirm_delete_file(filename, attrib) && eax != -1 )

            mov _diskflag,1
            mov rbx,_utftows(strfcat(&path, directory, filename))

            .if ( attrib & _A_RDONLY )

                _wsetfattr(rbx, 0)
            .endif

            _set_errno( 0 )
            .ifd _wremove(rbx)

                erdelete(filename)
            .endif
        .endif
    .endif
    ret

remove_file endp


remove_directory proc directory:LPSTR

  local path[2048]:byte

    .ifd ( confirm_delete_sub(strfcat(&path, __spath, directory)) == 1 )

        scan_directory(0, &path)
    .endif
    ret

remove_directory endp


fp_remove_file proc directory:LPSTR, wfblock:ptr

    ldr rdx,wfblock
    remove_file(directory, &[rdx].WIN32_FIND_DATA.cFileName, [rdx].WIN32_FIND_DATA.dwFileAttributes)
    ret

fp_remove_file endp


fp_remove_directory proc uses rsi rbx directory:LPSTR

    ldr rbx,directory

    .ifd ( !progress_set(0, rbx, 1) )

        mov esi,scan_files(rbx)
        mov rbx,_utftows(rbx)

        mov _diskflag,1
        _wsetfattr(rbx, 0)
        _wrmdir(rbx)
        mov eax,esi
    .endif
    ret

fp_remove_directory endp


cmdelete_remove proc name:string_t, flags:uint_t

    .if ( flags & _A_SUBDIR )
        remove_directory(name)
    .else
        _set_errno(0)
        remove_file(__spath, name, flags)
    .endif
    ret

cmdelete_remove endp


    option proc: PUBLIC

cmdelete proc uses rsi rbx

    .if ( cpanel_findfirst() == NULL || ecx & _FB_ROOTDIR )

        .return( 0 )
    .endif

    mov rbx,rdx
    mov rsi,cpanel
    open_progress()
    mov ecx,[rbx].FBLK.flag

    .if ( ecx & _FB_ARCHEXT )

        warcdelete([rsi].PANEL.wsub, rbx)

    .elseif ( ecx & _FB_ARCHZIP )

        .repeat
            .break .ifd wzipdel([rsi].PANEL.wsub, rbx)
            and [rbx].FBLK.flag,not _FB_SELECTED
            panel_findnext(rsi)
            mov rbx,rdx
        .until !rax
    .else
        mov rdx,[rsi].PANEL.wsub
        mov rax,[rdx].WSUB.path
        mov __spath,rax

        mov fp_maskp,&cp_stdmask
        mov fp_fileblock,&fp_remove_file
        mov fp_directory,&fp_remove_directory
        mov rax,[rbx].FBLK.name

        .if !( ecx & _FB_SELECTED )

            cmdelete_remove(rax, ecx)
        .else
            .repeat
                .break .ifd cmdelete_remove(rax, ecx)
                and [rbx].FBLK.flag,not _FB_SELECTED
                panel_findnext(rsi)
                mov rbx,rdx
            .until !rax
        .endif
    .endif
    mov _diskflag,1
    progress_close()
    ret

cmdelete endp

    END
