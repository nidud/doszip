; CMSETUP.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include io.inc
include string.inc
include stdlib.inc
include errno.inc
include stdio.inc
include malloc.inc
include config.inc

define __AT__

.enumt ID_DZSystemOptions:TOBJ {
    ID_SysOptionsDLG,
    ID_UBEEP,           ; Use Beep
    ID_MOUSE,           ; Use Mouse
    ID_IOSFN,           ; Use Long File Names
    ID_CLIPB,           ; Use System Clipboard
    ID_ASCII,           ; Use Ascii symbol
    ID_NTCMD,           ; Use NT Prompt
    ID_CMDENV,          ; CMD Compatible Mode
    ID_IMODE,           ; Init screen mode on startup
    ID_DELHISTORY,
    ID_ESCUSERSCR
    }

.enumt ID_DZScreenOptions:TOBJ {
    ID_ScreenOptions,
    ID_MEUSLINE,
    ID_USEDATE,
    ID_USETIME,
    ID_USELDATE,
    ID_USELTIME,
    ID_COMMANDLINE,
    ID_STAUSLINE,
    ID_ATTRIB,
    ID_STANDARD,
    ID_LOAD,
    ID_SAVE
    }

    .data

cf_panel        db 0
cf_panel_upd    db 0
cf_screen_upd   db 0

color_Blue byte \
    0x00,0x0F,0x0F,0x07,0x08,0x00,0x00,0x07,
    0x08,0x00,0x0A,0x0B,0x00,0x0F,0x0F,0x0F,
    0x00,0x10,0x70,0x70,0x40,0x30,0x30,0x70,
    0x30,0x30,0x30,0x00,0x10,0x10,0x07,0x06
color_Black byte \
    0x07,0x07,0x0F,0x07,0x08,0x08,0x07,0x07,
    0x08,0x07,0x0A,0x0B,0x0F,0x0B,0x0B,0x0B,
    0x00,0x00,0x00,0x10,0x30,0x10,0x10,0x00,
    0x10,0x10,0x00,0x00,0x00,0x00,0x07,0x07
color_Mono byte \
    0x0F,0x0F,0x0F,0x0F,0x0F,0x0F,0x0F,0x0F,
    0x0F,0x0F,0x0F,0x0F,0x0F,0x0F,0x0F,0x0F,
    0x00,0x00,0x00,0x00,0x00,0x70,0x70,0x00,
    0x70,0x70,0x70,0x00,0x00,0x00,0x0F,0x0F
color_White byte \
    0x00,0x07,0x0F,0x07,0x08,0x07,0x00,0x07,
    0x08,0x00,0x0A,0x0B,0x00,0x07,0x08,0x08,
    0x00,0x10,0xF0,0xF0,0x40,0x70,0x70,0x70,
    0x80,0x30,0x70,0x70,0x00,0x00,0x07,0x07
color_Norton byte \
    0x07,0x0B,0x0B,0x0B,0x0B,0x00,0x00,0x07,
    0x08,0x0F,0x0E,0x0B,0x0F,0x00,0x0E,0x0E,
    0x00,0x10,0x30,0x30,0x40,0xF0,0x20,0x70,
    0xF0,0x30,0x00,0x00,0x30,0x30,0x0F,0x0F

color_Table LPSTR \
    color_Blue,
    color_Black,
    color_Mono,
    color_White,
    color_Norton

    .code

event_help proc private
    view_readme(HELPID_15)
    ret
event_help endp

