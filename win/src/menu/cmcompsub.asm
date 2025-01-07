; CMCOMPSUB.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include malloc.inc
include io.inc
include string.inc
include errno.inc
include syserr.inc
include time.inc
include config.inc
include stdlib.inc
include wsub.inc
include tview.inc
include progress.inc

ifdef __WIN95__
define MAXHIT 100000
else
define MAXHIT 500000
endif

.enumt CompareSubIDD : TOBJ {

    OF_MASK = 14,
    OF_SOURCE,
    OF_TARGET,
    OF_SUBD,
    OF_EQUAL,
    OF_DIFFER,
    OF_FIND,
    OF_FILT,
    OF_SAVE,
    OF_GOTO,
    OF_QUIT,
    OF_MSUP,
    OF_MSDN
    }

define ID_FILE 13
define ID_GOTO 22
define OF_GCMD OF_MSUP

.data

GCMD_search GLCMD \
    { KEY_F2,      event_mklist     },
    { KEY_F3,      ff_event_view    },
    { KEY_F4,      ff_event_edit    },
    { KEY_F5,      ff_event_filter  },
    { KEY_F6,      event_path       },
    { KEY_F7,      event_find       },
    { KEY_F8,      event_delete     },
    { KEY_F9,      cmfilter_load    },
    { KEY_F10,     event_advanced   },
    { KEY_DEL,     event_delete     },
    { KEY_ALTX,    ff_event_exit    },
    { KEY_CTRLF6,  event_flip       },
    { 0,           0                }

ff_basedir      LPSTR 0
DLG_FindFile    PDOBJ 0
ff_table        PVOID 0
ff_count        dd 0
ff_recursive    dd 0
source          LPSTR 0
target          LPSTR 0
flags           dd compare_name or compare_time or compare_size or compare_subdir

cp_emaxfb   char_t "This subdirectory contains more",10
            char_t "than %d files/directories.",10
            char_t "Only %d of the files is read.",0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .code

    option proc: private

ff_putcelid proc uses rbx

    mov rbx,DLG_FindFile
    movzx eax,[rbx].DOBJ.index
    .if al >= ID_FILE
        xor eax,eax
    .endif
    inc eax
    mov rdx,tdllist
    add eax,[rdx].LOBJ.index
    mov ecx,[rdx].LOBJ.count
    mov bx,[rbx+4]
    add bx,0x0F03
    mov dl,bh
    scputf(ebx, edx, 0, 0, "[%04d:%04d]", eax, ecx)
    ret

ff_putcelid endp


ff_event_xcell proc

    ff_putcelid()
    dlxcellevent()
    ret

ff_event_xcell endp


ff_getcurobj proc

    xor eax,eax
    mov rdx,tdllist
    .if [rdx].LOBJ.count != eax

        mov eax,[rdx].LOBJ.index
        add eax,[rdx].LOBJ.celoff
        mov rdx,[rdx].LOBJ.list
        lea rdx,[rdx+rax*size_t]
        mov rax,[rdx]
    .endif
    ret

ff_getcurobj endp


ff_alloc proc uses rsi rdi rbx path:LPSTR, fb:PFBLK

    ldr rbx,path
    lea edi,[strlen(rbx)+BLOCKSIZE]

    .if malloc(edi)

        mov rsi,rax
        lea rcx,[rax+FBLK+ZINF]
        mov [rax].FBLK.name,rcx
        strcpy(rcx, rbx)

        mov rbx,tdllist
        mov eax,[rbx].LOBJ.count
ifdef _WIN64
        progress_update(rax)
else
        xor edx,edx
        progress_update(edx::eax)
endif
        mov ecx,eax
        mov eax,[rbx].LOBJ.count
        inc [rbx].LOBJ.count
        mov edx,[rbx].LOBJ.count
        .if edx >= ID_FILE
            mov edx,ID_FILE
        .endif
        mov [rbx].LOBJ.numcel,edx
        mov rbx,[rbx].LOBJ.list
        mov [rbx+rax*size_t],rsi
        mov  rdi,fb
        xchg rdi,rsi
        mov  eax,ecx
        mov  ecx,4
        rep  movsd
        mov  dword ptr [rdi-8],0
        dec  eax
    .endif
    ret

