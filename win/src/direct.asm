; DIRECT.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include direct.inc
include string.inc
include time.inc
include io.inc
include conio.inc
include errno.inc
include stdlib.inc
include malloc.inc
include wsub.inc


    .data
     _diskflag dd 0
     drvinfo DISK MAXDRIVES dup(<?>)
     push_button db "&A",0

    .code

_chdir proc directory:LPSTR

  local root
  local abspath[_MAX_PATH]:byte

    .repeat
        .repeat
            .ifd SetCurrentDirectory(directory)

                .ifd GetCurrentDirectory(_MAX_PATH, &abspath)

                    mov ecx,dword ptr abspath
                    .if ch == ':'

                        mov eax,0x003A003D
                        mov ah,cl
                        .if ah >= 'a' && ah <= 'z'
                            sub ah,'a' - 'A'
                        .endif
                        mov root,eax
                        .break .ifd !SetEnvironmentVariable(&root, &abspath)
                    .endif
                    xor eax,eax
                    .break(1)
                .endif
            .endif
        .until 1
        osmaperr()
    .until 1
    ret

_chdir endp

_mkdir proc uses rbx directory:LPSTR

    .ifd !CreateDirectoryA(directory, 0)

        .if __allocwpath(directory)

            mov rbx,rax
            add rax,8
            .ifd !CreateDirectoryW(rax, 0)

                CreateDirectoryW(rbx, 0)
            .endif
            mov rcx,rbx
            mov ebx,eax
            free(rcx)
            mov eax,ebx
        .endif
    .endif

    .if ( eax == 0 )
        osmaperr()
    .else
        mov _diskflag,1
        xor eax,eax
    .endif
    ret

_mkdir endp

_rmdir proc uses rbx directory:LPSTR

    .ifd !RemoveDirectoryA(directory)

        .if __allocwpath(directory)

            mov rbx,rax
            RemoveDirectoryW(rbx)
            mov rcx,rbx
            mov ebx,eax
            free(rcx)
            mov eax,ebx
        .endif
    .endif
    .if ( eax == 0 )
        osmaperr()
    .else
        xor eax,eax
    .endif
    ret

_rmdir endp

_getdcwd proc private uses rdi drive:SINT, buffer:LPSTR, maxlen:SINT

    mov rdi,malloc( maxlen )
    ;
    ; GetCurrentDirectory only works for the default drive
    ;
    .if ( drive == 0 ) ; 0 = default, 1 = 'a:', 2 = 'b:', etc.

        GetCurrentDirectoryA( maxlen, rdi )
    .else
        ;
        ; Not the default drive - make sure it's valid.
        ;
        GetLogicalDrives()
        mov ecx,drive
        shr eax,cl
        .ifnc

            free( rdi )
            mov _doserrno,ERROR_INVALID_DRIVE
            mov errno,EACCES
           .return 0
        .endif
        ;
        ; Get the current directory string on that drive and its length
        ;
       .new path[4]:char_t

        add cl,'A'-1
        mov path[0],cl
        mov path[1],':'
        mov path[2],'.'
        mov path[3],0

        GetFullPathNameA( &path, maxlen, rdi, 0 )
    .endif
    ;
    ; API call failed, or buffer not large enough
    ;
    .if ( eax > maxlen )

        free( rdi )
        mov errno,ERANGE
        .return 0

    .elseif ( eax )

        mov rax,rdi
        mov rcx,buffer

        .if ( rcx )

            strcpy( rcx, rdi )
            free( rdi )
            mov rax,buffer
        .endif
    .endif
    ret

_getdcwd endp

_getcwd proc buffer:LPSTR, maxlen:SINT

    _getdcwd(0, buffer, maxlen)
    ret

_getcwd endp

GetVolumeID proc lpRootPathName:LPSTR, lpVolumeNameBuffer:LPSTR

  local MaximumComponentLength, FileSystemFlags

    GetVolumeInformation(
        lpRootPathName,
        lpVolumeNameBuffer,
        64, ; length of lpVolumeNameBuffer
        0,  ; address of volume serial number
        &MaximumComponentLength,
        &FileSystemFlags,
        0,  ; address of name of file system
        0 ) ; length of lpFileSystemNameBuffer
    ret

