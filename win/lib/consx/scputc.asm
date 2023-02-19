; SCPUTC.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include consx.inc

    .code

scputc proc uses eax ecx edx x, y, l, char

  local NumberOfCharsWritten

    mov eax,char
    mov ecx,rcunicode()

    movzx eax,byte ptr x
    movzx edx,byte ptr y
    shl   edx,16
    or    edx,eax

    FillConsoleOutputCharacterW(
        hStdOutput,
        ecx,
        l,
        edx,
        &NumberOfCharsWritten)
    ret

scputc endp

    END
