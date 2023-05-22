; CMPATH.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include string.inc
include stdlib.inc
include config.inc

    .code

cmpath proc private id:int_t

  local path[_MAX_PATH]:char_t

    .if panel_state(cpanel)

        .if CFGetSectionID("Directory", id)

            .if ( word ptr [rax] != '><' )

                .if strchr(rax, ',')

                    mov rcx,strstart(&[rax+1])
                    expenviron(strnzcpy(&path, rcx, _MAX_PATH-1))

                    .if ( path != '[' )

                        cpanel_setpath(&path)
                    .endif
                .endif
            .endif
        .endif
    .endif
    ret

cmpath endp

cmpathp macro q
cmpath&q proc
    cmpath(q)
    ret
cmpath&q endp
    endm

cmpathp 0
cmpathp 1
cmpathp 2
cmpathp 3
cmpathp 4
cmpathp 5
cmpathp 6
cmpathp 7

    END
