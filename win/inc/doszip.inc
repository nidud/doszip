; DOSZIP.INC--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT
;
ifndef __DOSZIP_INC
define __DOSZIP_INC

include direct.inc
include wsub.inc
include filter.inc
include conio.inc
include time.inc
include helpid.inc

DOSZIP_VERSION	equ 0x0379
DOSZIP_MINVERS	equ 0x0349
DOSZIP_VSTRING	equ <"3.79">
ifdef _WIN64
DOSZIP_VSTRPRE	equ <" Win64">
else
DOSZIP_VSTRPRE	equ <" Win32">
endif
MAXHISTORY	equ 32
MAXDOSKEYS	equ 64

DOSZIP_INIFILE	equ <"dz.ini">	; config file
DOSZIP_TXTFILE	equ <"dz.txt">	; readme file

externdef	DZTitle:LPSTR
externdef	DZ_INIFILE:char_t

_C_PANELID	equ 0001h	; config.c_cflag
_C_HORIZONTAL	equ 0002h
_C_ESCUSERSCR	equ 0004h
_C_EGALINE	equ 0008h
_C_SELECTDIR	equ 0010h
_C_INSMOVDN	equ 0020h
_C_CDCLRDONLY	equ 0040h
_C_AUTOSAVE	equ 0080h
_C_SORTDIR	equ 0100h
_C_WIDEVIEW	equ 0200h
_C_DELHISTORY	equ 0400h
_C_DELTEMP	equ 0800h
_C_MENUSLINE	equ 1000h
_C_STATUSLINE	equ 2000h
_C_COMMANDLINE	equ 4000h
_C_CONFCOPY	equ 00010000h
_C_CONFMOVE	equ 00020000h
_C_CONFDELETE	equ 00040000h
_C_CONFDELSUB	equ 00080000h
_C_CONFSYSTEM	equ 00100000h
_C_CONFRDONLY	equ 00200000h
_C_CONFEXIT	equ 00400000h
_C_ZINCSUBDIR	equ 00800000h
_C_VISUALUPDATE equ 01000000h
_C_PANELEDIT	equ 02000000h
_C_DEFAULT	equ 017F40A4h

_MKL_APPEND	equ 0001h	; add to list or create new
_MKL_UNIX	equ 0002h	; convert to unix
_MKL_EXCL_CD	equ 0004h	; use local directory
_MKL_EXCL_DRV	equ 0008h	; use drive in directory
_MKL_EXCL_FILE	equ 0010h	; use file name in directory
_MKL_MASK	equ 0020h	; add mask to directory\[*.*]
_MKL_MACRO	equ 0100h	; use output macro

.enum compare_options {

    ; Compare Panels (Ctrl-C) and Directories (Shift-F5)

    compare_name	= 0x01, ; Compare File names
    compare_time	= 0x02, ; Compare Last modification time
    compare_size	= 0x04, ; Compare File Size
    compare_attrib	= 0x08, ; Compare File Attributes

    ; Compare Directories

    compare_create	= 0x10, ; Compare File creation time
    compare_access	= 0x20, ; Compare Last access time
    compare_data	= 0x40, ; Compare File content
    compare_count	= 7,	; Dialog options
    compare_default	= 0x0F,

    ; Extended bit flags

    compare_equal	= 0x80, ; Find equal/differ
    compare_subdir	= 0x100,; Scan subdirectories
    }

CompareOptions	proto :ptr compare_options

MKLST		STRUC
flag		dd ?
offspath	dd ?		; length of local directory
offs		dd ?		; search offset from findfile
handle		dd ?
count		dd ?		; total file count in list
MKLST		ENDS

MSOBJ		STRUC
rc		TRECT <>
cmd		DPROC ?
MSOBJ		ENDS
PMSOBJ		typedef ptr MSOBJ

SBLK		STRUC
base		dd ?
size		dd ?
line		dd ?
offs		dd ?
file		db 4 dup(?)
SBLK		ENDS

define INFOSIZE	 38
define BLOCKSIZE (SBLK+INFOSIZE)

_XY_DRVINFO	equ 8
_XY_CONFIG	equ 7
_XY_MINISTATUS	equ 6
_XY_NEWDISK	equ 5
_XY_MOVEUP	equ 4
_XY_MOVEDOWN	equ 3
_XY_FILE	equ 2
_XY_INSIDE	equ 1
_XY_OUTSIDE	equ 0

wsmaxfba	equ <config.c_apath.maxfb>
wsmaxfbb	equ <config.c_bpath.maxfb>
flaga		equ <config.c_apath.flag>
flagb		equ <config.c_bpath.flag>

