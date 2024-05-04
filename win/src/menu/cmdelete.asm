; CMDELETE.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include io.inc
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


remove_file proc uses rsi directory:LPSTR, filename:LPSTR, attrib

  local path[_MAX_PATH*2]:char_t

    lea rsi,path

    .ifd !progress_set(filename, directory, 0)

	.ifd confirm_delete_file(filename, attrib) && eax != -1

	    strfcat(rsi, directory, filename)
	    .if byte ptr attrib & _A_RDONLY
		setfattr(rsi, 0)
	    .endif

	    mov errno,0
	    .ifd remove(rsi)
		erdelete(rsi)
	    .endif
	.endif
    .endif
    ret
remove_file endp


remove_directory proc directory:LPSTR

  local path[_MAX_PATH*2]:byte

    .ifd confirm_delete_sub(strfcat(&path, __spath, directory)) == 1

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
    .ifd !progress_set(0, rbx, 1)

	mov esi,scan_files(rbx)
	setfattr(rbx, 0)
	_rmdir(rbx)
	mov eax,esi
    .endif
    ret

fp_remove_directory endp


cmdelete_remove proc

    .if cl & _A_SUBDIR
	remove_directory(rax)
    .else
	mov errno,0
	remove_file(__spath, rax, ecx)
    .endif
    ret

cmdelete_remove endp


    option proc: PUBLIC

cmdelete proc uses rbx

    .switch
    .case !cpanel_findfirst()
    .case ecx & _FB_ROOTDIR
	xor eax,eax
       .endc
    .case ecx & _FB_ARCHEXT
	mov rax,cpanel
	mov rax,[rax].PANEL.wsub
	warcdelete(rax, rdx)
	xor eax,eax
       .endc
    .case ecx & _FB_ARCHZIP
	xor eax,eax
	mov rbx,rdx
	open_progress()
	.repeat
	    mov rax,cpanel
	    .break .ifd wzipdel([rax].PANEL.wsub, rbx)
	    and [rbx].FBLK.flag,not _FB_SELECTED
	    panel_findnext(cpanel)
	    mov rbx,rdx
	.untilz
	progress_close()
	.endc

    .default

	mov rbx,rdx
	mov rax,cpanel
	mov rdx,[rax].PANEL.wsub
	mov rax,[rdx].WSUB.path
	mov __spath,rax

	mov fp_maskp,&cp_stdmask
	mov fp_fileblock,&fp_remove_file
	mov fp_directory,&fp_remove_directory

	open_progress()
	mov rdx,rbx
	mov ecx,[rdx].FBLK.flag
	lea rax,[rdx].FBLK.name

	.if !( ecx & _FB_SELECTED )

	    cmdelete_remove()
	.else
	    .repeat

		.break .ifd cmdelete_remove()
		and [rbx].FBLK.flag,not _FB_SELECTED
		panel_findnext(cpanel)
		mov rbx,rdx
	    .untilz
	.endif
	progress_close()
    .endsw
    ret

cmdelete endp

    END
