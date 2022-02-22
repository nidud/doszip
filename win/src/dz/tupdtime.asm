include time.inc
include consx.inc
include winnls.inc

public time_id

    .data
     time_id dd 61

    .code

tupdtime proc uses esi edi ebx

  local ts:SYSTEMTIME
  local buf[64]:byte

    mov ebx,console
    xor eax,eax

    .if ebx & CON_UTIME or CON_UDATE

        mov buf,al
        mov ecx,sizeof(SYSTEMTIME)/4
        lea edi,ts
        rep stosd
        mov edi,ebx
        GetLocalTime(&ts)

        mov eax,edi
        and eax,CON_UTIME or CON_LTIME
        cmp eax,CON_UTIME or CON_LTIME
        movzx eax,ts.wSecond
        .ifnz
            movzx eax,ts.wMinute
        .endif

        .if eax != time_id

            mov time_id,eax
            mov ebx,_scrcol
            inc ebx

            .if edi & CON_UTIME

                SystemTimeToStringA(&buf, &ts)
                .if !( edi & CON_LTIME )
                    mov buf[5],0
                    sub ebx,6
                .else
                    sub ebx,9
                .endif
                scputs(ebx, 0, 0, 0, &buf)
            .endif

            .if edi & CON_UDATE

                SystemDateToStringA(&buf, &ts)
                .if !(edi & CON_LDATE)
                    lea esi,buf
                    mov al,[esi+2]
                    .if ( al >= '0' && al <= '9' )
                        add esi,2
                    .else
                        mov eax,[esi+6]
                        shr eax,16
                        mov [esi+6],eax
                    .endif
                    sub ebx,9
                .else
                    sub ebx,11
                .endif
                scputs(ebx, 0, 0, 0, &buf)
            .endif
        .endif
    .endif
    ret

tupdtime endp

    END