ff_alloc endp


CompareFileData proc uses rsi rdi rbx A:LPSTR, B:LPSTR

  local h1,h2,b1:LPSTR,b2:LPSTR

    mov b1,alloca(0x8000)
    add rax,0x4000
    mov b2,rax

    .repeat

        mov h1,osopen(A, 0, M_RDONLY, A_OPEN)
        .break .if eax == -1
        mov h2,osopen(B, 0, M_RDONLY, A_OPEN)

        .if eax == -1

            _close(h1)
            mov eax,-1
           .break
        .endif

        .while osread(h1, b1, 0x4000)

            mov ebx,eax
            .ifd osread(h2, b2, 0x4000) != ebx

                mov eax,-1
               .break
            .endif
            mov  eax,-1
            mov  ecx,ebx
            mov  rsi,b1
            mov  rdi,b2
            repz cmpsb
           .break .ifnz
        .endw
        mov ebx,eax
        _close(h1)
        _close(h2)
        mov eax,ebx
    .until 1
    ret

CompareFileData endp


ff_fileblock proc uses rsi rdi rbx directory:LPSTR, wfblk:PWIN32_FIND_DATA

  local path[_MAX_PATH*2]:sbyte, result:int_t, found[4]:byte
  local h:int_t, t:uint_t

    xor eax,eax
    mov result,eax

    .repeat

        .break .if eax == ff_count

        mov found,al
        mov rdi,wfblk
        mov edx,MAXHIT
        mov result,edx
        mov rbx,tdllist

        .if [rbx].LOBJ.count >= edx

            stdmsg(&cp_warning, &cp_emaxfb, edx, edx)
            mov result,2
           .break
        .endif

        mov result,eax
        .break .ifd !filter_wblk(rdi)

        add rdi,WIN32_FIND_DATA.cFileName
        strfcat(&path, directory, rdi)
        .break .ifd !strwild(fp_maskp, rdi)

        mov result,test_userabort()
        .break .if eax

        .for rbx = wfblk, edi = ff_count, rsi = ff_table : edi : edi--, rsi += size_t

            .if flags & compare_size ; Compare File Size

                mov rcx,[rsi]
                mov eax,dword ptr [rcx].FBLK.size
                .continue .if eax != [rbx].WIN32_FIND_DATA.nFileSizeLow
                mov eax,dword ptr [rcx].FBLK.size[4]
                .continue .if eax != [rbx].WIN32_FIND_DATA.nFileSizeHigh
            .endif

            .if flags & compare_attrib ; Compare File Attributes

                mov eax,[rcx].FBLK.flag
                .continue .if eax != [rbx].WIN32_FIND_DATA.dwFileAttributes
            .endif

            .if flags & compare_time ; Compare Last modification time

                FileTimeToTime(&[rbx].WIN32_FIND_DATA.ftLastWriteTime)
                mov rcx,[rsi]
               .continue .if eax != [rcx].FBLK.time
            .endif

            .if flags & compare_create ; Compare File creation time

                .ifd osopen([rcx].FBLK.name, 0, M_RDONLY, A_OPEN) != -1

                    mov h,eax
                    mov t,getftime_create(eax)
                    _close(h)
                    FileTimeToTime(&[rbx].WIN32_FIND_DATA.ftCreationTime)
                   .continue .if eax != t
                .endif
                mov rcx,[rsi]
            .endif

            .if flags & compare_access ; Compare Last access time

                .ifd osopen([rcx].FBLK.name, 0, M_RDONLY, A_OPEN) != -1

                    mov h,eax
                    mov t,getftime_access(eax)
                    _close(h)
                    FileTimeToTime(&[rbx].WIN32_FIND_DATA.ftLastAccessTime)
                   .continue .if eax != t
                .endif
                mov rcx,[rsi]
            .endif

            .if flags & compare_name ; Compare File names

                mov rcx,strfn([rcx].FBLK.name)
               .continue .ifd _stricmp(&[rbx].WIN32_FIND_DATA.cFileName, rcx)
                mov rcx,[rsi]
            .endif

            .if flags & compare_data ; Compare File content

                .continue .ifd CompareFileData([rcx].FBLK.name, &path)
                mov rcx,[rsi]
            .endif
            mov found,1
           .break
        .endf

        mov   rax,DLG_FindFile
        movzx eax,[rax].TOBJ.flag[OF_EQUAL]
        and   eax,_O_RADIO

        .break .if eax && !found
        .break .if !eax && found

        .if !ff_alloc(&path, rcx)

            clear_table()
            ermsg(0, _sys_err_msg(ENOMEM))
            mov result,-1
        .endif
    .until 1
    mov eax,result
    ret

