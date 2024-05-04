#
# Makefile for Doszip 32/64-bit using LINKW
#
asmc   = \asmc
flags  = -win64 -frame -Zp8
libdir = x64
ifdef x86
flags  = -coff -Zp4
model  = -mf -Gd
libdir = x86
endif

dz.exe:
        del *.obj
        $(asmc)\bin\asmc $(flags) -Cs -D__BMP__ -Iinc -r src\*.asm
        $(asmc)\bin\asmc $(flags) $(model) -idd src\res\en\*.idd
        $(asmc)\bin\linkw @<<
name    $@
libpath $(asmc)\lib\$(libdir)
library libc
option  map
option  stub=src\res\dz.bin
option  resource=src\res\dz.res
option  stack=0x300000 com stack=0x200000
file    { *.obj }
<<
        del *.obj
        del *.s

