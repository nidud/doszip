; PROGRESS.INC--
;
; Copyright (c) Doszip Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;
ifndef __PROGRESS_INC
define __PROGRESS_INC

include conio.inc

externdef	progress_dobj:DOBJ
externdef	progress_size:QWORD

progress_open	proto __cdecl :LPSTR, :LPSTR
progress_close	proto __cdecl
progress_set	proto __cdecl :LPSTR, :LPSTR, :QWORD
progress_update proto __cdecl :QWORD
test_userabort	proto __cdecl

endif

