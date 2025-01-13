; CMCOMPRESS.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include io.inc
include config.inc
include dzstr.inc

    .data
     default_arc char_t "default.7z", 128-11 dup(0)

    .code

PackerGetSection proc private uses rsi rdi rbx section:LPSTR, result:LPSTR

    .new d:PDOBJ

    .if rsopen(IDD_DZHistory)

        mov rbx,rax
        xor esi,esi

        .if CFGetSection(section)

            mov d,rbx
            mov rdi,rax
            mov rbx,[rbx].DOBJ.object

            .while INIGetEntryID(rdi, esi)

                strnzcpy([rbx].TOBJ.data, rax, 128-1)
                and [rbx].TOBJ.flag,not (_O_STATE or _O_LLIST)
                inc esi
                add rbx,TOBJ
            .endw
            mov rbx,d
        .endif

        mov eax,esi
        .if eax

            mov [rbx].DOBJ.count,al

            dlinit(rbx)
            dlshow(rbx)

            movzx ecx,[rbx].DOBJ.rc.x
            movzx edx,[rbx].DOBJ.rc.y
            add ecx,8
            scputf(ecx, edx, 0, 0, "Select External Tool")

            .ifd rsevent(IDD_DZHistory, rbx)

                imul eax,eax,TOBJ
                strcpy(result, [rbx+rax].TOBJ.data)
            .endif
        .endif
        mov rdi,rax
        dlclose(rbx)
        mov rax,rdi
    .endif
    ret

PackerGetSection endp

cmcompress proc uses rsi rdi rbx

    local section[128]:byte
    local list[_MAX_PATH]:byte
    local archive[_MAX_PATH]:byte
    local cmd[_MAX_PATH]:byte

    lea rsi,archive
    lea rdi,default_arc

    .if cpanel_findfirst() && !( ecx & _FB_ROOTDIR or _FB_ARCHIVE )

        .if cpanel_gettarget()

            strfcat(rsi, rax, rdi)

            .if PackerGetSection("Compress", &section)

                .if CFGetSectionID(rax, 2)

                    strfxcat(rsi, rax)
                .endif

                .if rsopen(IDD_DZCopy)

                        mov rbx,rax
                    mov filter,0
                    mov [rbx].TOBJ.data[TOBJ],rsi
                    mov byte ptr [rbx].TOBJ.count[TOBJ],16
                    mov [rbx].TOBJ.tproc[3*TOBJ],&cpyevent_filter

                    wcenter([rbx].DOBJ.wp, 59, "Compress")

                    .ifd dlmodal(rbx)

                        ;------------------------------------------
                        ; no unix path, no mask in directory\[*.*]
                        ;------------------------------------------

                        mov eax,mklist.flag
                        and eax,not (_MKL_UNIX or _MKL_MASK)
                        mov mklist.flag,eax

                        .ifd mkziplst_open(&list)

                            .ifd mkziplst()
                                xor eax,eax
                            .else
                                or  eax,mklist.count
                            .endif
                        .endif

                        .if eax

                            strcpy(rdi, strfn(rsi))
                            lea rbx,section

                            .if CFGetSectionID(rbx, 0)

                                lea rdi,cmd
                                strcat(strcat(strcat(strcpy(rdi, rax), " "), rsi), " ")

                                .if !CFGetSectionID(rbx, 1)
                                    lea rax,@CStr("@")
                                .endif
                                strcat(rdi, rax)
                                command(strcat(rdi, &list))
                            .endif
                        .endif
                    .endif
                .endif
            .endif
        .endif
    .endif
    ret

cmcompress endp


cmdecompress proc uses rsi rdi rbx

    local archive:LPSTR
    local section[128]:char_t
    local cmd[_MAX_PATH]:char_t
    local path[_MAX_PATH]:char_t

    lea rsi,path
    lea rbx,section

    .if cpanel_findfirst() && !( ecx & _A_SUBDIR or _FB_ROOTDIR or _FB_ARCHIVE )

        mov archive,rax

        .if cpanel_gettarget()

            strcpy(rsi, rax)

            .if PackerGetSection("Decompress", rbx)

                .if rsopen(IDD_DZDecompress)

                    mov rdi,rax
                    mov [rdi].TOBJ.count[TOBJ],256/16
                    mov [rdi].TOBJ.data[TOBJ],rsi

                    dlinit(rdi)
                    dlshow(rdi)

                    mov ax,[rdi+4]
                    add ax,0x020E
                    mov dl,ah
                    scpath(eax, edx, 50, archive)

                    .ifd dlmodal(rdi)

                        .if CFGetSectionID(rbx, 0)

                            lea rdi,cmd
                            strcat(strcpy(rdi, rax), " ")

                            .if CFGetSectionID(rbx, 1)

                                ; <command> -o"<out_path>" <archive>

                                strcat(rdi, rax)
                                strcat(strcat(strcat(strcat(rdi, "\""), rsi), "\" "), archive)
                            .else

                                ; <command> <archive> "<out_path>\"

                                strcat(strcat(rdi, archive), " \"")
                                strcat(strcat(rdi, rsi), "\\\"")
                            .endif
                            command(rdi)
                        .endif
                    .endif
                .endif
            .endif
        .endif
    .endif
    ret

cmdecompress endp

    end
