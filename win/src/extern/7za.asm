; 7ZA.ASM--
; Copyright (C) 2015 Doszip Developers -- see LICENSE.TXT
;
; Change history:
; 2025-01-07 - nidud
; - 7z.dll plugin --> removed 7za.exe code
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

.enum {

  kId_Zip       = 0x01,
  kId_BZip2     = 0x02,
  kId_Rar       = 0x03,
  kId_Arj       = 0x04,
  kId_Z         = 0x05,
  kId_Lzh       = 0x06,
  kId_7z        = 0x07,
  kId_Cab       = 0x08,
  kId_Nsis      = 0x09,
  kId_Lzma      = 0x0A,
  kId_Lzma86    = 0x0B,
  kId_Xz        = 0x0C,
  kId_Ppmd      = 0x0D,
  kId_Zstd      = 0x0E,
  kId_LVM       = 0xBF,
  kId_AVB       = 0xC0,
  kId_LP        = 0xC1,
  kId_Sparse    = 0xC2,
  kId_APFS      = 0xC3,
  kId_Vhdx      = 0xC4,
  kId_Base64    = 0xC5,
  kId_COFF      = 0xC6,
  kId_Ext       = 0xC7,
  kId_VMDK      = 0xC8,
  kId_VDI       = 0xC9,
  kId_Qcow      = 0xCA,
  kId_GPT       = 0xCB,
  kId_Rar5      = 0xCC,
  kId_IHex      = 0xCD,
  kId_Hxs       = 0xCE,
  kId_TE        = 0xCF,
  kId_UEFIc     = 0xD0,
  kId_UEFIs     = 0xD1,
  kId_SquashFS  = 0xD2,
  kId_CramFS    = 0xD3,
  kId_APM       = 0xD4,
  kId_Mslz      = 0xD5,
  kId_Flv       = 0xD6,
  kId_Swf       = 0xD7,
  kId_Swfc      = 0xD8,
  kId_Ntfs      = 0xD9,
  kId_Fat       = 0xDA,
  kId_Mbr       = 0xDB,
  kId_Vhd       = 0xDC,
  kId_Pe        = 0xDD,
  kId_Elf       = 0xDE,
  kId_Mach_O    = 0xDF,
  kId_Udf       = 0xE0,
  kId_Xar       = 0xE1,
  kId_Mub       = 0xE2,
  kId_Hfs       = 0xE3,
  kId_Dmg       = 0xE4,
  kId_Compound  = 0xE5,
  kId_Wim       = 0xE6,
  kId_Iso       = 0xE7,
  kId_Chm       = 0xE9,
  kId_Split     = 0xEA,
  kId_Rpm       = 0xEB,
  kId_Deb       = 0xEC,
  kId_Cpio      = 0xED,
  kId_Tar       = 0xEE,
  kId_GZip      = 0xEF,
}

.enum {

  kpidNoProperty,
  kpidMainSubfile,
  kpidHandlerItemIndex,
  kpidPath,
  kpidName,
  kpidExtension,
  kpidIsDir,
  kpidSize,
  kpidPackSize,
  kpidAttrib,
  kpidCTime,
  kpidATime,
  kpidMTime,
  kpidSolid,
  kpidCommented,
  kpidEncrypted,
  kpidSplitBefore,
  kpidSplitAfter,
  kpidDictionarySize,
  kpidCRC,
  kpidType,
  kpidIsAnti,
  kpidMethod,
  kpidHostOS,
  kpidFileSystem,
  kpidUser,
  kpidGroup,
  kpidBlock,
  kpidComment,
  kpidPosition,
  kpidPrefix,
  kpidNumSubDirs,
  kpidNumSubFiles,
  kpidUnpackVer,
  kpidVolume,
  kpidIsVolume,
  kpidOffset,
  kpidLinks,
  kpidNumBlocks,
  kpidNumVolumes,
  kpidTimeType,
  kpidBit64,
  kpidBigEndian,
  kpidCpu,
  kpidPhySize,
  kpidHeadersSize,
  kpidChecksum,
  kpidCharacts,
  kpidVa,
  kpidId,
  kpidShortName,
  kpidCreatorApp,
  kpidSectorSize,
  kpidPosixAttrib,
  kpidSymLink,
  kpidError,
  kpidTotalSize,
  kpidFreeSpace,
  kpidClusterSize,
  kpidVolumeName,
  kpidLocalName,
  kpidProvider,
  kpidNtSecure,
  kpidIsAltStream,
  kpidIsAux,
  kpidIsDeleted,
  kpidIsTree,
  kpidSha1,
  kpidSha256,
  kpidErrorType,
  kpidNumErrors,
  kpidErrorFlags,
  kpidWarningFlags,
  kpidWarning,
  kpidNumStreams,
  kpidNumAltStreams,
  kpidAltStreamsSize,
  kpidVirtualSize,
  kpidUnpackSize,
  kpidTotalPhySize,
  kpidVolumeIndex,
  kpidSubType,
  kpidShortComment,
  kpidCodePage,
  kpidIsNotArcType,
  kpidPhySizeCantBeDetected,
  kpidZerosTailIsAllowed,
  kpidTailSize,
  kpidEmbeddedStubSize,
  kpidNtReparse,
  kpidHardLink,
  kpidINode,
  kpidStreamId,
  kpidReadOnly,
  kpidOutName,
  kpidCopyLink,
  kpidArcFileName,
  kpidIsHash,
  kpidChangeTime,
  kpidUserId,
  kpidGroupId,
  kpidDeviceMajor,
  kpidDeviceMinor,
  kpidDevMajor,
  kpidDevMinor,

  kpid_NUM_DEFINED,

  kpidUserDefined = 0x10000
}


