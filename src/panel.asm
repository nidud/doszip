; PANEL.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include dzstr.inc
include malloc.inc
include io.inc
include errno.inc
include stdlib.inc
include process.inc
include time.inc
include config.inc
include progress.inc

    .data

pcellwb     dd 256 dup(0x00070020)
pcell_a     XCEL <_D_BACKG or _D_MYBUF,1,1,<2,2,12,1>,pcellwb,<2,2,12,1>>
pcell_b     XCEL <_D_BACKG or _D_MYBUF,1,1,<2,2,12,1>,pcellwb,<2,2,12,1>>
prect_a     DOBJ <_D_CLEAR or _D_COLOR,0,0,<0,1,40,20>,0,0>
prect_b     DOBJ <_D_CLEAR or _D_COLOR,0,0,<40,1,40,20>,0,0>
spanela     PANEL <path_a,0,0,0,0,pcell_a,prect_a,0>
spanelb     PANEL <path_b,0,0,0,0,pcell_b,prect_b,0>

cp_disk     db "C:\",0
cp_warning  sbyte "Warning",0

CALLBACKC(FBPUT, :PFBLK, :PCHAR_INFO, :UINT)

S_PRECT     STRUC
p_name      dd ?
p_type      dd ?    ; 0+Name,1+Size,2+Date,3+Time
p_putfile   FBPUT ?
p_rect      TRECT <>
S_PRECT     ENDS

align size_t
PTABLE S_PRECT \
    < 0,0,fbputsl,<1,2,12,1>>, ; Vertical Short List
    <26,3,fbputsd,<1,2,38,1>>, ; Vertical Short Detail
    < 0,0,fbputsl,<1,2,12,1>>, ; Horizontal Short List
    <26,3,fbputld,<1,2,78,1>>, ; Horizontal Short Detail
    < 0,0,fbputll,<1,2,18,1>>, ; Vertical Long List
    <16,2,fbputld,<1,2,38,1>>, ; Vertical Long Detail
    < 0,0,fbputll,<1,2,18,1>>, ; Horizontal Long List
    <26,3,fbputld,<1,2,78,1>>, ; Horizontal Long Detail
    < 0,0,fbputll,<1,2,38,1>>, ; Vertical Wide
    < 0,0,fbputll,<1,2,78,1>>  ; Horizontal Wide

    .code

prect_open proc private uses rsi rdi rbx panel:LPPANEL

  local rect:   TRECT,
        xcell:  ptr,
        xlrc:   TRECT,
        prect:  TRECT,
        dlwp:   PCHAR_INFO,
        col:    uint_t,
        type:   uint_t,
        flag:   uint_t

    ldr rsi,panel
    comhide()

    mov rdi,[rsi].PANEL.wsub
    mov edi,[rdi].WSUB.flag
    mov flag,edi
    xor edx,edx     ; x,y
    mov eax,_scrcol     ; cols
    shr eax,1
    mov ah,byte ptr _scrrow ; rows
    mov ecx,cflag
    mov bh,9        ; panel size (rows)

    .if !(ecx & _C_COMMANDLINE)

        inc ah      ; rows++
    .endif
    .if ecx & _C_MENUSLINE

        inc dh      ; y++
        dec ah      ; rows--
    .endif
    .if ecx & _C_STATUSLINE

        dec ah      ; rows--
    .endif
    .if ecx & _C_HORIZONTAL && !(ecx & _C_WIDEVIEW)

        shr ah,1    ; rows / 2
        dec bh
    .endif
    mov bl,ah
    sub bl,bh       ; rows - bh (size)
    .if bl < byte ptr config.c_panelsize

        mov byte ptr config.c_panelsize,bl
    .endif

    sub ah,byte ptr config.c_panelsize
    .if ecx & _C_HORIZONTAL

        mov al,byte ptr _scrcol ; cols = 80
        .if edi & _W_PANELID && !(ecx & _C_WIDEVIEW)

            add dh,ah   ; y += rows
        .endif
    .elseif edi & _W_PANELID && !(ecx & _C_WIDEVIEW)

        mov dl,byte ptr _scrcol ; x = 40
        shr dl,1
    .endif

    mov word ptr rect,dx
    mov word ptr rect+2,ax
    xor ebx,ebx

    .if ecx & _C_HORIZONTAL
        mov bl,2
    .endif
    .if edi & _W_DETAIL
        inc bl
    .endif
    .if edi & _W_LONGNAME
        add bl,4
    .endif
    .if edi & _W_WIDEVIEW
        mov bl,8
        .if ecx & _C_HORIZONTAL
            inc bl
        .endif
    .endif

    push    rax
    lea     rax,PTABLE
    imul    ebx,ebx,S_PRECT
    add     rbx,rax
    mov     xcell,rbx
    mov     dl,[rbx].S_PRECT.p_rect.col
    mov     eax,[rbx].S_PRECT.p_rect
    mov     prect,eax
    mov     eax,_scrcol

    .if dl != 78
        shr eax,1
        .if dl != 38
            .if dl == 18
                shr eax,1
            .else
                mov eax,14
            .endif
        .endif
    .endif
    sub     eax,2
    pop     rcx

    mov     prect.col,al

    mov     eax,prect
    add     ax,word ptr rect
    mov     xlrc,eax

    mov     rbx,[rsi].PANEL.xl
    mov     [rbx].XCEL.cpos,eax
    sub     ch,3
    mov     [rbx].XCEL.rows,ch

    movzx   eax,cl
    dec     al
    mov     cl,xlrc.col
    inc     cl
    div     cl
    mov     [rbx].XCEL.cols,al
    mov     rbx,[rsi].PANEL.dialog

    .if ( [rbx].DOBJ.flag & _D_DOPEN )

        dlclose([rsi].PANEL.xl)
        dlclose(rbx)
    .endif

    mov     eax,rect
    mov     [rbx].DOBJ.rc,eax
    movzx   eax,at_background[B_Panel]
    or      al,at_foreground[F_Frame]

    .if dlopen(rbx, eax, 0)

        xor     eax,eax
        mov     word ptr rect,ax

        mov     rdx,[rsi].PANEL.dialog
        mov     rcx,[rdx].DOBJ.wp
        mov     dlwp,rcx
        movzx   edx,rect.col
        lea     rcx,[rcx+rdx*4]
        movzx   eax,at_background[B_Panel]
        or      al,at_foreground[F_Panel]
        shl     eax,16
        mov     al,' '

        wcputw(rcx, edx, eax)

        .if ( edi & _W_MINISTATUS )

            mov     al,2
            sub     rect.row,al
            mov     rdx,[rsi].PANEL.xl
            sub     [rdx].XCEL.rows,al

            .if ( edi & _W_DRVINFO )

                sub rect.row,al
                sub [rdx].XCEL.rows,al

                .if !( cflag & _C_HORIZONTAL )

                    dec rect.row
                    dec [rdx].XCEL.rows
                .endif
            .endif
            mov     eax,BOX_SINGLE
            mov     ah,at_background[B_Panel]
            or      ah,at_foreground[F_Frame]
            movzx   edx,rect.col

            rcframe(rect, dlwp, edx, eax)
        .endif

        mov     rbx,xcell
        mov     rax,[rbx].S_PRECT.p_putfile
        mov     [rsi].PANEL.putfcb,rax

        mov     xlrc,rect
        mov     al,prect.col
        add     al,2
        mov     xlrc.col,al
        mov     edx,BOX_SINGLE_VERTICAL
        mov     dh,at_background[B_Panel]
        or      dh,at_foreground[F_Frame]
        movzx   ecx,rect.col
        mov     col,ecx
        mov     type,edx
        lea     edi,[rcx*4]
        add     rdi,dlwp
        movzx   eax,prect.col
        lea     esi,[rax*4+4]
        shr     eax,1
        sub     eax,1

        .switch [rbx].S_PRECT.p_type

          .case 0
            lea rdi,[rdi+rax*4]
            .repeat

                wcputs(rdi, col, "Name")
                add rdi,rsi

                rcframe(xlrc, dlwp, col, type)

                movzx   eax,prect.col
                inc     eax
                movzx   ebx,xlrc.x
                add     ebx,eax
                .break .if bh

                add     xlrc.x,al
                add     eax,ebx
                .break .if ah

                movzx   ebx,xlrc.col
                add     eax,ebx
                .break .if ah

            .until al > rect.col

            mov al,prect.col
            add al,2
            .if al != rect.col
                wcputs(rdi, col, "Name")
            .endif
            .endc

          .case 2
            sub eax,[rbx].S_PRECT.p_name
            lea rax,[rdi+rax*4]
            wcputs(rax, col, "Name")
            mov ecx,col
            lea rax,[rdi+rcx*4-(7*4)]
            wcputs(rax, ecx, "Date")
            mov ecx,col
            lea rax,[rdi+rcx*4-(17*4)]
            wcputs(rax, ecx, "Size")
            sub xlrc.col,9
            rcframe(xlrc, dlwp, col, type)
            sub xlrc.col,11
            rcframe(xlrc, dlwp, col, type)
            .endc
          .case 3
            sub eax,[rbx].S_PRECT.p_name
            lea rax,[rdi+rax*4]
            wcputs(rax, col, "Name")
            mov ecx,col
            lea rax,[rdi+rcx*4-(5*4)]
            wcputs(rax, ecx, "Time")
            mov ecx,col
            lea rax,[rdi+rcx*4-(13*4)]
            wcputs(rax, ecx, "Date")
            mov ecx,col
            lea rax,[rdi+rcx*4-(23*4)]
            wcputs(rax, ecx, "Size")
            sub xlrc.col,6
            rcframe(xlrc, dlwp, col, type)
            sub xlrc.col,9
            rcframe(xlrc, dlwp, col, type)
            sub xlrc.col,11
            rcframe(xlrc, dlwp, col, type)
        .endsw

        mov edi,flag
        mov rbx,dlwp
        xor eax,eax
        xor edx,edx
        mov al,rect.col
        add al,2
        lea rax,[rbx+rax*4]
        mov word ptr [rax],':'
        mov word ptr [rax+4],0x2193

        mov rax,panel
        mov rcx,[rax].PANEL.dialog
        mov dl,[rcx].DOBJ.rc.col
        mov ecx,[rcx].DOBJ.rc
        xor cx,cx
        mov eax,BOX_DOUBLE
        mov ah,at_background[B_Panel]
        or  ah,at_foreground[F_Frame]
        rcframe(ecx, rbx, edx, eax)
        xor eax,eax
        mov al,rect.row
        mov ah,rect.col

        .if !( edi & _W_MINISTATUS )
            mul ah
            mov word ptr [rbx+rax*4-(3*4)],U_UP_TRIANGLE
        .else
            dec al
            mul ah
            .if edi & _W_DRVINFO
                mov word ptr [rbx+rax*4+(2*4)],U_DOWN_TRIANGLE
            .else
                mov word ptr [rbx+rax*4+(2*4)],U_BULLET_OPERATOR
                movzx edx,rect.col
                add eax,edx
                mov word ptr [rbx+rax*4-(3*4)],U_DOWN_TRIANGLE
            .endif
        .endif

        mov rsi,panel
        mov eax,cflag
        and eax,_C_WIDEVIEW
        .if ZERO? || rsi == cpanel
            dlshow([rsi].PANEL.dialog)
            or  edi,_W_VISIBLE
            and edi,not _W_WHIDDEN
        .else
            or edi,_W_WHIDDEN
        .endif
        mov rdx,[rsi].PANEL.wsub
        mov [rdx].WSUB.flag,edi
    .endif

    mov col,eax
    comshow()
    mov eax,col
    ret

