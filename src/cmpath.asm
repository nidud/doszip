; CMPATH.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include dzstr.inc
include stdlib.inc
include config.inc

    .code

cmpath proc private uses rsi id:int_t
  local path[_MAX_PATH]:char_t
    ldr esi,id
    .if panel_state(cpanel)
        .if CFGetSection("Directory")
            INIGetNextEntry(rax)
            .for ( : rax && esi : esi-- )
                INIGetNextEntry(rax)
            .endf
        .endif
        .if ( rax )
            mov rax,[rax].S_INI.value
            .if ( rax && word ptr [rax] != '><' )
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
    endp

cmpathp macro q
cmpath&q proc
    cmpath(q)
    ret
    endp
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