GetVolumeID endp

GetFileSystemName proc lpRootPathName:LPSTR, lpFileSystemNameBuffer:LPSTR

  local MaximumComponentLength, FileSystemFlags

    GetVolumeInformation(
        lpRootPathName,
        0,
        0,
        0,
        &MaximumComponentLength,
        &FileSystemFlags,
        lpFileSystemNameBuffer,
        32)
    ret

GetFileSystemName endp

_getdrive proc

  local b[512]:byte

    .ifd GetCurrentDirectory(512, &b)

ifdef _UNICODE
        mov al,b
        mov ah,b[2]
else
        mov ax,word ptr b
endif
        .if ah == ':'

            movzx eax,al
            or    al,0x20
            sub   al,'a' - 1  ; A: == 1
        .else
            xor eax,eax
        .endif
    .else
        osmaperr()
    .endif
    ret

_getdrive endp

_chdrive proc drive:SINT

    mov eax,drive
    .ifs eax > 0 || eax > 31

        add al,'A' - 1
        mov ah,':'
        mov drive,eax

        .ifd SetCurrentDirectory(&drive)

            xor eax,eax
        .else
            osmaperr()
        .endif
    .else
        mov errno,EACCES
        mov _doserrno,ERROR_INVALID_DRIVE
        or  eax,-1
    .endif
    ret

_chdrive endp

_disk_valid proc private drive:SINT

    GetLogicalDrives()
    mov ecx,drive
    dec ecx
    shr eax,cl
    sbb eax,eax
    and eax,1
    ret

_disk_valid endp

_disk_type proc uses rdx rcx disk:UINT

  local path[2]:dword

    mov eax,'\: '
    mov al,byte ptr disk
    add al,'A'-1
    mov path,eax
    xor eax,eax
    mov path[4],eax
    GetDriveType(&path)
    ret

_disk_type endp

_disk_test proc private disk:UINT

    .ifd _disk_ready(disk)
        .ifd _disk_type(disk) < 2
            .repeat
                .ifd _disk_retry(disk)
                    _disk_ready(disk)
                .endif
            .until eax
        .else
            mov eax,1
        .endif
    .endif
    ret

_disk_test endp

_disk_init proc uses rdi disk:UINT

    mov edi,disk
    .ifd !_disk_test(edi)
        .ifd _disk_select("Select disk")
            mov edi,_disk_init(eax)
        .endif
    .endif
    mov eax,edi
    ret

_disk_init endp

_disk_exist proc uses rdx disk:UINT

    mov eax,DISK
    mov edx,disk
    dec edx
    mul edx
    lea rdx,drvinfo
    add rdx,rax
    xor eax,eax
    .if [rdx].DISK.flag != eax
        mov rax,rdx
    .endif
    ret

_disk_exist endp

_disk_retry proc private uses rsi rdi rbx disk:UINT

    .if rsopen(IDD_DriveNotReady)

        mov rdi,rax
        dlshow(rax)

        movzx ebx,[rdi].DOBJ.rc.x
        add   ebx,25
        movzx esi,[rdi].DOBJ.rc.y
        add   esi,2
        mov   eax,disk
        add   al,'A' - 1
        scputc(ebx, edx, 1, eax)

        sub ebx,22
        add esi,2
        mov eax,errno
        lea rcx,_sys_errlist
        mov rcx,[rcx+rax*LPSTR]
        scputs(ebx, esi, 0, 29, rcx)
        dlmodal(rdi)
    .endif
    ret

_disk_retry endp

_disk_ready proc disk

  local MaximumComponentLength:dword,
        FileSystemFlags:dword,
        RootPathName[2]:dword,
        FileSystemNameBuffer[32]:word

    mov eax,disk
    inc eax
    .ifd _disk_valid(eax)

        mov eax,'\: '
        mov al,byte ptr disk
        add al,'A' - 1
        mov RootPathName,eax
        GetVolumeInformation(&RootPathName, 0, 0, 0, &MaximumComponentLength,
                &FileSystemFlags, &FileSystemNameBuffer, 32)
    .endif
    ret