.namespace NExtract

  .namespace NAskMode

      .enum {
        kExtract,
        kTest,
        kSkip,
        kReadExternal
      }
  .endn

  .namespace NOperationResult

      .enum {
        kOK,
        kUnsupportedMethod,
        kDataError,
        kCRCError,
        kUnavailable,
        kUnexpectedEnd,
        kDataAfterEnd,
        kIsNotArc,
        kHeadersError,
        kWrongPassword
      }
  .endn
.endn


.comdef IInArchive : public IUnknown

    Open                            proc :ptr, :ptr, :ptr
    Close                           proc
    GetNumberOfItems                proc :ptr
    GetProperty                     proc :DWORD, :DWORD, :ptr
    Extract                         proc :ptr, :DWORD, :SDWORD, :ptr
    GetArchiveProperty              proc :DWORD, :ptr
    GetNumberOfProperties           proc :ptr
    GetPropertyInfo                 proc :DWORD, :ptr, :ptr, :ptr
    GetNumberOfArchiveProperties    proc :ptr
    GetArchivePropertyInfo          proc :DWORD, :ptr, :ptr, :ptr
   .ends
    LPIARCHIVE          typedef ptr IInArchive


.comdef IOutArchive : public IUnknown

    UpdateItems         proc :ptr, :DWORD, :ptr
    GetFileTimeType     proc :ptr
   .ends
    LPOARCHIVE          typedef ptr IOutArchive



.comdef CUnknown : public IUnknown

    m_refCount          SDWORD ?
   .ends


.comdef CProgress : public CUnknown

    SetTotal            proc :QWORD
    SetCompleted        proc :ptr QWORD
   .ends


.comdef CStream : public CUnknown

    m_Handle            HANDLE ?
    m_IsOutStream       BOOL ?

    Read                proc :ptr, :dword, :ptr dword
    Seek                proc :sqword, :dword, :ptr qword
    SetSize             proc :qword
   .ends
    PSTREAM             typedef ptr CStream


.comdef IArchiveOpenCallback : public CUnknown

    IArchiveOpenCallback proc
    SetTotal            proc :ptr, :ptr
    SetCompleted        proc :ptr, :ptr
   .ends


.comdef CArchiveExtractCallback : public CProgress

    m_Archive           LPIARCHIVE ?
    m_outStream         PSTREAM ?
    m_curId             DWORD ?
    m_setResult         DWORD ?
    m_curFile           PFBLK ?
    m_outPath           LPSTR ?
    m_arcPath           LPSTR ?
    m_outBase           LPWSTR ?
    m_arcBase           LPWSTR ?
    m_outPathW          WCHAR WMAXPATH dup(?)
    m_arcPathW          WCHAR WMAXPATH dup(?)

    CArchiveExtractCallback proc :LPIARCHIVE, :LPSTR, :LPSTR, :PFBLK

    GetStream           proc :DWORD, :PTR PSTREAM, :SDWORD
    PrepareOperation    proc :SDWORD
    SetOperationResult  proc :SDWORD
   .ends


.enum
    UpdateDelete = -1,
    UpdateKeep   =  0,
    UpdateAdd    =  1


.comdef IArchiveUpdateCallback : public CProgress

    GetUpdateItemInfo   proc :DWORD, :ptr SDWORD, :ptr SDWORD, :ptr DWORD
    GetProperty         proc :DWORD, :PROPID, :ptr PROPVARIANT
    GetStream           proc :DWORD, :ptr PSTREAM
    SetOperationResult  proc :SDWORD
   .ends


.comdef IArchiveUpdateCallback2 : public IArchiveUpdateCallback

    GetVolumeSize       proc :DWORD, :QWORD
    GetVolumeStream     proc :DWORD, :ptr PSTREAM
   .ends


.comdef CArchiveUpdateCallback : public IArchiveUpdateCallback2

    m_numId             DWORD ?
    m_newId             DWORD ?
    m_curId             DWORD ?
    m_remId             DWORD ?
    m_idList            LPSTR ?
    m_curFile           PFBLK ?
    m_srcPath           LPSTR ?
    m_arcPath           LPSTR ?
    m_srcBase           LPWSTR ?
    m_arcBase           LPWSTR ?
    m_srcPathW          WCHAR WMAXPATH dup(?)
    m_arcPathW          WCHAR WMAXPATH dup(?)

    CArchiveUpdateCallback proc

    SetPath             proc :LPSTR, :LPSTR, :PFBLK
    InitList            proc :LPSTR, :DWORD, :DWORD
   .ends


.comdef CCryptoGetTextPassword : public CUnknown

    Password            LPWSTR 128 dup(?)
    PasswordIsDefined   BOOL ?

    CCryptoGetTextPassword proc
    CryptoGetTextPassword proc :ptr BSTR
   .ends

define TYPE_7Z  0xAFBC7A37
define TYPE_GZ  0x8B1F
define TYPE_BZ2 0x5A42
define TYPE_CAB 0x4643534D
define TYPE_XZ  0x587A37FD

OpenStream proto :LPWSTR, :BOOL, :ptr PSTREAM

CALLBACK(CREATEZ7OBJ, :ptr, :ptr, :ptr)

.data?
CreateObject    CREATEZ7OBJ ?
fp_blk          PFBLK ?
fp_base         dd ?
arcfile         dw WMAXPATH dup(?)
tmpfile         dw WMAXPATH dup(?)

