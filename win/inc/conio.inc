.pragma list(push, 0)
ifndef __INC_CONIO
define __INC_CONIO

include wincon.inc
include keyb.inc

ifndef _INTPTR_T_DEFINED
define _INTPTR_T_DEFINED
ifdef _WIN64
intptr_t typedef sqword
else
intptr_t typedef sdword
endif
endif

define MAXCOLS		240	; max/min screen size
define MAXROWS		240
define MINCOLS		80
define MINROWS		25
define TIMAXSCRLINE	MAXCOLS

define B_Desktop	0	; at_background
define B_Panel		1
define B_Dialog		2
define B_Menus		3
define B_Error		4
define B_Title		5
define B_Inverse	6
define B_Gray		7
define B_PushButt	8
define B_InvPanel	9
define B_InvMenus	10
define B_TextView	12
define B_TextEdit	13

define F_Title		0	; at_foreground
define F_Frame		1
define F_Files		2
define F_System		3
define F_Hidden		4
define F_PBShade	5
define F_KeyBar		6
define F_Desktop	7
define F_Inactive	8
define F_Dialog		9
define F_Panel		10
define F_Subdir		11
define F_Menus		12
define F_TitleKey	13
define F_DialogKey	14
define F_MenusKey	15
define F_TextView	(16+14)
define F_TextEdit	(16+15)

define CON_UBEEP	0x0001	; Use Beep
define CON_MOUSE	0x0002	; Use Mouse
define CON_IOSFN	0x0004	; Use Long File Names
define CON_CLIPB	0x0008	; Use System Clipboard
define CON_NETCFG	0x0010	; Use Network Config
define CON_NTCMD	0x0020	; Use NT Prompt
define CON_CMDENV	0x0040	; CMD Compatible Mode
define CON_IMODE	0x0080	; Init screen mode on startup
define CON_UTIME	0x0200	; Use Time
define CON_UDATE	0x0400	; Use Date
define CON_LTIME	0x0800	; Use Long Time HH:MM:SS
define CON_LDATE	0x1000	; Use Long Date YYYY-MM-DD
define CON_SLEEP	0x2000	; Wait if set
define CON_SIMDE	0x4000	; Use SSE Functions
define CON_WIN95	0x8000	; Windows 95 mode if set
define CON_DEFAULT	0x42AA

define CON_SLEEP_TIME	10	; Time to wait
define CURSOR_NORMAL	16

define _D_DOPEN		0x0001
define _D_ONSCR		0x0002
define _D_DMOVE		0x0004
define _D_SHADE		0x0008
define _D_MYBUF		0x0010	; do not delete on exit (static)
define _D_RCNEW		0x0020	; dlclose -- delete dialog if set
define _D_RESAT		0x0040	; attrib is index in color table (rcedit)
define _D_DHELP		0x0080	; execute thelp() if set
define _D_CLEAR		0x0100	; args on open/create
define _D_BACKG		0x0200
define _D_FOREG		0x0400
define _D_STDLG		0x0800
define _D_STERR		0x1000	; error color (red)
define _D_MENUS		0x2000	; menus color (gray), no title
define _D_MUSER		0x4000
define _D_KLINE		0x8000

define _D_COLOR		(_D_BACKG or _D_FOREG)
define _D_RESRC		(_D_RCNEW or _D_MYBUF)
define _D_SETRC		(_D_RCNEW or _D_MYBUF or _D_DOPEN)
define _D_STDDLG	(_D_DMOVE or _D_SHADE or _D_CLEAR or _D_COLOR)
define _D_STDERR	(_D_STDDLG or _D_STERR)

define _O_PBUTT		0
define _O_RBUTT		1
define _O_CHBOX		2
define _O_XCELL		3
define _O_TEDIT		4
define _O_MENUS		5
define _O_XHTML		6
define _O_MOUSE		7
define _O_LLMSU		8
define _O_LLMSD		9
define _O_TBUTT		10

