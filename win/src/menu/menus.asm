; MENUS.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include io.inc
include config.inc
include time.inc
include conio.inc
include stdlib.inc
include string.inc

.enum {
    ID_MPANELA,
    ID_MFILE,
    ID_MEDIT,
    ID_MSETUP,
    ID_MTOOLS,
    ID_MHELP,
    ID_MPANELB
    }

MOBJ        STRUC
cmd         DPROC ?
name        LPSTR ?
MOBJ        ENDS
PMOBJ       typedef ptr MOBJ

.data

menus_idd       dd 0
menus_obj       dd 0
menus_xtitle    dd 11,8,8,9,9,8,11
menus_xpos      dd 0,10,17,24,32,40,47

menus_iddtable PIDD \
    IDD_DZMenuPanel,
    IDD_DZMenuFile,
    IDD_DZMenuEdit,
    IDD_DZMenuSetup,
    IDD_DZMenuTools,
    IDD_DZMenuHelp,
    IDD_DZMenuPanel

MENUS_PANELA MOBJ \
    { cmalong,      @CStr("Long/short filename") },
    { cmadetail,    @CStr("Show detail") },
    { cmawideview,  @CStr("Wide view") },
    { cmahidden,    @CStr("Show hidden files") },
    { cmamini,      @CStr("Ministatus") },
    { cmavolinfo,   @CStr("Volume information") },
    { cmaname,      @CStr("Sort current panel by Name, Type, Time, Size, or Unsorted") },
    { cmatype,      @CStr("Sort current panel by Name, Type, Time, Size, or Unsorted") },
    { cmadate,      @CStr("Sort current panel by Name, Type, Time, Size, or Unsorted") },
    { cmasize,      @CStr("Sort current panel by Name, Type, Time, Size, or Unsorted") },
    { cmanosort,    @CStr("Sort current panel by Name, Type, Time, Size, or Unsorted") },
    { cmatoggle,    @CStr("Toggle panel - on/off") },
    { cmafilter,    @CStr("Panel filter") },
    { cmasubinfo,   @CStr("Directory information") },
    { cmahistory,   @CStr("Browse history") },
    { cmaupdate,    @CStr("Re-read") },
    { cmachdrv,     @CStr("Select drive") }


MENUS_FILE MOBJ \
    { cmrename,     @CStr("Rename file or directory") },
    { cmview,       @CStr("View File or Directory information") },
    { cmedit,       @CStr("Edit") },
    { cmcopy,       @CStr("Copy") },
    { cmmove,       @CStr("Move") },
    { cmmkdir,      @CStr("Make directory") },
    { cmdelete,     @CStr("Delete") },
    { cmattrib,     @CStr("Edit file property") },
    { cmcompress,   @CStr("Compress") },
    { cmdecompress, @CStr("Decompress") },
    { cmmkzip,      @CStr("Create archive") },
    { cmsearch,     @CStr("Search") },
    { cmhistory,    @CStr("List of the last 16 DOS commands") },
    { cmsysteminfo, @CStr("Memory Information") },
    { cmexit,       @CStr("Exit program") }

MENUS_EDIT MOBJ \
    { cmselect,     @CStr("Select files") },
    { cmdeselect,   @CStr("Deselect files") },
    { cminvert,     @CStr("Invert selection") },
    { cmcompare,    @CStr("Compare directories") },
    { cmcompsub,    @CStr("Compare directories") },
    { cmmklist,     @CStr("Create List File from selection") },
    { cmenviron,    @CStr("Edit Environment") },
    { cmquicksearch,@CStr("Quick Search") },
    { cmtmodal,     @CStr("Edit") }

