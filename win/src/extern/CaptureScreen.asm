include conio.inc
include string.inc
include io.inc
include wsub.inc
include malloc.inc
include errno.inc
include stdio.inc
include stdlib.inc

ifdef __BMP__

define POPUPKEY (SHIFT_CTRLLEFT or SHIFT_LEFT)

    .data
     winp       PCHAR_INFO ?
     oldevent   DPROC 0
     idleh      DPROC 0
     active     dd 0
     cscr       RIDD <>
     file       char_t "default.idd", 256-11 dup(0)

    .code

    option proc:private

bmp_event proc uses rsi rdi rbx

   .new x:int_t
   .new y:int_t

    .ifd ( oldevent() == MOUSECMD )

        mov edi,mousex()
        mov esi,mousey()
        mov rbx,tdialog

        movzx ecx,[rbx].DOBJ.rc.x
        movzx edx,[rbx].DOBJ.rc.y
        add ecx,21
        add edx,4

        mov x,ecx
        mov y,edx
        scputf(ecx, edx, 0, 0, "%d\n%d", edi, esi)

        sub x,21
        sub y,4
        mov edx,x
        mov ecx,y

        mov eax,MOUSECMD
        .if edi < edx || esi < ecx
            xor eax,eax
        .else
            add dl,[rbx].DOBJ.rc.col
            add cl,[rbx].DOBJ.rc.row
            dec ecx
            .if edx < edi || ecx < esi
                xor eax,eax
            .endif
        .endif
    .endif
    ret

bmp_event endp

read_screen proc uses rsi rdi rbx

   .new retval:int_t = 0

    .if rsopen(IDD_SaveScreen)

        mov rbx,rax
        mov rdi,[rbx].DOBJ.object
        mov [rdi].TOBJ.data,&file

        strcpy( [rdi+TOBJ*1].TOBJ.data, "0")
        strcpy( [rdi+TOBJ*2].TOBJ.data, "0")
        sprintf([rdi+TOBJ*3].TOBJ.data, "%d", _scrcol)

        mov eax,_scrrow
        inc eax
        sprintf([rdi+TOBJ*4].TOBJ.data, "%d", eax)
        dlinit(rbx)

        mov rsi,tgetevent
        mov tgetevent,&bmp_event
        mov oldevent,rsi

        .if rsevent(IDD_SaveScreen, rbx)

            atol([rdi+TOBJ*1].TOBJ.data)
            mov cscr.rc.x,al
            atol([rdi+TOBJ*2].TOBJ.data)
            mov cscr.rc.y,al
            atol([rdi+TOBJ*3].TOBJ.data)
            mov cscr.rc.col,al
            atol([rdi+TOBJ*4].TOBJ.data)
            mov cscr.rc.row,al
            mov retval,1
        .endif
        mov tgetevent,oldevent
        dlclose(rbx)
    .endif

    .if retval

        .if rcalloc(cscr.rc, 0)

            mov winp,rax
            rcread(cscr.rc, rax)
            mov eax,1
        .endif
    .endif
    .return(retval)

read_screen endp

cmsavebmp proc uses rsi rdi rbx

   .new p:PCHAR_INFO

    .ifs ( ioopen(&STDO, &file, M_WRONLY, 0x10000) > 0 )

        mov cscr.flag,_D_MYBUF
        mov cscr.count,0
        mov cscr.index,0
        movzx eax,cscr.rc.row
        mul cscr.rc.col
        shl eax,2
        add eax,DOBJ
        mov cscr.size,ax

        .if iowrite(&STDO, &cscr, sizeof(cscr))

            .if rcalloc(cscr.rc, 0)

                mov p,rax
                rczip(cscr.rc, p, winp)
                iowrite(&STDO, p, eax)
                free(p)
            .endif
            ioflush(&STDO)
        .endif
        ioclose(&STDO)
    .else
        eropen(&file)
    .endif
    ret

cmsavebmp endp


TempIdle proc

    xor eax,eax
    ret

TempIdle endp


MakeBMP proc uses rbx

    mov rbx,tdidle
    mov tdidle,&TempIdle

    .if read_screen()

        .if file

            cmsavebmp()
            stdmsg("Screen Saved", "Screen saved to:\n%s", &file)
        .endif
        free(winp)
    .endif
    mov tdidle,rbx
    ret

MakeBMP endp

CSIdle proc

    mov rax,keyshift
    mov eax,[rax]
    and eax,POPUPKEY

    .if ( eax == POPUPKEY )

        .if ( active == 0 )

            mov active,1
            MakeBMP()
        .endif
    .else
        mov active,0
        idleh()
    .endif
    ret

CSIdle endp

CaptureScreen proc public

    mov idleh,tdidle
    mov tdidle,&CSIdle
    ret

CaptureScreen endp

endif
    END
