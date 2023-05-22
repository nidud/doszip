; _DAYS.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include time.inc
include stdlib.inc
include user32.inc

    .data
     _days      UINT -1, 30, 58, 89, 119, 150, 180, 211, 242, 272, 303, 333, 364
     PST        SBYTE "PST",0
     PDT        SBYTE "PDT",0
     _timezone  UINT 8*3600
     _daylight  UINT 1
     align LPSTR
     _tzname    LPSTR PST, PDT
     start_tics QWORD 0

    .code

_tzset proc private uses rsi

  local tz:TIME_ZONE_INFORMATION

    .if GetTimeZoneInformation(&tz) != -1

        mov ecx,60
        mov eax,tz.Bias
        mul ecx
        mov esi,eax
        .if tz.StandardDate.wMonth
            mov eax,tz.StandardBias
            mul ecx
            add esi,eax
        .endif
        mov _timezone,esi
        xor eax,eax
        .if tz.DaylightDate.wMonth != ax && tz.DaylightBias != eax

            inc eax
        .endif

        mov _daylight,eax
        xor eax,eax
        mov rcx,_tzname
        mov [rcx],al
        mov rcx,_tzname[size_t]
        mov [rcx],al
    .endif
    ret

_tzset endp

_isindst proc private uses rsi rdi rbx tb:ptr tm

    mov rsi,tb
    xor eax,eax
    mov ecx,[rsi].tm.tm_mon
    mov edx,[rsi].tm.tm_year

    .repeat

        .break .if edx < 67
        .break .if ecx < 3
        .break .if ecx > 9
         inc eax
        .break .if ecx > 3 && ecx < 9
        mov edi,edx
        lea rdx,_days
        mov ebx,[rdx+rcx*4+4]
        .if edi > 86 && ecx == 3
            mov ebx,[rdx+rcx*4]
            add ebx,7
        .endif

        .if !( edi & 3 )
            inc ebx
        .endif

        lea eax,[rbx+365]
        lea ecx,[rdi-70]
        mul ecx
        lea eax,[rax+rdi-1]
        shr eax,2
        sub eax,_LEAP_YEAR_ADJUST + _BASE_DOW
        xor edx,edx
        mov ecx,7
        idiv ecx
        mov eax,1
        .if [rsi].tm.tm_mon == 3

            .break .if [rsi].tm.tm_yday > edx
            .ifz
                .break .if [rsi].tm.tm_hour >= 2
            .endif
            dec eax
            .break
        .endif

        .break .if [rsi].tm.tm_yday < edx
        .ifz
            .break .if [rsi].tm.tm_hour < 1
        .endif
        dec rax
    .until 1
    ret

_isindst endp

clock proc

  local ct:FILETIME

    GetSystemTimeAsFileTime( &ct )
    mov eax,ct.dwLowDateTime
    mov edx,ct.dwHighDateTime
    sub eax,dword ptr start_tics
    sbb edx,dword ptr start_tics[4]
    mov ecx,10000
    div ecx
    ret

clock endp

DaysInFebruary proc private year:UINT

    ldr eax,year
    .repeat
        .while 1

            .break .if !eax

            .if !( eax & 3 )

                mov ecx,100
                xor edx,edx
                div ecx
                .break .if edx
                mov eax,year
            .endif

            mov ecx,400
            xor edx,edx
            div ecx
            .break .if !edx
            mov eax,28
           .break( 1 )
        .endw
        mov eax,29
    .until 1
    ret

DaysInFebruary endp

DaysInMonth proc year:UINT, month:UINT

    ldr edx,month
    mov eax,31
    .switch edx
    .case 2
        ldr ecx,year
        DaysInFebruary(ecx)
       .endc
    .case 4,6,9,11
        sub eax,1
       .endc
    .endsw
    ret

DaysInMonth endp

FileDateToStringA proc string:ptr char_t, ft:ptr FILETIME

  local ftime:FILETIME, stime:SYSTEMTIME

    FileTimeToLocalFileTime(ft, &ftime)
    FileTimeToSystemTime(&ftime, &stime)
    SystemDateToStringA(string, &stime)
    ret

FileDateToStringA endp

