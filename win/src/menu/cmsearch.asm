; FILESEARCH.ASM--
; Copyright (C) 2019 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include tview.inc
include malloc.inc
include io.inc
include dzstr.inc
include stdio.inc
include errno.inc
include syserr.inc
include wsub.inc
include FileSearch.inc
include progress.inc

GetPathFromHistory proto :ptr

.enum {
    OUTPUT_BINARY,  ; Binary dump (default)
    OUTPUT_TEXT,    ; Convert tabs, CR/LF
    OUTPUT_LINE,    ; Convert tabs, break on LF
    OUTPUT_MASK,
    SINGLE_FILE     ; One hit file per file
    }

.enumt FileSearchIDD : TOBJ {
    O_FILE = 13,
    O_MASK,
    O_LOCATION,
    O_STRING,
    O_SUBDIR,
    O_CASE,
    O_HEX,
    O_START,
    O_FILTER,
    O_SAVE,
    O_GOTO,
    O_REPLACE,
    O_QUIT,
    O_GCMD
    }

.enum {
    ID_FILE = 12,
    ID_MASK,
    ID_LOCATION,
    ID_STRING,
    ID_SUBDIR,
    ID_CASE,
    ID_HEX,
    ID_START,
    ID_FILTER,
    ID_SAVE,
    ID_GOTO,
    ID_REPLACE,
    ID_QUIT,
    ID_MOUSEUP,
    ID_MOUSEDN,
    ID_GCMD = ID_MOUSEUP
    }

.enumt FFReplaceIDD : TOBJ {
    O_NEWSTRING = 1,
    O_CREATEBACUP,
    O_USEESCAPE,
    }

.enum {
    ID_NEWSTRING,
    ID_CREATEBACUP,
    ID_USEESCAPE,
    ID_OK,
    ID_CANCEL,
    }

    .data

    ff ptr FileSearch 0

    GlobalKeys GLCMD \
        { KEY_F2,     EventProc }, ; List
        { KEY_F3,     EventProc }, ; View
        { KEY_F4,     EventProc }, ; Edit
        { KEY_F5,     EventProc }, ; Filter
        { KEY_F6,     EventProc }, ; Hex
        { KEY_F7,     EventProc }, ; Find
        { KEY_F8,     EventProc }, ; Delete
        { KEY_F9,     EventProc }, ; Load
        { KEY_F10,    EventProc }, ; Format
        { KEY_F11,    EventProc }, ; Path
        { KEY_F12,    EventProc }, ; Single file
        { KEY_DEL,    EventProc }, ; Delete
        { KEY_ALTR,   EventProc }, ; Replace
        { KEY_ALTX,   EventProc }, ; Quit
        { 0,          0         }

    .code

    option proc: private

    assume rsi:PDOBJ
    assume rbx:ptr FileSearch

FileSearch::PutCellId proc uses rsi rdi rbx

    ldr rbx,this
    mov rsi,[rbx].dialog

    movzx eax,[rsi].index
    .if al > ID_FILE
        xor eax,eax
    .endif
    inc   eax
    add   eax,[rbx].ll.index
    mov   ecx,[rbx].ll.count
    movzx edi,[rsi].DOBJ.rc.y
    movzx ebx,[rsi].DOBJ.rc.x
    add   ebx,3
    add   edi,15

    .ifd ( scputf(ebx, edi, 0, 0, "[ %u:%u ]", eax, ecx) < 13 )

        add ebx,eax
        mov ecx,13
        sub ecx,eax
        scputc(ebx, edi, ecx, U_LIGHT_HORIZONTAL)
    .endif
    ret

FileSearch::PutCellId endp


FileSearch::UpdateCell proc uses rbx

    ldr rbx,this
    [rbx].PutCellId()
    [rbx].List()
    .for ( rdx = [rbx].dialog,
           eax = _O_STATE,
           ecx = 0 : ecx <= ID_FILE : ecx++, rdx += TOBJ )
        or [rdx+TOBJ].TOBJ.flag,ax
    .endf
    .for ( rdx = [rbx].dialog,
           eax = not _O_STATE,
           ecx = [rbx].ll.numcel : ecx : ecx--, rdx += TOBJ )
        and [rdx+TOBJ].TOBJ.flag,ax
    .endf
    .return(_C_NORMAL)

