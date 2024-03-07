; MAIN.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include stdio.inc
include stdlib.inc
include malloc.inc
include string.inc
include config.inc
ifdef _WIN64
include signal.inc
define __SIGNAL__
endif

doszip_init proto :LPSTR
doszip_open proto
doszip_modal proto
doszip_close proto

    .data

    DZTitle LPSTR cptitle
    cptitle db "Doszip Commander",0

    .code

    dd 495A440Ah
    dd 564A4A50h
    db __LIBC__ / 100 + '0','.',__LIBC__ mod 100 / 10 + '0',__LIBC__ mod 10 + '0'

ifdef __SIGNAL__

GeneralFailure proc signo

    doszip_close()
    tcloseall()
    .if CFGetSection("Exit")
        CFExecute(rax)
    .endif

    mov ecx,signo
    mov eax,1
    .if ecx == SIGTERM || ecx == SIGABRT

        exit(0)
    .endif

    assume rbx:ptr CONTEXT
ifdef _WIN64
    lea rdi,@CStr(
            "\n"
            "This message is created due to unrecoverable error\n"
            "and may contain data necessary to locate it.\n"
            "\n"
            "\tRAX: %p R8:  %p\n"
            "\tRBX: %p R9:  %p\n"
            "\tRCX: %p R10: %p\n"
            "\tRDX: %p R11: %p\n"
            "\tRSI: %p R12: %p\n"
            "\tRDI: %p R13: %p\n"
            "\tRBP: %p R14: %p\n"
            "\tRSP: %p R15: %p\n"
            "\tRIP: %p %p\n"
            "\t     %p %p\n\n"
            "\tEFL: 0000000000000000\n"
            "\t     r n oditsz a p c\n\n" )
else
    lea edi,@CStr(
            "\n"
            "This message is created due to unrecoverable error\n"
            "and may contain data necessary to locate it.\n"
            "\n"
            "\tEAX: %p EDX: %p\n"
            "\tEBX: %p ECX: %p\n"
            "\tESI: %p EDI: %p\n"
            "\tESP: %p EBP: %p\n"
            "\tEIP: %p %p%p\n"
            "\t     %p %p\n\n"
            "\tEFL: 0000000000000000\n"
            "\t     r n oditsz a p c\n\n" )
endif

    mov rcx,__pxcptinfoptrs()
    mov rbx,[rcx].EXCEPTION_POINTERS.ContextRecord
    mov rsi,[rcx].EXCEPTION_POINTERS.ExceptionRecord
    mov eax,[rbx].EFlags
    mov ecx,16
    .repeat
        shr eax,1
        adc byte ptr [rdi+rcx+sizeof(@CStr(0))-43],0
    .untilcxz

ifdef _WIN64
    mov rdx,[rbx]._Rip
    mov rcx,[rdx]
    mov r10,[rdx-8]
    mov r11,[rdx+8]
    _print( rdi,
        [rbx]._Rax, [rbx]._R8,
        [rbx]._Rbx, [rbx]._R9,
        [rbx]._Rcx, [rbx]._R10,
        [rbx]._Rdx, [rbx]._R11,
        [rbx]._Rsi, [rbx]._R12,
        [rbx]._Rdi, [rbx]._R13,
        [rbx]._Rbp, [rbx]._R14,
        [rbx]._Rsp, [rbx]._R15,
        rdx, rcx, r10, r11 )
else
    mov edx,[ebx]._Eip
    _print( edi,
        [ebx]._Eax, [ebx]._Edx,
        [ebx]._Ebx, [ebx]._Ecx,
        [ebx]._Esi, [ebx]._Edi,
        [ebx]._Esp, [ebx]._Ebp,
        edx, [edx+4], [edx], [edx-4], [edx+8] )
endif
    assume rbx:nothing
    _read(0, &signo, 1)
    exit(1)
    ret

GeneralFailure endp

endif

main proc __Cdecl uses rsi rdi rbx argc:UINT, argv:ptr, environ:ptr

  local nologo:byte

    mov nologo,0
    mov esi,1
    xor edi,edi ; pointer to <filename>

    .while esi < argc

        mov rax,argv
        mov rbx,[rax+rsi*size_t]
        mov eax,[rbx]

        .switch al

        .case '?'
            _print(
                "The Doszip Commander Version " DOSZIP_VSTRING DOSZIP_VSTRPRE ", "
                "Copyright (C) 2023 Doszip Developers\n\n"
                "Command line switches\n"
                " The following switches may be used in the command line:\n"
                "\n"
                "  -N<file_count> - Maximum number of files in each panel\n"
                "     default is 5000.\n"
                "\n"
                "  -C<config_path> - Read/Write setup from/to <config_path>\n"
                "\n"
                "  -cmd - Start DZ and show only command prompt.\n"
                "\n"
                "  -E:<file> - Save environment block to <file>.\n"
                "\n"
                "  -nologo - Suppress copyright message.\n"
                "\n"
                "  DZ <filename> command starts DZ and forces it to show <filename>\n"
                "contents if it is an archive or show folder contents if <filename>\n"
                "is a folder.\n" )
            .return 0

        .case '-'
        .case '/'
            inc rbx
            shr eax,8
            .switch al
                ;
                ; @3.42 - save environment block to file
                ;
                ; Note: This is called inside a child process
                ;
            .case 'E'
                .gotosw(1: '?') .if ( ah != ':' )
                add rbx,2
                SaveEnvironment(rbx)
                exit(0)

            .case 'N'
                inc rbx
                .if strtolx(rbx)
                    mov numfblock,eax
                .endif
                .endc
            .case 'n'
                .gotosw(1: '?') .if eax != "lon"
                mov nologo,1
                .endc
            .case 'c'
                .gotosw(1: '?') .if eax != "dmc"
                mov edi,1
                .endc
            .case 'C'
                inc rbx
                .if filexist(rbx) == 2

                    free(_pgmpath)
                    _strdup(rbx)
                    mov _pgmpath,rax
                    .endc
                .endif
            .default
                .gotosw(1: '?')
            .endsw
            .endc
        .default
            mov rdi,rbx
        .endsw
        inc esi
    .endw

    SetConsoleTitle( DZTitle )

    .if !doszip_init( rdi )

        .if nologo == 0
            _print( "The Doszip Commander Version " DOSZIP_VSTRING DOSZIP_VSTRPRE ", "
                "Copyright (C) 2023 Doszip Developers\n\n" )
        .endif

        doszip_open()
ifdef __SIGNAL__
        lea rbx,GeneralFailure
        signal( SIGINT,   rbx ) ; interrupt
        signal( SIGILL,   rbx ) ; illegal instruction - invalid function image
        signal( SIGFPE,   rbx ) ; floating point exception
        signal( SIGSEGV,  rbx ) ; segment violation
        signal( SIGTERM,  rbx ) ; Software termination signal from kill
        signal( SIGABRT,  rbx ) ; abnormal termination triggered by abort call

        doszip_modal()
        GeneralFailure(SIGTERM)
else
        doszip_modal()
        doszip_close()
        tcloseall()

        .if CFGetSection("Exit")
            CFExecute(rax)
        .endif
        xor eax,eax
endif
    .endif
    ret

main endp

include oldapi.inc

    end
