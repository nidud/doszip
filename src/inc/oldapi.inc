; OLDAPI.INC--
;
; Copyright (c) The Doszip Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

ifndef _WIN64

if ( _WIN32_WINNT LT 0x0500 )

    .data
     GetConsoleWindow GetConsoleWindow_T GetConsoleWindow_dummy

    .code

GetConsoleWindow_dummy proc WINAPI private
    xor eax,eax
    ret
GetConsoleWindow_dummy endp

GetConsoleWindow_Install proc private

    .if GetModuleHandle("kernel32.dll")
        .if GetProcAddress( rax, "GetConsoleWindow" )
            mov GetConsoleWindow,rax
        .else
            and console,not CON_CLIPB
            or  console,CON_WIN95
        .endif
    .endif
    xor eax,eax
    ret

GetConsoleWindow_Install endp

endif

if ( WINVER LT 0x0500 )

    .data
     GetKeyState GetKeyState_T GetKeyState_dummy
     SetWindowPos SetWindowPos_T SetWindowPos_dummy

    .code

GetKeyState_dummy proc WINAPI private key:SINT
    xor eax,eax
    ret
GetKeyState_dummy endp

SetWindowPos_dummy proc WINAPI private a:HWND, b:HWND, c:SINT, d:SINT, e:SINT, f:SINT, g:UINT
    xor eax,eax
    ret
SetWindowPos_dummy endp

GetKeyState_Install proc private uses rbx

    .if GetModuleHandle("user32.dll")
        mov rbx,rax
        .if GetProcAddress(rbx, "GetKeyState")
            mov GetKeyState,rax
        .endif
        .if GetProcAddress(rbx, "SetWindowPos")
            mov SetWindowPos,rax
        .endif
    .endif
    ret

GetKeyState_Install endp

endif

if ( WINVER LT 0x0502 )

    .data
     GetFileSizeEx GetFileSizeEx_T GetFileSizeEx_dummy
     SetFilePointerEx SetFilePointerEx_T SetFilePointerEx_dummy

    .code

GetFileSizeEx_dummy proc WINAPI private hFile:HANDLE, lpFileSize:PLARGE_INTEGER

    .if GetFileSize( hFile, lpFileSize )

        mov rdx,lpFileSize
        mov [rdx],eax
        xor eax,eax
        mov [rdx+4],eax
        inc eax
    .endif
    ret

GetFileSizeEx_dummy endp

SetFilePointerEx_dummy proc WINAPI private hFile:HANDLE, liDistanceToMove:LARGE_INTEGER,
        lpNewFilePointer:PLARGE_INTEGER, dwMoveMethod:DWORD

    mov eax,DWORD PTR liDistanceToMove
    mov edx,DWORD PTR liDistanceToMove[4]
    mov rcx,lpNewFilePointer
    add rcx,4
    mov [rcx],edx

    .if SetFilePointer(
        hFile,      ;; handle of file
        eax,        ;; number of bytes to move file pointer
        rcx,        ;; pointer to high-order DWORD of distance to move
        dwMoveMethod ) != -1 ;; how to move

        mov rdx,lpNewFilePointer
        mov [rdx],eax
        mov eax,1
    .else
        dec rax
    .endif
    ret

SetFilePointerEx_dummy endp

GetFileSizeEx_Install proc private uses rbx

    .if GetModuleHandle("kernel32.dll")
        mov rbx,rax
        .if GetProcAddress(rbx, "GetFileSizeEx")
            mov GetFileSizeEx,rax
        .endif
        .if GetProcAddress(rbx, "SetFilePointerEx")
            mov SetFilePointerEx,rax
        .endif
    .endif
    ret

GetFileSizeEx_Install endp

endif

if ( _WIN32_WINNT LT 0x0500 )
.pragma init(GetConsoleWindow_Install, 6)
endif
if ( WINVER LT 0x0500 )
.pragma init(GetKeyState_Install, 6)
endif
if ( WINVER LT 0x0502 )
.pragma init(GetFileSizeEx_Install, 7)
endif

endif
