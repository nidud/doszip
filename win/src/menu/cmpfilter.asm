; CMFILTER.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include stdio.inc
include stdlib.inc
include string.inc

.enumt DZPanelFilter:TOBJ {
    ID_DZPanelFilter,
    ID_READCOUNT,
    ID_READMASK,
    ID_DIRECTORY,
    ID_OK,
    ID_LOADPATH,
    ID_CANCEL
    }

    .data
     pathptr string_t 0

    .code

event_loadpath proc private

   .new path[_MAX_PATH]:char_t = 0
   .new rc:int_t = tools_idd(_MAX_PATH, &path, "Directory")

    msloop()

    .if ( !path || !rc || rc == MOUSECMD )

        mov eax,_C_NORMAL
    .else

        strcpy(pathptr, expenviron(&path))
        mov eax,_C_REOPEN
    .endif
    ret

event_loadpath endp


PanelFilter proc private uses rsi rdi rbx panel:PPANEL, xpos:int_t


    ldr rbx,panel
    ldr eax,xpos
    mov rdi,IDD_DZPanelFilter
    mov [rdi].RIDD.rc.x,al

    .if rsopen(rdi)

        mov rdi,rax
        mov rsi,[rbx].PANEL.wsub
        mov [rdi].TOBJ.tproc[ID_LOADPATH],&event_loadpath
        mov pathptr,[rdi].TOBJ.data[ID_DIRECTORY]

        strcpy(rax, [rsi].WSUB.path)
        strcpy([rdi].TOBJ.data[ID_READMASK], [rsi].WSUB.mask)
        sprintf([rdi].TOBJ.data[ID_READCOUNT], "%d", [rsi].WSUB.maxfb)
        dlinit(rdi)

        .ifd dlevent(rdi)

            mov ebx,atol([rdi].TOBJ.data[ID_READCOUNT])

            strcpy([rdi].TOBJ.data[ID_DIRECTORY], [rsi].WSUB.path)
            strcpy([rdi].TOBJ.data[ID_READMASK], [rsi].WSUB.mask)
            dlclose(rdi)

            .if ( ebx != [rsi].WSUB.maxfb && ebx > 10 && ebx < WMAXFBLOCK && [rsi].WSUB.fcb )

                mov edi,[rsi].WSUB.maxfb
                mov [rsi].WSUB.maxfb,ebx

                .ifd wsopen(rsi)

                    mov eax,1
                .else

                    mov [rsi].WSUB.maxfb,edi
                    wsopen(rsi)
                    xor eax,eax
                .endif
            .endif

            mov edi,eax
            mov rbx,panel
            panel_reread(rbx)

            .if ( rbx == cpanel )

                cominit(rsi)
            .endif
            mov eax,edi
        .else
            dlclose(rdi)
            xor eax,eax
        .endif
    .endif
    ret

PanelFilter endp


cmafilter proc

    PanelFilter(panela, 3)
    ret

cmafilter endp


cmbfilter proc

    PanelFilter(panelb, 42)
    ret

cmbfilter endp


cmloadpath proc uses rbx

  local path[_MAX_PATH]:char_t

    lea rbx,path
    mov pathptr,rbx
    .ifd ( event_loadpath() == _C_REOPEN )

        cpanel_setpath(rbx)
    .endif
    ret

cmloadpath endp

    END
