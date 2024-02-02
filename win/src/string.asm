; STRING.ASM--
;
; Copyright (c) The Doszip Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include string.inc
include malloc.inc

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

cmpwarg PROC uses rsi path:LPSTR, wild:LPSTR

    ldr rsi,path
    ldr rcx,wild
    xor eax,eax

    .while 1

        lodsb
        mov ah,[rcx]
        inc rcx

        .if ah == '*'

            .while 1
                mov ah,[rcx]
                .if !ah
                    mov eax,1
                    .break(1)
                .endif
                inc rcx
                .continue .if ah != '.'
                xor edx,edx
                .while al
                    .if al == ah
                        mov rdx,rsi
                    .endif
                    lodsb
                .endw
                mov rsi,rdx
                .continue(1) .if rdx
                mov ah,[rcx]
                inc rcx
                .continue .if ah == '*'
                test eax,eax
                mov  ah,0
                setz al
               .break(1)
            .endw
        .endif

        mov edx,eax
        xor eax,eax
        .if !dl
            .break .if edx
            inc eax
            .break
        .endif
        .break .if !dh
        .continue .if dh == '?'
        .if dh == '.'
            .continue .if dl == '.'
            .break
        .endif
        .break .if dl == '.'
        or edx,0x2020
        .break .if dl != dh
    .endw
    ret

cmpwarg endp

cmpwargs proc uses rdi path:LPSTR, wild:LPSTR

    ldr rdi,wild

    .repeat
        .if strchr(rdi, ' ')
            mov rdi,rax
            mov byte ptr [rdi],0
            cmpwarg(path, rax)
            mov byte ptr [rdi],' '
            inc rdi
        .else
            cmpwarg(path, rdi)
           .break
        .endif
    .until eax
    ret

cmpwargs endp

dostounix proc string:LPSTR

    ldr rax,string
.0:
    cmp byte ptr [rax],0
    je  .1
    cmp byte ptr [rax],'\'
    lea rax,[rax+1]
    jne .0
    mov byte ptr [rax-1],'/'
    jmp .0
.1:
    ldr rax,string
    ret

dostounix endp

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

memcpy proc uses rsi rdi dst:ptr, src:ptr, size:size_t

    ldr rax,dst
    ldr rsi,src
    ldr rcx,size
    mov rdi,rax
    rep movsb
    ret

memcpy endp

memmove proc uses rsi rdi dst:ptr, src:ptr, count:size_t

    ldr     rax,dst
    ldr     rsi,src
    ldr     rcx,count

    mov     rdi,rax
    cmp     rax,rsi
    ja      .0
    rep     movsb
    jmp     .1
.0:
    lea     rsi,[rsi+rcx-1]
    lea     rdi,[rdi+rcx-1]
    std
    rep     movsb
    cld
.1:
    ret

memmove endp

memcmp proc uses rsi rdi a:ptr, b:ptr, count:size_t

    ldr     rdi,a
    ldr     rsi,b
    ldr     rcx,count
    xor     eax,eax
    repe    cmpsb
    jz      .0
    sbb     rax,rax
    sbb     rax,-1
.0:
    ret

memcmp endp

memset proc uses rdi dst:ptr, chr:int_t, size:size_t

    ldr     rdi,dst
    ldr     eax,chr
    ldr     rcx,size
    rep     stosb
    mov     rax,dst
    ret

memset endp

memrchr proc uses rdi base:string_t, char:int_t, bsize:uint_t

    ldr     rdi,base
    ldr     eax,char
    ldr     ecx,bsize

    test    ecx,ecx
    jz      .0
    lea     rdi,[rdi+rcx-1]
    std
    repnz   scasb
    cld
    jnz     .0
    mov     rax,rdi
    inc     rax
    jmp     .1
.0:
    xor     eax,eax
.1:
    ret

memrchr endp

memxchg proc dst:string_t, src:string_t, count:size_t

ifdef _WIN64

