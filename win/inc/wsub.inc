ifndef __WSUB_INC
define __WSUB_INC

include io.inc
include zip.inc
include winbase.inc

define WMAXPATH		2048		; the max length is 8000h..
define WMAXFBLOCK	300000

define _FB_SELECTED	0x00010000
define _FB_ROOTDIR	0x00020000
define _FB_UPDIR	0x00040000
define _FB_CDROOM	0x00080000
define _FB_ARCHZIP	0x00100000
define _FB_ARCHEXT	0x00200000
define _FB_ZENCRYPTED	0x00400000	; if _FB_ARCHZIP
define _FB_ZEXTLOCHD	0x00800000	; if _FB_ARCHZIP
define _FB_ARCHIVE	(_FB_ARCHEXT or _FB_ARCHZIP)
define _A_FATTRIB	0x0000FFFF

define _W_PANELID	0x00000001	; _P_PANELID
define _W_VISIBLE	0x00000002	; _P_VISIBLE
define _W_MINISTATUS	0x00000004	; _P_MINISTATUS
define _W_WIDEVIEW	0x00000008	; _P_WIDEVIEW
define _W_DETAIL	0x00000010	; _P_DETAIL
define _W_DRVINFO	0x00000020	; _P_DRVINFO
define _W_WHIDDEN	0x00000040	; _P_WHIDDEN - Hidden Panel
define _P_FLAGMASK	0x0000007F

define _W_HIDDEN	0x00000080	; Hidden files
define _W_LONGNAME	0x00000100
define _W_SORTNAME	0x00000000
define _W_SORTTYPE	0x00000200
define _W_SORTDATE	0x00000400
define _W_SORTSIZE	0x00000600
define _W_NOSORT	0x00000800
define _W_SORTSUB	0x00001000
define _W_ROOTDIR	0x00002000
define _W_CDROOM	0x00004000
define _W_NETWORK	0x00008000
define _W_REMOVABLE	0x00010000
define _W_TEDIT		0x00020000
define _W_WSREAD	0x00040000	; Read mode: count = 0, fcb = first block
define _W_ARCHZIP	0x00100000
define _W_ARCHEXT	0x00200000
define _W_MALLOC	0x01000000

define _W_ARCHIVE	(_W_ARCHZIP or _W_ARCHEXT)
define _W_DEFAULT	(_W_SORTTYPE or _W_HIDDEN or _W_VISIBLE or _W_MINISTATUS or _W_LONGNAME)

define ATTRIB_ALL	0xB7
define ATTRIB_FILE	0xF7

define _WOPEN		0x01
define _WSAVE		0x02
define _WLOCAL		0x04		; use program or current directory
define _WLOCK		0x08		; lock to this directory
define _WNEWFILE	0x10

define IO_SEARCHCASE	0x0001
define IO_SEARCHHEX	0x0002
define IO_SEARCHSET	0x0004
define IO_SEARCHCUR	0x0008
define IO_SEARCHMASK	0x000F
define IO_SEARCHSUB	0x0020

define IO_RETURNLF	0x0040		; return line index on search
define IO_GLMEM		0x0080		; save pointer in ios_line (ios_bp aligned xxxx0000h)
define IO_CRYPT		0x0100		; Crypted file
define IO_USEUPD	0x0200		; Progress
define IO_UPDTOTAL	0x0400		; Add Read/Write size to total
define IO_USECRC	0x0800		; Update CRC on read/write
define IO_MEMBUF	0x4000		; File in buffer or memory addr
define IO_ERROR		0x8000		; Write fault

define OO_MEM64K	0x00010000	; malloc(segment) aligned xxxx0000h
define OO_MEMBUF	0x00000000	; read, set ios_fsize and IO_MEMBUF

define MAXDRIVES	26

define _DI_ROOTDIR	0x00020000	; _FB_ROOTDIR
define _DI_CDROOM	0x00080000	; _FB_CDROOM
define _DI_VOLID	0x00000008	; _A_VOLID

define _DISK_LOCAL	0x0001
define _DISK_FLOPPY	0x0100
define _DISK_NETWORK	0x0200
define _DISK_SUBST	0x0400
define _DISK_CDROOM	0x0800

define DRIVE_REMOVABLE	2		; _disk_type()
define DRIVE_FIXED	3
define DRIVE_REMOTE	4
define DRIVE_CDROM	5
define DRIVE_RAMDISK	6

ifndef Q64
Q64		UNION
q		dq ?
STRUCT
 q_l		dd ?
 q_h		dd ?
ENDS
Q64		ENDS
endif

DISK		STRUC
flag		dd ?
time		dd ?
size		dq ?
name		db 32 dup(?)
DISK		ENDS
PDISK		typedef ptr DISK

IOST		STRUC
base		LPSTR ?
index		dd ?
cnt		dd ?
size		dd ?
flag		dd ?
file		dd ?
crc		dd ?
line		dd ?	; line offset
union
 offs		dq ?	; seek offset
 struct
  offs_l	dd ?
  offs_h	dd ?
 ends
ends
union
 total		dq ?	; count read/write
 struct
  total_l	dd ?
  total_h	dd ?
 ends
ends
union
 fsize		dq ?
 struct
  fsize_l	dd ?
  fsize_h	dd ?
 ends
ends
sptr		LPSTR ?
IOST		ENDS
PIOST		typedef ptr IOST


; Extra info added to file block

ZINF		union
ftime		FILETIME <>
struct
 csize		dd ? ; compressed size
 crc		dd ? ; crc
 z7id		dd ? ; index in 7z.dll archive
 offs		dd ? ; local offset in zip file or search offset
ends
struct
 base		dd ? ; offset of search base directory
 size		dd ? ; size of search struct
 line		dd ? ; search line