FileSearch::UpdateCell endp


FileSearch::CurItem proc uses rbx

    ldr rbx,this
    xor eax,eax

    .if ( [rbx].ll.count )

        mov eax,[rbx].ll.index
        add eax,[rbx].ll.celoff
        mov rdx,[rbx].ll.list
        lea rdx,[rdx+rax*size_t]
        mov rax,[rdx]
    .endif
    ret

FileSearch::CurItem endp


FileSearch::CurFile proc

    .if this.CurItem()

        mov rax,[rax].FBLK.name
    .endif
    ret

FileSearch::CurFile endp


CallbackFile proc private uses rsi rdi rbx directory:string_t, wfblk:PWIN32_FIND_DATA

  local path[_MAX_PATH*2]:byte
  local fblk:PFBLK, offs, line, fbsize, ioflag, result, user
  local maxhit:int_t

    mov rbx,ff
    ldr rdi,wfblk

    mov eax,FFMAXHIT
    mov result,eax
    .if ffflag & SINGLE_FILE
        mov eax,1
    .endif
    mov maxhit,eax

    xor eax,eax
    mov offs,eax
    mov line,eax
    mov STDI.line,eax
    xor esi,esi

    .if ( [rbx].ll.count < FFMAXHIT )

        mov result,eax
        .ifd filter_wblk(rdi)

            add rdi,WIN32_FIND_DATA.cFileName
            strfcat(&path, directory, rdi)
            mov result,test_userabort()

            .if !eax
                .if directory
                    .ifd strwild(fp_maskp, rdi)
                        inc esi
                    .endif
                .else
                    mov result,-1
                .endif
            .endif
        .endif
    .endif

    .if esi

        xor esi,esi
        cmp searchstring,0
        je  found

        mov rdx,wfblk
        mov esi,osopen(&path, [rdx].WIN32_FIND_DATA.dwFileAttributes, M_RDONLY, A_OPEN)
        mov STDI.file,eax

        inc eax
        .ifnz ; @v2.33 -- continue seacrh if open fails..

            mov rcx,wfblk
            mov eax,[rcx].WIN32_FIND_DATA.nFileSizeLow
            mov edx,[rcx].WIN32_FIND_DATA.nFileSizeHigh
            mov STDI.fsize_l,eax
            mov STDI.fsize_h,edx

            xor eax,eax
            .if edx == eax  ; No search above 4G...

                mov STDI.offs_l,eax
                mov STDI.offs_h,eax
                mov STDI.flag,IO_RETURNLF
                mov STDI.index,eax
                mov STDI.cnt,eax
                ioread(&STDI)

                mov eax,STDI.cnt
                .if STDI.fsize_l <= eax
                    or STDI.flag,IO_MEMBUF
                .endif

                xor eax,eax
                mov rdx,[rbx].dialog
                .if [rdx].TOBJ.flag[O_CASE] & _O_FLAGB
                    or STDI.flag,IO_SEARCHCASE
                .endif
                .if [rdx].TOBJ.flag[O_HEX] & _O_FLAGB
                    or STDI.flag,IO_SEARCHHEX
                .endif

                .repeat

                    oseek(eax, SEEK_SET)
                    .break .if eax == -1

                    mov STDI.offs_l,eax
                    mov STDI.offs_h,edx
                    or  STDI.flag,IO_SEARCHCUR
                    .break .if !searchstring
                    .break .ifd osearch() == -1

                    mov offs,eax
                    mov line,ecx

                found:

                    lea edi,[strlen(&path)+BLOCKSIZE]
                    .if !malloc(edi)

                        dec eax
                        mov result,eax
                       .break
                    .endif

                    mov fblk,memset(rax, 0, edi)
                    lea rcx,[rax+FBLK+ZINF]
                    mov [rax].FBLK.name,rcx
                    strcpy(rcx, &path)

                    mov eax,[rbx].ll.count