ff_fileblock endp


clear_table proc uses rsi rdi

    mov esi,ff_count
    mov rdi,ff_table
    .while esi
        free([rdi])
        add rdi,size_t
        dec esi
    .endw
    mov ff_count,esi
    ret

clear_table endp


clear_list proc uses rsi rdi

    mov rax,tdllist
    mov rdi,[rax].LOBJ.list
    mov esi,[rax].LOBJ.count
    .while esi
        free([rdi])
        add rdi,size_t
        dec esi
    .endw
    xor eax,eax
    mov rdx,tdllist
    mov [rdx].LOBJ.celoff,eax
    mov [rdx].LOBJ.index,eax
    mov [rdx].LOBJ.numcel,eax
    mov [rdx].LOBJ.count,eax
    ret

clear_list endp


ff_addfileblock proc uses rsi rdi rbx directory:LPSTR, wfblk:PWIN32_FIND_DATA

  local path[512]:sbyte
  local fsize:qword

    mov rdi,wfblk
    mov eax,[rdi].WIN32_FIND_DATA.nFileSizeHigh
    mov dword ptr fsize[4],eax
    mov eax,[rdi].WIN32_FIND_DATA.nFileSizeLow
    mov dword ptr fsize,eax

    .ifd filter_wblk(rdi)

        strfcat(&path, directory, &[rdi].WIN32_FIND_DATA.cFileName)
        mov eax,ff_count
        .if eax < MAXHIT

            FileTimeToTime(&[rdi].WIN32_FIND_DATA.ftLastWriteTime)
            mov ecx,eax
            .if fballoc(&path, ecx, fsize, [rdi].WIN32_FIND_DATA.dwFileAttributes)

                mov ecx,ff_count
                inc ff_count
                mov rdx,ff_table
                mov [rdx+rcx*size_t],rax
ifdef _WIN64
                progress_update(rcx)
else
                xor edx,edx
                progress_update(edx::ecx)
endif
            .else
                clear_table()
                ermsg(0, _sys_err_msg(ENOMEM))
                mov eax,1
            .endif
        .else
            stdmsg(&cp_warning, &cp_emaxfb, eax, eax)
            mov eax,2
        .endif
    .endif
    ret

ff_addfileblock endp


clear_slash proc string:LPSTR

    mov rax,string
    mov ecx,[rax+1]
    and ecx,0x00FFFFFF
    .if ecx == 0x5C3A ; ":\"
        mov byte ptr [rax+2],0
    .endif
    ret

clear_slash endp


ff_directory proc uses rbx directory:LPSTR

    mov eax,1
    .if eax != ff_recursive

        mov ebx,strlen(source)
        strlen(directory)
        .if eax >= ebx
            mov eax,ebx
        .endif
        .ifd !_strnicmp(directory, source, eax)
            rsmodal(IDD_DZRecursiveCompare)
        .endif
    .endif
    .if eax
        mov ff_recursive,1
        .ifd !progress_set(0, directory, 0)
            scan_files(directory)
        .endif
    .endif
    ret