MENUS_SETUP MOBJ \
    { cmxormenubar, @CStr("Toggle Menus line - on/off") },
    { cmtoggleon,   @CStr("Toggle panels - on/off") },
    { cmtogglesz,   @CStr("Toggle Panels - size") },
    { cmtogglehz,   @CStr("Toggle panels - horizontal/vertical") },
    { cmxorcmdline, @CStr("Toggle Command line - on/off") },
    { cmxorkeybar,  @CStr("Toggle Status line - on/off") },
    { cmegaline,    @CStr("Toggle full screen") },
    { cmscreensize, @CStr("Set console size") },
    { cmswap,       @CStr("Swap panels") },
    { cmconfirm,    @CStr("Confirmations options") },
    { cmpanel,      @CStr("Panel options") },
    { cmcompression,@CStr("Configuration") },
    { toption,      @CStr("Configuration") },
    { cmscreen,     @CStr("Screen options") },
    { cmsystem,     @CStr("Configuration") },
    { cmoptions,    @CStr("Configuration") }

MENUS_HELP MOBJ \
    { cmhelp,       @CStr("Help") },
    { cmabout,      @CStr("About Doszip") }

MENUS_PANELB MOBJ \
    { cmblong,      @CStr("Long/short filename") },
    { cmbdetail,    @CStr("Show detail") },
    { cmbwideview,  @CStr("Wide view") },
    { cmbhidden,    @CStr("Show hidden files") },
    { cmbmini,      @CStr("Ministatus") },
    { cmbvolinfo,   @CStr("Volume information") },
    { cmbname,      @CStr("Sort current panel by Name, Type, Time, Size, or Unsorted") },
    { cmbtype,      @CStr("Sort current panel by Name, Type, Time, Size, or Unsorted") },
    { cmbdate,      @CStr("Sort current panel by Name, Type, Time, Size, or Unsorted") },
    { cmbsize,      @CStr("Sort current panel by Name, Type, Time, Size, or Unsorted") },
    { cmbnosort,    @CStr("Sort current panel by Name, Type, Time, Size, or Unsorted") },
    { cmbtoggle,    @CStr("Toggle panel - on/off") },
    { cmbfilter,    @CStr("Panel filter") },
    { cmbsubinfo,   @CStr("Directory information") },
    { cmbhistory,   @CStr("Browse history") },
    { cmbupdate,    @CStr("Re-read") },
    { cmbchdrv,     @CStr("Select drive") }

menus_oid PMOBJ \
        MENUS_PANELA,
        MENUS_FILE,
        MENUS_EDIT,
        MENUS_SETUP,
        0,
        MENUS_HELP,
        MENUS_PANELB

menus_shortkeys uint_t \
        0x1E00,    ; A Panel-A
        0x2100,    ; F File
        0x1200,    ; E Edit
        0x1F00,    ; S Setup
        0x1400,    ; T Tools
        0x2300,    ; H Help
        0x3000     ; B Panel-B

menus_TOBJ TOBJ \
        { 0x0006, 0, 0x1E, {  0, 0, 11, 1 }, @CStr("Panel-&A"), 0 },
        { 0x0006, 0, 0x21, { 10, 0, 10, 1 }, @CStr("&File"),    0 },
        { 0x0006, 0, 0x12, { 17, 0,  8, 1 }, @CStr("&Edit"),    0 },
        { 0x0006, 0, 0x1F, { 24, 0, 10, 1 }, @CStr("&Setup"),   0 },
        { 0x0006, 0, 0x14, { 32, 0,  9, 1 }, @CStr("&Tools"),   0 },
        { 0x0006, 0, 0x23, { 40, 0,  8, 1 }, @CStr("&Help"),    0 },
        { 0x0006, 0, 0x30, { 47, 0, 11, 1 }, @CStr("Panel-&B"), 0 }

DLG_Menusline   PDOBJ NULL
DLG_Statusline  PDOBJ NULL
DLG_Commandline PDOBJ NULL

dlgcursor       CURSOR <0,0,0,0>
dlgflags        db 5 dup(0)

    .code

apiidle proc

    .if cflag & _C_MENUSLINE

        tupdtime()
    .endif
    xor eax,eax
    ret

apiidle endp

