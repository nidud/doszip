; CMHELP.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include string.inc
include tview.inc
include stdlib.inc

%define BUILD_DATE <"&@Date">

    .data

DZ_TXTFILE char_t DOSZIP_TXTFILE,0

Offset_README uint_t \
    0,          ; DZ_TXTFILE
    HELPID_02,  ; Compress
    HELPID_03,  ; View
    HELPID_06,  ; Extension
    HELPID_07,  ; Environ
    HELPID_08,  ; Install
    HELPID_09,  ; Tools
    HELPID_10,  ; FF
    HELPID_11,  ; List
    HELPID_12,  ; Filter
    HELPID_13   ; Shortkey

    .code

view_doszip proc private file:LPSTR, offs:uint_t

  local path[_MAX_PATH]:byte

    tview(strfcat(&path, _pgmpath, file), offs)
    ret

view_doszip endp


view_readme proc offs:uint_t

    and tvflag,not _TV_HEXVIEW
    view_doszip(&DZ_TXTFILE, offs)
    ret

view_readme endp

cmabout proc

    stdmsg(
        "About",
        " The Doszip Commander Version " DOSZIP_VSTRING DOSZIP_VSTRPRE "\n"
        " Copyright (c) 2023 Doszip Developers\n"
        "\n"
        " Source code is available under the GNU \n"
        " General Public License version 2.0\n"
        "\n"
        " Build Date: " BUILD_DATE
        )
    ret

cmabout endp


cmhelp proc uses rsi rdi

    .if rsopen(IDD_DZHelp)

        mov rdi,rax
        mov [rdi].TOBJ.tproc[13*TOBJ],&cmabout
        mov rsi,thelp
        mov thelp,&cmabout

        .while rsevent(IDD_DZHelp, rdi)

            dec eax
            lea rcx,Offset_README
            mov eax,[rcx+rax*4]
            view_readme(eax)
        .endw
        dlclose(rdi)
        mov thelp,rsi
        mov eax,1
    .endif
    ret

cmhelp endp

    end
