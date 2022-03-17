; SYSTEMDATETOSTRINGA.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;
; DMY:dd.mm.yyyy, MDY:mm/dd/yyyy, YMD:yyyy/mm/dd
;
include time.inc
include winnls.inc

    .code

SystemDateToStringA proc uses esi edi string:ptr char_t, date:ptr SYSTEMTIME

   .new dateString[16]:char_t

    lea esi,dateString
    mov edi,string
    mov ecx,GetUserDefaultLCID()
    GetDateFormatA(ecx, DATE_SHORTDATE, date, NULL, esi, lengthof(dateString))

    mov ax,'90'
    mov cx,[esi+1]
    .if ( cl >= '0' && cl <= '9' && ch >= '0' && ch <= '9' )

        mov ecx,5 ; 'yyyy?'
        rep movsb
        mov ecx,3
        .if ( [esi+1] < al || [esi+1] > ah )
            stosb
            dec ecx
        .endif
        rep movsb
        mov ecx,3
        .if ( [esi+1] < al || [esi+1] > ah )
            stosb
            dec ecx
        .endif
        rep movsb
    .else
        mov ecx,3
        .if ( [esi+1] < al || [esi+1] > ah )
            stosb
            dec ecx
        .endif
        rep movsb
        mov ecx,8
        .if ( [esi+1] < al || [esi+1] > ah )
            stosb
            dec ecx
        .endif
        rep movsb
    .endif
    .return( string )

SystemDateToStringA endp

    END