cmsystem proc uses rsi rdi rbx

    .new th:DPROC = thelp

    .if rsopen(IDD_DZSystemOptions)

        mov rbx,rax
        mov thelp,&event_help
        mov eax,cflag
        .if eax & _C_DELHISTORY
            or [rbx].TOBJ.flag[ID_DELHISTORY],_O_FLAGB
        .endif

        .if eax & _C_ESCUSERSCR
            or [rbx].TOBJ.flag[ID_ESCUSERSCR],_O_FLAGB
        .endif
        tosetbitflag([rbx].DOBJ.object, 8, _O_FLAGB, console)
        dlinit(rbx)
        mov esi,rsevent(IDD_DZSystemOptions, rbx)

        togetbitflag([rbx].DOBJ.object, 10, _O_FLAGB)
        dlclose(rbx)

        mov thelp,th
        mov eax,esi
        .if eax

            mov eax,edx
            mov edx,cflag
            and edx,not (_C_DELHISTORY or _C_ESCUSERSCR)
            .if eax & 0x100 ; Auto Delete History
                or edx,_C_DELHISTORY
            .endif
            .if eax & 0x200 ; Use Esc for user screen
                or edx,_C_ESCUSERSCR
            .endif
            mov cflag,edx
            mov ecx,console
            mov byte ptr console,al
            and eax,CON_MOUSE or CON_IOSFN or CON_CMDENV
            and ecx,CON_MOUSE or CON_IOSFN or CON_CMDENV
            .if ecx != eax
                mov ecx,ENABLE_WINDOW_INPUT
                .if eax & CON_MOUSE
                    or ecx,ENABLE_MOUSE_INPUT
                .endif
                SetConsoleMode(_coninpfh, ecx)
                .if cf_panel == 1
                    mov cf_panel_upd,1
                .else
                    redraw_panels()
                .endif
            .endif
            mov eax,1
        .endif
    .endif
    ret

cmsystem endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    option proc:private

event_reload proc

    .if cf_panel == 0

        dlhide(tdialog)
        apiupdate()
        dlshow(tdialog)
        msloop()
        mov eax,_C_NORMAL
    .else
        msloop()
        mov cf_screen_upd,1
        mov eax,_C_ESCAPE
    .endif
    ret

event_reload endp

event_loadcolor proc uses rsi

  local path[_MAX_PATH]:byte

    .if wgetfile(&path, "*.pal", _WOPEN)

        mov esi,eax
        osread(esi, &at_foreground, COLOR)
        xchg eax,esi
        _close(eax)
        mov eax,_C_NORMAL
        .if esi == COLOR
            event_reload()
        .endif
    .endif
    ret

event_loadcolor endp

event_savecolor proc uses rbx

  local path[_MAX_PATH]:byte

    .if wgetfile(&path, "*.pal", _WSAVE)

        mov ebx,eax
        oswrite(eax, &at_foreground, COLOR)
        _close(ebx)
    .endif
    mov eax,_C_NORMAL
    ret

event_savecolor endp

ifdef __AT__

event_editat proc

    .if editattrib()
        event_reload()
    .else
        mov eax,_C_NORMAL
    .endif
    ret

event_editat endp

endif

event_standard proc

    mov rax,tdialog
    mov ax,[rax+4]
    add ax,0x0B0C
    mov rcx,IDD_DZDefaultColor
    mov [rcx+6],ax

    .if rsmodal(rcx)

        .if eax < 6

            dec eax
            lea rcx,color_Table
            mov rax,[rcx+rax*size_t]
            memcpy(addr at_foreground, rax, COLOR)
            event_reload()
        .else
            xor eax,eax
        .endif
    .else
        inc eax
    .endif
    ret

event_standard endp

    option proc: PUBLIC

cmscreen proc uses rsi rdi

    mov cf_screen_upd,0

    .if rsopen(IDD_DZScreenOptions)

        mov rdi,rax
        mov dl,_O_FLAGB
        mov eax,cflag
        .if eax & _C_MENUSLINE
            or [rdi][ID_MEUSLINE],dl
        .endif
        .if eax & _C_COMMANDLINE
            or [rdi][ID_COMMANDLINE],dl
        .endif
        .if eax & _C_STATUSLINE
            or [rdi][ID_STAUSLINE],dl
        .endif
        mov eax,console
        .if eax & CON_UDATE
            or [rdi][ID_USEDATE],dl
        .endif
        .if eax & CON_LDATE
            or [rdi][ID_USELDATE],dl
        .endif
        .if eax & CON_UTIME
            or [rdi][ID_USETIME],dl
        .endif
        .if eax & CON_LTIME
            or [rdi][ID_USELTIME],dl
        .endif
ifdef __AT__
        mov [rdi].TOBJ.tproc[ID_ATTRIB],&event_editat
else
        or  [rdi].TOBJ.flag[ID_ATTRIB],_O_STATE
