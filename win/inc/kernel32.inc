; KERNEL32.INC--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;
ifndef __KERNEL32_INC
define __KERNEL32_INC

include libc.inc

_MAX_PATH   equ 260
_MAX_DRIVE  equ 3
_MAX_DIR    equ 256
_MAX_FNAME  equ 256
_MAX_EXT    equ 256
define      MAX_PATH 260

BOOL        typedef dword
PVOID       typedef ptr
PVOID64     typedef ptr
CHAR        typedef sbyte
LONG        typedef sdword
WCHAR       typedef word
PWCH        typedef ptr WCHAR
LPWCH       typedef ptr WCHAR
PWCHAR      typedef ptr WCHAR
PCWCH       typedef ptr WCHAR
LPCWCH      typedef ptr WCHAR
NWPSTR      typedef ptr WCHAR
LPWSTR      typedef ptr WCHAR
PWSTR       typedef ptr WCHAR
PZPWSTR     typedef ptr PWSTR
PCZPWSTR    typedef ptr PWSTR
LPUWSTR     typedef ptr WCHAR
PUWSTR      typedef ptr WCHAR
LPCWSTR     typedef ptr WCHAR
PCWSTR      typedef ptr WCHAR
PZPCWSTR    typedef ptr PCWSTR
LPCUWSTR    typedef ptr WCHAR
PCUWSTR     typedef ptr WCHAR
PZZWSTR     typedef ptr WCHAR
PCZZWSTR    typedef ptr WCHAR
PNZWCH      typedef ptr WCHAR
PCNZWCH     typedef ptr WCHAR
PCH         typedef ptr CHAR
LPCH        typedef ptr CHAR
PCCH        typedef ptr CHAR
PCHAR       typedef ptr CHAR
LPCCH       typedef ptr CHAR
NPSTR       typedef ptr CHAR
LPSTR       typedef ptr CHAR
PSTR        typedef ptr CHAR
PZPSTR      typedef ptr PSTR
PCZPSTR     typedef ptr PSTR
LPCSTR      typedef ptr CHAR
PCSTR       typedef ptr CHAR
PZPCSTR     typedef ptr PCSTR
PZZSTR      typedef ptr CHAR
PCZZSTR     typedef ptr CHAR
PNZCH       typedef ptr CHAR
PCNZCH      typedef ptr CHAR

SPHANDLE    typedef ptr HANDLE
LPHANDLE    typedef ptr HANDLE
HGLOBAL     typedef HANDLE
HLOCAL      typedef HANDLE
ATOM        typedef WORD
HANDLE      typedef ptr
PHANDLE     typedef ptr HANDLE
FCHAR       typedef BYTE
FSHORT      typedef WORD
FLONG       typedef DWORD

DECLARE_HANDLE macro name
    exitm<name typedef HANDLE>
    endm

ifndef _HRESULT_DEFINED
define _HRESULT_DEFINED
HRESULT typedef LONG
endif

PDWORD      typedef ptr DWORD
CCHAR       typedef CHAR
LCID        typedef DWORD
PLCID       typedef PDWORD
LANGID      typedef WORD

DECLARE_HANDLE(HKEY)
PHKEY typedef ptr HKEY
DECLARE_HANDLE(HMETAFILE)
DECLARE_HANDLE(HINSTANCE)
HMODULE typedef HINSTANCE
DECLARE_HANDLE(HRGN)
DECLARE_HANDLE(HRSRC)
DECLARE_HANDLE(HSPRITE)
DECLARE_HANDLE(HLSURF)
DECLARE_HANDLE(HSTR)
DECLARE_HANDLE(HTASK)
DECLARE_HANDLE(HWINSTA)
DECLARE_HANDLE(HKL)

COORD                   struct
X                       sword ?
Y                       sword ?
COORD                   ends
PCOORD                  typedef ptr COORD

SMALL_RECT              struct
Left                    sword ?
Top                     sword ?
Right                   sword ?
Bottom                  sword ?
SMALL_RECT              ends
PSMALL_RECT             typedef ptr SMALL_RECT

KEY_EVENT_RECORD        struct
bKeyDown                BOOL ?
wRepeatCount            WORD ?
wVirtualKeyCode         WORD ?
wVirtualScanCode        WORD ?
union uChar
 UnicodeChar            WCHAR ?
 AsciiChar              CHAR ?
ends
dwControlKeyState       DWORD ?
KEY_EVENT_RECORD        ends
PKEY_EVENT_RECORD       typedef ptr KEY_EVENT_RECORD

define RIGHT_ALT_PRESSED     0x0001
define LEFT_ALT_PRESSED      0x0002
define RIGHT_CTRL_PRESSED    0x0004
define LEFT_CTRL_PRESSED     0x0008
define SHIFT_PRESSED         0x0010
define NUMLOCK_ON            0x0020
define SCROLLLOCK_ON         0x0040
define CAPSLOCK_ON           0x0080
define ENHANCED_KEY          0x0100
define NLS_DBCSCHAR          0x00010000
define NLS_ALPHANUMERIC      0x00000000
define NLS_KATAKANA          0x00020000
define NLS_HIRAGANA          0x00040000
define NLS_ROMAN             0x00400000
define NLS_IME_CONVERSION    0x00800000
define ALTNUMPAD_BIT         0x04000000
define NLS_IME_DISABLE       0x20000000

