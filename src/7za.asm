; 7ZA.ASM--
; Copyright (C) 2015 Doszip Developers -- see LICENSE.TXT
;
; Change history:
; 2026-02-11 - added progress on read file list
; 2025-01-11 - added Confirm Delete for Add function
; 2025-01-07 - 7z.dll plugin --> removed 7za.exe code
;
include errno.inc
include malloc.inc
include io.inc
include string.inc
include stdio.inc
include stdlib.inc
include process.inc
include time.inc
include propidl.inc
include winnls.inc

include doszip.inc
include config.inc
include tview.inc
include confirm.inc
include progress.inc
include dzstr.inc
include 7z.inc

.data?
fp_first        PFBLK ?
fp_last         PFBLK ?
fp_base         dd ?
fp_count        dd ?
arcfile         dw WMAXPATH dup(?)
tmpfile         dw WMAXPATH dup(?)

.data
IID_IInArchive  GUID { 0x23170F69, 0x40C1, 0x278A, { 0x00, 0x00, 0x00, 0x06, 0x00, 0x60, 0x00, 0x00 } }
IID_IOutArchive GUID { 0x23170F69, 0x40C1, 0x278A, { 0x00, 0x00, 0x00, 0x06, 0x00, 0xA0, 0x00, 0x00 } }
CLSID_Format    GUID { 0x23170F69, 0x40C1, 0x278A, { 0x10, 0x00, 0x00, 0x01, 0x10, 0x07, 0x00, 0x00 } }
CreateObject    CREATEZ7OBJ dummy_CreateObject
IsLoaded        DWORD 0

.code

option proc: private

dummy_CreateObject proc WINAPI format:ptr, iid:ptr, archive:ptr
    mov eax,E_NOTIMPL
    ret
    endp


LoadDll proc uses rsi

   .new dll[_MAX_PATH]:sbyte

    mov eax,IsLoaded
    .if ( eax == FALSE )

        dec IsLoaded
        lea rsi,@CStr("7z.dll")
        .if CFGetSection(rsi)
            .if INIGetEntry(rax, "DllFile")
                lea rsi,dll
                ExpandEnvironmentStrings(rax, rsi, _MAX_PATH - 1)
            .endif
        .endif
        .if ( LoadLibrary(rsi) != NULL )

            mov rsi,rax
            .if GetProcAddress(rax, "CreateObject")

                mov CreateObject,rax
                mov eax,TRUE
                mov IsLoaded,eax
            .else
                FreeLibrary(rsi)
                xor eax,eax
            .endif
        .endif
    .elseif ( eax == -1 )
        xor eax,eax
    .endif
    ret
    endp


DisplayError proc hr:HRESULT
    .if (FAILED(hr))
        syserr(hr, "7-zip", 0)
    .endif
    mov eax,hr
    ret
    endp

    assume class:rbx

;-------------------------------------------------------------------------
; IUnknown
;-------------------------------------------------------------------------

CUnknown::QueryInterface proc WINAPI riid:LPIID, ppv:ptr ptr
    ldr rdx,riid
    ldr rcx,ppv
    movzx eax,[rdx].GUID.Data4[3]
    mov ah,[rdx].GUID.Data4[5]
    .if ( eax == 0x0303 || eax == 0x0403 )
        mov [rcx],rbx
        InterlockedIncrement(&m_refCount)
        xor eax,eax
    .elseif ( eax == 0x1005 )
        mov rbx,rcx
        CCryptoGetTextPassword()
        mov [rbx],rax
        xor eax,eax
    .else
        mov eax,E_NOINTERFACE
    .endif
    ret
    endp


CUnknown::AddRef proc WINAPI
    InterlockedIncrement(&m_refCount)
    ret
    endp

CUnknown::Release proc WINAPI
    .ifd ( InterlockedDecrement(&m_refCount) == 0 )
        free(rbx)
        xor eax,eax
    .endif
    ret
    endp

;-------------------------------------------------------------------------
; ICryptoGetTextPassword
;-------------------------------------------------------------------------

CCryptoGetTextPassword::CryptoGetTextPassword proc WINAPI uses rdi pPassword:ptr BSTR

   .new password[128]:char_t
    ldr rdi,pPassword

    .if ( !PasswordIsDefined )

        ; Ask password from user

        mov password,0
        .ifd tgetline("Enter password", &password, 32, 80)
            .if ( password )
                lea ecx,[strlen(&password)+1]
                MultiByteToWideChar(CP_UTF8, 0, &password, ecx, &Password, 128)
                mov PasswordIsDefined,TRUE
            .endif
        .endif
    .endif
    mov eax,E_FAIL
    .if ( PasswordIsDefined )
        SysAllocString(&Password)
        mov [rdi],rax
        xor eax,eax
    .endif
    ret
    endp


CCryptoGetTextPassword::CCryptoGetTextPassword proc
    mov rbx,@ComAlloc(CCryptoGetTextPassword)
    inc m_refCount
    ret
    endp

;-------------------------------------------------------------------------
; IProgress
;-------------------------------------------------------------------------

    assume class:rcx

CProgress::SetTotal proc WINAPI total:QWORD
    progress_set(__srcfile, __outfile, ldr(total))
    ret
    endp


CProgress::SetCompleted proc WINAPI completeValue:ptr QWORD
    ldr rdx,completeValue
    xor eax,eax
    .if ( rdx )
        progress_update([rdx])
    .endif
    ret
    endp


;-------------------------------------------------------------------------
; IArchiveOpenCallback
;-------------------------------------------------------------------------
if 0
IArchiveOpenCallback::SetTotal proc WINAPI files:ptr QWORD, bytes:ptr QWORD
    xor eax,eax
    ret
    endp

IArchiveOpenCallback::SetCompleted proc WINAPI files:ptr QWORD, bytes:ptr QWORD
    xor eax,eax
    ret
    endp
