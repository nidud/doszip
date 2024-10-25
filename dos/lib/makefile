cl.lib:
    asmc -c -idd -ml -r src\*.idd
    asmc -c -I..\inc -D__DZ__ -r src\*.asm
    libw -q -b -n -c $@ *.obj
    del *.obj
    del *.s
    asmc -c -Fo c0l.obj -D__l__ crt.asm
    asmc -c -Fo w0l.obj -D__l__ -D__WCC__ crt.asm
    asmc -c -Fo c0fl.obj -DDEBUG -D__l__ -Zd crt.asm