ff_directory endp


ffsearchinitpath proc path:LPSTR

    ldr rcx,path
    mov edx,' '
    .if [rcx] == dl
        inc rcx
    .endif
    .if ( byte ptr [rcx] == '"' )
        inc rcx
        mov dl,'"'
    .endif

    mov rax,rcx
    .repeat

        mov dh,[rcx]
        inc rcx
       .return .if !dh
    .until dl == dh
    mov byte ptr [rcx-1],0
    ret

ffsearchinitpath endp


ff_searchpath proc uses rsi rdi rbx directory:LPSTR

  local path[_MAX_PATH]:sbyte
  local len:int_t
  local retval:int_t

    mov ff_basedir,strcpy(&path, directory)
    xor ecx,ecx
    xor ebx,ebx

    .if path == cl

        mov path,'"'
        inc rax
        mov rdx,com_wsub
        strcpy(rax, [rdx].WSUB.path)
    .endif

    .repeat
        ;
        ; Multi search using quotes:
        ; Find Files: ["Long Name.type" *.c *.asm.......]
        ; Location:   ["D:\My Documents" c: f:\doc......]
        ;

        mov ff_basedir,ffsearchinitpath(ff_basedir)
        mov rdi,rcx

        .ifd strlen(rax)

            mov len,eax
            add rax,ff_basedir
            .if byte ptr [rax-1] == '\'
                mov byte ptr [rax-1],0
            .endif
            mov rcx,DLG_FindFile
            mov fp_maskp,[rcx].TOBJ.data[OF_MASK]

            .repeat

                mov fp_maskp,ffsearchinitpath(fp_maskp)
                mov rsi,rcx
                mov retval,edx

                mov rdx,DLG_FindFile
                .if [rdx].TOBJ.flag[OF_SUBD] & _O_FLAGB
                    scan_directory(1, ff_basedir)
                .else
                    fp_directory(ff_basedir)
                .endif

                mov edx,retval
                mov retval,eax
                mov fp_maskp,rsi

                .if dl == '"'
                    mov [rsi-1],dl
                .endif
                .break .if byte ptr [rsi] == 0
                mov [rsi-1],dl
            .until eax
            mov eax,len
        .endif
        mov ff_basedir,rdi
        .break .if retval
        .break .if byte ptr [rsi] == 0
    .until !eax
    .return(retval)

ff_searchpath endp


event_find proc uses rsi rdi rbx

  local cursor:CURSOR

    _getcursor(&cursor)
    _cursoroff()

    clear_table()
    clear_list()

    mov rbx,DLG_FindFile
    dlinit(rbx)
    mov rsi,clear_slash(source)
    clear_slash(target)
    mov fp_directory,&ff_directory
    mov fp_fileblock,&ff_addfileblock
    mov ff_recursive,1

    progress_open("Read Source", 0)
    progress_set(rsi, 0, MAXHIT)
    mov fp_maskp,&cp_stdmask
    mov al,[rbx+OF_SUBD]
    .if al & _O_FLAGB
        scan_directory(1, rsi)
    .else
        ff_directory(rsi)
    .endif
    progress_close()

    xor eax,eax
    mov ff_recursive,eax
    mov fp_fileblock,&ff_fileblock

    .if ff_count != eax && !( [rbx].TOBJ.flag[OF_GOTO] & _O_STATE )

        mov ax,[rbx+4]
        add ax,0x0F03
        mov dl,ah
        scputw(eax, edx, 15, U_LIGHT_HORIZONTAL)

        progress_open("Compare", 0)
        progress_set(target, 0, MAXHIT+2)
        ff_searchpath(target)
        progress_close()
        clear_table()
        mov rdx,tdllist
        mov eax,[rdx].LOBJ.count
        .if eax >= ID_FILE
            mov eax,ID_FILE
        .endif
        mov [rdx].LOBJ.numcel,eax
        update_cellid()
    .endif
    _setcursor(&cursor)
    ret