FileTimeToStringA proc string:ptr char_t, ft:ptr FILETIME

  local ftime:FILETIME, stime:SYSTEMTIME

    FileTimeToLocalFileTime(ft, &ftime)
    FileTimeToSystemTime(&ftime, &stime)
    SystemTimeToStringA(string, &stime)
    ret

FileTimeToStringA endp

FileTimeToTime proc ft:LPFILETIME

  local ftime:FILETIME
  local stime:SYSTEMTIME

    FileTimeToLocalFileTime(ft, &ftime)
    FileTimeToSystemTime(&ftime, &stime)
    SystemTimeToTime(&stime)
    ret

FileTimeToTime endp

GetWeekDay proc uses rsi rdi rbx year, month, day

    mov eax,year
    mov ebx,eax
    shr eax,2
    mov ecx,365 * 4 + 1
    mul ecx
    mov esi,eax
    .while ebx & 3
        DaysInFebruary(ebx)
        add eax,365-28
        add esi,eax
        sub ebx,1
    .endw
    mov ebx,year
    .if ebx
        DaysInFebruary(ebx)
        add eax,365-28
        sub esi,eax
    .endif
    mov edi,month
    .while  edi > 1
        sub edi,1
        DaysInMonth(ebx, edi)
        add esi,eax
    .endw
    mov eax,day
    add eax,esi
    dec eax
    mov ecx,7
    xor edx,edx
    div ecx
    mov eax,edx
    ret

GetWeekDay endp

    assume rdi:ptr SYSTEMTIME

StringToSystemDateA proc uses rsi rdi rbx string:ptr char_t, lpSystemTime:ptr SYSTEMTIME

  local separator:byte

    mov rdi,lpSystemTime
    mov rsi,string
    mov rcx,rsi
    .repeat
        lodsb
    .until al > '9' || al < '0'
    mov separator,al
    mov ebx,atol(rcx)
    mov ecx,atol(rsi)
    .repeat
        lodsb
    .until al > '9' || al < '0'
    xchg rcx,rsi
    mov ecx,atol(rcx)
    mov rdx,string
    mov al,[rdx+2]
    .if ( al <= '9' && al >= '0' )  ; YMD
        mov [rdi].wYear,bx
        mov [rdi].wMonth,si
        mov [rdi].wDay,cx
    .elseif ( separator == '/' )    ; MDY
        mov [rdi].wYear,cx
        mov [rdi].wMonth,bx
        mov [rdi].wDay,si
    .else
        mov [rdi].wYear,cx          ; DMY
        mov [rdi].wMonth,si
        mov [rdi].wDay,bx
    .endif
    mov [rdi].wDayOfWeek,0
    mov rax,rdi
    ret

StringToSystemDateA endp

StringToSystemTimeA proc uses rsi rdi string:ptr char_t, lpSystemTime:ptr SYSTEMTIME

    mov rsi,string
    mov rcx,rsi
    mov rdi,lpSystemTime
    .repeat
        lodsb
    .until al > '9' || al < '0'
    atol(rcx)
    mov [rdi].wHour,ax
    atol(rsi)
    mov [rdi].wMinute,ax
    .repeat
        lodsb
    .until al > '9' || al < '0'
    atol(rsi)
    mov [rdi].wSecond,ax
    mov [rdi].wMilliseconds,0
    mov rax,rdi
    ret

StringToSystemTimeA endp

    assume rdi:nothing

SystemDateToStringA proc uses rsi rdi string:ptr char_t, date:ptr SYSTEMTIME

   .new dateString[16]:char_t

    lea rsi,dateString
    mov rdi,string
    mov ecx,GetUserDefaultLCID()
    GetDateFormatA(ecx, DATE_SHORTDATE, date, NULL, rsi, lengthof(dateString))

    mov ax,'90'
    mov cx,[rsi+1]
    .if ( cl >= '0' && cl <= '9' && ch >= '0' && ch <= '9' )

        mov ecx,5 ; 'yyyy?'
        rep movsb
        mov ecx,3
        .if ( [rsi+1] < al || [rsi+1] > ah )
            stosb
            dec ecx
        .endif
        rep movsb
        mov ecx,3
        .if ( [rsi+1] < al || [rsi+1] > ah )
            stosb
            dec ecx
        .endif
        rep movsb
    .else
        mov ecx,3
        .if ( [rsi+1] < al || [rsi+1] > ah )
            stosb
            dec ecx
        .endif
        rep movsb
        mov ecx,8
        .if ( [rsi+1] < al || [rsi+1] > ah )
            stosb
            dec ecx
        .endif
        rep movsb
    .endif
    .return( string )

