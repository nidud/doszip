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
    LPIARCHIVE                      typedef ptr IInArchive


.comdef IOutArchive : public IUnknown

    UpdateItems                     proc :ptr, :DWORD, :ptr
    GetFileTimeType                 proc :ptr
   .ends
    LPOARCHIVE                      typedef ptr IOutArchive



.comdef CUnknown : public IUnknown

    refCount        SDWORD ?
   .ends


.comdef Z7Stream : public CUnknown

    stHandle        HANDLE ?
    IsOutStream     BOOL ?

    Read            proc :ptr, :dword, :ptr dword
    Seek            proc :sqword, :dword, :ptr qword
    SetSize         proc :qword
   .ends
    PZSTREAM        typedef ptr Z7Stream


.comdef Z7OpenCallback : public CUnknown

    Z7OpenCallback  proc
    SetTotal        proc :ptr, :ptr
    SetCompleted    proc :ptr, :ptr
   .ends


.comdef Z7ExtractCallback : public CUnknown

    Archive             LPIARCHIVE ?
    OutStream           PZSTREAM ?
    Index               DWORD ?
    Result              DWORD ?
    Base                LPWSTR ?
    SubDir              PWSUB ?
    FileBlock           PFBLK ?
    OutPath             WCHAR WMAXPATH dup(?)
    ArcPath             WCHAR WMAXPATH dup(?)

    Z7ExtractCallback   proc :LPIARCHIVE, :LPSTR, :PWSUB, :PFBLK
    SetTotal            proc :QWORD
    SetCompleted        proc :ptr QWORD
    GetStream           proc :DWORD, :PTR PZSTREAM, :SDWORD
    PrepareOperation    proc :SDWORD
    SetOperationResult  proc :SDWORD
   .ends


.comdef Z7UpdateCallback : public CUnknown

    List                LPSTR ?
    Count               DWORD ?
    Index               DWORD ?
    FileBlock           PFBLK ?
    Total               QWORD ?
    SrcBase             LPWSTR ?
    ArcBase             LPWSTR ?
    SrcDir              PWSUB ?
    ArcDir              PWSUB ?
    SrcPath             WCHAR WMAXPATH dup(?)
    ArcPath             WCHAR WMAXPATH dup(?)

    Z7UpdateCallback    proc :LPSTR, :DWORD, :PWSUB, :PWSUB
    SetTotal            proc :QWORD
    SetCompleted        proc :ptr QWORD
    GetUpdateItemInfo   proc :DWORD, :ptr SDWORD, :ptr SDWORD, :ptr DWORD
    GetProperty         proc :DWORD, :PROPID, :ptr PROPVARIANT
    GetStream           proc :DWORD, :ptr PZSTREAM
    SetOperationResult  proc :SDWORD
   .ends


.comdef Z7GetPassword : public CUnknown

    Password            LPWSTR 128 dup(?)
    PasswordIsDefined   BOOL ?

    Z7GetPassword       proc
    CGetPassword        proc :ptr BSTR
   .ends

define TYPE_7Z  0xAFBC7A37
define TYPE_GZ  0x8B1F
define TYPE_BZ2 0x5A42
define TYPE_CAB 0x4643534D
define TYPE_XZ  0x587A37FD

OpenStream proto :LPWSTR, :BOOL, :ptr PZSTREAM

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

Z7Error proc hr:HRESULT, msg:string_t

   .new szMessage:string_t

    ldr edx,hr
    .if (HRESULT_FACILITY(edx) == FACILITY_WINDOWS)
        mov hr,HRESULT_CODE(edx)
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

Z7Error endp

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
        InterlockedIncrement(&[rcx].CUnknown.refCount)
        xor eax,eax

    .elseif ( eax == 0x1005 )

        Z7GetPassword()
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

    InterlockedIncrement(&[rcx].CUnknown.refCount)
    ret

CUnknown::AddRef endp

CUnknown::Release proc WINAPI

    UNREFERENCED_PARAMETER(this)

    ldr rcx,this

    .if ( InterlockedDecrement(&[rcx].CUnknown.refCount) == 0 )

        free(rcx)
        xor eax,eax
    .endif
    ret

CUnknown::Release endp

