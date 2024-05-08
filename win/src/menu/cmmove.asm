; CMMOVE.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include io.inc
include stdlib.inc
include string.inc
include errno.inc
include conio.inc
include progress.inc

    .data
     jmp_count UINT 0

    .code

move_initfiles proc private filename:LPSTR

    strfcat(__outfile, __outpath, filename)
    strfcat(__srcfile, __srcpath, filename)
    ret

move_initfiles endp

move_deletefile proc private uses rbx result:SINT, flag:UINT

    mov eax,result
    add eax,copy_jump
    .if eax

        mov eax,result
        .if !eax

            mov copy_jump,eax
            inc jmp_count
        .endif
    .else

        mov rbx,_utftows(__srcfile)
        .if ( flag & _A_RDONLY )

            _wsetfattr(rbx, 0)
        .endif
        _wremove(rbx)
        mov eax,result
    .endif
    ret

move_deletefile endp

fp_movedirectory proc private uses rbx directory:LPSTR

    .ifd !progress_set(0, directory, 0)

        mov rbx,_utftows(directory)
        _wsetfattr(rbx, 0)
        .ifd _wrmdir(rbx)

            xor eax,eax
            .if jmp_count == eax

                erdelete(directory)
            .endif
        .endif
    .endif
    ret

fp_movedirectory endp

fp_movefile proc private directory:LPSTR, wfblk:PWIN32_FIND_DATA

    fp_copyfile(directory, wfblk)
    mov rdx,wfblk
    move_deletefile(eax, [rdx].WIN32_FIND_DATA.dwFileAttributes)
    ret

fp_movefile endp

fblk_movefile proc private uses rbx fblk:PFBLK

    ldr rbx,fblk

    .ifd !progress_set(addr [rbx].FBLK.name, __outpath, [rbx].FBLK.size)

        .ifd rename(__srcfile, __outfile)

            copyfile([rbx].FBLK.size, [rbx].FBLK.time, [rbx].FBLK.flag)
            move_deletefile(eax, [rbx].FBLK.flag)
        .endif
    .endif
    ret

fblk_movefile endp

fblk_movedirectory proc private uses rsi rdi fblk:PFBLK

  local path[512]:byte

    lea rdi,path
    ldr rsi,fblk
    add rsi,FBLK.name

    .ifd !progress_set(rsi, __outpath, 0)

        move_initfiles(rsi)
        .ifd rename(rax, __outfile)

            strfcat(rdi, __srcpath, rsi)
            mov fp_directory,&fp_copydirectory
            .ifd scansub(rdi, &cp_stdmask, 1)

                mov eax,-1
            .else
                .if copy_jump == eax

                    mov fp_directory,&fp_movedirectory
                    scansub(rdi, addr cp_stdmask, 0)
                .else
                    mov copy_jump,eax
                    inc jmp_count
                .endif
            .endif
        .endif
    .endif
    ret

fblk_movedirectory endp


cmmove proc uses rdi

    .if cpanel_findfirst()

        mov rdi,rdx

        .if ( ecx & ( _FB_ARCHZIP or _FB_UPDIR ) )
            ;
            ; ...
            ;
        .elseifd init_copy(rdi, 0)

            .if !( copy_flag & _COPY_IARCHIVE or _COPY_OARCHIVE )

                mov jmp_count,0
                mov fp_fileblock,&fp_movefile
                progress_open("Move", "Move")

                mov ecx,[rdi].FBLK.flag
                .if ecx & _FB_SELECTED
                    .while  1
                        .if ecx & _A_SUBDIR
                            fblk_movedirectory(rdi)
                        .else
                            move_initfiles(&[rdi].FBLK.name)
                            fblk_movefile(rdi)
                        .endif
                        .break .if eax
                        and [rdi].FBLK.flag,not _FB_SELECTED
                        .break .if !panel_findnext(cpanel)
                        mov rdi,rdx
                    .endw
                .else
                    .if ecx & _A_SUBDIR
                        fblk_movedirectory(rdi)
                    .else
                        fblk_movefile(rdi)
                    .endif
                .endif
                progress_close()
                mov eax,1
                mov _diskflag,eax
            .endif
        .endif
    .endif
    ret

cmmove endp

    end
