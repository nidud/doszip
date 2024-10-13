; HEDIT.ASM--
; Copyright (C) 2017 Doszip Developers -- see LICENSE.TXT
;
; Change history:
; 2017-10-19 - added ClassMode
; 2017-10-14 - created
;
include dzstr.inc
include stdio.inc
include stdlib.inc
include errno.inc
include syserr.inc
include ltype.inc
include doszip.inc
include config.inc

define _USEMLINE   0x01
define _USESLINE   0x02
define _HEXOFFSET  0x04
define _CLASSMODE  0x08

define _MAXL       64
define _MAXTEXT    49

define T_STRING    0x01
define T_BINARY    0x02
define T_BYTE      0x04
define T_WORD      0x08
define T_DWORD     0x10
define T_QWORD     0x20
define T_SIGNED    0x40
define T_HEX       0x80

define T_NUMBER    (T_BYTE or T_WORD or T_DWORD or T_QWORD)
define T_ARRAY     (T_STRING or T_BINARY)

.template LINE
    flags db ?
    bytes db ?
    boffs dw ?
   .ends
    PLINE typedef ptr LINE

   .data
    x_cpos db 12,15,18,21,24,27,30,33,38,41,44,47,50,53,56,59

   .code

    option proc: private

savefile proc uses rsi rdi rbx file:LPSTR, buffer:ptr, fsize:dword

  local path[1024]:byte
  local flags:dword
    lea rdi,path

    .ifd getfattr(strcpy(rdi, file)) == -1

        .return( 0 )
    .endif

    mov flags,eax
    .if eax & _A_RDONLY

        ermsg(0, "The file is Read-Only")
    .endif

    .ifsd ogetouth(strfxcat(rdi, ".$$$"), M_WRONLY) <= 0

        .return( 0 )
    .endif
    mov esi,eax
    mov ebx,fsize
    .ifd oswrite(esi, buffer, ebx) != ebx
        xor ebx,ebx
    .endif
    _close(esi)
    .if ebx
        _wremove(_utftows(file))
        rename(rdi, file)
        mov eax,1
    .else
        mov eax,ebx
    .endif
    ret

savefile endp

LToString proc uses rsi rdi lp:ptr LINE, source:LPSTR, dest:LPSTR

    ldr rcx,lp
    ldr rdi,source
    ldr rsi,dest

    movzx eax,[rcx].LINE.flags
    mov ecx,eax
    and eax,T_BYTE or T_WORD or T_DWORD or T_QWORD

    .switch eax

    .case T_BYTE
        movzx edx,byte ptr [rdi]
        lea rax,@CStr("%u")
        .if cl & T_SIGNED
            lea rax,@CStr("%i")
            movsx edx,dl
        .elseif cl & T_HEX
            lea rax,@CStr("%02X")
        .endif
        sprintf(rsi, rax, edx)
       .endc

    .case T_WORD
        movzx edx,word ptr [rdi]
        lea rax,@CStr("%u")
        .if cl & T_SIGNED
            lea rax,@CStr("%i")
            movsx ecx,cx
        .elseif cl & T_HEX
            lea rax,@CStr("%04X")
        .endif
        sprintf(rsi, rax, edx)
       .endc

    .case T_DWORD
        lea rax,@CStr("%u")
        .if cl & T_SIGNED
            lea rax,@CStr("%i")
        .elseif cl & T_HEX
            lea rax,@CStr("%08X")
        .endif
        mov ecx,[rdi]
        sprintf(rsi, rax, ecx)
       .endc

    .case T_QWORD
        lea rax,@CStr("%llu")
        .if cl & T_SIGNED
            lea rax,@CStr("%lld")
        .elseif cl & T_HEX
            lea rax,@CStr("%016llX")
        .endif
        sprintf(rsi, rax, qword ptr [rdi])
       .endc
    .endsw
    ret

LToString endp

local_update proc
    xor eax,eax
    ret
local_update endp