;-------------------------------------------------------------------------
; ICryptoGetTextPassword
;-------------------------------------------------------------------------

    assume rbx:ptr Z7GetPassword

Z7GetPassword::CGetPassword proc WINAPI uses rdi rbx pPassword:ptr BSTR

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

Z7GetPassword::CGetPassword endp


Z7GetPassword::Z7GetPassword proc

    @ComAlloc(Z7GetPassword)
    inc [rax].Z7GetPassword.refCount
    ret

Z7GetPassword::Z7GetPassword endp

;-------------------------------------------------------------------------
; IArchiveOpenCallback
;-------------------------------------------------------------------------

Z7OpenCallback::SetTotal proc WINAPI files:ptr QWORD, bytes:ptr QWORD
    xor eax,eax
    ret
Z7OpenCallback::SetTotal endp

Z7OpenCallback::SetCompleted proc WINAPI files:ptr QWORD, bytes:ptr QWORD
    xor eax,eax
    ret
Z7OpenCallback::SetCompleted endp

Z7OpenCallback::Z7OpenCallback proc
    @ComAlloc(Z7OpenCallback)
    ret
Z7OpenCallback::Z7OpenCallback endp

;-------------------------------------------------------------------------
; IArchiveExtractCallback
;-------------------------------------------------------------------------

    assume rbx:ptr Z7ExtractCallback

Z7ExtractCallback::SetTotal proc WINAPI total:QWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(total)

    ldr rcx,this

    mov rcx,[rcx].Z7ExtractCallback.FileBlock
    progress_set([rcx].FBLK.name, __outpath, total)
    ret

Z7ExtractCallback::SetTotal endp

Z7ExtractCallback::SetCompleted proc WINAPI completeValue:ptr QWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(completeValue)

    ldr rdx,completeValue

    progress_update([rdx])
    ret

Z7ExtractCallback::SetCompleted endp

define kEmptyFileAlias <L"[Content]">