ifdef _WIN64
                    mov user,progress_update(rax)
else
                    xor edx,edx
                    mov user,progress_update(edx::eax)
endif
                    mov eax,[rbx].ll.count
                    inc [rbx].ll.count
                    mov edx,[rbx].ll.count
                    .if edx > ID_FILE+1
                        mov edx,ID_FILE+1
                    .endif
                    mov [rbx].ll.numcel,edx
                    mov rdx,[rbx].ll.list

                    mov rcx,fblk
                    mov [rdx+rax*size_t],rcx
                    mov [rcx+FBLK].ZINF.size,edi
                    mov [rcx+FBLK].ZINF.line,line
                    mov [rcx+FBLK].ZINF.offs,offs

                    mov eax,user
                    .if eax ; user abort
                        mov result,eax
                       .break
                    .endif

                    strlen([rbx].basedir)
                    mov rcx,fblk
                    inc eax
                    mov [rcx+FBLK].ZINF.base,eax

                    .break .if !esi

                    oseek(offs, SEEK_SET)

                    mov rax,fblk
                    lea rax,[rax+rdi-INFOSIZE]
                    oreadb(rax, INFOSIZE-1)

                    mov eax,offs
                    inc eax
                    .if eax >= dword ptr STDI.fsize
                        mov eax,dword ptr STDI.fsize
                    .endif
                    oseek(eax, SEEK_SET)

                    .break .if result

                    mov ecx,maxhit
                .until [rbx].ll.count >= ecx

            .endif
            .if esi
                _close(esi)
            .endif
        .endif
    .endif
    .return(result)

CallbackFile endp


CallbackDirectory proc private directory:string_t

    .ifd !progress_set(0, directory, 0)

        scan_files(directory)
    .endif
    ret

CallbackDirectory endp


InitPath proc directory:string_t

    ldr rcx,directory ; *.asm *.inc C: D:
    mov edx,' '       ; seperator assumed space
    .if [rcx] == dl
        add rcx,1     ; next item
    .endif
    .if ( byte ptr [rcx] == '"' )
        inc rcx
        mov dl,'"'    ; seperator is quote
    .endif

    mov rax,rcx       ; start of item
    .repeat

        mov dh,[rcx]
        inc rcx
        .return .if !dh
    .until dh == dl
    mov byte ptr [rcx-1],0
    ret

InitPath endp


FileSearch::Searchpath proc uses rsi rdi rbx directory:string_t

  local path[_MAX_PATH]:byte, retval:int_t, length:int_t

    ldr rbx,this
    mov [rbx].basedir,strcpy(&path, directory)
    xor ecx,ecx
    mov retval,ecx

    .if ( path == cl )

        mov path,'"'
        inc rax
        mov rdx,com_wsub
        strcpy(rax, [rdx].WSUB.path)
    .endif

    .repeat

        ; Multi search using quotes:
        ; Find Files: ["Long Name.type" *.c *.asm.......]
        ; Location:   ["D:\My Documents" c: f:\doc......]

        mov [rbx].basedir,InitPath([rbx].basedir)
        mov rdi,rcx

        .ifd strlen(rax)
            mov length,eax
            add rax,[rbx].basedir
            .if byte ptr [rax-1] == '\'
                mov byte ptr [rax-1],0
            .endif

            mov rcx,[rbx].dialog
            mov fp_maskp,[rcx].TOBJ.data[O_MASK]

            .repeat

                mov fp_maskp,InitPath(fp_maskp)
                mov rsi,rcx
                mov retval,edx

                mov rdx,[rbx].dialog
                .if [rdx].TOBJ.flag[O_SUBDIR] & _O_FLAGB
                    scan_directory(1, [rbx].basedir)
                .else
                    fp_directory([rbx].basedir)
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
            mov eax,length
        .endif
        mov [rbx].basedir,rdi

        .break .if retval
        .break .if byte ptr [rdi] == 0
    .until !eax
    .return(retval)

FileSearch::Searchpath endp


