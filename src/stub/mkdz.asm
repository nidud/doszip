; MKDZ.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include stdio.inc
include direct.inc
include tchar.inc

.data
 version dd VERSION
%srcfile db "&SRCFILE&",0
%outpath db "&OUTPATH&",0

.code

_tmain proc argc:int_t, argv:array_t

   .new fp:LPFILE
   .new fo:LPFILE
   .new ver_h:int_t
   .new ver_l:int_t
   .new buffer[256]:char_t

    mov eax,version
    mov ecx,100
    xor edx,edx
    idiv ecx
    mov ver_h,eax
    mov ver_l,edx

    _mkdir(&outpath)
    _mkdir(strcat(strcpy(&buffer, &outpath), "\\dz"))

    .if ( fopen(strcat(strcpy(&buffer, &outpath), "\\LICENSE"), "wt" ) == NULL )

        perror(&buffer)
       .return( 1 )
    .endif
    mov fo,rax
    fprintf(fo,
        " Doszip\n"
        "\n"
        " License for use and distribution\n"
        "\n"
        " Copyright (C) 1999-2025 The Doszip Contributors.\n"
        "\n"
        " The license for files are GNU General Public License.\n"
        "\n"
        " GNU GPL information:\n"
        "\n"
        "    This program is free software; you can redistribute it and/or modify\n"
        "    it under the terms of the GNU General Public License as published by\n"
        "    the Free Software Foundation; either version 2 of the License, or\n"
        "    (at your option) any later version.\n"
        "\n"
        "    This program is distributed in the hope that it will be useful,\n"
        "    but WITHOUT ANY WARRANTY; without even the implied warranty of\n"
        "    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n"
        "    GNU General Public License for more details.\n"
        "\n"
        "    You should have received a copy of the GNU General Public License along\n"
        "    with this program; if not, you can get a copy of the GNU General Public\n"
        "    License from http://www.gnu.org/\n"
        "\n" )

    fclose(fo)

    .if ( fopen(strcat(strcpy(&buffer, &outpath), "\\dz\\dz.txt"), "wt" ) == NULL )

        perror(&buffer)
       .return( 1 )
    .endif
    mov fo,rax

    .if ( fopen(&srcfile, "rt" ) == NULL )

        perror(&buffer)
        fclose(fo)
       .return( 1 )
    .endif
    mov fp,rax
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
