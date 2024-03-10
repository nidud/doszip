; _OUTPUT.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include stdio.inc
include stdlib.inc
include limits.inc
include io.inc

BUFFERSIZE      equ 512     ; ANSI-specified minimum is 509

FL_SIGN         equ 0x0001  ; put plus or minus in front
FL_SIGNSP       equ 0x0002  ; put space or minus in front
FL_LEFT         equ 0x0004  ; left justify
FL_LEADZERO     equ 0x0008  ; pad with leading zeros
FL_LONG         equ 0x0010  ; long value given
FL_SHORT        equ 0x0020  ; short value given
FL_SIGNED       equ 0x0040  ; signed data given
FL_ALTERNATE    equ 0x0080  ; alternate form requested
FL_NEGATIVE     equ 0x0100  ; value is negative
FL_FORCEOCTAL   equ 0x0200  ; force leading '0' for octals
FL_LONGDOUBLE   equ 0x0400  ; long double
FL_WIDECHAR     equ 0x0800
FL_LONGLONG     equ 0x1000  ; long long or REAL16 value given
FL_I64          equ 0x8000  ; 64-bit value given
FL_CAPEXP       equ 0x10000

ST_NORMAL       equ 0       ; normal state; outputting literal chars
ST_PERCENT      equ 1       ; just read '%'
ST_FLAG         equ 2       ; just read flag character
ST_WIDTH        equ 3       ; just read width specifier
ST_DOT          equ 4       ; just read '.'
ST_PRECIS       equ 5       ; just read precision specifier
ST_SIZE         equ 6       ; just read size specifier
ST_TYPE         equ 7       ; just read type specifier

    .data
    _iob    _iobuf  <_bufin,0,_bufin,_IOREAD or _IOYOURBUF,0,0,_INTIOBUF,0>
    _stdout _iobuf  <0,0,0,_IOWRT,1,0,0,0>  ; stdout
    _stderr _iobuf  <0,0,0,_IOWRT,2,0,0,0>  ; stderr
    _first  _iobuf  _NSTREAM_ - 4 dup(<0,0,0,0,-1,0,0,0>)
    _last   _iobuf  <0,0,0,0,-1,0,0,0>

    align   size_t
    stdin   LPFILE _iob
    stdout  LPFILE _stdout
    stderr  LPFILE _stderr

    __nullstring sbyte "(null)",0,0

    __lookuptable byte \
    06h, 00h, 00h, 06h, 00h, 01h, 00h, 00h, ;  !"#$%&' 20 00
    10h, 00h, 03h, 06h, 00h, 06h, 02h, 10h, ; ()*+,-./ 28 08
    04h, 45h, 45h, 45h, 05h, 05h, 05h, 05h, ; 01234567 30 10
    05h, 35h, 30h, 00h, 50h, 00h, 00h, 00h, ; 89:;<=>? 38 18
    00h, 28h, 28h, 38h, 50h, 58h, 07h, 08h, ; @ABCDEFG 40 20
    00h, 37h, 30h, 30h, 57h, 50h, 07h, 00h, ; HIJKLMNO 48 28
    00h, 20h, 20h, 08h, 00h, 00h, 00h, 00h, ; PQRSTUVW 50 30
    08h, 60h, 68h, 60h, 60h, 60h, 60h, 00h, ; XYZ[\]^_ 58 38
    00h, 78h, 78h, 78h, 78h, 78h, 78h, 08h, ; `abcdefg 60 40
    07h, 08h, 00h, 00h, 07h, 00h, 08h, 08h, ; hijklmno 68 48
    08h, 00h, 00h, 08h, 00h, 08h, 00h, 07h, ; pqrstuvw 70 50
    08h                                     ; xyz{|}~  78 58

    .code

    option proc:private

write_char proc char:SINT, fp:LPFILE, pnumwritten:LPDWORD

    ldr eax,char
    ldr rcx,fp
    ldr rdx,pnumwritten
    dec [rcx]._iobuf._cnt
    .ifl
        mov eax,-1
        mov [rdx],eax
    .else
        inc dword ptr [rdx]
        mov rdx,[rcx]._iobuf._ptr
        inc [rcx]._iobuf._ptr
        mov [rdx],al
        xor eax,eax
    .endif
    ret

write_char endp

write_string proc uses rsi rdi string:LPSTR, len:UINT, fp:LPFILE, pnumwritten:LPDWORD

    .fors ( rsi = string, edi = len : edi > 0 : edi-- )

        movzx eax,BYTE PTR [rsi]
        inc rsi

       .break .ifd ( write_char(eax, fp, pnumwritten) == -1 )
    .endf
    ret

write_string endp

write_multi_char proc uses rdi char:SINT, num:UINT, fp:LPFILE, pnumwritten:LPDWORD

    .fors ( edi = num : edi > 0 : edi-- )

       .break .ifd ( write_char(char, fp, pnumwritten) == -1 )
    .endf
    ret

write_multi_char endp

    option proc:public

_output proc uses rsi rdi rbx fp:LPFILE, format:LPSTR, arglist:ptr

  local charsout            : SINT,
        hexoff              : UINT,
        state               : UINT,
        curadix             : UINT,
        prefix[2]           : BYTE,
        textlen             : UINT,
        prefixlen           : UINT,
        no_output           : UINT,
        fldwidth            : UINT,
        bufferiswide        : UINT,
        padding             : UINT,
        text                : LPSTR,
        buffer[BUFFERSIZE]  : char_t

    mov textlen,0
    mov charsout,0
    mov state,0

    .while 1

        mov   rax,format
        inc   format
        movzx eax,byte ptr [rax]
        mov   ecx,eax

        .break .if ( !eax || charsout > INT_MAX )

        lea rdx,__lookuptable
        .if ( eax >= ' ' && eax <= 'x' )

            mov al,[rdx+rax-32]
            and eax,0x0F
        .else
            xor eax,eax
        .endif
        shl eax,3
        add eax,state
        mov al,[rdx+rax]
        shr eax,4
        and eax,0x0F
        mov state,eax

        .if eax <= 7

            .switch eax
            .case ST_NORMAL
                mov bufferiswide,0
                write_char(ecx, fp, addr charsout)
               .endc
            .case ST_PERCENT
                xor eax,eax
                mov no_output,eax
                mov fldwidth,eax
                mov prefixlen,eax
                mov bufferiswide,eax
                xor esi,esi ; flags
                mov edi,-1  ; precision
               .endc
            .case ST_FLAG
                movzx eax,cl
                .switch eax
                  .case '+': or esi,FL_SIGN:      .endc ; '+' force sign indicator
                  .case ' ': or esi,FL_SIGNSP:    .endc ; ' ' force sign or space
                  .case '#': or esi,FL_ALTERNATE: .endc ; '#' alternate form
                  .case '-': or esi,FL_LEFT:      .endc ; '-' left justify
                  .case '0': or esi,FL_LEADZERO:  .endc ; '0' pad with leading zeros
                .endsw
                .endc
            .case ST_WIDTH
                .if cl == '*'
                    mov rax,arglist
                    add arglist,size_t
                    mov eax,[rax]
                    .ifs eax < 0
                        or  esi,FL_LEFT
                        neg eax
                    .endif
                    mov fldwidth,eax
                .else
                    imul eax,fldwidth,10
                    add eax,ecx
                    add eax,-48
                    mov fldwidth,eax
                .endif
                .endc
            .case ST_DOT
                xor edi,edi
               .endc
            .case ST_PRECIS
                .if cl == '*'
                    mov rax,arglist
                    add arglist,size_t
                    mov edi,[rax]
                    .ifs edi < 0
                        mov edi,-1
                    .endif
                .else
                    imul eax,edi,10
                    movsx edi,cl
                    add edi,eax
                    add edi,-48
                .endif
                .endc
            .case ST_SIZE
                .switch ecx
                .case 'l'
                    .if !( esi & FL_LONG )
                        or esi,FL_LONG
                       .endc
                    .endif

                    ; case ll => long long

                    and esi,NOT FL_LONG
                    or  esi,FL_LONGLONG
                   .endc
                .case 'L'
                    or  esi,FL_LONGDOUBLE or FL_I64
                   .endc
                .case 'I'
                    mov rax,format
                    mov cx,[rax]
                    .switch cl
                    .case '6'
                        .gotosw(2:ST_NORMAL) .if ch != '4'
                        or  esi,FL_I64
                        add rax,2
                        mov format,rax
                       .endc
                    .case '3'
                        .gotosw(2:ST_NORMAL) .if ch != '2'
                        and esi,not FL_I64
                        add rax,2
                        mov format,rax
                       .endc
                    .case 'd'
                    .case 'i'
                    .case 'o'
                    .case 'u'
                    .case 'x'
                    .case 'X'
                        .endc
                    .default
                        .gotosw(2:ST_NORMAL)
                    .endsw
                    .endc

                .case 'h'
                    or esi,FL_SHORT
                   .endc
                .case 'w'
                    or esi,FL_WIDECHAR  ; 'w' => wide character
                   .endc
                .endsw
                .endc

            .case ST_TYPE
                mov eax,ecx
                .switch eax
                .case 'b'
                    mov rax,arglist
                    add arglist,size_t
                    mov edx,[rax]
                    xor ecx,ecx
                    bsr ecx,edx
                    inc ecx
                    mov textlen,ecx
                    .repeat
                        sub eax,eax
                        shr edx,1
                        adc al,'0'
                        mov buffer[rcx-1],al
                    .untilcxz
                    lea rax,buffer
                    mov text,rax
                   .endc
                .case 'C'
                    .if !( esi & ( FL_SHORT or FL_LONG or FL_WIDECHAR ) )

                        or esi,FL_WIDECHAR ; ISO std.
                    .endif
                .case 'c'
                    mov bufferiswide,1
                    mov rax,arglist
                    add arglist,size_t
                    mov edx,[rax]
                    mov buffer,dl
                    mov textlen,1 ; print just a single character
                    lea rax,buffer
                    mov text,rax
                   .endc
                .case 'S' ; ISO wide character string
                    .if !( esi & ( FL_SHORT or FL_LONG or FL_WIDECHAR ) )
                        or esi,FL_WIDECHAR
                    .endif
                .case 's'
                    mov rax,arglist
                    add arglist,size_t
                    mov rax,[rax]
                    mov ecx,edi
                    .if edi == -1
                        mov ecx,INT_MAX
                    .endif
                    .if rax == NULL
                        lea rax,__nullstring
                    .endif
                    mov text,rax
                    .repeat
                        .break .if BYTE PTR [rax] == 0
                        inc rax
                    .untilcxz
                    sub rax,text
                    mov textlen,eax
                   .endc
                .case 'n'
                    mov rax,arglist
                    add arglist,size_t
                    mov rdx,[rax-size_t]
                    mov eax,charsout
                    mov [rdx],eax
                    .if esi & FL_LONG
                        mov no_output,1
                    .endif
                    .endc
                .case 'd'
                .case 'i' ; signed decimal output
                    or  esi,FL_SIGNED
                .case 'u'
                    mov curadix,10
                    jmp COMMON_INT
                .case 'p'
                    mov edi,size_t * 2
ifdef _WIN64
                    or  esi,FL_I64
endif
                .case 'X'
                    mov hexoff,'A'-'9'-1
                    jmp COMMON_HEX
                .case 'x'
                    mov hexoff,'a'-'9'-1

                    COMMON_HEX:

                    mov curadix,16
                    .if esi & FL_ALTERNATE
                        mov eax,'x' - 'a' + '9' + 1
                        add eax,hexoff
                        mov prefix,'0'
                        mov prefix[1],al
                        mov prefixlen,2
                    .endif
                    jmp COMMON_INT
                .case 'o'
                    mov curadix,8
                    .if esi & FL_ALTERNATE
                        or esi,FL_FORCEOCTAL
                    .endif

                   COMMON_INT:

                    mov rcx,arglist
                    mov eax,[rcx]
                    xor edx,edx
                    .if esi & ( FL_I64 or FL_LONGLONG )
                        mov edx,[rcx+4]
ifndef _WIN64
                        add rcx,size_t
endif
                    .endif
                    add rcx,size_t
                    mov arglist,rcx
                    .if esi & FL_SHORT
                        .if esi & FL_SIGNED
                            movsx eax,ax
                        .else
                            movzx eax,ax
                        .endif
                    .elseif esi & FL_SIGNED
                        .if esi & FL_LONGLONG or FL_I64
                            .ifs edx < 0
                                or  esi,FL_NEGATIVE
                            .endif
                        .else
                            .ifs eax < 0
                                dec edx
                                or  esi,FL_NEGATIVE
                            .endif
                        .endif
                    .endif
                    .ifs edi < 0
                        mov edi,1
                    .else
                        and esi,NOT FL_LEADZERO
                    .endif
                    mov ecx,eax
                    or  ecx,edx
                    .ifz
                        mov prefixlen,eax
                    .endif
                    .if esi & FL_SIGNED
                        test edx,edx
                        .ifs
                            neg eax
                            neg edx
                            sbb edx,0
                            or  esi,FL_NEGATIVE
                        .endif
                    .endif

                    lea rbx,buffer[BUFFERSIZE-1]
ifdef _WIN64
                    mov r8,rbx
                    mov r9d,curadix
                    shl rdx,32
                    or  rax,rdx
                    .fors ( : rax || edi > 0 : edi-- )
                        xor edx,edx
                        div r9
                        add dl,'0'
                        .ifs dl > '9'
                            add dl,byte ptr hexoff
                        .endif
                        mov [rbx],dl
                        dec rbx
                    .endf
else
                    .fors ( : eax || edx || edi > 0 : edi-- )
                        .if ( !edx || !curadix )
                            div curadix
                            mov ecx,edx
                            xor edx,edx
                        .else
                            push esi
                            push edi
                            .for ( ecx = 64, esi = 0, edi = 0 : ecx : ecx-- )
                                add eax,eax
                                adc edx,edx
                                adc esi,esi
                                adc edi,edi
                                .if ( edi || esi >= curadix )
                                    sub esi,curadix
                                    sbb edi,0
                                    inc eax
                                .endif
                            .endf
                            mov ecx,esi
                            pop edi
                            pop esi
                        .endif
                        add ecx,'0'
                        .ifs ( ecx > '9' )
                            add ecx,hexoff
                        .endif
                        mov [ebx],cl
                        dec ebx
                    .endf
endif
                    lea rax,buffer[BUFFERSIZE-1]
                    sub rax,rbx
                    add rbx,1

                    .if esi & FL_FORCEOCTAL

                        .if byte ptr [rbx] != '0' || eax == 0

                            dec rbx
                            mov byte ptr [rbx],'0'
                            inc eax
                        .endif
                    .endif
                    mov text,rbx
                    mov textlen,eax
                   .endc
                .endsw

                .if !no_output
                    .if esi & FL_SIGNED
                        .if esi & FL_NEGATIVE
                            mov prefix,'-'
                            mov prefixlen,1
                        .elseif esi & FL_SIGN
                            mov prefix,'+'
                            mov prefixlen,1
                        .elseif esi & FL_SIGNSP
                            mov prefix,' '
                            mov prefixlen,1
                        .endif
                    .endif
                    mov eax,fldwidth
                    sub eax,textlen
                    sub eax,prefixlen
                    mov padding,eax
                    .if !( esi & ( FL_LEFT or FL_LEADZERO ) )
                        write_multi_char(' ', padding, fp, &charsout)
                    .endif
                    write_string(&prefix, prefixlen, fp, &charsout)
                    .if ( ( esi & FL_LEADZERO ) && !( esi & FL_LEFT ) )
                        write_multi_char('0', padding, fp, &charsout)
                    .endif
                    write_string(text, textlen, fp, &charsout)
                    .if esi & FL_LEFT
                        write_multi_char(' ', padding, fp, &charsout)
                    .endif
                .endif
                .endc
            .endsw
        .endif
    .endw
    mov eax,charsout ; return value = number of characters written
    ret

_output endp

sprintf proc __Cdecl string:LPSTR, format:LPSTR, argptr:VARARG

  local o:_iobuf

    mov o._flag,_IOWRT or _IOSTRG
    mov o._cnt,INT_MAX
    mov rax,string
    mov o._ptr,rax
    mov o._base,rax
    _output(&o, format, &argptr)
    mov rcx,o._ptr
    mov byte ptr [rcx],0
    ret

sprintf endp

ftobufin proc format:LPSTR, argptr:ptr

  local o:_iobuf

    mov o._flag,_IOWRT or _IOSTRG
    mov o._cnt,_INTIOBUF
    mov _bufin,0
    lea rax,_bufin
    mov o._ptr,rax
    mov o._base,rax
    _output(&o, format, argptr)
    mov rdx,o._ptr
    mov byte ptr [rdx],0
    lea rdx,_bufin
    ret

ftobufin endp

_print proc __Cdecl format:LPSTR, arglist:VARARG

    _write(1, &_bufin, ftobufin(format, &arglist))
    ret

_print endp

    end