endif
        mov [rdi].TOBJ.tproc[ID_STANDARD],&event_standard
        mov [rdi].TOBJ.tproc[ID_LOAD],&event_loadcolor
        mov [rdi].TOBJ.tproc[ID_SAVE],&event_savecolor
        dlinit(rdi)
        mov esi,rsevent(IDD_DZScreenOptions, rdi)
        togetbitflag([rdi].DOBJ.object, 7, _O_FLAGB)
        xchg rdi,rax
        dlclose(rax)  ; return bit-flag in DX
        mov eax,esi
        mov esi,cflag
        .if eax
            mov eax,edi
            mov edx,console
            and edx,not (CON_UTIME or CON_UDATE or CON_LTIME or CON_LDATE)

            .if al & 0x02
                or edx,CON_UDATE
            .endif
            .if al & 0x08
                or edx,CON_LDATE
            .endif
            .if al & 0x04
                or edx,CON_UTIME
            .endif
            .if al & 0x10
                or edx,CON_LTIME
            .endif
            and esi,not (_C_MENUSLINE or _C_STATUSLINE or _C_COMMANDLINE)
            .if al & 0x01
                or esi,_C_MENUSLINE
            .endif
            .if al & 0x20
                or esi,_C_COMMANDLINE
            .endif
            .if al & 0x40
                or esi,_C_STATUSLINE
            .endif
            .if console != edx
                mov console,edx
                .if cflag & _C_MENUSLINE
                    scputw(60, 0, 20, ' ')
                .endif
            .endif
            .if cflag != esi || cf_screen_upd
                mov cf_screen_upd,0
                mov cflag,esi
                .if cf_panel == 1
                    dlhide(tdialog)
                .endif
                apiupdate()
                .if cf_panel == 1
                    dlshow(tdialog)
                .endif
            .endif
        .endif
        mov eax,_C_NORMAL
    .endif
    ret
cmscreen endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cmpanel proc uses rsi rdi rbx

    .if rsopen(IDD_DZPanelOptions)

        mov rbx,rax
        mov edx,_O_FLAGB
        mov eax,cflag
        .if eax & _C_INSMOVDN
            or [rbx+1*TOBJ],dl
        .endif
        .if eax & _C_SELECTDIR
            or [rbx+2*TOBJ],dl
        .endif
        .if eax & _C_SORTDIR
            or [rbx+3*TOBJ],dl
        .endif
        .if eax & _C_CDCLRDONLY
            or [rbx+4*TOBJ],dl
        .endif
        .if eax & _C_VISUALUPDATE
            or [rbx+5*TOBJ],dl
        .endif
        dlinit(rbx)
        mov esi,rsevent(IDD_DZPanelOptions, rbx)
        mov edi,togetbitflag([rbx].DOBJ.object, 5, _O_FLAGB)
        dlclose(rbx)

        .if esi

            mov eax,edi
            and path_a.flag,not _W_SORTSUB
            and path_b.flag,not _W_SORTSUB
            mov edx,cflag
            and edx,not (_C_INSMOVDN or _C_SELECTDIR or _C_SORTDIR or _C_CDCLRDONLY or _C_VISUALUPDATE)
            .if al & 1
                or edx,_C_INSMOVDN
            .endif
            .if al & 2
                or edx,_C_SELECTDIR
            .endif
            .if al & 4
                or edx,_C_SORTDIR
                or path_a.flag,_W_SORTSUB
                or path_b.flag,_W_SORTSUB
            .endif
            .if al & 8
                or edx,_C_CDCLRDONLY
            .endif
            .if al & 16
                or edx,_C_VISUALUPDATE
            .endif
            .if cflag != edx
                mov cflag,edx
                mov byte ptr _diskflag,1
            .endif
            mov eax,1
        .endif
    .endif
    ret