endif

;-------------------------------------------------------------------------
; IArchiveExtractCallback
;-------------------------------------------------------------------------

    assume class:rbx

CArchiveExtractCallback::GetStream proc WINAPI uses rsi rdi index:DWORD, outStream:PTR PSTREAM, askExtractMode:SDWORD

   .new p:LPWSTR
   .new prop:PROPVARIANT
   .new hr:HRESULT

    ldr ecx,askExtractMode
    xor eax,eax
    .return .if ( ecx != NExtract::NAskMode::kExtract )

    ldr esi,index
    ldr rdi,outStream

    mov m_outStream,rax
    mov [rdi],rax
    mov rcx,m_outBase
    mov [rcx],eax

    mov prop.vt,VT_EMPTY
    mov prop.ulVal,FALSE
    m_Archive.GetProperty(esi, kpidIsDir, &prop)
    .if ( prop.ulVal != FALSE )
        .return( 0 )
    .endif

    mov prop.vt,VT_EMPTY
    mov m_curId,esi
    m_Archive.GetProperty(esi, kpidPath, &prop)
    .if ( prop.vt == VT_EMPTY )
        .if ( esi == 0 ) ; .tar.xx ?
            mov rsi,m_curFile
            lea ecx,[strlen([rsi].FBLK.name)+1]
            MultiByteToWideChar(CP_UTF8, 0, [rsi].FBLK.name, ecx, entryname, WMAXPATH/2)
            mov rdx,entryname
        .else
            lea rdx,@CStr(kEmptyFileAlias)
        .endif
    .elseif ( prop.vt == VT_BSTR )
        mov rdx,prop.bstrVal
    .else
        .return ( E_FAIL )
    .endif
    lea rsi,m_arcPathW
    movzx eax,word ptr [rsi]
    .if ( eax )
        .for ( : eax && ax == [rdx] : rdx+=2, rsi+=2, ax = [rsi] )
        .endf
        .if ( eax || word ptr [rdx] != '\' )
            .if ( prop.vt == VT_BSTR )
                SysFreeString(prop.bstrVal)
            .endif
            .return( 0 )
        .endif
        add rdx,2
    .endif
    .for ( p = rdx, eax = 1, esi = 0 : eax : esi += 2 )
        mov rdx,p
        movzx eax,word ptr [rdx+rsi]
        .if ( eax == '\' )
            .ifd ( CreateDirectoryW( &m_outPathW, 0 ) == 0 )
                .ifd ( GetLastError() != ERROR_ALREADY_EXISTS )
                    .return ( HRESULT_FROM_WIN32(eax) )
                .endif
            .endif
            mov eax,'\'
        .endif
        mov rcx,m_outBase
        mov [rcx+rsi],eax
    .endf
    .if ( prop.vt == VT_BSTR )
        SysFreeString(prop.bstrVal)
    .endif
    .if (SUCCEEDED(OpenStream(&m_outPathW, 1, &m_outStream)))
        mov m_setResult,1
    .endif
    mov rcx,m_outStream
    mov [rdi],rcx
    ret
    endp

    assume class:rcx

CArchiveExtractCallback::PrepareOperation proc WINAPI askExtractMode:SDWORD
    xor eax,eax
    ret
    endp

    assume class:rbx

CArchiveExtractCallback::SetOperationResult proc WINAPI uses rsi rdi opRes:SDWORD

   .new prop:PROPVARIANT
    xor eax,eax
    .if ( eax != m_setResult )
        mov m_setResult,eax
        mov prop.vt,VT_EMPTY
        m_Archive.GetProperty(m_curId, kpidMTime, &prop)
        .if ( prop.vt == VT_FILETIME )
            .ifd ( CreateFileW( &m_outPathW, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL) != INVALID_HANDLE_VALUE )
                mov rsi,rax
                SetFileTime( rsi, 0, 0, &prop.filetime )
                CloseHandle( rsi )
            .endif
        .endif
        mov prop.vt,VT_EMPTY
        m_Archive.GetProperty(m_curId, kpidAttrib, &prop)
        .if ( prop.vt != VT_EMPTY )
            SetFileAttributesW( &m_outPathW, prop.ulVal )
        .endif
        xor eax,eax
    .endif
    ret
    endp


CArchiveExtractCallback::CArchiveExtractCallback proc uses rsi rdi archive:LPIARCHIVE,
        outPath:LPSTR, arcPath:LPSTR, curFile:PFBLK

    ldr rsi,archive
    ldr rdi,outPath
    mov rbx,@ComAlloc(CArchiveExtractCallback)
    .if ( rax == NULL )
        .return
    .endif

    mov m_Archive,rsi
    mov m_outPath,rdi
    mov m_curFile,curFile

    mov m_arcPath,arcPath
    lea rsi,m_outPathW
    .ifd ( MultiByteToWideChar(CP_UTF8, 0, rdi, -1, &m_outPathW, WMAXPATH) > 1 )
        lea rsi,m_outPathW[rax*2]
        mov eax,'\'
        .if ( ax == [rsi-4] )
            sub rsi,2 ; remove '\' from end of srcpath (C:\)
        .endif
        mov [rsi-2],eax
    .endif
    mov m_outBase,rsi
    lea rdi,m_arcPathW
    .ifd ( MultiByteToWideChar(CP_UTF8, 0, m_arcPath, -1, &m_arcPathW, WMAXPATH) > 1 )
        lea rdi,m_arcPathW[rax*2]
    .endif
    mov m_arcBase,rdi
    mov rcx,m_curFile
    .if ( [rcx].FBLK.flag & _A_SUBDIR )
        MultiByteToWideChar(CP_UTF8, 0, [rcx].FBLK.name, -1, rsi, _MAX_PATH)
        mov ecx,eax
        lea rax,m_arcPathW
        .if ( rdi != rax )
            mov eax,'\'
            mov [rdi-2],eax
        .endif
        rep movsw
        CreateDirectoryW( &m_outPathW, 0 )
        mov eax,'\'
        .if ( ax == [rdi-4] )
            sub rdi,2
            sub rsi,2
        .endif
        mov [rsi-2],eax
        mov m_arcBase,rdi
        mov m_outBase,rsi
    .endif
    mov rax,rbx
    ret
    endp

;-------------------------------------------------------------------------
; IArchiveUpdateCallback
;-------------------------------------------------------------------------

    assume class:rcx

IArchiveUpdateCallback::SetOperationResult proc WINAPI operationResult:SDWORD
    xor eax,eax
    ret
    endp

;-------------------------------------------------------------------------
; IArchiveUpdateCallback2
;-------------------------------------------------------------------------

IArchiveUpdateCallback2::GetVolumeSize proc WINAPI index:DWORD, size:ptr QWORD
    mov eax,E_NOTIMPL
    ret
    endp

IArchiveUpdateCallback2::GetVolumeStream proc WINAPI index:DWORD, volumeStream:ptr PSTREAM
    mov eax,E_NOTIMPL
    ret
    endp

;-------------------------------------------------------------------------
; CArchiveUpdateCallback
;-------------------------------------------------------------------------

    assume class:rbx

CArchiveUpdateCallback::GetUpdateItemInfo proc WINAPI index:DWORD, newData:ptr SDWORD,
        newProps:ptr SDWORD, indexInArchive:ptr DWORD

    ldr edx,index
    mov rcx,m_idList
    mov eax,[rcx+rdx*4]
    mov rcx,indexInArchive
    mov [rcx],eax
    cmp eax,-1
    mov eax,0
    setz al
    ldr rdx,newData
    ldr rcx,newProps
    mov [rcx],eax
    mov [rdx],eax
    xor eax,eax
    ret
    endp


CArchiveUpdateCallback::GetProperty proc WINAPI uses rsi rdi index:DWORD, propID:PROPID, value:ptr PROPVARIANT

    ldr edx,index
    .for ( rdi = fp_first, rcx = rdi : rdi : rcx = rdi, rdi = [rdi].FBLK.next )
        .break .if ( edx == [rdi+FBLK].ZINF.z7id )
    .endf

    .if ( rdi && edx == [rdi+FBLK].ZINF.z7id )

        ldr eax,propID
        ldr rsi,value
        .switch eax
        .case kpidAttrib
            mov [rsi].PROPVARIANT.vt,VT_UI4
            mov ecx,[rdi].FBLK.flag
            and ecx,_A_FATTRIB
            mov [rsi].PROPVARIANT.ulVal,ecx
           .endc
        .case kpidPath
            mov [rsi].PROPVARIANT.vt,VT_BSTR
            mov rdx,m_srcBase
            lea rax,m_srcPathW
            sub rdx,rax
            shr edx,1
            mov ecx,WMAXPATH
            sub ecx,edx
            MultiByteToWideChar(CP_UTF8, 0, [rdi].FBLK.name, -1, m_arcBase, ecx)
            mov [rsi].PROPVARIANT.bstrVal,SysAllocString(&m_arcPathW)
            inc fp_count
            progress_update(fp_count)
           .endc
        .case kpidIsDir
            mov [rsi].PROPVARIANT.vt,VT_BOOL
            mov [rsi].PROPVARIANT.ulVal,FALSE
           .endc
        .case kpidMTime
            mov [rsi].PROPVARIANT.vt,VT_FILETIME
            mov [rsi].PROPVARIANT.filetime,[rdi+FBLK].ZINF.ftime
           .endc
        .case kpidIsAnti
            mov [rsi].PROPVARIANT.vt,VT_BOOL
            mov [rsi].PROPVARIANT.ulVal,FALSE
           .endc
        .case kpidSize
            mov [rsi].PROPVARIANT.vt,VT_UI8
            mov [rsi].PROPVARIANT.uhVal,[rdi].FBLK.size

            ; Last call for this index: Rotate list

            mov rax,[rdi].FBLK.next
            mov [rdi].FBLK.next,NULL
            .if ( rcx == rdi )
                .if ( rax )
                    mov fp_first,rax
                .endif
            .else
                mov [rcx].FBLK.next,rax
            .endif
            mov rdx,fp_last
            mov fp_last,rdi
            .if ( rdx && rdx != rdi )
                mov [rdx].FBLK.next,rdi
            .endif
            .endc
        .endsw
    .endif
    xor eax,eax
    ret
    endp


CArchiveUpdateCallback::GetStream proc WINAPI uses rsi rdi index:DWORD, inStream:ptr PSTREAM

    ldr edx,index
    ldr rsi,inStream

    .for ( rdi = fp_first, rcx = rdi : rdi : rcx = rdi, rdi = [rdi].FBLK.next )
        .break .if ( edx == [rdi+FBLK].ZINF.z7id )
    .endf

    mov eax,E_FAIL
    .if ( rdi && edx == [rdi+FBLK].ZINF.z7id )

        mov rax,[rdi].FBLK.next
        mov [rdi].FBLK.next,NULL
        .if ( rcx == rdi )
            .if ( rax )
                mov fp_first,rax
            .endif
        .else
            mov [rcx].FBLK.next,rax
        .endif
        mov rdx,fp_last
        mov fp_last,rdi
        .if ( rdx && rdx != rdi )
            mov [rdx].FBLK.next,rdi
        .endif
        strfcat(__srcfile, m_srcPath, [rdi].FBLK.name)
        mov rdx,m_srcBase
        lea rax,m_srcPathW
        sub rdx,rax
        shr edx,1
        mov ecx,WMAXPATH
        sub ecx,edx
        MultiByteToWideChar(CP_UTF8, 0, [rdi].FBLK.name, -1, m_srcBase, ecx)
        mov eax,E_FAIL
        .if ( rsi )
            OpenStream(&m_srcPathW, 0, rsi)
        .endif
    .endif
    ret
    endp


CArchiveUpdateCallback::SetPath proc WINAPI uses rsi arcPath:LPSTR, srcPath:LPSTR

    ldr rdx,arcPath
    ldr rsi,srcPath

    mov m_arcPath,rdx
    mov m_srcPath,rsi

    .if ( rdx )

        .ifd ( MultiByteToWideChar(CP_UTF8, 0, rdx, -1, &m_arcPathW, WMAXPATH) > 1 )

            lea rcx,m_arcPathW[rax*2]
            mov eax,'\'
            .if ( ax == [rcx-4] )
                sub rcx,2
            .endif
            mov [rcx-2],eax
            mov m_arcBase,rcx
        .endif
    .endif

    .if ( rsi )

        .ifd ( MultiByteToWideChar(CP_UTF8, 0, rsi, -1, &m_srcPathW, WMAXPATH) > 1 )

            lea rcx,m_srcPathW[rax*2]
            mov eax,'\'
            .if ( ax == [rcx-4] )
                sub rcx,2
            .endif
            mov [rcx-2],eax
            mov m_srcBase,rcx
        .endif
    .endif
    xor eax,eax
    ret
    endp


CArchiveUpdateCallback::InitList proc WINAPI idList:LPDWORD
    mov m_idList,ldr(idList)
    xor eax,eax
    ret
    endp


CArchiveUpdateCallback::CArchiveUpdateCallback proc
    mov rbx,@ComAlloc(CArchiveUpdateCallback)
    .if ( rax )
        inc m_refCount
        lea rdx,m_arcPathW
        lea rcx,m_srcPathW
        mov m_arcBase,rdx
        mov m_srcBase,rcx
    .endif
    ret
    endp

;-------------------------------------------------------------------------
; ISequentialInStream, ISequentialOutStream
;-------------------------------------------------------------------------

CStream::Release proc WINAPI
    .new hr:HRESULT = S_OK
    .if ( InterlockedDecrement(&m_refCount) == 0 )
        .if ( m_Handle != INVALID_HANDLE_VALUE )
            .ifd ( CloseHandle( m_Handle ) == 0 )
                mov hr,HRESULT_FROM_WIN32(GetLastError())
            .endif
            mov m_Handle,INVALID_HANDLE_VALUE
        .endif
        free( rbx )
    .endif
    mov eax,hr
    ret
    endp


CStream::Read proc WINAPI buffer:ptr, size:dword, rdsize:ptr dword
    ldr rdx,buffer
    ldr rax,rdsize
    .if ( m_IsOutStream )
        WriteFile(m_Handle, rdx, size, rax, NULL)
    .else
        ReadFile(m_Handle, rdx, size, rax, NULL)
    .endif
    test eax,eax
    mov eax,S_OK
    .ifz
        HRESULT_FROM_WIN32(GetLastError())
    .endif
    ret
    endp


CStream::Seek proc WINAPI liDistanceToMove:sqword, dwMoveMethod:dword, lpNewFilePointer:ptr qword
    ldr rcx,lpNewFilePointer
    SetFilePointerEx(m_Handle, liDistanceToMove, rcx, ldr(dwMoveMethod))
    test eax,eax
    mov eax,S_OK
    .ifz
        HRESULT_FROM_WIN32(GetLastError())
    .endif
    ret
    endp

    assume class:rcx

CStream::SetSize proc WINAPI newSize:qword
    mov eax,E_NOTIMPL
    ret
    endp

    assume class:nothing

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; <Archive>.$$$

GetTempArchive proc
    .for ( rcx = &tmpfile, rdx = &arcfile, eax = 1 : eax : rcx+=2, rdx+=2 )
        mov ax,[rdx]
        mov [rcx],rax
    .endf
    mov dword ptr [rcx-2],0x0024002E
    mov dword ptr [rcx+2],0x00240024
    mov word ptr [rcx+6],0x0000
    lea rax,tmpfile
    ret
    endp


OpenStream proc uses rsi rdi rbx name:LPWSTR, OutStream:BOOL, Stream:ptr PSTREAM

   .new hr:HRESULT = S_OK

    ldr rsi,name
    ldr ebx,OutStream
    ldr rdi,Stream

    .if ( @ComAlloc(CStream) == NULL )
        .return( E_OUTOFMEMORY )
    .endif
    mov [rax].CStream.m_IsOutStream,ebx
    inc [rax].CStream.m_refCount
    mov rbx,rax
    xor eax,eax
    mov [rdi],rax
    mov edx,GENERIC_READ
    mov eax,OPEN_EXISTING
    .if ( [rbx].CStream.m_IsOutStream )
        mov edx,GENERIC_WRITE
        mov eax,CREATE_ALWAYS
    .endif
    .ifd ( CreateFileW(rsi, edx, FILE_SHARE_READ, NULL, eax, FILE_ATTRIBUTE_NORMAL, NULL) == INVALID_HANDLE_VALUE )
        free(rbx)
        HRESULT_FROM_WIN32(GetLastError())
    .else
        mov [rbx].CStream.m_Handle,rax
        mov [rdi],rbx
        xor eax,eax
    .endif
    ret
    endp


OpenArchive proc uses rdi pArc:ptr LPIARCHIVE

   .new pos:QWORD = 0
   .new archive:LPIARCHIVE = 0
   .new stream:PSTREAM = 0
   .new hr:HRESULT

    ldr rdi,pArc

    mov hr,CreateObject(&CLSID_Format, &IID_IInArchive, &archive)
    .if SUCCEEDED(hr)
        mov hr,OpenStream(&arcfile, 0, &stream)
    .endif
    .if SUCCEEDED(hr)

        mov hr,archive.Open(stream, &pos, 0)

        ; the ref count should be 2 from ::Open, 1 if failed

        stream.Release()
        .if SUCCEEDED(hr)
            mov [rdi],archive
        .else
            archive.Release()
        .endif
    .else
        SafeRelease(archive)
    .endif
    mov eax,hr
    ret
    endp


fp_addfile proc uses rsi rdi rbx path:LPSTR, wblk:ptr WIN32_FIND_DATA

   .new q:QWORD

    ldr rsi,path
    ldr rbx,wblk

    .ifd filter_wblk(rbx)

        strfcat(__srcfile, rsi, &[rbx].WIN32_FIND_DATA.cFileName)

        mov edx,[rbx].WIN32_FIND_DATA.nFileSizeHigh
        mov eax,[rbx].WIN32_FIND_DATA.nFileSizeLow
        mov dword ptr q[0],eax
        mov dword ptr q[4],edx

        mov edx,fp_base
        mov rcx,__srcfile
        add rcx,rdx
        mov edx,[rbx].WIN32_FIND_DATA.dwFileAttributes
        and edx,_A_FATTRIB
        or  edx,_FB_ARCHEXT
        mov rdi,fballoc(rcx, 0, q, edx)
        .if ( rax == NULL )
            dec rax
           .return
        .endif
        mov [rdi+FBLK].ZINF.ftime,[rbx].WIN32_FIND_DATA.ftLastWriteTime
        mov rcx,fp_first
        xor eax,eax
        .if ( rcx == NULL )
            mov fp_first,rdi
            mov fp_last,rdi
            mov fp_count,1
        .else
            inc fp_count
            mov rcx,fp_last
            mov [rcx].FBLK.next,rdi
            mov fp_last,rdi
            .if !( fp_count & 3 )
                sprintf(__srcfile, "%d selected file(s)", fp_count)
                progress_set(__srcfile, __outfile, 0)
            .endif
        .endif
    .endif
    ret
    endp


fp_addsub proc uses rsi rdi path:LPSTR, file:LPSTR

    ldr rbx,path
    ldr rsi,file

    .ifd !progress_set(0, strfcat(__outpath, rbx, rsi), 1)

        mov fp_fileblock,&fp_addfile
        mov fp_directory,&scan_files
        scansub(__outpath, &cp_stdmask, 1)
    .endif
    ret
    endp


FindDuplicate proc uses rsi rdi rbx archive:LPIARCHIVE, numItems:SDWORD, fb:PFBLK, callback:ptr CArchiveUpdateCallback

   .new prop:PROPVARIANT

    ldr rbx,fb
    ldr rsi,callback

    mov rdi,[rsi].CArchiveUpdateCallback.m_arcBase
    lea rsi,[rsi].CArchiveUpdateCallback.m_arcPathW
    mov rax,rdi
    sub rax,rsi
    shr eax,1
    mov ecx,WMAXPATH
    sub ecx,eax

    .ifd ( MultiByteToWideChar(CP_UTF8, 0, [rbx].FBLK.name, -1, rdi, ecx) > 1 )

        sub rdi,rsi
        lea edi,[rdi+rax*2]

        .for ( ebx = 0 : ebx < numItems : ebx++ )

            mov prop.vt,VT_EMPTY
            archive.GetProperty(ebx, kpidPath, &prop)
            .if ( prop.vt == VT_BSTR )

                ; _wcsicmp(prop.bstrVal, rsi)

                .ifd ( memcmp(prop.bstrVal, rsi, edi) == 0 )

                    lea eax,[rbx+1]
                   .return
                .endif
                SysFreeString(prop.bstrVal)
            .endif
        .endf
    .endif
    xor eax,eax
    ret
    endp


; Returns 0 if entry not part of basepath,
; else _A_ARCH or _A_SUBDIR.

testentryname proc uses rsi rdi rbx wsub:PWSUB, name:LPSTR

    ldr rbx,wsub
    ldr rsi,name

    mov edi,strlen( [rbx].WSUB.arch )
    .ifd ( strlen(rsi) <= edi )
        .return( 0 )
    .endif
    .ifs ( edi > 0 )
        .if _strnicmp( rsi, [rbx].WSUB.arch, edi )
            .return( 0 )
        .endif
        .if ( byte ptr [rsi+rdi] != '\' )
            .return( 0 )
        .endif
        strcpy( rsi, &[rsi+rdi+1] )
        .while ( byte ptr [rsi] == ',' )
            strcpy( rsi, &[rsi+1] )
        .endw
    .endif
    mov edi,_A_ARCH
    .if ( strchr(rsi, '\') != NULL )
        mov byte ptr [rax],0
        mov edi,_A_SUBDIR
    .endif
    .ifd ( wsearch(rbx, rsi) != -1 )
        xor edi,edi
    .endif
    mov eax,edi
    ret
    endp

    option proc:public

;-------------------------------------------------------------------------
; Read
;-------------------------------------------------------------------------

warcread proc uses rsi rdi rbx ws:PWSUB

   .new archive:LPIARCHIVE = 0
   .new pos:QWORD = 0
   .new prop:PROPVARIANT
   .new numItems:SDWORD = 0
   .new ftime:DWORD
   .new curtime:DWORD
   .new fattrib:DWORD
   .new name:LPSTR = entryname

    ldr rsi,ws

    strfcat(entryname, [rsi].WSUB.path, [rsi].WSUB.file)
    lea edi,[strlen(entryname)+1]
    MultiByteToWideChar(CP_UTF8, 0, entryname, edi, &arcfile, WMAXPATH)

    .if SUCCEEDED(OpenArchive(&archive))

        wsfree( rsi )

        .if fbupdir( _W_ARCHEXT )

            mov [rsi].WSUB.fcb,rax
            mov rbx,rax
            mov curtime,[rbx].FBLK.time

            archive.GetNumberOfItems(&numItems)
            .if ( numItems < 0 )
                mov numItems,0
            .endif

            .for ( edi = 0 : edi < numItems : edi++ )

                mov prop.vt,VT_EMPTY
                mov prop.wReserved1,0
                mov prop.bstrVal,NULL

                archive.GetProperty(edi, kpidPath, &prop)

                .if ( prop.vt == VT_BSTR )

                    WideCharToMultiByte(CP_UTF8, 0, prop.bstrVal, -1, name, WMAXPATH, NULL, NULL)
                    SysFreeString(prop.bstrVal)

                .elseif ( numItems == 1 )

                    .continue .if !strext( strcpy(name, [rsi].WSUB.file ) )
                    mov byte ptr [rax],0
                .else
                    .continue
                .endif
                .continue .ifd !testentryname( rsi, name )

                and eax,_A_SUBDIR
                mov fattrib,eax
                .ifz
                    strwild( [rsi].WSUB.mask, name )
                .endif
                .continue .if ( eax == 0 )

                archive.GetProperty(edi, kpidAttrib, &prop)
                movzx eax,prop.bVal
                or fattrib,eax
                .if !( fattrib & _A_SUBDIR )
                    archive.GetProperty(edi, kpidIsDir, &prop)
                    .if ( prop.ulVal )
                        or fattrib,_A_SUBDIR
                    .endif
                .endif
                or fattrib,_FB_ARCHEXT
                archive.GetProperty(edi, kpidMTime, &prop)
                mov eax,curtime
                .if ( prop.vt == VT_FILETIME )
                    FileTimeToTime(&prop.filetime)
                .endif
                mov ftime,eax
                archive.GetProperty(edi, kpidSize, &prop)

                .break .if !fballoc(name, ftime, prop.uhVal, fattrib)
                mov [rbx].FBLK.next,rax
                mov rbx,rax
                mov [rax+FBLK].ZINF.z7id,edi
            .endf
        .endif
        archive.Release()
        wsetfcb(rsi)
    .else
        DisplayError(eax)
        mov eax,ER_READARCH
    .endif
    ret
    endp

;-------------------------------------------------------------------------
; Copy
;-------------------------------------------------------------------------

warccopy proc uses rsi rdi rbx wsub:PWSUB, fblk:PFBLK, outPath:LPSTR

   .new archive:LPIARCHIVE = 0
   .new indices[2]:DWORD = {0}
   .new hr:HRESULT

    ldr rsi,wsub
    ldr rbx,fblk

    mov hr,OpenArchive(&archive)

    .if SUCCEEDED(hr)

        .repeat
            .if CArchiveExtractCallback(archive, outPath, [rsi].WSUB.arch, rbx)

                mov rdi,rax

                strfcat(__srcfile, [rsi].WSUB.file, [rsi].WSUB.arch)
                strfcat(__srcfile, NULL, [rbx].FBLK.name)
                strfcat(__outfile, outPath, [rbx].FBLK.name)
                and [rbx].FBLK.flag,not _FB_SELECTED
                .if ( [rbx].FBLK.flag & _A_SUBDIR )
                    archive.Extract(NULL, -1, 0, rdi)
                .else
                    mov ecx,[rbx+FBLK].ZINF.z7id
                    mov indices,ecx
                    archive.Extract(&indices, 1, 0, rdi)
                .endif
                mov hr,eax
                .break .if FAILED(eax)
                panel_findnext(cpanel)
                mov rbx,rdx
            .endif
        .until !rax
        archive.Release()
    .endif
    DisplayError(hr)
    ret
    endp


;-------------------------------------------------------------------------
; Add
;-------------------------------------------------------------------------

warcadd proc uses rsi rdi rbx dest:PWSUB, wsub:PWSUB, fblk:PFBLK

    xor eax,eax
   .new archive:LPIARCHIVE = rax
   .new outarch:LPOARCHIVE = rax
   .new stream:PSTREAM = rax
   .new callback:ptr CArchiveUpdateCallback = rax
   .new indices:LPDWORD = rax
   .new prop:PROPVARIANT
   .new count:DWORD
   .new blkcount:DWORD
   .new newcount:DWORD
   .new numItems:SDWORD = eax
   .new tempfile:DWORD = eax
   .new hr:HRESULT = eax
   .new wb:WIN32_FIND_DATAW

    ldr rsi,dest
    ldr rdi,wsub
    ldr rbx,fblk

    mov fp_first,rax
    mov fp_last,rax

    ; Find selected item count

    strlen([rdi].WSUB.path)
    mov rcx,[rdi].WSUB.path
    .if ( byte ptr [rcx+rax-1] != '\' )
        inc eax
    .endif
    mov fp_base,eax

    .repeat

        and [rbx].FBLK.flag,not _FB_SELECTED
        .if ( [rbx].FBLK.flag & _A_SUBDIR )

            ; Add subdir

            fp_addsub([rdi].WSUB.path, [rbx].FBLK.name)

        .else

            ; Add file

            strfcat(__srcfile, [rdi].WSUB.path, [rbx].FBLK.name)
            .ifd ( wsfindfirst(__srcfile, &wb, ATTRIB_FILE) != -1 )

                wscloseff(rax)
                fp_addfile([rdi].WSUB.path, &wb)
            .endif
        .endif
        .if ( eax )
            mov hr,E_FAIL
           .break
        .endif
        panel_findnext(cpanel)
        mov rbx,rdx
    .until !rax
    strfcat(__outfile, [rsi].WSUB.file, [rsi].WSUB.arch)
    .if SUCCEEDED(hr)
        mov blkcount,fp_count
        .if ( eax == 0 )
            mov hr,E_ABORT
        .endif
    .endif

    ; Open archive

    .if SUCCEEDED(hr)
        mov hr,OpenArchive(&archive)
    .endif

    .if SUCCEEDED(hr)

        archive.GetNumberOfItems(&numItems)
        ;
        ; v3.93: allow empty archives (created by Shift-F7)
        ; v3.94: a "fake" file name not only added to GZip
        ;
        mov eax,numItems
        .ifs ( eax < 0 || eax == 1 ) ; || ( eax == 1 && CLSID_Format.Data4[5] == kId_GZip ) )
            .if ( eax != 1 )
                mov hr,E_BOUNDS
                xor eax,eax
            .endif
            inc eax
            .if ( eax == [rsi].WSUB.count )
                .ifd ( FindFirstFileW(&arcfile, &wb) != -1 )
                    FindClose(rax)
                    mov eax,wb.nFileSizeLow
                    or  eax,wb.nFileSizeHigh
                    .ifz
                        mov hr,eax
                        mov numItems,eax
                    .endif
                .endif
            .endif
        .endif
    .endif

    .if SUCCEEDED(hr)

        mov ecx,numItems
        add ecx,blkcount
        mov count,ecx
        mov newcount,ecx
        shl ecx,2
        .if ( malloc(ecx) == NULL )
            mov hr,E_OUTOFMEMORY
        .endif
        mov indices,rax
    .endif
    .if SUCCEEDED(hr)
        mov callback,CArchiveUpdateCallback()
        .if ( rax == NULL )
            mov hr,E_OUTOFMEMORY
        .endif
    .endif
    .if SUCCEEDED(hr)
        callback.SetPath( [rsi].WSUB.arch, [rdi].WSUB.path )
    .endif

    .if SUCCEEDED(hr)

        mov rdi,indices
        mov ecx,numItems
        xor eax,eax
        rep stosd

        .for ( rdi = fp_first, rsi = rdi : rdi : rsi = rdi, rdi = [rdi].FBLK.next )

            .ifd FindDuplicate(archive, numItems, rdi, callback)

                lea ebx,[rax-1]
                .ifd ( confirm_delete_file([rdi].FBLK.name, [rdi].FBLK.flag) == -1 )

                    mov hr,E_ABORT ; Cancel
                   .break

                .elseif ( eax == 0 ) ; Jump

                    mov rcx,rdi
                    mov rdi,[rdi].FBLK.next
                    .if ( rsi == fp_first )
                        mov fp_first,rdi
                    .else
                        mov [rsi].FBLK.next,rdi
                    .endif
                    free(rcx)
                    dec blkcount
                    .ifz
                        mov hr,E_ABORT
                       .break
                    .endif
                    dec count
                    dec newcount
                .else
                    dec newcount
                    mov ecx,newcount
                    mov rdx,indices
                    mov [rdx+rcx*4],ebx
                    dec byte ptr [rdx+rbx*4]
                .endif
            .endif
        .endf
    .endif

    .if SUCCEEDED(hr)

        sprintf(__srcfile, "%d selected file(s)", blkcount)

        .for ( rdi = indices, eax = 0, ecx = 0 : ecx < numItems : ecx++ )
            .if ( byte ptr [rdi+rcx*4] == 0 )
                mov [rdi+rax*4],ecx
                inc eax
            .endif
        .endf
        .for ( ecx = -1, rdx = fp_first : rdx : rdx = [rdx].FBLK.next, eax++ )
            mov [rdi+rax*4],ecx
            mov [rdx+FBLK].ZINF.z7id,eax
        .endf
        mov hr,archive.QueryInterface(&IID_IOutArchive, &outarch)
    .endif
    .if SUCCEEDED(hr)
        mov rcx,GetTempArchive()
        mov hr,OpenStream(rcx, 1, &stream)
    .endif
    .if SUCCEEDED(hr)

        inc tempfile
        mov fp_count,0
        progress_set("Update Items...", __outfile, blkcount)
        callback.InitList( indices )
        mov hr,outarch.UpdateItems(stream, newcount, callback)
    .endif
    .for ( rdi = fp_first : rdi : )
        mov rcx,rdi
        mov rdi,[rdi].FBLK.next
        free(rcx)
    .endf
    free(indices)
    SafeRelease(outarch)
    SafeRelease(callback)
    SafeRelease(stream)
    SafeRelease(archive)
    .if ( tempfile )
        .if (SUCCEEDED(hr))
            _wremove(&arcfile)
            _wrename(&tmpfile, &arcfile)
        .else
            _wremove(&tmpfile)
        .endif
    .endif
    DisplayError(hr)
    ret
    endp


;-------------------------------------------------------------------------
; Delete
;-------------------------------------------------------------------------

warcdelete proc uses rsi rdi rbx wsub:PWSUB, fblk:PFBLK

    xor eax,eax
   .new archive:LPIARCHIVE = rax
   .new outarch:LPOARCHIVE = rax
   .new stream:PSTREAM = rax
   .new callback:ptr CArchiveUpdateCallback = rax
   .new indices:LPDWORD = rax
   .new flags:LPSTR
   .new prop:PROPVARIANT
   .new sublen:SDWORD
   .new count:DWORD
   .new numItems:SDWORD = eax
   .new tempfile:DWORD = eax
   .new hr:HRESULT

    ldr rsi,wsub
    ldr rbx,fblk

    mov hr,OpenArchive(&archive)
    .if SUCCEEDED(hr)

        archive.GetNumberOfItems(&numItems)
        .if ( numItems <= 0 )
            mov hr,E_BOUNDS
        .endif
    .endif

    .if SUCCEEDED(hr)

        mov ecx,numItems
        lea ecx,[rcx+rcx*4]
        .if ( malloc(ecx) == NULL )
            mov hr,E_OUTOFMEMORY
        .endif
        mov indices,rax
        imul ecx,numItems,4
        add rax,rcx
        mov flags,rax
    .endif

    .if SUCCEEDED(hr)

        ; Find selected item count

        mov rdi,flags
        mov ecx,numItems
        xor eax,eax
        rep stosb

        .repeat

            and [rbx].FBLK.flag,not _FB_SELECTED

            .if ( [rbx].FBLK.flag & _A_SUBDIR )

                ; Delete subdir

                .ifd ( confirm_delete_sub([rbx].FBLK.name) == 0 )

                    mov hr,E_ABORT
                   .break
                .endif

                .if ( eax == 1 )

                    mov rcx,strfcat(__srcfile, [rsi].WSUB.arch, [rbx].FBLK.name)
                    .ifd ( MultiByteToWideChar(CP_UTF8, 0, rcx, -1, entryname, WMAXPATH/2) > 1 )

                        lea eax,[rax+rax-2]
                        mov sublen,eax

                        .for ( edi = 0 : edi < numItems : edi++ )

                            mov prop.vt,VT_EMPTY
                            archive.GetProperty(edi, kpidPath, &prop)
                            .if ( prop.vt == VT_BSTR )

                                .ifd ( memcmp(prop.bstrVal, entryname, sublen) == 0 )

                                    mov rcx,prop.bstrVal
                                    mov edx,sublen
                                    movzx eax,word ptr [rcx+rdx]
                                    .if ( eax == '\' || eax == '/' || eax == 0 )

                                        mov rdx,flags
                                        inc byte ptr [rdx+rdi]
                                    .endif
                                .endif
                                SysFreeString(prop.bstrVal)
                            .endif
                        .endf
                    .endif
                .endif

            .else ; Delete file

                .ifd ( confirm_delete_file([rbx].FBLK.name, [rbx].FBLK.flag) == 0 )

                    mov hr,E_ABORT
                   .break

                .elseif ( eax == 1 )

                    mov rdi,flags
                    mov ecx,[rbx+FBLK].ZINF.z7id
                    inc byte ptr [rdi+rcx]
                .endif
            .endif
            panel_findnext(cpanel)
            mov rbx,rdx
        .until !rax
    .endif

    .if SUCCEEDED(hr)

        .for ( rdi = indices, eax = 0, edx = 0, ecx = 0 : ecx < numItems : ecx++ )

            mov rbx,flags
            .if ( byte ptr [rbx+rcx] == 0 )
                mov [rdi+rdx*4],ecx
                inc edx
            .else
                inc eax
                mov ebx,numItems
                sub ebx,eax
                mov [rdi+rbx*4],ecx
            .endif
        .endf
        .if ( eax )
            mov ecx,numItems
            sub ecx,eax
            mov count,ecx
        .else
            mov hr,E_BOUNDS
        .endif
    .endif

    .if SUCCEEDED(hr)
        mov hr,archive.QueryInterface(&IID_IOutArchive, &outarch)
    .endif
    .if SUCCEEDED(hr)
        mov rcx,GetTempArchive()
        mov hr,OpenStream(rcx, 1, &stream)
    .endif
    .if SUCCEEDED(hr)
        mov callback,CArchiveUpdateCallback()
        .if ( rax == NULL )
            mov hr,E_OUTOFMEMORY
        .endif
    .endif
    .if SUCCEEDED(hr)

        inc tempfile
        mov ecx,numItems
        sub ecx,count
        sprintf(__outfile, "%d selected file(s)", ecx)
        strfcat(__srcfile, [rsi].WSUB.file, [rsi].WSUB.arch)
        callback.InitList( indices )
        mov hr,outarch.UpdateItems(stream, count, callback)
    .endif
    free(indices)
    SafeRelease(outarch)
    SafeRelease(callback)
    SafeRelease(stream)
    SafeRelease(archive)
    .if ( tempfile )
        .if (SUCCEEDED(hr))
            _wremove(&arcfile)
            _wrename(&tmpfile, &arcfile)
        .else
            _wremove(&tmpfile)
        .endif
    .endif
    DisplayError(hr)
    ret
    endp

;-------------------------------------------------------------------------
; View
;-------------------------------------------------------------------------

warcview proc uses rsi rdi rbx wsub:PWSUB, fblk:PFBLK

   .new archive:LPIARCHIVE = 0
   .new indices[2]:DWORD = { 0, 0 }
   .new fbname[_MAX_PATH]:char_t

    mov rsi,wsub
    mov rbx,fblk
    mov rdi,envtemp

    .if SUCCEEDED(OpenArchive(&archive))

        progress_open("Copy", "Copy")
        strcpy(__srcfile, [rbx].FBLK.name)
        strcpy(__outfile, rdi)
        .if CArchiveExtractCallback(archive, rdi, [rsi].WSUB.arch, rbx)

            mov ecx,[rbx+FBLK].ZINF.z7id
            mov indices,ecx
            archive.Extract(&indices, 1, 0, rax)
        .endif
        archive.Release()
        progress_close()
        mov rdi,strfcat( &fbname, rdi, [rbx].FBLK.name )
        .ifd ( filexist( rdi ) == 1 )

            tview( rdi, 0 )
            remove( rdi )
            mov _diskflag,0
        .endif
    .endif
    ret
    endp


;-------------------------------------------------------------------------
; Test
;-------------------------------------------------------------------------

warctest proc uses rsi rdi rbx fblk:LPSTR, sign:int_t

    ldr rbx,fblk
    ldr edi,sign

    .ifd ( LoadDll() == TRUE )

        .if ( edi == TYPE_7Z ) ; only support .7z ID..

            mov eax,kId_7z

        .elseif CFGetSection("7z.dll")

            mov rsi,rax
            .if strext(rbx)

                inc rax
                .if INIGetEntry(rsi, rax)

                    .ifd ( strtolx(rax) > kId_GZip )
                        xor eax,eax
                    .endif
                .endif
            .endif
        .endif
        .if ( eax )
            mov CLSID_Format.Data4[5],al
            mov eax,1
        .endif
    .endif
    ret
    endp

    end
