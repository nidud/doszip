#
# Makefile for Doszip
#

watc   = \watcom
ifndef dosver
dosver = 266
endif
dosmin = 253
ifndef winver
winver = 383
endif
winmin = 349

all: DZ16 DZ32 DZ64

DZ16:
	md $@
	md $@\dz
	asmc -pe src\stub\mt.asm
	mt src\dos\inc\dz.txt $@\dz\dz.txt $(dosver)
	copy copying.txt $@\LICENSE
	asmc -DVERSION=$(dosver) -mz -Fo $@\dz\dz.exe -q src\stub\dz.asm
	asmc -idd -ml src\dos\res\*.idd
	asmc -Isrc\dos\inc -DVERSION=$(dosver) -DMINVERS=$(dosmin) -D__LARGE__ -D__DZ__ src\dos\*.asm
	linkw system dos name $@\dz\dz.dos file *.obj
	del *.obj
	del *.s
	del mt.exe

DZ32:
	md $@
	md $@\dz
	asmc -pe src\stub\mt.asm
	mt src\inc\dz.txt $@\dz\dz.txt $(winver)
	copy copying.txt $@\LICENSE
	asmc -DVERSION=$(dosver) -mz -Fo dz.bin -q -Isrc\dos\inc src\stub\dz.asm
	asmc -c -DVERSION=$(winver) -DMINVERS=$(winmin) -MT -coff -Zp4 -Cs -D__BMP__ -Isrc\inc src\*.asm
	asmc -c -MT -coff -Zp4 -mf -Gd -idd src\res\*.idd
	$(watc)\binnt\rc.exe -nologo -fodz.res -I$(watc)\h\win src\res\dz.rc
	linkw name $@\dz\dz.exe symt _nofloat op stub=dz.bin, resource=dz.res, stack=0x300000 com stack=0x200000 file *.obj
	del *.obj
	del *.s
	del dz.bin
	del mt.exe

DZ64:
	md $@
	md $@\dz
	asmc -pe src\stub\mt.asm
	asmc -DVERSION=$(dosver) -mz -Fo dz.bin -q src\stub\dz.asm
	asmc -c -DVERSION=$(winver) -DMINVERS=$(winmin) -MT -win64 -frame -Zp8 -Cs -D__BMP__ -Isrc\inc src\*.asm
	asmc -c -MT -win64 -Zp8 -idd src\res\*.idd
	$(watc)\binnt\rc.exe -nologo -fodz.res -I$(watc)\h\win src\res\dz.rc
	linkw name $@\dz\dz.exe symt _nofloat op stub=dz.bin, resource=dz.res, stack=0x300000 com stack=0x200000 file *.obj
	copy copying.txt $@\LICENSE
	mt src\inc\dz.txt $@\dz\dz.txt $(winver)
	del *.obj
	del *.s
	del dz.res
	del dz.bin
	del mt.exe

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