prect_open endp


prect_hide proc uses rbx panel:PPANEL

    ldr rbx,panel
    mov rdx,[rbx].PANEL.wsub
    mov eax,[rdx].WSUB.flag

    .if eax & _W_WHIDDEN

        xor eax,_W_WHIDDEN
        mov [rdx].WSUB.flag,eax
        mov eax,1

    .elseif eax & _W_VISIBLE

        xor eax,_W_VISIBLE
        mov [rdx].WSUB.flag,eax
        dlclose([rbx].PANEL.xl)
        dlhide([rbx].PANEL.dialog)
        mov eax,1
    .else
        xor eax,eax
    .endif
    ret

prect_hide endp


prect_close proc fastcall private uses rbx panel:PPANEL

    mov rax,[rcx].PANEL.wsub
    mov eax,[rax].WSUB.flag
    and eax,_W_VISIBLE
    .ifnz
        mov rbx,rcx
        prect_hide(rcx)
        dlclose([rbx].PANEL.dialog)
        mov eax,1
    .endif
    ret

prect_close endp


prect_open_ab proc

    mov eax,cflag
    and eax,_C_PANELID
    lea rax,spanela
    .ifnz
        lea rax,spanelb
    .endif
    mov cpanel,rax

    xor eax,eax
    .if flaga & _W_VISIBLE
        prect_open(&spanela)
    .endif
    .if flagb & _W_VISIBLE
        prect_open(&spanelb)
    .endif
    ret

prect_open_ab endp


panel_getb proc

    mov rax,panela
    .if rax == cpanel
        mov rax,panelb
    .endif
    ret

panel_getb endp


panel_state proc fastcall panel:PPANEL

    mov rax,[rcx].PANEL.dialog
    mov rax,[rax].DOBJ.wp
    .if rax
        mov rax,[rcx].PANEL.wsub
        mov rax,[rax].WSUB.fcb
        .if rax
            mov rax,rcx
        .endif
    .endif
    ret

panel_state endp


cpanel_state proc

    panel_state(cpanel)
    ret

cpanel_state endp


panel_stateab proc

    .ifd panel_state(panela)
        panel_state(panelb)
    .endif
    ret

panel_stateab endp


panel_curobj proc fastcall panel:PPANEL

    mov rax,[rcx].PANEL.wsub
    .if rax

        mov eax,[rcx].PANEL.fcb_index
        add eax,[rcx].PANEL.cel_index

        .if wsfblk([rcx].PANEL.wsub, eax)

            mov rdx,rax
            mov rax,[rax].FBLK.name
        .endif
    .endif
    ret

panel_curobj endp


panel_findnext proc fastcall panel:PPANEL

    .if wsffirst([rcx].PANEL.wsub)

        mov rdx,rax
        mov rax,[rax].FBLK.name
    .endif
    ret

panel_findnext endp


cpanel_findfirst proc

    .ifd panel_state(cpanel)
        .if !panel_findnext(rax)
            panel_curobj(cpanel)
        .endif
        .if rax && ecx & _FB_UPDIR
            xor eax,eax
        .endif
    .endif
    ret

cpanel_findfirst endp


cpanel_gettarget proc

    .ifd panel_stateab()

        mov rax,path_a.path
        mov rcx,cpanel
        .if rcx == panela
            mov rax,path_b.path
        .endif
    .endif
    ret

cpanel_gettarget endp


panel_hide proc uses rbx panel:PPANEL

    ldr rbx,panel
    prect_close(rbx)
    wsfree([rbx].PANEL.wsub)
    mov rax,rbx
    ret

panel_hide endp


panel_show proc fastcall panel:PPANEL

    mov rdx,[rcx].PANEL.wsub
    or  [rdx].WSUB.flag,_W_VISIBLE
    panel_update(rcx)
    ret

panel_show endp


panel_selected proc fastcall private uses rsi panel:PPANEL

    xor eax,eax
    .for edx = [rcx].PANEL.fcb_count,
         rcx = [rcx].PANEL.wsub,
         rsi = [rcx].WSUB.fcb : rsi && rdx : rsi+=size_t, edx--

        mov rcx,[rsi]
        .if [rcx].FBLK.flag & _FB_SELECTED
            inc eax
        .endif
    .endf
    ret

panel_selected endp


pcell_set proc private uses rsi rdi rbx panel:PPANEL

    mov     rsi,panel
    mov     rdi,[rsi].PANEL.xl
    movzx   eax,[rdi].XCEL.cols
    movzx   edx,[rdi].XCEL.rows
    mul     edx
    mov     edx,[rsi].PANEL.fcb_count
    sub     edx,[rsi].PANEL.fcb_index

    .if eax >= edx
        mov eax,edx
    .endif

    mov [rsi].PANEL.cel_count,eax
    mov edx,[rsi].PANEL.cel_index
    .if edx < eax
        mov eax,edx
    .else
        dec eax
    .endif

    mov     [rsi].PANEL.cel_index,eax
    sub     edx,edx
    movzx   ebx,[rdi].XCEL.rows
    div     ebx
    mov     ecx,eax
    mul     ebx
    mov     ebx,[rsi].PANEL.cel_index
    sub     ebx,eax
    movzx   eax,[rdi].XCEL.cpos.col
    inc     eax
    mul     ecx
    mov     ecx,eax
    mov     eax,[rdi].XCEL.cpos
    add     al,cl
    add     ah,bl
    mov     [rdi].XCEL.rc,eax
    mov     eax,[rsi].PANEL.cel_index
    ret

pcell_set endp


panel_setid proc panel:PPANEL, index:UINT

    mov rdx,panel
    xor eax,eax
    mov [rdx].PANEL.cel_index,eax
    mov [rdx].PANEL.fcb_index,eax
    pcell_set(rdx)

    mov eax,index
    mov rdx,panel

    .if eax < [rdx].PANEL.cel_count

        mov [rdx].PANEL.cel_index,eax
    .else
        sub eax,[rdx].PANEL.cel_count
        inc eax
        mov [rdx].PANEL.fcb_index,eax
        mov eax,[rdx].PANEL.cel_count
        dec eax
        mov [rdx].PANEL.cel_index,eax
    .endif
    ret

panel_setid endp


pcell_open proc fastcall private panel:PPANEL

    dlopen([rcx].PANEL.xl, at_background[B_InvPanel], 0)
    ret

pcell_open endp


pcell_show proc uses rsi rdi panel:PPANEL

    ldr rsi,panel
    mov rdi,[rsi].PANEL.xl
    xor eax,eax
    .if !( [rdi].XCEL.flag & _D_DOPEN or _D_ONSCR )

        pcell_set(rsi)
        xor eax,eax
        .if ( [rsi].PANEL.cel_count != eax )

            pcell_open(rsi)
            dlshow(rdi)
            mov eax,1
        .endif
    .endif
    ret

pcell_show endp

panel_putinfo proc private uses rsi rdi rbx panel:PPANEL

   .new x:int_t, y:int_t, col:int_t, len:int_t
   .new path[WMAXPATH]:char_t

    .ifd panel_state(panel)

        mov rdi,rax
        mov rbx,[rdi].PANEL.dialog

        .if ( [rbx].DOBJ.flag & _D_ONSCR )

            mov rsi,[rdi].PANEL.wsub
            strcpy(&path, [rsi].WSUB.path)
            .if ( [rsi].WSUB.flag & _W_ARCHIVE or _W_ROOTDIR )
                strfcat(rax, [rsi].WSUB.file, [rsi].WSUB.arch)
            .endif
            mov len,strlen(rax)

            movzx   eax,[rbx].DOBJ.rc.x
            movzx   edx,[rbx].DOBJ.rc.y
            movzx   ecx,[rbx].DOBJ.rc.col
            inc     eax
            sub     ecx,2
            mov     x,eax
            mov     y,edx
            mov     col,ecx

            mov     rsi,[rsi].WSUB.path
            movzx   eax,at_background[B_Panel]
            or      al,at_foreground[F_Panel]
            shl     eax,16
            mov     al,[rsi]
            mov     edx,y
            inc     edx
            scputw( x, edx, 1, eax )

            movzx   eax,at_background[B_Panel]
            or      al,at_foreground[F_Frame]
            shl     eax,16
            mov     ax,U_DOUBLE_HORIZONTAL
            scputw( x, y, col, eax )

            movzx ebx,at_background[B_Panel]
            .if ( rdi == cpanel )
                mov bl,at_background[B_InvPanel]
            .endif
            or  bl,at_foreground[F_Frame]
            shl ebx,16

            .if ( len > col )

                mov bl,' '
                scputw( x, y, col, ebx )
                inc x
                sub col,2
                scpath(x, y, col, &path)

            .else

                mov ecx,col
                sub ecx,len
                shr ecx,1
                dec ecx
                add ecx,x
                shr ebx,16
                scputf(ecx, y, ebx, 0, " %s ", &path)
            .endif
        .endif
    .endif
    ret