MOUSE_EVENT_RECORD      struct
dwMousePosition         COORD <>
dwButtonState           DWORD ?
dwControlKeyState       DWORD ?
dwEventFlags            DWORD ?
MOUSE_EVENT_RECORD      ends
PMOUSE_EVENT_RECORD     typedef ptr MOUSE_EVENT_RECORD

define FROM_LEFT_1ST_BUTTON_PRESSED    0x0001
define RIGHTMOST_BUTTON_PRESSED        0x0002
define FROM_LEFT_2ND_BUTTON_PRESSED    0x0004
define FROM_LEFT_3RD_BUTTON_PRESSED    0x0008
define FROM_LEFT_4TH_BUTTON_PRESSED    0x0010

define MOUSE_MOVED   0x0001
define DOUBLE_CLICK  0x0002
define MOUSE_WHEELED 0x0004
if(_WIN32_WINNT ge 0x0600)
define MOUSE_HWHEELED 0x0008
endif

WINDOW_BUFFER_SIZE_RECORD struct
dwSize                  COORD <>
WINDOW_BUFFER_SIZE_RECORD ends
PWINDOW_BUFFER_SIZE_RECORD typedef ptr WINDOW_BUFFER_SIZE_RECORD

MENU_EVENT_RECORD       struct
dwCommandId             UINT ?
MENU_EVENT_RECORD       ends
PMENU_EVENT_RECORD      typedef ptr MENU_EVENT_RECORD

FOCUS_EVENT_RECORD      struct
bSetFocus               BOOL ?
FOCUS_EVENT_RECORD      ends
PFOCUS_EVENT_RECORD     typedef ptr FOCUS_EVENT_RECORD

INPUT_RECORD            struct 4
EventType               WORD ?
union Event
 KeyEvent               KEY_EVENT_RECORD <>
 MouseEvent             MOUSE_EVENT_RECORD <>
 WindowBufferSizeEvent  WINDOW_BUFFER_SIZE_RECORD <>
 MenuEvent              MENU_EVENT_RECORD <>
 FocusEvent             FOCUS_EVENT_RECORD <>
ends
INPUT_RECORD            ends
PINPUT_RECORD           typedef ptr INPUT_RECORD

define KEY_EVENT         0x0001
define MOUSE_EVENT       0x0002
define WINDOW_BUFFER_SIZE_EVENT 0x0004
define MENU_EVENT       0x0008
define FOCUS_EVENT      0x0010

define ENABLE_PROCESSED_INPUT              0x0001
define ENABLE_LINE_INPUT                   0x0002
define ENABLE_ECHO_INPUT                   0x0004
define ENABLE_WINDOW_INPUT                 0x0008
define ENABLE_MOUSE_INPUT                  0x0010
define ENABLE_INSERT_MODE                  0x0020
define ENABLE_QUICK_EDIT_MODE              0x0040
define ENABLE_EXTENDED_FLAGS               0x0080
define ENABLE_AUTO_POSITION                0x0100
define ENABLE_VIRTUAL_TERMINAL_INPUT       0x0200

define ENABLE_PROCESSED_OUTPUT             0x0001
define ENABLE_WRAP_AT_EOL_OUTPUT           0x0002
define ENABLE_VIRTUAL_TERMINAL_PROCESSING  0x0004
define DISABLE_NEWLINE_AUTO_RETURN         0x0008
define ENABLE_LVB_GRID_WORLDWIDE           0x0010

CHAR_INFO               struct
union Char
 UnicodeChar            WCHAR ?
 AsciiChar              CHAR ?
ends
Attributes              WORD ?
CHAR_INFO               ends
PCHAR_INFO              typedef ptr CHAR_INFO

CONSOLE_CURSOR_INFO     struct
dwSize                  DWORD ?
bVisible                BOOL ?
CONSOLE_CURSOR_INFO     ends
PCONSOLE_CURSOR_INFO    typedef ptr CONSOLE_CURSOR_INFO

CONSOLE_SCREEN_BUFFER_INFO struct
dwSize                  COORD <>
dwCursorPosition        COORD <>
wAttributes             WORD ?
srWindow                SMALL_RECT <>
dwMaximumWindowSize     COORD <>
CONSOLE_SCREEN_BUFFER_INFO ends
PCONSOLE_SCREEN_BUFFER_INFO typedef ptr CONSOLE_SCREEN_BUFFER_INFO

define CREATE_NEW_CONSOLE   0x00000010
define DETACHED_PROCESS     0x00000008
define INFINITE             0xFFFFFFFF

