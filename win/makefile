#
# Makefile for Doszip 32/64-bit using LINKW
#
asmc = \asmc
!ifdef x64
flags  = -win64 -frame -Zp8
libdir = x64
!else
flags  = -coff -Gz -Zp4
libdir = x86
!endif

dz.exe:
        del *.obj
        $(asmc)\bin\asmc $(flags) -Cs -D__BMP__ -Iinc -r src\*.asm
        $(asmc)\bin\linkw @<<
name    $@
libpath $(asmc)\lib\$(libdir)
option  map
option  stub=src\res\dz.bin
option  resource=src\res\dz.res
option  stack=0x300000 com stack=0x200000
file    { *.obj }
<<
        del *.obj
        dz.exe