panel_putinfo endp


panel_setactive proc uses rsi rdi panel:PPANEL

    ldr rsi,panel
    mov rdi,cpanel
    and cflag,not _C_PANELID

    mov rax,[rsi].PANEL.wsub
    .if [rax].WSUB.flag & _W_PANELID

        or cflag,_C_PANELID
    .endif

    cominit([rsi].PANEL.wsub)
    dlclose([rdi].PANEL.xl)

    mov cpanel,rsi
    panel_putinfo(rdi)
    .if cflag & _C_WIDEVIEW

        .if rsi != rdi

            .ifd panel_state(rsi)

                prect_hide(rdi)
                mov rax,[rdi].PANEL.wsub
                or  [rax].WSUB.flag,_W_WHIDDEN
                mov rax,[rsi].PANEL.wsub
                and [rax].WSUB.flag,not _W_WHIDDEN
                panel_show(rsi)
            .endif
            .return
        .endif
    .endif
    pcell_show(rsi)
    panel_putinfo(rsi)
    ret

panel_setactive endp

panel_sethdd proc uses rsi rdi rbx panel:PPANEL, hdd:UINT

    mov ebx,_getdrive()
    mov rsi,panel
    mov edi,_disk_init(hdd)

    historysave()
    wschdrv([rsi].PANEL.wsub, edi)
    panel_read(rsi)

    mov eax,ebx
    .if rsi == cpanel

        cominit([rsi].PANEL.wsub)
    .endif
    panel_putinfozx()
    ret

panel_sethdd endp

panel_toggle proc uses rsi rdi panel:PPANEL

    mov rsi,panel
    mov rdi,panel_getb()
    mov ecx,panel_state(rdi)
    mov rdx,[rsi].PANEL.dialog
    mov eax,[rdx]

    .if eax & _D_ONSCR

        xchg rdi,rdx
        .if ecx && rsi == cpanel

            panel_setactive(rdx)
        .endif
        mov eax,[rdi]
        .if eax & _D_ONSCR

            panel_hide(rsi)
        .endif
    .else
        panel_show(rsi)

        mov rdi,cpanel
        mov rdi,[rdi].PANEL.dialog
        mov eax,[rdi]
        .if !(eax & _D_ONSCR)

            panel_setactive(rsi)
        .endif
    .endif
    xor eax,eax
    ret

panel_toggle endp


panel_toggleact proc

    .ifd panel_stateab()

        historysave()
        panel_setactive(panel_getb())
        mov eax,1
    .endif
    ret

panel_toggleact endp

panel_update proc uses rsi panel:PPANEL

    mov rsi,panel
    mov rax,[rsi].PANEL.wsub
    mov eax,[rax].WSUB.flag
    and eax,_W_VISIBLE
    .ifnz
        panel_read(rsi)
        panel_redraw(rsi)
    .endif
    ret

panel_update endp


panel_xorinfo proc panel:PPANEL

    ldr rcx,panel
    mov rdx,[rcx].PANEL.wsub
    mov eax,[rdx].WSUB.flag
    xor eax,_W_DRVINFO
    .if eax & _W_DRVINFO
        or eax,_W_MINISTATUS
    .endif
    mov [rdx].WSUB.flag,eax
    panel_redraw(rcx)
    ret

panel_xorinfo endp


panel_xormini proc panel:PPANEL

    ldr rcx,panel
    mov rax,[rcx].PANEL.wsub
    xor [rax].WSUB.flag,_W_MINISTATUS
    .if [rax].WSUB.flag & _W_VISIBLE
        panel_redraw(rcx)
    .endif
    msloop()
    xor eax,eax
    ret

panel_xormini endp


pcell_getrect proc private uses rsi rdi rbx xcell:PXCEL, index:uint_t

    ldr rbx,xcell
    ldr ecx,index
    movzx edi,[rbx].XCEL.rows

    mov eax,ecx
    xor edx,edx
    div edi

    mov esi,eax
    mul edi
    sub ecx,eax

    movzx eax,[rbx].XCEL.cpos.col
    inc eax
    mul esi
    add eax,[rbx].XCEL.cpos
    add ah,cl
    ret

pcell_getrect endp


panel_xycmd proc uses rsi rdi rbx panel:PPANEL, xpos:UINT, ypos:UINT

    .ifd panel_state(panel)

        mov rsi,rax
        xor eax,eax
        mov rdx,[rsi].PANEL.dialog

        .if [rdx].DOBJ.flag & _D_ONSCR

            mov ebx,[rdx].DOBJ.rc
            .switch rcxyrow(ebx, xpos, ypos)

              .case 1
                mov eax,_XY_MOVEUP
              .case 0
                .endc

              .case 2
                movzx edx,bl
                mov ecx,xpos
                mov eax,_XY_INSIDE
                .endc .if ecx == edx
                add edx,2
                mov eax,_XY_NEWDISK
                .endc .if ecx <= edx
                inc edx
                mov eax,_XY_CONFIG
                .endc .if ecx == edx
                mov eax,_XY_MOVEUP
                .endc

              .default

                mov edx,eax
                mov ecx,ebx
                shr ecx,24
                mov rax,[rsi].PANEL.wsub

                .if [rax].WSUB.flag & _W_MINISTATUS

                    sub ecx,2
                    .if [rax].WSUB.flag & _W_DRVINFO
                        sub ecx,2
                        .if !(cflag & _C_HORIZONTAL)

                            dec ecx
                        .endif
                    .endif
                    mov eax,_XY_MOVEDOWN
                    .endc .if edx > ecx

                    .ifz
                        movzx eax,bl
                        add eax,2
                        .if eax == xpos
                            mov eax,_XY_DRVINFO
                           .endc
                        .endif
                    .endif
                .endif

                .if edx == ecx

                    movzx eax,bl
                    shr ebx,16
                    add al,bl
                    sub eax,3
                    cmp eax,xpos
                    mov eax,_XY_MINISTATUS
                    .endc .if ZERO?
                    mov eax,_XY_MOVEDOWN
                    .endc
                .endif

                xor ebx,ebx
                .while ebx < [rsi].PANEL.cel_count
                    pcell_getrect([rsi].PANEL.xl, ebx)
                    inc ebx
                    mov edi,eax
                    rcxyrow(eax,xpos,ypos)
                    and eax,eax
                    mov edx,edi
                    mov eax,_XY_INSIDE
                    .ifnz
                        lea ecx,[rbx-1]
                        mov eax,_XY_FILE
                       .break
                    .endif
                .endw
            .endsw
        .endif
    .endif
    ret

panel_xycmd endp

redraw_panels proc uses rbx

    mov ebx,prect_hide(panelb)
    .ifd prect_hide(panela)

        redraw_panel(panela)
    .endif
    .if ebx
        redraw_panel(panelb)
    .endif
    ret

redraw_panels endp


panel_openmsg proc uses rsi rdi rbx panel:PPANEL

   .new col:int_t

    ldr rsi,panel
    mov rbx,[rsi].PANEL.dialog
    xor eax,eax

    .if [rbx].DOBJ.flag & _D_ONSCR && [rbx].DOBJ.wp != rax

        mov rax,[rsi].PANEL.wsub
        mov eax,[rax].WSUB.flag
        and eax,_W_MINISTATUS
        .ifnz
            movzx   ecx,[rbx].DOBJ.rc.col
            sub     ecx,2
            mov     col,ecx
            movzx   edx,[rbx].DOBJ.rc.y
            add     dl,[rbx].DOBJ.rc.row
            sub     edx,2
            movzx   ebx,[rbx].DOBJ.rc.x
            inc     ebx
            mov     al,at_background[B_Panel]
            or      al,at_foreground[F_System]
            shl     eax,16
            mov     al,' '
            mov     edi,edx

            scputw( ebx, edx, ecx, eax )
            scputs( ebx, edi, 0, 5, "open:" )

            mov rsi,[rsi].PANEL.wsub
            mov rax,[rsi].WSUB.path
            .if [rsi].WSUB.flag & _W_ARCHIVE
                mov rax,[rsi].WSUB.file
            .endif
            sub col,6
            add ebx,6
            scpath(ebx, edi, col, rax)
        .endif
    .endif
    ret

panel_openmsg endp


wsreadroot proc private uses rsi rdi rbx wsub:PWSUB, panel:PPANEL

   .new disk:int_t
   .new index:int_t = 0
   .new VolumeID[32]:char_t
   .new fb:PFBLK = NULL

    ldr rbx,wsub

    wsfree(rbx)

    mov eax,[rbx].WSUB.flag
    and eax,not (_W_ARCHIVE or _W_NETWORK)
    or  eax,_W_ROOTDIR
    mov [rbx].WSUB.flag,eax
    _disk_read()
    mov disk,_getdrive()

    .ifd _disk_exist(eax)

        mov rdi,rax
        mov rax,[rbx].WSUB.path
        mov eax,[rax]
        .if ( al && ah == ':' )

            and al,not 20h
            mov cp_disk,al
            .ifd GetVolumeID(&cp_disk, &VolumeID)

                add rdi,DISK.name[3]
                mov byte ptr [rdi-1],' '
                strnzcpy(rdi, &VolumeID, 27)
            .endif
        .endif
    .endif

    mov rax,[rbx].WSUB.arch
    mov byte ptr [rax],0
    strcpy([rbx].WSUB.file, "home")
    xor edi,edi
    xor esi,esi

    .while ( esi < MAXDRIVES )

        inc esi
        .continue .ifd !_disk_exist(esi)

        lea rcx,[rax].DISK.name
        .break .if !fballoc(rcx, [rax].DISK.time, [rax].DISK.size, [rax].DISK.flag)

        mov rcx,fb
        mov fb,rax
        .if ( rcx == NULL )
            mov [rbx].WSUB.fcb,rax
        .else
            mov [rcx].FBLK.next,rax
        .endif
        inc edi
        .if ( esi == disk )
            lea eax,[rdi-1]
            mov index,eax
        .endif
    .endw
    wsetfcb(rbx)
    mov edx,index
    ret

wsreadroot endp