apiopen proc

    ConsolePush()
    oswrite(1, "\r\n", 2)
    mov DLG_Commandline,rsopen(IDD_Commandline)
    mov DLG_Menusline,rsopen(IDD_Menusline)
    mov DLG_Statusline,rsopen(IDD_Statusline)

    movzx eax,console_cu.y
    mov com_info.ypos,eax
    mov eax,_scrrow
    mov rcx,DLG_Statusline
    mov [rcx].DOBJ.rc.y,al
    .if cflag & _C_STATUSLINE
        dec al
    .endif
    mov edx,com_info.ypos
    .if dl < al
        mov al,dl
    .endif
    mov edx,_scrcol
    mov rcx,DLG_Commandline
    mov [rcx].DOBJ.rc.y,al
    mov [rcx].DOBJ.rc.col,dl
    mov com_info.ypos,eax
    mov rcx,DLG_Statusline
    mov [rcx].DOBJ.rc.col,dl
    mov rcx,DLG_Menusline
    mov [rcx].DOBJ.rc.col,dl

    .if cflag & _C_MENUSLINE
        dlshow(DLG_Menusline)
        tupdtime()
    .endif
    .if cflag & _C_STATUSLINE
        dlshow(DLG_Statusline)
    .endif
    comshow()
    ret

apiopen endp

apiclose proc

    dlclose(DLG_Menusline)
    dlclose(DLG_Commandline)
    dlclose(DLG_Statusline)
    ret

apiclose endp

apiupdate proc

    comhide()
    doszip_hide()
    mov time_id,61
    doszip_show()
    ret

apiupdate endp


apiega proc

    and cflag,not _C_EGALINE
    mov eax,_scrcol
    mov edx,_scrrow
    inc edx
    .if dx >= _scrmax.Y && ax >= _scrmax.X

        or cflag,_C_EGALINE
    .endif
    ret

apiega endp

UpdateWindowSize proc uses rsi rdi size:COORD

    movzx esi,size.X
    movzx edi,size.Y
    dec edi

    .if ( edi != _scrrow || esi != _scrcol )

        comhide()
        doszip_hide()
        mov _scrrow,edi
        mov _scrcol,esi
        doszip_show()
        apiega()
    .endif
    ret

UpdateWindowSize endp


apimode proc

    mov eax,_scrmin
    .if cflag & _C_EGALINE
        mov eax,_scrmax
    .endif
    conssetl(eax)
    apiega()
    ret

apimode endp


open_idd proc private uses rsi rdi rbx id:int_t, lpMTitle:ptr

    mov time_id,61
    lea rcx,menus_iddtable
    mov eax,id
    mov rax,[rcx+rax*PIDD]
    mov rax,[rax]

    .if rsopen(rax)

        mov rbx,rax
        .if ( cflag & _C_MENUSLINE )

            mov eax,id
            lea rcx,menus_xtitle
            lea rdx,menus_xpos
            mov esi,[rcx+rax*4]
            mov edi,[rdx+rax*4]
            scgetws(edi, 0, esi)
            mov rcx,lpMTitle
            mov [rcx],rax
            movzx eax,at_foreground[F_MenusKey]
            scputa(edi, 0, esi, eax)
        .endif
        mov rax,rbx
    .endif
    ret

open_idd endp


close_idd proc private id:uint_t, wpMenusTitle:ptr

    .if ( cflag & _C_MENUSLINE )

        mov eax,id
        lea rdx,menus_xtitle
        lea rcx,menus_xpos
        mov edx,[rdx+rax*4]
        mov ecx,[rcx+rax*4]
        scputws(ecx, 0, edx, wpMenusTitle)
    .endif
    ret

close_idd endp


modal_idd proc private uses rsi rdi rbx index:int_t, stInfo:ptr, dialog:PDOBJ, wpMenusTitle:ptr

  local stBuffer[MAXCOLS]:CHAR_INFO

    lea rsi,stBuffer
    mov rdi,dialog
    wcpushst(rsi, stInfo)
    dlinit(rdi)
    dlshow(rdi)
    msloop()
    mov ebx,dlevent(rdi)

    movzx eax,[rdi].DOBJ.index
    imul  eax,eax,TOBJ
    add   rax,[rdi].DOBJ.object
    movzx edi,[rax].TOBJ.flag
    and   edi,_O_STATE or _O_FLAGB

    wcpopst(rsi)
    close_idd(index, wpMenusTitle)
    mov edx,edi
    mov eax,ebx
    ret