define _O_RADIO		0x0010	; Used in (*) Radio	(one of)
define _O_FLAGB		0x0020	; Used in [x] switch (ON/OFF)
define _O_LLIST		0x0040	; Linked list item
define _O_DTEXT		0x0080	; Select text on activation
define _O_CONTR		0x0100	; Allow _CONTROL chars
define _O_DEXIT		0x0200	; Close dialog and return 0: Cancel
define _O_PBKEY		0x0400	; Return result if short key used
define _O_DLGED		0x0800	; dialog text -- return Left/Right
define _O_GLCMD		0x1000	; Object contain global short-key table
define _O_EVENT		0x2000	; Object have local event handler
define _O_CHILD		0x4000	; Object have a child
define _O_STATE		0x8000	; State (ON/OFF)
define _O_DEACT		_O_STATE

define _C_NORMAL	1
define _C_RETURN	2
define _C_ESCAPE	3
define _C_REOPEN	4

define _TE_MODIFIED	1
define _TE_OVERWRITE	2
define _TE_USECONTROL	_O_CONTR
define _TE_DLEDIT	_O_DLGED ; dialog text -- return Left/Right

define _TE_CONTINUE	0	; continue edit
define _TE_RETEVENT	1	; return current event (keystroke)
define _TE_CMFAILED	(-1)	; operation fail (end of line/buffer)

define TIMAXLINE	0x8000	; max line size
define TIMAXFILE	0x200000; max file size
define TIMAXFILES	300	; max open files
define TITABCHAR	0x0B	; expand tabs with this char (Vertical Tab)
define TIMAXTABSIZE	16	; max Tab size
define STYLESIZE	0x4000

define _T_PANELB	0x0001
define _T_MALLOC	0x0002
define _T_TEDIT		0x0004
define _T_FILE		0x0008
define _T_MODIFIED	0x0010	; default
define _T_USEMENUS	0x0020	;*[x] Ctrl-M (F11)
define _T_OPTIMALFILL	0x0040	;*[x] Ctrl-F
define _T_OVERWRITE	0x0080	;*[x]
define _T_USEINDENT	0x0100	;*[x] Ctrl-I
define _T_USESTYLE	0x0200	;*[x] Ctrl-S
define _T_USETABS	0x0400	;*[x]
define _T_USEBAKFILE	0x0800	;*[x]
define _T_USECRLF	0x1000	;*[x]
define _T_PROMPTONREP	0x2000	; [x]
define _T_USECONTROL	0x4000
define _T_SHOWTABS	0x8000

define _T_TEDEFAULT	0x3FE0
define _T_TECFGMASK	0x3FE0
define _T_UNREAD	0x10000

define _TI_CONTINUE	0	; continue edit
define _TI_RETEVENT	1	; return current event (keystroke)
define _TI_NOTEVENT	2	; event not handled -- continue test
define _TI_CMFAILED	(-1)	; operation fail (end of line/buffer)


externdef _confh:HANDLE
externdef _coninpfh:HANDLE

externdef at_background:byte
externdef at_foreground:byte

externdef console:UINT
externdef _scrrow:DWORD		; Screen rows - 1
externdef _scrcol:DWORD		; Screen columns
externdef _scrmin:COORD		; Min screen columns,rows
externdef _scrmax:COORD		; Max screen columns,rows
externdef _scrrc:RECT		; Window init position

ConsoleIdle	proto __cdecl
ConsolePush	proto __cdecl
CreateConsole	proto __cdecl :LPSTR, :UINT

COLOR		struct
foreground	db 16 dup(?)
background	db 16 dup(?)
COLOR		ends

CURSOR		struct		; CONSOLE_CURSOR_INFO
dwSize		dd ?		; .dwSize	1..100
bVisible	dd ?		; .bVisible	0..1
x		dw ?		; word x,y	COORD
y		dw ?
CURSOR		ends
PCURSOR		typedef ptr CURSOR

_gotoxy		proto __cdecl :int_t, :int_t
_cursoron	proto __cdecl
_cursoroff	proto __cdecl
_getcursor	proto __cdecl :PCURSOR
_setcursor	proto __cdecl :PCURSOR

TRECT		struct
x		db ?
y		db ?
col		db ?
row		db ?
TRECT		ends
PTRECT		typedef ptr TRECT