define GENERIC_READ         0x80000000
define GENERIC_WRITE        0x40000000
define GENERIC_EXECUTE      0x20000000
define GENERIC_ALL          0x10000000
define FILE_SHARE_READ      0x00000001
define FILE_SHARE_WRITE     0x00000002
define CREATE_NEW           1
define CREATE_ALWAYS        2
define OPEN_EXISTING        3
define OPEN_ALWAYS          4
define TRUNCATE_EXISTING    5

ifndef LPFILETIME
FILETIME    STRUC
dwLowDateTime   dd ?
dwHighDateTime  dd ?
FILETIME    ENDS
LPFILETIME  typedef ptr FILETIME
endif

ifndef LPSYSTEMTIME
SYSTEMTIME  STRUC
wYear       dw ?
wMonth      dw ?
wDayOfWeek  dw ?
wDay        dw ?
wHour       dw ?
wMinute     dw ?
wSecond     dw ?
wMilliseconds   dw ?
SYSTEMTIME  ENDS
LPSYSTEMTIME    typedef ptr SYSTEMTIME
endif

DWORDLONG               typedef qword

MEMORYSTATUSEX          struct
dwLength                DWORD ?
dwMemoryLoad            DWORD ?
ullTotalPhys            DWORDLONG ?
ullAvailPhys            DWORDLONG ?
ullTotalPageFile        DWORDLONG ?
ullAvailPageFile        DWORDLONG ?
ullTotalVirtual         DWORDLONG ?
ullAvailVirtual         DWORDLONG ?
ullAvailExtendedVirtual DWORDLONG ?
MEMORYSTATUSEX          ends
LPMEMORYSTATUSEX        typedef ptr MEMORYSTATUSEX

PROCESS_INFORMATION     struct
hProcess                HANDLE ?
hThread                 HANDLE ?
dwProcessId             DWORD ?
dwThreadId              DWORD ?
PROCESS_INFORMATION     ends
PPROCESS_INFORMATION    typedef ptr PROCESS_INFORMATION
LPPROCESS_INFORMATION   typedef ptr PROCESS_INFORMATION

STARTUPINFOA            struct
cb                      DWORD ?
lpReserved              LPSTR ?
lpDesktop               LPSTR ?
lpTitle                 LPSTR ?
dwX                     DWORD ?
dwY                     DWORD ?
dwXSize                 DWORD ?
dwYSize                 DWORD ?
dwXCountChars           DWORD ?
dwYCountChars           DWORD ?
dwFillAttribute         DWORD ?
dwFlags                 DWORD ?
wShowWindow             WORD ?
cbReserved2             WORD ?
lpReserved2             LPBYTE ?
hStdInput               HANDLE ?
hStdOutput              HANDLE ?
hStdError               HANDLE ?
STARTUPINFOA            ends
LPSTARTUPINFOA          typedef ptr STARTUPINFOA

STARTUPINFOW            struct
cb                      DWORD ?
lpReserved              LPWSTR ?
lpDesktop               LPWSTR ?
lpTitle                 LPWSTR ?
dwX                     DWORD ?
dwY                     DWORD ?
dwXSize                 DWORD ?
dwYSize                 DWORD ?
dwXCountChars           DWORD ?
dwYCountChars           DWORD ?
dwFillAttribute         DWORD ?
dwFlags                 DWORD ?
wShowWindow             WORD ?
cbReserved2             WORD ?
lpReserved2             LPBYTE ?
hStdInput               HANDLE ?
hStdOutput              HANDLE ?
hStdError               HANDLE ?
STARTUPINFOW            ends
LPSTARTUPINFOW          typedef ptr STARTUPINFOW
ifdef _UNICODE
STARTUPINFO             typedef STARTUPINFOW
LPSTARTUPINFO           typedef LPSTARTUPINFOW
else
STARTUPINFO             typedef STARTUPINFOA
LPSTARTUPINFO           typedef LPSTARTUPINFOA
endif

IMAGE_DATA_DIRECTORY    STRUC
VirtualAddress          dd ?
Size                    dd ?
IMAGE_DATA_DIRECTORY    ENDS
PIMAGE_DATA_DIRECTORY   typedef ptr IMAGE_DATA_DIRECTORY

IMAGE_NUMBEROF_DIRECTORY_ENTRIES equ 16

