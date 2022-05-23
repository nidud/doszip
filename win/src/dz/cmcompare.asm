; CMCOMPARE.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include io.inc
include string.inc
include crtl.inc
include stdlib.inc
include cfini.inc

externdef cp_compare:byte

    .code

CompareOptions proc uses esi edi ebx options:ptr compare_options

    .if rsopen(IDD_CompareOptions)

        mov esi,eax
        mov ecx,options
        mov eax,[ecx]
        tosetbitflag([esi].S_DOBJ.dl_object, compare_count, _O_FLAGB, eax)
        dlinit(esi)

        .while rsevent(IDD_CompareOptions, esi)

            togetbitflag([esi].S_DOBJ.dl_object, compare_count, _O_FLAGB)

            .if ( (eax & compare_data) && !(eax & compare_size) )

                ermsg("Compare Options", "Option File Content needs Size")

            .elseif ( eax == 0 )

                ermsg("Compare Options", "At least one Option needed")

            .else
                mov ebx,eax
               .break
            .endif
        .endw
        mov edi,eax
        dlclose(esi)

        .if edi

            mov ecx,options
            mov eax,[ecx]
            and eax,compare_equal or compare_subdir
            or  eax,ebx
            mov [ecx],eax
        .endif
        mov eax,edi
    .endif
    ret

CompareOptions endp

cmcompoption proc

    .new options:compare_options = compare_default

    .if CFGetSection(".compsubdir")
        .if INIGetEntryID(eax, 0)
            mov options,__xtol(eax)
        .endif
    .endif

    .if CompareOptions(&options)

        .if CFAddSection(".compsubdir")

            INIAddEntryX(eax, "0=%X", options)
        .endif
    .endif
    mov eax,_C_NORMAL
    ret

cmcompoption endp


ComapareFBLK proc uses esi edi ebx a:LPFBLK, b:LPFBLK, options:compare_options

    mov esi,a
    mov edi,b
    mov ebx,1

    .if ( options & compare_size ) ; Compare File Size

        .if ( [esi].S_FBLK.fb_size != [edi].S_FBLK.fb_size )
            xor ebx,ebx
        .endif
    .endif
    .if ( options & compare_attrib ) ; Compare File Attributes

        .if ( [esi].S_FBLK.fb_flag != [edi].S_FBLK.fb_flag )
            xor ebx,ebx
        .endif
    .endif
    .if ( options & compare_time ) ; Compare Last modification time

        .if ( [esi].S_FBLK.fb_time != [edi].S_FBLK.fb_time )
            xor ebx,ebx
        .endif
    .endif
    .if ( options & compare_name ) ; Compare File name

        .if ( _stricmp(&[esi].S_FBLK.fb_name, &[edi].S_FBLK.fb_name) )
            xor ebx,ebx
        .endif
    .endif
    mov eax,ebx
    ret

ComapareFBLK endp


cmcompare proc uses esi edi ebx

  local fcb_A, fcb_B, fblk_A, fblk_B,
    count_A, count_B, loopc_A, loopc_B, equal_C

    .new options:compare_options = compare_default
    .if CFGetSection(".compsubdir")
        .if INIGetEntryID(eax, 0)
            mov options,__xtol(eax)
        .endif
    .endif

    .if !(options & compare_default)

        ermsg("Warning", "The Compare Options flag is zero\n(nothing to do)\n\nUse Alt-O to reset the flags")
    .endif

    mov esi,panela
    mov edi,panelb
    .if esi != cpanel
        xchg esi,edi        ; Set SI to current panel
    .endif

    .repeat

        panel_stateab()     ; Need two panels
        .break .ifz

        mov ebx,[esi]
        mov eax,[ebx]
        mov ebx,[edi]
        mov edx,[ebx]
        and eax,_W_LONGNAME ; Need equal file names
        and edx,_W_LONGNAME
        .if eax != edx

            stdmsg(&cp_compare, "Only one panel use Long File Names")
            .break
        .endif

        mov eax,[esi].S_PANEL.pn_wsub
        mov eax,[eax].S_WSUB.ws_fcb
        mov fcb_A,eax       ; fblk **A
        mov eax,[edi].S_PANEL.pn_wsub
        mov eax,[eax].S_WSUB.ws_fcb
        mov fcb_B,eax       ; fblk **B
        mov eax,[esi].S_PANEL.pn_fcb_count
        mov count_A,eax     ; count A
        mov loopc_A,eax
        mov ecx,eax
        mov eax,[edi].S_PANEL.pn_fcb_count
        mov count_B,eax     ; count B
        mov loopc_B,eax
        push esi            ; Select all files in both panels
        mov ebx,fcb_A

        .while ecx

            dec ecx
            mov esi,[ebx]
            or  [esi].S_FBLK.fb_flag,_FB_SELECTED
            add ebx,4
            .if [esi].S_FBLK.fb_flag & _A_SUBDIR

                and [esi].S_FBLK.fb_flag,not _FB_SELECTED
                dec count_A
            .endif
        .endw
        mov ebx,fcb_B

        .while eax

            dec eax
            mov esi,[ebx]
            or  [esi].S_FBLK.fb_flag,_FB_SELECTED
            add ebx,4
            .if [esi].S_FBLK.fb_flag & _A_SUBDIR

                and [esi].S_FBLK.fb_flag,not _FB_SELECTED
                dec count_B
            .endif
        .endw

        pop esi
        mov eax,count_A
        add eax,count_B
        ;
        ; If both panels have zero files they are identical
        ;
        .ifz

            stdmsg(&cp_compare, "The two folders seems\nto be identical")
            .break
        .endif
        ;
        ; If one of the panels have zero files
        ; then everything is ok (selected)
        ;
        xor eax,eax
        .if eax == count_A || eax == count_B

            panel_putitem(esi, 0)
            panel_putitem(edi, 0)
            .break
        .endif
        ;
        ; Compare file blocks and de-select if equal
        ;
        mov equal_C,eax ; Number of identical files
        mov loopc_A,eax ; Loop count A

        .while 1

            mov eax,loopc_A
            .break .if eax >= [esi].S_PANEL.pn_fcb_count

            xor eax,eax
            mov loopc_B,eax

            .while 1

                mov eax,loopc_B
                .break .if eax >= [edi].S_PANEL.pn_fcb_count

                mov ebx,fcb_B
                shl eax,2
                add ebx,eax
                mov eax,[ebx]
                mov fblk_B,eax
                mov ebx,[ebx]

                .if !(byte ptr [ebx] & _A_SUBDIR)

                    push esi
                    push edi

                    mov esi,fcb_A
                    mov eax,loopc_A
                    shl eax,2
                    add esi,eax
                    mov esi,[esi]
                    mov fblk_A,esi
                    xor eax,eax

                    .if !(byte ptr [esi] & _A_SUBDIR)

                        ComapareFBLK(esi, fblk_B, options)
                    .endif

                    pop edi
                    pop esi

                    .if al
                        mov ebx,fblk_B
                        mov eax,[ebx]
                        and eax,not _FB_SELECTED
                        mov [ebx],eax
                        mov ebx,fblk_A
                        mov eax,[ebx]
                        and eax,not _FB_SELECTED
                        mov [ebx],eax
                        inc equal_C
                        .break
                    .endif
                .endif
                inc loopc_B
            .endw
            inc loopc_A
        .endw

        panel_putitem(esi, 0)
        panel_putitem(edi, 0)

        mov eax,count_A
        .break .if eax != count_B
        .break .if eax != equal_C

        stdmsg(&cp_compare, "The two folders seems\nto be identical")

    .until 1
    ret

cmcompare endp

    END