event_find endp


event_help proc

    view_readme(HELPID_14)
    ret

event_help endp


event_mklist proc uses rsi rdi rbx

    mov rsi,tdllist
    xor eax,eax

    .if [rsi].LOBJ.count != eax

        .ifd mklistidd()

            .for ( edi = 0 : edi < [rsi].LOBJ.count : edi++ )

                mov rdx,[rsi].LOBJ.list
                mov rbx,[rdx+rdi*size_t]
                strfn([rbx].FBLK.name)
                sub rax,[rbx].FBLK.name
                mov mklist.offspath,eax
                mov mklist.offs,0
                mklistadd([rbx].FBLK.name)
            .endf
            _close(mklist.handle)
            mov eax,_C_NORMAL
        .endif
    .endif
    ret

event_mklist endp


event_list proc uses rsi rdi rbx

    dlinit(DLG_FindFile)

    mov rax,DLG_FindFile
    mov ebx,[rax].DOBJ.rc
    add ebx,0x0204
    mov rax,tdllist
    mov edi,[rax].LOBJ.index
    shl edi,(2+size_t/8)
    add rdi,[rax].LOBJ.list
    mov esi,[rax].LOBJ.numcel

    .while esi
        mov rax,[rdi]
        mov dl,bh
        scpath(ebx, edx, 68, [rax].FBLK.name)
        inc bh
        add rdi,size_t
        dec esi
    .endw
    mov eax,1
    ret

event_list endp


update_cellid proc

    ff_putcelid()
    event_list()
    ff_update_cellid()
    ret

update_cellid endp


event_delete proc

    ff_deleteobj()
    update_cellid()
    mov eax,_C_NORMAL
    ret

event_delete endp


event_path proc

    mov rax,panela ; Source - Panel-A
    mov rcx,[rax].PANEL.wsub
    strcpy(source, [rcx].WSUB.path)
    mov rax,panelb ; Target - Panel-B
    mov rcx,[rax].PANEL.wsub
    strcpy(target, [rcx].WSUB.path)
    mov rax,DLG_FindFile
    .if rax
        dlinit(rax)
    .endif
    mov eax,_C_NORMAL
    ret

event_path endp


event_advanced proc

    CompareOptions(&flags)
    mov eax,_C_NORMAL
    ret

event_advanced endp


event_flip proc

    mov rax,DLG_FindFile
    .if rax
        mov rcx,[rax].TOBJ.data[OF_SOURCE]
        mov rdx,[rax].TOBJ.data[OF_TARGET]
        mov [rax].TOBJ.data[OF_SOURCE],rdx
        mov [rax].TOBJ.data[OF_TARGET],rcx
        mov [rax].DOBJ.index,ID_FILE
        dlinit(rax)
        PushEvent(KEY_ENTER)
    .endif
    mov eax,_C_NORMAL
    ret

event_flip endp


ff_event_edit proc uses rbx

    .if ff_getcurobj()

        mov rbx,rax
        dlhide(DLG_FindFile)
        tedit([rbx].FBLK.name, [rbx+FBLK].ZINF.line)
        dlshow(DLG_FindFile)
    .endif
    mov eax,_C_NORMAL
    ret

ff_event_edit endp


ff_event_exit proc

    mov eax,_C_ESCAPE
    ret

ff_event_exit endp


ff_event_view proc

    mov rax,DLG_FindFile
    .if [rax].DOBJ.index < ID_FILE
        .if ff_getcurobj()
            tview([rax].FBLK.name, [rax+FBLK].ZINF.offs) ; .SBLK.offs
        .endif
    .endif
    mov eax,_C_NORMAL
    ret

ff_event_view endp