IMAGE_OPTIONAL_HEADER32 STRUC
Magic                   dw ?
MajorLinkerVersion      db ?
MinorLinkerVersion      db ?
SizeOfCode              dd ?
SizeOfInitializedData   dd ?
SizeOfUninitializedData dd ?
AddressOfEntryPoint     dd ?
BaseOfCode              dd ?
BaseOfData              dd ?
ImageBase               dd ?
SectionAlignment        dd ?
FileAlignment           dd ?
MajorOperatingSystemVersion dw ?
MinorOperatingSystemVersion dw ?
MajorImageVersion       dw ?
MinorImageVersion       dw ?
MajorSubsystemVersion   dw ?
MinorSubsystemVersion   dw ?
Win32VersionValue       dd ?
SizeOfImage             dd ?
SizeOfHeaders           dd ?
CheckSum                dd ?
Subsystem               dw ?
DllCharacteristics      dw ?
SizeOfStackReserve      dd ?
SizeOfStackCommit       dd ?
SizeOfHeapReserve       dd ?
SizeOfHeapCommit        dd ?
LoaderFlags             dd ?
NumberOfRvaAndSizes     dd ?
DataDirectory           IMAGE_DATA_DIRECTORY IMAGE_NUMBEROF_DIRECTORY_ENTRIES dup(<>)
IMAGE_OPTIONAL_HEADER32 ENDS
PIMAGE_OPTIONAL_HEADER32 typedef ptr IMAGE_OPTIONAL_HEADER32

IMAGE_OPTIONAL_HEADER64 STRUC
Magic                   dw ?
MajorLinkerVersion      db ?
MinorLinkerVersion      db ?
SizeOfCode              dd ?
SizeOfInitializedData   dd ?
SizeOfUninitializedData dd ?
AddressOfEntryPoint     dd ?
BaseOfCode              dd ?
ImageBase               dq ?
SectionAlignment        dd ?
FileAlignment           dd ?
MajorOperatingSystemVersion dw ?
MinorOperatingSystemVersion dw ?
MajorImageVersion       dw ?
MinorImageVersion       dw ?
MajorSubsystemVersion   dw ?
MinorSubsystemVersion   dw ?
Win32VersionValue       dd ?
SizeOfImage             dd ?
SizeOfHeaders           dd ?
CheckSum                dd ?
Subsystem               dw ?
DllCharacteristics      dw ?
SizeOfStackReserve      dq ?
SizeOfStackCommit       dq ?
SizeOfHeapReserve       dq ?
SizeOfHeapCommit        dq ?
LoaderFlags             dd ?
NumberOfRvaAndSizes     dd ?
DataDirectory           IMAGE_DATA_DIRECTORY IMAGE_NUMBEROF_DIRECTORY_ENTRIES dup(<>)
IMAGE_OPTIONAL_HEADER64 ENDS
PIMAGE_OPTIONAL_HEADER64 typedef ptr IMAGE_OPTIONAL_HEADER64

IMAGE_FILE_HEADER       STRUC
Machine                 dw ?
NumberOfSections        dw ?
TimeDateStamp           dd ?
PointerToSymbolTable    dd ?
NumberOfSymbols         dd ?
SizeOfOptionalHeader    dw ?
Characteristics         dw ?
IMAGE_FILE_HEADER       ENDS
PIMAGE_FILE_HEADER      typedef ptr IMAGE_FILE_HEADER

IMAGE_NT_HEADERS64      STRUC
Signature               dd ?
FileHeader              IMAGE_FILE_HEADER <>
OptionalHeader          IMAGE_OPTIONAL_HEADER64 <>
IMAGE_NT_HEADERS64      ENDS
PIMAGE_NT_HEADERS64     typedef ptr IMAGE_NT_HEADERS64

IMAGE_NT_HEADERS32      STRUC
Signature               dd ?
FileHeader              IMAGE_FILE_HEADER <>
OptionalHeader          IMAGE_OPTIONAL_HEADER32 <>
IMAGE_NT_HEADERS32      ENDS
PIMAGE_NT_HEADERS32     typedef ptr IMAGE_NT_HEADERS32

ifdef _WIN64
IMAGE_NT_HEADERS        typedef IMAGE_NT_HEADERS64
PIMAGE_NT_HEADERS       typedef PIMAGE_NT_HEADERS64
else
IMAGE_NT_HEADERS        typedef IMAGE_NT_HEADERS32
PIMAGE_NT_HEADERS       typedef PIMAGE_NT_HEADERS32
endif

IMAGE_DOS_HEADER        STRUC
e_magic                 dw ?
e_cblp                  dw ?
e_cp                    dw ?
e_crlc                  dw ?
e_cparhdr               dw ?
e_minalloc              dw ?
e_maxalloc              dw ?
e_ss                    dw ?
e_sp                    dw ?
e_csum                  dw ?
e_ip                    dw ?
e_cs                    dw ?
e_lfarlc                dw ?
e_ovno                  dw ?
e_res                   dw 4 dup(?)
e_oemid                 dw ?
e_oeminfo               dw ?
e_res2                  dw 10 dup(?)
e_lfanew                dd ?
IMAGE_DOS_HEADER        ENDS
PIMAGE_DOS_HEADER       typedef ptr IMAGE_DOS_HEADER


