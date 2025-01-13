; PANEL.INC--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

.class Panel

    fcb_count   int_t ?
    cel_count   int_t ?
    fcb_index   int_t ?
    cel_index   int_t ?
    dialog      HWND ?

    Panel       proc
    Release     proc

    State       proc
    Close       proc
    Hide        proc
    Show        proc
    SetActive   proc
    CurItem     proc
    FindNext    proc
    OpenMsg     proc
    Read        proc
    ReRead      proc
    ReDraw      proc
    Toggle      proc
    Update      proc
    XorMini     proc
    XorInfo     proc
    SetId       proc :int_t
    PutItem     proc :int_t
    XYCmd       proc :int_t, :int_t
    SetHdd      proc :int_t
    Event       proc :int_t
   .ends