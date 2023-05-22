; ERRNO.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include errno.inc
include kernel32.inc

    .data

errno      errno_t 0
_doserrno  errno_t 0

    T equ <@CStr>

_sys_errlist string_t \
    T("No error"),
    T("Operation not permitted"),               ;  1 EPERM
    T("No such file or directory"),             ;  2 ENOENT
    T("No such process"),                       ;  3 ESRCH
    T("Interrupted function call"),             ;  4 EINTR
    T("Input/output error"),                    ;  5 EIO
    T("No such device or address"),             ;  6 ENXIO
    T("Arg list too long"),                     ;  7 E2BIG
    T("Exec format error"),                     ;  8 ENOEXEC
    T("Bad file descriptor"),                   ;  9 EBADF
    T("No child processes"),                    ; 10 ECHILD
    T("Resource temporarily unavailable"),      ; 11 EAGAIN
    T("Not enough space"),                      ; 12 ENOMEM
    T("Permission denied"),                     ; 13 EACCES
    T("Bad address"),                           ; 14 EFAULT
    T("Unknown error"),                         ; 15 ENOTBLK
    T("Resource device"),                       ; 16 EBUSY
    T("File exists"),                           ; 17 EEXIST
    T("Improper link"),                         ; 18 EXDEV
    T("No such device"),                        ; 19 ENODEV
    T("Not a directory"),                       ; 20 ENOTDIR
    T("Is a directory"),                        ; 21 EISDIR
    T("Invalid argument"),                      ; 22 EINVAL
    T("Too many open files in system"),         ; 23 ENFILE
    T("Too many open files"),                   ; 24 EMFILE
    T("Inappropriate I/O control operation"),   ; 25 ENOTTY
    T("Unknown error"),                         ; 26 ETXTBSY
    T("File too large"),                        ; 27 EFBIG
    T("No space left on device"),               ; 28 ENOSPC
    T("Invalid seek"),                          ; 29 ESPIPE
    T("Read-only file system"),                 ; 30 EROFS
    T("Too many links"),                        ; 31 EMLINK
    T("Broken pipe"),                           ; 32 EPIPE
    T("Domain error"),                          ; 33 EDOM
    T("Result too large"),                      ; 34 ERANGE
    T("Unknown error"),                         ; 35 EUCLEAN
    T("Resource deadlock avoided"),             ; 36 EDEADLK
    T("Unknown error"),                         ; 37 UNKNOWN
    T("Filename too long"),                     ; 38 ENAMETOOLONG
    T("No locks available"),                    ; 39 ENOLCK
    T("Function not implemented"),              ; 40 ENOSYS
    T("Directory not empty"),                   ; 41 ENOTEMPTY
    T("Illegal byte sequence"),                 ; 42 EILSEQ
    T("Unknown error")

errnotable byte \
        EINVAL,
        ENOENT,
        ENOENT,
        EMFILE,
        EACCES,
        EBADF,
        ENOMEM,
        ENOMEM,
        ENOMEM,
        E2BIG,
        ENOEXEC,
        EINVAL,
        EINVAL,
        ENOENT,
        EACCES,
        EXDEV,
        ENOENT,
        EACCES,
        ENOENT,
        EACCES,
        ENOENT,
        EEXIST,
        EACCES,
        EACCES,
        EINVAL,
        EAGAIN,
        EACCES,
        EPIPE,
        ENOSPC,
        EBADF,
        EINVAL,
        ECHILD,
        ECHILD,
        EBADF,
        EINVAL,
        EACCES,
        ENOTEMPTY,
        EACCES,
        ENOENT,
        EAGAIN,
        EACCES,
        EEXIST,
        ENOENT,
        EAGAIN,
        ENOMEM

syserrtable dword \
        ERROR_INVALID_FUNCTION,
        ERROR_FILE_NOT_FOUND,
        ERROR_PATH_NOT_FOUND,
        ERROR_TOO_MANY_OPEN_FILES,
        ERROR_ACCESS_DENIED,
        ERROR_INVALID_HANDLE,
        ERROR_ARENA_TRASHED,
        ERROR_NOT_ENOUGH_MEMORY,
        ERROR_INVALID_BLOCK,
        ERROR_BAD_ENVIRONMENT,
        ERROR_BAD_FORMAT,
        ERROR_INVALID_ACCESS,
        ERROR_INVALID_DATA,
        ERROR_INVALID_DRIVE,
        ERROR_CURRENT_DIRECTORY,
        ERROR_NOT_SAME_DEVICE,
        ERROR_NO_MORE_FILES,
        ERROR_LOCK_VIOLATION,
        ERROR_BAD_NETPATH,
        ERROR_NETWORK_ACCESS_DENIED,
        ERROR_BAD_NET_NAME,
        ERROR_FILE_EXISTS,
        ERROR_CANNOT_MAKE,
        ERROR_FAIL_I24,
        ERROR_INVALID_PARAMETER,
        ERROR_NO_PROC_SLOTS,
        ERROR_DRIVE_LOCKED,
        ERROR_BROKEN_PIPE,
        ERROR_DISK_FULL,
        ERROR_INVALID_TARGET_HANDLE,
        ERROR_INVALID_HANDLE,
        ERROR_WAIT_NO_CHILDREN,
        ERROR_CHILD_NOT_COMPLETE,
        ERROR_DIRECT_ACCESS_HANDLE,
        ERROR_NEGATIVE_SEEK,
        ERROR_SEEK_ON_DEVICE,
        ERROR_DIR_NOT_EMPTY,
        ERROR_NOT_LOCKED,
        ERROR_BAD_PATHNAME,
        ERROR_MAX_THRDS_REACHED,
        ERROR_LOCK_FAILED,
        ERROR_ALREADY_EXISTS,
        ERROR_FILENAME_EXCED_RANGE,
        ERROR_NESTING_NOT_ALLOWED,
        ERROR_NOT_ENOUGH_QUOTA

    .code

osmaperr proc uses rbx

    mov edx,GetLastError()
    mov _doserrno,eax
    xor ecx,ecx
    mov rax,-1

    lea rbx,syserrtable
    .whiles ecx < 45

        .if edx == [rbx+rcx*4]

            lea rbx,errnotable
            movzx ecx,byte ptr [rbx+rcx]
            mov errno,ecx
           .return
        .endif
        inc ecx
    .endw
    .if edx >= ERROR_WRITE_PROTECT && edx <= ERROR_SHARING_BUFFER_EXCEEDED

        mov errno,EACCES
    .elseif edx >= ERROR_INVALID_STARTING_CODESEG && edx <= ERROR_INFLOOP_IN_RELOC_CHAIN

        mov errno,ENOEXEC
    .else
        mov errno,EINVAL
    .endif
    ret

osmaperr endp

    end
