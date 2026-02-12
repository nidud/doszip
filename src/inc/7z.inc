; 7Z.INC--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;
ifndef __7Z_INC
define __7Z_INC

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

    m_curId             DWORD ?
    m_idList            LPDWORD ?
    m_srcPath           LPSTR ?
    m_arcPath           LPSTR ?
    m_srcBase           LPWSTR ?
    m_arcBase           LPWSTR ?
    m_srcPathW          WCHAR WMAXPATH dup(?)
    m_arcPathW          WCHAR WMAXPATH dup(?)

    CArchiveUpdateCallback proc
    SetPath             proc :LPSTR, :LPSTR
    InitList            proc :LPDWORD
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

define kEmptyFileAlias <L"[Content]">

OpenStream proto :LPWSTR, :BOOL, :ptr PSTREAM

CALLBACK(CREATEZ7OBJ, :ptr, :ptr, :ptr)

endif