wsub_read proc private uses rsi rdi wsub:PWSUB

    ldr rdi,wsub

    xor esi,esi
    .if ( [rdi].WSUB.flag & _W_ARCHIVE )

        .ifd ( filexist(strfcat(entryname, [rdi].WSUB.path, [rdi].WSUB.file)) == 1 )

            .if ( [rdi].WSUB.flag & _W_ARCHZIP )
                wzipread(rdi)
            .else
                warcread(rdi)
            .endif
            .if ( eax != ER_READARCH )
                inc esi
            .endif
        .endif
    .endif
    .if !esi
        and [rdi].WSUB.flag,not ( _W_ARCHIVE or _W_ROOTDIR )
        wsread(rdi)
    .endif
    mov esi,eax
    .if eax > 1 && !( [rdi].WSUB.flag & _W_NOSORT )
        wssort(rdi)
    .endif
    mov eax,esi
    ret

wsub_read endp


panel_read proc uses rsi rdi panel:PPANEL

    ldr rsi,panel

    mov rdi,[rsi].PANEL.wsub
    panel_openmsg(rsi)

    mov rax,[rdi].WSUB.path
    .if byte ptr [rax] && [rdi].WSUB.flag & _W_ROOTDIR
        wsreadroot(rdi, rsi)
        mov [rsi].PANEL.cel_index,edx
    .else
        wsub_read(rdi)
    .endif
    mov [rsi].PANEL.fcb_count,eax
    .if eax <= [rsi].PANEL.fcb_index
        .if eax
            dec eax
            mov [rsi].PANEL.fcb_index,eax
            inc eax
        .else
            mov [rsi].PANEL.fcb_index,eax
        .endif
    .endif
    ret

panel_read endp


panel_open proc private uses rsi rdi panel:PPANEL

  local path[WMAXPATH]:byte, wsub:ptr, flags:int_t

    ldr rsi,panel
    mov rdi,[rsi].PANEL.wsub
    mov wsub,rdi

    .ifd wsopen(rdi)

        mov [rsi].PANEL.cel_count,0

        .if rsi == cpanel

            mov flags,[rdi].WSUB.flag
            strcpy(addr path, [rdi].WSUB.path)
            mov rax,[rdi].WSUB.path
            mov byte ptr [rax],0
            cominit(wsub)

            .if ( flags & _W_ARCHIVE )
                .ifd !_stricmp(&path, [rdi].WSUB.path)
                    mov [rdi].WSUB.flag,flags
                .endif
            .endif
        .endif

        .if ( [rdi].WSUB.flag & _W_VISIBLE )
            panel_reread(rsi)
            .if ( rsi == cpanel )
                panel_setactive(rsi)
            .endif
        .endif
        mov eax,1
    .endif
    ret

panel_open endp


panel_open_ab proc

    .ifd panel_open(cpanel)
        lea rax,spanelb
        .if rax == cpanel
            lea rax,spanela
        .endif
    .endif
    panel_open(rax)
    mov eax,1
    ret

panel_open_ab endp


panel_close proc uses rbx panel:PPANEL

    ldr rcx,panel

    .if panel_state(rcx)

        mov rbx,rax
        prect_close(rax)
        wsclose([rbx].PANEL.wsub)
    .endif
    ret

panel_close endp

cpanel_setpath proc path:LPSTR

    ldr rax,path
    mov eax,[rax]

    .if ah == ':'

        or  al,20h
        sub eax,'a' - 1

        _disk_ready(eax)
    .endif

    .if eax

        mov rax,cpanel
        mov rax,[rax].PANEL.wsub
        and [rax].WSUB.flag,not (_W_NETWORK or _W_ARCHIVE or _W_ROOTDIR)
        strcpy([rax].WSUB.path, path)
        mov rax,cpanel
        cominit([rax].PANEL.wsub)
        panel_reread(cpanel)
    .endif
    ret

cpanel_setpath endp


cpanel_deselect proc uses rsi rdi rbx fp:PFBLK

    ldr rbx,fp

    and [rbx].FBLK.flag,not _FB_SELECTED

    .if ( cflag & _C_VISUALUPDATE )

        mov di,progress_dobj.DOBJ.flag
        and edi,_D_ONSCR
        .ifnz
            dlhide(&progress_dobj)
        .endif
        panel_putitem(cpanel, 0)

        lea rsi,spanela
        .if rsi == cpanel
            lea rsi,spanelb
        .endif
        wsaddfb([rsi].PANEL.wsub, rbx)
        panel_event(rsi, KEY_END)
        .if edi
            dlshow(&progress_dobj)
        .endif
    .endif
    ret

cpanel_deselect endp


fblk_selectable proc private fp:PFBLK

    ldr rcx,fp
    xor eax,eax

    .if !( byte ptr [rcx] & _A_VOLID )

        inc eax
        .if byte ptr [rcx] & _A_SUBDIR && !( cflag & _C_SELECTDIR )

            dec eax
        .endif
    .endif
    ret

fblk_selectable endp


fblk_invert proc fp:PFBLK

    .if fblk_selectable( ldr(fp) )

        fbinvert(rcx)
    .endif
    ret

fblk_invert endp


fblk_select proc fp:PFBLK

    .if fblk_selectable( ldr(fp) )

        fbselect(rcx)
    .endif
    ret

fblk_select endp


clear37 proc fastcall private uses rcx rdx x, y

    mov al,at_background[B_Panel]
    or  al,at_foreground[F_Panel]
    shl eax,16
    mov al,' '
    scputw(ecx, edx, 37, eax)
    ret

clear37 endp


panel_putmini proc private uses rsi rdi rbx panel:PPANEL

   .new l:int_t, x:int_t, y:int_t
   .new sx:int_t, sy:int_t
   .new fb:PFBLK
   .new VolumeID[32]:byte
   .new DiskID:int_t
   .new FreeBytesAvailable:qword
   .new TotalNumberOfBytes:qword
   .new TotalNumberOfFreeBytes:qword
   .new cFreeBytesAvailable[32]:char_t
   .new cTotalNumberOfBytes[32]:char_t
   .new bstring[64]:char_t
   .new FileSystemName[32]:char_t
   .new SystemTime:SYSTEMTIME
   .new Time[32]:char_t
   .new Date[32]:char_t
   .new len:uint_t
   .new color:uint_t

    ldr rsi,panel
    .if panel_state(rsi)

        mov rdi,[rsi].PANEL.dialog
        .if [rdi].DOBJ.flag & _D_ONSCR

            movzx   eax,[rdi].DOBJ.rc.col
            sub     eax,2
            mov     l,eax
            movzx   eax,[rdi].DOBJ.rc.x
            inc     eax
            mov     x,eax
            movzx   eax,[rdi].DOBJ.rc.y
            add     al,[rdi].DOBJ.rc.row
            sub     al,2
            mov     y,eax
            mov     rax,[rsi].PANEL.wsub
            mov     eax,[rax].WSUB.flag

            .if ( eax & _W_MINISTATUS )

                .if ( eax & _W_DRVINFO )

                    mov ecx,x
                    mov edx,y
                    sub edx,2
                    inc ecx
                    .if cflag & _C_HORIZONTAL
                        add ecx,40
                    .endif
                    clear37(ecx, edx)
                    inc edx
                    clear37(ecx, edx)
                    inc edx
                    .if cflag & _C_HORIZONTAL
                        sub ecx,40
                        clear37(ecx, edx)
                    .endif
                    mov ecx,x
                    add ecx,1
                    .if cflag & _C_HORIZONTAL
                        add ecx,40
                    .endif
                    mov edx,y
                    sub edx,2
                    mov sx,ecx
                    mov sy,edx
                    scputs(ecx, edx, 0, 0, "Size:\nFree:")
                    add sx,31
                    scputs(sx, sy, 0, 0, "byte")
                    inc sy
                    scputs(sx, sy, 0, 0, "byte")

                    mov rax,[rsi].PANEL.wsub
                    mov rax,[rax].WSUB.path
                    mov eax,[rax]
                    mov cp_disk,al
                    .if al && ah == ':'

                        and al,not 0x20
                        mov cp_disk,al
                        sub al,'A' - 1
                        movzx eax,al
                        mov DiskID,eax

                        .ifd GetVolumeID(&cp_disk, &VolumeID)

                            .ifd _disk_exist(DiskID)

                                add rax,DISK.name[3]
                                mov rcx,rax
                                mov byte ptr [rax-1],' '
                                strnzcpy(rcx, &VolumeID, 27)
                            .endif

                            mov cl,at_background[B_Panel]
                            or  cl,at_foreground[F_Files]
                            mov edx,y
                            sub edx,2
                            mov ebx,x
                            inc ebx

                            .if !( cflag & _C_HORIZONTAL )

                                dec edx
                            .endif
                            scputs(ebx, edx, ecx, 30, &VolumeID)
                        .endif
                    .endif

                    .ifd GetFileSystemName(&cp_disk, &FileSystemName)

                        mov dl,at_background[B_Panel]
                        or  dl,at_foreground[F_Subdir]
                        mov ebx,y
                        sub ebx,2
                        mov ecx,x
                        add ecx,12
                        .if !( cflag & _C_HORIZONTAL )
                            dec ebx
                        .endif
                        scputf(ecx, ebx, edx, 24, "%24s", &FileSystemName)
                    .endif

                    GetDiskFreeSpaceEx(&cp_disk, &FreeBytesAvailable,
                            &TotalNumberOfBytes, &TotalNumberOfFreeBytes)

                    mkbstring(&cFreeBytesAvailable, FreeBytesAvailable)
                    mkbstring(&cTotalNumberOfBytes, TotalNumberOfBytes)

                    mov dl,at_background[B_Panel]
                    or  dl,at_foreground[F_Files]
                    mov ecx,x
                    mov ebx,y
                    sub ebx,2
                    add ecx,11
                    .if ( cflag & _C_HORIZONTAL )
                        add ecx,40
                    .endif
                    mov sx,ecx
                    mov sy,edx
                    scputf(ecx, ebx, edx, 20, "%20s", &cTotalNumberOfBytes)
                    inc ebx
                    scputf(sx, ebx, sy, 20, "%20s", &cFreeBytesAvailable)
                .endif

                movzx eax,at_background[B_Panel]
                or  al,at_foreground[F_Hidden]
                shl eax,16
                mov al,' '
                scputw(x, y, l, eax)

                .if ( ![rsi].PANEL.fcb_count )

                    mov rax,[rsi].PANEL.wsub
                    mov rax,[rax].WSUB.path
                    mov al,[rax]
                    scputf(x, y, 0, 0, "[%c:] Empty disk", eax)

                .else

                    mov eax,[rsi].PANEL.fcb_index
                    add eax,[rsi].PANEL.cel_index
                    mov fb,wsfblk([rsi].PANEL.wsub, eax)

                    .ifd panel_selected(rsi)

                        xor eax,eax
                        xor edx,edx
                        mov ecx,[rsi].PANEL.fcb_count
                        .if ecx

                            mov rbx,[rsi].PANEL.wsub
                            .if [rbx].WSUB.fcb != rax

                                xor edi,edi
                                mov rsi,[rbx].WSUB.fcb
                                .repeat

                                    mov rbx,[rsi]
                                    .if [rbx].FBLK.flag & _FB_SELECTED

                                        inc edi
                                        .if !([rbx].FBLK.flag & _A_SUBDIR)

                                            add rax,size_t ptr [rbx].FBLK.size
