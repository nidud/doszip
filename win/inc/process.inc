ifndef _INC_PROCESS
define _INC_PROCESS
include stdlib.inc

define _P_WAIT      0
define _P_NOWAIT    1

define MAXCMDL      0x8000

externdef   __pCommandArg:LPSTR
externdef   __pCommandCom:LPSTR
externdef   __comspec:sbyte
externdef   comspec_type:dword
externdef   OldConsoleMode:dword

__initcomspec   proto __cdecl

endif