XCEL		STRUC
flag		dw ?		; DOBJ.dl_flag
cols		db ?		; number of files in one line
rows		db ?		; number of lines in panel
rc		TRECT <>	; the current position of cell
wp		PCHAR_INFO ?	; DOBJ.dl_wp
cpos		TRECT <>	; position of first cell in panel
XCEL		ENDS
PXCEL		typedef ptr XCEL

CALLBACK(FPUT, :PFBLK, :PCHAR_INFO, :UINT)

PANEL		STRUC
wsub		PWSUB ?
fcb_count	dd ?
cel_count	dd ?
fcb_index	dd ?
cel_index	dd ?
xl		PXCEL ?
dialog		PDOBJ ?
putfcb		FPUT ?
PANEL		ENDS
PPANEL		typedef ptr PANEL

S_CONFIG	STRUC		; Configuration file:	DZ.CFG
c_version	dd ?		; hex: 0.1.3.8 --> 0138h
c_cflag		dd ?
c_console	dd ?		; -- console.inc
c_fsflag	dd ?		; -- iost.inc
c_tvflag	dd ?		; -- tview.asm
c_teflag	dd ?		; -- tedit.asm
c_titabsize	dd ?		; -- tedit.asm Tab Size
c_ffflag	dd ?		; -- ff.asm
c_comprlevel	dd ?
c_panelsize	dd ?		; Alt-Up/Down
c_fcb_indexa	dd ?
c_cel_indexa	dd ?
c_fcb_indexb	dd ?
c_cel_indexb	dd ?
c_apath		WSUB <?>
c_bpath		WSUB <?>
c_filter	FILTER <?>
c_color		COLOR <?>
c_list		MKLST <?>
S_CONFIG	ENDS

DIRECTORY	STRUC
path		LPSTR ?
flag		dd ?
fcb_index	dd ?
cel_index	dd ?
DIRECTORY	ENDS
PDIRECTORY	typedef ptr DIRECTORY

HISTORY		STRUC
directory	DIRECTORY MAXHISTORY dup(<>)
doskey		LPSTR MAXDOSKEYS dup(?)
selectmask	char_t 32 dup(?)
HISTORY		ENDS
PHISTORY	typedef ptr HISTORY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

externdef cp_emaxfb:		char_t
externdef cp_ziplst:		char_t
externdef cp_selectmask:	char_t

externdef findfilemask:		char_t
externdef findfilepath:		char_t
externdef filelist_bat:		char_t
externdef format_lst:		char_t
externdef searchstring:		char_t
externdef replacestring:	char_t
externdef default_arc:		char_t
externdef default_zip:		char_t
externdef com_base:		char_t

externdef cpanel:		PPANEL
externdef panela:		PPANEL
externdef panelb:		PPANEL
externdef cflag:		DWORD
externdef console:		DWORD
externdef fsflag:		DWORD
externdef tvflag:		DWORD
externdef teflag:		DWORD
externdef titabsize:		DWORD
externdef ffflag:		DWORD
externdef compresslevel:	DWORD

externdef history:		PHISTORY
externdef comspec:		LPSTR	; %COMSPEC%
externdef mainswitch:		DWORD
externdef dzexitcode:		DWORD
externdef numfblock:		DWORD	; number of file pointers allocated
externdef global_key:		DWORD

externdef prect_a:		XCEL
externdef prect_b:		XCEL
externdef spanela:		PANEL
externdef spanelb:		PANEL
externdef path_a:		WSUB
externdef path_b:		WSUB
externdef opfilter:		FILTER
externdef config:		S_CONFIG
externdef mklist:		MKLST
externdef com_info:		TEDIT
externdef MOBJ_Statusline:	MSOBJ

externdef DLG_Commandline:	PDOBJ
externdef DLG_Commandline:	PDOBJ
externdef com_wsub:		PWSUB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ifdef __CI__
CodeInfo		PROTO
endif
ifdef __BMP__
CaptureScreen		PROTO
endif

warcread		PROTO :PWSUB
warctest		PROTO :PFBLK, :SINT
warcadd			PROTO :LPSTR, :PWSUB, :PFBLK
warccopy		PROTO :PWSUB, :PFBLK, :LPSTR, :SINT
warcview		PROTO :PWSUB, :PFBLK
warcdelete		PROTO :PWSUB, :PFBLK

unzip_to_temp		proto :PFBLK, :LPSTR
TVGetCurrentFile	proto :LPSTR
loadiniproc		proto :LPSTR, :LPSTR, :int_t
hedit			proto :LPSTR, :DWORD
continuesearch		proto :ptr
putscreenb		proto :int_t, :int_t, :ptr
SaveChanges		proto :LPSTR