cmpanel endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cmconfirm proc uses rsi rdi rbx

    .if rsopen(IDD_DZConfirmations)

        mov rbx,rax
        mov eax,config.c_cflag
        shr eax,16
        tosetbitflag([rbx].DOBJ.object, 7, _O_FLAGB, eax)
        dlinit(rbx)
        mov esi,rsevent(IDD_DZConfirmations, rbx)
        mov edi,togetbitflag([rbx].DOBJ.object, 7, _O_FLAGB)
        dlclose(rbx)

        .if esi

            mov eax,config.c_cflag
            and eax,not 0x007F0000
            shl edi,16
            or  eax,edi
            mov config.c_cflag,eax
        .endif
    .endif
    ret

cmconfirm endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cmcompression proc uses rbx

    .if rsopen(IDD_DZCompression)

        mov rbx,rax
        mov eax,compresslevel

        .if al > 9
            mov al,6
            mov compresslevel,eax
        .endif

        inc eax
        imul eax,eax,TOBJ
        or [rbx+rax].DOBJ.flag,_O_RADIO

        .if cflag & _C_ZINCSUBDIR

            or [rbx].DOBJ.flag[11*TOBJ],_O_FLAGB
        .endif

        dlinit(rbx)

        .if rsevent(IDD_DZCompression, rbx)

            mov eax,cflag
            and eax,not _C_ZINCSUBDIR
            .if [rbx].DOBJ.flag[11*TOBJ] & _O_FLAGB
                or eax,_C_ZINCSUBDIR
            .endif
            mov cflag,eax

            xor eax,eax
            mov rdx,rbx

            .repeat
                add rdx,TOBJ
                .break .if [rdx].DOBJ.flag & _O_RADIO
                inc eax
            .until eax == 10

            .if eax == 10
                mov eax,6
            .endif
            mov compresslevel,eax
        .endif
        dlclose(rbx)
    .endif
    ret

cmcompression endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cmoptions proc uses rsi rsi rbx

    mov cf_panel,1
    mov cf_panel_upd,0

    .if rsopen(IDD_DZConfiguration)

        mov rbx,rax
        mov [rbx].TOBJ.tproc[4*TOBJ],&toption
        mov [rbx].TOBJ.tproc[5*TOBJ],&cmconfirm
        mov [rbx].TOBJ.tproc[6*TOBJ],&cmcompression
        mov [rbx].TOBJ.tproc[1*TOBJ],&cmsystem
        mov [rbx].TOBJ.tproc[2*TOBJ],&cmscreen
        mov [rbx].TOBJ.tproc[3*TOBJ],&cmpanel

        .if cflag & _C_AUTOSAVE
            or byte ptr [rbx+7*TOBJ],_O_FLAGB
        .endif

        dlinit(rbx)
        mov esi,rsevent(IDD_DZConfiguration, rbx)
        mov edi,[rbx+7*TOBJ]
        dlclose(rbx)

        mov cf_panel_upd,0
        .if esi
            and cflag,not _C_AUTOSAVE
            .if edi & _O_FLAGB
                or cflag,_C_AUTOSAVE
            .endif
        .endif
        redraw_panels()
    .endif
    mov cf_panel,0
    ret
cmoptions endp

.enumt ConsoleSize:TOBJ {
    ID_ConsoleSize,
    ID_MIN_X,
    ID_MIN_Y,
    ID_MIN_COL,
    ID_MIN_ROW,
    ID_MAX_X,
    ID_MAX_Y,
    ID_MAX_COL,
    ID_MAX_ROW,
    ID_DEFAULT
    }