ifndef _WIN64
                                            adc edx,dword ptr [rbx].FBLK.size[4]
endif
                                        .endif
                                    .endif
                                    add rsi,PFBLK
                                .untilcxz
                                mov size_t ptr FreeBytesAvailable,rax
ifndef _WIN64
                                mov dword ptr FreeBytesAvailable[4],edx
endif
                                lea rbx,bstring
                                mkbstring(rbx, FreeBytesAvailable)
                                mov ecx,x
                                inc ecx
                                scputc(ecx, y, 37, ' ')

                                mov dl,at_background[B_Panel]
                                or  dl,at_foreground[F_Panel]
                                mov ecx,x
                                inc ecx
                                scputf(ecx, y, edx, 0, "%s byte in %d file(s)", rbx, edi)
                            .endif
                        .endif

                    .else

                        mov rbx,fb
                        mov edi,l
                        mov len,strlen([rbx].FBLK.name)
                        mov color,fbcolor(rbx)
                        scputs(x, y, color, &[rdi-25], [rbx].FBLK.name)

                        lea ecx,[rdi-26]
                        .if ( len > ecx )

                            add     ecx,x
                            movzx   eax,at_foreground[F_Panel]
                            or      al,at_background[B_Panel]
                            shl     eax,16
                            mov     ax,U_RIGHT_DOUBLE_QUOTE
                            scputw( ecx, y, 1, eax )
                        .endif

                        lea ecx,[rdi-25]
                        .if ( [rbx].FBLK.flag & _A_HIDDEN or _A_SYSTEM )

                            add     ecx,x
                            mov     eax,color
                            shl     eax,16
                            mov     ax,U_LIGHT_SHADE
                            scputw( ecx, y, 1, eax )
                        .endif

                        lea ecx,[rdi-23]
                        add ecx,x
                        .if ( [rbx].FBLK.flag & _FB_UPDIR )
                            scputs(ecx, y, color, 0, "UP-DIR")
                        .elseif ( [rbx].FBLK.flag & _A_VOLID )
                            mov eax,dword ptr [rbx].FBLK.size
                            scputf(ecx, y, color, 0, "VOL-%02u", eax )
                        .elseif ( [rbx].FBLK.flag & _A_SUBDIR )
                            scputs(ecx, y, color, 0, "SUBDIR")
                        .else
                            mov sx,ecx
                            mov eax,dword ptr [rbx].FBLK.size
                            mov edx,dword ptr [rbx].FBLK.size[4]
                            xor ecx,ecx
                            .while edx
                                shrd eax,edx,10
                                inc  ecx
                                shr  edx,10
                            .endw
                            .while eax >= 0x000F0000
                                shr eax,10
                                inc ecx
                            .endw
                            lea rdx,@CStr("\0KMGT")
                            mov cl,[rdx+rcx]
                            scputf(sx, y, color, 0, "%7u%c", eax, ecx)
                        .endif

                        TimeToSystemTime([rbx].FBLK.time, &SystemTime)
                        SystemDateToStringA(&Date, &SystemTime)
                        SystemTimeToStringA(&Time, &SystemTime)

                        sub edi,5
                        add edi,x
                        scputs(edi, y, color, 5, &Time)
                        sub edi,9
                        lea rdx,Date
                        mov al,[rdx+2]
                        .if ( al >= '0' && al <= '9' )
                            add rdx,2
                        .else
                            mov eax,[rdx+6]
                            shr eax,16
                            mov [rdx+6],eax
                        .endif
                        scputs(edi, y, color, 8, rdx)

                        .if ( [rbx].FBLK.flag & _FB_UPDIR )

                            scputw(x, y, 2, ' ')
                            mov rsi,[rsi].PANEL.wsub
                            strfn([rsi].WSUB.path)
                            mov cl,at_background[B_Panel]
                            or  cl,at_foreground[F_System]
                            scputs(x, y, ecx, 12, rax)
                        .endif
                    .endif
                .endif
            .endif
        .endif
    .endif
    ret

panel_putmini endp

    option  proc: private

fbputdate proc uses rsi rdi rbx fb:PFBLK, wp:PCHAR_INFO, updTime:BOOL, color:UINT

  local SystemTime:SYSTEMTIME
  local Time[32]:char_t
  local Date[32]:char_t

    ldr rbx,fb
    TimeToSystemTime([rbx].FBLK.time, &SystemTime)
    SystemDateToStringA(&Date, &SystemTime)
    mov ebx,color
    shr ebx,8
    lea rsi,Date
    mov al,[rsi+2]
    .if ( al >= '0' && al <= '9' )
        add rsi,2
    .else
        mov eax,[rsi+6]
        shr eax,16
        mov [rsi+6],eax
    .endif
    wcputs(wp, ebx, rsi)
    .if updTime
        SystemTimeToStringA(&Time, &SystemTime)
        add wp,9*4
        mov Time[5],0
        wcputs(wp, ebx, &Time)
    .endif
    ret

fbputdate endp

fbputsize proc uses rsi rdi rbx fb:PFBLK, wp:PCHAR_INFO, l:UINT, color:UINT

    ldr rbx,fb
    ldr rdi,wp
    ldr esi,l

    .if ( [rbx].FBLK.flag & _FB_UPDIR or _A_SUBDIR or _A_VOLID )

        mov eax,color
        mov ax,U_RIGHT_TRIANGLE
        wcputw( rdi, 1, eax)
        mov eax,color
        mov ax,U_LEFT_TRIANGLE
        wcputw( &[rdi+9*4], 1, eax)

        mov edx,color
        shr edx,8
        or  edx,esi

        .if ( [rbx].FBLK.flag & _FB_UPDIR )
            wcputs( &[rdi+2*4], edx, "UP-DIR")
        .elseif ( [rbx].FBLK.flag & _A_VOLID )
            mov eax,dword ptr [rbx].FBLK.size
            wcputf( &[rdi+2*4], edx, "VOL-%02u", eax )
        .else
            wcputs( &[rdi+2*4], edx, "SUBDIR")
        .endif
    .else
        mov edx,esi
        mov dh,at_foreground[F_Subdir]
        or  dh,at_background[B_Panel]
        wcputf( rdi, edx, "%10lu", [rbx].FBLK.size )
    .endif
    ret

fbputsize endp


    option proc:public

fbputsl proc private uses rsi rdi rbx fb:PFBLK, wp:PCHAR_INFO, l:UINT

   .new color:uint_t
   .new len:uint_t
   .new ext:string_t

    ldr rbx,fb
    ldr rdi,wp
    ldr esi,l
    shl fbcolor(rbx),16
    mov color,eax

    mov rax,[rbx].FBLK.name
    .if word ptr [rax] == '..'
        xor eax,eax
    .else
        strext(rax)
    .endif
    mov ext,rax
    mov rcx,[rbx].FBLK.name
    .if rax
        sub rax,rcx
    .else
        strlen(rcx)
    .endif
    mov len,eax

    mov ecx,color
    shr ecx,8
    mov cl,byte ptr len
    .if cl > 8
        mov cl,8
    .endif
    wcputs(rdi, ecx, [rbx].FBLK.name)

    .if ( len > 8 )

        movzx   eax,at_foreground[F_Panel]
        or      al,at_background[B_Panel]
        shl     eax,16
        mov     ax,U_RIGHT_DOUBLE_QUOTE
        wcputw( &[rdi+7*4], 1, eax )
    .endif

    .if ( [rbx].FBLK.flag & _A_HIDDEN or _A_SYSTEM )

        mov eax,color
        shl eax,16
        mov ax,U_LIGHT_SHADE
        wcputw( &[rdi+8*4], 1, eax)
    .endif

    mov rax,ext
    .if rax

        inc rax
        mov edx,color
        shr edx,8
        mov dl,3
        wcputs( &[rdi+9*4], edx, rax)
    .endif
    ret

fbputsl endp

fbputll proc private uses rsi rdi rbx fb:PFBLK, wp:PCHAR_INFO, l:UINT

   .new color:uint_t

    ldr rbx,fb
    ldr rdi,wp
    ldr esi,l

    mov color,fbcolor(rbx)
    lea ecx,[rsi-1]
    mov ch,al
    wcputs(rdi, ecx, [rbx].FBLK.name)

    .ifd ( strlen([rbx].FBLK.name) > esi )

        movzx   eax,at_foreground[F_Panel]
        or      al,at_background[B_Panel]
        shl     eax,16
        mov     ax,0x00BB

        wcputw( &[rdi+rsi*4-8], 1, eax )
    .endif

    .if ( [rbx].FBLK.flag & _A_HIDDEN or _A_SYSTEM )

        mov eax,color
        shl eax,16
        mov ax,U_LIGHT_SHADE
        wcputw( &[rdi+rsi*4-4], 1, eax)
    .endif
    ret

fbputll endp