setconfirmflag		PROTO
config_read		PROTO
config_save		PROTO
config_open		PROTO

historyread		PROTO
historywrite		PROTO
historyremove		PROTO
historysave		PROTO
historytocpanel		PROTO
doskeytocommand		PROTO
doskeysave		PROTO

LPPANEL TYPEDEF PTR S_PANEL

fblk_select		PROTO :PFBLK
fblk_invert		PROTO :PFBLK
prect_hide		PROTO :PPANEL
prect_open_ab		PROTO
pcell_show		PROTO :PPANEL
pcell_update		PROTO :PPANEL
pcell_setxy		PROTO :PPANEL, :UINT, :UINT

cpanel_state		PROTO
cpanel_findfirst	PROTO
cpanel_gettarget	PROTO
cpanel_setpath		PROTO :LPSTR
cpanel_deselect		PROTO :PFBLK

panel_state		PROTO fastcall :PPANEL
panel_close		PROTO :PPANEL
panel_hide		PROTO :PPANEL
panel_show		PROTO fastcall :PPANEL
panel_setactive		PROTO :PPANEL
panel_curobj		PROTO fastcall :PPANEL
panel_findnext		PROTO fastcall :PPANEL
panel_openmsg		PROTO :PPANEL
panel_read		PROTO :PPANEL
panel_reread		PROTO :PPANEL
panel_redraw		PROTO :PPANEL
panel_toggle		PROTO :PPANEL
panel_update		PROTO :PPANEL
panel_xormini		PROTO :PPANEL
panel_xorinfo		PROTO :PPANEL
panel_setid		PROTO :PPANEL, :UINT
panel_putitem		PROTO :PPANEL, :UINT
panel_xycmd		PROTO :PPANEL, :UINT, :UINT
panel_sethdd		PROTO :PPANEL, :UINT
panel_event		PROTO :PPANEL, :UINT
panel_stateab		PROTO
panel_open_ab		PROTO
panel_getb		PROTO
panel_toggleact		PROTO

redraw_panel		PROTO :PPANEL
redraw_panels		PROTO
reread_panels		PROTO

mklistidd		proto
mklistadd		proto :LPSTR
mkziplst		proto
mkziplst_open		proto :LPSTR

tools_idd		PROTO :SINT, :LPSTR, :LPSTR
statusline_xy		PROTO :SINT, :SINT, :SINT, :PMSOBJ
menus_getevent		proto

cominit			PROTO :PWSUB
cominitline		PROTO
comhide			PROTO
comshow			PROTO
clrcmdl			PROTO
comevent		PROTO :DWORD
command			PROTO :string_t

FindFile		PROTO :string_t
cmfilter_load		PROTO

cm_loadfblk		PROTO
cmfilter_load		PROTO
doszip_show		PROTO
doszip_hide		PROTO

apiidle			PROTO
apimode			PROTO
apiega			PROTO
apiopen			PROTO
apihide			PROTO
apishow			PROTO
apiclose		PROTO
apiupdate		PROTO

cmalong			PROTO
cmadetail		PROTO
cmahidden		PROTO
cmamini			PROTO
cmavolinfo		PROTO
cmaname			PROTO
cmatype			PROTO
cmadate			PROTO
cmasize			PROTO
cmanosort		PROTO
cmatoggle		PROTO
cmafilter		PROTO
cmasubinfo		PROTO
cmahistory		PROTO
cmaupdate		PROTO
cmachdrv		PROTO

cmrename		PROTO
cmview			PROTO
cmedit			PROTO
cmhexedit		PROTO
cmtmodal		PROTO
cmcopy			PROTO
cmmove			PROTO
cmmkdir			PROTO
cmdelete		PROTO
cmattrib		PROTO
cmcompress		PROTO
cmdecompress		PROTO
cmsearch		PROTO
cmcompsub		PROTO
cmhistory		PROTO
cmexit			PROTO

cmselect		PROTO
cmdeselect		PROTO
cminvert		PROTO
cmquicksearch		PROTO	; Ctrl-Q
cmcompare		PROTO

cmtoggleon		PROTO
cmtogglehz		PROTO
cmtogglesz		PROTO
cmegaline		PROTO
cmswap			PROTO
cmconfirm		PROTO
cmpanel			PROTO
cmcompression		PROTO
teoption		PROTO
cmscreen		PROTO
cmsystem		PROTO
cmoptions		PROTO

cmhelp			PROTO
cmabout			PROTO

