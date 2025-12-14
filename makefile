#
# Makefile for Doszip 16/32/64
#

watc   = \watcom
ifndef dosver
dosver = 269
endif
ifndef winver
winver = 392
endif
dosmin = 253
winmin = 349

all: DZ16 DZ32 DZ64

DZ16:
	asmc -pe -DVERSION=$(dosver) -DSRCFILE=src\dos\inc\dz.txt -DOUTPATH=$@ src\stub\mkdz.asm
	mkdz
	asmc -DVERSION=$(dosver) -mz -Fo $@\dz\dz.exe -q src\stub\dz.asm
	asmc -idd -ml -r src\dos\*.idd
	asmc -Isrc\dos\inc -D__DZ__ -r src\dos\lib\src\*.asm
	libw -q -b -n -c src\dos\lib\cl.lib *.obj
	del *.obj
	del *.s
	asmc -Fo src\dos\lib\c0l.obj -D__l__ src\dos\lib\crt.asm
	asmc -Isrc\dos\inc -D__DZ__ src\dos\src\dz\*.asm
	linkw system dos name $@\dz\dz.dos lib src\dos\lib\cl.lib file src\dos\lib\c0l.obj, *.obj
	del *.obj
	del mkdz.exe

DZ32:
	asmc -pe -DVERSION=$(winver) -DSRCFILE=src\inc\dz.txt -DOUTPATH=$@ src\stub\mkdz.asm
	mkdz
	$(watc)\binnt\rc.exe -nologo -fodz.res -I$(watc)\h\win src\res\dz.rc
	asmc -DVERSION=$(dosver) -mz -Fo dz.bin -q -Isrc\dos\inc src\stub\dz.asm
	asmc -DVERSION=$(winver) -DMINVERS=$(winmin) -MT -coff -Zp4 -Cs -D__BMP__ -Isrc\inc src\*.asm -mf -Gd -idd src\res\*.idd -link -st:0x300000,0x200000 -o:$@\dz\dz.exe -stub:dz.bin -res:dz.res
	del *.obj
	del *.s
	del dz.bin
	del mkdz.exe

DZ64:
	asmc -pe -DVERSION=$(winver) -DSRCFILE=src\inc\dz.txt -DOUTPATH=$@ src\stub\mkdz.asm
	mkdz
	$(watc)\binnt\rc.exe -nologo -fodz.res -I$(watc)\h\win src\res\dz.rc
	asmc -DVERSION=$(dosver) -mz -Fo dz.bin -q src\stub\dz.asm
	asmc -DVERSION=$(winver) -DMINVERS=$(winmin) -MT -win64 -frame -Zp8 -Cs -D__BMP__ -Isrc\inc src\*.asm -idd src\res\*.idd -link -map -st:0x300000,0x200000 -o:$@\dz\dz.exe -stub:dz.bin -res:dz.res
	del *.obj
	del *.s
	del dz.res
	del dz.bin
	del mkdz.exe

clean:
	del /Q DZ16\*.*
	del /Q DZ32\*.*
	del /Q DZ64\*.*
	del /Q DZ16\dz\*.*
	del /Q DZ32\dz\*.*
	del /Q DZ64\dz\*.*
	rd DZ16\dz
	rd DZ32\dz
	rd DZ64\dz
	rd DZ16
	rd DZ32
	rd DZ64
