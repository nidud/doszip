; PROCESS.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include io.inc
include errno.inc
include process.inc
include string.inc
include conio.inc
include malloc.inc
include direct.inc
include stdlib.inc
include config.inc
include winbase.inc

externdef _diskflag:int_t
externdef envtemp:string_t

    .data
     _errormode UINT 5

    .code

process proc private uses rsi rdi lpProgram:LPSTR, lpCommand:LPSTR, CreationFlags:dword

  local PI:PROCESS_INFORMATION, SINFO:STARTUPINFO, ConsoleMode:dword

    xor eax,eax
    lea rdi,PI
    mov rsi,rdi
    mov ecx,PROCESS_INFORMATION
    rep stosb
    lea rdi,SINFO
    mov ecx,STARTUPINFO
    rep stosb
    lea rdi,SINFO
    mov SINFO.cb,STARTUPINFO
    _set_errno(eax)
    SetErrorMode(_errormode)
    GetConsoleMode(_coninpfh, &ConsoleMode)

    ; added v3.59 - Windows 10 console
    SetConsoleMode(_coninpfh, OldConsoleMode)

    mov edx,CreationFlags
    and edx,CREATE_NEW_CONSOLE or DETACHED_PROCESS
    xor eax,eax
    mov edi,CreateProcess(lpProgram, lpCommand, rax, rax, eax, edx, rax, rax, rdi, rsi)
    mov rsi,PI.hProcess
    _dosmaperr( GetLastError() )

    .if edi
        .if !( CreationFlags & _P_NOWAIT )
            WaitForSingleObject(rsi, INFINITE)
        .endif
        CloseHandle(rsi)
        CloseHandle(PI.hThread)
    .endif

    mov _confh, GetStdHandle(STD_OUTPUT_HANDLE)
    mov _coninpfh,GetStdHandle(STD_INPUT_HANDLE)
    SetConsoleMode(rax, ConsoleMode)
    SetErrorMode(SEM_FAILCRITICALERRORS)
    mov _diskflag,3

    mov eax,edi
    ret

process endp


system proc uses rdi rsi rbx string:LPSTR

   .new arg0[_MAX_PATH]:char_t
   .new quote:int_t

    mov rbx,alloca(MAXCMDL)
    mov BYTE PTR [rbx],0
    mov rdi,string

    mov edx,' '
    .if ( byte ptr [rdi] == '"' )

        inc rdi
        mov edx,'"'
    .endif
    mov quote,edx

    xor esi,esi
    .if strchr(rdi, edx)

        mov byte ptr [rax],0
        mov rsi,rax
    .endif

    strncpy(&arg0, rdi, _MAX_PATH-1)

    .if rsi
        mov edx,quote
        mov [rsi],dl
        .if dl == '"'
            inc rsi
        .endif
    .else
        add strlen(string),string
        mov rsi,rax
    .endif

    mov rdi,rsi
    strcat(strcpy(rbx, __pCommandCom), " ")

    mov rcx,__pCommandArg
    .if byte ptr [rcx]

        strcat(strcat(rbx, rcx), " ")
    .endif

    lea rsi,arg0
    .if strchr(rsi, ' ')
        strcat(strcat(strcat(rbx, "\""), rsi), "\"")
    .else
        strcat(rbx, rsi)
    .endif
    process(0, strcat(rbx, rdi), 0)
    ret

system endp

CreateBatch proc uses rbx cmd:string_t, CallBatch:int_t, UpdateEnviron:int_t

  local batch[_MAX_PATH]:char_t, argv0[_MAX_PATH]:char_t

    strfcat( &batch, envtemp, "dzcmd.bat" )
    .return .ifd ( osopen(rax, 0, M_WRONLY, A_CREATETRUNC) == -1 )

    mov ebx,eax
    mov _diskflag,1
    oswrite(ebx, "@echo off\r\n", 11)
    .if CallBatch
        oswrite(ebx, "call ", 5)
    .endif
    oswrite(ebx, cmd, strlen(cmd))
    oswrite(ebx, "\r\n", 2)

    .if UpdateEnviron

        mov rcx,__argv
        strcpy(&argv0, [rcx])
        strcat(strcat(strcat(rax, " /E:" ), envtemp), "\\dzcmd.env")

        oswrite(ebx, &argv0, strlen(rax))
        oswrite(ebx, "\r\n", 2)
    .endif
    _close(ebx)
    strcpy(cmd, &batch)
    ret

CreateBatch endp

CreateConsole proc uses rsi rdi rbx string:string_t, flag:uint_t

  local cmd[1024]:byte

    lea rdi,cmd
    mov esi,console
    and esi,CON_NTCMD

    strcat(strcpy(rdi, CFGetComspec(esi)), " ")

    .if __pCommandArg

        strcat(strcat(rdi, __pCommandArg), " ")
    .endif
    .if esi

        strcat(rdi, "\"")
    .endif
    lea rbx,[rdi+strlen(rdi)]
    .if strchr(strcat(rdi, string), 10)

        CreateBatch(rbx, 0, 0)
    .endif
    .if esi

        strcat(rdi, "\"")
    .endif
    mov eax,flag
    .if eax == _P_NOWAIT
        or eax,DETACHED_PROCESS
    .endif
    process(0, rdi, eax)
    SetKeyState()
    ret

CreateConsole endp

    END