hedit proc public uses rsi rdi rbx file:LPSTR, loffs:DWORD

  local \
    dialog      :PDOBJ,     ; main dialog pointer
    cdialog     :PDOBJ,     ; class dialog
    rowcnt      :UINT,      ; screen lines
    lcount      :UINT,      ; lines on screen
    cline       :UINT,      ; current line
    scount      :UINT,      ; bytes on screen
    bcount      :UINT,      ; screen size in bytes (page)
    screen      :PDWORD,    ; screen buffer
    cools       :size_t,
    update      :DPROC,
    p           :LPSTR,
    q           :LPSTR,
    n           :UINT,
    menusline   :PDOBJ,     ; dialogs for F11/Ctrl-S/Ctrl-M
    statusline  :PDOBJ,
    fsize       :UINT,      ; file size
    fbuff       :LPSTR,     ; file buffer
    index       :dword,     ; x index into x_cpos table
    x           :dword,     ; x pos from LEFT/RIGHT
    lbuff[512]  :byte,
    lbc[_MAXL]  :LINE,      ; class table
    lbh[_MAXL]  :LINE,      ; hex table
    lptr        :PLINE,     ; pointer to active table
    rc          :TRECT,     ; edit text pos
    dlgobj      :DOBJ,
    cursor      :CURSOR,
    flags       :byte,      ; main flags
    rsrows      :byte,      ; rect-line count
    modified    :byte

    mov rc.x,12
    mov rc.y,1
    mov rc.col,_MAXTEXT
    mov rc.row,1

    mov ecx,_MAXL
    lea rdi,lbh
    mov eax,0x1000
    rep stosd
    mov ecx,_MAXL
    mov eax,0x0104
    rep stosd

    xor eax,eax
    lea rdi,STDI
    mov ecx,IOST
    rep stosb

    mov cline,eax
    mov index,eax
    mov x,12
    mov modified,al
    mov STDI.flag,eax

    mov ecx,_scrrow
    mov eax,_scrcol
    mov cools,rax
    inc cl
    mov rsrows,cl

    mov flags,_USEMLINE or _USESLINE or _HEXOFFSET

    .if CFGetSection(".hexedit")

        mov rbx,rax
        .if INIGetEntry(rbx, "Flags")

            __xtol(rax)
            mov flags,al
        .endif
        .for ( edi = 0 : edi < _MAXL: edi++ )

            .break .if !INIGetEntryID(rbx, edi)

            __xtol(rax)
            mov lbc[rdi*4].bytes,al
            mov lbc[rdi*4].flags,ah
        .endf
    .endif

    movzx eax,rsrows
    .if flags & _USEMLINE
        dec eax
    .endif
    .if flags & _USESLINE
        dec eax
    .endif
    mov rowcnt,eax ; adapt to current screen size
    add eax,2
    mul _scrcol
    mov esi,eax

    lea rax,lbh
    .if flags & _CLASSMODE
        lea rax,lbc
    .endif
    mov lptr,rax

    .ifd ( osopen(file, 0, M_RDONLY, A_OPEN) == -1 )

        .return( 0 )
    .endif

    mov ebx,eax
    _filelength(ebx)

    .if ( ( !eax && !edx ) || edx )

        .if edx
            ermsg(0, _sys_err_msg(ENOMEM))
        .endif
        _close(ebx)
        .return( 0 )
    .endif

    mov fsize,eax
    mov STDI.flag,IO_MEMBUF
    mov STDI.cnt,eax
    mov STDI.fsize_l,eax

    add eax,esi
    .if !malloc(eax)

        ermsg(0, _sys_err_msg(ENOMEM))
        _close(ebx)
        .return( 0 )
    .endif

    mov screen,rax
    add rax,rsi
    mov fbuff,rax
    mov STDI.base,rax
    osread(ebx, rax, fsize)
    _close(ebx)

    mov al,at_background[B_TextView]
    or  al,at_foreground[F_TextView]
    .if !dlscreen(&dlgobj, eax)

        free(screen)
       .return( 1 )
    .endif

    mov dialog,rax
    dlshow(rax)
    mov rdi,rsopen(IDD_HEMenusline)
    mov rbx,rsopen(IDD_HEStatusline)
    mov ecx,_scrrow
    mov eax,_scrcol
    mov [rdi].DOBJ.rc.col,al
    mov [rbx].DOBJ.rc.col,al
    mov [rbx].DOBJ.rc.y,cl
    mov menusline,rdi
    mov statusline,rbx
    dlshow(rdi)
    .if flags & _USESLINE
        dlshow(rbx)
    .endif

    scpath(1, 0, 41, file)
    mov ecx,_scrcol
    sub ecx,38
    scputf(ecx, 0, 0, 0, "%12u byte", fsize)
    mov ecx,_scrcol
    sub ecx,5
    scputs(ecx, 0, 0, 0, "100%")

    .if !( flags & _USEMLINE )

        dlhide(menusline)
    .endif

    _getcursor(&cursor)
    _cursoron()

    mov update,tupdate
    mov tupdate,&local_update

    msloop()
    mov esi,1

    .while 1

        .if esi

            mov eax,cline
            .if flags & _USEMLINE
                inc eax
            .endif
            _gotoxy(x, eax)

            mov eax,_scrcol
            mul rowcnt
            mov ecx,eax
            mov rdi,screen
            mov eax,0x20
            rep stosb

            mov esi,fsize
            sub esi,loffs

            .for ( rbx = lptr,
                   edx = 0,
                   ecx = 0 : edx < esi, ecx < rowcnt: ecx++ )

                movzx eax,[rbx+rcx*4].LINE.bytes
                mov [rbx+rcx*4].LINE.boffs,dx
                add edx,eax
            .endf
            .if edx > esi
                mov edx,esi
            .endif
            mov scount,edx
            mov lcount,ecx

            .for ( : edx < esi && ecx < rowcnt : ecx++ )

                movzx eax,[rbx+rcx*4].LINE.bytes
                mov [rbx+rcx*4].LINE.boffs,dx
                add edx,eax
            .endf
            mov bcount,edx

            .for ( rsi = screen, ebx = 0 : ebx < lcount : ebx++, rsi += cools )

                lea rax,@CStr("%010u  ")
                .if flags & _HEXOFFSET
                    lea rax,@CStr("%010X  ")
                .endif
                mov rdx,lptr
                movzx edi,[rdx+rbx*4].LINE.boffs
                add edi,loffs
                sprintf(rsi, rax, edi)

                mov ecx,fsize
                sub ecx,edi
                add rdi,fbuff

                mov rdx,lptr
                movzx eax,[rdx+rbx*4].LINE.flags
                and eax,T_NUMBER or T_ARRAY

                .switch eax
                .case T_STRING
                    push rsi
                    xchg rsi,rdi
                    movzx eax,[rdx+rbx*4].LINE.bytes
                    .if ecx > eax
                        mov ecx,eax
                    .endif
                    add rdi,12
                    .if ecx > _MAXTEXT
                        mov ecx,_MAXTEXT
                    .endif
                    rep movsb
                    pop rsi
                    lea rcx,[rsi+51+12]
                    sprintf(rcx, "CHAR[%u]", eax)
                   .endc

                .case T_BINARY
                    movzx eax,[rdx+rbx*4].LINE.bytes
                    .if ecx > eax
                        mov ecx,eax
                    .endif
                    .if ecx > _MAXTEXT
                        mov ecx,_MAXTEXT
                    .endif
                    mov n,eax
                    mov p,rsi
                    mov q,rdi
                    mov ebx,ecx
                    mov rsi,rdi
                    lea rdi,lbuff
                    rep movsb
                    lea rsi,lbuff
                    btohex(rsi, ebx)
                    mov ecx,ebx
                    add ecx,ecx
                    .if ecx > _MAXTEXT
                        mov ecx,_MAXTEXT
                    .endif
                    mov rbx,q
                    mov rdi,p
                    add rdi,12
                    rep movsb
                    mov rsi,p
                    lea rcx,[rsi+51+12]
                    sprintf(rcx, "BYTE[%u]", n)
                   .endc

                .case T_BYTE
                .case T_WORD
                .case T_DWORD
                .case T_QWORD
                    mov n,eax
                    lea rax,[rsi+12]
                    lea rcx,[rdx+rbx*4]
                    mov q,rcx
                    LToString(rcx, rdi, rax)
                    mov rdx,q
                    mov eax,n
                    movzx edx,[rdx].LINE.flags
                    lea rcx,@CStr("unsigned")
                    .if edx & T_SIGNED
                        lea rcx,@CStr("signed")
                    .elseif edx & T_HEX
                        lea rcx,@CStr("hexadecimal")
                    .endif
                    lea rdx,@CStr("BYTE")
                    .if eax == T_DWORD
                        lea rdx,@CStr("DWORD")
                    .elseif eax == T_WORD
                        lea rdx,@CStr("WORD")
                    .elseif eax == T_QWORD
                        lea rdx,@CStr("QWORD")
                    .endif
                    lea rax,[rsi+51+12]
                    sprintf(rax, "%s(%s)", rdx, rcx)
                   .endc

                .default
                    .if ecx > 16
                        mov ecx,16
                    .endif
                    mov n,ebx
                    mov p,rsi
                    xchg rsi,rdi
                    add rdi,12
                    lea rbx,[rdi+51]
                    xor edx,edx
                    .repeat
                        .if edx == 8
                            mov al,179
                            stosb
                            inc rdi
                        .endif
                        lodsb
                        mov [rbx],al
                        .if !al
                            mov byte ptr [rbx],' '
                        .endif
                        mov ah,al
                        and eax,0x0FF0
                        shr al,4
                        or  eax,0x3030
                        .if ah > 0x39
                            add ah,7
                        .endif
                        .if al > 0x39
                            add al,7
                        .endif
                        stosw
                        inc rdi
                        inc rbx
                        inc edx
                    .untilcxz
                    mov rsi,p
                    mov ebx,n
                .endsw
                mov eax,1
            .endf

            .if eax

                .if flags & _USEMLINE

                    mov eax,scount
                    add eax,loffs
                    .ifz
                        mov eax,100
                    .else
                        mov ecx,100
                        mul ecx
                        mov ecx,fsize
                        div ecx
                        and eax,0x7F
                        .if eax > 100
                            mov eax,100
                        .endif
                    .endif
                    mov ecx,_scrcol
                    sub ecx,5
                    scputf(ecx, 0, 0, 0, "%3d", eax)
                    .if modified
                        scputc(0, 0, 1, '*')
                    .else
                        scputc(0, 0, 1, ' ')
                    .endif
                .endif

                .if flags & _USESLINE

                    mov rdx,statusline
                    movzx rdx,[rdx].DOBJ.rc.y
                    .if flags & _CLASSMODE
                        lea rax,@CStr("Hex  ")
                    .else
                        lea rax,@CStr("Class")
                    .endif
                    scputs(42, edx, 0, 5, rax)
                .endif
                mov eax,fsize
                .if eax
                    xor eax,eax
                    .if flags & _USEMLINE
                        inc eax
                    .endif
                    putscreenb(eax, rowcnt, screen)
                .endif
            .endif
        .endif

        mov ebx,cline
        mov rdx,lptr
        mov al,[rdx+rbx*4].LINE.flags
        and al,T_ARRAY or T_NUMBER

        .if al

            mov ecx,fsize
            movzx esi,[rdx+rbx*4].LINE.boffs
            add esi,loffs
            sub ecx,esi
            add rsi,fbuff
            lea rdi,lbuff

            mov p,rsi
            mov q,rdi

            .switch al
            .case T_STRING
                movzx eax,[rdx+rbx*4].LINE.bytes
                .if ecx > eax
                    mov ecx,eax
                .endif
                rep movsb
                mov byte ptr [rdi],0
               .endc
            .case T_BINARY
                movzx eax,[rdx+rbx*4].LINE.bytes
                .if ecx > eax
                    mov ecx,eax
                .endif
                mov n,ecx
                rep movsb
                btohex(&lbuff, n)
               .endc
            .case T_BYTE
            .case T_WORD
            .case T_DWORD
            .case T_QWORD
                lea rcx,[rdx+rbx*4]
                LToString(rcx, rsi, rdi)
               .endc
            .endsw
            mov rdi,q
            mov rsi,p

            mov eax,ebx
            mov rdx,lptr
            lea rbx,[rdx+rbx*4]
            .if flags & _USEMLINE
                inc eax
            .endif
            mov rc.y,al
            mov ecx,256
            .if [rbx].LINE.flags & T_BINARY
                shl ecx,1
            .endif
            mov n,dledit(rdi, rc, ecx, 0)
            .if !( [rbx].LINE.flags & T_STRING )
                .if [rbx].LINE.flags & T_BINARY
                    hextob(rdi)
                .else
                    .if [rbx].LINE.flags & T_HEX
                        __xtoi64(rdi)
                    .else
                        _atoi64(rdi)
                    .endif
