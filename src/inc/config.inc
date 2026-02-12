ifndef __CONFIG_INC
define __CONFIG_INC

.enum {
    CON_MIN_X = 1,
    CON_MIN_Y,
    CON_MIN_COL,
    CON_MIN_ROW,
    CON_MAX_X,
    CON_MAX_Y,
    CON_MAX_COL,
    CON_MAX_ROW,
    CON_USEDEFAULT
    }

if 0
.enum EntryType {
    C_EMPTY,
    C_BASE,
    C_SECTION,
    C_ENTRY,
    C_COMMENT
    }

    config_t typedef ptr Config

.class Config

    name        string_t ?
    next        config_t ?
    list        intptr_t ?
    type        uint_t ?

    Config      proc
    Release     proc
    Read        proc :string_t
    Write       proc :string_t
    Find        proc :string_t
    GetEntry    proc :string_t, :string_t
    Create      proc :string_t, :vararg
    Delete      proc :string_t
    Unlink      proc :config_t
   .ends
endif

define INI_BASE         0
define INI_SECTION      1
define INI_ENTRY        2
define INI_COMMENT      4


LPINI           typedef ptr S_INI
S_INI           STRUC
flags           UINT ?
entry           LPSTR ?         ; [<Section>]  | <Entry>
union
 value          LPSTR ?         ; first entry  | value
 first          LPINI ?
ends
next            LPINI ?         ; next section | next entry
S_INI           ENDS

CFBLK           union 1
struct
 loff           dd ?
 yoff           dd ?
 boff           dd ?
 xoff           dd ?
 tabz           dd ?
 flag           dd ?
 name           string_t ?
ends
struct
 attrib         dd ?
 fcb_index      dd ?
 cel_index      dd ?
 path           string_t ?
ends
CFBLK           ends
PCFBLK          typedef ptr CFBLK

INIRead         proto __cdecl :LPINI, :LPSTR
INIWrite        proto __cdecl :LPINI, :LPSTR
INIClose        proto __cdecl :LPINI
INIAlloc        proto __cdecl
INIGetSection   proto __cdecl :LPINI, :LPSTR
INIGetEntry     proto __cdecl :LPINI, :LPSTR
INIGetEntryID   proto __cdecl :LPINI, :UINT
INIGetNextEntry proto __cdecl :LPINI
INIAddSection   proto __cdecl :LPINI, :LPSTR
INIDelSection   proto __cdecl :LPINI, :LPSTR
INIDelEntries   proto __cdecl :LPINI
INIAddEntryX    proto __Cdecl :LPINI, :LPSTR, :VARARG

CFRead          proto __cdecl :LPSTR
CFWrite         proto __cdecl :LPSTR
CFClose         proto __cdecl
CFGetSection    proto __cdecl :LPSTR
CFGetSectionID  proto __cdecl :LPSTR, :UINT
CFGetSecEntry   proto __cdecl :LPSTR, :LPSTR
CFAddSection    proto __cdecl :LPSTR
CFReadFileName  proto __cdecl :LPINI, :PCFBLK, :UINT
CFFindSection   proto __cdecl :LPINI, :LPSTR, :LPSTR

CFExecute       proto __cdecl :LPINI
CFExpandMac     proto __cdecl :LPSTR, :LPSTR
CFExpandCmd     proto __cdecl :LPSTR, :LPSTR, :LPSTR
CFGetComspec    proto __cdecl :UINT
CFError         proto __cdecl :LPSTR, :LPSTR

externdef       __CFBase:LPINI

TIOpenSession   proto __cdecl :LPINI, :LPSTR
TISaveSession   proto __cdecl :LPINI, :LPSTR

endif
