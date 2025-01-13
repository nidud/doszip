; STRING.ASM--
;
; Copyright (c) The Doszip Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include dzstr.inc

    .code

    option dotname

btohex proc string:LPSTR, count:SINT

    ldr eax,count
    ldr rdx,string

    dec eax
    mov rcx,rdx
    add rcx,rax
    add eax,eax
    add rdx,rax
    mov byte ptr [rdx+2],0

    .repeat

        mov al,[rcx]
        mov ah,al
        shr al,4
        and ah,15
        add ax,'00'
        .if al > '9'
            add al,7
        .endif
        .if ah > '9'
            add ah,7
        .endif
        mov [rdx],ax
        dec rcx
        sub rdx,2
    .until rdx < rcx
    mov rax,string
    ret

btohex endp

hextob proc string:LPSTR

    ldr rcx,string
    mov rdx,rcx

    .while 1

        mov ax,[rcx]
        inc rcx
        .continue .if al == ' '

        inc rcx
        .break .if !al

        sub al,'0'
        .if al > 9
            sub al,7
        .endif

        shl al,4
        .if !ah
            mov [rdx],al
            inc rdx
           .break
        .endif

        sub ah,'0'
        .if ah > 9
            sub ah,7
        .endif

        or  al,ah
        mov [rdx],al
        inc rdx
    .endw

    mov byte ptr [rdx],0
    mov rax,string
    mov rcx,rdx
    sub rcx,rax
    ret

hextob endp


strchri proc string:string_t, char:int_t

    ldr     eax,char
    ldr     rdx,string
    movzx   eax,al

    sub     al,'A'
    cmp     al,'Z'-'A'+1
    sbb     cl,cl
    and     cl,'a'-'A'
    add     cl,al
    add     cl,'A'
.0:
    mov     al,[rdx]
    test    eax,eax
    jz      .1
    add     rdx,1
    sub     al,'A'
    cmp     al,'Z'-'A'+1
    sbb     ch,ch
    and     ch,'a'-'A'
    add     al,ch
    add     al,'A'
    cmp     al,cl
    jne     .0
    mov     rax,rdx
    dec     rax
.1:
    ret

strchri endp


streol proc uses rsi rbx string:LPSTR

    ldr     rax,string
    mov     rsi,rax
.0:
    mov     edx,[rax]
    add     rax,4
    lea     ecx,[rdx-0x01010101]
    not     edx
    and     ecx,edx
    and     ecx,0x80808080
    xor     edx,not 0x0A0A0A0A
    lea     ebx,[rdx-0x01010101]
    not     edx
    and     ebx,edx
    and     ebx,0x80808080
    or      ecx,ebx
    jz      .0
    bsf     ecx,ecx
    shr     ecx,3
    lea     rax,[rax+rcx-4]
    cmp     rax,rsi
    je      .1
    cmp     BYTE PTR [rax],0
    je      .1
    cmp     BYTE PTR [rax-1],0x0D
    jne     .1
    dec     rax
.1:
    ret

streol endp

strins proc uses rbx s1:LPSTR, s2:LPSTR

    mov ebx,strlen(s2)
    inc strlen(s1)
    mov ecx,ebx
    add rcx,s1

    memmove(rcx, s1, eax)
    memcpy(s1, s2, ebx)
    ret

strins endp

stripend proc uses rbx rdx string:LPSTR

    ldr rbx,string

    mov ecx,strlen(rbx)
    .if eax

        add rbx,rax
        .repeat

            sub rbx,char_t
            mov al,[rbx]
            .break .if ( al != ' ' && al != 9 )
            mov char_t ptr [rbx],0
        .untilcxz
        mov eax,ecx
    .endif
    ret

stripend endp

strnzcpy proc uses rdi dst:string_t, src:string_t, count:size_t

    ldr     rdi,dst
    ldr     rdx,src
    ldr     rcx,count
.0:
    test    ecx,ecx
    jz      .1
    dec     ecx
    mov     al,[rdx]
    mov     [rdi],al
    add     rdx,1
    add     rdi,1
    test    al,al
    jnz     .0
.1:
    mov     rax,dst
    ret

strnzcpy endp

strpath PROC string:LPSTR

    .if strfn(string) != string

        mov byte ptr [rax-1],0
        mov rax,string
    .endif
    ret

strpath ENDP

    end