fbputld proc private uses rsi rdi rbx fb:PFBLK, wp:PCHAR_INFO, l:UINT

   .new color:uint_t
   .new dist:uint_t = 0
   .new fext:uint_t = 3
   .new maxf:uint_t
   .new ext:string_t

    ldr rbx,fb
    ldr rdi,wp
    ldr esi,l
    shl fbcolor(rbx),16
    mov color,eax

    .if ( cflag & _C_HORIZONTAL ) ; Long Horizontal Detail
        mov dist,6
        mov fext,8
    .endif

    lea rcx,[rdi+rsi*4-8*4]
    xor eax,eax
    .if cflag & _C_HORIZONTAL
        inc eax
        sub rcx,((14-8)*4)
    .endif
    fbputdate(rbx, rcx, eax, color)


    lea ecx,[rsi-19]
    sub ecx,dist
    mov maxf,ecx
    fbputsize(rbx, &[rdi+rcx*4], esi, color)

    mov eax,fext
    add eax,3
    sub maxf,eax

    .ifd ( strlen([rbx].FBLK.name) > maxf )

        movzx   eax,at_foreground[F_Panel]
        or      al,at_background[B_Panel]
        shl     eax,16
        mov     ax,U_RIGHT_DOUBLE_QUOTE
        mov     ecx,maxf
        wcputw( &[rdi+rcx*4], 1, eax )
    .endif

    .if ( [rbx].FBLK.flag & _A_HIDDEN or _A_SYSTEM )

        mov eax,color
        shl eax,16
        mov ax,U_LIGHT_SHADE
        mov ecx,maxf
        inc ecx
        wcputw( &[rdi+rcx*4], 1, eax)
    .endif

    mov rax,[rbx].FBLK.name
    .if word ptr [rax] == '..'
        xor eax,eax
    .else
        strext(rax)
    .endif
    mov ext,rax

    mov ecx,color
    shr ecx,8
    mov cl,byte ptr maxf
    mov rdx,[rbx].FBLK.name
    .if rax
        sub rax,rdx
        .if al <= cl
            mov cl,al
        .endif
    .endif
    wcputs(rdi, ecx, rdx)

    mov rax,ext
    .if rax

        inc rax
        mov edx,color
        shr edx,8
        mov dl,byte ptr fext
        mov ecx,maxf
        add ecx,2
        wcputs( &[rdi+rcx*4], edx, rax)
    .endif
    ret

fbputld endp

fbputsd proc private uses rsi rdi rbx fb:PFBLK, wp:PCHAR_INFO, l:UINT

   .new color:uint_t
   .new maxf:uint_t
   .new ext:string_t

    ldr rbx,fb
    ldr rdi,wp
    ldr esi,l

    .if ( cflag & _C_HORIZONTAL ) ; Long Horizontal Detail

        .return( fbputld(rbx, rdi, esi) )
    .endif

    shl fbcolor(rbx),16
    mov color,eax
    lea rcx,[rdi+rsi*4-14*4]
    fbputdate(rbx, rcx, 1, color)
    lea ecx,[rsi-25]
    mov maxf,ecx
    sub maxf,6
    fbputsize(rbx, &[rdi+rcx*4], esi, color)

    .ifd ( strlen([rbx].FBLK.name) > maxf )

        movzx   eax,at_foreground[F_Panel]
        or      al,at_background[B_Panel]
        shl     eax,16
        mov     ax,U_RIGHT_DOUBLE_QUOTE
        mov     ecx,maxf
        wcputw( &[rdi+rcx*4], 1, eax )
    .endif

    .if ( [rbx].FBLK.flag & _A_HIDDEN or _A_SYSTEM )

        mov eax,color
        shl eax,16
        mov ax,U_LIGHT_SHADE
        mov ecx,maxf
        inc ecx
        wcputw( &[rdi+rcx*4], 1, eax)
    .endif

    mov rax,[rbx].FBLK.name
    .if word ptr [rax] == '..'
        xor eax,eax
    .else
        strext(rax)
    .endif
    mov ext,rax

    mov ecx,color
    shr ecx,8
    mov cl,byte ptr maxf
    mov rdx,[rbx].FBLK.name
    .if rax
        sub rax,rdx
        .if al <= cl
            mov cl,al
        .endif
    .endif
    wcputs(rdi, ecx, rdx)

    mov rax,ext
    .if rax
        inc rax
        mov edx,color
        shr edx,8
        mov dl,3
        mov ecx,maxf
        add ecx,2
        wcputs(&[rdi+rcx*4], edx, rax)
    .endif
    ret

fbputsd endp

;
; 0. Clear panel
; 1. moving down: all lines moved up 1   -- last line cleared
; 2. moving up:   all lines moved down 1 -- first line cleared
;

prect_clear proc private uses rsi rdi rbx window:PCHAR_INFO, rc:TRECT, ptype:UINT

  local wl:UINT, l:UINT

    mov     rbx,window
    movzx   eax,rc.col
    mov     l,eax
    shl     eax,2
    mov     wl,eax
    movzx   edi,rc.row
    mov     eax,ptype

    .switch al
      .case 1   ; move one line up
        mov ecx,l
        lea eax,[rdi-1]
        mov rdi,rbx
        lea rsi,[rdi+rcx*4]
        mul ecx
        mov ecx,eax
        rep movsd
        mov rbx,rdi
        mov edi,1
       .endc
      .case 2   ; move one line down
        mov ecx,l
        lea eax,[rdi-1]
        mov rsi,rbx
        lea rdi,[rsi+rcx*4]
        mul ecx
        mov ecx,eax
        dec eax
        shl eax,2
        add rdi,rax
        add rsi,rax
        std
        rep movsd
        cld
        mov edi,1
    .endsw

    .repeat
        mov rdx,rbx
        mov ecx,l
        movzx eax,at_foreground[F_Panel]
        or  al,at_background[B_Panel]
        shl eax,16
        .repeat
            mov ax,[rdx]
            .if ax != U_LIGHT_VERTICAL
                mov ax,' '
                mov [rdx],eax
            .endif
            add rdx,4
        .untilcxz
        mov eax,wl
        add rbx,rax
        dec edi
    .untilz
    ret

prect_clear endp


panel_putitem proc uses rsi rdi rbx panel:PPANEL, index:UINT

  local rc:TRECT, rcxc:TRECT, dlrc, result, count, dlwp:PCHAR_INFO

    mov rsi,panel
    mov rdi,[rsi].PANEL.dialog

    .if !( [rdi].DOBJ.flag & _D_ONSCR )

        .return
    .endif

    mov     rc,[rdi].DOBJ.rc
    movzx   eax,ax
    mov     dlrc,eax
    add     rc.y,2
    inc     rc.x
    sub     rc.col,2
    sub     rc.row,3
    mov     rax,[rsi].PANEL.wsub
    mov     eax,[rax].WSUB.flag

    .if ( eax & _W_MINISTATUS )
        sub rc.row,2
        .if ( eax & _W_DRVINFO )
            sub rc.row,3
            .if ( cflag & _C_HORIZONTAL )
                inc rc.row
            .endif
        .endif
    .endif

    .if !rcalloc(rc, 0)

        .return
    .endif
    mov dlwp,rax
    mov rbx,rax

    .if ( [rsi].PANEL.fcb_count )

        mov result,dlclose([rsi].PANEL.xl)

        pcell_set(rsi)
        rcread(rc, rbx)
        prect_clear(rbx, rc, index)

        xor edi,edi
        mov count,-1

        .while  1

            inc count
            mov eax,count
            .if ( eax >= [rsi].PANEL.cel_count )

                rcwrite(rc, rbx)
                free(rbx)

                .if result
                    pcell_show(rsi)
                .endif
                panel_putmini(rsi)
               .break
            .endif

            pcell_getrect([rsi].PANEL.xl, eax)

            sub     eax,dlrc
            sub     eax,0x0201
            mov     rcxc,eax
            movzx   ecx,rc.col
            mov     rdx,rcbprc(eax, dlwp, ecx)
            mov     eax,index

            .if eax == 1

                mov rcx,[rsi].PANEL.xl
                mov eax,edi
                add al,[rcx].XCEL.rows
                dec al
            .elseif eax == 2
                mov eax,edi
            .else
                mov al,rcxc.y
            .endif

            .continue .if rcxc.y != al

            mov     rax,[rsi].PANEL.wsub
            mov     rcx,[rax].WSUB.fcb
            mov     eax,[rsi].PANEL.fcb_index
            add     eax,count
            mov     rcx,[rcx+rax*size_t]
            mov     rax,[rsi].PANEL.xl
            movzx   eax,[rax].XCEL.cpos.col

            [rsi].PANEL.putfcb(rcx, rdx, eax)
        .endw
    .else

        dlclose([rsi].PANEL.xl)
        pcell_set(rsi)
        rcread(rc, rbx)
        prect_clear(rbx, rc, 0)
        rcwrite(rc, rbx)
        free(rbx)

        mov rcx,[rsi].PANEL.wsub
        and [rcx].WSUB.flag,not (_W_ARCHIVE or _W_ROOTDIR)
    .endif
    ret

panel_putitem endp

panel_putitemax proc private index:UINT

    panel_putitem(rsi, index)
    mov eax,1
    ret

panel_putitemax endp

panel_putinfoax proc private index:UINT

    panel_putinfo(rsi)
    panel_putitemax(index)
    ret

panel_putinfoax endp

panel_putinfozx proc private

    xor ecx,ecx
    mov [rsi].PANEL.cel_index,ecx
    mov [rsi].PANEL.fcb_index,ecx
    panel_putinfoax(ecx)
    ret

panel_putinfozx endp


panel_reread proc uses rsi panel:PPANEL

    xor eax,eax
    ldr rsi,panel
    mov rcx,[rsi].PANEL.wsub
    .if [rcx].WSUB.flag & _W_VISIBLE

        panel_read(rsi)
        panel_putinfoax(0)
        mov eax,1
    .endif
    ret

panel_reread endp


reread_panels proc

    .if panel_state(panela)
        panel_reread(rax)
    .endif
    .if panel_state(panelb)
        panel_reread(rax)
    .endif
    ret

reread_panels endp


panel_redraw proc uses rsi panel:PPANEL

    xor eax,eax
    ldr rsi,panel
    mov rcx,[rsi].PANEL.wsub
    .if [rcx].WSUB.flag & _W_VISIBLE

        prect_open(rsi)
        panel_putinfoax(0)
        mov eax,1
        .if rsi == cpanel
            pcell_show(rsi)
        .endif
    .endif
    ret

