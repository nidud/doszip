ifndef __CONFIRM_INC
define __CONFIRM_INC

include libc.inc

.enum
  CONFIRM_CANCEL,
  CONFIRM_DELETE,
  CONFIRM_DELETEALL,
  CONFIRM_JUMP

define CFREADONY   0x0001
define CFSYSTEM	   0x0002
define CFDIRECTORY 0x0004
define CFSELECTED  0x0008
define CFDELETEALL 0x0010

externdef confirmflag:uint_t

confirm_continue    proto __cdecl :string_t
confirm_delete	    proto __cdecl :string_t, :uint_t
confirm_delete_file proto __cdecl :string_t, :uint_t
confirm_delete_sub  proto __cdecl :string_t

endif
