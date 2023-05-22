.pragma list(push, 0)
ifndef __STDLIB_INC
define __STDLIB_INC
include libc.inc

ifndef _ERRNO_T_DEFINED
define _ERRNO_T_DEFINED
errno_t typedef sdword
endif

ifndef _INTPTR_T_DEFINED
define _INTPTR_T_DEFINED
ifdef _WIN64
intptr_t typedef sqword
else
intptr_t typedef sdword
endif
endif

ifndef _UINTPTR_T_DEFINED
define _UINTPTR_T_DEFINED
ifdef _WIN64
uintptr_t typedef qword
else
uintptr_t typedef dword
endif
endif

ifndef __STDC_WANT_SECURE_LIB__
define __STDC_WANT_SECURE_LIB__ 1
endif

include limits.inc

ifndef Q64
Q64		UNION
q		dq ?
STRUCT
 q_l		dd ?
 q_h		dd ?
ENDS
Q64		ENDS
endif

ifndef _ONEXIT_T_DEFINED
define _ONEXIT_T_DEFINED

ifndef _M_CEE_PURE
CALLBACKC(_onexit_t)
else
CALLBACKC(_onexit_t)
_onexit_m_t typedef _onexit_t
endif

ifdef _M_CEE_MIXED
CALLBACKC(_onexit_m_t)
endif

if not __STDC__
onexit_t typedef _onexit_t
endif

endif

ifndef _DIV_T_DEFINED
define _DIV_T_DEFINED
_div_t		struct
quot		int_t ?
rem		int_t ?
_div_t		ends
_ldiv_t		struct
quot		long_t ?
rem		long_t ?
_ldiv_t		ends
_lldiv_t	struct
quot		int64_t ?
rem		int64_t ?
_lldiv_t	ends
endif

ifndef _CRT_DOUBLE_DEC
define _CRT_DOUBLE_DEC

ifndef _LDSUPPORT
.pragma pack(push, 4)
_LDOUBLE struct
    ld	db 10 dup(?)
_LDOUBLE ends
.pragma pack(pop)
_PTR_LD macro x
	exitm<x.ld>
	endm
else
_LDOUBLE typedef real10
_PTR_LD macro x
	exitm<x>
	endm
endif

_CRT_DOUBLE struct
    x	real8 ?
_CRT_DOUBLE ends
_CRT_FLOAT struct
    f	real4 ?
_CRT_FLOAT ends
_LONGDOUBLE struct
    x	real10 ?
_LONGDOUBLE ends

.pragma pack(push,4)
_LDBL12 struct
    ld12 db 12 dup(?)
_LDBL12 ends
.pragma pack(pop)

endif ;; _CRT_DOUBLE_DEC

RAND_MAX equ 0x7fff

_MAX_PATH		equ 260
_MAX_DRIVE		equ 3
_MAX_DIR		equ 256
_MAX_FNAME		equ 256
_MAX_EXT		equ 256

_OUT_TO_DEFAULT		equ 0
_OUT_TO_STDERR		equ 1
_OUT_TO_MSGBOX		equ 2
_REPORT_ERRMODE		equ 3

_WRITE_ABORT_MSG	equ 0x1 ;; debug only, has no effect in release
_CALL_REPORTFAULT	equ 0x2

;;
;; Sizes for buffers used by the getenv/putenv family of functions.
;;
_MAX_ENV		equ 32767

ifndef _CRT_ERRNO_DEFINED
define _CRT_ERRNO_DEFINED
externdef	errno:errno_t
endif

__doserrno	proto __cdecl
_set_doserrno	proto __cdecl :ulong_t
_get_doserrno	proto __cdecl :ptr ulong_t
__sys_errlist	proto __cdecl
externdef	_doserrno:errno_t
externdef	_sys_errlist:array_t
externdef	_sys_nerr:int_t
osmaperr	proto __cdecl
__sys_nerr	proto __cdecl
_dosmaperr	proto __cdecl :ulong_t

externdef	__argc:int_t
externdef	__argv:array_t
externdef	__wargv:warray_t

externdef	_environ:array_t
externdef	_wenviron:warray_t
externdef	_pgmptr:string_t
externdef	_pgmpath:string_t
externdef	_wpgmptr:wstring_t

_get_pgmptr	proto __cdecl :array_t
_get_wpgmptr	proto __cdecl :warray_t

