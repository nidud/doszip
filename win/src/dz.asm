; MAIN.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include stdio.inc
include stdlib.inc
include malloc.inc
include string.inc
include config.inc

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

    mov ecx,signo
    mov eax,1
    .if ecx == SIGTERM || ecx == SIGABRT

        doszip_close()
        .if cflag & _C_DELHISTORY

            historyremove()
        .endif
        tcloseall()
        ExecuteSection("Exit")
        xor eax,eax
    .endif
    exit(eax)
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