FileSearch::Find proc uses rsi rdi rbx

  local cursor:CURSOR

    mov fp_directory,&CallbackDirectory
    mov fp_fileblock,&CallbackFile

    mov STDI.size,4096 ; default to _bufin
    mov STDI.base,&_bufin

    .if malloc(0x800000)

        mov STDI.base,rax
        mov STDI.size,0x800000
    .endif

    mov rbx,this
    mov rdx,[rbx].dialog

    .if !( [rdx].TOBJ.flag[O_GOTO] & _O_STATE )

        _getcursor(&cursor)
        _cursoroff()
        [rbx].ClearList()
        dlinit( [rbx].dialog )
        mov rdx,[rbx].dialog
        mov ax,[rdx+4]
        add ax,0x0F03
        mov dl,ah
        scputw(eax, edx, 11, U_MIDDLE_DOT)
        progress_open("Search", 0)

        mov rdx,[rbx].dialog
        mov rdi,[rdx].TOBJ.data[O_LOCATION]

        progress_set(rdi, 0, FFMAXHIT+2)
        [rbx].Searchpath(rdi)
        progress_close()

        _setcursor(&cursor)

        mov eax,[rbx].ll.count
        .if eax > ID_FILE+1
            mov eax,ID_FILE+1
        .endif
        mov [rbx].ll.numcel,eax
        [rbx].UpdateCell()
    .endif

    .if STDI.size != 4096

        free(STDI.base)
    .endif

    memset(&STDI, 0, IOST)
    ret

FileSearch::Find endp


define FILEBUF 0x8000

FileSearch::Replace proc uses rsi rdi rbx backup:int_t, escape:int_t

   .new curfile:string_t
   .new tmpfile:string_t
   .new bakfile:string_t
   .new readbuf:string_t
   .new srchandle:int_t
   .new tmphandle:int_t
   .new index:int_t = 0
   .new size:uint_t
   .new offs:uint_t
   .new lenstr1:int_t
   .new lenstr2:int_t
   .new replace[256]:char_t

    ldr rbx,this
    ldr edi,escape

    .if !malloc(FILEBUF*3)
        .return
    .endif
    mov tmpfile,rax
    add rax,FILEBUF
    mov bakfile,rax
    add rax,FILEBUF
    mov readbuf,rax

    .if ( edi )
        stresc(&replace, &replacestring)
    .else
        strlen(strcpy(&replace, &replacestring))
    .endif
    mov lenstr2,eax
    mov lenstr1,strlen(&searchstring)

    .for ( rdi = [rbx].ll.list : index < [rbx].ll.count : index++ )

        mov rdx,[rdi]
        mov offs,[rdx+FBLK].ZINF.offs
        mov rax,[rdx].FBLK.name
        mov curfile,rax
        strcpy(bakfile, strcpy(tmpfile, rax))

        .ifd ( osopen(curfile, 0, M_RDONLY, A_OPEN) == -1 )
            .break
        .endif
        mov srchandle,eax
        .ifd ( osopen(strfxcat(tmpfile, ".$$$"), 0, M_WRONLY, A_CREATETRUNC) == -1 )
            _close(srchandle)
            .break
        .endif
        mov _diskflag,1
        mov tmphandle,eax
        xor esi,esi

        .while 1

            .for ( : esi < offs : )

                mov eax,offs
                sub eax,esi
                .if ( eax > FILEBUF )
                    mov eax,FILEBUF
                .endif
                add esi,eax
                mov size,eax
               .break .if ( eax == 0 )
               .break .ifd ( osread(srchandle, readbuf, size) != size )
               .break .ifd ( oswrite(tmphandle, readbuf,size) != size )
            .endf
            add esi,lenstr1
            osread(srchandle, readbuf, lenstr1)
            .if ( lenstr2 )
                oswrite(tmphandle, &replace, lenstr2)
            .endif
            add rdi,size_t
            mov ecx,index
            inc ecx
            mov eax,1
            .if ( ecx < [rbx].ll.count )

                mov rdx,[rdi]
                mov offs,[rdx+FBLK].ZINF.offs
                strcmp(curfile, [rdx].FBLK.name)
            .endif
            .if ( eax )

                .while 1
                    .break .ifd ( osread(srchandle, readbuf, FILEBUF) == 0 )
                    .break .ifd ( oswrite(tmphandle, readbuf, eax) == 0 )
                .endw
                .break
            .endif
            inc index
        .endw
        _close(srchandle)
        _close(tmphandle)
        .if ( backup )
            remove(strfxcat(bakfile, ".bak"))
            rename(curfile, bakfile)
        .else
            remove(curfile)
        .endif
        rename(tmpfile, curfile)
    .endf
    free(tmpfile)
    ret

