; MAIN.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include stdio.inc
include stdlib.inc
include malloc.inc
include dzstr.inc
include config.inc
ifdef _WIN64
include signal.inc
include minwinbase.inc
endif

doszip_init     proto :LPSTR
doszip_open     proto
doszip_modal    proto
doszip_close    proto

    .data

    DZTitle LPSTR cptitle
    cptitle db "Doszip Commander",0
    ctrl_shutdown dd 0

    .code

    dd 495A440Ah
    dd 564A4A50h
    db __LIBC__ / 100 + '0','.',__LIBC__ mod 100 / 10 + '0',__LIBC__ mod 10 + '0'


define DZ_CLOSE_EVENT 7

CtrlHandler proc private EventCode:UINT

    ldr ecx,EventCode

    .switch ecx
    .case CTRL_C_EVENT
    .case CTRL_BREAK_EVENT
    .case CTRL_CLOSE_EVENT
    .case CTRL_LOGOFF_EVENT
    .case CTRL_SHUTDOWN_EVENT
ifdef _WIN64
        mov ctrl_shutdown,ecx
endif
    .case DZ_CLOSE_EVENT
        doszip_close()
        tcloseall()
        .if CFGetSection("Exit")
            CFExecute(rax)
        .endif
    .endsw
ifdef _WIN64
    SetConsoleCtrlHandler( &CtrlHandler, 0 )
endif
    xor eax,eax
    ret

CtrlHandler endp


if defined(_WIN64) and not defined(__DEBUG__)