WIN32_FIND_DATAA        STRUC 4
dwFileAttributes        dd ?
ftCreationTime          FILETIME <>
ftLastAccessTime        FILETIME <>
ftLastWriteTime         FILETIME <>
nFileSizeHigh           dd ?
nFileSizeLow            dd ?
dwReserved0             dd ?
dwReserved1             dd ?
cFileName               db 260 dup(?)
cAlternateFileName      db 14 dup(?)
ifdef _MAC
dwFileType              dd ?
dwCreatorType           dd ?
wFinderFlags            dw ?
endif
WIN32_FIND_DATAA        ENDS
PWIN32_FIND_DATAA       typedef ptr WIN32_FIND_DATAA
LPWIN32_FIND_DATAA      typedef ptr WIN32_FIND_DATAA
WIN32_FIND_DATAW        STRUC 4
dwFileAttributes        dd ?
ftCreationTime          FILETIME <>
ftLastAccessTime        FILETIME <>
ftLastWriteTime         FILETIME <>
nFileSizeHigh           dd ?
nFileSizeLow            dd ?
dwReserved0             dd ?
dwReserved1             dd ?
cFileName               WCHAR MAX_PATH dup(?)
cAlternateFileName      WCHAR 14 dup(?)
ifdef _MAC
dwFileType              dd ?
dwCreatorType           dd ?
wFinderFlags            dw ?
endif
WIN32_FIND_DATAW        ENDS
PWIN32_FIND_DATAW       typedef ptr WIN32_FIND_DATAW
LPWIN32_FIND_DATAW      typedef ptr WIN32_FIND_DATAW
ifdef _UNICODE
WIN32_FIND_DATA         typedef WIN32_FIND_DATAW
PWIN32_FIND_DATA        typedef PWIN32_FIND_DATAW
LPWIN32_FIND_DATA       typedef LPWIN32_FIND_DATAW
else
WIN32_FIND_DATA         typedef WIN32_FIND_DATAA
PWIN32_FIND_DATA        typedef PWIN32_FIND_DATAA
LPWIN32_FIND_DATA       typedef LPWIN32_FIND_DATAA
endif

define STD_INPUT_HANDLE    (-10)
define STD_OUTPUT_HANDLE   (-11)
define STD_ERROR_HANDLE    (-12)

define SEM_FAILCRITICALERRORS      0x0001

.pragma comment(lib, kernel32)

SetConsoleTitleA proto WINAPI :LPCSTR
SetConsoleTitleW proto WINAPI :LPCWSTR
ifdef _UNICODE
define SetConsoleTitle  <SetConsoleTitleW>
else
define SetConsoleTitle  <SetConsoleTitleA>
endif

GetFullPathNameA proto WINAPI :LPCSTR, :DWORD, :LPSTR, :ptr
GetFullPathNameW proto WINAPI :LPCWSTR, :DWORD, :LPWSTR, :ptr
ifdef _UNICODE
define GetFullPathName <GetFullPathNameW>
else
define GetFullPathName <GetFullPathNameA>
endif

GetEnvironmentStringsW proto WINAPI
ifdef _UNICODE
define GetEnvironmentStrings  <GetEnvironmentStringsW>
else
GetEnvironmentStrings proto WINAPI
define GetEnvironmentStringsA  <GetEnvironmentStrings>
endif

FreeEnvironmentStringsA proto WINAPI :LPCH
FreeEnvironmentStringsW proto WINAPI :LPWCH
ifdef _UNICODE
define FreeEnvironmentStrings  <FreeEnvironmentStringsW>
else
define FreeEnvironmentStrings  <FreeEnvironmentStringsA>
endif

GetCurrentDirectoryA proto WINAPI :DWORD, :LPSTR
GetCurrentDirectoryW proto WINAPI :DWORD, :LPWSTR
ifdef _UNICODE
define GetCurrentDirectory  <GetCurrentDirectoryW>
else
define GetCurrentDirectory  <GetCurrentDirectoryA>
endif

GetCommandLineA proto WINAPI
GetCommandLineW proto WINAPI
ifdef _UNICODE
define GetCommandLine  <GetCommandLineW>
else
define GetCommandLine  <GetCommandLineA>
endif

GetModuleFileNameA proto WINAPI :HMODULE, :LPSTR, :DWORD
GetModuleFileNameW proto WINAPI :HMODULE, :LPWSTR, :DWORD
ifdef _UNICODE
define GetModuleFileName  <GetModuleFileNameW>
else
define GetModuleFileName  <GetModuleFileNameA>
endif

define GMEM_MOVEABLE    0x0002
define GMEM_DDESHARE    0x2000
define HEAP_ZERO_MEMORY 0x0008
GetProcessHeap proto WINAPI
HeapAlloc proto WINAPI :HANDLE, :DWORD, :size_t
HeapFree proto WINAPI :HANDLE, :DWORD, :ptr

ExpandEnvironmentStringsA proto WINAPI :LPCSTR, :LPSTR, :DWORD
ExpandEnvironmentStringsW proto WINAPI :LPCWSTR, :LPWSTR, :DWORD
ifdef _UNICODE
define ExpandEnvironmentStrings  <ExpandEnvironmentStringsW>
else
define ExpandEnvironmentStrings  <ExpandEnvironmentStringsA>
endif