panel_redraw endp

redraw_panel proc panel:PPANEL

    ldr rcx,panel
    mov rdx,[rcx].PANEL.wsub
    or  [rdx].WSUB.flag,_W_VISIBLE
    panel_redraw(rcx)
    ret

redraw_panel endp


pcell_update proc uses rsi rdi rbx panel:PPANEL

   .new p:ptr

    ldr rsi,panel
    .ifd dlclose([rsi].PANEL.xl)

        pcell_set(rsi)
        .if panel_curobj(rsi)

            mov rbx,[rsi].PANEL.xl
            mov ebx,[rbx].XCEL.rc
            mov rdi,rdx

            .if rcalloc(ebx, 0)

                mov p,rax
                rcread(ebx, rax)

                mov rcx,rdi
                mov rdi,p
                mov rax,[rsi].PANEL.xl
                movzx eax,[rax].XCEL.cpos.col
                [rsi].PANEL.putfcb(rcx, rdi, eax)
                rcwrite(ebx, rdi)
                free(rdi)
            .endif

            pcell_open(rsi)
            dlshow([rsi].PANEL.xl)
            panel_putmini(rsi)
            mov eax,1
        .endif
    .endif
    ret

pcell_update endp


pcell_select proc private panel:PPANEL

    .if panel_curobj(panel)

        .if fblk_invert(rdx)

            pcell_update(panel)
            mov eax,1
        .endif
    .endif
    ret

pcell_select endp

;----------------------------------------------------------------------------
; Panel Event
;----------------------------------------------------------------------------

S_PEVENT    STRUC
pe_fblk     PFBLK ?
pe_name     LPSTR ?
pe_flag     uint_t ?
pe_file     char_t _MAX_PATH dup(?)
pe_path     char_t _MAX_PATH dup(?)
S_PEVENT    ENDS

    assume  rsi:ptr PANEL
    assume  rdi:ptr WSUB

add_to_path proc private path:LPSTR, name:LPSTR

    ldr rcx,path
    ldr rdx,name

    xor eax,eax
    .if [rcx] == al
        strcpy(rcx, rdx)
    .else
        strfcat(rcx, rax, rdx)
    .endif
    ret

add_to_path endp

