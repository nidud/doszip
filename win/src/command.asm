; COMMAND.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include tview.inc
include process.inc
include string.inc
include malloc.inc
include stdio.inc
include stdlib.inc
include io.inc
include config.inc

    .data

com_wsub  PWSUB path_a
com_base  char_t WMAXPATH dup(0)
com_info  TEDIT {com_base,_TE_OVERWRITE,0,24,80,WMAXPATH,0,0,0,0,0,0x070020 }

    .code

comhndlevent proc private event:uint_t

    xor eax,eax
    .if ( cflag & _C_COMMANDLINE )

        _cursoron()
        dledite(&com_info, event)
    .endif
    ret
comhndlevent endp

cominit proc wsub:PWSUB

    ldr rax,wsub
    mov com_wsub,rax
    wsinit(rax)

    cominitline()
    mov eax,1
    ret

cominit endp

    assume rsi:PWSUB

cominitline proc private uses rsi rdi rbx

    mov rbx,DLG_Commandline
    .if rbx && [rbx].DOBJ.flag & _D_DOPEN

        movzx eax,[rbx].DOBJ.rc.x
        movzx edx,[rbx].DOBJ.rc.y
        mov com_info.ypos,edx
        mov com_info.xpos,eax
        mov rsi,com_wsub
        strlen([rsi].path)
        inc eax
        .if eax > 51
            mov eax,51
        .endif
        mov com_info.xpos,eax
        mov edx,_scrcol
        sub edx,eax
        mov com_info.cols,edx
        _gotoxy(eax, com_info.ypos)

        .if ( [rbx].DOBJ.flag & _D_ONSCR )

            mov edi,com_info.ypos
            scputw(0, edi, _scrcol, ' ')
            scpath(0, edi, 50, [rsi].path)
            mov al,byte ptr com_info.xpos
            dec al
            scputw(eax, edi, 1, 62) ; '>'
            comhndlevent(KEY_PGUP)
        .else
            mov rdi,[rbx].DOBJ.wp
            wcputw(rdi, _scrcol, ' ')
            mov eax,com_info.xpos
            lea rax,[rdi+rax*4-8]
            wcputw(rax, 1, 62)
            wcpath(rdi, 50, [rsi].path)
        .endif
    .endif
    ret

cominitline endp

comshow proc

    mov eax,com_info.ypos
    lea rcx,prect_b
    .if !(byte ptr [rcx] & _D_ONSCR)

        lea rcx,prect_a
    .endif

    .if (byte ptr [rcx] & _D_ONSCR)

        mov dl,[rcx].DOBJ.rc.y
        add dl,[rcx].DOBJ.rc.row
        .if dl > al

            mov al,dl
        .endif
    .endif

    .if !eax && cflag & _C_MENUSLINE

        inc eax
    .endif

    .if eax >= _scrrow && cflag & _C_STATUSLINE

        dec eax
    .endif

    .if eax > _scrrow

        mov eax,_scrrow
    .endif

    mov byte ptr com_info.ypos,al
    mov rdx,DLG_Commandline
    mov [rdx+5],al

    .if cflag & _C_COMMANDLINE

        _gotoxy(0, eax)
        _cursoron()
        dlshow(DLG_Commandline)
        cominitline()
    .endif
    ret

comshow endp

comhide proc
    dlhide(DLG_Commandline)
    _cursoroff()
    ret
comhide endp

comevent proc event

    mov eax,event
    .switch eax
      .case KEY_UP
        .ifd cpanel_state()

            xor eax,eax
        .else
            cmdoskeyup()
            mov eax,1
        .endif
        .endc
      .case KEY_DOWN
        .ifd cpanel_state()

            xor eax,eax
        .else
            cmdoskeydown()
            mov eax,1
        .endif
        .endc
      .case KEY_ALTRIGHT
        cmpathright()
        mov eax,1
        .endc
      .case KEY_ALTLEFT
        cmpathleft()
        mov eax,1
        .endc
      .case 0
      .case KEY_CTRLX
        xor eax,eax
        .endc
      .default
        .ifd comhndlevent(eax)
            xor eax,eax
        .else
            mov eax,1
        .endif
    .endsw
    ret
comevent endp

clrcmdl proc
    .if cflag & _C_COMMANDLINE

        mov com_base,0
        comevent(KEY_HOME)
        cominitline()
    .endif
    ret
