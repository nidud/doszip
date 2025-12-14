; CMFILTER.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include stdio.inc
include stdlib.inc
include dzstr.inc
include time.inc

.enumt FilterIDD : TOBJ {
    ID_DIALOG,
    ID_INCLUDE,
    ID_EXCLUDE,
    ID_MIN_DATE,
    ID_MAX_DATE,
    ID_MIN_SIZE,
    ID_MAX_SIZE,
    ID_RDONLY,
    ID_HIDDEN,
    ID_SYSTEM,
    ID_VOLID,
    ID_SUBDIR,
    ID_ARCH,
    ID_OK,
    ID_CLEAR,
    ID_CANCEL
    }

    .data

filter_keys GLCMD \
        { KEY_F3, cmfilter_load },
        { KEY_F4, cmfilter_date },
        { 0, NULL }

    .code

cmfilter_load proc uses rsi rdi rbx

  local filt[FILT_MAXSTRING]:byte

    mov rbx,tdialog
    mov rax,IDD_DZFindFile
    mov dl,[rax].RIDD.count
    mov edi,0x0D0D
    .if [rbx].DOBJ.count != dl
        dec edx
        .if [rbx].DOBJ.count != dl
            mov edi,1
        .endif
    .endif
    mov esi,tools_idd(128, &filt, "Filter")

    msloop()

    .if ( esi && esi != MOUSECMD )

        mov eax,edi
        .if [rbx].DOBJ.index != al
            mov [rbx].DOBJ.index,ah
        .endif
        movzx ecx,[rbx].DOBJ.index
        imul  ecx,ecx,TOBJ
        add   rcx,[rbx].DOBJ.object
        strcpy([rcx].TOBJ.data, &filt)
        dlinit(rbx)
    .endif
    .return(_C_NORMAL)

cmfilter_load endp


cmfilter_date proc private uses rdi rbx

    mov rdi,tdialog
    mov al,[rdi].DOBJ.index
    .if al != 2 && al != 3
        mov [rdi].DOBJ.index,2
    .endif

    .ifd cmcalendar()

        mov   ebx,eax
        movzx eax,[rdi].DOBJ.index
        inc   eax
        imul  eax,eax,TOBJ
        add   rax,rdi

        sprintf([rax].TOBJ.data, "%02u.%02u.%02u", edx, ebx, ecx)
        dlinit(rdi)
    .endif
    .return(_C_NORMAL)

cmfilter_date endp


TDateToString proc private string:ptr sbyte, tptr:time_t

  local SystemTime:SYSTEMTIME

    TimeToSystemTime(tptr, &SystemTime)
    SystemDateToStringA(string, &SystemTime)
    ret

TDateToString endp


atodate proc private string:ptr sbyte

  local SystemTime:SYSTEMTIME

    StringToSystemDateA(string, &SystemTime)

    movzx eax,SystemTime.wYear
    movzx edx,SystemTime.wMonth
    movzx ecx,SystemTime.wDay
    .if eax
        .if eax <= 1900     ; year yy | yyyy
            .if eax < 80
                add eax,100
            .endif
            add eax,1900
        .endif
        sub eax,DT_BASEYEAR
        shl eax,9           ; year
        shl edx,5           ; month
        or  eax,edx
        or  eax,ecx         ; yyyyyyymmmmddddd
        shl eax,16          ; <date>:<time>
    .endif
    ret

atodate endp


event_clear proc private uses rsi

    mov rsi,tdialog
    xor eax,eax
    mov rdx,[rsi].TOBJ.data[ID_MIN_DATE]
    mov [rdx],al
    mov rdx,[rsi].TOBJ.data[ID_MAX_DATE]
    mov [rdx],al
    mov rdx,[rsi].TOBJ.data[ID_MIN_SIZE]
    mov [rdx],al
    mov rdx,[rsi].TOBJ.data[ID_MAX_SIZE]
    mov [rdx],al
    memset(filter, 0, FILTER)
    mov rsi,filter
    strcpy(&[rsi].FILTER.minclude, &cp_stdmask)
    mov [rsi].FILTER.flag,-1
    mov rax,tdialog
    add rax,ID_RDONLY
    tosetbitflag(rax, 6, _O_FLAGB, 0xFFFFFFFF)
    mov eax,_C_REOPEN
    ret

event_clear endp


event_help proc private

    view_readme(HELPID_12)
    ret

event_help endp


filter_edit proc private uses rsi rdi rbx filt:PFILTER, glcmd:ptr GLCMD

  local FileTime:FILETIME
  local ohelp:DPROC

    .if rsopen(IDD_OperationFilters)

        mov rdi,rax
        mov rsi,filt
        mov filter,rsi
        mov ohelp,thelp
        mov thelp,&event_help

        lea rax,[rsi].FILTER.minclude
        mov [rdi].TOBJ.data[ID_INCLUDE],rax
        add rax,128
        mov [rdi].TOBJ.data[ID_EXCLUDE],rax
        mov [rdi].TOBJ.count[ID_INCLUDE],8
        mov [rdi].TOBJ.count[ID_EXCLUDE],8
        mov rax,glcmd
        mov [rdi].TOBJ.data[ID_OK],rax
        mov [rdi].TOBJ.tproc[ID_CLEAR],&event_clear
        .if [rsi].FILTER.min_date
            TDateToString([rdi].TOBJ.data[ID_MIN_DATE], [rsi].FILTER.min_date)
        .endif
        .if [rsi].FILTER.max_date
            TDateToString([rdi].TOBJ.data[ID_MAX_DATE], [rsi].FILTER.max_date)
        .endif
        .if [rsi].FILTER.min_size
            sprintf([rdi].TOBJ.data[ID_MIN_SIZE], "%u", [rsi].FILTER.min_size)
        .endif
        .if [rsi].FILTER.max_size
            sprintf([rdi].TOBJ.data[ID_MAX_SIZE], "%u", [rsi].FILTER.max_size)
        .endif
        lea rbx,[rdi+ID_RDONLY]
        mov eax,[rsi].FILTER.flag

        tosetbitflag(rbx, 6, _O_FLAGB, eax)
        dlinit(rdi)
        mov ebx,rsevent(IDD_OperationFilters, rdi)
        dlclose(rdi)

        mov thelp,ohelp
        .if ebx
            togetbitflag(&[rdi][ID_RDONLY], 6, _O_FLAGB)
            or  eax,0xFFC0
            mov [rsi].FILTER.flag,eax
            mov [rsi].FILTER.max_size,strtolx([rdi].TOBJ.data[ID_MAX_SIZE])
            mov [rsi].FILTER.min_size,strtolx([rdi].TOBJ.data[ID_MIN_SIZE])
            mov [rsi].FILTER.max_date,atodate([rdi].TOBJ.data[ID_MAX_DATE])
            mov [rsi].FILTER.min_date,atodate([rdi].TOBJ.data[ID_MIN_DATE])
            mov eax,_C_NORMAL
        .else
            xor eax,eax
            mov filter,rax
        .endif
    .else
        xor eax,eax
        mov filter,rax
    .endif
    ret

filter_edit endp


cmfilter proc

    filter_edit(&opfilter, &filter_keys)
    ret

cmfilter endp

    END
