include conio.inc
include string.inc

    .data

dialog      PDOBJ 0

Background  db B_Title, B_Panel, B_Panel,B_Panel,B_Panel,B_Dialog,B_Dialog,B_Desktop
            db B_Dialog,B_Dialog,B_Panel,B_Panel,B_Menus,B_Title, B_Dialog,B_Menus
Foreground  db F_Desktop,F_Panel,F_Dialog,F_Menus,F_Dialog,F_Title,F_Panel,F_Dialog
            db F_Title,F_Files,F_Dialog,F_Dialog,F_TextView,F_TextEdit,F_TextView,F_TextEdit

    .code

putinfo proc private uses rsi rdi rbx

   .new x:int_t
   .new y:int_t
   .new n:int_t

    lea     rsi,at_foreground
    mov     rbx,dialog
    mov     ax,[rbx+4+TOBJ]
    add     ax,[rbx+4]
    add     al,2
    movzx   ecx,ah
    movzx   eax,al
    mov     x,eax
    mov     y,ecx

    .for ( edi = 0 : edi < 16 : edi++, y++ )

        movzx eax,byte ptr [rsi+rdi]
        scputf(x, y, 0, 3, "%X", eax)

        add x,5
        lea rax,Background
        movzx eax,byte ptr [rax+rdi]
        mov   al,[rsi+rax+16]
        or    al,[rsi+rdi]
        scputa(x, y, 13, eax)

        add x,42
        mov al,[rsi+B_Dialog+16]
        or  eax,edi
        scputa(x, y, 1, eax)
        sub x,47
    .endf

    mov     eax,[rbx+4+TOBJ*17]
    add     eax,[rbx+4]
    movzx   ecx,ah
    movzx   eax,al
    add     eax,7
    mov     x,eax
    mov     y,ecx
    sub     eax,5
    mov     n,eax

    .for ( edi = 0 : edi < 14 : edi++, y++ )

        movzx eax,byte ptr [rsi+rdi+16]
        shr al,4
        scputf(n, y, 0, 3, "%X", eax)

        lea rax,Foreground
        movzx eax,byte ptr [rax+rdi]
        mov al,[rsi+rax]
        or  al,[rsi+rdi+16]
        scputa(x, y, 13, eax)
    .endf

    movzx eax,byte ptr [rsi+rdi+16]
    scputf(n, y, 0, 3, "%X", eax)

    lea rax,Foreground
    movzx eax,byte ptr [rax+rdi]
    mov al,[rsi+rax]
    or  al,[rsi+B_TextView+16]
    scputa(x, y, 13, eax)

    inc y
    inc edi
    movzx eax,byte ptr [rsi+rdi+16]
    scputf(n, y, 0, 3, "%X", eax)

    lea rax,Foreground
    movzx eax,byte ptr [rax+rdi]
    mov al,[rsi+rax]
    or  al,[rsi+B_TextEdit+16]
    scputa(x, y, 13, eax)
    xor eax,eax
    ret

putinfo endp

editat proc private uses rsi rdi rbx

    lea rdi,at_foreground
    lea rsi,[rdi+16]

    putinfo()
    dlxcellevent()

    xor edx,edx
    mov rcx,tdialog
    movzx ecx,[rcx].DOBJ.index

    .if eax == KEY_MOUSEUP
        mov eax,KEY_UP
    .elseif eax == KEY_MOUSEDN
        mov eax,KEY_DOWN
    .endif
    .if eax == KEY_PGUP
        .if ecx < 16
            .if byte ptr [rdi+rcx] < 0Fh
                inc edx
                inc byte ptr [rdi+rcx]
            .endif
        .elseif ecx < 30
            .if byte ptr [rsi+rcx-16] < 0F0h
                inc edx
                add byte ptr [rsi+rcx-16],10h
            .endif
        .elseif ecx < 32
            .if byte ptr [rdi+rcx] < 0Fh
                inc edx
                inc byte ptr [rdi+rcx]
            .endif
        .endif
    .elseif eax == KEY_PGDN
        .if ecx < 16
            .if byte ptr [rdi+rcx]
                inc edx
                dec byte ptr [rdi+rcx]
            .endif
        .elseif ecx < 30
            .if byte ptr [rsi+rcx-16] >= 10h
                inc edx
                sub byte ptr [rsi+rcx-16],10h
            .endif
        .elseif ecx < 32
            .if byte ptr [rdi+rcx]
                inc edx
                dec byte ptr [rdi+rcx]
            .endif
        .endif
    .endif
    .if edx
        mov ebx,eax
        rsreload(IDD_EditColor, tdialog)
        putinfo()
        mov eax,ebx
    .endif
    ret

editat endp


editattrib proc uses rbx

  local tmp:COLOR

    .if rsopen(IDD_EditColor)

        mov dialog,rax
        memcpy(&tmp, &at_foreground, COLOR)

        dlshow(dialog)
        putinfo()

        mov rdx,dialog
        movzx ecx,[rdx].DOBJ.count
        mov rdx,[rdx].DOBJ.object
        sub ecx,2
        lea rax,editat
        .repeat
            mov [rdx].TOBJ.tproc,rax
            add rdx,TOBJ
        .untilcxz
        mov ebx,rsevent(IDD_EditColor, dialog)
        dlclose(dialog)
        .if ebx
            mov eax,1
        .else
            memcpy(&at_foreground, &tmp, COLOR)
            xor eax,eax
        .endif
    .endif
    ret

editattrib endp

    END
