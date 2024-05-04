include io.inc
include time.inc
include stdlib.inc
include malloc.inc
include stdio.inc
include string.inc
include errno.inc
include conio.inc
include confirm.inc
include wsub.inc
include doszip.inc

    .data
     _osfile BYTE \
        FH_OPEN or FH_DEVICE or FH_TEXT,
        FH_OPEN or FH_DEVICE or FH_TEXT,
        FH_OPEN or FH_DEVICE or FH_TEXT, _NFILE_ - 3 dup(0)

     align size_t
     _osfhnd    label HANDLE
     _coninpfh  HANDLE -1
     _confh     HANDLE -1, _NFILE_ - 2 dup(-1)
     STDI       IOST {0,0,0,0x8000,0,0,0,0,{0},{0},{0}}
     STDO       IOST {0,0,0,0x8000,0,0,0,0,{0},{0},{0}}
     oupdate    IOUPD 0
     _errormode UINT 5
     _nfile     UINT _NFILE_
     crctab UINT \
        000000000h, 077073096h, 0EE0E612Ch, 0990951BAh,
        0076DC419h, 0706AF48Fh, 0E963A535h, 09E6495A3h,
        00EDB8832h, 079DCB8A4h, 0E0D5E91Eh, 097D2D988h,
        009B64C2Bh, 07EB17CBDh, 0E7B82D07h, 090BF1D91h,
        01DB71064h, 06AB020F2h, 0F3B97148h, 084BE41DEh,
        01ADAD47Dh, 06DDDE4EBh, 0F4D4B551h, 083D385C7h,
        0136C9856h, 0646BA8C0h, 0FD62F97Ah, 08A65C9ECh,
        014015C4Fh, 063066CD9h, 0FA0F3D63h, 08D080DF5h,
        03B6E20C8h, 04C69105Eh, 0D56041E4h, 0A2677172h,
        03C03E4D1h, 04B04D447h, 0D20D85FDh, 0A50AB56Bh,
        035B5A8FAh, 042B2986Ch, 0DBBBC9D6h, 0ACBCF940h,
        032D86CE3h, 045DF5C75h, 0DCD60DCFh, 0ABD13D59h,
        026D930ACh, 051DE003Ah, 0C8D75180h, 0BFD06116h,
        021B4F4B5h, 056B3C423h, 0CFBA9599h, 0B8BDA50Fh,
        02802B89Eh, 05F058808h, 0C60CD9B2h, 0B10BE924h,
        02F6F7C87h, 058684C11h, 0C1611DABh, 0B6662D3Dh,
        076DC4190h, 001DB7106h, 098D220BCh, 0EFD5102Ah,
        071B18589h, 006B6B51Fh, 09FBFE4A5h, 0E8B8D433h,
        07807C9A2h, 00F00F934h, 09609A88Eh, 0E10E9818h,
        07F6A0DBBh, 0086D3D2Dh, 091646C97h, 0E6635C01h,
        06B6B51F4h, 01C6C6162h, 0856530D8h, 0F262004Eh,
        06C0695EDh, 01B01A57Bh, 08208F4C1h, 0F50FC457h,
        065B0D9C6h, 012B7E950h, 08BBEB8EAh, 0FCB9887Ch,
        062DD1DDFh, 015DA2D49h, 08CD37CF3h, 0FBD44C65h,
        04DB26158h, 03AB551CEh, 0A3BC0074h, 0D4BB30E2h,
        04ADFA541h, 03DD895D7h, 0A4D1C46Dh, 0D3D6F4FBh,
        04369E96Ah, 0346ED9FCh, 0AD678846h, 0DA60B8D0h,
        044042D73h, 033031DE5h, 0AA0A4C5Fh, 0DD0D7CC9h,
        05005713Ch, 0270241AAh, 0BE0B1010h, 0C90C2086h,
        05768B525h, 0206F85B3h, 0B966D409h, 0CE61E49Fh,
        05EDEF90Eh, 029D9C998h, 0B0D09822h, 0C7D7A8B4h,
        059B33D17h, 02EB40D81h, 0B7BD5C3Bh, 0C0BA6CADh,
        0EDB88320h, 09ABFB3B6h, 003B6E20Ch, 074B1D29Ah,
        0EAD54739h, 09DD277AFh, 004DB2615h, 073DC1683h,
        0E3630B12h, 094643B84h, 00D6D6A3Eh, 07A6A5AA8h,
        0E40ECF0Bh, 09309FF9Dh, 00A00AE27h, 07D079EB1h,
        0F00F9344h, 08708A3D2h, 01E01F268h, 06906C2FEh,
        0F762575Dh, 0806567CBh, 0196C3671h, 06E6B06E7h,
        0FED41B76h, 089D32BE0h, 010DA7A5Ah, 067DD4ACCh,
        0F9B9DF6Fh, 08EBEEFF9h, 017B7BE43h, 060B08ED5h,
        0D6D6A3E8h, 0A1D1937Eh, 038D8C2C4h, 04FDFF252h,
        0D1BB67F1h, 0A6BC5767h, 03FB506DDh, 048B2364Bh,
        0D80D2BDAh, 0AF0A1B4Ch, 036034AF6h, 041047A60h,
        0DF60EFC3h, 0A867DF55h, 0316E8EEFh, 04669BE79h,
        0CB61B38Ch, 0BC66831Ah, 0256FD2A0h, 05268E236h,
        0CC0C7795h, 0BB0B4703h, 0220216B9h, 05505262Fh,
        0C5BA3BBEh, 0B2BD0B28h, 02BB45A92h, 05CB36A04h,
        0C2D7FFA7h, 0B5D0CF31h, 02CD99E8Bh, 05BDEAE1Dh,
        09B64C2B0h, 0EC63F226h, 0756AA39Ch, 0026D930Ah,
        09C0906A9h, 0EB0E363Fh, 072076785h, 005005713h,
        095BF4A82h, 0E2B87A14h, 07BB12BAEh, 00CB61B38h,
        092D28E9Bh, 0E5D5BE0Dh, 07CDCEFB7h, 00BDBDF21h,
        086D3D2D4h, 0F1D4E242h, 068DDB3F8h, 01FDA836Eh,
        081BE16CDh, 0F6B9265Bh, 06FB077E1h, 018B74777h,
        088085AE6h, 0FF0F6A70h, 066063BCAh, 011010B5Ch,
        08F659EFFh, 0F862AE69h, 0616BFFD3h, 0166CCF45h,
        0A00AE278h, 0D70DD2EEh, 04E048354h, 03903B3C2h,
        0A7672661h, 0D06016F7h, 04969474Dh, 03E6E77DBh,
        0AED16A4Ah, 0D9D65ADCh, 040DF0B66h, 037D83BF0h,
        0A9BCAE53h, 0DEBB9EC5h, 047B2CF7Fh, 030B5FFE9h,
        0BDBDF21Ch, 0CABAC28Ah, 053B39330h, 024B4A3A6h,
        0BAD03605h, 0CDD70693h, 054DE5729h, 023D967BFh,
        0B3667A2Eh, 0C4614AB8h, 05D681B02h, 02A6F2B94h,
        0B40BBE37h, 0C30C8EA1h, 05A05DF1Bh, 02D02EF8Dh,

    .code