externdef	_fmode:int_t

_set_fmode	proto __cdecl :int_t
_get_fmode	proto __cdecl :ptr int_t

ifndef _countof
_countof	equ <lengthof>
endif

ifndef _CRT_TERMINATE_DEFINED
define _CRT_TERMINATE_DEFINED
exit		proto __cdecl :int_t
_exit		proto __cdecl :int_t
abort		proto __cdecl
endif

_set_abort_behavior proto __cdecl :int_t, :int_t

abs		proto __cdecl :int_t
labs		proto __cdecl :long_t
llabs		proto __cdecl :int64_t
_abs64		proto __cdecl :int64_t

ifdef _M_CEE
_atexit_m_appdomain proto __cdecl :ptr_t
ifdef _M_CEE_MIXED
_atexit_m	proto __cdecl :ptr_t
else
_atexit_m macro _Function
	exitm<_atexit_m_appdomain(_Function)>
	endm
endif
endif ; _M_CEE

ifdef _M_CEE_PURE
_atexit_m macro _Function
	exitm<_atexit_m_appdomain(_Function)>
	endm
else
atexit		proto __cdecl :ptr
endif

atof		proto __cdecl :string_t
atoi		proto __cdecl :string_t
atol		proto __cdecl :string_t
atoll		proto __cdecl :string_t

ifndef _CRT_ALGO_DEFINED
define _CRT_ALGO_DEFINED
CALLBACKC(LPQSORTCMD, :ptr, :ptr)
if __STDC_WANT_SECURE_LIB__
CALLBACKC(_PtFuncCompare_s, :ptr, :ptr, :ptr)
bsearch_s	proto __cdecl :ptr, :ptr, :size_t, :size_t, :_PtFuncCompare_s, :ptr
endif
CALLBACKC(_PtFuncCompare, :ptr, :ptr)
bsearch		proto __cdecl :ptr, :ptr, :size_t, :size_t, :_PtFuncCompare
if __STDC_WANT_SECURE_LIB__
qsort_s		proto __cdecl :ptr, :size_t, :size_t, :LPQSORTCMD, :ptr
endif
qsort		proto __cdecl :ptr, :size_t, :size_t, :LPQSORTCMD
endif

getenv		proto __cdecl :string_t
if __STDC_WANT_SECURE_LIB__
getenv_s	proto __cdecl :ptr size_t, :string_t, :size_t, :string_t
endif
_dupenv_s	proto __cdecl :array_t, :ptr size_t, :string_t

_itoa_s		proto __cdecl :int_t, :string_t, :size_t, :int_t
_i64toa_s	proto __cdecl :int64_t, :string_t, :size_t, :int_t
_i64toa		proto __cdecl :int64_t, :string_t, :int_t
_ui64toa_s	proto __cdecl :uint64_t, :string_t, :size_t, :int_t
_ui64toa	proto __cdecl :uint64_t, :string_t, :int_t
_atoi64		proto __cdecl :string_t
_strtoi64	proto __cdecl :string_t, :array_t, :int_t
_strtoui64	proto __cdecl :string_t, :array_t, :int_t
ldiv		proto __cdecl :long_t, :long_t
lldiv		proto __cdecl :int64_t, :int64_t

_ltoa_s		proto __cdecl :long_t, :string_t, :size_t, :int_t

mblen		proto __cdecl :string_t, :size_t
_mbstrlen	proto __cdecl :string_t
_mbstrnlen	proto __cdecl :string_t, :size_t

mbtowc		proto __cdecl :wstring_t, :string_t, :size_t
mbstowcs	proto __cdecl :wstring_t, :string_t, :size_t

rand		proto __cdecl
ifdef _CRT_RAND_S
rand_s		proto __cdecl :ptr uint_t
endif

_set_error_mode proto __cdecl :int_t

srand		proto __cdecl :uint_t
strtod		proto __cdecl :string_t, :array_t
strtol		proto __cdecl :string_t, :array_t, :int_t
strtoll		proto __cdecl :string_t, :array_t, :int_t
strtoul		proto __cdecl :string_t, :array_t, :int_t
strtoull	proto __cdecl :string_t, :array_t, :int_t
strtold		proto __cdecl :string_t, :array_t
strtof		proto __cdecl :string_t, :array_t

