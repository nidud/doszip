; _INITTERM.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include stdlib.inc
include kernel32.inc

main proto __Cdecl :UINT, :ptr, :ptr

option dotname

.CRT$XI0 SEGMENT ALIGN(8) 'CONST'
__xi_a dq 0
.CRT$XI0 ENDS
.CRT$XIA SEGMENT ALIGN(8) 'CONST'
x      dq 0
.CRT$XIA ENDS
.CRT$XIZ SEGMENT ALIGN(8) 'CONST'
__xi_z dq 0
.CRT$XIZ ENDS

.CRT$XT0 SEGMENT ALIGN(8) 'CONST'
__xt_a dq 0
.CRT$XT0 ENDS
.CRT$XTA SEGMENT ALIGN(8) 'CONST'
       dq 0
.CRT$XTA ENDS
.CRT$XTZ SEGMENT ALIGN(8) 'CONST'
__xt_z dq 0
.CRT$XTZ ENDS

define MAXENTRIES 32

    .code

_initterm proc private uses rsi rdi rbx pfbegin:ptr, pfend:ptr

   .new entries[MAXENTRIES]:uint64_t

    ldr rcx,pfbegin
    ldr rdx,pfend

    mov rax,rdx
    sub rax,rcx

    ; walk the table of function pointers from the bottom up, until
    ; the end is encountered.  Do not skip the first entry.  The initial
    ; value of pfbegin points to the first valid entry.  Do not try to
    ; execute what pfend points to.  Only entries before pfend are valid.

    .ifnz

        .for ( rsi = rcx,
               rdi = &entries,
               edx = 0,
               rcx += rax : rsi < rcx && edx < MAXENTRIES : rsi += 8 )

            mov eax,[rsi]
            .if ( eax )

                stosd
                mov eax,[rsi+4]
                stosd
                inc edx
            .endif
        .endf

        .for ( rsi = &entries, edi = edx :: )

            .for ( ecx = -1,
                   rbx = rsi,
                   edx = 0,
                   eax = edi : eax : eax--, rbx+=8 )

                .if ( dword ptr [rbx] != 0 && ecx >= [rbx+4] )

                    mov ecx,[rbx+4]
                    mov rdx,rbx
                .endif
            .endf
            .break .if !rdx

            mov  ecx,[rdx]
            mov  dword ptr [rdx],0
ifdef _WIN64
            lea  rax,_initterm
            mov  rdx,imagerel _initterm
            sub  rax,rdx
            add  rcx,rax
endif
            call rcx
        .endf
    .endif
    ret

_initterm endp


exit proc code:int_t

    _initterm(&__xt_a, &__xt_z)
    ExitProcess(code)
    ret

exit endp

mainCRTStartup proc

  local _exception_registration[2]:dword

    _initterm( &__xi_a, &__xi_z )
    exit( main( __argc, __argv, _environ ) )

mainCRTStartup endp

    end mainCRTStartup