ends
ZINF		ends
PZINF		typedef ptr ZINF

FBLK		struct
flag		dd ?	; _FB_:_A_
time		dd ?	; date:time
size		dq ?
name		LPSTR ?
next		PZINF ?
FBLK		ends
PFBLK		typedef ptr FBLK

WSUB		struct
flag		dd ?
count		dd ?
mask		LPSTR ?
file		LPSTR ?
arch		LPSTR ?
path		LPSTR ?
fcb		PFBLK ?
WSUB		ends
PWSUB		typedef ptr WSUB


fballoc		proto __cdecl :LPSTR, :DWORD, :QWORD, :DWORD
fbupdir		proto __cdecl :DWORD
fballocff	proto __cdecl :DWORD, :DWORD
fbinvert	proto __cdecl :PFBLK
fbselect	proto __cdecl :PFBLK
fbcolor		proto __cdecl :PFBLK

wsalloc		proto __cdecl :DWORD, :DWORD
wsopen		proto __cdecl :PWSUB
wsclose		proto __cdecl :PWSUB
wsinit		proto __cdecl :PWSUB
wsfree		proto __cdecl :PWSUB
wsread		proto __cdecl :PWSUB
wssort		proto __cdecl :PWSUB
wschdrv		proto __cdecl :PWSUB, :DWORD
wsearch		proto __cdecl :PWSUB, :LPSTR
wsfblk		proto __cdecl :PWSUB, :DWORD
wsffirst	proto __cdecl :PWSUB
wsetfcb		proto __cdecl :PWSUB
wsaddfb		proto __cdecl :PWSUB, :PFBLK

wsopenarch	proto __cdecl :PWSUB
wzipread	proto __cdecl :PWSUB
wzipopen	proto __cdecl
wzipclose	proto __cdecl
wsdecomp	proto __cdecl :PWSUB, :PFBLK, :LPSTR
wzipadd		proto __cdecl :QWORD, :DWORD, :DWORD
wzipdel		proto __cdecl :PWSUB, :PFBLK
wsmkzipdir	proto __cdecl :PWSUB, :LPSTR
wscopyremove	proto __cdecl :LPSTR
wscopyopen	proto __cdecl :LPSTR, :LPSTR

wsfindfirst	proto __cdecl :LPSTR, :PWIN32_FIND_DATA, :UINT
wscloseff	proto __cdecl :HANDLE
wedit		proto __cdecl :PFBLK, :SINT

scansub		proto __cdecl :LPSTR, :LPSTR, :UINT
scan_files	proto __cdecl :LPSTR
scan_directory	proto __cdecl :UINT, :LPSTR

_disk_read	proto __cdecl
_disk_exist	proto __cdecl :UINT
_disk_init	proto __cdecl :UINT
_disk_type	proto __cdecl :UINT
_disk_ready	proto __cdecl :UINT
_disk_retry	proto __cdecl :UINT
_disk_select	proto __cdecl :LPSTR

GetVolumeID	proto __cdecl :LPSTR, :LPSTR
GetFileSystemName proto __cdecl :LPSTR, :LPSTR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CALLBACKC(FPDIR, :LPSTR)
CALLBACKC(FPBLK, :LPSTR, :PWIN32_FIND_DATA)
CALLBACKC(IOUPD, :PIOST)

externdef	STDI:IOST
externdef	STDO:IOST
externdef	oupdate:IOUPD

externdef	fp_maskp:LPSTR
externdef	fp_directory:FPDIR
externdef	fp_fileblock:FPBLK
externdef	scan_fblock:PWIN32_FIND_DATA

externdef	cp_stdmask:SBYTE
externdef	cp_warning:SBYTE

externdef	__srcpath:LPSTR
externdef	__outpath:LPSTR
externdef	__srcfile:LPSTR
externdef	__outfile:LPSTR
externdef	entryname:LPSTR
externdef	crctab:DWORD

removefile	proto __cdecl :LPSTR
removetemp	proto __cdecl :LPSTR
filexist	proto __cdecl :LPSTR
setfattr	proto __cdecl :LPTSTR, :UINT

eropen		proto __cdecl :LPSTR
ermkdir		proto __cdecl :LPSTR
erdelete	proto __cdecl :LPSTR
errnomsg	proto __cdecl :LPSTR, :LPSTR, :LPSTR

wdlgopen	proto __cdecl :LPSTR, :LPSTR, :DWORD
wgetfile	proto __cdecl :LPSTR, :LPSTR, :DWORD

ioinit		proto __cdecl :PIOST, :DWORD
ioopen		proto __cdecl :PIOST, :LPSTR, :DWORD, :DWORD
ioseek		proto __cdecl :PIOST, :QWORD, :DWORD
iocopy		proto __cdecl :PIOST, :PIOST, :QWORD
ioflush		proto __cdecl :PIOST
ioread		proto __cdecl :PIOST
ioclose		proto __cdecl :PIOST
iofree		proto fastcall :PIOST
iowrite		proto __cdecl :PIOST, :PTR, :SIZE_T
iotell		proto fastcall :PIOST
oputc		proto __cdecl :SINT
ogetc		proto __cdecl
oupdcrc		proto __cdecl
osearch		proto __cdecl
notfoundmsg	proto __cdecl
oreadb		proto __cdecl :LPSTR, :DWORD
oungetc		proto __cdecl
oread		proto __cdecl :DWORD
oprintf		proto __Cdecl :LPSTR, :VARARG
ogetl		proto __cdecl :LPSTR, :LPSTR, :DWORD
ogets		proto __cdecl
oputs		proto __cdecl :LPSTR
ogetouth	proto __cdecl :LPSTR, :DWORD
openfile	proto __cdecl :LPSTR, :DWORD, :DWORD
oseek		proto __cdecl :size_t, :DWORD

endif
