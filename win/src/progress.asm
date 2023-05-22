include conio.inc
include errno.inc
include string.inc
include confirm.inc
include wsub.inc
include config.inc
include progress.inc

    .data

progress_size   dq 0
progress_name   LPSTR 0
progress_xpos   dd 0
progress_loop   dd 0
progress_args   db '%s',10,'  to',0
progress_dobj   DOBJ <_D_STDDLG,0,0,<4,9,72,6>,0,0>
old_console     dd 0

    .code

test_userabort proc

    mov ecx,getkey()
    xor eax,eax
    .if ecx == KEY_ESC
        .if confirm_continue(progress_name)
            mov eax,ER_USERABORT
        .endif
    .endif
    ret

test_userabort endp


progress_open proc ttl:LPSTR, function:LPSTR

    mov old_console,console
    and console,not CON_SLEEP
    mov progress_name,ttl
    xor eax,eax
ifdef _WIN64
    mov progress_size,rax
else
    mov dword ptr progress_size,eax
    mov dword ptr progress_size[4],eax
endif
    mov progress_xpos,4

    .if word ptr function
        mov progress_xpos,9
    .endif
    mov dl,at_background[B_Dialog]
    or  dl,at_foreground[F_Dialog]

    .if dlopen(&progress_dobj, edx, ttl)
        dlshow(&progress_dobj)
        .if word ptr function
            mov dl,at_background[B_Dialog]
            or  dl,at_foreground[F_DialogKey]
            scputf(8, 11, edx, 0, &progress_args, function)
        .endif
        scputc(8, 13, 64, U_LIGHT_SHADE)
    .endif
    ret

progress_open endp


progress_set proc uses rbx s1:LPSTR, s2:LPSTR, len:qword

   .new maxl:int_t

    xor eax,eax
    .if progress_dobj.flag & _D_ONSCR

        mov progress_loop,eax
        mov ebx,progress_xpos
        mov ecx,68
        sub ecx,ebx
        mov maxl,ecx
        add ebx,4

        .if s1 != rax

            mov progress_name,strfn(s1)
            mov progress_size,len

            scpathl(ebx, 11, maxl, s1)
            .if s2
                scpathl(ebx, 12, maxl, s2)
            .endif
            add ebx,4
            sub ebx,progress_xpos
            scputc(ebx, 13, 64, U_LIGHT_SHADE)
        .else
            scpathl(ebx, 12, maxl, s2)
        .endif
        tupdate()
        test_userabort()
    .endif
    ret

progress_set endp


progress_close proc

    .if dlclose(&progress_dobj)

        mov eax,old_console
        and eax,CON_SLEEP
        or  console,eax
        xor eax,eax
        mov old_console,eax
    .endif
    ret

progress_close endp


progress_update proc offs:qword

    movzx eax,progress_dobj.flag
    and eax,_D_ONSCR
    .if eax
ifdef _WIN64
        mov rax,progress_size
        shr rax,6
        mov rdx,rax
        mov r8d,1
        .while rax < rcx

            add rax,rdx
            inc r8d
           .break .if r8d == 64
        .endw
        mov ecx,r8d
else
       .new progress:Q64

        push    ebx
        push    edi
        mov     edx,dword ptr progress_size[4]
        mov     eax,dword ptr progress_size
        shrd    eax,edx,6
        shr     edx,6
        mov     progress.q_l,eax
        mov     progress.q_h,edx
        mov     ebx,eax
        mov     edi,edx
        mov     ecx,1
        mov     edx,dword ptr offs[4]
        mov     eax,dword ptr offs
        .while  edi < edx || ebx < eax
            add ebx,progress.q_l
            adc edi,progress.q_h
            inc ecx
            .break .if ecx == 64
        .endw
        pop     edi
        pop     ebx
endif
        mov eax,ecx
        .if eax != progress_loop
            mov ecx,progress_loop
            mov progress_loop,eax
            .if eax < ecx
                scputc(8, 13, 64, U_LIGHT_SHADE)
            .endif
            scputc(8, 13, eax, U_FULL_BLOCK)
        .endif
        test_userabort()
    .endif
    ret

progress_update endp

    END
