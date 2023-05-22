ifndef __TVIEW_INC
define __TVIEW_INC

_TV_USEMLINE	equ 01h
_TV_USESLINE	equ 02h
_TV_HEXVIEW	equ 04h
_TV_WRAPLINES	equ 08h
_TV_HEXOFFSET	equ 10h
_TV_HIGHCOLOR	equ 20h
_TV_BINVIEW	equ 40h
_TV_CLASSVIEW	equ 80h

tview		proto __cdecl :LPSTR, :size_t
load_tedit	proto __cdecl :LPSTR, :int_t
load_tview	proto __cdecl :LPSTR, :int_t
view_readme	proto __cdecl :DWORD

endif
