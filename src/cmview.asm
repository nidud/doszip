; CMVIEW.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include io.inc
include dzstr.inc
include stdlib.inc
include process.inc
include config.inc
include tview.inc
include doszip.inc
include progress.inc

    .code

; type 4: F4    - edit
; type 3: Alt   - edit/view
; type 2: Ctrl  - edit/view
; type 1: Shift - edit/view
; type 0: F3    - view

loadiniproc proc uses rsi rdi section:LPSTR, filename:LPSTR, itype:int_t

  local path[_MAX_PATH]:char_t

    ldr rdi,filename
    ldr eax,itype
    lea rsi,@CStr("F3")

    .switch al
      .case 4 : lea rsi,@CStr("F4")    : .endc
      .case 3 : lea rsi,@CStr("Alt")   : .endc
      .case 2 : lea rsi,@CStr("Ctrl")  : .endc
      .case 1 : lea rsi,@CStr("Shift") : .endc
    .endsw

    .if CFGetSection(section)

        .if INIGetEntry(rax, rsi)

            mov rsi,rax
            mov esi,strlen(strnzcpy(&path, rsi, _MAX_PATH - 1))
            add strlen(rdi),rsi

            .if eax < _MAX_PATH

                CFExpandMac(&path, rdi)
                command(&path)
                mov eax,1
            .else
                xor eax,eax
            .endif
        .endif
    .endif
    ret

loadiniproc endp

load_tview proc uses rsi rdi filename:LPSTR, etype:int_t

   .new offs:size_t = 0

    ldr rdi,filename
    .if !loadiniproc("View", rdi, etype)

        clrcmdl()
        mov rsi,rdi

        .while 1 ; %view% [-options] [file]

            lodsb
            .break .if !al
            .if ( al == '"' )
                mov rdi,rsi ; start of "file name"
                .repeat
                    lodsb
                    .if ( al == 0 )
                        .return ermsg(0, "TVIEW error: %s", rdi)
                    .endif
                .until al == '"'
                xor eax,eax
                mov [rsi-1],al
               .break
            .elseif ( al == '/' && byte ptr [rsi-2] == ' ' )
                lodsb
                or  al,' '
                .if al == 't'
                    and tvflag,not _TV_HEXVIEW
                .elseif al == 'h'
                    or  tvflag,_TV_HEXVIEW
                .elseif al == 'o'       ; -o<offset> - Start offset
                    mov offs,strtolx(rsi)
                .else
                    .return ermsg(0, "TVIEW error: %s", rdi)
                .endif
                .repeat
                    lodsb
                .until al <= ' '
                .break .if !al
                mov rdi,rsi
            .endif
        .endw
        tview(rdi, offs)
    .endif
    ret

load_tview endp

TVGetCurrentFile proc uses rdi buffer:LPSTR

    xor edi,edi     ; 0 (F3 or F4)
    mov rax,keyshift
    mov eax,[rax]

    .if eax & SHIFT_KEYSPRESSED

        mov edi,1
    .elseif al & KEY_CTRL   ; 2 (Ctrl)

        mov edi,2
    .elseif al & KEY_ALT    ; 3 (Alt)

        mov edi,3
    .endif

    .if panel_curobj(cpanel)

        xchg rax,rcx
        .if eax & _FB_ARCHIVE

            .if eax & _A_SUBDIR

                xor eax,eax     ; 0 (subdir in archive)
            .else

                .if eax & _FB_ARCHEXT

                    mov eax,4   ; 4 (plugin)
                .else

                    mov eax,2   ; 2 (zip)
                .endif
            .endif
        .elseif eax & _A_SUBDIR

            mov eax,3           ; 3 (subdir)
        .else

            mov rax,cpanel          ; 1 (file)
            mov rax,[rax].PANEL.wsub
            mov rax,[rax].WSUB.path

            strfcat(buffer, rax, rcx)

            mov eax,1
        .endif
    .endif
    mov ecx,edi
    ret

TVGetCurrentFile endp

unzip_to_temp proc uses rsi rdi fblk:PFBLK, name_buffer:LPSTR

    mov rdi,fblk
    .if envtemp

        progress_open("Unzip file to TEMP", "Copy")
        progress_set([rdi].FBLK.name, envtemp, [rdi].FBLK.size)
        mov rax,cpanel
        wsdecomp([rax].PANEL.wsub, rdi, envtemp)

        .ifd !progress_close()

            strfcat(name_buffer, envtemp, [rdi].FBLK.name)
        .else
            xor eax,eax
        .endif
    .else
        ermsg(0, "Bad or missing TEMP directory")
    .endif
    test eax,eax
    ret

unzip_to_temp endp

viewzip proc private uses rdi

    mov edi,ecx
    mov rcx,rdx

    .ifd unzip_to_temp(rcx, rbx)

        load_tview(rax, edi)

        mov rdi,_utftows(rbx)
        _wsetfattr(rdi, 0)
        _wremove(rdi)
        mov eax,1
    .endif
    ret

viewzip endp

cmview proc uses rbx

  local fname[_MAX_PATH*2]:byte

    lea rbx,fname

    .switch TVGetCurrentFile(rbx)

      .case 1
        load_tview(rbx, ecx)
        .endc
      .case 2
        viewzip()
        .endc
      .case 4
        mov rax,cpanel
        mov rax,[rax].PANEL.wsub
        warcview(rax, rdx)
        .endc
      .case 3
        cmsubsize()
        .endc
    .endsw
    ret

cmview endp

    END