ff_event_filter proc

    cmfilter()

    mov  rdx,DLG_FindFile
    mov  cx,[rdx+4]
    add  cx,0x1410
    mov  dl,ch
    mov  rax,filter
    test rax,rax
    mov  eax,U_BULLET_OPERATOR
    .ifz
        mov eax,' '
    .endif
    scputw(ecx, edx, 1, eax)
    mov eax,_C_NORMAL
    ret

ff_event_filter endp


ff_update_cellid proc uses rdi rbx

    mov rbx,DLG_FindFile
    mov rdi,tdllist
    mov ecx,ID_FILE
    mov eax,_O_STATE
    .repeat
        add rbx,TOBJ
        or  [rbx],ax
    .untilcxz
    mov rbx,DLG_FindFile
    mov eax,not _O_STATE
    mov ecx,[rdi].LOBJ.numcel
    .while ecx
        add rbx,TOBJ
        and [rbx],ax
        dec ecx
    .endw
    mov eax,_C_NORMAL
    ret

ff_update_cellid endp


ff_deleteobj proc uses rbx

    .if ff_getcurobj()

        .repeat
            mov rcx,[rdx+size_t]
            mov [rdx],rcx
            add rdx,size_t
        .until !rcx

        free(rax)

        mov rbx,tdllist
        dec [rbx].LOBJ.count
        mov eax,[rbx].LOBJ.count
        mov edx,[rbx].LOBJ.index
        mov ecx,[rbx].LOBJ.celoff

        .ifz
            mov edx,eax
            mov ecx,eax
        .else
            .if edx
                mov ebx,eax
                sub ebx,edx
                .if ebx < ID_FILE
                    dec edx
                    inc ecx
                .endif
            .endif
            sub eax,edx
            .if eax >= ID_FILE
                mov eax,ID_FILE
            .endif
            .if ecx >= eax
                dec ecx
            .endif
        .endif

        mov rbx,tdllist
        mov [rbx].LOBJ.index,edx
        mov [rbx].LOBJ.celoff,ecx
        mov [rbx].LOBJ.numcel,eax
        mov rbx,DLG_FindFile

        test eax,eax
        mov al,cl
        .ifz
            mov al,ID_FILE
        .endif
        mov [rbx].DOBJ.index,al
        mov eax,1
    .endif
    ret

ff_deleteobj endp

ff_close proc uses rsi rdi

    mov rdi,tdllist
    mov rsi,[rdi].LOBJ.list
    .if rsi
        mov edi,[rdi].LOBJ.count
        .while edi

            mov rcx,[rsi]
            add rsi,size_t
            free(rcx)
            dec edi
        .endw
        mov rdi,tdllist
        free([rdi].LOBJ.list)
    .endif
    ret

ff_close endp