_disk_ready endp

_disk_select proc uses rsi rdi rbx msg:LPSTR

  local dobj:DOBJ
  local tobj[MAXDRIVES]:TOBJ

    mov ebx,_getdrive()
    _disk_read()
    mov dword ptr dobj.flag,_D_STDDLG
    mov dobj.rc,0x003F0908
    lea rdi,tobj
    mov dobj.object,rdi
    mov esi,1

    .repeat

        .ifd _disk_exist(esi)

            movzx eax,dobj.count
            inc dobj.count
            mov [rdi].TOBJ.flag,_O_PBKEY
            mov ecx,eax
            .if esi == ebx

                mov al,dobj.count
                dec al
                mov dobj.index,al
            .endif

            mov eax,esi
            add al,'@'
            mov [rdi].TOBJ.ascii,al
            mov eax,0x01050000
            mov al,cl
            shr al,3
            shl al,1
            add al,2
            mov ah,al
            and cl,7
            mov al,cl
            shl al,3
            sub al,cl
            add al,4
            mov [rdi].TOBJ.rc,eax
            add rdi,TOBJ
        .endif
        inc esi
    .until esi > MAXDRIVES

    movzx eax,dobj.count
    dec eax
    mov ebx,eax
    shr eax,3
    shl eax,1
    add al,5
    mov dobj.rc.row,al
    mov eax,ebx

    .if eax <= 7
        shl eax,3
        sub eax,ebx
        add eax,14
        mov dobj.rc.col,al
        mov cl,byte ptr _scrcol
        sub cl,al
        shr cl,1
        mov dobj.rc.x,cl
    .endif

    xor edi,edi
    mov bl,at_foreground[F_Dialog]
    or  bl,at_background[B_Dialog]

    .if dlopen(&dobj, ebx, msg)

        lea rsi,tobj
        mov bl,[rsi].TOBJ.rc.col

        .while 1

            movzx eax,dobj.count
            .break .if edi >= eax
            mov al,[rsi].TOBJ.ascii
            mov push_button[1],al
            mov al,dobj.rc.col
            rcbprc([rsi].TOBJ.rc, dobj.wp, eax)
            movzx ecx,dobj.rc.col
            wcpbutt(rax, ecx, ebx, &push_button)
            inc edi
            add rsi,TOBJ
        .endw
        mov edi,dlmodal(&dobj)
    .endif

    xor eax,eax
    .if edi

        or    al,dobj.index
        imul  eax,eax,TOBJ
        add   rax,dobj.object
        movzx eax,[rax].TOBJ.ascii
        sub   al,'@'
    .endif
    ret

_disk_select endp

_disk_read proc uses rsi rdi rbx

    mov esi,clock()
    mov edi,GetLogicalDrives()
    lea rbx,drvinfo
    mov ecx,1
    .repeat
        xor eax,eax
        mov [rbx].DISK.flag,eax
        shr edi,1
        .ifc
            .ifd _disk_type(ecx) > 1
                mov edx,_FB_ROOTDIR or _A_VOLID
                .if eax == DRIVE_CDROM
                    or edx,_FB_CDROOM
                .endif
                mov [rbx].DISK.flag,edx
            .endif
            mov [rbx].DISK.time,esi
        .endif
        add rbx,DISK
        inc ecx
    .until ecx == MAXDRIVES+1
    ret

_disk_read endp

InitDisk proc private

    lea rdx,drvinfo
    mov ecx,1
    mov eax,':A'
    .repeat
        mov dword ptr [rdx].DISK.name,eax
        mov dword ptr [rdx].DISK.size,ecx
        inc eax
        add rdx,DISK
        inc ecx
    .until ecx == MAXDRIVES+1
    _disk_read()
    ret

InitDisk endp

.pragma init(InitDisk, 70)

    END
