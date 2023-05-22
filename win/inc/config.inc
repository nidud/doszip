ifndef __CONFIG_INC
define __CONFIG_INC

define INI_BASE		0
define INI_SECTION	1
define INI_ENTRY	2
define INI_COMMENT	4

S_INI		STRUC
flags		UINT ?
entry		LPSTR ?		; [<Section>]  | <Entry>
value		PVOID ?		; first entry  | value
next		PVOID ?		; next section | next entry
S_INI		ENDS
LPINI		typedef ptr S_INI

INIRead		proto __cdecl :LPINI, :LPSTR
INIWrite	proto __cdecl :LPINI, :LPSTR
INIClose	proto __cdecl :LPINI
INIAlloc	proto __cdecl
INIGetSection	proto __cdecl :LPINI, :LPSTR
INIGetEntry	proto __cdecl :LPINI, :LPSTR
INIGetEntryID	proto __cdecl :LPINI, :UINT
INIAddSection	proto __cdecl :LPINI, :LPSTR
INIDelSection	proto __cdecl :LPINI, :LPSTR
INIDelEntries	proto __cdecl :LPINI
INIAddEntryX	proto __Cdecl :LPINI, :LPSTR, :VARARG

CFRead		proto __cdecl :LPSTR
CFWrite		proto __cdecl :LPSTR
CFClose		proto __cdecl
CFGetSection	proto __cdecl :LPSTR
CFGetSectionID	proto __cdecl :LPSTR, :UINT
CFAddSection	proto __cdecl :LPSTR
CFReadFileName	proto __cdecl :LPINI, :PTR, :UINT
CFFindSection	proto __cdecl :LPINI, :LPSTR, :LPSTR

CFExecute	proto __cdecl :LPINI
CFExpandMac	proto __cdecl :LPSTR, :LPSTR
CFExpandCmd	proto __cdecl :LPSTR, :LPSTR, :LPSTR
CFGetComspec	proto __cdecl :UINT
CFError		proto __cdecl :LPSTR, :LPSTR

externdef	__CFBase:LPINI

TIOpenSession	proto __cdecl :LPINI, :LPSTR
TISaveSession	proto __cdecl :LPINI, :LPSTR

endif