FileSearch::Replace endp


FileSearch::Modal proc uses rbx

    ldr rbx,this
    mov filter,0

    .while rsevent(IDD_DZFindFile, [rbx].dialog)

        mov rdx,[rbx].dialog
        movzx eax,[rdx].DOBJ.index
        .if eax <= ID_FILE

            .break .if [rbx].WndProc(KEY_F3) != _C_NORMAL
        .else
            .break .if eax == ID_GOTO
            [rbx].Find()
        .endif
    .endw
    ret

FileSearch::Modal endp

    assume rsi:nothing

FileSearch::List proc uses rsi rdi rbx

   .new x:int_t, y:int_t, cnt:int_t, i:int_t, n:int_t, c:int_t

    mov rbx,this

    dlinit([rbx].dialog)

    mov     rcx,[rbx].dialog
    movzx   eax,[rcx].DOBJ.rc.x
    add     eax,4
    mov     x,eax
    movzx   eax,[rcx].DOBJ.rc.y
    add     eax,2
    mov     y,eax

    .for edi = [rbx].ll.index,
         edi <<= (2 + (size_t / 8)),
         rdi += [rbx].ll.list,
         cnt = [rbx].ll.numcel : cnt : y++, cnt--, rdi+=size_t

        mov rsi,[rdi]
        mov eax,[rsi+FBLK].ZINF.base
        add rax,[rsi].FBLK.name
        scpath(x, y, 25, rax)

        add eax,x
        mov edx,[rsi+FBLK].ZINF.line
        .if edx
            inc edx ; append (<line>) to filename
            mov ecx,eax
            scputf(ecx, y, 0, 7, "(%u)", edx)
        .endif

        mov eax,x
        add eax,33
        mov i,eax
        mov eax,[rsi+FBLK].ZINF.size
        lea rsi,[rsi+rax-INFOSIZE]

        .for ( n = 36 : n : n--, i++ )

            lodsb
            .if ffflag & OUTPUT_LINE

                .break .if al == 10
                .break .if al == 13
            .endif

            movzx eax,al
            .if ( ffflag & ( OUTPUT_LINE or OUTPUT_TEXT ) ) && ( al == 9 || al == 10 || al == 13 )

                mov c,eax
                mov eax,'\'
                scputc(i, y, 1, eax)
                inc i
                mov eax,'t'
                .if c == 13
                    mov al,'n'
                .endif
                .if c == 10
                    mov al,'r'
                .endif
                dec n
               .break .ifz
            .endif
            .if eax
                scputc(i, y, 1, eax)
            .endif
        .endf
    .endf
    mov eax,1
    ret

FileSearch::List endp


FileSearch::ClearList proc uses rsi rdi rbx

    ldr rbx,this
    .for ( rsi=[rbx].ll.list, edi=[rbx].ll.count : edi : edi-- )
        free([rsi+rdi*size_t])
    .endf
    xor eax,eax
    mov [rbx].ll.celoff,eax
    mov [rbx].ll.index,eax
    mov [rbx].ll.numcel,eax
    mov [rbx].ll.count,eax
    ret

FileSearch::ClearList endp