.enum BOXTYPE {
    BOX_SINGLE,			; Single corners
    BOX_DOUBLE,			; Double corners
    BOX_SINGLE_VERTICAL,	; Single insert corners
    BOX_SINGLE_HORIZONTAL,
    BOX_SINGLE_ARC,		; Single rounded corners
    BOX_CLEAR
    }

rcalloc		proto __cdecl :TRECT, :UINT
rcclose		proto __cdecl :TRECT, :UINT, :PCHAR_INFO
rcshow		proto __cdecl :TRECT, :UINT, :PCHAR_INFO
rcopen		proto __cdecl :TRECT, :UINT, :UINT, :LPSTR, :PTR
rcread		proto __cdecl :TRECT, :PCHAR_INFO
rcwrite		proto __cdecl :TRECT, :PCHAR_INFO
rcmove		proto __cdecl :PTRECT,:PCHAR_INFO, :UINT, :UINT, :UINT
rcbprc		proto __cdecl :TRECT, :PCHAR_INFO, :UINT
rcbprcrc	proto __cdecl :TRECT, :UINT, :PCHAR_INFO, :UINT
rcframe		proto __cdecl :TRECT, :PCHAR_INFO, :UINT, :UINT
rcmemsize	proto __cdecl :TRECT, :UINT
rcxyrow		proto __cdecl :TRECT, :UINT, :UINT
rcinside	proto __cdecl :TRECT, :UINT
rczip		proto __cdecl :TRECT, :PTR, :PCHAR_INFO

wcputf		proto __Cdecl :PCHAR_INFO, :DWORD, :LPSTR, :VARARG
wcputs		proto __cdecl :PCHAR_INFO, :DWORD, :LPSTR
wcpath		proto __cdecl :PCHAR_INFO, :DWORD, :LPSTR
wcputw		proto __cdecl :PCHAR_INFO, :DWORD, :DWORD
wcenter		proto __cdecl :PCHAR_INFO, :DWORD, :LPSTR
wctitle		proto __cdecl :PCHAR_INFO, :DWORD, :LPSTR
wcpbutt		proto __cdecl :PCHAR_INFO, :DWORD, :DWORD, :LPSTR
wcpushst	proto __cdecl :PCHAR_INFO, :LPSTR
wcpopst		proto __cdecl :PCHAR_INFO

getxyc		proto __cdecl :UINT, :UINT
getxyw		proto __cdecl :UINT, :UINT
scgetws		proto __cdecl :UINT, :UINT, :UINT
scputws		proto __cdecl :UINT, :UINT, :UINT, :PTR
scgetword	proto __cdecl :LPSTR
scputa		proto __cdecl :UINT, :UINT, :UINT, :UINT
scputal		proto __cdecl :UINT, :UINT, :UINT, :PTR
scputfg		proto __cdecl :UINT, :UINT, :UINT, :UINT
scputc		proto __cdecl :UINT, :UINT, :UINT, :UINT
scputw		proto __cdecl :UINT, :UINT, :UINT, :UINT
scputs		proto __cdecl :UINT, :UINT, :UINT, :UINT, :LPSTR
scpath		proto __cdecl :SINT, :SINT, :SINT, :LPSTR
scpathl		proto __cdecl :UINT, :UINT, :UINT, :LPSTR
scenter		proto __cdecl :UINT, :UINT, :UINT, :LPSTR
scputf		proto __Cdecl :SINT, :SINT, :SINT, :SINT, :LPSTR, :VARARG


ROBJ		struct 1
flag		dw ?		; 8 byte object size in Resource.idd
count		db ?
index		db ?
rc		TRECT <>
ROBJ		ends
PROBJ		typedef ptr ROBJ

RIDD		struct 1
flag		dw ?
count		db ?
index		db ?
rc		TRECT <>
RIDD		ends
PIDD		typedef ptr RIDD

TOBJ		struct
flag		dw ?
count		db ?
ascii		db ?
rc		TRECT <>
data		PVOID ?
tproc		DPROC ?
TOBJ		ends
PTOBJ		typedef ptr TOBJ

DOBJ		struct
flag		dw ?
count		db ?
index		db ?
rc		TRECT <>
wp		PCHAR_INFO ?
object		PTOBJ ?
DOBJ		ends
PDOBJ		typedef ptr DOBJ