ifndef _MSVCRT
_strtold	proto __cdecl :string_t, :string_t
_strtoq		proto __cdecl :ptr, :string_t, :string_t
strtoqd		proto __cdecl :string_t, :string_t
endif

ifndef _CRT_SYSTEM_DEFINED
define _CRT_SYSTEM_DEFINED
system		proto __cdecl :string_t
endif

_ultoa_s	proto __cdecl :ulong_t, :string_t, :size_t, :int_t
wctomb		proto __cdecl :string_t, :wchar_t

ifndef _CRT_ALLOCATION_DEFINED
define _CRT_ALLOCATION_DEFINED
calloc		proto __cdecl :size_t, :size_t
free		proto __cdecl :ptr
malloc		proto __cdecl :size_t
realloc		proto __cdecl :ptr, :size_t
_recalloc	proto __cdecl :ptr, :size_t, :size_t
_aligned_free	proto __cdecl :ptr
_aligned_malloc proto __cdecl :size_t, :size_t
_aligned_offset_malloc proto __cdecl :size_t, :size_t, :size_t
_aligned_realloc proto __cdecl :ptr, :size_t, :size_t
_aligned_recalloc proto __cdecl :ptr, :size_t, :size_t, :size_t
_aligned_offset_realloc proto __cdecl :ptr, :size_t, :size_t, :size_t
_aligned_offset_recalloc proto __cdecl :ptr, :size_t, :size_t, :size_t, :size_t
_aligned_msize	proto __cdecl :ptr, :size_t, :size_t
endif

ifndef _WSTDLIB_DEFINED
define _WSTDLIB_DEFINED

ifndef _WCHAR_T_DEFINED
define _WCHAR_T_DEFINED
wchar_t		typedef word
endif

ifndef _WCTYPE_T_DEFINED
define _WCTYPE_T_DEFINED
wint_t		typedef wchar_t
wctype_t	typedef wchar_t
endif

_itow		proto __cdecl :int_t, :wstring_t, :int_t
_itow_s		proto __cdecl :int_t, :wstring_t, :size_t, :int_t
_ltow		proto __cdecl :int_t, :wstring_t, :int_t
_ltow_s		proto __cdecl :long_t, :wstring_t, :size_t,:int_t
_ultow		proto __cdecl :ulong_t, :wstring_t, :int_t
_ultow_s	proto __cdecl :ulong_t, :wstring_t, :size_t, :int_t
wcstod		proto __cdecl :wstring_t, :wstring_t
wcstol		proto __cdecl :wstring_t, :wstring_t, :int_t
wcstoll		proto __cdecl :wstring_t, :wstring_t, :int_t
wcstoul		proto __cdecl :wstring_t, :wstring_t, :int_t
wcstoull	proto __cdecl :wstring_t, :wstring_t, :int_t
wcstold		proto __cdecl :wstring_t, :wstring_t
wcstof		proto __cdecl :wstring_t, :wstring_t

_wgetenv	proto __cdecl :wstring_t

ifndef _CRT_WSYSTEM_DEFINED
define _CRT_WSYSTEM_DEFINED
_wsystem	proto __cdecl :wstring_t
endif

_wtof		proto __cdecl :wstring_t
_wtoi		proto __cdecl :wstring_t
_wtol		proto __cdecl :wstring_t
_wtoll		proto __cdecl :wstring_t

_i64tow		proto __cdecl :int64_t, :wstring_t, :int_t
_ui64tow	proto __cdecl :uint64_t, :wstring_t, :int_t
_wtoi64		proto __cdecl :wstring_t
_wcstoi64	proto __cdecl :wstring_t, :warray_t, :int_t
_wcstoui64	proto __cdecl :wstring_t, :warray_t, :int_t

endif ; _WSTDLIB_DEFINED

_CVTBUFSIZE	equ (309+40) ;; # of digits in max. dp value + slop

_fullpath	proto __cdecl :string_t, :string_t, :size_t

_ecvt		proto __cdecl :real8, :int_t, :ptr int_t, :ptr int_t
_fcvt		proto __cdecl :real8, :int_t, :ptr int_t, :ptr int_t
_gcvt		proto __cdecl :real8, :int_t, :string_t

