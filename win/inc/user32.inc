; USER32.INC--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;
ifndef __USER32_INC
define __USER32_INC
include kernel32.inc

RECT        STRUC
left        sdword ?
top         sdword ?
right       sdword ?
bottom      sdword ?
RECT        ENDS

PRECT       typedef ptr RECT
NPRECT      typedef ptr RECT
LPRECT      typedef ptr RECT
LPCRECT     typedef ptr RECT
RECTL       typedef RECT
PRECTL      typedef ptr RECT
LPRECTL     typedef ptr RECT
LPCRECTL    typedef ptr RECTL
DECLARE_HANDLE(HWND)

define SWP_NOSIZE   0x0001
define SWP_NOACTIVATE   0x0010
define SWP_NOZORDER 0x0004

.pragma comment(lib, user32)

if (_WIN32_WINNT GE 0x0500)
GetForegroundWindow proto WINAPI
else
CALLBACK(GetForegroundWindow_T)
externdef GetForegroundWindow:GetForegroundWindow_T
endif

if(WINVER GE 0x0500)
SetWindowPos proto WINAPI :HWND, :HWND, :SINT, :SINT, :SINT, :SINT, :UINT
else
CALLBACK(SetWindowPos_T, :HWND, :HWND, :SINT, :SINT, :SINT, :SINT, :UINT)
externdef SetWindowPos:SetWindowPos_T
endif

GetWindowRect proto WINAPI :HWND, :LPRECT

if (WINVER GE 0x0500)
GetKeyState proto WINAPI :SINT
else
CALLBACK(GetKeyState_T, nVirtKey:SINT)
externdef GetKeyState:GetKeyState_T
endif

SetClipboardData proto WINAPI :UINT, :HANDLE
GetClipboardData proto WINAPI :UINT
OpenClipboard proto WINAPI :HWND
CloseClipboard proto WINAPI
EmptyClipboard proto WINAPI
IsClipboardFormatAvailable proto WINAPI :UINT

SM_CXMIN        equ 28
SM_CYMIN        equ 29

GetSystemMetrics proto WINAPI :SINT

MB_ICONHAND         equ 0x00000010
MB_ICONQUESTION     equ 0x00000020
MB_ICONEXCLAMATION  equ 0x00000030
MB_ICONASTERISK     equ 0x00000040

MessageBeep proto WINAPI :UINT

endif

