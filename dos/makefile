# MAKEFILE--
# Makefile for Doszip
#
dz.exe:
    asmc -mz -Fo dz.exe -q -Iinc src\dz.asm
    iddc -ml -r src\res\*.idd
    asmc -Iinc -D__DZ__ src\dz\*.asm
    linkw system dos name dz.dos lib lib\cl.lib file lib\c0l.obj, *.obj
    del *.obj