.0:
    cmp     r8,8
    jb      .1
    sub     r8,8
    mov     rax,[rcx+r8]
    mov     r10,[rdx+r8]
    mov     [rcx+r8],r10
    mov     [rdx+r8],rax
    jmp     .0
.1:
    test    r8,r8
    jz      .3
.2:
    dec     r8
    mov     al,[rcx+r8]
    mov     r10b,[rdx+r8]
    mov     [rcx+r8],r10b
    mov     [rdx+r8],al
    jnz     .2
.3:
    mov     rax,rcx

else
    push    esi
    push    edi

    mov     edi,dst
    mov     esi,src
    mov     ecx,count
    test    ecx,ecx

.0:
    jz      .2
    test    ecx,3
    jz      .1

    sub     ecx,1
    mov     al,[esi+ecx]
    mov     dl,[edi+ecx]
    mov     [esi+ecx],dl
    mov     [edi+ecx],al
    jmp     .0

.1:
    sub     ecx,4
    mov     eax,[esi+ecx]
    mov     edx,[edi+ecx]
    mov     [esi+ecx],edx
    mov     [edi+ecx],eax
    jnz     .1

.2:
    mov     eax,edi
    pop     edi
    pop     esi
endif
    ret

memxchg endp

memquote proc uses rsi rdi rbx string:string_t, bsize:uint_t

    ldr     rax,string
    ldr     ebx,bsize

    test    ebx,ebx
    jz      .2
    test    rax,3
    jz      .0
    mov     ecx,0x2227

    cmp     [rax],cl
    je      .5
    cmp     [rax],ch
    je      .5
    cmp     ebx,1
    jz      .2

    cmp     [rax+1],cl
    je      .4
    cmp     [rax+1],ch
    je      .4
    cmp     ebx,2
    jz      .2

    cmp     [rax+2],cl
    je      .3
    cmp     [rax+2],ch
    je      .3
    cmp     ebx,3
    jz      .2

.0:
    add     rbx,rax
    add     rax,3
    and     rax,-4
.1:
    cmp     rax,rbx
    jae     .2

    mov     esi,[rax]
    mov     edi,esi
    add     rax,4
    xor     esi,'""""'
    xor     edi,"''''"
    lea     ecx,[rsi-0x01010101]
    not     esi
    and     ecx,esi
    lea     esi,[rdi-0x01010101]
    not     edi
    and     esi,edi
    and     ecx,0x80808080
    and     esi,0x80808080
    or      ecx,esi
    jz      .1
    bsf     ecx,ecx
    shr     ecx,3
    lea     rax,[rax+rcx-4]
    cmp     rax,rbx
    sbb     rcx,rcx
    and     rax,rcx
    jmp     .5
.2:
    xor     eax,eax
    jmp     .5
.3:
    inc     rax
.4:
    inc     rax
.5:
    ret

memquote endp

memstri proc private uses rsi rdi rbx s1:string_t, l1:uint_t, s2:string_t, l2:uint_t

    ldr     rdi,s1
    ldr     rsi,s2
    ldr     ecx,l1

    mov     al,[rsi]
    sub     al,'A'
    cmp     al,'Z'-'A'+1
    sbb     bl,bl
    and     bl,'a'-'A'
    add     bl,al
    add     bl,'A'
.0:
    test    ecx,ecx
    jz      .2
    dec     ecx
    mov     al,[rdi]
    add     rdi,1
    sub     al,'A'
    cmp     al,'Z'-'A'+1
    sbb     bh,bh
    and     bh,'a'-'A'
    add     al,bh
    add     al,'A'
    cmp     al,bl
    jne     .0
    mov     edx,l2
    dec     edx
    jz      .3
    cmp     ecx,edx
    jl      .2
.1:
    dec     edx
    jl      .3
    mov     al,[rsi+rdx+1]
    cmp     al,[rdi+rdx]
    je      .1
    mov     ah,[rdi+rdx]
    sub     ax,'AA'
    cmp     al,'Z'-'A' + 1
    sbb     bh,bh
    and     bh,'a'-'A'
    add     al,bh
    cmp     ah,'Z'-'A' + 1
    sbb     bh,bh
    and     bh,'a'-'A'
    add     ah,bh
    add     ax,'AA'
    cmp     al,ah
    je      .1
    jmp     .0
