; CMENVIRON.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include malloc.inc
include io.inc
include string.inc
include stdio.inc
include errno.inc
include syserr.inc
include stdlib.inc

define MAXHIT      128
define CELLCOUNT   18

    .data


DLG_Environ PDOBJ 0
FCB_Environ PLOBJ 0

event_keys GLCMD \
    { KEY_F2,  event_add    },
    { KEY_F3,  event_load   },
    { KEY_F4,  event_edit   },
    { KEY_F5,  event_save   },
    { KEY_F8,  event_delete },
    { 0,       0            }

    .code

    option proc:private

getcurobj proc

    xor eax,eax
    mov rdx,FCB_Environ

    .if ( [rdx].LOBJ.count )

        mov eax,[rdx].LOBJ.index
        add eax,[rdx].LOBJ.celoff
        mov rdx,[rdx].LOBJ.list
        mov rax,[rdx+rax*size_t]
    .endif
    ret

getcurobj endp


putcelid proc uses rbx

    mov rbx,DLG_Environ
    movzx eax,[rbx].DOBJ.index
    .if ( eax >= CELLCOUNT )
        xor eax,eax
    .endif
    inc eax
    mov rdx,FCB_Environ
    add eax,[rdx].LOBJ.index
    mov ecx,[rdx].LOBJ.count
    movzx edx,[rbx].DOBJ.rc.y
    movzx ebx,[rbx].DOBJ.rc.x
    add edx,20
    add ebx,3
    scputf(ebx, edx, 0, 0, "<%02d:%02d>", eax, ecx)
    ret

putcelid endp


read_environ proc uses rsi rdi rbx

   .new p:LPSTR

    mov rbx,FCB_Environ
    mov rdi,[rbx].LOBJ.list
    .if rdi

        .for ( esi = 0 : esi < [rbx].LOBJ.count : esi++ )

            free( [rdi+rsi*LPSTR] )
        .endf


        mov [rbx].LOBJ.count,0
        mov [rbx].LOBJ.numcel,0

        .if GetEnvironmentStrings()

            mov p,rax
            mov rsi,rax

            .while 1

                mov al,[rsi]
                .break .if !al

                .if ( al != '=' )

                    mov [rdi],_strdup(rsi)
                    add rdi,size_t
                    inc [rbx].LOBJ.count
                    mov eax,[rbx].LOBJ.count
                    .if ( eax <= CELLCOUNT )
                        inc [rbx].LOBJ.numcel
                    .endif
                .endif
                .break .ifd !strlen(rsi)
                lea rsi,[rsi+rax+1]
            .endw
            FreeEnvironmentStrings(p)
            mov eax,[rbx].LOBJ.count
        .endif
    .endif
    ret

read_environ endp


event_list proc uses rsi rdi rbx

   .new x:int_t
   .new y:int_t

    mov rbx,DLG_Environ
    dlinit(rbx)

    movzx   eax,[rbx].DOBJ.rc.x
    add     eax,3
    mov     x,eax
    movzx   eax,[rbx].DOBJ.rc.y
    add     eax,2
    mov     y,eax

    .for ( rdi = FCB_Environ, ebx = 0 : ebx < [rdi].LOBJ.numcel : ebx++, y++ )

        mov eax,ebx
        add eax,[rdi].LOBJ.index
        mov rsi,[rdi].LOBJ.list
        mov rsi,[rsi+rax*size_t]
        strchr(rsi, '=')
        mov rcx,rsi
        mov rsi,rax
        .if rax
            mov byte ptr [rax],0
        .endif
        scputs(x, y, 0, 25, rcx)
        .if rsi
            mov byte ptr [rsi],'='
            inc rsi
            mov eax,x
            add eax,25
            scputs(eax, y, 0, 45, rsi)
        .endif
    .endf
    .return( 1 )

event_list endp


update_cellid proc uses rdi rbx

    putcelid()
    event_list()

    mov rbx,DLG_Environ
    mov rdi,FCB_Environ
    mov ecx,CELLCOUNT
    mov eax,_O_STATE
    .repeat
        add rbx,TOBJ
        or  [rbx],ax
    .untilcxz
    mov rbx,DLG_Environ
    not eax
    mov ecx,[rdi].LOBJ.numcel
    .while ecx
        add rbx,TOBJ
        and [rbx],ax
        dec ecx
    .endw
    .return(_C_NORMAL)

update_cellid endp


event_xcell proc

    putcelid()
    mov rdx,DLG_Environ
    movzx eax,[rdx].DOBJ.index
    mov rdx,FCB_Environ
    mov [rdx].LOBJ.celoff,eax
    dlxcellevent()
    ret

event_xcell endp

     ;--------------------------------------

event_edit proc uses rsi rdi rbx

  local variable[256]:byte
  local value[2048]:byte

    .if getcurobj()

        mov rsi,rax
        lea rdi,variable
        xor ebx,ebx
        mov value,bl

        .if strchr(rsi, '=')

            mov byte ptr [rax],0
            mov rbx,rax
            inc rax
            strcpy(&value, rax)
        .endif
        strcpy(rdi, rsi)

        .if rbx
            mov byte ptr [rbx],'='
        .endif
        mov rsi,rbx
        lea rbx,value

        .if tgetline(rdi, rbx, 60, 2048)

            .if byte ptr [rbx]

                .if rsi

                    inc rsi
                    .ifd !strcmp(rsi, rbx)

                        .return(_C_NORMAL)
                    .endif
                .endif

                .ifd SetEnvironmentVariable(rdi, rbx)

                    read_environ()
                    update_cellid()
                .endif
            .endif
        .endif
    .endif
    .return(_C_NORMAL)