getosfhnd proc private handle:SINT

    mov rax,-1
    ldr ecx,handle
    .if ecx < _nfile
        lea rdx,_osfile
        .if byte ptr [rdx+rcx] & FH_OPEN
            lea rdx,_osfhnd
            mov rax,[rdx+rcx*size_t]
        .endif
    .endif
    ret

getosfhnd endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

osopen proc uses rbx file:LPSTR, attrib:UINT, mode:UINT, action:UINT

    .new len:int_t
    .new h:SINT
    .new share:SINT = 0

    .if ( mode != M_RDONLY )
        mov byte ptr _diskflag,1
    .endif
    .if ( mode == M_RDONLY )
        mov share,FILE_SHARE_READ
    .endif

    xor eax,eax
    lea rdx,_osfile

    .while ( byte ptr [rdx+rax] & FH_OPEN )

        inc eax
        .if eax == _nfile

            xor eax,eax
            mov _doserrno,eax ; no OS error
            mov errno,EBADF
            dec rax
           .return
        .endif
    .endw
    mov h,eax
    strlen(file)
    inc eax
    mov len,eax

    .ifd ( !MultiByteToWideChar(CP_UTF8, 0, file, eax, 0, 0) )

        dec rax
       .return
    .endif

    mov ebx,eax
    add eax,4 ; \\?\
    add eax,eax
    alloca(eax)
    mov ecx,ebx
    lea rbx,[rax+8]
    MultiByteToWideChar(CP_UTF8, 0, file, len, rbx, ecx)

    .ifd ( CreateFileW(rbx, mode, share, 0, action, attrib, 0) == -1 )

     ifdef  _WIN95
        .if ( console & CON_WIN95 )

            .return
        .endif
     endif

        osmaperr()
        .if ( edx != ERROR_FILENAME_EXCED_RANGE )

            .return
        .endif

        sub rbx,8
        mov eax,(('\' shl 16) or '\')
        mov [rbx],eax
        mov eax,(('?' shl 16) or '\')
        mov [rbx+4],eax
        .ifd ( CreateFileW(rbx, mode, share, 0, action, attrib, 0) == -1 )
            .return osmaperr()
        .endif
    .endif

    mov rdx,rax
    mov eax,h
    lea rcx,_osfile
    or  byte ptr [rcx+rax],FH_OPEN
    lea rcx,_osfhnd
    mov [rcx+rax*size_t],rdx
    ret

osopen endp

_close proc handle:int_t

    ldr ecx,handle
    lea rax,_osfile

    .if ( ecx < 3 || ecx >= _nfile || !( byte ptr [rax+rcx] & FH_OPEN ) )

        mov errno,EBADF
        mov _doserrno,0
        xor eax,eax

    .else

        mov byte ptr [rax+rcx],0
        lea rax,_osfhnd
        mov rcx,[rax+rcx*size_t]

        .ifd !CloseHandle( rcx )

            osmaperr()
        .else
            xor eax,eax
        .endif
    .endif
    ret

_close endp

osread proc h:SINT, b:PTR, size:UINT

  .new retval:UINT = 0

    ldr ecx,h
    lea rax,_osfhnd
    mov rcx,[rax+rcx*size_t]

    .ifd !ReadFile(rcx, b, size, &retval, 0)

        osmaperr()
       .return( 0 )
    .endif
    mov eax,retval
    ret

osread endp

oswrite proc h:SINT, b:PTR, size:UINT

  local NumberOfBytesWritten:dword

    ldr ecx,h
    lea rax,_osfhnd
    mov rcx,[rax+rcx*size_t]

    .ifd WriteFile(rcx, b, size, &NumberOfBytesWritten, 0)

        mov eax,NumberOfBytesWritten
        .if eax != size
            mov errno,ERROR_DISK_FULL
            xor eax,eax
        .endif
    .else
        osmaperr()
        xor eax,eax
    .endif
    ret

oswrite endp

_write proc uses rdi rsi rbx h:SINT, b:PTR, l:UINT

  local result, count, lb[1026]:byte

    mov eax,l
    .return .if !eax

    mov ebx,h
    .if ebx >= _NFILE_

        xor eax,eax
        mov _doserrno,eax
        mov errno,EBADF
        dec rax
       .return
    .endif
    lea rsi,_osfile
    mov bl,[rsi+rbx]

    .if bl & FH_APPEND

        _lseek(h, 0, SEEK_END)
    .endif

    xor eax,eax
    mov result,eax
    mov count,eax

    .if bl & FH_TEXT

        .for ( rsi = b :: )

            mov rax,rsi
            sub rax,b
            .break .if eax >= l

            lea rdi,lb
            .for ( :: rsi++, rdi++, count++ )

                lea rdx,lb
                mov rax,rdi
                sub rax,rdx
                .break .if eax >= 1024

                mov rax,rsi
                sub rax,b
                .break .if eax >= l

                mov al,[rsi]
                .if al == 10

                    mov byte ptr [rdi],13
                    inc rdi
                .endif
                mov [rdi],al
            .endf

            lea rax,lb
            mov rdx,rdi
            sub rdx,rax
            .ifd !oswrite(h, &lb, edx)

                inc result
               .break
            .endif
            lea rcx,lb
            mov rdx,rdi
            sub rdx,rcx
           .break .if eax < edx
        .endf
    .else

        .return .ifd oswrite(h, b, l)

        inc result
    .endif

    mov eax,count
    .if !eax
        .if eax == result
            .if _doserrno == 5 ; access denied

                mov errno,EBADF
            .endif
        .else

            mov edx,h
            lea rcx,_osfile
            mov dl,[rcx+rdx]
            .if dl & FH_DEVICE

                mov rbx,b
               .return .if byte ptr [rbx] == 26
            .endif
            mov errno,ENOSPC
            mov _doserrno,0
        .endif
        dec rax
    .endif
    ret

_write endp

_lseeki64 proc private handle:SINT, offs:QWORD, pos:UINT

  local lpNewFilePointer:QWORD

    ldr ecx,handle
    lea rax,_osfhnd
    mov rcx,[rax+rcx*size_t]

    .ifd !SetFilePointerEx( rcx, offs, &lpNewFilePointer, pos )

        osmaperr()
ifdef _WIN64
    .else
        mov rax,lpNewFilePointer
else
        cdq
    .else
        mov eax,DWORD PTR lpNewFilePointer
        mov edx,DWORD PTR lpNewFilePointer[4]
endif
    .endif
    ret

_lseeki64 endp

_lseek proc handle:SINT, offs:size_t, pos:UINT

ifdef _WIN64
    .if ( r8d == SEEK_SET )
        mov edx,edx
    .endif
    .return( _lseeki64( ecx, rdx, r8d ) )
else
    mov eax,offs
    cdq
    .if ( pos == SEEK_SET )
        xor edx,edx
    .endif
    .return( _lseeki64( handle, edx::eax, pos ) )
endif

_lseek endp

getfattr proc uses rsi rdi lpFilename:LPSTR

    .ifd GetFileAttributesA(lpFilename) == -1

        .if !__allocwpath(lpFilename)

            dec rax
           .return
        .endif
        mov rsi,rax
        .ifd GetFileAttributesW(rsi) == -1

            osmaperr()
        .endif
        mov edi,eax

        free(rsi)
        mov eax,edi
    .endif
    ret

getfattr endp

setfattr proc lpFilename:LPTSTR, Attributes:UINT

    .ifd !SetFileAttributes(lpFilename, Attributes)

        osmaperr()
    .else

        xor eax,eax
        mov byte ptr _diskflag,2
    .endif
    ret
setfattr endp

_access proc file:LPSTR, mode:UINT

    .ifd ( getfattr(file) == -1 )

;        osmaperr()

    .elseif ( ( mode & 2 ) && ( eax & _A_RDONLY ) )

        mov errno,EACCES
        mov eax,-1
    .else
        xor eax,eax
    .endif
    ret

_access endp

filexist proc file:LPSTR

    getfattr(file)
    inc eax
    .ifnz
        dec eax             ; 1 = file
        and eax,_A_SUBDIR   ; 2 = subdir
        shr eax,4
        inc eax
    .endif
    ret

filexist endp

_filelength proc handle:SINT

  local FileSize:QWORD

    mov ecx,handle
    lea rax,_osfhnd
    mov rcx,[rax+rcx*size_t]

    .ifd GetFileSizeEx( rcx, &FileSize )
ifdef _WIN64
        mov rax,FileSize
else
        mov edx,dword ptr FileSize[4]
        mov eax,dword ptr FileSize
endif
    .else
        osmaperr()
        xor eax,eax
    .endif
    ret

_filelength endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

getftime proc handle:SINT

  local FileTime:FILETIME

    .ifd getosfhnd(handle) != -1

        mov rcx,rax
        .ifd !GetFileTime(rcx, 0, 0, &FileTime)

            osmaperr()
        .else
            FileTimeToTime(&FileTime)
        .endif
    .endif
    ret

getftime endp

getftime_access proc handle:SINT

  local FileTime:FILETIME

    .ifd getosfhnd(handle) != -1

        mov rcx,rax
        .ifd !GetFileTime(rcx, 0, &FileTime, 0)

            osmaperr()
        .else
            FileTimeToTime(&FileTime)
        .endif
    .endif
    ret

getftime_access endp

getftime_create proc handle:SINT

  local FileTime:FILETIME

    .ifd getosfhnd(handle) != -1

        mov rcx,rax
        .ifd !GetFileTime(rcx, &FileTime, 0, 0)

            osmaperr()
        .else
            FileTimeToTime(&FileTime)
        .endif
    .endif
    ret

getftime_create ENDP

setftime proc uses rbx h:SINT, t:UINT

  local FileTime:FILETIME

    .ifd getosfhnd(h) != -1

        mov rbx,rax
        .ifd SetFileTime(rbx, 0, 0, TimeToFileTime(t, addr FileTime))

            xor eax,eax
            mov byte ptr _diskflag,2
        .else
            osmaperr()
        .endif
    .endif
    ret

setftime endp

setftime_create proc uses rbx h:SINT, t:UINT

  local FileTime:FILETIME

    .ifd getosfhnd(h) != -1

        mov rbx,rax
        .ifd SetFileTime(rbx, TimeToFileTime(t, &FileTime), 0, 0)

            xor eax,eax
            mov byte ptr _diskflag,2
        .else
            osmaperr()
        .endif
    .endif
    ret

setftime_create endp

setftime_access proc uses rbx h:SINT, t:UINT

  local FileTime:FILETIME

    .ifd getosfhnd(h) != -1

        mov rbx,rax
        .ifd SetFileTime(rbx, 0, TimeToFileTime(t, addr FileTime), 0)

            xor eax,eax
            mov byte ptr _diskflag,2
        .else
            osmaperr()
        .endif
    .endif
    ret

setftime_access endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove proc file:LPSTR

    .ifd DeleteFileA(file)

        xor eax,eax
        mov _diskflag,1
    .else
        osmaperr()
    .endif
    ret

remove endp

rename proc Oldname:LPSTR, Newname:LPSTR

    .ifd MoveFileA(Oldname, Newname)

        xor eax,eax
        mov _diskflag,1

    .else
        osmaperr()
    .endif
    ret

rename endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    assume rbx:PIOST

ioinit proc uses rsi rdi rbx io:PIOST, bsize:DWORD

    ldr rbx,io
    ldr esi,bsize

    mov edx,[rbx].file
    mov rdi,rbx
    mov ecx,IOST
    xor eax,eax
    rep stosb
    mov [rbx].file,edx
    dec [rbx].crc       ; CRC to FFFFFFFFh

    .if ( esi == OO_MEM64K )

        mov [rbx].size,esi

        _aligned_malloc(_SEGSIZE_, _SEGSIZE_)

    .else

        mov ecx,esi
        .if ( ecx == 0 )

            mov ecx,OO_MEM64K
        .endif
        mov [rbx].size,ecx

        .if malloc(ecx) && !esi

            mov [rbx].base,rax
            ioread(rbx)

            _filelength([rbx].file)

            stq [rbx].fsize
            .if ( dword ptr [rbx].fsize[4] == 0 && eax <= [rbx].cnt )

                or [rbx].flag,IO_MEMBUF
            .endif
            mov rax,[rbx].base
        .endif
    .endif
    mov [rbx].base,rax
    ret

ioinit endp

ioopen proc uses rbx io:PIOST, file:LPSTR, mode:DWORD, bsize:DWORD

    ldr rbx,io
    .if ( mode == M_RDONLY )
        openfile(file, mode, A_OPEN)
    .else
        ogetouth(file, mode)
    .endif
    .ifs ( eax > 0 ) ; -1, 0 (error, cancel), or handle

        mov [rbx].IOST.file,eax
        .ifd !ioinit(rbx, bsize)

            _close([rbx].file)
            ermsg(0, _sys_errlist[ENOMEM*size_t])
            xor eax,eax
        .else
            mov eax,[rbx].file
        .endif
    .endif
    ret

ioopen endp

    assume rcx:PIOST

iofree proc fastcall io:PIOST

    mov rax,[rcx].base
    mov [rcx].base,0
    free(rax)
    ret

iofree endp

ioclose proc uses rbx io:PIOST

    ldr rbx,io
    mov ecx,[rbx].file
    .if ecx != -1
        _close(ecx)
    .endif
    iofree(rbx)
    ret

ioclose endp

iotell proc fastcall io:PIOST

    ldq [rcx].total
    mov ecx,[rcx].index
    add rax,rcx
ifndef _WIN64
    adc edx,0
endif
    ret

iotell endp

ioseek proc uses rbx io:PIOST, offs:qword, from:DWORD

    ldr rbx,io
    ldq offs

    .if ( from == SEEK_CUR )

        mov ecx,[rbx].cnt
        sub ecx,[rbx].index

        .if ( rcx >= rax )

            add [rbx].index,eax
           .return
        .endif

    .elseif ( [rbx].flag & IO_MEMBUF )

        .if ( eax > [rbx].cnt )

            .return( -1 )
        .endif

        mov [rbx].index,eax
        stq [rbx].offs
       .return
    .endif

    .if ( _lseeki64( [rbx].file, _ARGQ, from ) != -1 )

        stq [rbx].offs
        mov [rbx].index,0
        mov [rbx].cnt,0
    .endif
    ret

ioseek endp

iogetc proc private uses rbx io:PIOST

    ldr rbx,io
    mov eax,[rbx].index

    .if ( eax == [rbx].cnt )

        .while 1

            .if !( [rbx].flag & IO_MEMBUF )

                .ifd ioread(rbx)

                    mov eax,[rbx].index
                   .break
                .endif
            .endif
            .return( -1 )
        .endw
    .endif
    inc [rbx].index
    add rax,[rbx].base
    movzx eax,byte ptr [rax]
    ret

iogetc endp

ioputc proc private uses rbx io:PIOST, c:int_t

    ldr rbx,io
    mov ecx,[rbx].index

    .if ( ecx == [rbx].size )

        .ifd ( ioflush(rbx) == 0 )

            .return 0
        .endif
        mov ecx,[rbx].index
    .endif

    mov eax,c
    add rcx,[rbx].base
    inc [rbx].index
    mov [rcx],al
    mov eax,1
    ret

ioputc endp

    assume rsi:PIOST
    assume rdi:PIOST

iocopy proc uses rsi rdi rbx ost:PIOST, ist:PIOST, len:qword

   .new base:ptr
   .new size:DWORD
   .new szh:SDWORD

    ldr rdi,ost
    ldr rsi,ist
ifdef _WIN64
    ldr rbx,len
    .if ( rbx == 0 )
else
    mov ebx,dword ptr len
    .if ( ebx == 0 && dword ptr len[4] == 0 )
endif
        .return( 1 ) ; copy zero byte is ok..
    .endif

    mov eax,[rsi].cnt ; if count is zero -- file copy
    sub eax,[rsi].index
    .ifz
        .ifd ( iogetc(rsi) == -1 )

            .return( 0 )
        .endif
        dec [rsi].index
        mov eax,[rsi].cnt
        sub eax,[rsi].index
       .return .ifz
    .endif

    mov edx,[rdi].size  ; copy max byte from STDI to STDO
    sub edx,[rdi].index
    .if edx <= eax
        mov eax,edx
    .endif
    .if ( dword ptr len[4] == 0 && ebx <= eax )
        mov eax,ebx
    .endif

    mov  ecx,eax
    mov  size,eax
    mov  eax,[rsi].index
    add  rax,[rsi].base
    mov  edx,[rdi].index
    add  rdx,[rdi].base
    xchg rax,rsi
    xchg rdx,rdi
    rep  movsb
    mov  rsi,rax
    mov  rdi,rdx
    mov  eax,size
    add  [rdi].index,eax
    add  [rsi].index,eax
    mov  edx,dword ptr len[4]

    sub ebx,eax
    sbb edx,0
    .if ( edx == 0 && ebx == 0 )

        .return( 1 )
    .endif

    mov eax,[rsi].cnt
    .if eax

        sub eax,[rsi].index ; flush inbuf
        .ifnz

            .repeat

                mov   eax,[rsi].index
                inc   [rsi].index
                add   rax,[rsi].base
                movzx eax,byte ptr [rax]
                mov   szh,edx

                .ifd ( ioputc(rdi, eax) == 0 )

                    .return
                .endif

                mov edx,szh
                sub ebx,eax
                sbb edx,0
                .if ( edx == 0 && ebx == 0 ) ; success if zero (inbuf > len)

                    .return( 1 )
                .endif

                mov eax,[rsi].index
                ;
                ; do byte copy from STDI to STDO
                ;
            .until ( eax == [rsi].cnt )
        .endif
    .endif

    mov szh,edx
    .ifd ( ioflush(rdi) == 0 ) ; flush STDO

        .return( 0 )
    .endif

    ;
    ; do block copy of bytes left
    ;

    mov base,[rdi].base
    mov size,[rdi].size
    mov [rdi].base,[rsi].base
    mov [rdi].size,[rsi].size

    .repeat

        .ifd ( ioread(rsi) == 0 )

            .break .if szh
            .break .if ebx
            inc eax
           .break
        .endif

        mov eax,[rsi].cnt
        .if ( szh == 0 && eax >= ebx )

            mov [rsi].index,ebx
            mov [rdi].index,ebx
            ioflush(rdi)
           .break
        .endif

        sub ebx,eax
        sbb szh,0
        mov [rdi].index,eax     ; fill STDO
        mov [rsi].index,eax     ; flush STDI
        ioflush(rdi)            ; flush STDO
    .until eax == 0             ; copy next block

    mov rcx,base
    mov [rdi].base,rcx
    mov ecx,size
    mov [rdi].size,ecx
    ret

iocopy endp

    assume rsi:nothing
    assume rdi:nothing

ioread proc uses rsi rdi rbx io:PIOST

    ldr rbx,io
    mov esi,[rbx].flag
    xor eax,eax
    .if ( esi & IO_MEMBUF )

        .return
    .endif

    mov edi,[rbx].cnt
    sub edi,[rbx].index
    .ifnz
        .if ( edi == [rbx].cnt )

            .return
        .endif
        mov eax,[rbx].index
        add rax,[rbx].base
        memcpy([rbx].base, rax, edi)
        xor eax,eax
    .endif

    mov [rbx].index,eax
    mov [rbx].cnt,edi
    mov ecx,[rbx].size
    sub ecx,edi
    mov eax,edi
    add rax,[rbx].base
    osread([rbx].file, rax, ecx)

    add [rbx].cnt,eax
    add eax,edi
    .return .ifz

    and esi,IO_UPDTOTAL or IO_USECRC or IO_USEUPD
    .ifz
        .return .if eax
    .endif

    .if ( esi & IO_UPDTOTAL )
ifdef _WIN64
        add [rbx].total,rax
else
        add dword ptr [rbx].total,eax
        adc dword ptr [rbx].total[4],0
endif
    .endif

    .if ( esi & IO_USECRC )

        push rax
        push rsi

        lea rsi,crctab
        add rdi,[rbx].base

        .for ( ecx = [rbx].crc, edx = 0 : eax : eax-- )

            mov dl,cl
            xor dl,[rdi]
            shr ecx,8
            xor ecx,[rsi+rdx*4]
            inc rdi
        .endf
        mov [rbx].crc,ecx
        pop rsi
        pop rax
    .endif

    .if ( esi & IO_USEUPD )

        mov edi,eax
        .ifd ( oupdate(rbx) == 0 )

            osmaperr()
            or [rbx].flag,IO_ERROR
            xor edi,edi
        .endif
        mov eax,edi
    .endif
    ret

ioread endp

iowrite proc uses rsi rdi rbx io:PIOST, buf:ptr, len:size_t

   .new count:DWORD = 0

    ldr rsi,buf
    ldr rbx,io

    .repeat

        mov rcx,len
        mov edi,[rbx].index
        mov eax,[rbx].size
        sub eax,edi
        add rdi,[rbx].base

        .if ( eax < ecx )

            add [rbx].index,eax
            sub len,rax
            mov rcx,rax
            add count,eax
            rep movsb

           .return .ifd !ioflush(rbx)
           .continue( 0 )
        .endif
        add count,ecx
        add [rbx].index,ecx
        rep movsb
    .until 1
    mov eax,count
    ret

iowrite endp

ioflush proc uses rsi rdi rbx io:PIOST

    ldr rbx,io
    mov eax,1
    mov ecx,[rbx].index
    .if ecx

        .if ( [rbx].flag & IO_USECRC )

            mov rdi,[rbx].base
            lea rsi,crctab
            mov eax,ecx

            .for ( ecx = [rbx].crc, edx = 0 : eax : eax-- )

                mov dl,cl
                xor dl,[rdi]
                shr ecx,8
                xor ecx,[rsi+rdx*4]
                inc rdi
            .endf
            mov [rbx].crc,ecx
        .endif

        .ifd ( oswrite([rbx].file, [rbx].base, [rbx].index) == [rbx].index )
ifdef _WIN64
            add [rbx].total,rax
else
            add [rbx].total_l,eax
            adc [rbx].total_h,0
endif
            mov [rbx].cnt,0
            mov [rbx].index,0
            mov eax,1
            .if ( [rbx].flag & IO_USEUPD )

                oupdate(rbx)
            .endif
        .else
            or [rbx].flag,IO_ERROR
        .endif
    .endif
    ret

ioflush endp


ogetc proc

    .return iogetc(&STDI)

ogetc endp

oseek proc uses rsi rdi offs:size_t, from:DWORD

    ldr rax,offs
ifdef _WIN64
    .if ( ioseek(&STDI, rax, from) != -1 )

        .if !( STDI.flag & IO_MEMBUF )

            mov rsi,rax
            ioread(&STDI)
            mov rax,rsi
else
    xor edx,edx
    .if ( ioseek(&STDI, edx::eax, from) != -1 )

        .if !( STDI.flag & IO_MEMBUF )

            mov esi,eax
            mov edi,edx
            ioread(&STDI)
            mov eax,esi
            mov edx,edi
endif
        .endif
    .endif
    ret

oseek endp


oread proc size:DWORD

    mov ecx,STDI.cnt
    sub ecx,STDI.index
    .if ( ecx < size )

        .ifd !ioread( &STDI )

            .return
        .endif
        mov ecx,STDI.cnt
        sub ecx,STDI.index
        .if ( ecx < size )
            .return( 0 )
        .endif
    .endif
    mov eax,STDI.index
    add rax,STDI.base
    ret

oread endp


oreadb proc uses rsi rdi rbx b:LPSTR, size:DWORD

    ldr rdi,b
    ldr ebx,size

    .ifd oread(ebx)

        memcpy(rdi, rax, ebx)
        mov eax,ebx

    .else

        xor esi,esi
        .while ( esi < ebx )

            .break .ifd ( ogetc() == -1 )
            stosb
            inc esi
        .endw
        mov eax,esi
    .endif
    ret

oreadb endp


oputc proc uses rbx c:SINT

    mov ebx,STDO.index
    .if ebx == STDO.size

        .ifd !ioflush(&STDO)

            .return
        .endif
        mov ebx,STDO.index
    .endif

    mov eax,c
    add rbx,STDO.base
    inc STDO.index
    mov [rbx],al
    mov eax,1
    ret

oputc endp


oungetc proc uses rbx

    .while 1

        mov eax,STDI.index
        .if eax

            dec STDI.index
            add rax,STDI.base
            movzx eax,byte ptr [rax-1]
           .return
        .endif

        .if STDI.flag & IO_MEMBUF

            .return -1
        .endif

        .if _lseeki64(STDI.file, 0, SEEK_CUR) == -1

            .return .if edx == -1
        .endif

        mov ebx,STDI.cnt  ; last read size to CX
        .if ebx > eax
            ;
            ; stream not align if above
            ;
            or STDI.flag,IO_ERROR
           .return -1
        .endif
        .return -1 .ifz ; EOF == top of file

        .if eax == STDI.size && dword ptr STDI.offs == 0

            .return -1
        .endif

        sub eax,ebx ; adjust offset to start
        mov ebx,STDI.size
        .if ebx >= eax

            mov ebx,eax
            xor eax,eax
        .else
            sub eax,ebx
        .endif

        .if oseek(eax, SEEK_SET) == -1

            .return
        .endif

        mov eax,ebx
        .if eax > STDI.cnt

            or STDI.flag,IO_ERROR
           .return -1
        .endif

        mov STDI.cnt,eax
        mov STDI.index,eax
    .endw
    ret

oungetc endp


oprintf proc __Cdecl uses rsi rbx format:LPSTR, argptr:VARARG

    mov ebx,ftobufin(format, &argptr)
    mov rsi,rdx

    .while 1

        lodsb
        movzx eax,al
        .break .if !eax

        .if ( eax == 10 )

            mov eax,STDO.file
            lea rcx,_osfile
            .if ( byte ptr [rcx+rax] & FH_TEXT )

                .ifd !oputc(13)

                    .break
                .endif
                inc ebx
            .endif
            mov eax,10
        .endif
        .break .ifd !oputc(eax)
    .endw
    .return(ebx)

oprintf endp

openfile proc fname:LPSTR, mode:uint_t, action:uint_t

    .ifd osopen(fname, _A_NORMAL, mode, action) == -1

        eropen(fname)
    .endif
    ret

openfile endp


ogetouth proc filename:LPSTR, mode:uint_t

    .ifd osopen(filename, _A_NORMAL, mode, A_CREATE) != -1

        .return
    .endif
    .if ( errno != EEXIST )
        .return eropen(filename)
    .endif

    mov eax,CONFIRM_DELETE
    .if confirmflag & CFDELETEALL

        confirm_delete(filename, 0)
    .endif

    .switch eax
    .case CONFIRM_JUMP
        .return 0
    .case CONFIRM_DELETEALL
        and confirmflag,not CFDELETEALL
    .case CONFIRM_DELETE
        setfattr(filename, 0)
        .return openfile(filename, mode, A_TRUNC)
    .endsw
    .return( -1 )

ogetouth endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

readword proc file:LPSTR

   .new result:int_t, h:int_t, len:int_t

    .ifd ( osopen(file, 0, M_RDONLY, A_OPEN) == -1 )

        .return( 0 )
    .endif

    mov h,eax
    mov len,osread(h, &result, 4)
    _close(h)
    xor eax,eax
    .if ( len > 1 )
        mov eax,result
    .endif
    ret

readword endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ogetl proc filename:LPSTR, buffer:LPSTR, bsize

    memset(&STDI, 0, sizeof(IOST))

    .ifd osopen(filename, _A_NORMAL, M_RDONLY, A_OPEN) != -1

        mov STDI.file,eax
        .if malloc(OO_MEM64K)

            mov STDI.base,rax
            mov STDI.size,OO_MEM64K
            mov STDI.line,bsize
            mov STDI.sptr,buffer
        .else
            _close(STDI.file)
            xor eax,eax
        .endif
    .else
        xor eax,eax
    .endif
    ret
ogetl endp

ogets proc uses rdi

    mov rdi,STDI.sptr
    mov ecx,STDI.line

    .repeat

        sub ecx,2

        .break .ifd ogetc() == -1
        .repeat

            .if al == 0x0D

                ogetc()
               .break(1)
            .endif
            .break .if al == 0x0A
            .break(1) .if !al
            mov [rdi],al
            inc rdi
            dec ecx
            .break .ifz
            ogetc()
        .until eax == -1
        inc al
    .until 1

    mov eax,0
    mov [rdi],al
    .ifnz
        mov rax,STDI.sptr
        mov rcx,rdi
        sub rcx,rax
        mov eax,1
    .endif
    ret

ogets endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SearchText proc private uses rsi rdi rbx pos:qword

   .new len:UINT
   .new n:Q64 = pos

    mov len,strlen(&searchstring)

    .while 1

        .break .if !eax

        xor edi,edi
        movzx ebx,searchstring

        .if ( STDI.flag & IO_SEARCHCASE )

            .while 1

                .ifd ogetc() == -1
ifndef _WIN64
                    cdq
endif
                   .break( 1 )
                .endif
ifdef _WIN64
                add n,1
else
                add n.q_l,1
                adc n.q_h,0
endif
                .break .if eax == ebx
                .continue(0) .if eax != 10
                inc edi
            .endw

        .else

            mov eax,ebx
            sub al,'A'
            cmp al,'Z'-'A'+1
            sbb edx,edx
            and edx,'a'-'A'
            add eax,edx
            add eax,'A'
            mov ebx,eax     ; tolower(*searchstring)

            .while 1

                .ifd ogetc() == -1
ifndef _WIN64
                    cdq
endif
                   .break( 1 )
                .endif
ifdef _WIN64
                add n,1
else
                add n.q_l,1
                adc n.q_h,0
endif
                .break .if al == bl

                sub al,'A'
                cmp al,'Z'-'A'+1
                sbb ah,ah
                and ah,'a'-'A'
                add al,ah
                add al,'A'      ; tolower(AL)

                .break .if al == bl
                .continue(0) .if eax != 10
                inc edi
            .endw
        .endif

        add STDI.line,edi
        lea rsi,searchstring
        mov eax,len
        mov ecx,STDI.cnt
        sub ecx,STDI.index
        .if eax >= ecx

            xor eax,eax
            .if !( STDI.flag & IO_MEMBUF )
                ioread(&STDI)
            .endif
            .if !eax

                mov rax,-1
ifndef _WIN64
                cdq
endif
               .break
            .endif
        .endif

        .while 1

            .ifd ogetc() == -1
ifndef _WIN64
                cdq
endif
               .break( 1 )
            .endif

ifdef _WIN64
            add n,1
else
            add n.q_l,1
            adc n.q_h,0
endif
            inc rsi
            lea rdx,searchstring
            mov ecx,eax
            mov al,[rsi]
            .break .if !eax
            .continue(0) .if eax == ecx

            .if !( STDI.flag & IO_SEARCHCASE )

                mov ah,cl
                sub ax,'AA'
                cmp al,'Z'-'A' + 1
                sbb cl,cl
                and cl,'a'-'A'
                cmp ah,'Z'-'A' + 1
                sbb ch,ch
                and ch,'a'-'A'
                add ax,cx
                add ax,'AA'
                .continue(0) .if al == ah
            .endif

            mov rax,rsi
            sub rax,rdx
ifdef _WIN64
            sub n,rax
else
            sub n.q_l,eax
            sbb n.q_h,0
endif
            sub STDI.index,eax
            .continue(1)
        .endw

        mov rax,rsi
        sub rax,rdx
        inc eax
ifdef _WIN64
        sub n,rax
        mov rax,n
else
        sub n.q_l,eax
        sbb n.q_h,0
        mov eax,n.q_l
        mov edx,n.q_h
endif
        mov ecx,STDI.line
       .break
    .endw
    ret

SearchText endp

SearchHex proc private uses rsi rdi rbx pos:qword

   .new hex[128]:byte
   .new string:LPSTR
   .new hexstrlen:dword
   .new n:Q64 = pos

    xor ecx,ecx
    lea rsi,searchstring
    lea rdx,hex
    mov string,rdx

    .while 1

        .repeat
            mov al,[rsi]
            .break(1) .if !al
            inc rsi
            .continue(0) .if al < '0'
            .if al > '9'
                or al,0x20
                .continue(0) .if al > 'f'
                sub al,0x27
            .endif
            sub al,'0'
        .until 1
        mov ah,al
        .repeat
            mov al,[rsi]
            .if !al
                xchg al,ah
                .break
            .endif
            inc rsi
            .continue(0) .if al < '0'
            .if al > '9'
                or al,0x20
                .continue(0) .if al > 'f'
                sub al,0x27
            .endif
            sub al,'0'
        .until 1
        shl ah,4
        or  al,ah
        mov [rdx],al
        inc rdx
        inc ecx
    .endw
    mov hexstrlen,ecx

    .while 1

        mov rax,string
        movzx ebx,byte ptr [rax]
        mov edi,STDI.line

        .while 1

            .ifd ogetc() == -1
ifndef _WIN64
                cdq
endif
               .break( 1 )
            .endif
ifdef _WIN64
            add n,1
else
            add n.q_l,1
            adc n.q_h,0
endif
            .break .if al == bl
            .continue(0) .if eax != 10
            inc edi
        .endw

        mov STDI.line,edi
        mov rsi,string
        mov eax,hexstrlen
        mov ecx,STDI.cnt
        sub ecx,STDI.index

        .if eax >= ecx

            xor eax,eax
            .if !( STDI.flag & IO_MEMBUF )
                ioread(&STDI)
            .endif
            .if !eax

                mov rax,-1
ifndef _WIN64
                cdq
endif
               .break
            .endif
        .endif

        .while 1

            .ifd ogetc() == -1
ifndef _WIN64
                cdq
endif
               .break( 1 )
            .endif
ifdef _WIN64
            add n,1
else
            add n.q_l,1
            adc n.q_h,0
endif
            inc rsi
            mov rdx,string
            mov rcx,rsi
            sub rcx,rdx
            .if ecx == hexstrlen

                mov rax,rsi
                sub rax,rdx
                inc eax
ifdef _WIN64
                sub n,rax
                mov rax,n
else
                sub n.q_l,eax
                sbb n.q_h,0
                mov eax,n.q_l
                mov edx,n.q_h
endif
                mov ecx,STDI.line
               .break(1)
            .endif
            .break .if al != [rsi]
        .endw
        mov rax,rsi
        sub rax,rdx
ifdef _WIN64
        sub n,rax
else
        sub n.q_l,eax
        sbb n.q_h,0
endif
        sub STDI.index,eax
    .endw
    ret

SearchHex endp

osearch proc
ifdef _WIN64
    mov rax,STDI.offs
    mov ecx,STDI.flag
    and STDI.flag,not (IO_SEARCHSET or IO_SEARCHCUR)

    .if ecx & IO_SEARCHSET
        xor eax,eax
    .elseif !(ecx & IO_SEARCHCUR)
        add rax,1 ; offset++ (continue)
    .endif

    ioseek(&STDI, rax, SEEK_SET)
    .if eax != -1
        .if STDI.flag & IO_SEARCHHEX
            SearchHex(rax)
        .else
            SearchText(rax)
        .endif
    .endif

else
    mov eax,STDI.offs_l
    mov edx,STDI.offs_h
    mov ecx,STDI.flag
    and STDI.flag,not (IO_SEARCHSET or IO_SEARCHCUR)

    .if ecx & IO_SEARCHSET
        xor eax,eax
        xor edx,edx
    .elseif !(ecx & IO_SEARCHCUR)
        add eax,1       ; offset++ (continue)
        adc edx,0
    .endif

    ioseek(&STDI, edx::eax, SEEK_SET)
    .if eax != -1
        .if STDI.flag & IO_SEARCHHEX
            SearchHex(edx::eax)
        .else
            SearchText(edx::eax)
        .endif
    .endif
endif
    ret

osearch endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_ioinit proc private

    mov _coninpfh, GetStdHandle( STD_INPUT_HANDLE )
    mov _confh,    GetStdHandle( STD_OUTPUT_HANDLE )
    mov _errormode,SetErrorMode( SEM_FAILCRITICALERRORS )
    ret

_ioinit endp

_ioexit proc private uses rsi rdi

    .for ( rdi = &_osfile, esi = 3 : esi < _NFILE_ : esi++ )

        .if ( byte ptr [rdi+rsi] & FH_OPEN )
            _close(esi)
        .endif
    .endf
    ret

_ioexit endp

.pragma init(_ioinit, 1)
.pragma exit(_ioexit, 100)

    end
