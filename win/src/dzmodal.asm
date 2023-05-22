; DZMODAL.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include string.inc
include io.inc
include malloc.inc
include stdlib.inc

history_event_list      proto watcall :PDOBJ, :PLOBJ
DirectoryToCurrentPanel proto :PDIRECTORY

    .data

MOBJ_Statusline MSOBJ \
    { {  1,24,7,1 }, cmhelp     },
    { { 10,24,6,1 }, cmrename   },
    { { 18,24,7,1 }, cmview     },
    { { 27,24,7,1 }, cmedit     },
    { { 36,24,7,1 }, cmcopy     },
    { { 45,24,7,1 }, cmmove     },
    { { 54,24,7,1 }, cmmkdir    },
    { { 64,24,7,1 }, cmdelete   },
    { { 72,24,7,1 }, cmexit     }

    .code

comaddstring proc private string:LPSTR

    xor eax,eax
    mov rdx,DLG_Commandline

    .if ( [rdx].DOBJ.flag & _D_ONSCR )

        mov rax,com_info.base
        .if byte ptr [rax]

            strtrim(com_info.base)
            strcat(com_info.base, " ")
        .endif
        strcat(strcat(com_info.base, string), " ")
        comevent(KEY_END)
    .endif
    ret

comaddstring endp


cmcfblktocmd proc private

    .if panel_curobj(cpanel)

        comaddstring(rax)
    .endif
    ret

cmcfblktocmd endp


cmpathatocmd proc private

    mov rax,panela
    mov rax,[rax].PANEL.wsub
    comaddstring([rax].WSUB.path)
    ret

cmpathatocmd endp


cmpathbtocmd proc private

    mov rax,panelb ; @v3.35 - Ctrl-9
    mov rax,[rax].PANEL.wsub
    comaddstring([rax].WSUB.path)
    ret

cmpathbtocmd endp


statusline_xy proc uses rsi rdi rbx x:SINT, y:SINT, q:SINT, o:PMSOBJ

    mov edi,q
    mov ebx,y
    mov eax,cflag
    and eax,_C_STATUSLINE

    .ifnz
        xor eax,eax
        .if ebx == _scrrow
            mov rsi,o
            .repeat
                mov [rsi].MSOBJ.rc.y,bl
                .break .if rcxyrow([rsi].MSOBJ.rc, x, ebx)
                add rsi,MSOBJ
                dec edi
            .untilz
            .if eax
                mov rax,rsi
                mov ecx,edi
            .endif
        .endif
    .endif
    ret

statusline_xy endp


GetPathFromHistory proc uses rsi rdi rbx panel:PPANEL

  local ll:LOBJ, rc:TRECT, old_list:ptr

    mov rbx,IDD_DZHistory
    mov rc,[rbx].RIDD.rc

    mov rax,panel
    mov rax,[rax].PANEL.dialog
    mov ecx,[rax].DOBJ.rc
    add cl,3
    mov [rbx].RIDD.rc.x,cl

    mov eax,_scrrow
    mov cl,al
    sub al,ch
    .if al >= [rbx].RIDD.rc.row
        mov al,ch
        add al,2
    .else
        mov al,cl
        sub al,[rbx].RIDD.rc.row
    .endif
    mov [rbx].RIDD.rc.y,al

    mov rax,history
    .if rax
        mov rsi,rax
        .if rsopen(rbx)

            mov rbx,rax

            lea rdi,ll
            xor eax,eax
            mov ecx,LOBJ
            rep stosb

            mov ll.lproc,&history_event_list
            mov ll.dcount,16
            mov ll.list,alloca(MAXHISTORY*size_t)
            mov ecx,MAXHISTORY
            mov rdi,rax
            xor edx,edx

            .repeat
                mov rax,[rsi].DIRECTORY.path
                .break .if !rax
                mov [rdi],rax
                add rdi,LPSTR
                add rsi,DIRECTORY
                inc edx
            .untilcxz
            mov ll.count,edx

            .if edx > 16
                mov edx,16
            .endif
            mov ll.numcel,edx

            mov old_list,tdllist
            lea rdx,ll
            mov tdllist,rdx

            history_event_list(rbx, rdx)
            mov edi,dlevent(rbx)
            dlclose(rbx)

            mov tdllist,old_list
            mov eax,edi
            .if eax
                dec  eax
                add  eax,ll.index
                imul eax,eax,DIRECTORY
                add  rax,history
            .endif
        .endif
    .endif

    mov ecx,rc
    mov rbx,IDD_DZHistory
    mov [rbx].RIDD.rc.x,cl
    mov [rbx].RIDD.rc.y,ch
    ret