FileSearch::Release proc uses rdi rbx

    ldr rbx,this
    mov thelp, [rbx].oldhelp
    mov ff,    [rbx].oldff
    _setcursor(&[rbx].cursor)

    mov rdx,[rbx].dialog
    .if rdx

        xor eax,eax
        .if [rdx].TOBJ.flag[O_CASE] & _O_FLAGB
            or eax,IO_SEARCHCASE
        .endif
        .if [rdx].TOBJ.flag[O_HEX] & _O_FLAGB
            or eax,IO_SEARCHHEX
        .endif
        .if [rdx].TOBJ.flag[O_SUBDIR] & _O_FLAGB
            or eax,IO_SEARCHSUB
        .endif
        mov ecx,fsflag
        and ecx,not (IO_SEARCHCASE or IO_SEARCHHEX or IO_SEARCHSUB)
        or  eax,ecx
        mov fsflag,eax

        movzx edi,[rdx].DOBJ.index
        dlclose(rdx)

        .if ( edi == ID_GOTO )

            .if ( [rbx].ll.count )

                .if panel_state(cpanel)

                    mov eax,[rbx].ll.index
                    add eax,[rbx].ll.celoff
                    mov rdi,[rbx].ll.list
                    mov rdi,[rdi+rax*size_t]
                    mov rdi,[rdi].FBLK.name

                    .if strrchr(rdi, '\')

                        mov byte ptr [rax],0
                        cpanel_setpath(rdi)
                    .endif
                .endif
            .endif
        .endif
    .endif
    [rbx].ClearList()
    free(rbx)
    ret

FileSearch::Release endp

    assume rsi:PDOBJ

FileSearch::WndProc proc uses rsi rdi rbx cmd:uint_t

    ldr rbx,this
    ldr ecx,cmd
    mov eax,_C_NORMAL

    .switch ecx

    .case KEY_F2
        xor eax,eax
        .if ( [rbx].ll.count )

            .ifd mklistidd()

                .for ( rsi = [rbx].ll.list,
                       edi = 0 : edi < [rbx].ll.count : edi++ )

                    mov rdx,[rsi+rdi*size_t]
                    mov mklist.offspath,[rdx+FBLK].ZINF.base
                    mov mklist.offs,[rdx+FBLK].ZINF.offs
                    mklistadd([rdx].FBLK.name)
                .endf
                _close(mklist.handle)
                mov eax,_C_NORMAL
            .endif
        .endif
        .return

    .case KEY_F3
        mov rsi,[rbx].dialog
        .if ( [rsi].index > ID_FILE )
            .return
        .endif
        .if [rbx].CurItem()

            mov rdi,rax
            tview([rdi].FBLK.name, [rdi+FBLK].ZINF.offs)
        .endif
        .return(_C_NORMAL)

    .case KEY_F4
        .if [rbx].CurItem()

            mov rdi,rax
            mov rbx,[rbx].dialog
            dlhide(rbx)
            tedit([rdi].FBLK.name, [rdi+FBLK].ZINF.line)
            dlshow(rbx)
        .endif
        .return(_C_NORMAL)

    .case KEY_F5
        cmfilter()
        mov rdx,[rbx].dialog
        movzx ecx,[rdx].DOBJ.rc.x
        movzx edx,[rdx].DOBJ.rc.y
        add ecx,16
        add edx,20
        mov eax,U_BULLET_OPERATOR
        .if !filter
            mov eax,' '
        .endif
        scputw(ecx, edx, 1, eax)
       .return(_C_NORMAL)

    .case KEY_F6
        mov eax,_C_NORMAL
        mov rsi,[rbx].dialog
        .if ( [rsi].index == ID_STRING )
            xor [rsi].flag[O_HEX],_O_FLAGB
        .elseif ( [rsi].index != ID_HEX )
            .return _C_NORMAL
        .endif

        mov rdi,[rsi].wp[O_STRING]
        .if ( [rsi].flag[O_HEX] & _O_FLAGB )
            .ifd strlen(rdi)
                .if eax < 128 / 2
                    btohex(rdi, eax)
                .endif
            .endif
        .else
            hextob(rdi)
        .endif
        .return [rbx].List()

    .case KEY_F7
        .return [rbx].Find()

    .case KEY_F8
    .case KEY_DEL
        .if [rbx].CurItem()

            .repeat
                mov rcx,[rdx+size_t]
                mov [rdx],rcx
                add rdx,size_t
            .until !rcx
            free(rax)

            dec [rbx].ll.count
            mov eax,[rbx].ll.count
            mov edx,[rbx].ll.index
            mov ecx,[rbx].ll.celoff
            .ifz
                mov edx,eax
                mov ecx,eax
            .else
                .if edx
                    mov esi,eax
                    sub esi,edx
                    .if esi < ID_FILE+1
                        dec edx
                        inc ecx
                    .endif
                .endif
                sub eax,edx
                .if eax >= ID_FILE+1
                    mov eax,ID_FILE+1
                .endif
                .if ecx >= eax
                    dec ecx
                .endif
            .endif
            mov [rbx].ll.index,edx
            mov [rbx].ll.celoff,ecx
            mov [rbx].ll.numcel,eax
            mov rsi,[rbx].dialog
            test eax,eax
            mov al,cl
            .ifz
                mov al,ID_FILE+1
            .endif
            mov [rsi].index,al
            [rbx].List()
           .return(_C_NORMAL)
        .endif
        .return

    .case KEY_F9
        .return cmfilter_load()

    .case KEY_F10
        mov eax,ffflag
        .if eax & OUTPUT_LINE
            and eax,not (OUTPUT_TEXT or OUTPUT_LINE)
        .elseif eax & OUTPUT_TEXT
            and eax,not (OUTPUT_TEXT or OUTPUT_LINE)
            or  eax,OUTPUT_LINE
        .else
            or eax,OUTPUT_TEXT
        .endif
        mov ffflag,eax
       .return [rbx].List()

    .case KEY_F11
        .if GetPathFromHistory(cpanel)

            mov rcx,[rbx].dialog
            mov rcx,[rcx].TOBJ.data[O_LOCATION]
            strcpy(rcx, [rax].DIRECTORY.path)
            dlinit([rbx].dialog)
            mov eax,_C_NORMAL
        .endif
        .return

    .case KEY_F12
        xor ffflag,SINGLE_FILE
        mov rdx,[rbx].dialog
        movzx ecx,[rdx].DOBJ.rc.x
        movzx edx,[rdx].DOBJ.rc.y
        add ecx,3
        add edx,16
        mov eax,' '
        .if ( ffflag & SINGLE_FILE )
            mov eax,U_BULLET_OPERATOR
        .endif
        scputw(ecx, edx, 1, eax)
       .return(_C_NORMAL)

    .case KEY_ALTR
        .if ( [rbx].ll.count == 0 )

            stdmsg("Replace", "Nothing to do")
           .return(_C_NORMAL)
        .endif
        .if rsopen(IDD_FFReplace)

            mov rsi,rax
            mov [rsi].count[O_NEWSTRING],256 shr 4
            lea rax,replacestring
            mov [rsi].wp[O_NEWSTRING],rax
            ;or [rdx].TOBJ.flag[O_CREATEBACUP],_O_FLAGB
            dlinit(rsi)
            dlshow(rsi)

            movzx ecx,[rsi].rc.x
            movzx edx,[rsi].rc.y
            add ecx,11
            add edx,2
            scputf(ecx, edx, 0, 0, "%d occurrence(s) of", [rbx].ll.count)
            movzx ecx,[rsi].rc.x
            movzx edx,[rsi].rc.y
            add ecx,3
            add edx,3
            scpath(ecx, edx, 10, &searchstring)

            .ifd rsevent(IDD_FFReplace, rsi)

                movzx edx,[rsi].flag[O_CREATEBACUP]
                movzx ecx,[rsi].flag[O_USEESCAPE]
                and edx,_O_FLAGB
                and ecx,_O_FLAGB
                this.Replace(edx, ecx)
            .endif
            dlclose(rsi)
        .endif
        .return(_C_NORMAL)

    .case KEY_ALTX
        mov eax,_C_ESCAPE
    .endsw
    ret

FileSearch::WndProc endp


EventXCell proc

    ff.PutCellId()
    dlxcellevent()
    ret

EventXCell endp

EventList proc

    ff.List()
    ret

EventList endp

EventFind proc

    ff.Find()
    ret

EventFind endp

EventHelp proc

    rsmodal(IDD_DZFFHelp)
    ret

EventHelp endp

EventProc proc

    ff.WndProc(eax)
    ret

EventProc endp

EventFilter proc

    ff.WndProc(KEY_F5)
    ret

EventFilter endp

EventHex proc

    .ifd dlcheckevent() == KEY_SPACE

        ff.WndProc(KEY_F6)
    .endif
    ret

EventHex endp

EventSave proc

    ff.WndProc(KEY_F2)
    ret

EventSave endp

EventReplace proc

    ff.WndProc(KEY_ALTR)
    ret

EventReplace endp

FileSearch::FileSearch proc uses rsi rdi rbx directory:string_t

    .if !malloc( FileSearch + FileSearchVtbl + FFMAXHIT * size_t + size_t )

        ermsg(0, _sys_err_msg(ENOMEM))
       .return 0
    .endif

    mov rbx,rax
    mov rdi,rax
    mov ecx,( ( FileSearch + FileSearchVtbl + FFMAXHIT * size_t + size_t ) / 4 )
    xor eax,eax
    rep stosd

    lea rax,[rbx+FileSearch]
    mov [rbx].lpVtbl,rax
    mov [rbx].oldhelp,thelp
    mov [rbx].oldff,ff

    mov thelp,&EventHelp
    mov ff,rbx

    lea rdi,[rbx].ll
    mov tdllist,rdi

    mov rdi,[rbx].lpVtbl
    lea rax,[rdi+FileSearchVtbl]
    mov [rbx].ll.list,rax

    for m,<Release,WndProc,Find,Modal,PutCellId,UpdateCell,CurItem,\
           CurFile,List,ClearList,Searchpath,Replace>
        mov [rdi].FileSearchVtbl.m,&FileSearch_&m&
        endm

    mov [rbx].ll.dcount,ID_FILE+1
    mov [rbx].ll.lproc,&EventList

    clrcmdl()
    _getcursor(&[rbx].cursor)

    mov [rbx].dialog,rsopen(IDD_DZFindFile)
    .if eax == NULL

        [rbx].Release()
        ermsg(0, _sys_err_msg(ENOMEM))
       .return 0
    .endif

    assume rdi:ptr TOBJ

    mov rdi,rax
    mov [rdi].data[O_GCMD],&GlobalKeys

    lea rcx,findfilemask
    mov [rdi].data[O_MASK],rcx

    .if ( byte ptr [rcx] == 0 )
        strcpy(rcx, &cp_stdmask)
    .endif

    mov [rdi].data[O_STRING],&searchstring
    mov [rdi].data[O_LOCATION],directory
    mov [rdi].tproc[O_HEX],&EventHex
    mov [rdi].tproc[O_START],&EventFind
    mov [rdi].tproc[O_FILTER],&EventFilter
    mov [rdi].tproc[O_SAVE],&EventSave
    mov [rdi].tproc[O_REPLACE],&EventReplace

    mov eax,fsflag
    .if eax & IO_SEARCHCASE
        or [rdi].flag[O_CASE],_O_FLAGB
    .endif
    .if eax & IO_SEARCHHEX
        or [rdi].flag[O_HEX],_O_FLAGB
    .endif
    .if eax & IO_SEARCHSUB
        or [rdi].flag[O_SUBDIR],_O_FLAGB
    .endif
    .for ( rdx = &[rdi].tproc[TOBJ],
           rax = &EventXCell,
           ecx = 0 : ecx <= ID_FILE : ecx++, rdx+=TOBJ )
        mov [rdx],rax
    .endf
    and ffflag,OUTPUT_MASK

    dlshow(rdi)
    dlinit(rdi)
    mov rax,rbx
    ret

FileSearch::FileSearch endp


FindFile proc public directory:string_t

    .new this:ptr FileSearch(directory)

    .if ( rax )

        this.Modal()
        this.Release()
        mov eax,1
    .endif
    ret

FindFile endp


cmsearch proc public

    FindFile(&findfilepath)
    ret

cmsearch endp

    end