ifdef _WIN64
                    mov [rdi],rax
else
                    mov dword ptr [rdi],eax
                    mov dword ptr [rdi+4],edx
endif
                .endif
            .endif
            mov ecx,fsize
            movzx eax,[rbx].LINE.boffs
            movzx ebx,[rbx].LINE.bytes
            add eax,loffs
            add eax,ebx
            .if eax > ecx
                sub eax,ebx
                .if ecx >= eax
                    sub ecx,eax
                    mov ebx,ecx
                .else
                    xor ebx,ebx
                .endif
            .endif
            .if ebx
                .ifd memcmp(rsi, rdi, ebx)
                    memcpy(rsi, rdi, ebx)
                    mov modified,1
                .endif
            .endif
            mov eax,n
        .else
            tgetevent()
        .endif

        xor esi,esi
        mov ebx,cline
        mov rdi,lptr
        lea rdi,[rdi+rbx*4]

        .switch eax
        .case MOUSECMD

            .endc .ifd mousep() == 2
            .endc .if !eax
            mousey()
            inc eax
            .endc .if ( !( flags & _USESLINE ) || al != rsrows )
            msloop()
            mousex()
            .if al && al <= 7
                .gotosw(KEY_F1)
            .endif
            .if al >= 10 && al <= 16
                .gotosw(KEY_F2)
            .endif
            .if al >= 19 && al <= 27
                .gotosw(KEY_F3)
            .endif
            .if al >= 30 && al <= 36
                .gotosw(KEY_F4)
            .endif
            .if al >= 39 && al <= 46
                .gotosw(KEY_F5)
            .endif
            .if al >= 49 && al <= 57
                .gotosw(KEY_F6)
            .endif
            .if al >= 71 && al <= 78
                .gotosw(KEY_F10)
            .endif
            msloop()
           .endc

        .case KEY_F1
            view_readme(HELPID_16)
           .endc
        .case KEY_F2
            .ifd savefile(file, fbuff, fsize)
                mov modified,0
                mov esi,1
            .endif
            .endc
        .case KEY_F3
            and STDI.flag,not IO_SEARCHMASK
            mov eax,fsflag
            and eax,IO_SEARCHMASK
            or  STDI.flag,eax
            xor eax,eax
            .if fsize >= 16
                .ifd cmsearchidd(STDI.flag)
                    mov STDI.flag,edx
                    and edx,IO_SEARCHCUR or IO_SEARCHSET
                    mov n,edx
                    continuesearch(&loffs)
                    mov edx,n
                    or  STDI.flag,edx
                .endif
            .endif
            and fsflag,not IO_SEARCHMASK
            mov ecx,STDI.flag
            and STDI.flag,not (IO_SEARCHSET or IO_SEARCHCUR)
            and ecx,IO_SEARCHMASK
            or  fsflag,ecx
            .if eax
                inc esi
            .endif
            .endc

        .case KEY_F4
            .if rsopen(IDD_TVSeek)

                mov rbx,rax
                mov edx,loffs
                sprintf([rbx+24], "%08Xh", edx)
                dlinit(rbx)
                mov n,rsevent(IDD_TVSeek, rbx)
                strtolx([rbx+24])
                .if n && eax <= fsize
                    mov loffs,eax
                    mov esi,1
                .endif
                dlclose(rbx)
            .endif
            .endc

        .case KEY_F5
            xor flags,_CLASSMODE
            lea rax,lbh
            .if flags & _CLASSMODE
                lea rax,lbc
            .endif
            mov lptr,rax
            mov esi,1
           .endc

        .case KEY_F6
            xor flags,_HEXOFFSET
            mov esi,1
           .endc

        .case KEY_F8
            .ifd wgetfile(&lbuff, "*.cl", _WSAVE)
                _close(eax)
                .if INIAlloc()

                    mov rsi,rax
                    .if INIAddSection(rsi, ".")

                        mov rbx,rax
                        .for ( edi = 0 : edi < rowcnt: edi++ )

                            movzx eax,lbc[rdi*4].bytes
                            mov ah,lbc[rdi*4].flags
                            INIAddEntryX(rbx, "%d=%X", edi, eax)
                        .endf
                    .endif
                    INIWrite(rsi, &lbuff)
                    INIClose(rsi)
                    xor esi,esi
                .endif
            .endif
            .endc

        .case KEY_F9
            .ifd wgetfile(&lbuff, "*.cl", _WOPEN)

                _close(eax)
                .if INIRead(0, &lbuff)

                    mov rsi,rax
                    .if INIGetSection(rsi, ".")

                        mov rbx,rax
                        .for ( edi = 0 : edi < _MAXL : edi++ )

                            .break .if !INIGetEntryID(rbx, edi)
                            __xtol(rax)
                            mov lbc[rdi*4].bytes,al
                            mov lbc[rdi*4].flags,ah
                        .endf
                    .endif
                    INIClose(rsi)
                    mov esi,1
                .endif
            .endif
            .endc

        .case KEY_F10
        .case KEY_ESC
        .case KEY_ALTX
            .if modified
                .ifd SaveChanges(file)
                    savefile(file, fbuff, fsize)
                .endif
            .endif
            .break

        .case KEY_ALTF5
        .case KEY_CTRLB
            dlhide(dialog)
            .while !getkey()
            .endw
            dlshow(dialog)
           .endc

        .case KEY_CTRLM
            xor flags,_USEMLINE
            .if flags & _USEMLINE
                dlshow(menusline)
                dec rowcnt
            .else
                dlhide(menusline)
                inc rowcnt
            .endif
            mov esi,1
           .endc

        .case KEY_CTRLS
            xor flags,_USESLINE
            .if flags & _USESLINE

                dlshow(statusline)
                dec rowcnt
                mov rdx,statusline
                mov ecx,cline
                .if flags & _USEMLINE
                    inc ecx
                .endif
                movzx eax,[rdx].DOBJ.rc.y
                .if eax == ecx
                    dec cline
                .endif
            .else
                dlhide(statusline)
                inc rowcnt
            .endif
            mov esi,1
           .endc

        .case KEY_F11
            .if !( flags & _USESLINE or _USEMLINE )

                PushEvent(KEY_CTRLS)
               .gotosw(KEY_CTRLM)
            .endif
            .if flags & _USEMLINE
                PushEvent(KEY_CTRLM)
            .endif
            .if flags & _USESLINE
                .gotosw(KEY_CTRLS)
            .endif
            .endc

            ;--

        .case KEY_CTRLE
        .case KEY_UP

            xor eax,eax
            .if eax == cline

                mov eax,loffs
                .if eax
                    .if eax > fsize
                        mov eax,fsize
                    .else
                        movzx ecx,[rdi].LINE.bytes
                        .if eax <= ecx
                            xor eax,eax
                        .else
                            sub eax,ecx
                        .endif
                    .endif
                .endif
                .if eax != loffs
                    mov loffs,eax
                    mov esi,1
                .endif
            .else
                dec cline
                mov esi,1
            .endif
            .endc

        .case KEY_TAB
            .endc .if flags & _CLASSMODE
            mov eax,cline
            shl eax,4
            add eax,loffs
            add eax,index
            add eax,1
            .endc .if eax >= fsize
            mov eax,index
            mov edx,x
            .if eax < 15
                inc eax
                lea rsi,x_cpos
                mov dl,[rsi+rax]
                mov index,eax
                mov x,edx
                mov esi,1
               .endc
            .endif
            mov dl,x_cpos
            mov x,edx
            mov index,0

        .case KEY_CTRLX
        .case KEY_DOWN
            movzx ecx,[rdi].LINE.bytes
            movzx eax,[rdi].LINE.boffs
            add eax,loffs
            .if ecx == 16
                add eax,index
            .endif
            add eax,ecx
            .endc .if eax >= fsize
            mov eax,ebx
            .if flags & _USEMLINE
                inc eax
            .endif
            inc eax
            mov rdx,statusline
            movzx edx,[rdx].DOBJ.rc.y
            .if !( flags & _USESLINE )
                inc edx
            .endif
            .if eax == edx
                add loffs,ecx
            .else
                inc cline
            .endif
            mov esi,1
           .endc

        .case KEY_CTRLR
        .case KEY_PGUP
            .endc .if !loffs
             mov eax,bcount
             .if eax > loffs
                .gotosw(KEY_HOME)
             .endif
             sub loffs,eax
             mov esi,1
            .endc

        .case KEY_CTRLC
        .case KEY_PGDN
            mov eax,bcount
            add eax,eax
            add eax,loffs
            .if eax > fsize
                .gotosw(KEY_END)
            .endif
            sub eax,bcount
            mov loffs,eax
            mov esi,1
           .endc

        .case KEY_LEFT
            .endc .if flags & _CLASSMODE
            mov eax,index
            mov edx,x
            lea rdi,x_cpos
            movzx ecx,byte ptr [rdi+rax]
            .if eax
                .if ecx == edx
                    dec eax
                    mov dl,[rdi+rax]
                    inc edx
                .else
                    dec edx
                .endif
                mov index,eax
                mov x,edx
                mov esi,1
            .elseif edx > ecx
                dec x
                mov esi,1
            .endif
            .endc

        .case KEY_RIGHT
            .endc .if flags & _CLASSMODE
            mov eax,index
            mov edx,x
            .if eax <= 15
                lea rdi,x_cpos
                movzx ecx,byte ptr [rdi+rax]
                .if ecx != edx
                    .if eax != 15
                        inc eax
                        mov dl,[rdi+rax]
                    .endif
                .else
                    inc edx
                .endif
                mov ecx,cline
                shl ecx,4
                add ecx,eax
                add ecx,loffs
                .endc .if ecx >= fsize
                mov index,eax
                mov x,edx
                mov esi,1
            .endif
            .endc

        .case KEY_CTRLHOME
        .case KEY_HOME
            xor eax,eax
            mov loffs,eax
            mov index,eax
            mov cline,eax
            mov al,x_cpos
            mov x,eax
            mov esi,1
           .endc

        .case KEY_CTRLEND
        .case KEY_END
            mov ecx,fsize
            mov edx,rowcnt
            mov eax,edx
            shl eax,4
            inc eax
            .if eax < ecx
                sub eax,ecx
                not eax
                add eax,18
                and eax,-16
                mov loffs,eax
            .endif
            sub ecx,loffs
            mov eax,ecx
            shr ecx,4
            and eax,15
            .ifnz
                dec eax
            .else
                mov eax,15
                .if ecx
                    dec ecx
                .endif
            .endif
            mov index,eax
            lea rdi,x_cpos
            mov al,[rdi+rax]
            mov x,eax
            mov cline,ecx
            mov esi,1
           .endc

        .case KEY_MOUSEUP
            PushEvent(KEY_UP)
            PushEvent(KEY_UP)
            PushEvent(KEY_UP)
           .endc

        .case KEY_MOUSEDN
            PushEvent(KEY_DOWN)
            PushEvent(KEY_DOWN)
            PushEvent(KEY_DOWN)
           .endc

        .case KEY_SHIFTF3
        .case KEY_CTRLL
            mov esi,continuesearch(&loffs)
           .endc

        .case KEY_ENTER
           .endc .if !(flags & _CLASSMODE)
           .endc .if !rsopen(IDD_HELine)
            movzx edx,[rdi].LINE.bytes
            mov rdi,rax
            mov rbx,[rdi].DOBJ.object
            mov rcx,[rbx].TOBJ.data
            mov n,edx
            sprintf(rcx, "%d", edx)
            mov rcx,[rbx].TOBJ.data[TOBJ]
            sprintf(rcx, "%d", n)
            dlinit(rdi)
            mov esi,rsevent(IDD_HELine, rdi)
            .if esi == 1
                mov ebx,atol([rbx].TOBJ.data)
            .elseif esi == 2
                mov ebx,atol([rbx].TOBJ.data[TOBJ])
            .endif
            dlclose(rdi)
           .endc .if !esi

            .if esi < 3
                mov edx,esi
                mov eax,ebx
                .if eax
                    .if eax > 255
                        mov eax,16
                        xor edx,edx
                    .endif
                .else
                    mov eax,16
                    xor edx,edx
                .endif
            .else
                .ifd rsmodal(IDD_HEFormat) == 1
                    mov edx,T_SIGNED
                .elseif edx == 3
                    mov edx,T_HEX
                .else
                    xor edx,edx
                .endif
                .switch esi
                .case 3: mov eax,1  : or edx,T_BYTE  : .endc
                .case 4: mov eax,2  : or edx,T_WORD  : .endc
                .case 5: mov eax,4  : or edx,T_DWORD : .endc
                .case 6: mov eax,8  : or edx,T_QWORD : .endc
                .endsw
            .endif
            mov ebx,cline
            mov lbc[rbx*4].bytes,al
            mov lbc[rbx*4].flags,dl
            .if dl & T_STRING
                movzx esi,lbc[rbx*4].boffs
                add esi,loffs
                add rsi,fbuff
                mov ecx,eax
                lea rdi,lbuff
                rep movsb
                mov byte ptr [rdi],0
                strlen(&lbuff)
                mov lbc[rbx*4].bytes,al
            .endif
            mov esi,1
           .endc

        .default
           .endc .if flags & _CLASSMODE
            movzx eax,al
            mov ebx,eax
            lea rcx,_ltype
           .endc .if !( byte ptr [rcx+rax] & _HEX )
            mov eax,cline
            shl eax,4
            add eax,index
            add eax,loffs
            .endc .if eax > fsize
            add rax,fbuff
            mov rdx,rax
            .if bl > '9'
                or bl,0x20
                sub bl,'a'-10
            .else
                sub bl,'0'
            .endif
            mov ecx,index
            lea rax,x_cpos
            mov cl,[rax+rcx]
            mov al,[rdx]
            .if ecx == x
                shl bl,4
                and al,0x0F
            .else
                and al,0xF0
            .endif
            or  al,bl
            mov [rdx],al
            mov modified,1
            mov esi,1
           .gotosw(KEY_RIGHT)
        .endsw
    .endw

    .if CFAddSection(".hexedit")

        mov rbx,rax
        mov esi,rowcnt
        movzx ecx,flags
        INIAddEntryX(rbx, "Flags=%X", ecx)
        inc esi
        .for ( edi = 0 : edi <= esi : edi++ )

            movzx eax,lbc[rdi*4].bytes
            mov ah,lbc[rdi*4].flags
            INIAddEntryX(rbx, "%d=%X", edi, eax)
        .endf
    .endif

    free(screen)
    dlclose(statusline)
    dlclose(menusline)
    dlclose(dialog)
    _setcursor(&cursor)
    mov tupdate,update
    xor eax,eax
    ret

hedit endp

    end
