include wsub.inc
include doszip.inc

    .code

cmsearchidd proc uses rsi rdi rbx sflag:uint_t

    .if rsopen(IDD_Search)

        mov rdi,rax
        mov rbx,rax
        mov [rbx].TOBJ.count[1*TOBJ],256 shr 4
        mov [rbx].TOBJ.data[1*TOBJ],&searchstring
        mov eax,sflag
        mov dl,_O_FLAGB
        .if eax & IO_SEARCHCASE
            or  [rbx+2*TOBJ],dl
        .endif
        .if eax & IO_SEARCHHEX
            or  [rbx+3*TOBJ],dl
        .endif
        mov dl,_O_RADIO
        .if eax & IO_SEARCHCUR
            or  [rbx+6*TOBJ],dl
        .else
            or  [rbx+7*TOBJ],dl
        .endif
        dlinit(rdi)

        .if rsevent(IDD_Search, rdi)

            mov eax,sflag
            and eax,not IO_SEARCHMASK
            mov dl,_O_FLAGB
            .if [rbx+2*TOBJ] & dl
                or eax,IO_SEARCHCASE
            .endif
            .if [rbx+3*TOBJ] & dl
                or eax,IO_SEARCHHEX
            .endif
            .if byte ptr [rbx+6*TOBJ] & _O_RADIO
                or eax,IO_SEARCHCUR
            .else
                or eax,IO_SEARCHSET
            .endif
            mov edx,eax
            xor eax,eax
            .if searchstring != al
                inc eax
            .endif
        .endif
        mov ebx,eax
        mov esi,edx
        dlclose(rdi)
        mov eax,ebx
        mov edx,esi
    .endif
    ret

cmsearchidd endp

    END