LOBJ		struct
dlgoff		UINT ?	; start index in dialog
dcount		UINT ?	; number of cells (max)
celoff		UINT ?	; cell offset
numcel		UINT ?	; number of visible cells
count		UINT ?	; total number of items in list
index		UINT ?	; index in list buffer
list		PVOID ? ; pointer to list buffer
lproc		DPROC ?
LOBJ		ends
PLOBJ		typedef ptr LOBJ

GLCMD		struct
key		UINT ?
cmd		DPROC ?
GLCMD		ends

dlopen		proto __cdecl :PDOBJ, :DWORD, :LPSTR
dlclose		proto __cdecl :PDOBJ
dlshow		proto __cdecl :PDOBJ
dlhide		proto __cdecl :PDOBJ
dlmove		proto __cdecl :PDOBJ
dlmodal		proto __cdecl :PDOBJ
dlevent		proto __cdecl :PDOBJ
dllevent	proto __cdecl :PDOBJ, :PLOBJ
dlinit		proto __cdecl :PDOBJ
dlinitobj	proto __cdecl :PDOBJ, :PTOBJ
dledit		proto __cdecl :LPSTR, :TRECT, :DWORD, :DWORD
dledite		proto __cdecl :PVOID, :DWORD
dlscreen	proto __cdecl :PDOBJ, :DWORD
dlshowall	proto __cdecl
dlhideall	proto __cdecl
dlcheckevent	proto __cdecl
dlxcellevent	proto __cdecl
tosetbitflag	proto __cdecl :PTOBJ, :DWORD, :DWORD, :DWORD
togetbitflag	proto __cdecl :PTOBJ, :DWORD, :DWORD

rsopen		proto __cdecl :PIDD
rsevent		proto __cdecl :PIDD, :PDOBJ
rsmodal		proto __cdecl :PIDD
rsreload	proto __cdecl :PIDD, :PDOBJ

ermsg		proto __Cdecl :LPSTR, :LPSTR, :VARARG
stdmsg		proto __Cdecl :LPSTR, :LPSTR, :VARARG
msgbox		proto __cdecl :LPSTR, :DWORD, :LPSTR
tgetline	proto __cdecl :LPSTR, :LPSTR, :DWORD, :DWORD

externdef	tdialog:PDOBJ
externdef	tdllist:PLOBJ
externdef	thelp:DPROC

TEDIT		struct
base		LPSTR ?		; base pointer
flags		UINT ?		; config
xpos		UINT ?		; text window x,y
ypos		UINT ?
cols		UINT ?		; size of screen-line
bcol		UINT ?		; size of buffer-line
xoffs		UINT ?		; x offset on screen
boffs		UINT ?		; base offset - start of screen-line
bcount		UINT ?		; byte count in line
clip_so		UINT ?		; Clipboard start offset
clip_eo		UINT ?		; Clipboard end offset
clrc		UINT ?		; clear attrib/char
TEDIT		ends
PTEDIT		typedef ptr TEDIT

tidecx		proto __cdecl :PTEDIT
tiincx		proto __cdecl :PTEDIT

TINFO		struct		; aligned TEDIT
base		LPSTR ?
flags		UINT ?
xpos		UINT ?
ypos		UINT ?
cols		UINT ?
bcol		UINT ?
xoffs		UINT ?
boffs		UINT ?
bcount		UINT ?
clip_so		UINT ?
clip_eo		UINT ?
clrc		UINT ?
clip_sl		UINT ?		; Clipboard start line
clip_el		UINT ?		; Clipboard end line
rows		UINT ?		; number of lines on screen
loffs		UINT ?		; line offset in buffer
yoffs		UINT ?		; y offset on screen
lptr		LPSTR ?		; pointer to current line
flptr		LPSTR ?		; pointer to current line (in file)
flbcnt		UINT ?		; byte count in line (in file)
stylec		UINT ?		; style attrib/char
lcount		UINT ?		; line count in file
curline		UINT ?		; last line accessed
file		LPSTR ?		; file name
time		UINT ?		; file time
size		UINT ?		; file size
next		PTEDIT ?	; next file
prev		PTEDIT ?	; prev file
tabsize		UINT ?		; tab size
style		LPSTR ?
dobj		DOBJ <>
crc		UINT ?		; screen data CRC value for minimal output
bsize		UINT ?		; buffer size (dynamic)
TINFO		ends
PTINFO		typedef ptr TINFO

