; FILESEARCH.INC--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;
ifndef __FILESEARCH_INC
define __FILESEARCH_INC

FFMAXHIT equ 9999

.class FileSearch

    dialog      ptr_t ?
    basedir     string_t ?
    cursor      CURSOR <>
    ll          LOBJ <>
    oldff       ptr_t ?
    oldhelp     ptr_t ?

    FileSearch  proc :string_t
    Release     proc
    WndProc     proc :uint_t
    Find        proc
    Modal       proc
    PutCellId   proc
    UpdateCell  proc
    CurItem     proc
    CurFile     proc
    List        proc
    ClearList   proc
    Searchpath  proc :string_t
    Replace     proc :int_t, :int_t
   .ends

endif