GetPathFromHistory endp


SetPathFromHistory proc private uses rbx panel:PPANEL

    .if GetPathFromHistory(panel)

        mov rbx,rax
        panel_setactive(panel)
        DirectoryToCurrentPanel(rbx)
    .endif
    ret

SetPathFromHistory endp


cmahistory proc

    SetPathFromHistory(panela)
    ret

cmahistory endp


cmbhistory proc

    SetPathFromHistory(panelb)
    ret

cmbhistory endp


panel_scrolldn proc private panel:PPANEL

    mov rax,panel
    .if rax == cpanel

        .repeat

            mov rcx,panel
            mov eax,[rcx].PANEL.cel_count
            dec eax

            .ifs ( eax > [rcx].PANEL.cel_index )

                mov [rcx].PANEL.cel_index,eax
                pcell_update(rcx)
                scroll_delay()
            .else
                panel_event(rcx, KEY_DOWN)
            .endif
            scroll_delay()
            mousep()
        .until eax != 1
        mov eax,1
    .else
        panel_setactive(rax)
        xor eax,eax
    .endif
    ret

panel_scrolldn endp


panel_scrollup proc private panel:PPANEL

    mov rax,panel
    .if rax == cpanel

        .repeat

            mov rcx,cpanel
            xor eax,eax

            .if [rcx].PANEL.cel_index != eax

                mov [rcx].PANEL.cel_index,eax
                pcell_update(rcx)
                scroll_delay()
            .else
                panel_event(rcx, KEY_UP)
            .endif
            scroll_delay()
            mousep()
        .until eax != 1
        mov eax,1

    .else

        panel_setactive(rax)
        xor eax,eax
    .endif
    ret

panel_scrollup endp


mouseevent proc private uses rsi rdi rbx

    .while mousep()

        mov edi,keybmouse_x
        mov esi,keybmouse_y

        .if ( cflag & _C_MENUSLINE && !esi )

            mov eax,_scrcol
            sub eax,5

            .if ( edi >= eax )

                cmscreen()
               .break
            .endif
            sub eax,13

            .if ( edi > eax )

                cmcalendar()
            .endif
            .break
        .endif

        .if ( !( cflag & _C_MENUSLINE ) && !esi && edi <= 56 )

            cmxormenubar()
            menus_getevent()
            cmxormenubar()
           .break
        .endif

        .if statusline_xy(edi, esi, 9, &MOBJ_Statusline)

            mov rbx,rax
            msloop()
            [rbx].MSOBJ.cmd()
           .break
        .endif

        mov rbx,panela
        .if !panel_xycmd(rbx, edi, esi)

            mov rbx,panelb
            panel_xycmd(rbx, edi, esi)
        .endif

        .switch eax
        .case 1
        .case 2
            panel_setactive(rbx)
            pcell_setxy(rbx, edi, esi)
           .endc
        .case 3
            panel_scrolldn(rbx)
           .endc
        .case 4
            panel_scrollup(rbx)
           .endc
        .case 5
            .if ( rbx == panela )
                cmachdrv()
            .else
                cmbchdrv()
            .endif
            .endc
        .case 6
            panel_xormini(rbx)
           .endc
        .case 7
            SetPathFromHistory(rbx)
           .endc
        .case 8
            panel_xorinfo(rbx)
           .endc
        .endsw
        xor eax,eax
       .break
    .endw
    ret

