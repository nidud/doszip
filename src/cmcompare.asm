; CMCOMPARE.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include io.inc
include string.inc
include stdlib.inc
include config.inc

    .code

CompareOptions proc uses rsi rdi rbx options:ptr compare_options

    .if rsopen(IDD_CompareOptions)

        mov rsi,rax
        mov rcx,options
        mov eax,[rcx]
        tosetbitflag([rsi].DOBJ.object, compare_count, _O_FLAGB, eax)
        dlinit(rsi)

        .while rsevent(IDD_CompareOptions, rsi)

            togetbitflag([rsi].DOBJ.object, compare_count, _O_FLAGB)

            .if ( ( eax & compare_data ) && !( eax & compare_size ) )

                ermsg("Compare Options", "Option File Content needs Size")

            .elseif ( eax == 0 )

                ermsg("Compare Options", "At least one Option needed")

            .else
                mov ebx,eax
               .break
            .endif
        .endw
        mov edi,eax
        dlclose(rsi)

        .if edi

            mov rcx,options
            mov eax,[rcx]
            and eax,compare_equal or compare_subdir
            or  eax,ebx
            mov [rcx],eax
        .endif
        mov eax,edi
    .endif
    ret

CompareOptions endp

cmcompoption proc

    .new options:compare_options = compare_default

    .if CFGetSection(".compsubdir")
        .if INIGetEntryID(rax, 0)
            mov options,__xtol(rax)
        .endif
    .endif

    .ifd CompareOptions(&options)

        .if CFAddSection(".compsubdir")

            mov rcx,rax
            INIAddEntryX(rcx, "0=%X", options)
        .endif
    .endif
    .return(_C_NORMAL)

cmcompoption endp


ComapareFBLK proc private uses rsi rdi rbx a:PFBLK, b:PFBLK, options:compare_options

    ldr rsi,a
    ldr rdi,b
    mov ebx,1

    .if ( options & compare_size ) ; Compare File Size

        .if ( [rsi].FBLK.size != [rdi].FBLK.size )
            xor ebx,ebx
        .endif
    .endif
    .if ( options & compare_attrib ) ; Compare File Attributes

        .if ( [rsi].FBLK.flag != [rdi].FBLK.flag )
            xor ebx,ebx
        .endif
    .endif
    .if ( options & compare_time ) ; Compare Last modification time

        .if ( [rsi].FBLK.time != [rdi].FBLK.time )
            xor ebx,ebx
        .endif
    .endif
    .if ( options & compare_name ) ; Compare File name

        .if ( _stricmp([rsi].FBLK.name, [rdi].FBLK.name) )
            xor ebx,ebx
        .endif
    .endif
    mov eax,ebx
    ret

ComapareFBLK endp


cmcompare proc uses rsi rdi rbx

    .new fcb_A:ptr, fcb_B:ptr, fblk_A:PFBLK, fblk_B:PFBLK
    .new count_A:UINT, count_B:UINT, loopc_A:UINT, loopc_B:UINT, equal_C:UINT
    .new a:PPANEL, b:PPANEL
    .new options:compare_options = compare_default

    .if CFGetSection(".compsubdir")
        .if INIGetEntryID(rax, 0)
            mov options,__xtol(rax)
        .endif
    .endif

    .if !(options & compare_default)

        ermsg("Warning", "The Compare Options flag is zero\n(nothing to do)\n\nUse Alt-O to reset the flags")
    .endif

    mov rsi,panela
    mov rdi,panelb
    .if rsi != cpanel
        xchg rsi,rdi        ; Set SI to current panel
    .endif

    .return .ifd !panel_stateab() ; Need two panels

    mov rbx,[rsi].PANEL.wsub
    mov eax,[rbx].WSUB.flag
    mov rbx,[rdi].PANEL.wsub
    mov edx,[rbx].WSUB.flag
    and eax,_W_LONGNAME ; Need equal file names
    and edx,_W_LONGNAME
    .if eax != edx

        stdmsg("Compare directories", "Only one panel use Long File Names")
       .return
    .endif

    mov rax,[rsi].PANEL.wsub
    mov rax,[rax].WSUB.fcb
    mov fcb_A,rax       ; fblk **A
    mov rax,[rdi].PANEL.wsub
    mov rax,[rax].WSUB.fcb
    mov fcb_B,rax       ; fblk **B
    mov eax,[rsi].PANEL.fcb_count
    mov count_A,eax     ; count A
    mov loopc_A,eax
    mov ecx,eax
    mov eax,[rdi].PANEL.fcb_count
    mov count_B,eax     ; count B
    mov loopc_B,eax
    mov a,rsi           ; Select all files in both panels
    mov rbx,fcb_A

    .while ecx

        dec ecx
        mov rsi,[rbx]
        or  [rsi].FBLK.flag,_FB_SELECTED
        add rbx,PFBLK
        .if [rsi].FBLK.flag & _A_SUBDIR

            and [rsi].FBLK.flag,not _FB_SELECTED
            dec count_A
        .endif
    .endw
    mov rbx,fcb_B

    .while eax

        dec eax
        mov rsi,[rbx]
        or  [rsi].FBLK.flag,_FB_SELECTED
        add rbx,PFBLK
        .if [rsi].FBLK.flag & _A_SUBDIR

            and [rsi].FBLK.flag,not _FB_SELECTED
            dec count_B
        .endif
    .endw

    mov rsi,a
    mov eax,count_A
    add eax,count_B
    ;
    ; If both panels have zero files they are identical
    ;
    .ifz

        stdmsg("Compare directories", "The two folders seems\nto be identical")
       .return
    .endif
    ;
    ; If one of the panels have zero files
    ; then everything is ok (selected)
    ;
    xor eax,eax
    .if eax == count_A || eax == count_B

        panel_putitem(rsi, 0)
        panel_putitem(rdi, 0)
       .return
    .endif
    ;
    ; Compare file blocks and de-select if equal
    ;
    mov equal_C,eax ; Number of identical files
    mov loopc_A,eax ; Loop count A

    .while 1

        mov eax,loopc_A
        .break .if eax >= [rsi].PANEL.fcb_count

        xor eax,eax
        mov loopc_B,eax

        .while 1

            mov eax,loopc_B
            .break .if eax >= [rdi].PANEL.fcb_count

            mov rbx,fcb_B
            mov rbx,[rbx+rax*PFBLK]
            mov fblk_B,rbx

            .if !( [rbx].FBLK.flag & _A_SUBDIR )

                mov a,rsi
                mov b,rdi

                mov rsi,fcb_A
                mov eax,loopc_A
                mov rsi,[rsi+rax*PFBLK]
                mov fblk_A,rsi
                xor eax,eax

                .if !( [rsi].FBLK.flag & _A_SUBDIR)

                    ComapareFBLK(rsi, fblk_B, options)
                .endif

                mov rdi,b
                mov rsi,a
                .if eax
                    mov rbx,fblk_B
                    and [rbx].FBLK.flag,not _FB_SELECTED
                    mov rbx,fblk_A
                    and [rbx].FBLK.flag,not _FB_SELECTED
                    inc equal_C
                   .break
                .endif
            .endif
            inc loopc_B
        .endw
        inc loopc_A
    .endw

    panel_putitem(rsi, 0)
    panel_putitem(rdi, 0)
    mov eax,count_A
    .if ( eax == count_B && eax == equal_C )
        stdmsg("Compare directories", "The two folders seems\nto be identical")
    .endif
    ret

cmcompare endp

    END
