include time.inc
include conio.inc

define STARTYEAR   0
define MAXYEAR     3000

define USE_MDALTKEYS

    .data
     _dlg PDOBJ 0
     cp_month string_t \
        @CStr("January"),
        @CStr("February"),
        @CStr("March"),
        @CStr("April"),
        @CStr("May"),
        @CStr("June"),
        @CStr("July"),
        @CStr("August"),
        @CStr("September"),
        @CStr("October"),
        @CStr("November"),
        @CStr("December")

     keypos db 1,5,9,13,17,21,25

    .code

cupdate proc private

   .new ts:SYSTEMTIME = {0}
   .new buf[64]:byte = 0

    GetLocalTime(&ts)
    SystemTimeToStringA(&buf, &ts)

    mov rax,_dlg
    movzx ecx,[rax].DOBJ.rc.x
    movzx edx,[rax].DOBJ.rc.y
    add ecx,2
    add edx,1
    scputs(ecx, edx, 0, 0, &buf)
    xor eax,eax
    ret

cupdate endp

cmcalendar proc uses rsi rdi rbx

  local t:SYSTEMTIME
  local mouseloop
  local dialog:PDOBJ
  local x,y,w,xpos,ypos
  local curyear,curmonth,curday
  local year,month,day
  local week_day
  local days_in_month
  local current_year
  local current_month
  local result, update:ptr


    GetLocalTime(&t)

    movzx eax,t.wDay
    mov curday,eax
    mov ax,t.wMonth
    mov curmonth,eax
    mov ax,t.wYear
    mov curyear,eax
    xor eax,eax
    mov current_year,eax
    mov current_month,eax
    mov result,eax
    mov update,tupdate

    .if rsopen(IDD_Calendar)

        mov dialog,rax
        mov _dlg,rax
        mov rbx,rax
        mov tupdate,&cupdate
        xor eax,eax
        movzx eax,[rbx].DOBJ.rc.x
        mov xpos,eax
        mov al,[rbx].DOBJ.rc.y
        mov ypos,eax
        dlshow(dialog)

        mov ecx,xpos
        mov edx,ypos
        add ecx,2
        add edx,3
        mov ebx,curmonth
        lea rax,cp_month
        mov rbx,[rax+rbx*size_t-size_t]
        scputf(ecx, edx, 0x0B, 0, "%s %d", rbx, curyear)


        mov edx,curday
        mov ebx,curmonth
        mov ecx,curyear
        mov esi,1
        xor edi,edi
        mov mouseloop,1

        .while 1

            .if esi
                mov day,edx
                mov month,ebx
                mov year,ecx
                mov week_day,GetWeekDay(ecx, ebx, 0)
                mov days_in_month,DaysInMonth(year, ebx)
                inc edi
                xor esi,esi
            .endif

            .if edi

                mov eax,year
                mov edx,month

                .if eax != current_year || edx != current_month

                    mov current_month,edx
                    mov current_year,eax

                    mov eax,xpos
                    mov edx,ypos
                    add eax,4
                    add edx,5
                    mov x,eax
                    mov y,edx
                    scputc(eax, edx, 14, ' ')

                    mov eax,month
                    lea rcx,cp_month
                    mov rbx,[rcx+rax*size_t-size_t]
                    scputf(x, y, 0, 0, "%s %d", rbx, year)

                    mov eax,ypos
                    add eax,9
                    mov y,eax
                    sub x,1

                    .for ( ebx = 0 : ebx < 6 : ebx++, y++ )
                        scputw(x, y, 29, 0x00070020)
                    .endf
                .endif

                xor esi,esi
                mov edi,3
                .while ( esi < days_in_month && edi < 10 )

                    xor ecx,ecx

                    .while ( ecx < 7 )

                        mov eax,3   ; first line

                        .if ( ( week_day <= ecx && edi == eax ) ||
                              ( ( week_day > ecx || edi != eax ) &&
                                edi > eax && esi < days_in_month ) )

                            inc esi
                            mov x,ecx
                            mov y,edi
                            mov ebx,ecx

                            mov ecx,0x06
                            .if esi != day
                                mov ecx,0x07
                            .endif
                            lea rax,keypos
                            movzx eax,byte ptr [rax+rbx]
                            mov ebx,edi
                            add ebx,6
                            add eax,3
                            add ebx,ypos
                            add eax,xpos
                            mov edi,eax
                            scputf(edi, ebx, ecx, 2, "%2d", esi)

                            .if curday == esi
                                mov eax,curmonth
                                .if eax == month
                                    mov eax,curyear
                                    .if eax == year
                                        scputa(edi, ebx, 2, 0x0B)
                                    .endif
                                .endif
                            .endif
                            mov edi,y
                            mov ecx,x
                        .endif
                        add ecx,1
                    .endw
                    add edi,1
                .endw

                .if mouseloop

                    msloop()
                    mov mouseloop,0
                .endif
                xor edi,edi
                xor esi,esi
            .endif

            tgetevent()
            .switch eax

            .case KEY_F1
                mov tupdate,update
                rsmodal(IDD_CalHelp)
                mov tupdate,&cupdate
               .endc

            .case MOUSECMD
                mousex()
                mov edx,eax
                mousey()
                mov rbx,dialog
                .break .ifd !rcxyrow([rbx].DOBJ.rc, edx, eax)
                dlmove(dialog)
                mov rbx,dialog
                sub eax,eax
                mov al,[rbx+4]
                mov dl,al
                mov xpos,eax
                mov al,[rbx+5]
                mov ypos,eax
               .endc

            .case KEY_ENTER
                mov eax,1
                mov result,eax
            .case KEY_ALTX
            .case KEY_F10
            .case KEY_ESC
                .break

            .case KEY_HOME
                GetWeekDay(curyear, curmonth, 0)
                mov week_day,eax
                DaysInMonth(curyear, curmonth)
                mov days_in_month,eax
                mov edx,curday
                mov day,edx
                mov ebx,curmonth
                mov month,ebx
                mov ecx,curyear
                mov year,ecx
                inc edi
                .endc

            .case KEY_RIGHT
                mov edx,day
                inc edx
                .if edx > days_in_month
                    .gotosw(KEY_PGDN)
                .endif
                mov day,edx
                inc edi
                .endc

            .case KEY_LEFT
                mov edx,day
                .if edx != 1
                    mov ecx,year
                    mov ebx,month
                    dec edx
                    mov day,edx
                    inc edi
                .else
                    mov edx,1
                    mov ebx,month
                    mov ecx,year
                    .if ebx != 1
                        dec ebx
                    .else
                        mov ebx,12
                        .if ecx
                            dec ecx
                        .else
                            mov ecx,MAXYEAR
                        .endif
                    .endif
                    mov day,edx
                    mov month,ebx
                    mov year,ecx
                    mov week_day,GetWeekDay(ecx, ebx, 0)
                    mov days_in_month,DaysInMonth(year, ebx)
                    mov day,eax
                    inc edi
                .endif
                .endc

            .case KEY_UP
                mov eax,7
                .if day <= eax
                    .gotosw(KEY_LEFT)
                .endif
                sub day,eax
                inc edi
               .endc

            .case KEY_DOWN
                mov eax,day
                add eax,7
                .if eax > days_in_month
                    .gotosw(KEY_RIGHT)
                .endif
                mov day,eax
                inc edi
               .endc

            .case KEY_PGUP
                mov edx,1
                mov ebx,month
                mov ecx,year
                .if ebx != 1
                    dec ebx
                .else
                    mov ebx,12
                    mov ecx,year
                    .if ecx
                        dec ecx
                    .else
                        mov ecx,MAXYEAR
                    .endif
                .endif
                inc esi
               .endc

            .case KEY_PGDN
                mov ebx,month
                .if ebx == 12

                    .gotosw(KEY_CTRLPGDN)
                .endif
                mov edx,1
                mov ecx,year
                inc ebx
                inc esi
               .endc

            .case KEY_CTRLPGUP
                mov edx,1
                mov ebx,edx
                mov ecx,year
                .if ecx
                    dec ecx
                .else
                    mov ecx,MAXYEAR
                .endif
                inc esi
               .endc

            .case KEY_CTRLPGDN
                mov edx,1
                mov ebx,edx
                mov ecx,year
                .if ecx != MAXYEAR
                    inc ecx
                .else
                    mov ecx,STARTYEAR
                .endif
                inc esi
               .endc
            .endsw
        .endw

        mov tupdate,update
        dlclose(dialog)
        mov edx,day
        mov ebx,month
        mov ecx,year
        mov eax,result
        .if eax
            mov eax,ebx
        .endif
    .endif
    ret

cmcalendar endp

    END