SystemDateToStringA endp

SystemTimeToStringA proc uses rsi rdi string:ptr char_t, stime:ptr SYSTEMTIME

   .new timeString[16]:char_t

    mov rdi,string
    lea rsi,timeString

    mov ecx,GetUserDefaultLCID()
    GetTimeFormatA(ecx, TIME_FORCE24HOURFORMAT, stime, NULL, rsi, lengthof(timeString))

    ; 0:0:0 --> 00:00:00 -- WinXP

    .for ( al = '0', edx = 0 : edx < 3 : edx++ )

        mov ecx,3
        .if ( [rsi+1] < al || byte ptr [rsi+1] > '9' )
            stosb
            dec ecx
        .endif
        rep movsb
    .endf
    .return( string )

SystemTimeToStringA endp

SystemTimeToTime proc uses rdi lpSystemTime:ptr SYSTEMTIME

    mov     rcx,lpSystemTime
    movzx   eax,[rcx].SYSTEMTIME.wYear
    sub     eax,DT_BASEYEAR
    shl     eax,9
    movzx   edx,[rcx].SYSTEMTIME.wMonth
    shl     edx,5
    or      eax,edx
    or      ax,[rcx].SYSTEMTIME.wDay
    shl     eax,16
    mov     edi,eax
    movzx   eax,[rcx].SYSTEMTIME.wSecond
    shr     eax,1
    mov     edx,eax ; second/2
    mov     al,byte ptr [rcx].SYSTEMTIME.wHour
    movzx   ecx,byte ptr [rcx].SYSTEMTIME.wMinute
    shl     ecx,5
    shl     eax,11
    or      eax,ecx
    or      eax,edx
    mov     edx,edi ; <date> yyyyyyymmmmddddd
    mov     ecx,eax ; <time> hhhhhmmmmmmsssss
    or      eax,edx ; <date>:<time>
    shr     edx,16
    ret

SystemTimeToTime endp

TimeToFileTime proc Time:time_t, lpFileTime:ptr FILETIME

  local SystemTime:SYSTEMTIME

    SystemTimeToFileTime(TimeToSystemTime(Time, &SystemTime), lpFileTime)
    LocalFileTimeToFileTime(lpFileTime, lpFileTime)
   .return(lpFileTime)

TimeToFileTime endp

TimeToSystemTime proc Time:time_t, lpSystemTime:ptr SYSTEMTIME

    ldr     rcx,Time
    ldr     rdx,lpSystemTime

    mov     [rdx].SYSTEMTIME.wDayOfWeek,0
    mov     [rdx].SYSTEMTIME.wMilliseconds,0
    mov     eax,ecx
    shr     eax,16
    shr     eax,9
    add     eax,DT_BASEYEAR
    mov     [rdx].SYSTEMTIME.wYear,ax
    mov     eax,ecx
    shr     eax,16
    shr     eax,5
    and     eax,1111B
    mov     [rdx].SYSTEMTIME.wMonth,ax
    mov     eax,ecx
    shr     eax,16
    and     eax,11111B
    mov     [rdx].SYSTEMTIME.wDay,ax
    movzx   eax,cx
    shr     eax,11
    mov     [rdx].SYSTEMTIME.wHour,ax
    movzx   eax,cx
    shr     eax,5
    and     ax,111111B
    mov     [rdx].SYSTEMTIME.wMinute,ax
    movzx   eax,cx
    and     eax,11111B
    shl     eax,1
    mov     [rdx].SYSTEMTIME.wSecond,ax
    mov     rax,rdx
    ret

TimeToSystemTime endp

__inittime proc private

  local ct:FILETIME

    GetSystemTimeAsFileTime( &ct )
    mov eax,ct.dwLowDateTime
    mov edx,ct.dwHighDateTime
    mov dword ptr start_tics,eax
    mov dword ptr start_tics[4],edx
    xor eax,eax
    ret

__inittime endp

.pragma init(__inittime, 20)

    end