.2:
    xor     eax,eax
    jmp     .4
.3:
    mov     rax,rdi
    dec     rax
.4:
    ret

memstri endp

setfext PROC path:LPSTR, ext:LPSTR

    .if strext(path)

        mov byte ptr [rax],0
    .endif
    strcat(path, ext)
    ret

setfext ENDP

strcat proc uses rsi rdi s1:string_t, s2:string_t

    ldr     rdi,s1
    ldr     rsi,s2
    mov     rax,rdi
.0:
    cmp     byte ptr [rdi],0
    je      .1
    inc     rdi
    jmp     .0
.1:
    mov     cl,[rsi]
    mov     [rdi],cl
    inc     rsi
    inc     rdi
    test    cl,cl
    jnz     .1
    ret

strcat endp

strchr proc string:string_t, chr:int_t

    ldr     rax,string
    ldr     ecx,chr
    movzx   ecx,cl
.3:
    cmp     cl,[rax]
    je      .0
    cmp     ch,[rax]
    je      .4
    cmp     cl,[rax+1]
    je      .1
    cmp     ch,[rax+1]
    je      .4
    cmp     cl,[rax+2]
    je      .2
    cmp     ch,[rax+2]
    je      .4
    add     rax,3
    jmp     .3
.4:
    xor     eax,eax
    jmp     .0
.2:
    inc     rax
.1:
    inc     rax
.0:
    ret

strchr endp

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

strcmp proc a:string_t, b:string_t

    ldr     rcx,a
    ldr     rdx,b
    xor     eax,eax
.0:
    xor     al,[rcx]
    jz      .5
    sub     al,[rdx]
    jnz     .1
    xor     al,[rcx+1]
    jz      .4
    sub     al,[rdx+1]
    jnz     .1
    xor     al,[rcx+2]
    jz      .3
    sub     al,[rdx+2]
    jnz     .1
    xor     al,[rcx+3]
    jz      .2
    sub     al,[rdx+3]
    jnz     .1
    add     rcx,4
    add     rdx,4
    jmp     .0
.1:
    sbb     rax,rax
    sbb     rax,-1
    jmp     .6
.2:
    add     rdx,1
.3:
    add     rdx,1
.4:
    add     rdx,1
.5:
    sub     al,[rdx]
    jnz     .1
.6:
    ret

strcmp endp

strcpy proc uses rsi rdi dst:string_t, src:string_t

    ldr     rdi,src
    ldr     rdx,dst
    mov     rsi,rdi
    xor     eax,eax
    mov     rcx,-1
    repne   scasb
    not     rcx
    mov     rax,rdx
    mov     rdi,rdx
    rep     movsb
    ret

strcpy endp

_strdup proc string:LPSTR

    ldr rax,string
    .if rax

        .if malloc(&[strlen(rax)+1])

            strcpy(rax, string)
        .endif
    .endif
    ret

_strdup endp

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

strext proc string:LPSTR

    mov string,strfn(string)

    .if strrchr(rax, '.')

        .if rax == string

            xor eax,eax
        .endif
    .endif
    ret

strext endp

