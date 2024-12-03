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
include syserr.inc
include stdlib.inc
include malloc.inc
include wsub.inc

public _diskflag

    .data
     _diskflag dd 0
     drvinfo DISK MAXDRIVES dup(<?>)
     push_button db "&A",0

    .code

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

_disk_valid proc private drive:SINT

    GetLogicalDrives()
    mov ecx,drive
    dec ecx
    shr eax,cl
    sbb eax,eax
    and eax,1
    ret

_disk_valid endp

_disk_type proc disk:UINT

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

_disk_exist proc disk:UINT

    ldr eax,disk
    .if ( eax == 0 || eax > MAXDRIVES )
        .return( 0 )
    .endif
    dec  eax
    imul eax,eax,DISK
    lea  rdx,drvinfo
    add  rdx,rax
    xor  eax,eax
    .if ( eax != [rdx].DISK.flag )
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
        mov rcx,_sys_err_msg(_get_errno(NULL))
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

   .new d:dword = clock()

    mov edi,GetLogicalDrives()
    lea rbx,drvinfo

    .for ( esi = 0 : esi < MAXDRIVES : esi++, rbx += DISK )

        mov [rbx].DISK.flag,0
        bt  edi,esi
        .ifc
            lea ecx,[rsi+1]
            .ifd ( _disk_type(ecx) > 1 )

                mov edx,_FB_ROOTDIR or _A_VOLID
                .if eax == DRIVE_CDROM
                    or edx,_FB_CDROOM
                .endif
                mov [rbx].DISK.flag,edx
            .endif
            mov [rbx].DISK.time,d
        .endif
    .endf
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
