; MT.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include stdio.inc
include stdlib.inc
include tchar.inc

.code

_tmain proc argc:int_t, argv:array_t

    .new fp:LPFILE
    .new fo:LPFILE
    .new ver_h:int_t
    .new ver_l:int_t
    .new buffer[256]:char_t

    .if ( argc != 4 )
        .return( 1 )
    .endif
    mov rbx,argv
    mov fp,fopen([rbx+size_t], "rt" )
    .if ( rax == 0 )
        .return( 1 )
    .endif
    mov fo,fopen([rbx+size_t*2], "wt" )
    .if ( rax == 0 )
        .return( 1 )
    .endif
    atol([rbx+size_t*3])
    mov ecx,100
    xor edx,edx
    idiv ecx
    mov ver_h,eax
    mov ver_l,edx
    fprintf(fo,
        "DZ.TXT--\n"
        "Copyright (C) 2025 Doszip Developers.\n"
        "\n"
        "DOSZIP COMMANDER\n"
        "Version %d.%02d\n"
        "\n"
        "Welcome to Doszip Commander Version %d.%02d!\n", ver_h, ver_l, ver_h, ver_l )
    .while fgets(&buffer, 256, fp)
        fputs(&buffer, fo)
    .endw
    fclose(fp)
    fclose(fo)
    ret

_tmain endp

    end _tstart