_exception_handler proc \
    ExceptionRecord   : PEXCEPTION_RECORD,
    EstablisherFrame  : PEXCEPTION_REGISTRATION_RECORD,
    ContextRecord     : PCONTEXT,
    DispatcherContext : LPDWORD

    .new flags[17]:sbyte
    .new signo:int_t = SIGTERM
    .new string:string_t = "Segment violation"

     mov eax,[rcx].EXCEPTION_RECORD.ExceptionFlags
    .switch
    .case eax & EXCEPTION_UNWINDING
    .case eax & EXCEPTION_EXIT_UNWIND
       .endc
    .case eax & EXCEPTION_STACK_INVALID
    .case eax & EXCEPTION_NONCONTINUABLE
        mov signo,SIGSEGV
       .endc
    .case eax & EXCEPTION_NESTED_CALL
        exit(1)

    .default
        mov eax,[rcx].EXCEPTION_RECORD.ExceptionCode
        .switch eax
        .case EXCEPTION_ACCESS_VIOLATION
        .case EXCEPTION_ARRAY_BOUNDS_EXCEEDED
        .case EXCEPTION_DATATYPE_MISALIGNMENT
        .case EXCEPTION_STACK_OVERFLOW
        .case EXCEPTION_IN_PAGE_ERROR
        .case EXCEPTION_INVALID_DISPOSITION
        .case EXCEPTION_NONCONTINUABLE_EXCEPTION
            mov signo,SIGSEGV
           .endc
        .case EXCEPTION_SINGLE_STEP
        .case EXCEPTION_BREAKPOINT
            mov signo,SIGINT
            mov string,&@CStr("Interrupt")
           .endc
        .case EXCEPTION_FLT_DENORMAL_OPERAND
        .case EXCEPTION_FLT_DIVIDE_BY_ZERO
        .case EXCEPTION_FLT_INEXACT_RESULT
        .case EXCEPTION_FLT_INVALID_OPERATION
        .case EXCEPTION_FLT_OVERFLOW
        .case EXCEPTION_FLT_STACK_CHECK
        .case EXCEPTION_FLT_UNDERFLOW
            mov signo,SIGFPE
            mov string,&@CStr("Floating point exception")
           .endc
        .case EXCEPTION_ILLEGAL_INSTRUCTION
        .case EXCEPTION_INT_DIVIDE_BY_ZERO
        .case EXCEPTION_INT_OVERFLOW
        .case EXCEPTION_PRIV_INSTRUCTION
            mov signo,SIGILL
            mov string,&@CStr("Illegal instruction")
           .endc
        .endsw
    .endsw

    .if ( signo == SIGTERM )

        exit( CtrlHandler(CTRL_CLOSE_EVENT) )
    .endif

    .for ( r11      = r8,
           r10      = rcx,
           r8d      = 0,
           rdx      = &flags,
           rax      = '00000000',
           [rdx]    = rax,
           [rdx+8]  = rax,
           [rdx+16] = r8b,
           eax      = [r11].CONTEXT.EFlags,
           ecx      = 16 : ecx : ecx-- )

        shr eax,1
        adc [rdx+rcx-1],r8b
    .endf

    mov rdx,[r11].CONTEXT._Rip
    mov rcx,[rdx-8]
    mov r8,[rdx]
    mov r9,[rdx+8]

    printf(
            "This message is created due to unrecoverable error\n"
            "and may contain data necessary to locate it.\n"
            "\n"
            "\tException:   %s\n"
            "\tCode: \t     %08X\n"
            "\tFlags:\t     %08X\n"
            "\tProcessor:\n"
            "\t\tRAX: %p R8:  %p\n"
            "\t\tRBX: %p R9:  %p\n"
            "\t\tRCX: %p R10: %p\n"
            "\t\tRDX: %p R11: %p\n"
            "\t\tRSI: %p R12: %p\n"
            "\t\tRDI: %p R13: %p\n"
            "\t\tRBP: %p R14: %p\n"
            "\t\tRSP: %p R15: %p\n"
            "\t\tRIP: %p:\n"
            "\t\t dq 0x%p ; [-8]\n"
            "\t\t dq 0x%p ; [-0]\n"
            "\t\t dq 0x%p ; [+8]\n"
            "\t     EFlags: %s\n"
            "\t\t     r n oditsz a p c\n",
            string,
            [r10].EXCEPTION_RECORD.ExceptionCode,
            [r10].EXCEPTION_RECORD.ExceptionFlags,
            [r11].CONTEXT._Rax, [r11].CONTEXT._R8,
            [r11].CONTEXT._Rbx, [r11].CONTEXT._R9,
            [r11].CONTEXT._Rcx, [r11].CONTEXT._R10,
            [r11].CONTEXT._Rdx, [r11].CONTEXT._R11,
            [r11].CONTEXT._Rsi, [r11].CONTEXT._R12,
            [r11].CONTEXT._Rdi, [r11].CONTEXT._R13,
            [r11].CONTEXT._Rbp, [r11].CONTEXT._R14,
            [r11].CONTEXT._Rsp, [r11].CONTEXT._R15,
            rdx, rcx, r8, r9, &flags)

    osread( 0, &string, 1 )
    exit( 1 )

_exception_handler endp

main proc frame:_exception_handler argc:int_t, argv:array_t

else

main proc argc:int_t, argv:array_t

endif

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
            printf(
                "The Doszip Commander Version %d.%02d" DOSZIP_VSTRPRE ", "
                "Copyright (C) 2023 Doszip Developers\n\n"
                "Command line switches\n"
                " The following switches may be used in the command line:\n"
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
                "is a folder.\n", VERSION / 100, VERSION mod 100 )
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
                .ifd filexist(rbx) == 2

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

    .ifd !doszip_init( rdi )

        .if nologo == 0
            printf( "The Doszip Commander Version %d.%02d" DOSZIP_VSTRPRE ", "
                "Copyright (C) 2014-2025 Doszip Developers\n\n", VERSION / 100, VERSION mod 100  )
        .endif

        doszip_open()
ifdef _WIN64
        SetConsoleCtrlHandler( &CtrlHandler, 1 )
endif
        doszip_modal()
        CtrlHandler(DZ_CLOSE_EVENT)
    .endif
    ret

main endp

include oldapi.inc

    end