Z7ExtractCallback::GetStream proc WINAPI uses rsi rdi rbx index:DWORD, outStream:PTR PZSTREAM, askExtractMode:SDWORD

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

    mov [rbx].OutStream,rax
    mov [rdi],rax
    mov rcx,[rbx].Base
    mov [rcx],eax

    mov prop.vt,ax ; VT_EMPTY
    mov prop.wReserved1,ax
    mov prop.bstrVal,rax
    mov [rbx].Index,esi

    this.Archive.GetProperty(esi, kpidPath, &prop)

    .if ( prop.vt == VT_EMPTY )

        .if ( esi == 0 )

            mov rsi,[rbx].FileBlock
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

    lea rsi,[rbx].ArcPath
    movzx eax,word ptr [rsi]
    .if ( eax )
        .for ( : eax && ax == [rdx] : rdx+=2, rsi+=2, ax = [rsi] )
        .endf
        .if ( eax || word ptr [rdx] != '\' )
            .return( 0 )
        .endif
        add rdx,2
    .endif
    mov p,rdx

    .for ( eax = 1, esi = 0 : eax : esi += 2 )

        mov rdx,p
        movzx eax,word ptr [rdx+rsi]
        .if ( eax == '\' )

            .ifd ( CreateDirectoryW( &[rbx].OutPath, 0 ) == 0 )

                .ifd ( GetLastError() != ERROR_ALREADY_EXISTS )

                    .return ( HRESULT_FROM_WIN32(eax) )
                .endif
            .endif
            mov eax,'\'
        .endif
        mov rcx,[rbx].Base
        mov [rcx+rsi],eax
    .endf
    .if (SUCCEEDED(OpenStream(&[rbx].OutPath, 1, &[rbx].OutStream)))
        mov [rbx].Result,1
    .endif
    mov rcx,[rbx].OutStream
    mov [rdi],rcx
    ret

Z7ExtractCallback::GetStream endp

Z7ExtractCallback::PrepareOperation proc WINAPI askExtractMode:SDWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(askExtractMode)
    xor eax,eax
    ret

Z7ExtractCallback::PrepareOperation endp

Z7ExtractCallback::SetOperationResult proc WINAPI uses rsi rdi rbx opRes:SDWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(opRes)

   .new prop:PROPVARIANT

    ldr rbx,this

    xor eax,eax
    .if ( eax != [rbx].Result )

        mov [rbx].Result,eax
        mov prop.vt,VT_EMPTY
        this.Archive.GetProperty([rbx].Index, kpidMTime, &prop)
        .if ( prop.vt == VT_FILETIME )

            .ifd ( CreateFileW( &[rbx].OutPath, GENERIC_WRITE, FILE_SHARE_READ, NULL,
                    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL) != INVALID_HANDLE_VALUE )

                mov rsi,rax
                SetFileTime( rsi, 0, 0, &prop.filetime )
                CloseHandle( rsi )
            .endif
        .endif
        mov prop.vt,VT_EMPTY
        this.Archive.GetProperty([rbx].Index, kpidAttrib, &prop)
        .if ( prop.vt != VT_EMPTY )
            SetFileAttributesW( &[rbx].OutPath, prop.ulVal )
        .endif
        xor eax,eax
    .endif
    ret

Z7ExtractCallback::SetOperationResult endp

Z7ExtractCallback::Z7ExtractCallback proc uses rsi rdi rbx archive:LPIARCHIVE,
        outPath:LPSTR, ws:PWSUB, fb:PFBLK

    UNREFERENCED_PARAMETER(archive)
    UNREFERENCED_PARAMETER(outPath)

    ldr rsi,archive
    ldr rdi,outPath

    mov rbx,@ComAlloc(Z7ExtractCallback)
    .if ( rax == NULL )
        .return
    .endif

    mov [rbx].Archive,rsi
    mov esi,strlen(rdi)
    MultiByteToWideChar(CP_UTF8, 0, rdi, esi, &[rbx].OutPath, WMAXPATH)
    lea rcx,[rbx+rsi*2+2].OutPath
    mov eax,'\'
    .if ( ax == [rcx-4] )
        sub rcx,2 ; remove '\' from end of outpath (C:\)
    .endif
    mov [rcx-2],eax
    mov [rbx].Base,rcx
    mov rdi,ws
    mov [rbx].SubDir,rdi
    lea esi,[strlen([rdi].WSUB.arch)+1]
    MultiByteToWideChar(CP_UTF8, 0, [rdi].WSUB.arch, esi, &[rbx].ArcPath, WMAXPATH)

    mov [rbx].FileBlock,fb
    .if ( [rax].FBLK.flag & _A_SUBDIR )

        mov rdi,[rax].FBLK.name
        lea esi,[strlen(rdi)+1]
        MultiByteToWideChar(CP_UTF8, 0, rdi, esi, [rbx].Base, _MAX_PATH)
        CreateDirectoryW( &[rbx].OutPath, 0 )
        add esi,esi
        mov eax,'\'
        lea rdi,[rbx].ArcPath
        .if word ptr [rdi]
            .while word ptr [rdi]
                add rdi,2
            .endw
            stosw
        .endif
        mov ecx,esi
        mov rsi,[rbx].Base
        add [rbx].Base,rcx
        rep movsb
        mov [rdi],cx
        mov rcx,[rbx].Base
        mov [rcx-2],eax
    .endif
    mov rax,rbx
    ret

Z7ExtractCallback::Z7ExtractCallback endp


;-------------------------------------------------------------------------
; IArchiveUpdateCallback
;-------------------------------------------------------------------------

.enum {
    UpdateDelete = -1,
    UpdateKeep   =  0,
    UpdateAdd    =  1,
    }

    assume rbx:ptr Z7UpdateCallback
    assume rcx:ptr Z7UpdateCallback

Z7UpdateCallback::SetTotal proc WINAPI total:QWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(total)

    ldr rcx,this

    mov [rcx].Total,total
    mov rdx,[rcx].ArcDir
    progress_set("", [rdx].WSUB.file, total)
    ret

Z7UpdateCallback::SetTotal endp


Z7UpdateCallback::SetCompleted proc WINAPI completeValue:ptr QWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(completeValue)

    ldr rdx,completeValue

    xor eax,eax
    .if ( rcx )
        progress_update([rdx])
    .endif
    ret

Z7UpdateCallback::SetCompleted endp


Z7UpdateCallback::GetUpdateItemInfo proc WINAPI uses rsi rdi rbx index:DWORD, newData:ptr SDWORD, newProps:ptr SDWORD, indexInArchive:ptr DWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(index)
    UNREFERENCED_PARAMETER(newData)
    UNREFERENCED_PARAMETER(newProps)
    UNREFERENCED_PARAMETER(indexInArchive)

    ldr rbx,this
    ldr rsi,newData
    ldr edx,index
    ldr rcx,newProps

    mov rdi,[rbx].List
    movsx edi,byte ptr [rdi+rdx]
    xor eax,eax
    cmp edi,UpdateAdd
    setz al
    .if ( rcx )
        mov [rcx],eax
    .endif
    .if ( rsi )
        mov [rsi],eax
    .endif

    mov rcx,indexInArchive
    .if ( rcx )
        mov eax,-1
        .if ( edi == UpdateKeep )
            mov eax,[rbx].Index
            inc [rbx].Index
        .elseif ( edi == UpdateDelete )
            mov eax,[rbx].Count
            inc [rbx].Count
        .endif
        mov [rcx],eax
    .endif
    xor eax,eax
    ret

Z7UpdateCallback::GetUpdateItemInfo endp


Z7UpdateCallback::GetProperty proc WINAPI uses rsi rdi rbx index:DWORD, propID:PROPID, value:ptr PROPVARIANT

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(index)
    UNREFERENCED_PARAMETER(propID)
    UNREFERENCED_PARAMETER(value)

    ldr rbx,this
    ldr edx,index

    .for ( rdi = [rbx].FileBlock : rdi : rdi = [rdi].FBLK.next )
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
            lea ecx,[strlen([rdi].FBLK.name)+1]
            mov rdx,[rbx].SrcBase
            lea rax,[rbx].SrcPath
            sub rdx,rax
            shr edx,1
            mov eax,WMAXPATH
            sub eax,edx
            MultiByteToWideChar(CP_UTF8, 0, [rdi].FBLK.name, ecx, [rbx].SrcBase, eax)
            mov [rsi].PROPVARIANT.bstrVal,SysAllocString([rbx].SrcBase)
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

Z7UpdateCallback::GetProperty endp


Z7UpdateCallback::GetStream proc WINAPI uses rsi rdi rbx index:DWORD, inStream:ptr PZSTREAM

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(index)
    UNREFERENCED_PARAMETER(inStream)

    ldr rbx,this
    ldr edx,index
    ldr rsi,inStream

    .for ( rdi = [rbx].FileBlock : rdi : rdi = [rdi].FBLK.next )
        .break .if ( edx == [rdi+FBLK].ZINF.z7id )
    .endf
    mov eax,E_FAIL
    .if ( rdi && edx == [rdi+FBLK].ZINF.z7id )

        mov rdx,[rbx].ArcDir
        progress_set([rdi].FBLK.name, [rdx].WSUB.file, [rbx].Total)
        lea ecx,[strlen([rdi].FBLK.name)+1]
        mov rdx,[rbx].SrcBase
        lea rax,[rbx].SrcPath
        sub rdx,rax
        shr edx,1
        mov eax,WMAXPATH
        sub eax,edx
        MultiByteToWideChar(CP_UTF8, 0, [rdi].FBLK.name, ecx, [rbx].SrcBase, eax)
        mov eax,E_FAIL
        .if ( rsi )
            OpenStream(&[rbx].SrcPath, 0, rsi)
        .endif
    .endif
    ret

Z7UpdateCallback::GetStream endp


Z7UpdateCallback::SetOperationResult proc WINAPI operationResult:SDWORD

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(operationResult)

    xor eax,eax
    ret

Z7UpdateCallback::SetOperationResult endp


Z7UpdateCallback::Z7UpdateCallback proc uses rsi rdi rbx list:LPSTR, count:DWORD, srcDir:PWSUB, arcDir:PWSUB

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(list)
    UNREFERENCED_PARAMETER(count)
    UNREFERENCED_PARAMETER(srcDir)
    UNREFERENCED_PARAMETER(arcDir)

    ldr rbx,list
    ldr edi,count
    ldr rsi,srcDir

    .return .if ( @ComAlloc(Z7UpdateCallback) == NULL )

    mov rdx,arcDir
    mov [rax].Z7UpdateCallback.List,rbx
    mov [rax].Z7UpdateCallback.Count,edi
    mov [rax].Z7UpdateCallback.SrcDir,rsi
    mov [rax].Z7UpdateCallback.ArcDir,rdx
    .if ( rsi == NULL )
        .return
    .endif
    mov rbx,rax

    mov [rbx].FileBlock,fp_blk
    mov rcx,[rsi].WSUB.arch
    .if ( byte ptr [rcx] )
        mov edi,strlen(rcx)
        MultiByteToWideChar(CP_UTF8, 0, [rsi].WSUB.arch, edi, &[rbx].ArcPath, WMAXPATH)
        lea rcx,[rbx+rdi*2+2].ArcPath
        mov eax,'\'
        mov [rcx-2],eax
    .else
        lea rcx,[rbx].ArcPath
    .endif
    mov [rbx].ArcBase,rcx

    mov rsi,[rbx].SrcDir
    mov edi,strlen([rsi].WSUB.path)
    MultiByteToWideChar(CP_UTF8, 0, [rsi].WSUB.path, edi, &[rbx].SrcPath, WMAXPATH)
    lea rcx,[rbx+rdi*2+2].SrcPath
    mov eax,'\'
    .if ( ax == [rcx-4] )
        sub rcx,2 ; remove '\' from end of Srcpath (C:\)
    .endif
    mov [rcx-2],eax
    mov [rbx].SrcBase,rcx
    mov rax,rbx
    ret

Z7UpdateCallback::Z7UpdateCallback endp

;-------------------------------------------------------------------------
; ISequentialInStream, ISequentialOutStream
;-------------------------------------------------------------------------

    assume rcx:ptr Z7Stream
    assume rbx:ptr Z7Stream

Z7Stream::Release proc WINAPI uses rbx

    UNREFERENCED_PARAMETER(this)

   .new hr:HRESULT = S_OK
    ldr rbx,this

    .if ( InterlockedDecrement(&[rbx].refCount) == 0 )

        .if ( [rbx].stHandle != INVALID_HANDLE_VALUE )
            .ifd ( CloseHandle( [rbx].stHandle ) == 0 )
                mov hr,HRESULT_FROM_WIN32(GetLastError())
            .endif
            mov [rbx].stHandle,INVALID_HANDLE_VALUE
        .endif
        free( rbx )
    .endif
    mov eax,hr
    ret

Z7Stream::Release endp


Z7Stream::Read proc WINAPI buffer:ptr, size:dword, rdsize:ptr dword

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(buffer)
    UNREFERENCED_PARAMETER(rdsize)

    ldr rcx,this
    ldr rdx,buffer
    ldr rax,rdsize

    .if ( [rcx].IsOutStream )
        WriteFile([rcx].stHandle, rdx, size, rax, NULL)
    .else
        ReadFile([rcx].stHandle, rdx, size, rax, NULL)
    .endif
    test eax,eax
    mov eax,S_OK
    .ifz
        HRESULT_FROM_WIN32(GetLastError())
    .endif
    ret

Z7Stream::Read endp


Z7Stream::Seek proc WINAPI liDistanceToMove:sqword, dwMoveMethod:dword, lpNewFilePointer:ptr qword

    UNREFERENCED_PARAMETER(this)
    UNREFERENCED_PARAMETER(dwMoveMethod)
    UNREFERENCED_PARAMETER(lpNewFilePointer)

    ldr rcx,this
    ldr rax,lpNewFilePointer
    ldr edx,dwMoveMethod

    SetFilePointerEx([rcx].stHandle, liDistanceToMove, rax, edx)
    test eax,eax
    mov eax,S_OK
    .ifz
        HRESULT_FROM_WIN32(GetLastError())
    .endif
    ret

Z7Stream::Seek endp


Z7Stream::SetSize proc WINAPI newSize:qword

    mov eax,E_NOTIMPL
    ret

Z7Stream::SetSize endp

    assume rcx:nothing

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


OpenStream proc private uses rsi rdi rbx name:LPWSTR, OutStream:BOOL, Stream:ptr PZSTREAM

   .new hr:HRESULT = S_OK

    UNREFERENCED_PARAMETER(name)
    UNREFERENCED_PARAMETER(OutStream)
    UNREFERENCED_PARAMETER(Stream)

    ldr rsi,name
    ldr ebx,OutStream
    ldr rdi,Stream

    .if ( @ComAlloc(Z7Stream) == NULL )
        .return( E_OUTOFMEMORY )
    .endif
    mov [rax].Z7Stream.IsOutStream,ebx
    inc [rax].Z7Stream.refCount
    mov rbx,rax
    xor eax,eax
    mov [rdi],rax
    mov edx,GENERIC_READ
    mov eax,OPEN_EXISTING
    .if ( [rbx].IsOutStream )
        mov edx,GENERIC_WRITE
        mov eax,CREATE_ALWAYS
    .endif
    .ifd ( CreateFileW(rsi, edx, FILE_SHARE_READ, NULL, eax, FILE_ATTRIBUTE_NORMAL, NULL) == INVALID_HANDLE_VALUE )

        free(rbx)
        HRESULT_FROM_WIN32(GetLastError())
    .else
        mov [rbx].stHandle,rax
        mov [rdi],rbx
        xor eax,eax
    .endif
    ret

OpenStream endp

    assume rbx:nothing


OpenArchive proc private uses rsi rdi ws:PWSUB, pArc:ptr LPIARCHIVE

   .new pos:QWORD = 0
   .new archive:LPIARCHIVE = 0
   .new stream:PZSTREAM = 0
   .new hr:HRESULT

    ldr rsi,ws
    ldr rdi,pArc

    mov hr,CreateObject(&CLSID_Format, &IID_IInArchive, &archive)
    .if ( FAILED(hr) )
        .return
    .endif

    mov hr,OpenStream(&arcfile, 0, &stream)
    .if ( FAILED(hr) )

        archive.Release()
        Z7Error(hr, [rsi].WSUB.file)
       .return( hr )
    .endif
    mov hr,archive.Open(stream, &pos, Z7OpenCallback())
    mov rsi,stream
    .if ( [rsi].Z7Stream.refCount > 1 )
        mov [rsi].Z7Stream.refCount,1
    .endif
    .if ( FAILED(hr) )
        archive.Release()
        .if ( [rsi].Z7Stream.refCount > 0 )
            stream.Release()
        .endif
    .else
        mov rcx,archive
        mov [rdi],rcx
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


FindDuplicate proc private uses rsi rdi rbx archive:LPIARCHIVE, numItems:DWORD, fb:PFBLK

   .new prop:PROPVARIANT

    ldr rbx,fb

    lea edi,[strlen([rbx].FBLK.name)+1]
    MultiByteToWideChar(CP_UTF8, 0, [rbx].FBLK.name, edi, entryname, WMAXPATH/2)
    add edi,edi

    .for ( ebx = 0 : ebx < numItems : ebx++ )

        mov prop.vt,VT_EMPTY
        archive.GetProperty(ebx, kpidPath, &prop)
        .if ( prop.vt == VT_BSTR )

            .ifd ( memcmp(prop.bstrVal, entryname, edi) == 0 )

                lea eax,[rbx+1]
               .return
            .endif
        .endif
    .endf
    xor eax,eax
    ret

FindDuplicate endp


;
; Returns 0 if entry not part of basepath,
; else _A_ARCH or _A_SUBDIR.
;
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
   .new numItems:DWORD = 0
   .new ftime:DWORD
   .new curtime:DWORD
   .new fattrib:DWORD
   .new name:LPSTR = entryname

    ldr rsi,ws

    strfcat(entryname, [rsi].WSUB.path, [rsi].WSUB.file)
    lea edi,[strlen(entryname)+1]
    MultiByteToWideChar(CP_UTF8, 0, entryname, edi, &arcfile, WMAXPATH)
    strcat(entryname, ".$$$")
    add edi,4
    MultiByteToWideChar(CP_UTF8, 0, entryname, edi, &tmpfile, WMAXPATH)

    .if (SUCCEEDED(OpenArchive(rsi, &archive)))

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

warccopy proc uses rsi rdi rbx wsub:PWSUB, fblk:PFBLK, outp:LPSTR

   .new archive:LPIARCHIVE = 0
   .new indices[2]:DWORD = {0}

    mov rsi,wsub
    mov rbx,fblk
    mov rdi,outp

    .if (SUCCEEDED(OpenArchive(rsi, &archive)))
        .repeat
            .break .if !Z7ExtractCallback(archive, rdi, rsi, rbx)
            and [rbx].FBLK.flag,not _FB_SELECTED
            .if ( [rbx].FBLK.flag & _A_SUBDIR )
                archive.Extract(NULL, -1, 0, rax)
            .else
                mov ecx,[rbx+FBLK].ZINF.z7id
                mov indices,ecx
                archive.Extract(&indices, 1, 0, rax)
            .endif
            panel_findnext(cpanel)
            mov rbx,rdx
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
   .new stream:PZSTREAM = rax
   .new delete:string_t = rax
   .new prop:PROPVARIANT
   .new count:DWORD
   .new blkcount:DWORD
   .new newcount:DWORD
   .new numItems:DWORD = eax
   .new hr:HRESULT
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
            jmp done
        .endif
        panel_findnext(cpanel)
        mov rbx,rdx
    .until !rax

    .for ( rbx = fp_blk : rbx : rbx = [rbx].FBLK.next )
        inc eax
    .endf
    mov blkcount,eax

    ; Open archive

    mov hr,OpenArchive(rsi, &archive)
    .if (FAILED(hr))
        jmp done
    .endif
    archive.GetNumberOfItems(&numItems)

    mov ecx,numItems
    add ecx,blkcount
    jz done

    mov count,ecx
    mov newcount,ecx
    mov delete,malloc(ecx)
    .if ( !rax )
        jmp done
    .endif

    mov rbx,rdi
    mov rdi,rax
    mov ecx,numItems
    xor eax,eax
    rep stosb
    mov ecx,blkcount
    inc eax
    rep stosb

    .for ( rdi = fp_blk : rdi : rdi = [rdi].FBLK.next )

        .ifd FindDuplicate(archive, numItems, rdi)

            mov rdx,delete
            dec byte ptr [rdx+rax-1]
            dec newcount
        .endif
    .endf

    mov hr,archive.QueryInterface(&IID_IOutArchive, &outarch)
    .if ( FAILED(eax) )
        jmp done
    .endif
    mov hr,OpenStream(&tmpfile, 1, &stream)
    .if ( FAILED(eax) )
        jmp done
    .endif

    .if ( newcount != count )

        ; Delete duplicated files

        sub eax,newcount
        mov edx,numItems
        sub edx,eax
        mov count,edx
        mov hr,outarch.UpdateItems(stream, count, Z7UpdateCallback( delete, count, 0, rsi ))
        SafeRelease(outarch)
        SafeRelease(archive)
        stream.Release()

        .if (SUCCEEDED(hr))

            _wremove(&arcfile)
            _wrename(&tmpfile, &arcfile)
            .if ( eax )
                mov hr,E_FAIL
                jmp done
            .endif
        .else
            _wremove(&tmpfile)
            jmp done
        .endif

        ; Reopen archive

        mov hr,OpenArchive(rsi, &archive)
        .if ( FAILED(eax) )
            jmp done
        .endif
        archive.GetNumberOfItems(&numItems)

        mov hr,archive.QueryInterface(&IID_IOutArchive, &outarch)
        .if ( FAILED(eax) )
            jmp done
        .endif
        mov hr,OpenStream(&tmpfile, 1, &stream)
        .if ( FAILED(eax) )
            jmp done
        .endif

        mov rdi,delete
        mov ecx,numItems
        xor eax,eax
        rep stosb
        mov ecx,blkcount
        inc eax
        rep stosb
    .endif

    mov edx,numItems
    .for ( rdi = fp_blk : rdi : rdi = [rdi].FBLK.next, edx++ )
        mov [rdi+FBLK].ZINF.z7id,edx
    .endf

    mov eax,numItems
    add eax,blkcount
    mov count,eax
    mov hr,outarch.UpdateItems(stream, count, Z7UpdateCallback( delete, numItems, rbx, rsi ))
    SafeRelease(outarch)
    SafeRelease(archive)
    stream.Release()

    .if (SUCCEEDED(hr))

        _wremove(&arcfile)
        _wrename(&tmpfile, &arcfile)
    .else
        _wremove(&tmpfile)
    .endif

done:

    mov rbx,fp_blk
    .while ( rbx )
        mov rcx,rbx
        mov rbx,[rbx].FBLK.next
        free(rcx)
    .endw
    SafeRelease(outarch)
    SafeRelease(archive)
    free(delete)
    .if ( FAILED(hr) )
        Z7Error(hr, [rsi].WSUB.file)
    .endif
    mov eax,hr
    ret

warcadd endp


;-------------------------------------------------------------------------
; Delete
;-------------------------------------------------------------------------

warcdelete proc uses rsi rdi rbx wsub:PWSUB, fblk:PFBLK

   .new archive:LPIARCHIVE = 0
   .new outarch:LPOARCHIVE = 0
   .new stream:PZSTREAM = 0
   .new delete:string_t = 0
   .new prop:PROPVARIANT
   .new sublen:DWORD
   .new count:DWORD
   .new numItems:DWORD = 0
   .new hr:HRESULT

    ldr rsi,wsub
    ldr rbx,fblk

    mov hr,OpenArchive(rsi, &archive)
    .if (FAILED(hr))
        jmp done
    .endif
    archive.GetNumberOfItems(&numItems)
    .if ( !numItems )
        jmp done
    .endif
    mov delete,malloc(numItems)
    .if ( !rax )
        jmp done
    .endif

    ; Find selected item count

    mov rdi,rax
    mov ecx,numItems
    xor eax,eax
    rep stosb

    .repeat

        and [rbx].FBLK.flag,not _FB_SELECTED
        .if ( [rbx].FBLK.flag & _A_SUBDIR )

            ; Delete subdir

            confirm_delete_sub([rbx].FBLK.name)
            test eax,eax
            jz done

            .if ( eax == 1 )

                mov edi,strlen([rbx].FBLK.name)
                MultiByteToWideChar(CP_UTF8, 0, [rbx].FBLK.name, edi, entryname, WMAXPATH/2)
                add edi,edi
                mov sublen,edi

                .for ( edi = 0 : edi < numItems : edi++ )

                    mov prop.vt,VT_EMPTY
                    archive.GetProperty(edi, kpidPath, &prop)
                    .if ( prop.vt == VT_BSTR )

                        .ifd ( memcmp(prop.bstrVal, entryname, sublen) == 0 )

                            mov rcx,prop.bstrVal
                            mov edx,sublen
                            movzx eax,word ptr [rcx+rdx]
                            .if ( eax == '\' || eax == 0 )

                                mov rdx,delete
                                dec byte ptr [rdx+rdi]
                            .endif
                        .endif
                    .endif
                .endf
            .endif

        .else

            ; Delete file

            confirm_delete_file([rbx].FBLK.name, [rbx].FBLK.flag)
            test eax,eax
            jz done
            .if ( eax == 1 )

                mov rdi,delete
                mov ecx,[rbx+FBLK].ZINF.z7id
                dec byte ptr [rdi+rcx]
            .endif
        .endif
        panel_findnext(cpanel)
        mov rbx,rdx
    .until !rax

    .for ( rdi = delete, eax = 0, ecx = 0 : ecx < numItems : ecx++ )

        .if ( byte ptr [rdi+rcx] != 0 )

            inc eax
        .endif
    .endf
    .if ( !eax )
        jmp done
    .endif
    mov ecx,numItems
    sub ecx,eax
    mov count,ecx

    mov hr,archive.QueryInterface(&IID_IOutArchive, &outarch)
    .if ( FAILED(eax) )
        jmp done
    .endif
    mov hr,OpenStream(&tmpfile, 1, &stream)
    .if ( FAILED(eax) )
        jmp done
    .endif
    mov hr,outarch.UpdateItems(stream, count, Z7UpdateCallback( delete, count, 0, rsi ))
    SafeRelease(outarch)
    SafeRelease(archive)
    stream.Release()

    .if (SUCCEEDED(hr))

        _wremove(&arcfile)
        _wrename(&tmpfile, &arcfile)
    .else
        _wremove(&tmpfile)
    .endif

done:

    SafeRelease(outarch)
    SafeRelease(archive)
    free(delete)
    .if ( FAILED(hr) )
        Z7Error(hr, [rsi].WSUB.file)
    .endif
    mov eax,hr
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

    .if (SUCCEEDED(OpenArchive(rsi, &archive)))

        .if Z7ExtractCallback(archive, rdi, rsi, rbx)

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
