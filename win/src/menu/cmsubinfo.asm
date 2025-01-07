; CMSUBINFO.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include io.inc
include stdlib.inc
include conio.inc
include string.inc
include progress.inc

.data
 qrax           label qword
 qeax           dd 0
 qedx           dd 0
 di_subdcount   dd 0
 di_filecount   dd 0
 cp_bytesize    db "BKMGTPE",0

    .code

di_fileblock proc private directory:LPSTR, wblk:ptr

    inc di_filecount
    mov rcx,wblk
    mov eax,[rcx].WIN32_FIND_DATA.nFileSizeLow
    mov edx,[rcx].WIN32_FIND_DATA.nFileSizeHigh
    add qeax,eax
    adc qedx,edx
    xor eax,eax
    ret

di_fileblock endp

di_directory proc private uses rsi directory:LPSTR

    mov rsi,directory
    lea rdx,[rsi+strlen(rsi)-1]
    mov eax,'\'
    .if [rdx] == al
        mov [rdx],ah
    .endif

    .ifd !progress_set(0, rsi, 0)

        inc di_subdcount
        scan_files(rsi)
    .endif
    ret

di_directory endp


di_Init proc private

    xor eax,eax
    mov qeax,eax
    mov qedx,eax
    mov di_filecount,eax
    mov di_subdcount,eax
    ret

di_Init endp


di_ReadDirectory proc private directory:LPSTR

    progress_open("Directory Information", 0)
    mov fp_maskp,&cp_stdmask
    mov fp_fileblock,&di_fileblock
    mov fp_directory,&di_directory
    scan_directory(1, directory)
    progress_close()
    ret

di_ReadDirectory endp


di_SubInfo proc private uses rsi rdi rbx s1:LPSTR, s2:LPSTR

  local x,y,col

    .if rsopen(IDD_DZSubInfo)

        mov     rdi,rax
        movzx   eax,[rdi].DOBJ.rc.x
        add     eax,5
        mov     x,eax
        movzx   eax,[rdi].DOBJ.rc.y
        add     eax,2
        mov     y,eax
        movzx   eax,[rdi].DOBJ.rc.col
        mov     col,eax

        wctitle([rdi].DOBJ.wp, eax, s2)
        dlshow(rdi)

        mov ecx,x
        add ecx,10
        scpath(ecx, y, 20, s1)

        mov ecx,x
        sub ecx,11
        inc y
        dec x
        scputf(x, y, 0, 0, "%10u", di_filecount)

        mov eax,di_subdcount
        dec eax
        inc y
        scputf(x, y, 0, 0, "%10u", eax)

        mov ebx,mkbstring(s1, qrax)
        mov esi,edx
        add x,2
        add y,2
        scputf(x, y, 0, 0, "total %s byte", s1)

        .if ebx && esi

            lea rcx,cp_bytesize
            mov al,[rcx+rsi]
            add x,6
            inc y
            scputf(x, y, 0, 0, "%u%c", ebx, eax)
        .endif
        dlmodal(rdi)
    .endif
    ret

di_SubInfo endp


di_SelectedFiles proc private uses rsi rdi s1:LPSTR

    inc di_subdcount
    xor esi,esi

    .while 1

        mov eax,1
        mov rdx,cpanel
        .break .if esi >= [rdx].PANEL.fcb_count

        mov rax,[rdx].PANEL.wsub
        mov rax,[rax].WSUB.fcb
        mov rax,[rax+rsi*size_t]
        mov ecx,[rax].FBLK.flag
        inc esi

        .if ( ecx &_FB_SELECTED )

            .if ( ecx & _A_SUBDIR )

                mov rdx,[rdx].PANEL.wsub
               .break .ifd di_ReadDirectory(strfcat(s1, [rdx].WSUB.path, [rax].FBLK.name))
            .else
                mov edx,dword ptr [rax].FBLK.size[4]
                mov eax,dword ptr [rax].FBLK.size
                add qeax,eax
                adc qedx,edx
                inc di_filecount
            .endif
        .endif
    .endw

    .if eax
        mov rax,cpanel
        mov rax,[rax].PANEL.wsub
        di_SubInfo(strcpy(s1, [rax].WSUB.path), "Selected Files")
    .endif
    ret

di_SelectedFiles endp


di_cmSubInfo proc private uses rsi rdi rbx panel:PPANEL

  local path[_MAX_PATH]:char_t

    mov rsi,panel
    lea rdi,path

    .if panel_state(rsi)

        mov rbx,[rsi].PANEL.wsub
        xor eax,eax

        .if !( [rbx].WSUB.flag & _W_ARCHIVE or _W_ROOTDIR )

            di_Init()
            .if panel_findnext(rsi)
                di_SelectedFiles(rdi)
            .else
                .ifd !di_ReadDirectory(strcpy(rdi, [rbx].WSUB.path))
                    di_SubInfo(rdi, "Directory Information")
                .endif
            .endif
        .endif
    .endif
    ret

di_cmSubInfo endp


cmsubinfo proc
    di_cmSubInfo(cpanel)
    ret
cmsubinfo endp

cmasubinfo proc
    di_cmSubInfo(panela)
    ret
cmasubinfo endp

cmbsubinfo proc
    di_cmSubInfo(panelb)
    ret
cmbsubinfo endp


cmsubsize proc

  local path[_MAX_PATH]:byte

    di_Init()
    .if panel_curobj(cpanel)

        .if !( ecx & _FB_ARCHIVE or _FB_UPDIR )

            mov rdx,cpanel
            mov rdx,[rdx].PANEL.wsub
            mov rcx,rax
            .ifd !di_ReadDirectory(strfcat(&path, [rdx].WSUB.path, rcx))
                di_SubInfo(&path, "Directory Information")
            .endif
        .endif
    .endif
    xor eax,eax
    ret

cmsubsize endp

    end