GetShortPathNameA proto WINAPI :LPCSTR, :LPSTR, :DWORD
GetShortPathNameW proto WINAPI :LPCWSTR, :LPWSTR, :DWORD
ifdef _UNICODE
define GetShortPathName  <GetShortPathNameW>
else
define GetShortPathName  <GetShortPathNameA>
endif

SetEnvironmentVariableA proto WINAPI :LPCSTR, :LPCSTR
SetEnvironmentVariableW proto WINAPI :LPCWSTR, :LPCWSTR
ifdef _UNICODE
define SetEnvironmentVariable  <SetEnvironmentVariableW>
else
define SetEnvironmentVariable  <SetEnvironmentVariableA>
endif

GetFileAttributesA proto WINAPI :LPCSTR
GetFileAttributesW proto WINAPI :LPCWSTR
ifdef _UNICODE
define GetFileAttributes  <GetFileAttributesW>
else
define GetFileAttributes  <GetFileAttributesA>
endif

CloseHandle proto WINAPI :HANDLE

DeleteFileA proto WINAPI :LPCSTR
DeleteFileW proto WINAPI :LPCWSTR
ifdef _UNICODE
define DeleteFile  <DeleteFileW>
else
define DeleteFile  <DeleteFileA>
endif

WriteFile proto WINAPI :HANDLE, :ptr, :DWORD, :ptr, :ptr

GetEnvironmentVariableA proto WINAPI :LPCSTR, :LPSTR, :DWORD
GetEnvironmentVariableW proto WINAPI :LPCWSTR, :LPWSTR, :DWORD
ifdef _UNICODE
define GetEnvironmentVariable  <GetEnvironmentVariableW>
else
define GetEnvironmentVariable  <GetEnvironmentVariableA>
endif

SetCurrentDirectoryA proto WINAPI :LPCSTR
SetCurrentDirectoryW proto WINAPI :LPCWSTR
ifdef _UNICODE
define SetCurrentDirectory  <SetCurrentDirectoryW>
else
define SetCurrentDirectory  <SetCurrentDirectoryA>
endif

GetDiskFreeSpaceExA proto WINAPI :LPCSTR, :ptr, :ptr, :ptr
GetDiskFreeSpaceExW proto WINAPI :LPCWSTR, :ptr, :ptr, :ptr
ifdef _UNICODE
define GetDiskFreeSpaceEx  <GetDiskFreeSpaceExW>
else
define GetDiskFreeSpaceEx  <GetDiskFreeSpaceExA>
endif

Sleep proto WINAPI :DWORD
GetStdHandle proto WINAPI :DWORD
SetErrorMode proto WINAPI :UINT

SearchPathA proto WINAPI :LPCSTR, :LPCSTR, :LPCSTR, :DWORD, :LPSTR, :ptr
SearchPathW proto WINAPI :LPCWSTR, :LPCWSTR, :LPCWSTR, :DWORD, :LPWSTR, :ptr
ifdef _UNICODE
define SearchPath  <SearchPathW>
else
define SearchPath  <SearchPathA>
endif

SetConsoleCursorPosition proto WINAPI :HANDLE, :COORD
SetConsoleCursorInfo proto WINAPI :HANDLE, :ptr
GetConsoleMode proto WINAPI :HANDLE, :LPDWORD
SetConsoleMode proto WINAPI :HANDLE, :DWORD
FlushConsoleInputBuffer proto WINAPI :HANDLE
GetConsoleScreenBufferInfo proto WINAPI :HANDLE, :PCONSOLE_SCREEN_BUFFER_INFO

GetDriveTypeA proto WINAPI :LPCSTR
GetDriveTypeW proto WINAPI :LPCWSTR
ifdef _UNICODE
define GetDriveType  <GetDriveTypeW>
else
define GetDriveType  <GetDriveTypeA>
endif

GetLogicalDrives proto WINAPI

GetVolumeInformationA proto WINAPI :LPCSTR, :LPSTR, :DWORD, :LPDWORD, :LPDWORD, :LPDWORD, :LPSTR, :DWORD
GetVolumeInformationW proto WINAPI :LPCWSTR, :LPWSTR, :DWORD, :LPDWORD, :LPDWORD, :LPDWORD, :LPWSTR, :DWORD
ifdef _UNICODE
define GetVolumeInformation  <GetVolumeInformationW>
else
define GetVolumeInformation  <GetVolumeInformationA>
endif

GetLocalTime proto WINAPI :LPSYSTEMTIME
LocalFileTimeToFileTime proto WINAPI :ptr, :LPFILETIME
FileTimeToDosDateTime proto WINAPI :ptr, :LPWORD, :LPWORD
SystemTimeToFileTime proto WINAPI :ptr, :LPFILETIME

SetConsoleScreenBufferSize proto WINAPI :HANDLE, :COORD
GetLargestConsoleWindowSize proto WINAPI :HANDLE
SetConsoleWindowInfo proto WINAPI :HANDLE, :BOOL, :ptr
GetConsoleWindow proto WINAPI