_atodbl		proto __cdecl :ptr _CRT_DOUBLE, :string_t
_atoldbl	proto __cdecl :ptr _LDOUBLE, :string_t
_atoflt		proto __cdecl :ptr _CRT_FLOAT, :string_t
_makepath	proto __cdecl :string_t, :string_t, :string_t, :string_t, :string_t

ifdef _M_CEE_PURE
_onexit macro _Function
	exitm<_onexit_m_appdomain(_Function)>
	endm
else
_onexit		proto __cdecl :ptr
endif

ifndef _CRT_PERROR_DEFINED
define _CRT_PERROR_DEFINED
perror		proto __cdecl :string_t
endif

_putenv		proto __cdecl :string_t
_splitpath	proto __cdecl :string_t, :string_t, :string_t, :string_t, :string_t
_swab		proto __cdecl :string_t, :string_t, :int_t

ifndef _WSTDLIBP_DEFINED
define _WSTDLIBP_DEFINED

_wfullpath	proto __cdecl :wstring_t, :wstring_t, :size_t
ifndef _CRT_WPERROR_DEFINED
define _CRT_WPERROR_DEFINED
_wperror	proto __cdecl :wstring_t
endif
_wputenv	proto __cdecl :wstring_t

_wsplitpath	proto __cdecl :wstring_t, :wstring_t, :wstring_t, :wstring_t, :wstring_t

endif ;; _WSTDLIBP_DEFINED

;; The Win32 API SetErrorMode, Beep and Sleep should be used instead.
_seterrormode	proto __cdecl :int_t
_beep		proto __cdecl :ulong_t, :ulong_t
_sleep		proto __cdecl :ulong_t

ecvt		proto __cdecl :real8, :int_t, :ptr int_t, :ptr int_t
fcvt		proto __cdecl :real8, :int_t, :ptr int_t, :ptr int_t
gcvt		proto __cdecl :real8, :int_t, :string_t
itoa		proto __cdecl :int_t, :string_t, :int_t
ltoa		proto __cdecl :long_t, :string_t, :int_t

_itoa		proto __cdecl :int_t, :string_t, :int_t
_ltoa		proto __cdecl :long_t, :string_t, :int_t
_ultoa		proto __cdecl :ulong_t, :string_t, :int_t
_i64toa		proto __cdecl :int64_t, :string_t, :int_t
_ui64toa	proto __cdecl :uint64_t, :string_t, :int_t

putenv		proto __cdecl :string_t

swab		proto __cdecl :string_t, :string_t, :int_t
ultoa		proto __cdecl :ulong_t, :string_t, :int_t
onexit		proto __cdecl :onexit_t

;;---

__getmainargs	proto __cdecl :ptr, :ptr, :ptr, :ptr, :ptr
__wgetmainargs	proto __cdecl :ptr, :ptr, :ptr, :ptr, :ptr
__iob_func	proto __cdecl

if not defined(_MSVCRT) or defined(_CRTBLD)
_atoi128	proto __cdecl :string_t, :ptr int128_t
_xtoa		proto __cdecl :qword, :string_t, :int_t, :int_t
_xtow		proto __cdecl :qword, :wstring_t, :int_t, :int_t
_xtoa_s		proto __cdecl :qword, :string_t, :size_t, :uint_t, :int_t
_xtow_s		proto __cdecl :qword, :wstring_t, :size_t, :uint_t, :int_t
endif

define _EXEC_BAT 1
define _EXEC_COM 2
define _EXEC_EXE 3
define _EXEC_CMD 4

externdef	_diskflag:UINT
externdef	envtemp:LPSTR

__isexec	proto __cdecl :string_t
__wsetenvp	proto __cdecl :wstring_t
__xtoi		proto __cdecl :string_t
__xtoi64	proto __cdecl :string_t
__xtol		proto __cdecl :string_t

__allocwpath	proto __cdecl :LPSTR
recursive	proto __cdecl :LPSTR, :LPSTR, :LPSTR

mkbstring	proto __cdecl :LPSTR, :QWORD
searchp		proto __cdecl :LPSTR, :LPSTR
expenviron	proto __cdecl :LPSTR
SaveEnvironment proto __cdecl :LPSTR
ReadEnvironment proto __cdecl :LPSTR
CreateBatch	proto __cdecl :LPSTR, :SINT, :SINT

GetEnvironmentTEMP proto __cdecl
GetEnvironmentPATH proto __cdecl

endif ; __STDLIB_INC
.pragma list(pop)

