; SYSTEMTIMETOSTRINGA.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;
include time.inc
include winnls.inc

    .code

SystemTimeToStringA proc uses esi edi string:ptr char_t, stime:ptr SYSTEMTIME

   .new timeString[16]:char_t

    mov edi,string
    lea esi,timeString

    mov ecx,GetUserDefaultLCID()
    GetTimeFormatA(ecx, TIME_FORCE24HOURFORMAT, stime, NULL, esi, lengthof(timeString))

    ; 0:0:0 --> 00:00:00 -- WinXP

    .for ( al = '0', edx = 0 : edx < 3 : edx++ )

        mov ecx,3
        .if ( [esi+1] < al || byte ptr [esi+1] > '9' )
            stosb
            dec ecx
        .endif
        rep movsb
    .endf
    .return( string )

SystemTimeToStringA endp

    END