modal_idd endp


readtools proc private uses rsi rdi rbx section:LPSTR, dialog:PDOBJ, index:int_t, lsize:int_t

  local handle:ptr, p:ptr, buffer[512]:char_t, col:int_t

    mov rax,dialog
    mov rbx,[rax].DOBJ.object
    mov edi,index

    .if CFGetSection(section)

        mov handle,rax

        .while INIGetEntryID(handle, edi)

            lea rsi,buffer
            strcpy(rsi, rax)

            mov rsi,strstart(rsi)
            mov p,rsi
            mov ecx,36

            .repeat

                lodsb
                .switch al

                  .case ','

                    mov byte ptr [rsi-1],0  ; terminate text line
                    mov rsi,strstart(rsi)   ; start of command tail
                    mov ecx,lsize
                    mov rdx,[rbx].TOBJ.data
                    xchg rdi,rdx
                    xor eax,eax

                    .while ecx

                        lodsb
                        .break .if !al
                        .break .if al == ']'
                        .if al == '['
                            mov ah,al
                           .continue
                        .endif
                        stosb
                        dec ecx
                    .endw

                    mov ecx,1
                    mov al,0
                    stosb
                    mov rdi,rdx
                   .endc .if !ah

                    or [rbx].TOBJ.flag,_O_FLAGB
                   .endc

                  .case '<'
                    mov ecx,1
                   .endc

                  .case 0
                   error:
                    CFError(section, p)
                    xor edi,edi
                   .break( 1 )
                .endsw
            .untilcxz

            mov rcx,dialog
            mov eax,edi
            mul [rcx].DOBJ.rc.col
            movzx edx,[rcx].DOBJ.rc.col
            mov col,edx
            add eax,edx
            inc eax
            mov rsi,p
            mov rdx,[rcx].DOBJ.wp
            lea rcx,[rdx+rax*4]

            .if byte ptr [rsi] == '<'

                wcputw(rcx, col, U_LIGHT_HORIZONTAL)
                and [rbx].TOBJ.flag,not _O_FLAGB

            .else

                add rcx,2*4
                wcputs(rcx, 0, 32, rsi)
                mov eax,not _O_STATE
                and [rbx].TOBJ.flag,ax

                .if strchr(rsi, '&')

                    mov al,[rax+1]
                    mov [rbx].TOBJ.ascii,al
                .endif
            .endif

            add rbx,TOBJ
            inc edi
            .break .if edi >= 20
        .endw
    .endif
    mov eax,edi
    ret

readtools endp


tools_idd proc uses rsi rdi rbx lsize:int_t, p:LPSTR, section:LPSTR

  local mtitle:ptr, tbuf[256]:byte

    .while 1

        xor esi,esi
        .break .if !open_idd(ID_MTOOLS, &mtitle)

        mov rbx,rax
        .if !readtools(section, rax, esi, lsize)

            close_idd(ID_MTOOLS, mtitle)
            dlclose(rbx)
           .break
        .endif

        mov [rbx].DOBJ.count,al
        add al,2
        mov [rbx].DOBJ.rc.row,al
        mov ah,al
        mov al,[rbx].DOBJ.rc.col
        movzx edx,al
        shl eax,16

        rcframe(eax, [rbx].DOBJ.wp, edx, BOX_SINGLE)
        strnzcpy(&tbuf, section, 16)
        modal_idd(ID_MTOOLS, rax, rbx, mtitle)

        mov esi,eax ; dlevent() | key (Left/Right)
        mov edi,edx ; flag _O_STATE or _O_FLAGB
        movzx edx,[rbx].DOBJ.count

        .if ( eax && edx >= eax )

            imul eax,eax,TOBJ
            lea rdx,[rbx+rax]
            strnzcpy(&tbuf, [rdx].TOBJ.data, lsize)
        .endif

        mov rcx,rbx
        movzx ebx,[rbx].DOBJ.count
        dlclose(rcx)

        .if ( esi && ebx >= esi )

            lea rax,tbuf
            mov rcx,p
            .if ( edi == _O_FLAGB )

                mov section,rax
               .continue
            .endif
            .if rcx

                strcpy(rcx, rax)
                msloop()
               .break
            .endif
            mov esi,command(rax)
        .endif

        .if mousep()
            mov esi,MOUSECMD
        .endif
        .break
    .endw
    mov eax,esi
    ret