GlobalMemoryStatusEx proto WINAPI :LPMEMORYSTATUSEX

GetModuleHandleA proto WINAPI :LPCSTR
GetModuleHandleW proto WINAPI :LPCWSTR
ifdef _UNICODE
define GetModuleHandle  <GetModuleHandleW>
else
define GetModuleHandle  <GetModuleHandleA>
endif

GetLastError proto WINAPI

MultiByteToWideChar proto WINAPI :UINT, :DWORD, :LPCCH, :SINT, :LPWSTR, :SINT

MoveFileA proto WINAPI :LPCSTR, :LPCSTR
MoveFileW proto WINAPI :LPCWSTR, :LPCWSTR
ifdef _UNICODE
define MoveFile  <MoveFileW>
else
define MoveFile  <MoveFileA>
endif

GetFileTime proto WINAPI :HANDLE, :LPFILETIME, :LPFILETIME, :LPFILETIME

WriteConsoleOutputA proto WINAPI :HANDLE, :ptr, :COORD, :COORD, :PSMALL_RECT
WriteConsoleOutputW proto WINAPI :HANDLE, :ptr, :COORD, :COORD, :PSMALL_RECT
ifdef _UNICODE
define WriteConsoleOutput  <WriteConsoleOutputW>
else
define WriteConsoleOutput  <WriteConsoleOutputA>
endif

SetFileAttributesA proto WINAPI :LPCSTR, :DWORD
SetFileAttributesW proto WINAPI :LPCWSTR, :DWORD
ifdef _UNICODE
define SetFileAttributes  <SetFileAttributesW>
else
define SetFileAttributes  <SetFileAttributesA>
endif

FILE_SHARE_READ         equ 0x00000001
FILE_SHARE_WRITE        equ 0x00000002

GetFileSizeEx proto WINAPI :HANDLE, :ptr
GetFileSizeEx proto WINAPI :HANDLE, :ptr
ReadFile proto WINAPI :HANDLE, :ptr, :DWORD, :ptr, :ptr
CreateFileA proto WINAPI :LPCSTR, :DWORD, :DWORD, :ptr, :DWORD, :DWORD, :HANDLE
CreateFileW proto WINAPI :LPCWSTR, :DWORD, :DWORD, :ptr, :DWORD, :DWORD, :HANDLE
ifdef _UNICODE
define CreateFile  <CreateFileW>
else
define CreateFile  <CreateFileA>
endif

GetConsoleCursorInfo proto WINAPI :HANDLE, :PCONSOLE_CURSOR_INFO
ReadConsoleOutputA proto WINAPI :HANDLE, :PCHAR_INFO, :COORD, :COORD, :PSMALL_RECT
ReadConsoleOutputW proto WINAPI :HANDLE, :PCHAR_INFO, :COORD, :COORD, :PSMALL_RECT
ifdef _UNICODE
define ReadConsoleOutput  <ReadConsoleOutputW>
else
define ReadConsoleOutput  <ReadConsoleOutputA>
endif

ReadConsoleOutputCharacterA proto WINAPI :HANDLE, :LPSTR, :DWORD, :COORD, :LPDWORD
ReadConsoleOutputCharacterW proto WINAPI :HANDLE, :LPWSTR, :DWORD, :COORD, :LPDWORD
ifdef _UNICODE
define ReadConsoleOutputCharacter  <ReadConsoleOutputCharacterW>
else
define ReadConsoleOutputCharacter  <ReadConsoleOutputCharacterA>
endif

FillConsoleOutputCharacterA proto WINAPI :HANDLE, :CHAR, :DWORD, :COORD, :LPDWORD
FillConsoleOutputCharacterW proto WINAPI :HANDLE, :WCHAR, :DWORD, :COORD, :LPDWORD
ifdef _UNICODE
define FillConsoleOutputCharacter  <FillConsoleOutputCharacterW>
else
define FillConsoleOutputCharacter  <FillConsoleOutputCharacterA>
endif

GetTimeFormatA proto WINAPI :LCID, :DWORD, :ptr SYSTEMTIME, :LPCSTR, :LPSTR, :SINT
GetTimeFormatW proto WINAPI :LCID, :DWORD, :ptr SYSTEMTIME, :LPCWSTR, :LPWSTR, :SINT
ifdef _UNICODE
define GetTimeFormat  <GetTimeFormatW>
else
define GetTimeFormat  <GetTimeFormatA>
endif

define DATE_SHORTDATE       0x00000001
define DATE_LONGDATE        0x00000002
define TIME_FORCE24HOURFORMAT   0x00000008

GetUserDefaultLCID proto WINAPI
GetDateFormatA proto WINAPI :LCID, :DWORD, :ptr SYSTEMTIME, :LPCSTR, :LPSTR, :SINT
GetDateFormatW proto WINAPI :LCID, :DWORD, :ptr SYSTEMTIME, :LPCWSTR, :LPWSTR, :SINT
ifdef _UNICODE
define GetDateFormat  <GetDateFormatW>
else
define GetDateFormat  <GetDateFormatA>
endif