cmblong			PROTO
cmbdetail		PROTO
cmbhidden		PROTO
cmbmini			PROTO
cmbvolinfo		PROTO
cmbname			PROTO
cmbtype			PROTO
cmbdate			PROTO
cmbsize			PROTO
cmbnosort		PROTO
cmbtoggle		PROTO
cmbfilter		PROTO
cmbsubinfo		PROTO
cmbhistory		PROTO
cmbupdate		PROTO
cmbchdrv		PROTO

cmawideview		PROTO
cmbwideview		PROTO
cmcwideview		PROTO

cmcopycell		PROTO
cmlastmenu		PROTO
cmtool0			PROTO
cmtool1			PROTO
cmtool2			PROTO
cmtool3			PROTO
cmtool4			PROTO
cmtool5			PROTO
cmtool6			PROTO
cmtool7			PROTO
cmtool8			PROTO
cmtool9			PROTO
cmpath0			PROTO
cmpath1			PROTO
cmpath2			PROTO
cmpath3			PROTO
cmpath4			PROTO
cmpath5			PROTO
cmpath6			PROTO
cmpath7			PROTO
cmcname			PROTO
cmctype			PROTO
cmcdate			PROTO
cmcsize			PROTO
cmuserscreen		PROTO
cmchidden		PROTO
cmclong			PROTO
cmcmini			PROTO
cmcupdate		PROTO
cmcdetail		PROTO
cmcnosort		PROTO
cmvolinfo		PROTO
cmxormenubar		PROTO
cmxorkeybar		PROTO
cmxorcmdline		PROTO
cmupdir			PROTO
cmsubdir		PROTO
cmclrcmdl		PROTO
cmpsizeup		PROTO
cmpsizedn		PROTO
cmpathleft		PROTO	; Alt-Left  - Previous Directory
cmpathright		PROTO	; Alt-Right - Next Directory
cmdoskeyup		PROTO	; Alt-Up    - Previous Command
cmdoskeydown		PROTO	; Alt-Down  - Next Command
cmsavesetup		PROTO	; Shift-F10
cmsubsize		PROTO	; F3
cmsubinfo		PROTO	; Menus
cmquit			PROTO	; Alt-X
clrcmdl			PROTO	; Esc
cmfilter		PROTO
cmmklist		PROTO	; Alt-L
cmloadpath		PROTO	; Alt-P
cmcalendar		PROTO	; Ctrl-G
cmmkzip			PROTO	; Shift-F7
IFDEF DEBUG
cmdebug			PROTO	; Shift-F1
ENDIF
cmsysteminfo		PROTO	; Alt-M
cmhomedir		PROTO
cmwindowlist		PROTO
cmenviron		PROTO	; Shift-F6
cmscreensize		PROTO
cmcompoption		proto	; Alt-O

cmsearchidd		proto :uint_t

conssetl		PROTO :COORD
consuser		PROTO
editattrib		PROTO

externdef   console_cu:CURSOR	; Init cursor (set on exit)

define _COPY_SELECTED	0x01	; copy selected files
define _COPY_IARCHIVE	0x02	; source is archive
define _COPY_OARCHIVE	0x04	; target is archive
define _COPY_IEXTFILE	0x08	; source is .??? archive -- 7ZA.EXE
define _COPY_IZIPFILE	0x10	; source is .ZIP archive
define _COPY_OZIPFILE	0x20	; target is .ZIP archive
define _COPY_OEXTFILE	0x40	; target is .??? archive -- 7ZA.EXE
define _COPY_RECURSIV	0x80	; recursive error

externdef		copy_jump:dword
externdef		copy_flag:byte
externdef		copy_fast:byte
externdef		_diskflag:UINT
externdef		envtemp:LPSTR
externdef		_pgmpath:string_t

init_copy		proto :PFBLK, :UINT
copyfile		proto :qword, :UINT, :UINT
fp_copyfile		proto :LPSTR, :PWIN32_FIND_DATA
fp_copydirectory	proto :LPSTR
cpyevent_filter		proto
UpdateWindowSize	proto :COORD
readword		proto :LPSTR

recursive		proto __cdecl :LPSTR, :LPSTR, :LPSTR

__xtoi			proto __cdecl :string_t
__xtoi64		proto __cdecl :string_t
__xtol			proto __cdecl :string_t

mkbstring		proto __cdecl :LPSTR, :QWORD
searchp			proto __cdecl :LPSTR, :LPSTR
expenviron		proto __cdecl :LPSTR
SaveEnvironment		proto __cdecl :LPSTR
ReadEnvironment		proto __cdecl :LPSTR
CreateBatch		proto __cdecl :LPSTR, :SINT, :SINT

GetEnvironmentTEMP	proto __cdecl
GetEnvironmentPATH	proto __cdecl

endif
