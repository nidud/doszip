; CMEGALINE.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include config.inc
include stdlib.inc

.code

cmegaline proc uses rsi rdi rbx

   .new cmin:COORD  = _scrmin
   .new cmax:COORD  = _scrmax
   .new rc:RECT     = _scrrc

    doszip_hide()

    lea rbx,cmin
    .if !( cflag & _C_EGALINE )
        lea rbx,cmax
    .endif

    .if CFGetSection(".consolesize")

        mov rsi,rax
        mov edi,4
        .if ( cflag & _C_EGALINE )
            xor edi,edi
        .endif
        .if INIGetEntryID(rsi, edi)
            mov _scrrc.left,atol(rax)
        .endif
        .if INIGetEntryID(rsi, &[rdi+1])
            mov _scrrc.top,atol(rax)
        .endif
        .if INIGetEntryID(rsi, &[rdi+2])

            atol(rax)
            mov [rbx],ax
        .endif
        .if INIGetEntryID(rsi, &[rdi+3])

            atol(rax)
            mov [rbx+2],ax
        .endif
    .endif
    conssetl([rbx])
    apiega()

    mov _scrrc,rc
    doszip_show()
    ret

cmegaline endp

    end