ff_close_dlg proc uses rsi

    mov byte ptr fsflag,ah
    movzx esi,[rbx].DOBJ.index
    dlclose(rbx)

    .if esi == ID_GOTO

        mov rbx,tdllist
        .if [rbx].LOBJ.count

            .if panel_state(cpanel)

                mov eax,[rbx].LOBJ.index
                add eax,[rbx].LOBJ.celoff
                mov rbx,[rbx].LOBJ.list
                mov rbx,[rbx+rax*size_t]
                mov rbx,[rbx].FBLK.name
                .if strrchr(rbx, '\')
                    mov byte ptr [rax],0
                    cpanel_setpath(rbx)
                .endif
            .endif
        .endif
    .endif
    ret

ff_close_dlg endp

cmcompsub proc PUBLIC uses rsi rdi rbx

  local cursor:CURSOR,
        ll:LOBJ,
        old_thelp:dword,
        fmask[_MAX_PATH]:sbyte,
        tpath[_MAX_PATH]:sbyte,
        spath[_MAX_PATH]:sbyte

    mov target,&tpath
    mov source,&spath
    mov DLG_FindFile,0
    strcpy(&fmask, &cp_stdmask)
    event_path()

    .if CFGetSection(".compsubdir")
        mov rbx,rax
        .if INIGetEntryID(rbx, 0)
            mov flags,__xtol(rax)
        .endif
        .if INIGetEntryID(rbx, 1)
            strcpy(&fmask, rax)
        .endif
        .if INIGetEntryID(rbx, 2)
            strcpy(source, rax)
        .endif
        .if INIGetEntryID(rbx, 3)
            strcpy(target, rax)
        .endif
    .endif

    mov ff_count,0
    mov old_thelp,thelp
    mov thelp,&event_help
    clrcmdl()
    _getcursor(&cursor)
    lea rdx,ll
    mov tdllist,rdx
    mov rdi,rdx
    mov ecx,LOBJ
    xor eax,eax
    rep stosb

    mov [rdx].LOBJ.dcount,ID_FILE
    mov [rdx].LOBJ.lproc,&event_list

    .if malloc((MAXHIT * 8) + 4)

        mov ll.list,rax
        add rax,(MAXHIT*4)+4
        mov ff_table,rax

        .if rsopen(IDD_DZCompareDirectories)

            mov DLG_FindFile,rax
            mov rbx,rax
            mov [rbx].TOBJ.data[OF_GCMD],&GCMD_search
            mov [rbx].TOBJ.count[OF_MASK],256/16
            mov [rbx].TOBJ.count[OF_SOURCE],256/16
            mov [rbx].TOBJ.count[OF_TARGET],256/16
            mov [rbx].TOBJ.data[OF_MASK],&fmask
            mov [rbx].TOBJ.data[OF_SOURCE],source
            mov [rbx].TOBJ.data[OF_TARGET],target
            mov [rbx].TOBJ.tproc[OF_FIND],&event_find
            mov [rbx].TOBJ.tproc[OF_FILT],&ff_event_filter
            mov [rbx].TOBJ.tproc[OF_SAVE],&event_mklist

            mov ecx,flags
            mov al,_O_RADIO
            .if ecx & compare_equal
                or [rbx+OF_EQUAL],al
            .else
                or [rbx+OF_DIFFER],al
            .endif

            and fsflag,not IO_SEARCHSUB
            .if ecx & compare_subdir

                or byte ptr [rbx+OF_SUBD],_O_FLAGB
                or fsflag,IO_SEARCHSUB
            .endif

            lea rdx,[rbx].TOBJ.tproc[TOBJ]
            mov ecx,ID_FILE
            lea rax,ff_event_xcell
            .repeat
                mov [rdx],rax
                add rdx,TOBJ
            .untilcxz

            dlshow(rbx)
            dlinit(rbx)

            mov filter,NULL
            .while rsevent(IDD_DZCompareDirectories, rbx)

                mov esi,eax
                mov edi,ecx
                mov al,[rbx].DOBJ.index
                .if al < ID_FILE
                    .break .if ff_event_view() != _C_NORMAL
                .else
                    .break .if al == ID_GOTO
                    event_find()
                .endif
            .endw

            mov ah,byte ptr fsflag
            and ah,not IO_SEARCHSUB
            and flags,NOT (compare_equal or compare_subdir)
            .if byte ptr [rbx+OF_EQUAL] & _O_RADIO
                or flags,compare_equal
            .endif
            .if byte ptr [rbx+OF_SUBD] & _O_FLAGB
                or flags,compare_subdir
                or ah,IO_SEARCHSUB
            .endif

            ff_close_dlg()
            clear_list()
            clear_table()
        .else
            ermsg(0, _sys_err_msg(ENOMEM))
        .endif
        free(ll.list)
    .endif

    .if CFAddSection(".compsubdir")

        mov rbx,rax
        INIAddEntryX(rbx, "0=%X", flags)
        INIAddEntryX(rbx, "1=%s", &fmask)
        INIAddEntryX(rbx, "2=%s", &spath)
        INIAddEntryX(rbx, "3=%s", &tpath)
    .endif

    _setcursor(&cursor)
    mov thelp,old_thelp
    xor eax,eax
    ret

cmcompsub endp

    end