clrcmdl endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; command
;
command proc uses rsi rdi rbx cmd:string_t ; BOOL

  local cursor:CURSOR, batch:string_t, path:string_t, temp:string_t
  local UpdateEnviron:uint_t, CallBatch:uint_t, size:uint_t

    mov eax,console
    and eax,CON_NTCMD
    CFGetComspec(eax)

    mov rdi,alloca(0x8000 + _MAX_PATH*2 + 32)
    add rax,0x8000
    mov batch,rax
    mov byte ptr [rax],0
    add rax,_MAX_PATH
    mov path,rax
    add rax,_MAX_PATH
    mov temp,rax

    mov rdx,cmd
    .while byte ptr [rdx] == ' '

        add rdx,1
    .endw

    .return .ifd !strtrim(strnzcpy(rdi, rdx, 8000h-1))

    expenviron(rdi)

    .if byte ptr [rdi] == '%'

        ; %view% <filename>
        ; %edit% <filename>
        ; %find% [<directory>] [<file_mask(s)>] [<text_to_find_in_files>]

        .switch

          .case !_strnicmp(rdi, "%view%", 6)

            load_tview(addr [rdi+7], 0)
            .return 1

          .case !_strnicmp(rdi, "%edit%", 6)

            load_tedit(addr [rdi+7], 4)
            .return 1

          .case !_strnicmp(rdi, "%find%", 6)

            .if byte ptr [rdi+6] == ' '

                add rdi,7
                strchr(rdi, ' ')
                mov rcx,rdi
                mov rdi,rax
                .if strrchr(rcx, ' ')

                    mov byte ptr [rdi],0    ; end of first arg
                    mov byte ptr [rax],0    ; start of last arg - 1
                    .if byte ptr [rax+1] != '?' && rax != rdi

                        inc rax
                        strcpy(&searchstring, rax)
                    .endif

                    .if byte ptr [rdi+1] != '?'

                        strcpy(&findfilemask, &[rdi+1])
                    .endif
                .endif
                .return FindFile(&[rdi+7])
            .endif
            cmsearch()
            .return 1
          .default
            .return 0
        .endsw
    .endif

    clrcmdl()

    xor eax,eax
    mov CallBatch,eax
    mov UpdateEnviron,eax

    ; use batch for old .EXE files, \r\n, > and <

    .switch
    .case strchr(rdi, '>')
    .case strchr(rdi, '<')
    .case strchr(rdi, 10)
        jmp create_batch
    .endsw

    ; case exit

    mov eax,[rdi]
    or  eax,0x20202020

    .if eax == 'tixe' && byte ptr [rdi+4] <= ' '

        .return cmquit()
    .endif

    ; Inline CD and C: commands

    mov rdx,rdi
    mov ecx,1

    .if word ptr [rdi+1] != ':'

        mov eax,[rdi]
        or  ax,0x2020

        .if ax != 'dc'

            xor ecx,ecx

        .else

            add rdx,2

            mov al,[rdx]

            .if al != ' ' && al != '.' && al != '\'

                xor ecx,ecx
            .endif
        .endif
    .endif

    .if ecx

        mov rsi,rdx
        .while byte ptr [rsi] == ' '

            add rsi,1
        .endw

        .ifd SetCurrentDirectory(rsi)

            .ifd GetCurrentDirectory(_MAX_PATH, rsi)

                cpanel_setpath(rsi)
                mov _diskflag,3
            .endif
        .endif
        .return
    .endif


    ; Parse the first token

    mov rbx,strnzcpy(path, rdi, _MAX_PATH-1)
    strtrim(rbx)
    test eax,eax
    jz execute_command

    .if byte ptr [rbx] == '"'

        .if strchr(strcpy(rbx, &[rbx+1]), '"')

            mov byte ptr [rax],0
        .elseif strchr(rbx, ' ')
            mov byte ptr [rax],0
        .endif
    .elseif strchr(rbx, ' ')
        mov byte ptr [rax],0
    .endif

    .if !searchp(rbx, rbx)
        ;
        ; Not an executable file
        ;
        ; SET and FOR may change the environment
        ;
        __isexec(rbx)
        test eax,eax
        jnz execute_command
        mov eax,[rbx]
        and eax,00FFFFFFh
        or  eax,00202020h
        .switch eax
          ;
          ; Change or set environment variable
          ;
          .case 'tes'   ; SET
          .case 'rof'   ; FOR
            mov al,[rdi+3]
            .switch al
              .case ' '
              .case 9
                inc UpdateEnviron
                jmp create_batch
            .endsw
        .endsw
        jmp execute_command
    .endif

    .switch __isexec(rbx)
      .case _EXEC_EXE
        .if comspec_type == 0

            .ifd osopen(rbx, 0, M_RDONLY, A_OPEN) != -1

                mov esi,eax
                mov size,osread(esi, temp, 32)
                _close(esi)

                .if size == 32

                    mov rsi,temp
                    mov ax,[rsi+24]
                    .if ax == 0040h

                        xor eax,eax
                        .if eax != [rsi+20]

                            jmp create_batch
                        .endif
                    .endif
                .endif
            .endif
        .endif
        jmp execute_command
      .case _EXEC_CMD
      .case _EXEC_BAT
        mov CallBatch,eax
        mov UpdateEnviron,eax
      .case _EXEC_COM
        jmp create_batch
    .endsw

create_batch:

    mov eax,console
    and eax,CON_CMDENV
    .if !eax

        mov CallBatch,eax
        mov UpdateEnviron,eax
    .endif

    .if CreateBatch(rdi, CallBatch, UpdateEnviron) != -1

        strcpy(batch, rax)
    .endif


execute_command:

    doszip_hide()
    _gotoxy(0, com_info.ypos)
    _cursoron()
    system(rdi)
    mov size,eax

    .if UpdateEnviron

        strfcat(rdi, envtemp, "dzcmd.env")
        ReadEnvironment(rdi)
        removefile(rdi)
        GetEnvironmentTEMP()
        GetEnvironmentPATH()
        .ifd !GetCurrentDirectory(WMAXPATH, rdi)

            xor edi,edi
        .endif
    .endif

    doszip_show()
    SetKeyState()

    mov rax,batch
    .if byte ptr [rax]

        removefile(rax)
    .endif

    .if UpdateEnviron && rdi

        cpanel_setpath(rdi)
    .endif
    mov eax,size
    ret

command endp

    END