.data
IID_IInArchive  GUID { 0x23170F69, 0x40C1, 0x278A, { 0x00, 0x00, 0x00, 0x06, 0x00, 0x60, 0x00, 0x00 } }
IID_IOutArchive GUID { 0x23170F69, 0x40C1, 0x278A, { 0x00, 0x00, 0x00, 0x06, 0x00, 0xA0, 0x00, 0x00 } }
CLSID_Format    GUID { 0x23170F69, 0x40C1, 0x278A, { 0x10, 0x00, 0x00, 0x01, 0x10, 0x07, 0x00, 0x00 } }

IsLoaded        DWORD 0

.code

option proc: private

DisplayError proc hr:HRESULT, msg:string_t

   .new szMessage:string_t

    ldr ecx,hr

    .if (SUCCEEDED(ecx))
        .return( 0 )
    .endif
    .if (HRESULT_FACILITY(ecx) == FACILITY_WINDOWS)
        mov hr,HRESULT_CODE(ecx)
    .endif
    FormatMessage(
            FORMAT_MESSAGE_ALLOCATE_BUFFER or FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS,
            NULL,
            hr,
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            &szMessage,
            0,
            NULL)
    mov rcx,szMessage
    .if ( rcx )
        mov byte ptr [rcx+rax-2],0
    .else
        lea rcx,@CStr("Unknown error")
    .endif
    ermsg("7-zip", "%s\n%s\n%08X", msg, rcx, hr)
    LocalFree(szMessage)
    mov eax,hr
    ret

DisplayError endp

;-------------------------------------------------------------------------
; IUnknown
;-------------------------------------------------------------------------

CUnknown::QueryInterface proc WINAPI uses rbx riid:LPIID, ppv:ptr ptr

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(riid)

    ldr rcx,this
    ldr rdx,riid
    ldr rbx,ppv

    movzx eax,[rdx].GUID.Data4[3]
    mov ah,[rdx].GUID.Data4[5]

    .if ( eax == 0x0303 || eax == 0x0403 )

        mov [rbx],rcx
        InterlockedIncrement(&[rcx].CUnknown.m_refCount)
        xor eax,eax

    .elseif ( eax == 0x1005 )

        CCryptoGetTextPassword()
        mov [rbx],rax
        xor eax,eax
    .else
        mov eax,E_NOINTERFACE
    .endif
    ret

CUnknown::QueryInterface endp

CUnknown::AddRef proc WINAPI

    UNREFERENCED_PARAMETER(this)

    ldr rcx,this

    InterlockedIncrement(&[rcx].CUnknown.m_refCount)
    ret

CUnknown::AddRef endp

CUnknown::Release proc WINAPI

    UNREFERENCED_PARAMETER(this)

    ldr rcx,this

    .if ( InterlockedDecrement(&[rcx].CUnknown.m_refCount) == 0 )

        free(rcx)
        xor eax,eax
    .endif
    ret

CUnknown::Release endp

;-------------------------------------------------------------------------
; ICryptoGetTextPassword
;-------------------------------------------------------------------------

    assume rbx:ptr CCryptoGetTextPassword

CCryptoGetTextPassword::CryptoGetTextPassword proc WINAPI uses rdi rbx pPassword:ptr BSTR

   .new password[128]:char_t

    ldr rbx,this
    ldr rdi,pPassword

    .if ( ![rbx].PasswordIsDefined )

        ; Ask password from user

        mov password,0
        .ifd tgetline("Enter password", &password, 32, 80)

            .if ( password )

                lea ecx,[strlen(&password)+1]
                MultiByteToWideChar(CP_UTF8, 0, &password, ecx, &[rbx].Password, 128)
                mov [rbx].PasswordIsDefined,TRUE
            .endif
        .endif
    .endif

    mov eax,E_FAIL
    .if ( [rbx].PasswordIsDefined )

        SysAllocString(&[rbx].Password)
        mov [rdi],rax
        xor eax,eax
    .endif
    ret

CCryptoGetTextPassword::CryptoGetTextPassword endp


CCryptoGetTextPassword::CCryptoGetTextPassword proc

    @ComAlloc(CCryptoGetTextPassword)
    inc [rax].CCryptoGetTextPassword.m_refCount
    ret

CCryptoGetTextPassword::CCryptoGetTextPassword endp

;-------------------------------------------------------------------------
; IProgress
;-------------------------------------------------------------------------

CProgress::SetTotal proc WINAPI total:QWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(total)

    progress_set(__srcfile, __outfile, total)
    ret

CProgress::SetTotal endp


CProgress::SetCompleted proc WINAPI completeValue:ptr QWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(completeValue)

    ldr rdx,completeValue
    xor eax,eax
    .if ( rcx )
        progress_update([rdx])
    .endif
    ret

CProgress::SetCompleted endp


;-------------------------------------------------------------------------
; IArchiveOpenCallback
;-------------------------------------------------------------------------
if 0
IArchiveOpenCallback::SetTotal proc WINAPI files:ptr QWORD, bytes:ptr QWORD
    xor eax,eax
    ret
IArchiveOpenCallback::SetTotal endp

IArchiveOpenCallback::SetCompleted proc WINAPI files:ptr QWORD, bytes:ptr QWORD
    xor eax,eax
    ret
IArchiveOpenCallback::SetCompleted endp

IArchiveOpenCallback::IArchiveOpenCallback proc
    @ComAlloc(IArchiveOpenCallback)
    inc [rax].IArchiveOpenCallback.m_refCount
    ret
