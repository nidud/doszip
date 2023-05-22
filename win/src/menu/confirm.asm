include io.inc
include confirm.inc
include conio.inc

    .data
     confirmflag uint_t -1

    .code

confirm_continue proc uses rbx msg:LPSTR

    .if rsopen(IDD_ConfirmContinue)
        mov rbx,rax
        dlshow(rax)
        mov rax,msg
        .if rax
            mov cx,[rbx+4]
            add cx,0204h
            mov dl,ch
            scpath(ecx, edx, 34, rax)
        .endif
        dlmodal(rbx)
    .endif
    ret

confirm_continue endp

;
; ret:  0 Cancel
;       1 Delete
;       2 Delete All
;       3 Jump
;
confirm_delete proc uses rbx info:LPSTR, selected:dword

    .if rsopen(IDD_ConfirmDelete)

        mov rbx,rax
        dlshow(rax)
        mov cl,[rbx].DOBJ.rc.x
        mov dl,[rbx].DOBJ.rc.y
        add dl,2        ; y
        add cl,12       ; x
        mov eax,selected

        .if ( eax > 1 && eax < 0x8000 )

            scputf(ecx, edx, 0, 0,
                "   You have selected %d file(s)\nDo you want to delete all the files", eax)
        .else
            .if eax == -2
                scputf(ecx, edx, 0, 0,
                    "The following file is marked System.\n\n%s",
                    "  Do you still wish to delete it?")
            .elseif eax == -1
                sub ecx,2
                scputf(ecx, edx, 0, 0,
                    "The following file is marked Read only.\n\n  %s",
                    "  Do you still wish to delete it?")
            .else
                add ecx,6
                scputf(ecx, edx, 0, 0, "Do you wish to delete")
            .endif

            mov cl,[rbx].DOBJ.rc.x
            add cl,3
            mov dl,[rbx].DOBJ.rc.y
            add dl,3
            scenter(ecx, edx, 53, info)
        .endif
;       beep( 50, 6 )
        rsevent(IDD_ConfirmDelete, rbx)
        xchg rbx,rax
        dlclose(rax)
        mov eax,ebx
    .endif
    ret

confirm_delete endp

confirm_delete_file proc uses rsi fname:LPSTR, flag:dword

    mov eax,flag
    mov edx,confirmflag
    .switch
      .case al & _A_RDONLY && dl & CFREADONY
        mov eax,-1
        mov esi,not (CFREADONY or CFDELETEALL)
        .endc
      .case al & _A_SYSTEM && dl & CFSYSTEM
        mov eax,-2
        mov esi,not (CFSYSTEM or CFDELETEALL)
        .endc
      .case dl & CFDELETEALL
        xor eax,eax
        mov esi,not CFDELETEALL
        .endc
      .default
        .return 1
    .endsw
    .switch confirm_delete(fname, eax)
      .case CONFIRM_DELETEALL
        and confirmflag,esi
        mov eax,1
        .endc
      .case CONFIRM_JUMP
        xor eax,eax
      .case CONFIRM_DELETE
        .endc
      .default
        mov eax,-1
    .endsw
    ret

confirm_delete_file endp

confirm_delete_sub proc path:LPSTR

    mov eax,1
    .if confirmflag & CFDIRECTORY
        .if confirm_delete(path, 1) == CONFIRM_DELETEALL
            and confirmflag,not (CFDIRECTORY or CFDELETEALL)
            mov eax,1
        .elseif eax == CONFIRM_JUMP
            mov eax,-1
        .elseif eax != CONFIRM_DELETE
            xor eax,eax
        .endif
    .endif
    ret

confirm_delete_sub endp

    END