reduce_path proc private uses rdi path:LPSTR

    ldr rdi,path
    .if strrchr(rdi, '\')

        mov rdi,rax
        xor eax,eax
    .endif
    mov [rdi],al
    ret

reduce_path endp

error_directory proc private directory:LPSTR

    syserr(_get_doserrno(0), "Error open directory", "Can't open the directory:\n%s", directory)
    xor eax,eax
    ret

error_directory endp

panel_event proc uses rsi rdi rbx panel:PPANEL, event:UINT

  local pe:S_PEVENT

    mov rsi,panel_state(panel)
    mov eax,event

    .switch eax

      .case KEY_LEFT

        mov rcx,[rsi].xl
        xor edx,edx
        movzx eax,[rcx].XCEL.rows ; number of lines in panel
        mov ecx,[rsi].cel_index

        .switch
          .case eax <= ecx
            sub ecx,eax
            mov edx,ecx
          .case ecx
            mov [rsi].cel_index,edx
            pcell_update(rsi)
          .case [rsi].fcb_index == edx
            xor eax,eax
            .endc
          .case eax <= [rsi].fcb_index
            sub [rsi].fcb_index,eax
            mov edx,[rsi].fcb_index
          .default
            mov [rsi].fcb_index,edx
            panel_putitemax(0)
        .endsw
        .endc

      .case KEY_RIGHT

        mov rax,[rsi].xl
        movzx ecx,[rax].XCEL.rows
        mov eax,[rsi].cel_index
        add eax,ecx
        mov edx,[rsi].cel_count
        dec edx
        .if eax <= edx

            add [rsi].cel_index,ecx
            pcell_update(rsi)
        .else
            mov eax,[rsi].cel_index
            add eax,[rsi].fcb_index
            add eax,ecx
            .if eax < [rsi].fcb_count

                add [rsi].fcb_index,ecx
                panel_putitemax(0)
            .elseif [rsi].cel_index < edx

                mov [rsi].cel_index,edx
                pcell_update(rsi)
            .else
                xor eax,eax
            .endif
        .endif
        .endc

      .case KEY_UP
        xor eax,eax
        .if [rsi].cel_index != eax

            dec [rsi].cel_index
            pcell_update(rsi)
        .elseif [rsi].fcb_index != eax

            dec [rsi].fcb_index
            panel_putitemax(2)
        .endif
        .endc

      .case KEY_INS
        mov rax,keyshift
        .if byte ptr [rax] & 3
            xor eax,eax
            .endc
        .endif
        .endc .ifd !pcell_select(rsi)
        .endc .if !(cflag & _C_INSMOVDN)

      .case KEY_DOWN
        mov ecx,[rsi].cel_count
        dec ecx
        xor eax,eax
        .if ecx > [rsi].cel_index

            inc [rsi].cel_index
            pcell_update(rsi)
        .elseif ZERO?

            mov ecx,[rsi].fcb_count
            sub ecx,[rsi].fcb_index
            sub ecx,[rsi].cel_index
            .ifs ecx > 1

                inc [rsi].fcb_index
                panel_putitemax(1)
            .endif
        .endif
        .endc

      .case KEY_END
        mov edx,[rsi].cel_count
        mov eax,[rsi].fcb_count
        .if edx < eax

            sub eax,edx
            mov [rsi].fcb_index,eax
            dec edx
            mov [rsi].cel_index,edx
            panel_putitemax(0)
        .else
            xor eax,eax
            dec edx
            .if edx > [rsi].cel_index

                mov [rsi].cel_index,edx
                mov [rsi].fcb_index,eax
                panel_putitemax(eax)
            .endif
        .endif
        .endc

      .case KEY_HOME
        xor eax,eax
        mov edx,[rsi].cel_index
        or  edx,[rsi].fcb_index
        .ifnz
            mov [rsi].cel_index,eax
            mov [rsi].fcb_index,eax
            panel_putitemax(eax)
        .endif
        .endc

      .case KEY_PGUP
        xor eax,eax
        mov edx,[rsi].cel_index
        or  edx,[rsi].fcb_index
        .ifnz
            .if [rsi].cel_index != eax

                mov [rsi].cel_index,eax
                pcell_update(rsi)
            .else
                mov ecx,eax
                mov rdx,[rsi].xl
                mov al,[rdx+2]
                mov cl,[rdx+3]
                imul ecx

                .if eax <= [rsi].fcb_index

                    sub [rsi].fcb_index,eax
                .else
                    mov [rsi].fcb_index,0
                .endif
                panel_putitemax(0)
            .endif
        .endif
        .endc

      .case KEY_PGDN
        mov eax,[rsi].cel_count
        dec eax
        .if eax != [rsi].cel_index

            mov [rsi].cel_index,eax
            pcell_update(rsi)
        .else

            xor ecx,ecx
            add eax,[rsi].fcb_index
            inc eax
            .if eax != [rsi].fcb_count

                mov eax,[rsi].fcb_index
                add eax,[rsi].cel_count
                .if eax < [rsi].fcb_count

                    mov eax,[rsi].cel_count
                    dec eax
                    add [rsi].fcb_index,eax
                    xor eax,eax
                    mov [rsi].cel_index,eax
                    panel_putitemax(eax)
                    mov ecx,eax
                .endif
            .endif
            mov eax,ecx
        .endif
        .endc

      .case KEY_MOUSEDN
        mov rax,[rsi].xl
        movzx ecx,byte ptr [rax+3]
        mov eax,[rsi].cel_index
        add eax,[rsi].fcb_index
        add eax,ecx
        .if eax >= [rsi].fcb_count

            .gotosw(KEY_DOWN)
        .endif
        add [rsi].fcb_index,ecx
        panel_putitemax(0)
        .endc

      .case KEY_MOUSEUP
        mov rax,[rsi].xl
        movzx eax,byte ptr [rax+3]
        .if eax > [rsi].fcb_index

            .gotosw(KEY_UP)
        .endif
        sub [rsi].fcb_index,eax
        panel_putitemax(0)
        .endc

      .case KEY_ENTER
      .case KEY_KPENTER

        mov rdi,[rsi].wsub
        .endc .ifd !panel_curobj(rsi)

        mov pe.pe_name,rax
        mov pe.pe_fblk,rdx
        mov pe.pe_flag,ecx

        .switch
        .case ecx & _A_SUBDIR

            mov rax,[rdi].path
            mov al,[rax+1]
            .if !( al == ':' || al == '\' )

                error_directory([rdi].path)
               .endc
            .endif

            .if !( ecx & _FB_ARCHIVE )

                historysave()
            .endif
            mov pe.pe_file,0

            .if pe.pe_flag & _FB_UPDIR

                mov rax,[rdi].path
                .if [rdi].flag & _W_ARCHIVE or _W_ROOTDIR

                    mov rax,[rdi].arch
                    .if byte ptr [rax] == 0
                        mov rax,[rdi].file
                    .endif
                .endif
                strfn(rax)
                lea rcx,pe.pe_file
                strcpy(rcx, rax)
            .endif

            .if pe.pe_flag & _FB_ARCHIVE

                mov rcx,[rdi].arch
                .if pe.pe_flag & _FB_UPDIR

                    .if byte ptr [rcx] == 0

                        and [rdi].flag,not (_W_ARCHIVE or _W_ROOTDIR)
                    .else
                        reduce_path(rcx)
                    .endif
                .else

                    mov rdx,pe.pe_fblk
                    add_to_path(rcx, [rdx].FBLK.name)
                .endif

            .else

                mov rax,[rdi].path
                .if byte ptr [rax+1] == ':'

                    .if !( pe.pe_flag & _FB_ROOTDIR )

                        _utftows(strfcat(&pe.pe_path, [rdi].path, pe.pe_name))
                        .ifd SetCurrentDirectoryW(rax)

                            strnzcpy([rdi].path, &pe.pe_path, WMAXPATH)
                            ;GetCurrentDirectory(WMAXPATH, [rdi].path)
                        .endif
                        .if !eax

                            _dosmaperr( GetLastError() )
                            error_directory(&pe.pe_path)
                           .endc
                        .endif
                    .else

                        mov rax,[rdi].arch
                        mov byte ptr [rax],0
                        .if !( pe.pe_flag & _FB_UPDIR )

                            strcpy([rdi].arch, pe.pe_name)
                        .endif
                        or [rdi].flag,_W_ROOTDIR
                    .endif

                .else

                    mov rdi,rax
                    .if pe.pe_flag & _FB_UPDIR

                        .if strrchr(addr [rdi+2], '\')

                            reduce_path(rdi)
                        .else

                            mov rdi,[rsi].wsub
                            .if ( [rdi].flag & _W_NETWORK )
                                or [rdi].flag,_W_ROOTDIR
                            .endif
                        .endif
                    .else
                        mov rdx,pe.pe_fblk
                        add_to_path(rdi, [rdx].FBLK.name)
                    .endif
                .endif
            .endif

            cominit([rsi].wsub)
            panel_read(rsi)

            .if !( pe.pe_flag & _FB_ROOTDIR )

                xor eax,eax
                mov [rsi].cel_index,eax
                mov [rsi].fcb_index,eax

                .if pe.pe_file != al

                    .ifd wsearch([rsi].wsub, addr pe.pe_file) != -1

                        panel_setid(rsi, eax)
                    .endif
                .endif
            .endif
            panel_putinfoax(0)
            mov eax,1
           .endc

        .case ecx & _FB_ROOTDIR && ecx & _A_VOLID
            ;
            ; Root directory - change disk
            ;
            mov rax,cpanel
            mov rax,[rax].PANEL.wsub
            and [rax].WSUB.flag,not _W_ROOTDIR
            mov rax,pe.pe_name
            movzx eax,byte ptr [rax]
            sub al,'A' - 1
            panel_sethdd(cpanel, eax)
            mov eax,1
            .endc

            .case ecx & _FB_ARCHIVE
            ;
            ; File inside archive
            ;
            xor eax,eax
            .endc

        .default
            ;
            ; case file
            ;
            lea rbx,pe.pe_file
            .ifd _aisexec(strfcat(rbx, [rdi].path, pe.pe_name))
                ;
                ; case .EXE, .COM, .BAT, .CMD
                ;
                .if strchr(rbx, ' ')

                    strcpy(&pe.pe_path, "\"")
                    strcat(strcat(rax, rbx), "\"")
                    mov rbx,rax
                .endif
                command(rbx)
                mov eax,1
                .endc
            .endif

            .if CFExpandCmd(rbx, pe.pe_name, "Filetype")
                ;
                ; case DZ.INI type
                ;
                command(rbx)
                mov eax,1
               .endc
            .endif

            .if strext(rbx)
                ;
                ; case EDit Info file (.EDI) ?
                ;
                .ifd !_stricmp(rax, ".edi")

                    topenedi(rbx)
                    mov eax,1
                   .endc
                .endif
            .endif

            ;
            ; Read 4 byte from file
            ;
            .ifd readword(rbx)

                .if ax == 4B50h ; 'PK'
                    ;
                    ; case .ZIP file
                    ;
                    mov eax,_W_ARCHZIP
                .elseifd warctest(pe.pe_fblk, eax) == 1
                    ;
                    ; case 7za archive
                    ;
                    mov eax,_W_ARCHEXT
                .else
                    xor eax,eax
                .endif
            .endif

            .if !eax
                ;
                ; case System OS type
                ;
                .if console & CON_NTCMD

                    CreateConsole(rbx, _P_NOWAIT)
                    mov eax,1
                .endif
            .else

                mov ecx,path_a.flag
                or  ecx,path_b.flag
                and ecx,_W_ARCHIVE
                .ifz
                    mov rdi,[rsi].wsub
                    mov rcx,[rdi].arch
                    mov byte ptr [rcx],0
                    or  [rdi].flag,eax
                    mov rdi,[rdi].file
                    strcpy(rdi, pe.pe_name)
                    panel_read(rsi)
                    panel_putinfozx()
                    mov eax,1
                .else
                    xor eax,eax
                .endif
            .endif
        .endsw
        .endc
    .default
        xor eax,eax
    .endsw
    ret

panel_event endp

    assume  rsi:nothing
    assume  rdi:nothing

getmouse proc private

    mousep()
    mov esi,keybmouse_y
    mov edi,keybmouse_x
    test eax,eax
    ret

getmouse endp


pcell_move proc private uses rsi rdi rbx panel:PPANEL

  local fblk:PFBLK, rect:TRECT, dialog:PDOBJ, mouse, dlflag, selected

    ldr rbx,panel
    .if cpanel_findfirst()

        mov fblk,rdx
        mov rdi,[rbx].PANEL.xl
        mov eax,[rdi].XCEL.rc
        mov rect,eax
        mov selected,panel_selected(rbx)

        .ifd mousep() == 1
            ;
            ; Create a movable object
            ;
            mov rax,keyshift
            mov eax,[rax]
            and eax,3       ; Shift + Mouse = Move
            mov mouse,eax   ; else Copy

            .if selected
                mov rect.col,15
            .else

                mov rax,[rbx].PANEL.wsub
                mov eax,[rax].WSUB.flag
                .if eax & _W_DETAIL
                    sub rect.col,26
                .endif
                .repeat
                    mov cl,rect.x
                    add cl,rect.col
                    dec cl
                    mov dl,rect.y
                    .break .ifd getxyc(ecx, edx) != ' '
                    dec rect.col
                .untilz
                inc rect.col
            .endif

            inc rect.col
            dec rect.x
            movzx eax,at_background[B_Inverse]
            rcopen(rect, _D_DMOVE or _D_CLEAR or _D_COLOR, eax, 0, 0)
            mov dialog,rax
            lea rcx,[rax+4]
            mov edx,selected

            .if edx
                wcputf(rcx, 0, "%d file(s) to", edx)
            .else
                mov dl,rect.col
                dec dl
                mov rax,fblk
                wcputs(rcx, edx, [rax].FBLK.name)
            .endif

            mov dlflag,_D_DMOVE or _D_CLEAR or _D_COLOR or _D_DOPEN
            rcshow(rect, dlflag, dialog)
            or  dlflag,_D_ONSCR
            mov ecx,rect
            mov dl,ch
            scputw(ecx, edx, 1, ' ')
            mov ecx,rect
            add cl,rect.col
            dec cl
            mov dl,ch
            mov eax,'+'
            .if byte ptr mouse
                mov al,' '
            .endif
            scputw(ecx, edx, 1, eax)
            ;
            ; Move the object
            ;
            .while getmouse() == 1

                movzx ecx,rect.x
                .if ( ecx < edi )
                    mov rect,rcmove(rect, dialog, RC_MOVERIGHT)
                .elseif ( ecx > edi )
                    mov rect,rcmove(rect, dialog, RC_MOVELEFT)
                .endif
                movzx ecx,rect.y
                .if ( ecx < esi )
                    mov rect,rcmove(rect, dialog, RC_MOVEDOWN)
                .elseif ( ecx > esi )
                    mov rect,rcmove(rect, dialog, RC_MOVEUP)
                .endif
                mov rax,keyshift
                mov eax,[rax]
                and eax,3
                .if eax != mouse

                    mov mouse,eax
                    mov ecx,'+'
                    .if eax
                        mov ecx,' '
                    .endif
                    mov eax,rect
                    add al,rect.col
                    dec al
                    mov dl,ah
                    scputw(eax, edx, 1, ecx)
                .endif
            .endw
            rcclose(rect, dlflag, dialog)
            ;
            ; Find out where the object is
            ;
            mov rax,[rbx].PANEL.wsub
            mov eax,[rax].WSUB.flag
            mov rcx,panela
            .if !( eax & _W_PANELID )
                mov rcx,panelb
            .endif
            .ifd panel_xycmd(rcx, edi, esi)

                .if mouse
                    cmmove()
                .else
                    cmcopy()
                .endif
                mov eax,1
            .else
                .ifd statusline_xy(edi, esi, 9, &MOBJ_Statusline)

                    .switch ecx ;
                                ; 9 cmhelp
                                ; 8 cmrename
                    .case 7     ; 7 cmview
                    .case 6     ; 6 cmedit
                    .case 5     ; 5 cmcopy
                    .case 4     ; 4 cmmove
                                ; 3 cmmkdir
                    .case 2     ; 2 cmdelete
                                ; 1 cmexit
                        [rax].MSOBJ.cmd()
                        mov eax,1
                       .endc
                    .default
                        xor eax,eax
                    .endsw

                .elseif cflag & _C_COMMANDLINE

                    mov rcx,DLG_Commandline
                    movzx ecx,[rcx].DOBJ.rc.y

                    .if ecx == esi

                        cmmklist()
                        mov eax,1
                    .endif
                .endif
            .endif
        .else
            xor eax,eax
        .endif
    .endif
    ret

pcell_move endp


pcell_setxy proc uses rsi rdi rbx panel:PPANEL, xpos:UINT, ypos:UINT

  local rect:TRECT

    mov rbx,panel
    mov esi,ypos
    mov edi,xpos

    .if panel_state(rbx)

        .while  1

            mov xpos,edi
            mov ypos,esi
            .ifd panel_xycmd(rbx, edi, esi) != _XY_FILE

                .continue .ifd getmouse() == 2

                xor eax,eax
               .break
            .endif

            mov rect,edx
            .if ecx != [rbx].PANEL.cel_index

                mov [rbx].PANEL.cel_index,ecx
                pcell_update(rbx)
            .endif

            .ifd getmouse() != 2

                mousewait(edi, esi, 1)

                .ifd !pcell_move(rbx)

                    mov edi,10
                    .repeat

                        Sleep(16)
                        .break .ifd mousep()

                        dec edi
                    .untilz

                    .ifd getmouse()

                        .if edi == xpos && esi == ypos

                            panel_event(rbx, KEY_ENTER)
                        .endif
                    .endif
                .endif
                .break
            .endif

            pcell_select(rbx)

            movzx eax,rect.x
            movzx edx,rect.y
            movzx ecx,rect.col
            mousewait(eax, edx, ecx)

            mov esi,keybmouse_y
            mov edi,keybmouse_x
        .endw
    .endif
    ret

pcell_setxy endp

    END