event_edit endp


event_add proc uses rsi rdi rbx

  local environ[2048]:byte

    lea rbx,environ
    mov byte ptr [rbx],0

    .ifd tgetline("Format: <variable>=<value>", rbx, 60, 2048)

        .if byte ptr [rbx]

            .if strchr(rbx, '=')

                mov byte ptr [rax],0
                inc rax
                .ifd SetEnvironmentVariable(rbx, rax)

                    read_environ()
                    update_cellid()
                .endif
            .endif
        .endif
    .endif
    mov eax,_C_NORMAL
    ret

event_add endp


event_delete proc uses rsi rbx

    .if getcurobj()

        mov rsi,rax
        .if strchr(rax, '=')

            mov byte ptr [rax],0
            mov rbx,rax
            SetEnvironmentVariable(rsi, 0)
            mov byte ptr [rbx],'='

            .if eax

                mov rbx,FCB_Environ
                .ifd !read_environ()

                    mov [rbx].LOBJ.index,eax
                    mov [rbx].LOBJ.celoff,eax

                .else

                    mov edx,[rbx].LOBJ.index
                    mov ecx,[rbx].LOBJ.celoff
                    .if edx

                        mov esi,eax
                        sub esi,edx
                        .if esi < CELLCOUNT

                            dec edx
                            inc ecx
                        .endif
                    .endif

                    sub eax,edx
                    .if eax >= CELLCOUNT
                        mov eax,CELLCOUNT
                    .endif
                    .if ecx >= eax
                        dec ecx
                    .endif

                    mov [rbx].LOBJ.index,edx
                    mov [rbx].LOBJ.celoff,ecx
                    mov [rbx].LOBJ.numcel,eax
                    mov rbx,DLG_Environ
                    test eax,eax
                    mov al,cl
                    .ifz
                        mov al,CELLCOUNT-1
                    .endif
                    mov [rbx].DOBJ.index,al
                    update_cellid()
                .endif
            .endif
        .endif
    .endif
    mov eax,_C_NORMAL
    ret

event_delete endp


event_load proc

  local path[_MAX_PATH]:sbyte

    .ifd wgetfile(&path, "*.env", _WOPEN)

        _close(eax)
        ReadEnvironment(&path)
        read_environ()
        update_cellid()
    .endif
    mov eax,_C_NORMAL
    ret

event_load endp


event_save proc

  local path[_MAX_PATH]:sbyte

    .ifd wgetfile(&path, "*.env", _WSAVE)

        _close(eax)
        SaveEnvironment(&path)
    .endif
    mov eax,_C_NORMAL
    ret

event_save endp


cmenviron proc public uses rsi rdi rbx

  local cursor:CURSOR
  local ll:LOBJ

    lea rdx,ll
    mov FCB_Environ,rdx
    mov rdi,rdx
    xor eax,eax
    mov ecx,LOBJ
    rep stosb
    mov rdi,rdx

    mov [rdi].LOBJ.dcount,CELLCOUNT
    mov [rdi].LOBJ.lproc,&event_list

    .if malloc((MAXHIT * size_t) + size_t)

        mov [rdi].LOBJ.list,rax

        clrcmdl()
        _getcursor(&cursor)

        .if rsopen(IDD_DZEnviron)

            mov DLG_Environ,rax
            mov rbx,rax

            mov rdi,[rbx].DOBJ.object
            mov [rdi+24*TOBJ].TOBJ.data,&event_keys

            lea rdx,[rdi].TOBJ.tproc
            mov ecx,CELLCOUNT
            lea rax,event_xcell
            .repeat
                mov [rdx],rax
                add rdx,TOBJ
            .untilcxz

            dlshow(rbx)
            mov tdllist,FCB_Environ
            read_environ()
            update_cellid()

            .while rsevent(IDD_DZEnviron, rbx)
                .switch eax
                .case 1..19
                    .break .ifd event_edit() != _C_NORMAL
                    .endc
                .case 20
                    event_add()
                   .endc
                .case 21
                    event_delete()
                   .endc
                .case 22
                    event_load()
                   .endc
                .case 23
                    event_save()
                   .endc
                .endsw
            .endw
            dlclose(rbx)
        .endif

        mov rbx,FCB_Environ
        mov rsi,[rbx].LOBJ.list
        .if rsi
            .for ( edi = 0 : edi < [rbx].LOBJ.count : edi++ )
                free([rsi+rdi*size_t])
            .endf
            free(rsi)
        .endif
    .else
        ermsg(0, _sys_err_msg(ENOMEM))
    .endif
    GetEnvironmentTEMP()
    GetEnvironmentPATH()
    _setcursor(&cursor)
    xor eax,eax
    ret

cmenviron endp

    end
