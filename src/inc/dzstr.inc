ifndef __DZSTR_INC
define __DZSTR_INC
include string.inc

memrchr		proto __cdecl :string_t, :int_t, :uint_t
memquote	proto __cdecl :string_t, :uint_t

stripend	proto __cdecl :string_t

strpath		proto __cdecl :string_t
strnzcpy	proto __cdecl :string_t, :string_t, :size_t
strspace	proto __cdecl :string_t
strtoken	proto __cdecl :string_t
strins		proto __cdecl :string_t, :string_t
strtolx		proto __cdecl :string_t
strchri		proto __cdecl :string_t, :int_t
streol		proto __cdecl :string_t

btohex		proto __cdecl :string_t, :int_t
hextob		proto __cdecl :string_t

endif