IArchiveOpenCallback::IArchiveOpenCallback endp
endif

;-------------------------------------------------------------------------
; IArchiveExtractCallback
;-------------------------------------------------------------------------

    assume rbx:ptr CArchiveExtractCallback

define kEmptyFileAlias <L"[Content]">

CArchiveExtractCallback::GetStream proc WINAPI uses rsi rdi rbx index:DWORD, outStream:PTR PSTREAM, askExtractMode:SDWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(index)
    UNREFERENCED_PARAMETER(outStream)
    UNREFERENCED_PARAMETER(askExtractMode)

   .new p:LPWSTR
   .new prop:PROPVARIANT
   .new hr:HRESULT

    ldr rbx,this
    ldr ecx,askExtractMode

    xor eax,eax
    .return .if ( ecx != NExtract::NAskMode::kExtract )

    ldr esi,index
    ldr rdi,outStream

    mov [rbx].m_outStream,rax
    mov [rdi],rax
    mov rcx,[rbx].m_outBase
    mov [rcx],eax

    mov prop.vt,VT_EMPTY
    mov [rbx].m_curId,esi

    this.m_Archive.GetProperty(esi, kpidPath, &prop)

    .if ( prop.vt == VT_EMPTY )

        .if ( esi == 0 )

            mov rsi,[rbx].m_curFile
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

    lea rsi,[rbx].m_arcPathW
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
    mov p,rdx

    .for ( eax = 1, esi = 0 : eax : esi += 2 )

        mov rdx,p
        movzx eax,word ptr [rdx+rsi]
        .if ( eax == '\' )
            .ifd ( CreateDirectoryW( &[rbx].m_outPathW, 0 ) == 0 )
                .ifd ( GetLastError() != ERROR_ALREADY_EXISTS )
                    .return ( HRESULT_FROM_WIN32(eax) )
                .endif
            .endif
            mov eax,'\'
        .endif
        mov rcx,[rbx].m_outBase
        mov [rcx+rsi],eax
    .endf
    .if ( prop.vt == VT_BSTR )
        SysFreeString(prop.bstrVal)
    .endif
    .if (SUCCEEDED(OpenStream(&[rbx].m_outPathW, 1, &[rbx].m_outStream)))
        mov [rbx].m_setResult,1
    .endif
    mov rcx,[rbx].m_outStream
    mov [rdi],rcx
    ret

CArchiveExtractCallback::GetStream endp

CArchiveExtractCallback::PrepareOperation proc WINAPI askExtractMode:SDWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(askExtractMode)
    xor eax,eax
    ret

CArchiveExtractCallback::PrepareOperation endp

CArchiveExtractCallback::SetOperationResult proc WINAPI uses rsi rdi rbx opRes:SDWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(opRes)

   .new prop:PROPVARIANT

    ldr rbx,this

    xor eax,eax
    .if ( eax != [rbx].m_setResult )

        mov [rbx].m_setResult,eax
        mov prop.vt,VT_EMPTY
        this.m_Archive.GetProperty([rbx].m_curId, kpidMTime, &prop)
        .if ( prop.vt == VT_FILETIME )

            .ifd ( CreateFileW( &[rbx].m_outPathW, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL) != INVALID_HANDLE_VALUE )

                mov rsi,rax
                SetFileTime( rsi, 0, 0, &prop.filetime )
                CloseHandle( rsi )
            .endif
        .endif
        mov prop.vt,VT_EMPTY
        this.m_Archive.GetProperty([rbx].m_curId, kpidAttrib, &prop)
        .if ( prop.vt != VT_EMPTY )
            SetFileAttributesW( &[rbx].m_outPathW, prop.ulVal )
        .endif
        xor eax,eax
    .endif
    ret

CArchiveExtractCallback::SetOperationResult endp


CArchiveExtractCallback::CArchiveExtractCallback proc uses rsi rdi rbx archive:LPIARCHIVE,
        outPath:LPSTR, arcPath:LPSTR, curFile:PFBLK

    UNREFERENCED_PARAMETER(archive)
    UNREFERENCED_PARAMETER(outPath)

    ldr rsi,archive
    ldr rdi,outPath

    mov rbx,@ComAlloc(CArchiveExtractCallback)
    .if ( rax == NULL )
        .return
    .endif

    mov [rbx].m_Archive,rsi
    mov [rbx].m_outPath,rdi
    mov [rbx].m_arcPath,arcPath
    mov [rbx].m_curFile,curFile

    lea rsi,[rbx].m_outPathW
    .ifd ( MultiByteToWideChar(CP_UTF8, 0, rdi, -1, &[rbx].m_outPathW, WMAXPATH) > 1 )

        lea rsi,[rbx+rax*2].m_outPathW
        mov eax,'\'
        .if ( ax == [rsi-4] )
            sub rsi,2 ; remove '\' from end of srcpath (C:\)
        .endif
        mov [rsi-2],eax
    .endif
    mov [rbx].m_outBase,rsi

    lea rdi,[rbx].m_arcPathW
    .ifd ( MultiByteToWideChar(CP_UTF8, 0, [rbx].m_arcPath, -1, &[rbx].m_arcPathW, WMAXPATH) > 1 )

        lea rdi,[rbx+rax*2].m_arcPathW
    .endif
    mov [rbx].m_arcBase,rdi

    mov rcx,[rbx].m_curFile
    .if ( [rcx].FBLK.flag & _A_SUBDIR )

        MultiByteToWideChar(CP_UTF8, 0, [rcx].FBLK.name, -1, rsi, _MAX_PATH)
        mov ecx,eax
        lea rax,[rbx].m_arcPathW
        .if ( rdi != rax )
            mov eax,'\'
            mov [rdi-2],eax
        .endif
        rep movsw
        CreateDirectoryW( &[rbx].m_outPathW, 0 )
        mov eax,'\'
        .if ( ax == [rdi-4] )
            sub rdi,2
            sub rsi,2
        .endif
        mov [rsi-2],eax
        mov [rbx].m_arcBase,rdi
        mov [rbx].m_outBase,rsi
    .endif
    mov rax,rbx
    ret

CArchiveExtractCallback::CArchiveExtractCallback endp

;-------------------------------------------------------------------------
; IArchiveUpdateCallback
;-------------------------------------------------------------------------

IArchiveUpdateCallback::SetOperationResult proc WINAPI operationResult:SDWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(operationResult)

    xor eax,eax
    ret

IArchiveUpdateCallback::SetOperationResult endp

;-------------------------------------------------------------------------
; IArchiveUpdateCallback2
;-------------------------------------------------------------------------

IArchiveUpdateCallback2::GetVolumeSize proc WINAPI index:DWORD, size:ptr QWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(index)
    UNREFERENCED_PARAMETER(size)
    xor eax,eax
    ret

IArchiveUpdateCallback2::GetVolumeSize endp

IArchiveUpdateCallback2::GetVolumeStream proc WINAPI index:DWORD, volumeStream:ptr PSTREAM

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(index)
    UNREFERENCED_PARAMETER(volumeStream)
    xor eax,eax
    ret

IArchiveUpdateCallback2::GetVolumeStream endp

;-------------------------------------------------------------------------
; CArchiveUpdateCallback
;-------------------------------------------------------------------------

; This loop items to keep -- should be preset to DWORD[count]...
;
; - smaller if delete only
; - equal or bigger for adding
;

    assume rbx:ptr CArchiveUpdateCallback
    assume rcx:ptr CArchiveUpdateCallback

CArchiveUpdateCallback::GetUpdateItemInfo proc WINAPI uses rsi rdi rbx index:DWORD, newData:ptr SDWORD, newProps:ptr SDWORD, indexInArchive:ptr DWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(index)
    UNREFERENCED_PARAMETER(newData)
    UNREFERENCED_PARAMETER(newProps)
    UNREFERENCED_PARAMETER(indexInArchive)

    ldr rbx,this
    ldr rsi,newData
    ldr rcx,newProps
    ldr edi,index

    mov rdx,[rbx].m_idList
    xor eax,eax
    cmp byte ptr [rdx+rdi],UpdateAdd
    setz al
    mov [rcx],eax
    mov [rsi],eax
    mov rcx,indexInArchive

    .ifz ; add a new file ?

        mov eax,-1

    .elseif ( edi < [rbx].m_newId )

        ; next index of file to keep

        .for ( eax = [rbx].m_curId, esi = eax, esi++ : esi < [rbx].m_numId : esi++ )
            .break .if ( byte ptr [rdx+rsi] == UpdateKeep )
        .endf
        mov [rbx].m_curId,esi
    .else

        ; next index of file to delete

        .for ( eax = [rbx].m_remId, esi = eax, esi++ : esi < [rbx].m_numId : esi++ )
            .break .if ( byte ptr [rdx+rsi] == UpdateDelete )
        .endf
        mov [rbx].m_remId,esi
    .endif
    mov [rcx],eax ; [new_array] <-- old index
    xor eax,eax
    ret

CArchiveUpdateCallback::GetUpdateItemInfo endp


CArchiveUpdateCallback::GetProperty proc WINAPI uses rsi rdi rbx index:DWORD, propID:PROPID, value:ptr PROPVARIANT

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(index)
    UNREFERENCED_PARAMETER(propID)
    UNREFERENCED_PARAMETER(value)

    ldr rbx,this
    ldr edx,index

    .for ( rdi = [rbx].m_curFile : rdi : rdi = [rdi].FBLK.next )
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
            mov rdx,[rbx].m_srcBase
            lea rax,[rbx].m_srcPathW
            sub rdx,rax
            shr edx,1
            mov ecx,WMAXPATH
            sub ecx,edx
            MultiByteToWideChar(CP_UTF8, 0, [rdi].FBLK.name, -1, [rbx].m_srcBase, ecx)
            mov [rsi].PROPVARIANT.bstrVal,SysAllocString([rbx].m_srcBase)
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
           .endc
        .endsw
    .endif
    xor eax,eax
    ret

CArchiveUpdateCallback::GetProperty endp


CArchiveUpdateCallback::GetStream proc WINAPI uses rsi rdi rbx index:DWORD, inStream:ptr PSTREAM

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(index)
    UNREFERENCED_PARAMETER(inStream)

    ldr rbx,this
    ldr edx,index
    ldr rsi,inStream

    .for ( rdi = [rbx].m_curFile : rdi : rdi = [rdi].FBLK.next )
        .break .if ( edx == [rdi+FBLK].ZINF.z7id )
    .endf

    mov eax,E_FAIL
    .if ( rdi && edx == [rdi+FBLK].ZINF.z7id )

        strfcat(__srcfile, [rbx].m_srcPath, [rdi].FBLK.name)
        mov rdx,[rbx].m_srcBase
        lea rax,[rbx].m_srcPathW
        sub rdx,rax
        shr edx,1
        mov ecx,WMAXPATH
        sub ecx,edx
        MultiByteToWideChar(CP_UTF8, 0, [rdi].FBLK.name, -1, [rbx].m_srcBase, ecx)
        mov eax,E_FAIL
        .if ( rsi )
            OpenStream(&[rbx].m_srcPathW, 0, rsi)
        .endif
    .endif
    ret

CArchiveUpdateCallback::GetStream endp


CArchiveUpdateCallback::SetPath proc WINAPI uses rsi rbx arcPath:LPSTR, srcPath:LPSTR, curFile:PFBLK

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(srcPath)
    UNREFERENCED_PARAMETER(arcPath)

    ldr rbx,this
    ldr rdx,arcPath
    ldr rsi,srcPath
    ldr rcx,curFile

    mov [rbx].m_arcPath,rdx
    mov [rbx].m_srcPath,rsi
    mov [rbx].m_curFile,rcx

    .if ( rdx )

        .ifd ( MultiByteToWideChar(CP_UTF8, 0, rdx, -1, &[rbx].m_arcPathW, WMAXPATH) > 1 )

            lea rcx,[rbx+rax*2+2].m_arcPathW
            mov eax,'\'
            .if ( ax == [rcx-4] )
                sub rcx,2
            .endif
            mov [rcx-2],eax
            mov [rbx].m_arcBase,rcx
        .endif
    .endif

    .if ( rsi )

        .ifd ( MultiByteToWideChar(CP_UTF8, 0, rsi, -1, &[rbx].m_srcPathW, WMAXPATH) > 1 )

            lea rcx,[rbx+rax*2].m_srcPathW
            mov eax,'\'
            .if ( ax == [rcx-4] )
                sub rcx,2
            .endif
            mov [rcx-2],eax
            mov [rbx].m_srcBase,rcx
        .endif
    .endif
    xor eax,eax
    ret

CArchiveUpdateCallback::SetPath endp

CArchiveUpdateCallback::InitList proc WINAPI uses rbx idList:LPSTR, numId:DWORD, newId:DWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(idList)
    UNREFERENCED_PARAMETER(numId)
    UNREFERENCED_PARAMETER(newId)

    ldr rbx,this
    ldr rdx,idList
    ldr ecx,numId
    ldr eax,newId

    mov [rbx].m_numId,ecx   ; src count
    mov [rbx].m_newId,eax   ; new count
    mov [rbx].m_idList,rdx  ; del | keep | add

    ; first index of file to keep

    .for ( eax = 0 : eax < ecx : eax++ )
        .break .if ( byte ptr [rdx+rax] == UpdateKeep )
    .endf
    mov [rbx].m_curId,eax

    ; first index of file to delete

    .for ( eax = 0 : eax < ecx : eax++ )
        .break .if ( byte ptr [rdx+rax] == UpdateDelete )
    .endf
    mov [rbx].m_remId,eax
    xor eax,eax
    ret

CArchiveUpdateCallback::InitList endp

CArchiveUpdateCallback::CArchiveUpdateCallback proc

    .if @ComAlloc(CArchiveUpdateCallback)

        inc [rax].CArchiveUpdateCallback.m_refCount
        lea rdx,[rax].CArchiveUpdateCallback.m_arcPathW
        lea rcx,[rax].CArchiveUpdateCallback.m_srcPathW
        mov [rax].CArchiveUpdateCallback.m_arcBase,rdx
        mov [rax].CArchiveUpdateCallback.m_srcBase,rcx
    .endif
    ret

CArchiveUpdateCallback::CArchiveUpdateCallback endp

;-------------------------------------------------------------------------
; ISequentialInStream, ISequentialOutStream
;-------------------------------------------------------------------------

    assume rcx:ptr CStream
    assume rbx:ptr CStream

CStream::Release proc WINAPI uses rbx

    UNREFERENCED_PARAMETER(this)

   .new hr:HRESULT = S_OK

    ldr rbx,this

    .if ( InterlockedDecrement(&[rbx].m_refCount) == 0 )

        .if ( [rbx].m_Handle != INVALID_HANDLE_VALUE )
            .ifd ( CloseHandle( [rbx].m_Handle ) == 0 )
                mov hr,HRESULT_FROM_WIN32(GetLastError())
            .endif
            mov [rbx].m_Handle,INVALID_HANDLE_VALUE
        .endif
        free( rbx )
    .endif
    mov eax,hr
    ret

CStream::Release endp


CStream::Read proc WINAPI buffer:ptr, size:dword, rdsize:ptr dword

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(buffer)
    UNREFERENCED_PARAMETER(rdsize)

    ldr rcx,this
    ldr rdx,buffer
    ldr rax,rdsize

    .if ( [rcx].m_IsOutStream )
        WriteFile([rcx].m_Handle, rdx, size, rax, NULL)
    .else
        ReadFile([rcx].m_Handle, rdx, size, rax, NULL)
    .endif
    test eax,eax
    mov eax,S_OK
    .ifz
        HRESULT_FROM_WIN32(GetLastError())
    .endif
    ret

CStream::Read endp


CStream::Seek proc WINAPI liDistanceToMove:sqword, dwMoveMethod:dword, lpNewFilePointer:ptr qword

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(dwMoveMethod)
    UNREFERENCED_PARAMETER(lpNewFilePointer)

    ldr rcx,this
    ldr rax,lpNewFilePointer
    ldr edx,dwMoveMethod

    SetFilePointerEx([rcx].m_Handle, liDistanceToMove, rax, edx)
    test eax,eax
    mov eax,S_OK
    .ifz
        HRESULT_FROM_WIN32(GetLastError())
    .endif
    ret

CStream::Seek endp


CStream::SetSize proc WINAPI newSize:qword

    mov eax,E_NOTIMPL
    ret

CStream::SetSize endp

    assume rcx:nothing

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

GetTempArchive endp


OpenStream proc private uses rsi rdi rbx name:LPWSTR, OutStream:BOOL, Stream:ptr PSTREAM

   .new hr:HRESULT = S_OK

    UNREFERENCED_PARAMETER(name)
    UNREFERENCED_PARAMETER(OutStream)
    UNREFERENCED_PARAMETER(Stream)

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
    .if ( [rbx].m_IsOutStream )
        mov edx,GENERIC_WRITE
        mov eax,CREATE_ALWAYS
    .endif
    .ifd ( CreateFileW(rsi, edx, FILE_SHARE_READ, NULL, eax, FILE_ATTRIBUTE_NORMAL, NULL) == INVALID_HANDLE_VALUE )

        free(rbx)
        HRESULT_FROM_WIN32(GetLastError())
    .else
        mov [rbx].m_Handle,rax
        mov [rdi],rbx
        xor eax,eax
    .endif
    ret

OpenStream endp

    assume rbx:nothing


OpenArchive proc private uses rdi pArc:ptr LPIARCHIVE

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
        archive.Release()
    .endif
    mov eax,hr
    ret

OpenArchive endp


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
        mov rcx,fp_blk
        xor eax,eax
        .if ( rcx == NULL )
            mov fp_blk,rdi
        .else
            .while ( rax != [rcx].FBLK.next )
                mov rcx,[rcx].FBLK.next
            .endw
            mov [rcx].FBLK.next,rdi
        .endif
    .endif
    ret

fp_addfile endp


fp_addsub proc private uses rsi rdi path:LPSTR, file:LPSTR

    ldr rbx,path
    ldr rsi,file

    .ifd !progress_set(0, strfcat(__outpath, rbx, rsi), 1)

        mov fp_fileblock,&fp_addfile
        mov fp_directory,&scan_files
        scansub(__outpath, &cp_stdmask, 1)
    .endif
    ret

fp_addsub endp


FindDuplicate proc private uses rsi rdi rbx archive:LPIARCHIVE, numItems:SDWORD, fb:PFBLK

   .new prop:PROPVARIANT

    ldr rbx,fb

    .ifd ( MultiByteToWideChar(CP_UTF8, 0, [rbx].FBLK.name, -1, entryname, WMAXPATH/2) > 1 )

        lea edi,[rax+rax]
        .for ( ebx = 0 : ebx < numItems : ebx++ )

            mov prop.vt,VT_EMPTY
            archive.GetProperty(ebx, kpidPath, &prop)
            .if ( prop.vt == VT_BSTR )

                .ifd ( memcmp(prop.bstrVal, entryname, edi) == 0 )

                    lea eax,[rbx+1]
                   .return
                .endif
                SysFreeString(prop.bstrVal)
            .endif
        .endf
    .endif
    xor eax,eax
    ret

FindDuplicate endp


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

testentryname endp

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
                or fattrib,prop.ulVal
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
        mov eax,ER_READARCH
    .endif
    ret

warcread endp

;-------------------------------------------------------------------------
; Copy
;-------------------------------------------------------------------------

warccopy proc uses rsi rdi rbx wsub:PWSUB, fblk:PFBLK, outPath:LPSTR

   .new archive:LPIARCHIVE = 0
   .new indices[2]:DWORD = {0}

    ldr rsi,wsub
    ldr rbx,fblk

    .if SUCCEEDED(OpenArchive(&archive))

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
                panel_findnext(cpanel)
                mov rbx,rdx
            .endif
        .until !rax
        archive.Release()
    .endif
    ret

warccopy endp


;-------------------------------------------------------------------------
; Add
;-------------------------------------------------------------------------

warcadd proc uses rsi rdi rbx dest:PWSUB, wsub:PWSUB, fblk:PFBLK

    UNREFERENCED_PARAMETER(dest)
    UNREFERENCED_PARAMETER(wsub)
    UNREFERENCED_PARAMETER(fblk)
    xor eax,eax

   .new archive:LPIARCHIVE = rax
   .new outarch:LPOARCHIVE = rax
   .new stream:PSTREAM = rax
   .new callback:ptr CArchiveUpdateCallback = rax
   .new delete:string_t = rax
   .new prop:PROPVARIANT
   .new count:DWORD
   .new blkcount:DWORD
   .new newcount:DWORD
   .new numItems:SDWORD = eax
   .new tempfile:DWORD = eax
   .new hr:HRESULT = eax
   .new wb:WIN32_FIND_DATA

    ldr rsi,dest
    ldr rdi,wsub
    ldr rbx,fblk

    mov fp_blk,rax

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

    .if SUCCEEDED(hr)

        .for ( rbx = fp_blk : rbx : rbx = [rbx].FBLK.next )
            inc eax
        .endf
        mov blkcount,eax
    .endif

    ; Open archive

    .if SUCCEEDED(hr)
        mov hr,OpenArchive(&archive)
    .endif

    .if SUCCEEDED(hr)

        archive.GetNumberOfItems(&numItems)
        .if ( numItems <= 0 )
            mov hr,E_BOUNDS
        .endif
    .endif

    .if SUCCEEDED(hr)

        mov ecx,numItems
        add ecx,blkcount
        mov count,ecx
        mov newcount,ecx

        .if ( malloc(ecx) == NULL )
            mov hr,E_OUTOFMEMORY
        .endif
        mov delete,rax
    .endif

    .if SUCCEEDED(hr)

        mov rbx,rdi
        mov rdi,delete
        mov ecx,numItems
        xor eax,eax
        rep stosb

        .for ( rdi = fp_blk : rdi : rdi = [rdi].FBLK.next )

            .ifd FindDuplicate(archive, numItems, rdi)

                mov rdx,delete
                dec byte ptr [rdx+rax-1]
                dec newcount
            .endif
        .endf

        mov edi,numItems
        mov edx,newcount
        mov eax,count
        sub eax,edx
        sub edi,eax
        add rdi,delete
        mov ecx,blkcount
        sub edx,ecx
        mov eax,1
        rep stosb
        .for ( rdi = fp_blk : rdi : rdi = [rdi].FBLK.next, edx++ )

            mov [rdi+FBLK].ZINF.z7id,edx
        .endf
        mov hr,archive.QueryInterface(&IID_IOutArchive, &outarch)
    .endif
    .if SUCCEEDED(hr)
        mov hr,OpenStream(GetTempArchive(), 1, &stream)
    .endif
    .if SUCCEEDED(hr)
        mov callback,CArchiveUpdateCallback()
        .if ( rax == NULL )
            mov hr,E_OUTOFMEMORY
        .endif
    .endif
    .if SUCCEEDED(hr)

        inc tempfile
        sprintf(__srcfile, "%d selected file(s)", blkcount)
        strfcat(__outfile, [rsi].WSUB.file, [rsi].WSUB.arch)
        callback.InitList( delete, numItems, newcount )
        callback.SetPath( [rsi].WSUB.arch, [rbx].WSUB.path, fp_blk )
        mov hr,outarch.UpdateItems(stream, newcount, callback)
    .endif

    free(delete)
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
    DisplayError(hr, [rsi].WSUB.file)
    ret

warcadd endp


;-------------------------------------------------------------------------
; Delete
;-------------------------------------------------------------------------

warcdelete proc uses rsi rdi rbx wsub:PWSUB, fblk:PFBLK

    UNREFERENCED_PARAMETER(wsub)
    UNREFERENCED_PARAMETER(fblk)
    xor eax,eax

   .new archive:LPIARCHIVE = rax
   .new outarch:LPOARCHIVE = rax
   .new stream:PSTREAM = rax
   .new callback:ptr CArchiveUpdateCallback = rax
   .new delete:string_t = rax
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

        .if ( malloc(numItems) == NULL )
            mov hr,E_OUTOFMEMORY
        .endif
        mov delete,rax
    .endif

    .if SUCCEEDED(hr)

        ; Find selected item count

        mov rdi,delete
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

                                        mov rdx,delete
                                        dec byte ptr [rdx+rdi]
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

                    mov rdi,delete
                    mov ecx,[rbx+FBLK].ZINF.z7id
                    dec byte ptr [rdi+rcx]
                .endif
            .endif
            panel_findnext(cpanel)
            mov rbx,rdx
        .until !rax
    .endif

    .if SUCCEEDED(hr)

        .for ( rdi = delete, eax = 0, ecx = 0 : ecx < numItems : ecx++ )
            mov dl,[rdi+rcx]
            and edx,1
            add eax,edx
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
        mov hr,OpenStream(GetTempArchive(), 1, &stream)
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
        callback.InitList( delete, numItems, count )
        mov hr,outarch.UpdateItems(stream, count, callback)
    .endif
    free(delete)
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
    DisplayError(hr, [rsi].WSUB.file)
    ret

warcdelete endp

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

        .if CArchiveExtractCallback(archive, rdi, [rsi].WSUB.arch, rbx)

            mov ecx,[rbx+FBLK].ZINF.z7id
            mov indices,ecx
            archive.Extract(&indices, 1, 0, rax)
        .endif
        archive.Release()
        mov rdi,strfcat( &fbname, rdi, [rbx].FBLK.name )
        .ifd ( filexist( rdi ) == 1 )

            tview( rdi, 0 )
            remove( rdi )
            mov _diskflag,0
        .endif
    .endif
    ret

warcview endp


;-------------------------------------------------------------------------
; Test
;-------------------------------------------------------------------------

warctest proc uses rsi rdi rbx fblk:PFBLK, sign:int_t

   .new dll[_MAX_PATH]:sbyte

    ldr rbx,fblk
    ldr edi,sign

    .if ( IsLoaded == FALSE )

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
                mov IsLoaded,TRUE
            .else
                FreeLibrary(rsi)
               .return( 0 )
            .endif
        .endif
    .endif
    xor eax,eax
    .if ( IsLoaded != TRUE )
        .return
    .endif

    .switch
    .case edi == TYPE_CAB
        mov eax,kId_Cab
       .endc
    .case edi == TYPE_XZ
        mov eax,kId_Xz
       .endc
    .case edi == TYPE_7Z
        mov eax,kId_7z
       .endc
    .case di == TYPE_GZ
        mov eax,kId_GZip
       .endc
    .case di == TYPE_BZ2
        mov eax,kId_BZip2
       .endc
    .default
        .if CFGetSection("7z.dll")
            mov rsi,rax
            .if strext([rbx].FBLK.name)
                inc rax
                .if INIGetEntry(rsi, rax)
                    .ifd ( strtolx(rax) > kId_GZip )
                        xor eax,eax
                    .endif
                .endif
            .endif
        .endif
    .endsw
    .if ( eax )
        mov CLSID_Format.Data4[5],al
        mov eax,1
    .endif
    ret

warctest endp

    end