tools_idd endp


cmtool proc private i:int_t

  local tool[128]:char_t

    .if CFGetSectionID("Tools", i)

        mov rcx,rax
        mov eax,[rax]

        .if ( ax != '><' )

            .if strchr(rcx, ',')

                inc rax
                strstart(rax)
                mov rdx,rax
                strnzcpy(&tool, rdx, 128-1)

                .if ( tool != '[' )

                    command(rax)
                .else

                    lea rcx,[rax+1]
                    .if strchr(strcpy(rax, rcx), ']')

                        mov byte ptr [rax],0
                        tools_idd(128, 0, &tool)
                    .endif
                .endif
            .endif
        .endif
    .endif
    ret

cmtool endp

cmtool1 proc
    cmtool(0)
    ret
cmtool1 endp

cmtool2 proc
    cmtool(1)
    ret
cmtool2 endp

cmtool3 proc
    cmtool(2)
    ret
cmtool3 endp

cmtool4 proc
    cmtool(3)
    ret
cmtool4 endp

cmtool5 proc
    cmtool(4)
    ret
cmtool5 endp

cmtool6 proc
    cmtool(5)
    ret
cmtool6 endp

cmtool7 proc
    cmtool(6)
    ret
cmtool7 endp

cmtool8 proc
    cmtool(7)
    ret
cmtool8 endp

cmtool9 proc
    cmtool(8)
    ret
cmtool9 endp


menus_modalidd proc private uses rsi rdi rbx id:int_t

  local object:PTOBJ, mtitle:LPSTR, dialog:PDOBJ

    xor esi,esi
    .if ( id == ID_MTOOLS )

        mov esi,tools_idd(128, 0, "Tools")

    .else

        mov rax,IDD_DZMenuPanel
        mov [rax].RIDD.rc.x,0
        .if ( id == ID_MPANELB )
            mov [rax].RIDD.rc.x,42
        .endif

        .if open_idd(id, &mtitle)

            mov     dialog,rax
            mov     rbx,rax
            add     rax,DOBJ
            mov     object,rax
            movzx   ecx,[rbx].DOBJ.count
            add     rbx,TOBJ.data[TOBJ]
            mov     edx,id
            lea     rax,menus_oid
            mov     rdx,[rax+rdx*PMOBJ]

            .while ecx

                mov rax,[rdx].MOBJ.name
                mov [rbx],rax
                add rbx,TOBJ
                add rdx,MOBJ
                dec ecx
            .endw

            mov eax,id
            xor edx,edx
            .if !eax
                mov edx,config.c_apath.flag
            .elseif eax == ID_MPANELB
                mov edx,config.c_bpath.flag
            .endif

            .if edx

                mov rbx,object
                mov eax,_O_FLAGB
                mov ecx,_W_LONGNAME

                push 0
                push _W_DRVINFO
                push _W_MINISTATUS
                push _W_HIDDEN
                push _W_WIDEVIEW
                push _W_DETAIL

                .while ecx
                    .if edx & ecx
                        or [rbx].TOBJ.flag,ax
                    .endif
                    add rbx,TOBJ
                    pop rcx
                .endw

                mov eax,_O_RADIO
                and edx,_W_SORTSIZE or _W_NOSORT
                .switch edx
                  .case _W_SORTNAME
                    or [rbx+0*TOBJ].TOBJ.flag,ax
                    .endc
                  .case _W_SORTTYPE
                    or [rbx+1*TOBJ].TOBJ.flag,ax
                    .endc
                  .case _W_SORTDATE
                    or [rbx+2*TOBJ].TOBJ.flag,ax
                    .endc
                  .case _W_SORTSIZE
                    or [rbx+3*TOBJ].TOBJ.flag,ax
                    .endc
                  .default
                    or [rbx+4*TOBJ].TOBJ.flag,ax
                .endsw
            .endif

            lea  rdx,menus_TOBJ
            mov  eax,id
            imul eax,eax,TOBJ
            add  rdx,rax

            mov esi,modal_idd(id, [rdx].TOBJ.data, dialog, mtitle)
            mov edi,edx
            mov rax,dialog
            movzx ebx,[rax].DOBJ.count

            dlclose(dialog)

            .if esi && ebx >= esi

                mov edx,id
                mov menus_idd,edx
                mov eax,esi
                dec eax
                mov menus_obj,eax
                .if !( edi & _O_STATE )

                    lea rcx,menus_oid
                    mov rdx,[rcx+rdx*PMOBJ]
                    imul eax,eax,MOBJ
                    [rdx+rax].MOBJ.cmd()
                .endif
            .endif

            .if mousep()
                mov esi,MOUSECMD
            .endif
        .endif
    .endif
    .return(esi)