ExitProcess proto WINAPI :UINT
WaitForSingleObject proto WINAPI :HANDLE, :DWORD
GetExitCodeProcess proto WINAPI :HANDLE, :LPDWORD

CreateProcessA proto WINAPI :LPCSTR, :LPSTR, :ptr, :ptr, :BOOL, :DWORD, :ptr, :LPCSTR, :LPSTARTUPINFOA, :ptr
CreateProcessW proto WINAPI :LPCWSTR, :LPWSTR, :ptr, :ptr, :BOOL, :DWORD, :ptr, :LPCWSTR, :LPSTARTUPINFOW, :ptr
ifdef _UNICODE
define CreateProcess  <CreateProcessW>
else
define CreateProcess  <CreateProcessA>
endif

WriteConsoleOutputCharacterA proto WINAPI :HANDLE, :LPCSTR, :DWORD, :COORD, :LPDWORD
WriteConsoleOutputCharacterW proto WINAPI :HANDLE, :LPCWSTR, :DWORD, :COORD, :LPDWORD
ifdef _UNICODE
define WriteConsoleOutputCharacter  <WriteConsoleOutputCharacterW>
else
define WriteConsoleOutputCharacter  <WriteConsoleOutputCharacterA>
endif
GetSystemTimeAsFileTime proto WINAPI :LPFILETIME
FillConsoleOutputAttribute proto WINAPI :HANDLE, :WORD, :DWORD, :COORD, :LPDWORD
WriteConsoleOutputAttribute proto WINAPI :HANDLE, :ptr, :DWORD, :COORD, :LPDWORD
GetNumberOfConsoleInputEvents proto WINAPI :HANDLE, :LPDWORD
ReadConsoleInputA proto WINAPI :HANDLE, :PINPUT_RECORD, :DWORD, :LPDWORD
ReadConsoleInputW proto WINAPI :HANDLE, :PINPUT_RECORD, :DWORD, :LPDWORD
ifdef _UNICODE
define ReadConsoleInput  <ReadConsoleInputW>
else
define ReadConsoleInput  <ReadConsoleInputA>
endif

CreateDirectoryA proto WINAPI :LPCSTR, :ptr
CreateDirectoryW proto WINAPI :LPCWSTR, :ptr
ifdef _UNICODE
define CreateDirectory  <CreateDirectoryW>
else
define CreateDirectory  <CreateDirectoryA>
endif

FileTimeToLocalFileTime proto WINAPI :ptr, :LPFILETIME
FileTimeToSystemTime proto WINAPI :ptr, :LPSYSTEMTIME
SetFileTime proto WINAPI :HANDLE, :ptr, :ptr, :ptr

RemoveDirectoryA proto WINAPI :LPCSTR
RemoveDirectoryW proto WINAPI :LPCWSTR
ifdef _UNICODE
define RemoveDirectory  <RemoveDirectoryW>
else
define RemoveDirectory  <RemoveDirectoryA>
endif

FindClose proto WINAPI :HANDLE

FindFirstFileA proto WINAPI :LPCSTR, :LPWIN32_FIND_DATAA
FindFirstFileW proto WINAPI :LPCWSTR, :LPWIN32_FIND_DATAW
ifdef _UNICODE
define FindFirstFile  <FindFirstFileW>
else
define FindFirstFile  <FindFirstFileA>
endif

FindNextFileA proto WINAPI :HANDLE, :LPWIN32_FIND_DATAA
FindNextFileW proto WINAPI :HANDLE, :LPWIN32_FIND_DATAW
ifdef _UNICODE
define FindNextFile  <FindNextFileW>
else
define FindNextFile  <FindNextFileA>
endif

ReadConsoleOutputAttribute proto WINAPI :HANDLE, :LPWORD, :DWORD, :COORD, :LPDWORD
GlobalAlloc proto WINAPI :UINT, :SIZE_T
GlobalAlloc proto WINAPI :UINT, :SIZE_T
GlobalLock proto WINAPI :HGLOBAL
GlobalUnlock proto WINAPI :HGLOBAL

Beep proto WINAPI :DWORD, :DWORD
SetFilePointer proto WINAPI :HANDLE, :LONG, :ptr, :DWORD
SetFilePointerEx proto WINAPI :HANDLE, :qword, :ptr, :DWORD


TIME_ZONE_INFORMATION   struct
Bias                    LONG ?
StandardName            WCHAR 32 dup(?)
StandardDate            SYSTEMTIME <>
StandardBias            LONG ?
DaylightName            WCHAR 32 dup(?)
DaylightDate            SYSTEMTIME <>
DaylightBias            LONG ?
TIME_ZONE_INFORMATION   ends

GetTimeZoneInformation proto WINAPI :ptr PTIME_ZONE_INFORMATION

endif