mouseevent endp


doszip_modal proc uses rsi

    mov _diskflag,0
    mov mainswitch,1

    .while mainswitch

        .if ( _diskflag )
            ;
            ; 1. mkdir(),rmdir(),osopen(),remove(),rename()
            ; 2. setfattr(),setftime()
            ; 3. process()
            ;
            .if ( _diskflag == 3 )
                ;
                ; Update after extern command
                ;
                SetConsoleTitle(DZTitle)

                .if ( cflag & _C_DELTEMP )

                    removetemp(&cp_ziplst)
                    and cflag,not _C_DELTEMP
                .endif

                mov rax,cpanel
                mov rsi,[rax].PANEL.wsub

                .if filexist([rsi].WSUB.path) != 2

                    mov rax,[rsi].WSUB.path
                    mov byte ptr [rax],0
                    and [rsi].WSUB.flag,not _W_ROOTDIR
                .endif

                .if [rsi].WSUB.flag & _W_ARCHIVE

                    .if filexist([rsi].WSUB.file) != 1

                        and [rsi].WSUB.flag,not _W_ARCHIVE
                    .endif
                .endif
                cominit(rsi)
            .endif
            ;
            ; Clear flag and update panels
            ;
            mov _diskflag,0
            reread_panels()
        .endif


        mov esi,menus_getevent()
        .if ( ( eax == KEY_ENTER || eax == KEY_KPENTER) && com_base && cflag & _C_COMMANDLINE )

            .if doskeysave()

                .continue .if command(&com_base)
            .endif

            comevent(KEY_END)
           .continue
        .endif

        .if com_base && cflag & _C_COMMANDLINE

            .continue .if comevent(esi)
        .endif

        .if cpanel_state()

            .continue .if panel_event(cpanel, esi)
        .endif

        .break .if !mainswitch

        mov eax,esi
        .switch pascal eax
  ifdef DEBUG
          ;.case 0x5400:            cmdebug()   ; Shift-F1
  endif
          .case MOUSECMD:       mouseevent()
          .case KEY_TAB:        panel_toggleact()
          .case KEY_ESC:        cmclrcmdl()
          .case KEY_F1:         cmhelp()
          .case KEY_F2:         cmrename()
          .case KEY_F3:         cmview()
          .case KEY_F4:         cmedit()
          .case KEY_F5:         cmcopy()
          .case KEY_F6:         cmmove()
          .case KEY_F7:         cmmkdir()
          .case KEY_F8:         cmdelete()
          .case KEY_F9:         cmtmodal()
          .case KEY_F10:        cmexit()
          .case KEY_F11:        cmtogglesz()
          .case KEY_F12:        cmtogglehz()
          .case KEY_SHIFTF2:    cmcopycell()
          .case KEY_SHIFTF3:    cmview()
          .case KEY_SHIFTF4:    cmedit()
          .case KEY_SHIFTF5:    cmcompsub()
          .case KEY_SHIFTF6:    cmenviron()
          .case KEY_SHIFTF7:    cmmkzip()
          .case KEY_SHIFTF9:    cmsavesetup()
          .case KEY_SHIFTF10:   cmlastmenu()
          .case KEY_ALTC:       cmxorcmdline()
          .case KEY_ALTL:       cmmklist()
          .case KEY_ALTM:       cmsysteminfo()
          .case KEY_ALTO:       cmcompoption()
          .case KEY_ALTP:       cmloadpath()
          .case KEY_ALTW:       cmcwideview()
          .case KEY_ALTX:       cmquit()
          .case KEY_ALTZ:       cmscreensize()
          .case KEY_ALT0:       cmwindowlist()
          .case KEY_ALT1:       cmtool1()
          .case KEY_ALT2:       cmtool2()
          .case KEY_ALT3:       cmtool3()
          .case KEY_ALT4:       cmtool4()
          .case KEY_ALT5:       cmtool5()
          .case KEY_ALT6:       cmtool6()
          .case KEY_ALT7:       cmtool7()
          .case KEY_ALT8:       cmtool8()
          .case KEY_ALT9:       cmtool9()
          .case KEY_ALTUP:      cmpsizeup()
          .case KEY_ALTDN:      cmpsizedn()
          .case KEY_ALTF1:      cmachdrv()
          .case KEY_ALTF2:      cmbchdrv()
          .case KEY_ALTF3:      cmview()
          .case KEY_ALTF4:      cmedit()
          .case KEY_ALTF5:      cmcompress()
          .case KEY_ALTF6:      cmdecompress()
          .case KEY_ALTF8:      cmhistory()
          .case KEY_ALTF9:      cmegaline()
          .case KEY_ALTF7:      cmsearch()
          .case KEY_CTRLTAB:    cmsearch()
          .case KEY_CTRL0:      cmpath0()
          .case KEY_CTRL1:      cmpath1()
          .case KEY_CTRL2:      cmpath2()
          .case KEY_CTRL3:      cmpath3()
          .case KEY_CTRL4:      cmpath4()
          .case KEY_CTRL5:      cmpath5()
          .case KEY_CTRL6:      cmpath6()
          .case KEY_CTRL7:      cmpath7()
          .case KEY_CTRL8:      cmpathatocmd()
          .case KEY_CTRL9:      cmpathbtocmd()
          .case KEY_CTRLF1:     cmatoggle()
          .case KEY_CTRLF2:     cmbtoggle()
          .case KEY_CTRLF3:     cmview()
          .case KEY_CTRLF4:     cmedit()
          .case KEY_CTRLF5:     cmcname()
          .case KEY_CTRLF6:     toption()
          .case KEY_CTRLF7:     cmscreen()
          .case KEY_CTRLF8:     cmsystem()
          .case KEY_CTRLF9:     cmoptions()
          .case KEY_CTRLA:      cmattrib()
          .case KEY_CTRLB:      cmuserscreen()
          .case KEY_CTRLC:      cmcompare()
          .case KEY_CTRLD:      cmcdate()
          .case KEY_CTRLE:      cmctype()
          .case KEY_CTRLF:      cmconfirm()
          .case KEY_CTRLG:      cmcalendar()
          .case KEY_CTRLH:      cmchidden()
          .case KEY_CTRLI:      cmsubinfo()
          .case KEY_CTRLJ:      cmcompression()
          .case KEY_CTRLK:      cmxorkeybar()
          .case KEY_CTRLL:      cmclong()
          .case KEY_CTRLM:      cmcmini()
          .case KEY_CTRLN:      cmcname()
          .case KEY_CTRLO:      cmtoggleon()
          .case KEY_CTRLP:      cmpanel()
          .case KEY_CTRLQ:      cmquicksearch()
          .case KEY_CTRLR:      cmcupdate()
          .case KEY_CTRLS:      cmsearch()
          .case KEY_CTRLT:      cmcdetail()
          .case KEY_CTRLU:      cmcnosort()
          .case KEY_CTRLV:      cmvolinfo()
          .case KEY_CTRLW:      cmswap()
          .case KEY_CTRLX:      cmxormenubar()
          .case KEY_CTRLZ:      cmcsize()
          .case KEY_CTRLUP:     cmdoskeyup()
          .case KEY_CTRLDN:     cmdoskeydown()
          .case KEY_CTRLPGUP:   cmupdir()
          .case KEY_CTRLPGDN:   cmsubdir()
          .case KEY_CTRLENTER:  cmcfblktocmd()
          .case KEY_KPPLUS:     cmselect()
          .case KEY_KPMIN:      cmdeselect()
          .case KEY_KPSTAR:     cminvert()
          .case KEY_CTRLHOME:   cmhomedir()
          .default
            comevent(esi)
        .endsw
        msloop()
    .endw
    ret

doszip_modal endp

    end