menus_modalidd endp


menus_event proc private uses rsi rdi rbx id:uint_t, key:uint_t

    mov edi,key
    mov esi,1

    .while  1

        .switch edi
        .case MOUSECMD
            xor edi,edi
            xor esi,esi
           .endc
        .case KEY_LEFT
        .case KEY_RIGHT
            mov eax,edi
           .break .if !esi

            mov eax,id
            .if edi == KEY_RIGHT

                inc eax
                .if eax > ID_MPANELB

                    xor eax,eax
                .endif
            .else
                dec eax
                .if eax == -1

                    mov eax,ID_MPANELB
                .endif
            .endif
            mov id,eax
            menus_modalidd(eax)
            mov edi,eax
           .endc
        .case KEY_ESC
            mov eax,edi
           .break .if !esi
            xor eax,eax
           .break
        .default
            .if esi
                msloop()
               .break
            .endif
            .endc .if !edi
            .for ( rcx = &menus_shortkeys, ebx = 0 : ebx < 7 : ebx++ )

                .if ( edi == [rcx+rbx*4] )

                    mov id,ebx
                    menus_modalidd(ebx)
                    mov edi,eax
                    mov esi,1
                   .break
                .endif
            .endf
            mov eax,edi
           .break .if !esi
        .endsw

        .if ( esi == 0 )

            mov edi,tgetevent()
            .if eax == MOUSECMD
                xor edi,edi
            .endif
        .endif

        .if ( cflag & _C_MENUSLINE && !keybmouse_y && !edi )

            .if mousep()

                mov eax,keybmouse_x
                mov edx,eax
                mov ecx,ID_MPANELB

                .if eax >= 57

                    mov eax,MOUSECMD
                   .break
                .endif

                lea rdi,menus_TOBJ
                .repeat
                    imul ebx,ecx,TOBJ
                    dec ecx
                    add rbx,rdi
                .until al >= [rbx+4]

                mov ah,[rbx].TOBJ.ascii
                mov al,0
                mov edi,eax
                inc ecx
                mov id,ecx
               .continue
            .endif
        .endif
        mov eax,MOUSECMD
       .break .if !edi
    .endw
    ret

menus_event endp


menus_getevent proc

    menus_event(0, MOUSECMD)
    ret

menus_getevent endp


cmlastmenu proc uses rbx

    mov eax,menus_obj
    mov ebx,menus_idd
    lea rcx,menus_iddtable
    mov rcx,[rcx+rbx*PIDD]
    mov [rcx].RIDD.index,al
    menus_event(ebx, menus_modalidd(ebx))
    ret

cmlastmenu endp

    end