strfcat proc uses rsi rdi buffer:LPSTR, path:LPSTR, file:LPSTR

    mov rdx,buffer
    mov rsi,path
    xor eax,eax
    mov ecx,-1

    .if rsi

        mov rdi,rsi     ; overwrite buffer
        repne scasb
        mov rdi,rdx
        not ecx
        rep movsb
    .else

        mov rdi,rdx     ; length of buffer
        repne scasb
    .endif

    dec rdi
    .if rdi != rdx      ; add slash if missing

        mov al,[rdi-1]
        .if !( al == '\' || al == '/' )

            mov al,'\'
            stosb
        .endif
    .endif

    mov rsi,file        ; add file name
    .repeat
        lodsb
        stosb
    .until !eax
    mov rax,rdx
    ret

strfcat endp

strfn proc path:LPSTR

    mov rcx,path

    .for ( rax = rcx, dl = [rcx] : dl : rcx++, dl = [rcx] )

        .if ( dl == '\' || dl == '/' )

            .if ( byte ptr [rcx+1] )
                lea rax,[rcx+1]
            .endif
        .endif
    .endf
    ret

strfn endp

_stricmp proc a:string_t, b:string_t

    ldr     rcx,a
    ldr     rdx,b

    dec     rcx
    dec     rdx
    mov     eax,1
.0:
    test    eax,eax
    jz      .3
    inc     rcx
    inc     rdx
    mov     al,[rcx]
    cmp     al,[rdx]
    je      .0
    cmp     al,'A'
    jb      .1
    cmp     al,'Z'
    ja      .1
    or      al,0x20
.1:
    mov     ah,[rdx]
    cmp     ah,'A'
    jb      .2
    cmp     ah,'Z'
    ja      .2
    or      ah,0x20
.2:
    cmp     al,ah
    mov     ah,0
    je      .0
    sbb     rax,rax
    sbb     rax,-1
.3:
    ret

_stricmp endp

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
    .ifd strlen(rbx)

        mov ecx,eax
        add rbx,rax
        .repeat

            sub rbx,char_t
            mov al,[rbx]
            .break .if ( al != ' ' && al != 9 )
            mov char_t ptr [rbx],0
        .untilcxz
        mov rax,rcx
    .endif
    ret

stripend endp

strlen proc string:string_t

    ldr     rcx,string
    mov     rax,rcx
    and     rcx,3
    jz      .2
    sub     rax,rcx
    shl     ecx,3
    mov     edx,-1
    shl     edx,cl
    not     edx
    or      edx,[rax]
    lea     ecx,[rdx-0x01010101]
    not     edx
    and     ecx,edx
    and     ecx,0x80808080
    jnz     .3
.1:
    add     rax,4
.2:
    mov     edx,[rax]
    lea     ecx,[rdx-0x01010101]
    not     edx
    and     ecx,edx
    and     ecx,0x80808080
    jz      .1
.3:
    bsf     ecx,ecx
    shr     ecx,3
    add     rax,rcx
    sub     rax,string
    ret

strlen endp

strmove proc dst:LPSTR, src:LPSTR

    strlen(src)
    inc eax
    memmove(dst, src, eax)
    ret

strmove ENDP

strncmp proc uses rbx a:string_t, b:string_t, count:size_t

    ldr     rcx,a
    ldr     rdx,b
    ldr     rbx,count
    mov     eax,1
    dec     rcx
    dec     rdx
.0:
    test    al,al
    jz      .2
    test    ebx,ebx
    jz      .1
    dec     ebx
    inc     rcx
    inc     rdx
    mov     al,[rcx]
    cmp     al,[rdx]
    je      .0
    sbb     ebx,ebx
    sbb     ebx,-1
.1:
    mov     eax,ebx
.2:
    ret

strncmp endp

strncpy proc uses rdi dst:string_t, src:string_t, count:size_t

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
    rep     stosb
.1:
    mov     rax,dst
    ret

strncpy endp

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

_strnicmp proc uses rsi a:string_t, b:string_t, size:size_t

    ldr     rsi,a
    ldr     rdx,b
    ldr     rcx,size

    dec     rsi
    dec     rdx
    mov     eax,1
.0:
    test    eax,eax
    jz      .3
    inc     rsi
    inc     rdx
    xor     eax,eax
    test    ecx,ecx
    jz      .2
    dec     ecx
    mov     al,[rsi]
    cmp     al,[rdx]
    je      .0
    cmp     al,'A'
    jb      .1
    cmp     al,'Z'
    ja      .1
    or      al,0x20
.1:
    mov     ah,[rdx]
    cmp     ah,'A'
    jb      .2
    cmp     ah,'Z'
    ja      .2
    or      ah,0x20
.2:
    cmp     al,ah
    mov     ah,0
    je      .0
    sbb     rax,rax
    sbb     rax,-1
.3:
    ret

_strnicmp endp

strpath PROC string:LPSTR

    .if strfn(string) != string

        mov byte ptr [rax-1],0
        mov rax,string
    .endif
    ret

strpath ENDP

strrchr proc string:string_t, chr:int_t

    ldr     rcx,string
    ldr     edx,chr
    dec     rcx
    xor     eax,eax
.0:
    inc     rcx
    cmp     byte ptr [rcx],0
    jz      .2
    cmp     dl,[rcx]
    jnz     .0
    mov     rax,rcx
    jmp     .0
.2:
    ret

strrchr endp

_strrev proc string:string_t

    ldr rcx,string

    .for ( rdx = rcx : byte ptr [rdx] : rdx++ )
    .endf

    .for ( rdx-- : rdx > rcx : rdx--, rcx++ )

        mov al,[rcx]
        mov ah,[rdx]
        mov [rcx],ah
        mov [rdx],al
    .endf
    .return( string )

_strrev endp

strshr proc uses rsi rdi string:LPSTR, char:UINT

    ldr     rdi,string
    ldr     edx,char
    mov     ecx,-1
    xor     eax,eax
    repnz   scasb
    not     ecx
    inc     ecx
    mov     rsi,rdi
    inc     rdi
    std
    rep     movsb
    cld
    mov     [rdi],dl
    mov     rax,rdi
    ret

strshr endp

strstart proc string:LPSTR

    ldr rax,string
    .repeat

        add rax,1
        .continue(0) .if byte ptr [rax-1] == ' '
        .continue(0) .if byte ptr [rax-1] == 9
    .until 1
    sub rax,1
    ret

strstart endp

strstr proc uses rsi rdi rbx dst:LPSTR, src:LPSTR

    ldr rdi,dst
    ldr rbx,src

    .if strlen(rbx)

        mov rsi,rax
        .if strlen(rdi)

            mov rcx,rax
            xor eax,eax
            dec rsi

            .repeat

                mov al,[rbx]
                repne scasb
                mov al,0

                .break .ifnz
                .if rsi

                    .break .if ( rcx < rsi )
                     mov rdx,rsi
                    .repeat
                        mov al,[rbx+rdx]
                        .continue(01) .if ( al != [rdi+rdx-1] )
                        dec rdx
                    .untilz
                .endif
                lea rax,[rdi-1]
            .until 1
        .endif
    .endif
    ret

strstr endp

strstri proc private uses rbx dst:LPSTR, src:LPSTR

    mov ebx,strlen(dst)
    memstri(dst, ebx, src, strlen(src))
    ret

strstri endp

strtrim proc string:LPSTR

    .if strlen(string)

        mov ecx,eax
        add rcx,string
        .repeat
            dec rcx
            .break .if byte ptr [rcx] > ' '
            mov byte ptr [rcx],0
            dec eax
        .untilz
    .endif
    ret

strtrim endp

strxchg proc uses rsi rdi rbx dst:LPSTR, old:LPSTR, new:LPSTR

    ldr rdi,dst
    mov esi,strlen(new)
    mov ebx,strlen(old)

    .while strstri(rdi, old)    ; find token

        mov rdi,rax             ; EDI to start of token
        lea rcx,[rax+rsi]
        add rax,rbx
        strmove(rcx, rax)       ; move($ + len(new), $ + len(old))
        memmove(rdi, new, rsi)  ; copy($, new, len(new))
        inc rdi                 ; $++
    .endw
    mov rax,dst
    ret

strxchg endp

unixtodos proc string:LPSTR

    ldr rax,string

    .while 1

        .break .if byte ptr [rax] == 0
        cmp byte ptr [rax],'/'
        lea rax,[rax+1]
        .continue(0) .ifnz
        mov byte ptr [rax-1],'\'
    .endw
    mov rax,string
    ret

unixtodos endp

    end
