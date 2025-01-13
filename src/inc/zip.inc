ifndef __ZIP_INC
define __ZIP_INC
include libc.inc

define ZIPHEADERID	0x4B50	; two-byte zip lead-in
define ZIPLOCALID	0x0403	; signature local file
define ZIPCENTRALID	0x0201	; signature central file
define ZIPDIGITALID	0x0505	; digital signature
define ZIPENDSENTRID	0x0605	; signature end central

define WSIZE		0x8000

define ER_ZIP		2
define ER_BADERR	3
define ER_MEM		4
define ER_CRCERR	5
define ER_NOZIP		9
define ER_FIND		11
define ER_OPEN		12
define ER_DISK		50
define ER_USERABORT	E_FAIL;66
define ER_READARCH	(-2)

.pragma pack(push, 1)

LZIP		STRUC	; Local file header: 30 byte
pkzip		dw ?	; local file header signature
zipid		dw ?
version		dw ?	; version needed to extract
flag		dw ?	; general purpose bit flag
method		dw ?	; compression method
time		dw ?	; last mod file time
date		dw ?	; last mod file date
crc		dd ?	; crc-32
csize		dd ?	; compressed size
fsize		dd ?	; uncompressed size
fnsize		dw ?	; file name length
extsize		dw ?	; extra field length
LZIP		ENDS

CZIP		STRUC	; Central directory structure: 46 byte
pkzip		dw ?	; central file header signature
zipid		dw ?
version_made	dw ?	; version made by
version_need	dw ?	; version needed to extract
bitflag		dw ?	; general purpose bit flag
method		dw ?	; compression method
time		dw ?	; last mod file time
date		dw ?	; last mod file date
crc		dd ?	; crc-32
csize		dd ?	; compressed size
fsize		dd ?	; uncompressed size
fnsize		dw ?	; file name length
extsize		dw ?	; extra field length
cmtsize		dw ?	; file comment length
disk		dw ?	; disk number start
int_attrib	dw ?	; internal file attributes
ext_attrib	dw ?	; external file attributes
ext_attribdx	dw ?
off_local	dd ?	; relative offset of local header
CZIP		ENDS	; 46 byte

ZEND		STRUC	; End of central directory record: 22 byte
pkzip		dw ?	; end of central dir signature
zipid		dw ?
disk_cur	dw ?	; number of this disk
disk_one	dw ?	; number at start of the central directory
entry_cur	dw ?	; central directory on this disk
entry_dir	dw ?	; total entries in the central directory
size_cent	dd ?	; size central directory
off_cent	dd ?	; offset central directory
comment_size	dw ?	; .ZIP file comment length
ZEND		ENDS
PZEND		typedef ptr ZEND

.pragma pack(pop)

externdef zip_local:LZIP
externdef zip_central:CZIP
externdef file_method:BYTE
externdef compresslevel:UINT
externdef copy_fast:BYTE

zip_inflate	proto __cdecl
zip_explode	proto __cdecl
zip_deflate	proto __cdecl :UINT

endif
