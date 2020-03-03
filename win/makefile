#
# Visual C version 6 used for debug
# Open Watcom used to add the DZ.ICO file
#
watc = \watcom
asmc = \asmc

include = -Iinc -I$(asmc)\include

CC   = $(asmc)\bin\asmc /coff /Cs /Zi /Gz /D__BMP__ $(include)
RC   = $(asmc)\bin\iddc /coff
LIB  = $(asmc)\bin\libw /q /b /n /c /fac
LINK = $(asmc)\bin\linkw op stub=src\res\dz.bin file
ICON = $(watc)\binnt\wrc -q src\res\dz.res $@

all: libc.lib dz.exe clean

libc.lib:
    $(RC) /r src\res\*.idd
    $(CC) /r src\dz\*.asm
    $(CC) /r lib\*.asm
    $(LIB) $@ *.obj
    @del *.obj

dz.exe:
    $(CC) -nologo src\dz.asm
    $(LINK) dz.obj
    $(ICON)

clean:
    @del libc.lib
    @del dz.obj