externdef	tinfo:PTINFO
externdef	tiflags:UINT
externdef	titabsize:UINT
externdef	_consolecp:UINT

tistate		proto __cdecl :PTINFO
tialigny	proto __cdecl :PTINFO, :UINT
tiputs		proto __cdecl :PTINFO
tishow		proto __cdecl :PTINFO
tihide		proto __cdecl :PTINFO
tigetfile	proto __cdecl :PTINFO
tiflush		proto __cdecl :PTINFO
titogglefile	proto __cdecl :PTINFO, :PTINFO

SaveChanges	proto __cdecl :LPSTR
tdlgopen	proto __cdecl
toption		proto __cdecl
topen		proto __cdecl :LPSTR, :UINT
tclose		proto __cdecl
tcloseall	proto __cdecl
tmodal		proto __cdecl
tedit		proto __cdecl :LPSTR, :DWORD
topensession	proto __cdecl
topenedi	proto __cdecl :LPSTR
tloadfiles	proto __cdecl
tsavefiles	proto __cdecl
TIShiftFx	proto __cdecl :UINT
TIAltFx		proto __cdecl :UINT
tinexterror	proto __cdecl
tipreviouserror proto __cdecl
titransfer	proto __cdecl

; Unicode box charcters -- https://www.compart.com/en/unicode/U+2500

define U_LIGHT_HORIZONTAL		0x2500	; -
define U_LIGHT_VERTICAL			0x2502	; |
define U_LIGHT_DOWN_AND_RIGHT		0x250C	; Single corners
define U_LIGHT_DOWN_AND_LEFT		0x2510	;
define U_LIGHT_UP_AND_RIGHT		0x2514	;
define U_LIGHT_UP_AND_LEFT		0x2518	;
define U_LIGHT_VERTICAL_AND_RIGHT	0x251C	; Insert single corners
define U_LIGHT_VERTICAL_AND_LEFT	0x2524	;
define U_LIGHT_DOWN_AND_HORIZONTAL	0x252C	;
define U_LIGHT_UP_AND_HORIZONTAL	0x2534	;
define U_DOUBLE_HORIZONTAL		0x2550	; =
define U_DOUBLE_VERTICAL		0x2551	; ||
define U_DOUBLE_DOWN_AND_RIGHT		0x2554	; Double corners
define U_DOUBLE_DOWN_AND_LEFT		0x2557	;
define U_DOUBLE_UP_AND_RIGHT		0x255A	;
define U_DOUBLE_UP_AND_LEFT		0x255D	;
define U_LIGHT_ARC_DOWN_AND_RIGHT	0x256D	; Single rounded corners
define U_LIGHT_ARC_DOWN_AND_LEFT	0x256E	;
define U_LIGHT_ARC_UP_AND_LEFT		0x256F	;
define U_LIGHT_ARC_UP_AND_RIGHT		0x2570	;
define U_UPPER_HALF_BLOCK		0x2580	; Push Button
define U_LOWER_HALF_BLOCK		0x2584
define U_BLACK_RIGHT_POINTER		0x25BA	; >
define U_BLACK_LEFT_POINTER		0x25C4	; <
define U_LIGHT_SHADE			0x2591
define U_FULL_BLOCK			0x2588
define U_MIDDLE_DOT			0x00B7	; Text input
define U_BULLET_OPERATOR		0x2219	; (*) Radio
define U_UP_TRIANGLE			0x25B2
define U_DOWN_TRIANGLE			0x25BC
define U_RIGHT_TRIANGLE			0x25BA
define U_LEFT_TRIANGLE			0x25C4
define U_DOWN_ARROW			0x2193
define U_RIGHT_DOUBLE_QUOTE		0x00BB
define U_LEFT_DOUBLE_QUOTE		0x00AB

include idd.inc

endif
.pragma list(pop)