cmscreensize proc uses rsi rdi rbx

  local ci:CONSOLE_SCREEN_BUFFER_INFO,
    rc:RECT, maxcol, maxrow

    .repeat

        .break .if !GetConsoleScreenBufferInfo(_confh, addr ci)
         mov rcx,GetConsoleWindow()
        .break .if !GetWindowRect(rcx, addr rc)
        .break .if !rsopen(IDD_ConsoleSize)
        mov rbx,rax

        strcpy([rbx+ID_MIN_X].TOBJ.data, "0")
        strcpy([rbx+ID_MIN_Y].TOBJ.data, "0")
        strcpy([rbx+ID_MAX_X].TOBJ.data, "0")
        strcpy([rbx+ID_MAX_Y].TOBJ.data, "0")
        strcpy([rbx+ID_MIN_COL].TOBJ.data, "40")
        strcpy([rbx+ID_MIN_ROW].TOBJ.data, "16")
        movzx eax,ci.dwMaximumWindowSize.X
        sprintf([rbx+ID_MAX_COL].TOBJ.data, "%d", eax)
        movzx eax,ci.dwMaximumWindowSize.Y
        sprintf([rbx+ID_MAX_ROW].TOBJ.data, "%d", eax)

        .if CFGetSection(".consolesize")

            .for rsi=rax, edi=0: edi < 8, INIGetEntryID(rsi, edi): edi++

                lea ecx,[rdi+1]
                imul ecx,ecx,TOBJ
                strcpy([rbx+rcx].TOBJ.data, rax)
            .endf
            .if INIGetEntryID(rsi, 8)

                .if byte ptr [rax] == '1'

                    or [rbx+ID_DEFAULT].TOBJ.flag,_O_FLAGB
                .endif
            .endif
        .endif

        dlinit(rbx)
        dlshow(rbx)

        movzx esi,[rbx].DOBJ.rc.x
        movzx edi,[rbx].DOBJ.rc.y
        add esi,11
        add edi,9
        mov edx,GetLargestConsoleWindowSize(_confh)
        shr edx,16
        movzx eax,ax
        mov maxrow,edx
        mov maxcol,eax
        mov ecx,rc.top
        mov eax,rc.left
        scputf(esi, edi, 0, 0, "%d\n%d", eax, ecx)
        movzx eax,ci.dwSize.X
        movzx ecx,ci.dwSize.Y
        dec ecx
        mov _scrcol,eax
        mov _scrrow,ecx
        inc ecx
        add edi,2
        scputf(esi, edi, 0, 0, "%d\n%d", eax, ecx)
        add esi,24
        scputf(esi, edi, 0, 0, "%d\n%d", maxcol, maxrow)

        .while rsevent(IDD_ConsoleSize, rbx)

            xor esi,esi
            .if atol([rbx+ID_MIN_ROW].TOBJ.data) < MINROWS
                sprintf([rbx+ID_MIN_ROW].TOBJ.data, "%d", MINROWS)
                inc esi
            .elseif eax > MAXROWS
                sprintf([rbx+ID_MIN_ROW].TOBJ.data, "%d", MAXROWS)
                inc esi
            .endif

            .if atol([rbx+ID_MIN_COL].TOBJ.data) < MINCOLS
                sprintf([rbx+ID_MIN_COL].TOBJ.data, "%d", MINCOLS)
                inc esi
            .elseif eax > MAXCOLS
                sprintf([rbx+ID_MIN_COL].TOBJ.data, "%d", MAXCOLS)
                inc esi
            .endif

            .if atol([rbx+ID_MAX_ROW].TOBJ.data) < MINROWS
                sprintf([rbx+ID_MAX_ROW].TOBJ.data, "%d", MINROWS)
                inc esi
            .elseif eax > MAXROWS
                sprintf([rbx+ID_MAX_ROW].TOBJ.data, "%d", MAXROWS)
                inc esi
            .endif

            .if atol([rbx+ID_MAX_COL].TOBJ.data) < MINCOLS
                sprintf([rbx+ID_MAX_COL].TOBJ.data, "%d", MINCOLS)
                inc esi
            .elseif eax > MAXCOLS
                sprintf([rbx+ID_MAX_COL].TOBJ.data, "%d", MAXCOLS)
                inc esi
            .endif


            .if !esi

                .if CFAddSection(".consolesize")

                    .for rsi=rax, edi=0: edi < 8: edi++

                        lea ecx,[rdi+1]
                        imul ecx,ecx,TOBJ
                        INIAddEntryX(rsi, "%d=%s", edi, [rbx+rcx].TOBJ.data)
                    .endf
                    xor eax,eax
                    .if [rbx+ID_DEFAULT].TOBJ.flag & _O_FLAGB

                        inc eax
                    .endif
                    INIAddEntryX(rsi, "8=%d", eax)
                .endif
                mov eax,1
               .break

            .endif
            dlinit(rbx)
        .endw
        mov edi,eax
        dlclose(rbx)
        mov eax,edi
    .until 1
    ret

cmscreensize endp

    END

