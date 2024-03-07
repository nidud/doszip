include doszip.inc
include conio.inc
include io.inc
include malloc.inc
include direct.inc
include string.inc
include stdio.inc
include stdlib.inc
include errno.inc
include ltype.inc
include config.inc

    .data
     tinfo          PTINFO 0
     new_id         UINT 0
     tiupdate_line  UINT -1
     tiupdate_offs  UINT -1
     old_boff       UINT 0
     old_loff       UINT 0
     tisearch_off   UINT 0
     tisearch_line  UINT 0
     sflag          UINT 0
     QuickMenuKeys  UINT \
        KEY_CTRLDEL,
        KEY_CTRLINS, ; KEY_CTRLC
        KEY_CTRLV,
        KEY_CTRLA,
        KEY_ALT0,
        KEY_F5,
        KEY_ESC,
        KEY_CTRLX,
        KEY_F7
     cp_typech      BYTE "aoqdcsbwn",0

    .code

;
; Validate tinfo
; return CX .flags, DX .dl_flag, AX dialog
;
tistate proc ti:PTINFO

    mov rdx,ti
    xor eax,eax
    .if rdx

        mov ecx,[rdx].TINFO.flags
        lea rdx,[rdx].TINFO.dobj

        .if ecx & _T_TEDIT

            mov rax,rdx
            movzx edx,[rdx].DOBJ.flag
        .endif
    .endif
    ret

tistate endp

;-----------------------------------------------------------------------------
; Alloc file buffer
;-----------------------------------------------------------------------------

    assume rsi:PTINFO

tialloc proc private uses rsi ti:PTINFO

    mov rsi,ti

    mov eax,[rsi].bsize
    add eax,TIMAXLINE*2+_MAX_PATH*2+STYLESIZE

    .if malloc(eax)

        or  [rsi].flags,_T_MALLOC or _T_TEDIT
        mov [rsi].base,rax
        mov ecx,[rsi].bsize
        add rax,rcx
        mov [rsi].lptr,rax
        add rax,TIMAXLINE*2
        mov [rsi].style,rax
        add rax,STYLESIZE
        mov [rsi].file,rax
        mov eax,1
    .else

        ermsg(0, _sys_errlist[ENOMEM*size_t])
        xor eax,eax
    .endif
    ret

tialloc endp

tifree proc private uses rsi ti:PTINFO

    mov rsi,ti
    mov eax,[rsi].flags
    .if eax & _T_MALLOC
        xor eax,_T_MALLOC
        mov [rsi].flags,eax
        free([rsi].base)
    .endif
    ret

tifree endp

tirealloc proc private uses rsi rdi rbx ti:PTINFO

    mov rsi,ti
    mov rdi,[rsi].base
    mov ebx,[rsi].bsize
    add [rsi].bsize,TIMAXFILE

    .if !tialloc(rsi)
        mov [rsi].bsize,ebx
    .else
        memcpy([rsi].base, rdi, ebx)
        add rbx,rdi
        memcpy([rsi].lptr, rbx, TIMAXLINE * 2 + _MAX_PATH * 2 + STYLESIZE)
        free(rdi)
        sub [rsi].flptr,rdi
        mov rax,[rsi].base
        add [rsi].flptr,rax
        mov rax,rdi
    .endif
    ret

tirealloc endp

    assume rsi:nothing

timemzero proc private uses rdi ti:PTINFO

    mov rax,ti
    mov ecx,[rax].TINFO.bsize
    mov rdx,[rax].TINFO.base
    mov rdi,rdx
    add ecx,TIMAXLINE*2
    xor eax,eax
    rep stosb
    mov rax,rdx
    ret

timemzero endp

    assume rdx:PTINFO

;------------------------------------------------------------------------------
; Get line from buffer
;------------------------------------------------------------------------------

tigetline proc private uses rsi rdi rbx ti:PTINFO, line_id:UINT

    mov eax,line_id         ; ARG: line id
    mov rdx,ti
    mov rdi,[rdx].base     ; file is string[MAXFILESIZE]
    mov rbx,rdx

    .if eax                         ; first line ?

        mov ecx,[rdx].curline       ; current line ?
        .if eax == ecx              ; save time on repeated calls..

            mov rdi,[rdx].flptr    ; pointer to current line in buffer
        .else

            mov esi,eax             ; loop from EDI to line id in EAX
            .repeat

                .if !strchr(rdi, 10)

                    mov rdx,rbx
                    mov [rdx].curline,eax
                    mov rdi,[rdx].base
                    mov [rdx].flptr,rdi
                   .break
                .endif
                lea rdi,[rax+1]
                dec esi
            .untilz
            mov rdx,rbx
        .endif
    .endif

    mov [rdx].flptr,rdi        ; set current line pointer
    .if strchr(rdi, 10)         ; get length of line
        .if byte ptr [rax-1] == 0Dh
            dec rax
        .endif
        sub rax,rdi
    .else
        strlen(rdi)
    .endif

    mov rdx,rbx
    mov ebx,line_id
    mov [rdx].flbcnt,eax
    mov [rdx].curline,ebx
    mov ecx,eax
    mov rsi,rdi
    mov rdi,[rdx].lptr
    xor eax,eax

    .if ecx < [rdx].bsize

        mov [rdi],eax
        mov ebx,[rdx].tabsize   ; create mask for tabs in EBX
        dec ebx
        and ebx,TIMAXTABSIZE-1

        .while ecx

            lodsb
            .if eax == 9

                .if [rdx].flags & _T_USETABS

                    .repeat
                        mov [rdi],ax
                        inc rdi
                        mov eax,TITABCHAR
                    .until !( rdi & rbx )

                .else

                    or [rdx].flags,_T_MODIFIED

                    mov al,' '
                    mov [rdi],ax
                    inc rdi

                    .while rbx & rdi
                        mov [rdi],ax
                        inc rdi
                    .endw
                .endif
            .else
                mov [rdi],ax
                inc rdi
            .endif
            dec ecx
        .endw

        mov rax,[rdx].lptr     ; set expanded line size
        mov rcx,rdi
        sub rcx,rax
        mov [rdx].bcount,ecx
    .endif
    ret

tigetline endp

tigetnextl proc private uses rsi rdi rbx ti:PTINFO

    xor eax,eax
    mov rdx,ti
    mov [rdx].curline,eax
    mov edi,[rdx].flbcnt
    add rdi,[rdx].flptr    ; next = current + size + 0D 0A
    mov al,[rdi]
    mov rbx,rdx

    .if eax
        .if al == 0x0D
            inc rdi
            mov al,[rdi]
        .endif
        .if al != 0x0A
            xor eax,eax
        .else
            inc rdi
            mov [rdx].flptr,rdi

            .if !strchr(rdi,10)
                strlen(rdi)
            .else
                .if byte ptr [rax-1] == 0x0D
                    dec rax
                .endif
                sub rax,rdi
            .endif
            mov rdx,rbx
            mov [rdx].flbcnt,eax
            mov ecx,eax
            mov rsi,rdi
            mov rdi,[rdx].lptr
            xor eax,eax
            mov [rdi],eax

            .if ecx < [rdx].bsize

                mov ebx,[rdx].tabsize
                dec ebx
                and ebx,TIMAXTABSIZE-1

                .while ecx

                    lodsb
                    .if al == 9
                        .if [rdx].flags & _T_USETABS
                            stosb
                            mov eax,TITABCHAR
                            .while rdi & rbx
                                stosb
                            .endw
                        .else
                            or [rdx].flags,_T_MODIFIED
                            mov al,' '
                            stosb
                            .while rbx & rdi
                                stosb
                            .endw
                        .endif
                    .else
                        stosb
                    .endif
                    dec ecx
                .endw

                mov [rdi],ah
                mov rax,[rdx].lptr
                mov rcx,rdi
                sub rcx,rax
                mov [rdx].bcount,ecx
            .else
                xor eax,eax
            .endif
        .endif
    .endif
    ret

tigetnextl endp

ticurlp proc private uses rsi rdi ti:PTINFO

    mov rdx,ti              ; current line =
    mov eax,[rdx].loffs     ; line offset -- first line on screen
    add eax,[rdx].yoffs     ; + y offset -- cursory()

    .if tigetline(ti, eax)

        mov rsi,rax
        mov ecx,[rdx].bcol   ; terminate line
        add rax,rcx
        xor ecx,ecx             ; just in case..
        mov [rax-1],cl

        ;
        ; cursor->x may be above lenght of line
        ; so space is added up to current x-pos
        ;
        .while 1

            mov eax,[rdx].boffs           ; current line offset =
            add eax,[rdx].xoffs           ; buffer offset -- start of screen line
            .break .if eax < [rdx].bcol  ; + x offset -- cursorx()
            .if [rdx].xoffs != ecx
                dec [rdx].xoffs
            .else
                .break .if [rdx].boffs == ecx
                dec [rdx].boffs
            .endif
        .endw

        mov edi,eax
        .ifd strlen(rsi) < edi
            mov ecx,' '
            .repeat
                mov [rsi+rax],cx
                inc eax
            .until eax >= edi
        .endif
        mov ecx,eax
        mov rdx,ti
        mov [rdx].bcount,eax  ; byte count in line
        mov rax,rsi
    .endif
    ret

ticurlp endp

ticurcp proc private uses rbx ti:PTINFO
    ;
    ; current pointer = current line + line offset
    ;
    .if ticurlp(ti)

        mov ebx,[rdx].boffs
        add ebx,[rdx].xoffs
        add rax,rbx
    .endif
    ret

ticurcp endp

tiexpandline proc private uses rsi rdi rbx rdx ti:PTINFO, line:LPSTR

   .new p:LPSTR

    mov rdx,ti
    mov rax,line
    mov ebx,[rdx].tabsize

    .if [rdx].flags & _T_USETABS

        dec ebx
        and ebx,TIMAXTABSIZE-1
        mov rsi,rax
        mov rdi,rax
        mov ecx,[rdx].bcol
        add rcx,rsi
        dec rcx
        mov p,rcx

        .while  1
            lodsb
            .break .if al < 1

            .if al == 9
                stosb   ; insert TAB char
                        ; insert "spaces" to next Tab offset
                .break .if rdi >= p
                .while rsi & rbx
                    strshr(rsi, TITABCHAR)
                    .break .if rdi >= p
                    inc rsi
                    mov rdi,rsi
                .endw
                .continue
            .endif

            .break .if rdi == p
            stosb
        .endw
        mov byte ptr [rdi],0
    .endif
    ret

tiexpandline endp

tioptimalfill proc private uses rsi rdi rbx ti:PTINFO, line_offset:LPSTR

    mov rsi,line_offset
    mov ecx,strlen(rsi)
    mov rdx,ti
    mov eax,[rdx].flags
    and eax,_T_OPTIMALFILL or _T_USETABS
    cmp eax,_T_OPTIMALFILL or _T_USETABS
    mov rax,rsi

    .repeat

        .break .ifnz
        .break .if ecx < 5

        xor eax,eax

        .while 1

            mov rbx,rsi
            lodsb

            .switch al
            .case 0
            .case 10
            .case 13
                .break
            .case 39
            .case '"'
                mov bl,al
                .repeat
                    lodsb
                    .break(1) .if !al
                .until al == bl
                .continue(0)
            .endsw

            lea rcx,_ltype
            .continue(0) .if !( byte ptr [rcx+rax+1] & _SPACE )
            .repeat
                lodsb
                .break(1) .if al == 10
                .break(1) .if al == 13
            .until !( byte ptr [rcx+rax+1] & _SPACE )

            dec rsi
            .while 1

                mov rdi,rbx
                sub rdi,line_offset
                mov rcx,rdi
                add rdi,8
                and rdi,-8
                sub rdi,rcx
                lea rcx,[rsi+1]
                sub rcx,rbx
                .break .if ecx < 3
                .break .if ecx <= edi
                mov byte ptr [rbx],9
                inc rbx
                mov ecx,edi
                dec ecx
                .ifnz
                    mov rdi,rbx
                    add rbx,rcx
                    mov al,TITABCHAR
                    rep stosb
                .endif
            .endw
            .if ecx
                dec ecx
                .ifnz
                    mov al,' '
                    mov rdi,rbx
                    rep stosb
                .endif
            .endif
        .endw
        mov rax,line_offset
    .until 1
    ret

tioptimalfill endp

tigetfile proc uses rbx ti:PTINFO

    ldr rbx,ti

    xor eax,eax ; AX first file
    xor edx,edx ; DX last file
    xor ecx,ecx ; CX count

    .if rbx
        .if [rbx].TINFO.flags & _T_FILE
            mov rdx,rbx
            .repeat
                mov rax,rbx
                mov rbx,[rbx].TINFO.prev
            .until !rbx || rbx == rdx
            mov rbx,rax
            .repeat
                mov rdx,rbx
                mov rbx,[rbx].TINFO.next
                add ecx,1
            .until !rbx || rbx == rax
        .endif
    .endif
    ret

tigetfile endp


tigetfilename proc private uses rsi rdi ti:PTINFO

    ldr rsi,ti
    lea rdi,_bufin

    .if strfn(strcpy(rdi, [rsi].TINFO.file)) == rdi

        mov byte ptr [rdi],0
        GetCurrentDirectory(_MAX_PATH, rdi)
        mov rax,[rsi].TINFO.file
    .else
        mov byte ptr [rax-1],0
    .endif

    .if wdlgopen(rdi, rax, _WSAVE or _WNEWFILE)

        strcpy([rsi].TINFO.file, rax)
    .endif
    ret

tigetfilename endp


tiftime proc private uses rsi rdi ti:PTINFO

    ldr rsi,ti
    .ifd ( osopen([rsi].TINFO.file, 0, M_RDONLY, A_OPEN) == -1 )

        or [rsi].TINFO.flags,_T_MODIFIED
       .return( 0 )
    .endif

    mov edi,eax
    mov esi,getftime(edi)
    _close(edi)
    mov eax,esi
    ret

tiftime endp

    assume rdx:PTINFO
    ;
    ; Produce output to clipboard or file
    ;
tiflushl proc private uses rsi rdi rbx ti:PTINFO, line_start:UINT, offs_start:UINT,
    line_end:UINT, offs_end:UINT

  local line_index:UINT

    ldr edi,offs_start
    ldr ebx,offs_end
    mov line_index,line_start

    .if !tigetline(ti, eax)

        inc eax

    .else

        mov rsi,rax
        strtrim(rax)
        tioptimalfill(ti, rsi)

        sub rax,rsi
        add edi,eax
        add ebx,eax

        .while 1

            inc edi
            mov rdx,ti
            mov eax,[rdx].bcol
            mov ecx,line_end

            .if ecx == line_index
                mov eax,ebx
            .endif

            .if edi > eax       ; end of selection buffer

                .if ecx == line_index ; break if last line

                    mov eax,1
                   .break
                .endif
                jmp case_EOL    ; end of line
            .endif

            mov al,[rsi+rdi-1]
            .switch al
            .case 0
               case_EOL:

                inc line_index
                .if line_index > ecx

                    dec line_index
                    mov eax,1
                   .break
                .endif
                mov rsi,tigetnextl( ti )

                .if !eax ; break if last line (EOF)

                    inc eax
                   .break
                .endif

                strtrim(rsi)
                mov rsi,tioptimalfill(ti, rsi)
                xor rdi,rdi
                .if [rdx].flags & _T_USECRLF
                    ;
                    ; insert line: 0D0A or 0A
                    ;
                    oputc(0x0D)
                .endif

                oputc(0x0A)
                test eax,eax
                jz case_EOF    ; v3.24 -- eof()
               .endc

            .case 9
                mov eax,TIMAXTABSIZE-1
                .while byte ptr [rsi+rdi] == TITABCHAR
                    inc rdi
                    dec eax
                   .break .ifz
                .endw
                mov eax,9
            .default
                oputc(eax)
                test eax,eax
                jz case_EOF
            .endsw
        .endw
    .endif
toend:                  ; out:  EAX result
    mov ecx,edi         ;   EDX line index
    mov edx,line_index  ;   ECX line offset
    ret
case_EOF:
    xor eax,eax
    jmp toend

tiflushl endp

    assume rdx:nothing

tiflush proc uses rsi rdi rbx ti:PTINFO

  local path[_MAX_PATH]:byte

    ldr rsi,ti
    lea rdi,path
    .if getfattr(strcpy(rdi, [rsi].TINFO.file)) == -1
        .if tigetfilename(rsi)
            strcpy(rdi, rax)
        .else
            xor edi,edi
        .endif
    .elseif eax & _A_RDONLY
        ermsg(0, "The file is Read-Only")
        xor edi,edi
    .endif

    .if edi

        ioopen(&STDO, setfext(rdi, ".$$$"), M_WRONLY, OO_MEM64K)

        .ifs eax > 0

            mov ecx,[rsi].TINFO.lcount
            dec ecx

            .if !tiflushl(rsi, 0, 0, ecx, -1)

                ioclose(&STDO)
                remove(rdi)
                xor edi,edi

            .else

                ioflush(&STDO)
                ioclose(&STDO)

                .if [rsi].TINFO.flags & _T_USEBAKFILE

                    remove(setfext(rdi, ".bak"))
                    rename([rsi].TINFO.file, rdi)
                    setfext(rdi, ".$$$")
                .endif

                remove([rsi].TINFO.file)
                rename(rdi, [rsi].TINFO.file)

                lea rdi,[rax+1]
                and [rsi].TINFO.flags,not _T_MODIFIED

                tiftime(rsi)
                mov [rsi].TINFO.time,eax

                ;
                ; update .INI file ?
                ;
                mov rax,__argv
                mov rcx,[rax]

                setfext(strcpy(&path, rcx), ".ini")
                .if !_stricmp([rsi].TINFO.file, rax)

                    CFClose()
                    CFRead(&path)
                .endif
            .endif
        .else
            xor edi,edi
        .endif
    .endif
    mov eax,edi
    ret

tiflush endp

;
; 1. Attrib A - Set background and forground color
; 2. Control    O - Set color of CONTROL characters
; 3. Quote  Q - Set color of quoted text
; 4. Digit  D - Set color of numbers
; 5. Char   C - Set color of chars
; 6. String S - Set color of string
; 7. Begin  B - Set color from start of string
; 8. Word   W - Set color of words
; 9. Nested N - Set color of nested strings
;

ID_TYPE     equ 0
ID_ATTRIB   equ 1

ST_ATTRIB   equ 1   ; attrib    <at> [<char>]
ST_CONTROL  equ 2   ; control   <at>
ST_QUOTE    equ 3   ; quote     <at>
ST_NUMBER   equ 4   ; number    <at>
ST_CHAR     equ 5   ; char      <at> <chars>
ST_STRING   equ 6   ; string    <at> <string>
ST_START    equ 7   ; start     <at> <string>
ST_WORD     equ 8   ; word      <at> <words> ...
ST_NESTED   equ 9   ; nested    <at> <string1> <string2>
ST_COUNT    equ 9

    option proc:private

TIReadLabel proc uses rsi rdi rbx section:LPSTR, buffer:LPSTR, endbuf:LPSTR, attrib:LPSTR

  local st_type,i,p:LPSTR,q:LPSTR

    .repeat

        .break .if !INIGetEntryID(section, ID_TYPE)

        mov p,rax
        mov al,[rax]
        or  al,20h
        lea rdi,cp_typech
        mov ecx,sizeof(cp_typech)
        repnz scasb

        .break .ifnz
        mov rax,rdi
        lea rcx,cp_typech
        sub rax,rcx
        mov st_type,eax

        mov rdi,buffer
        mov rdi,[rdi]
        .break .if rdi >= endbuf

        stosb           ; store type
        mov rsi,p
        xor eax,eax
        mov i,eax
        lea rcx,_ltype

        .repeat
            inc rsi
            mov al,[rsi]

            .continue .if al == '_'

        .until !( byte ptr [rcx+rax+1] & _UPPER or _LOWER or _DIGIT )

        .repeat
            lodsb
            .switch
            .case al == ' '
                mov rax,rsi
               .endc
            .case al
               .continue
            .default
                mov i,1
               .break .if !INIGetEntryID(section, ID_ATTRIB)
            .endsw

            mov rsi,rax
            add rax,2
            mov p,rax

            __xtol(rsi)       ; Attrib XX
            mov ecx,[rsi]
            or  ecx,2020h
            mov rbx,attrib
            .switch
            .case cx == 'xx'
                mov al,[rbx]
               .endc
            .case cl == 'x'   ; Use default background
                __xtol(&[rsi+1])
                mov ah,[rbx]
                and ah,0xF0
                or  al,ah
               .endc
            .case ch == 'x'   ; Use default foreground
                mov ah,[rbx]
                and ah,0x0F
                or  al,ah
               .endc
            .endsw
            stosb       ; store attrib

            mov rsi,p
            .while byte ptr [rsi] == ' '
                add rsi,1
            .endw

            .if st_type == ST_ATTRIB

                mov [rbx],al    ; .stylec[1]
                .if byte ptr [rsi]

                    __xtol(rsi)
                    stosb
                .endif
                .break
            .endif

            .while  1
                .while  1
                    lodsb
                    .break .if !al
                    .break .if rdi >= endbuf
                    cmp al,' '
                    sete dl
                    dec dl
                    and al,dl
                    stosb
                .endw
                .break .if al
                stosb
                inc i
                .break .if i == 100
                .break .if !INIGetEntryID(section, i)
                mov rsi,rax
            .endw
        .until 1

        xor eax,eax
        .if [rdi-1] != al
            stosb
        .endif
        stosb
        mov rcx,buffer
        mov [rcx],rdi
        inc eax
    .until 1
    ret

TIReadLabel endp

TIDoSection proc uses rsi rdi rbx cfile:LPSTR, sname:LPSTR, buffer:LPSTR, endbuf:LPSTR, attrib:LPSTR

  local file[_MAX_PATH]:sbyte, entry[_MAX_PATH]:sbyte, section:LPSTR, index

    mov rsi,sname
    lea rdi,entry

    .if byte ptr [rsi] == '['
        ;
        ; [Section]   - this file
        ; [#File]     - extern file [.]
        ; [#File#Section] - extern file [<Section>]
        ;
        inc rsi
        mov rbx,rdi
        ;
        ; copy <Section>
        ;
        .repeat
            lodsb
            stosb
            .break .if !al
        .until al == ']'
        mov byte ptr [rdi-1],0
        ;
        ; do a recursive call
        ;
        .if byte ptr [rbx] == '#'

            inc rbx
            mov eax,[rbx]
            .switch
            .case ah == ':'
            .case al == '%'
            .case al == '\'
            .case al == '/'
            .case ax == '..'
                strcpy(&file, rbx)
               .endc
            .default
                strfcat(&file, _pgmpath, rbx)
            .endsw

            mov rsi,rax
            lea rdi,@CStr(".")

            .if strchr(expenviron(rax), '#')

                mov byte ptr [rax],0
                lea rdi,[rax+1]
            .endif

            .if INIRead(0, rsi)

                mov rsi,rax

                TIDoSection(rsi, rdi, buffer, endbuf, attrib)
                INIClose(rsi)
            .endif
        .else

            TIDoSection(cfile, rbx, buffer, endbuf, attrib)
        .endif

    .elseif INIGetSection(cfile, rsi)

        mov section,rax
        mov index,0

        .while INIGetEntryID(section, index)

            inc index

            .if byte ptr [rax] == '['

                mov rdx,rax
                TIDoSection(cfile, rdx, buffer, endbuf, attrib)

            .elseif INIGetSection(cfile, rax)

                TIReadLabel(rax, buffer, endbuf, attrib)
            .endif
        .endw
    .endif
    ret

TIDoSection endp

    option proc:public

tireadstyle proc private uses rsi rdi rbx ti:PTINFO

  local file[_MAX_PATH]:sbyte
  local section[64]:sbyte
  local buffer:ptr
  local endbuf:ptr  ; style + SIZE style - 2

    ldr rsi,ti

    mov rax,[rsi].TINFO.style
    mov buffer,rax
    mov rdi,rax
    add rax,STYLESIZE-4
    mov endbuf,rax

    xor eax,eax
    mov ecx,STYLESIZE/4
    rep stosd

    strcpy(&section, "style_default")
    strcpy(&file, strfn([rsi].TINFO.file))
    mov rdi,rax

    .if byte ptr [rdi+strlen(rdi)-1] == '.'

        mov byte ptr [rdi+rax-1],0
    .endif

    .if CFGetSection("Style")

        mov rbx,rax
        .if !INIGetEntry(rbx, rdi) ; FILENAME[.EXT]

            .if strext(rdi)   ; .EXT ?

                inc rax
                INIGetEntry(rbx, rax)
            .endif
        .endif
    .endif

    .if rax

        lea rcx,section
        strcpy(rcx, rax)
    .endif

    TIDoSection(__CFBase, addr section, addr buffer, endbuf, &[rsi].TINFO.stylec[2])

    mov rdi,buffer
    xor eax,eax
    stosw
    inc eax
    ret

tireadstyle endp

    assume rsi:PTINFO

tiread proc private uses rsi rdi rbx ti:PTINFO

  local line_count, tabs_used:byte, p:ptr

    mov rsi,ti      ; v2.49 - auto detect CR/LF
    mov tabs_used,0

    tiftime(rsi)
    mov [rsi].time,eax

    mov line_count,0
    mov rdi,[rsi].base

    .if ioopen(&STDI, [rsi].file, M_RDONLY, OO_MEMBUF) != -1

        mov eax,STDI.fsize_l
        mov [rsi].size,eax

        xor eax,eax
        .if eax == STDI.fsize_h

            mov line_count,eax  ; file offset (size)
            mov ebx,eax         ; line offset (for tabs)
            mov edx,[rsi].bsize
            add rdx,rdi
            sub rdx,TIMAXTABSIZE
            mov p,rdx

            .while 1

                .if rdi >= p

                    tirealloc(rsi)
                    test eax,eax
                    jz err_filetobig

                    sub rdi,rax
                    add rdi,[rsi].base
                    mov edx,[rsi].bsize
                    add rdx,[rsi].base
                    sub rdx,TIMAXTABSIZE
                    mov p,rdx
                 .endif


                .break .if ogetc() == -1

                .switch al
                .case 0
                    mov al,0Ah      ; @v3.29 - convert 0 to LF
                    or  [rsi].flags,_T_MODIFIED

                .case 0Ah
                    mov ecx,line_count
                    add ecx,ebx
                    .ifnz
                        .if byte ptr [rdi-1] != 0Dh
                            and [rsi].flags,not _T_USECRLF
                        .endif
                    .endif
                    stosb
                    inc line_count
                    xor ebx,ebx
                   .endc

                .case 09h
                    mov tabs_used,al
                    .if !( [rsi].flags & _T_USETABS )

                        or [rsi].flags,_T_MODIFIED
                        mov al,' '
                        stosb

                        inc ebx
                        mov ecx,[rsi].tabsize
                        dec ecx
                        and ecx,TIMAXTABSIZE-1

                        .while ebx & ecx
                            .break .if ebx == [rsi].bcol
                            stosb
                            inc ebx
                        .endw
                    .else
                        stosb
                        inc ebx
                    .endif
                    .endc

                .case 0Dh
                    or [rsi].flags,_T_USECRLF

                .default
                    stosb
                    inc ebx
                .endsw

                .if ebx == [rsi].bcol

                    .if [rsi].flags & _T_USECRLF
                        mov byte ptr [rdi],0Dh
                        inc rdi
                    .endif

                    mov byte ptr [rdi],0Ah
                    inc rdi
                    stosb

                    .if !( [rsi].flags & _T_MODIFIED )

                        or [rsi].flags,_T_MODIFIED
                        ermsg(0, "Line too long, was truncated")
                    .endif
                    inc line_count
                    xor ebx,ebx
                .endif
            .endw

        .else

         err_filetobig:

            ermsg(0, "File too big, no more memory")
            mov line_count,-1
            .if rdi != [rsi].base
                dec rdi
            .endif
        .endif

        mov byte ptr [rdi],0
        ioclose(&STDI)

        inc line_count
        mov eax,line_count
        mov [rsi].lcount,eax
    .endif

    mov eax,line_count
    .if [rsi].flags & _T_UNREAD

        and [rsi].flags,NOT _T_UNREAD
        .if !tabs_used && eax > 1 && [rsi].flags & _T_USETABS

            and [rsi].flags,NOT _T_USETABS
            mov [rsi].tabsize,4
        .endif
    .endif
    ret

tiread endp

tgetrect proc private

    mov rdx,cpanel
    mov eax,cflag
    mov rcx,[rdx].PANEL.dialog
    .if !( [rcx].DOBJ.flag & _D_ONSCR )

        and eax,NOT _C_PANELEDIT
    .endif
    mov cflag,eax
    .if eax & _C_PANELEDIT

        mov eax,[rcx].DOBJ.rc
        add eax,0x00000101
        sub eax,0x02020000
    .else
        mov edx,_scrrow
        inc edx
        mov eax,_scrcol
        mov ah,dl
        shl eax,16
    .endif
    ret

tgetrect endp

tsetrect proc private ti:PTINFO, rect:TRECT

    mov rdx,ti
    mov eax,rect
    mov [rdx].TINFO.dobj.rc,eax
    movzx ecx,ah
    movzx eax,al
    mov [rdx].TINFO.xpos,eax
    mov al,rect.col
    mov [rdx].TINFO.cols,eax
    .if [rdx].TINFO.xoffs >= eax

        dec eax
        mov [rdx].TINFO.xoffs,eax
    .endif
    mov al,rect.row
    .if [rdx].TINFO.flags & _T_USEMENUS

        inc ecx
        dec eax
    .endif
    mov [rdx].TINFO.ypos,ecx
    mov [rdx].TINFO.rows,eax
    .if [rdx].TINFO.yoffs >= eax

        dec eax
        mov [rdx].TINFO.yoffs,eax
    .endif
    mov eax,rect
    ret

tsetrect endp

    assume rsi:PTINFO
    assume rdx:PTINFO

tiopen proc private uses rsi ti:PTINFO, tabsize:UINT, flags:UINT

    .if !malloc(TINFO)

        ermsg(0, _sys_errlist[ENOMEM*size_t])
       .return( 0 )
    .endif

    mov rdx,rdi
    mov rsi,rax
    mov rdi,rax
    mov ecx,TINFO
    xor eax,eax
    rep stosb
    mov rdi,rdx

    mov eax,tabsize
    mov [rsi].tabsize,eax

    movzx eax,at_background[B_TextEdit]
    or  al,at_foreground[F_TextEdit]
    shl eax,16
    mov al,' '
    mov [rsi].clrc,eax
    mov [rsi].stylec,eax
    mov eax,flags
    or  eax,_T_UNREAD
    mov [rsi].flags,eax
    ;
    ; adapt to current screen
    ;
    tsetrect(rsi, tgetrect())

    mov [rsi].bcol,TIMAXLINE
    mov [rsi].bsize,TIMAXFILE

    .if tialloc(rsi)

        .if tigetfile(ti)
            ;
            ; link to last file
            ;
            mov [rsi].prev,rdx
            mov [rdx].next,rsi
        .endif
        mov rax,rsi

    .else

        free(rsi)
        ermsg(0, _sys_errlist[ENOMEM*size_t])
        xor eax,eax
    .endif
    ret

tiopen endp

    assume rdx:nothing
    assume rbx:PTINFO
    assume rdi:PTINFO

ticlose proc private uses rsi rdi rbx ti:PTINFO

    mov rsi,ti
    xor edi,edi

    .if ( [rsi].flags & _T_MALLOC )

        tifree(rsi)
        dlclose(&[rsi].dobj)
    .endif

    .if tigetfile(rsi)

        mov rdi,[rsi].prev
        mov rbx,[rsi].next
        mov [rsi].prev,0
        mov [rsi].next,0

        .if ( rbx && [rbx].prev == rsi )

            mov [rbx].prev,rdi
        .endif

        .if rdi

            .if ( [rdi].next == rsi )

                mov [rdi].next,rbx
            .endif
        .else
            mov rdi,rbx
        .endif
    .endif

    free(rsi)
    .return(rdi)

ticlose endp

    assume rbx:nothing
    assume rdi:nothing


tihide proc ti:PTINFO

    mov rcx,ti
    .if rcx

        mov [rcx].TINFO.crc,0
        dlclose(&[rcx].TINFO.dobj)
    .endif
    ret

tihide endp


    assume rsi:PTINFO

tihideall proc private ti:PTINFO

    .if tigetfile(ti)

        tihide(ti)
    .endif
    ret

tihideall endp


timenus proc private uses rsi rdi rbx ti:PTINFO

   .new ln:int_t
   .new col:int_t
   .new x:int_t
   .new y:int_t

    mov rsi,ti

    .if tistate(rsi)

        .if ( edx & _D_ONSCR && ecx & _T_USEMENUS )

            mov     rbx,rax
            mov     eax,[rsi].loffs
            add     eax,[rsi].yoffs
            inc     eax
            mov     ln,eax
            mov     eax,[rsi].xoffs
            add     eax,[rsi].boffs
            mov     col,eax
            movzx   eax,[rbx].DOBJ.rc.x
            movzx   edx,[rbx].DOBJ.rc.y
            movzx   ecx,[rbx].DOBJ.rc.col
            add     ecx,eax
            sub     ecx,18
            mov     y,edx
            mov     x,eax

            scputf(ecx, edx, 0, 0, " col %-3u ln %-6u", col, ln)

            mov eax,' '
            .if ( [rsi].flags & _T_MODIFIED )
                mov eax,'*'
            .endif
            scputw(x, y, 1, eax)
        .endif
    .endif
    .return( 0 )

timenus endp

ST_ATTRIB   equ 1   ; attrib    <at> [<char>]
ST_CONTROL  equ 2   ; control   <at>
ST_QUOTE    equ 3   ; quote     <at>
ST_NUMBER   equ 4   ; number    <at>
ST_CHAR     equ 5   ; char      <at> <chars>
ST_STRING   equ 6   ; string    <at> <string>
ST_START    equ 7   ; start     <at> <string>
ST_WORD     equ 8   ; word      <at> <words> ...
ST_NESTED   equ 9   ; nested    <at> <string1> <string2>
ST_COUNT    equ 9

_X_QUOTE    equ 1
_X_COMMENT  equ 2
_X_BEGIN    equ 4
_X_WORD     equ 8

TOUPPER macro reg
    sub al,'a'
    cmp al,'z'-'a'+1
    sbb dl,dl
    and dl,'a'-'A'
    sub al,dl
    add al,'a'
    retm<reg>
    endm

TOLOWER macro reg
    sub al,'A'
    cmp al,'Z'-'A'+1
    sbb dl,dl
    and dl,'a'-'A'
    add al,dl
    add al,'A'
    retm<reg>
    endm

TIStyleIsQuote proc private uses rsi rdi rbx line:LPSTR, string:LPSTR

    ldr rdi,line

    .while 1

        xor esi,esi
        xor ebx,ebx ; current quote

        mov rax,string
        sub rax,rdi
        .break .ifng
        ;
        ; first offset of quote
        ;
        mov rsi,memquote(rdi, eax)
        .break .if !rax

        or  bl,[rax]
        lea rdi,[rax+1]

        .while 1

            .break( 1 ) .if rdi >= string
             mov rcx,string
             sub rcx,rdi
             mov al,bl
             repnz scasb
            .break( 1 ) .ifnz

            ; case "\""
            ; case "\\"
            ; case "\\\""

            .break .if bl != '"'
            .break .if byte ptr [rdi-2] != '\'
            .break .if byte ptr [rdi-3] == '\' && byte ptr [rdi-4] != '\'
        .endw
    .endw
    mov eax,ebx ; return quote type
    ret

TIStyleIsQuote endp

    ;--------------------------------------
    ; seek back to get offset of /* and */
    ;--------------------------------------

find_token proc private uses rdi rbx ti:PTINFO

   .new p:LPSTR

    .repeat

        mov ebx,strlen(rsi)
        .break .if !eax

        mov rax,ti
        mov rdx,[rax].TINFO.base     ; top of file
        mov rdi,[rax].TINFO.flptr    ; current line
        mov rax,rdi
        sub rax,rdx
        .break .ifz
        dec rdi

        mov p,rdx

        .while  1
            ;
            ; Find the first token searching backwards
            ;
            movzx eax,byte ptr [rsi]
            mov rcx,rdi
            sub rcx,p
            .break .if !memrchr(p, eax, ecx)

            mov rdi,rax
            .continue .if strncmp(rsi, rdi, ebx)
            ;
            ; token found, now find start of line to make
            ; sure EDI is not indside " /* quotes */ "
            ;
            mov rcx,rdi
            sub rcx,p
            .if memrchr(p, 10, ecx)
                lea rax,[rax+1]
            .else
                mov rax,p
            .endif

            .if TIStyleIsQuote(rax, rdi)

                .continue .if al == '"'
                ;
                ; ' is found but /* it's maybe a fake */
                ;
                .if streol(rdi) != rdi ; get end of line

                    sub rax,rdi
                    .break .ifz
                    .continue .if memquote(rdi, eax)
                .endif
            .endif
            mov rax,rdi
           .break
        .endw
    .until 1
    ret

find_token endp

tistyle proc private uses rsi rdi rbx ti:PTINFO, line_id:dword, line_ptr:LPSTR,
        line_size:dword, out_buffer:PCHAR_INFO

  local \
    buffer:     LPSTR,  ; start of line
    endbuf:     LPSTR,  ; end of line
    endbufw:    LPSTR,  ; end of line (words)
    string:     LPSTR,
    ccount:     UINT,   ; length of visible line
    coffset:    size_t, ; number of non-visible chars <= 8
    attrib[2]:  byte,   ; current attrib
    ctype[2]:   byte,   ; current type
    quote1:     LPSTR,  ; pointer to first quote
    p:          LPSTR,
    q:          LPSTR,
    ctable[256]:byte,   ; LUT of char offset in line
    xtable[256]:byte    ; inside "quotes"

    mov rsi,ti
    mov edx,[rsi].TINFO.boffs
    mov rax,line_ptr
    add rax,rdx
    mov buffer,rax
    mov ecx,line_size
    sub ecx,edx
    .if ecx > [rsi].TINFO.cols
        mov ecx,[rsi].TINFO.cols
    .endif
    mov ccount,ecx
    add rax,rcx
    mov endbuf,rax
    mov endbufw,rax

    xor eax,eax
    mov ecx,256*2
    lea rdi,xtable
    rep stosb

    .if edx
        mov ecx,8
    .endif
    .if edx >= 8
        mov edx,8
    .endif
    mov coffset,rdx

    mov ecx,ccount  ; offset of last char + 1
    add ecx,edx     ; + <= 8 byte overlap
    mov rbx,buffer
    sub rbx,rdx
    mov rdi,endbuf
    .while rdi > rbx

        dec rdi
        mov al,[rdi]
        TOUPPER(eax)
        lea rdx,ctable
        mov [rdx+rax],cl
        TOLOWER(eax)
        lea rdx,ctable
        mov [rdx+rax],cl
        dec ecx
    .endw

    mov quote1,memquote(line_ptr, line_size)

    .if rax

        mov rdi,rax
        mov bl,[rdi] ; save quote in BL

        .while rdi < endbuf

            movzx eax,byte ptr [rdi]
            add rdi,1
            .break .if !rax

            .if rdi > buffer

                mov rcx,rdi
                sub rcx,buffer
                or  xtable[rcx-1],1
            .endif

            .if [rdi] == bl
                ;
                ; case C string \"
                ;
                .if bl == '"' && byte ptr [rdi-1] == '\'
                    ;
                    ; case "\\"
                    ; case "\\\""
                    ;
                    .continue .if byte ptr [rdi-2] != '\'
                    .continue .if word ptr [rdi-3] == '\\'
                .endif
                inc rdi
                .if rdi > buffer

                    mov rcx,rdi
                    sub rcx,buffer
                    or  xtable[rcx-1],1
                .endif
                mov ecx,line_size
                add rcx,line_ptr
                sub rcx,rdi
                .break .if !memquote(rdi, ecx)
                mov bl,[rax]
                mov rdi,rax
            .endif
        .endw
    .endif

    .repeat

        mov rsi,[rsi].TINFO.style

        .break .if !rsi
        .break .if !ccount

        .while 1

            movzx eax,byte ptr [rsi]
            movzx ebx,byte ptr [rsi+1]
            add rsi,2

            mov ctype,al
            mov attrib,bl

            .break .if !eax
            .break .if eax > ST_COUNT

            mov string,rsi
            mov rdx,endbuf
            .break .if rdx <= buffer

            .switch al
              .case ST_ATTRIB
                ;-----------------------------------------------
                ; 1. A Attrib   <at> [<char>]
                ;-----------------------------------------------
                mov rdx,ti
                mov byte ptr [rdx+2].TINFO.stylec,bl
                mov al,[rsi]
                .if al
                    mov byte ptr [rdx].TINFO.stylec,al
                .endif
                .endc

              .case ST_CONTROL
                ;-----------------------------------------------
                ; 2. O Control - match on all control chars
                ;-----------------------------------------------
                mov rax,ti
                .endc .if !( [rax].TINFO.flags & _T_SHOWTABS )

                xor eax,eax
                .for rdx = out_buffer, rdi = buffer, rcx = &_ltype,
                    al = [rdi] : eax && rdi < endbuf : rdi++, al = [rdi], rdx += 4

                    .if ( eax != 9 && byte ptr [rcx+rax+1] & _CONTROL )
                        mov [rdx+2],bl
                    .endif
                .endf
                .endc

              .case ST_QUOTE
                ;-----------------------------------------------
                ; 3. Q Quote - match on '"' and "'"
                ;-----------------------------------------------
                xor eax,eax
                .for ecx = ccount,
                     rdx = out_buffer,
                     rdi = buffer : rdi < endbuf && ecx : eax++, rdi++, ecx--

                    .if xtable[rax] & _X_QUOTE

                        .if !( xtable[rax] & ( _X_COMMENT or _X_BEGIN ) )

                            mov [rdx+rax*4][2],bl
                        .endif
                    .endif
                .endf
                .endc

              .case ST_NUMBER
                ;-------------------------------------------------
                ; 4. D Digit - match on 0x 0123456789ABCDEF and Xh
                ;-------------------------------------------------
                mov rdi,buffer
                .while rdi < endbuf

                    movzx eax,byte ptr [rdi]
                    add rdi,1
                    .endc .if !eax

                    lea rbx,_ltype
                    .if byte ptr [rbx+rax+1] & _DIGIT

                        lea rdx,[rdi-1]
                        .if rdx > line_ptr

                            movzx ecx,byte ptr [rdx-1]

                            .continue .if !ecx
                            .continue .if ecx == '_'
                            .continue .if byte ptr [rbx+rcx+1] & ( _UPPER or _LOWER or _DIGIT )
                        .endif
                        mov rsi,rdi
                        .if al == '0'
                            mov cl,[rsi]
                            or  cl,0x20
                            .if cl == 'x'
                                inc rsi
                            .endif
                        .endif
                        xor ecx,ecx
                        .while 1
                            lodsb
                            .break .if !eax
                            .continue .if byte ptr [rbx+rax+1] & _HEX
                            or  al,0x20
                            .continue .if al == 'u' ; ..UL
                            .continue .if al == 'i' ; ..I64
                            .continue .if al == 'l' ; ..UL[L]
                            inc rsi
                            .break .if al == 'h'    ; ..H
                            dec rsi
                            mov al,[rsi-1]
                            .break .if !( byte ptr [rbx+rax+1] & _UPPER or _LOWER )
                            inc ecx
                           .break
                        .endw
                        .continue .if ecx

                        sub rsi,rdi
                        .while esi

                            lea rax,[rdi-1]
                            .break .if rax >= endbuf
                            .if rax >= buffer

                                sub rax,buffer
                                .if !xtable[rax]

                                    shl eax,2
                                    add rax,out_buffer
                                    mov cl,attrib
                                    mov [rax+2],cl
                                .endif
                            .endif
                            inc rdi
                            dec esi
                        .endw
                    .endif
                .endw
                .endc

              .case ST_CHAR
                ;-----------------------------------------------
                ; 5. C Char <at> <chars>
                ;-----------------------------------------------
                .while 1

                    movzx eax,byte ptr [rsi]
                    add rsi,1

                    .break .if !eax

                    .if ctable[rax]

                        mov ecx,ccount
                        mov rdi,buffer
                        movzx edx,ctable[rax]
                        sub rdx,coffset
                        add rdi,rdx
                        sub ecx,edx
                        .endc .ifs

                        .while rdi <= endbuf

                            lea rdx,[rdi-1]
                            .if rdx >= buffer
                                sub rdx,buffer
                                .if !(xtable[rdx] & (_X_COMMENT or _X_QUOTE or _X_BEGIN) )

                                    shl edx,2
                                    add rdx,out_buffer
                                    mov [rdx+2],bl
                                .endif
                            .endif
                            repnz scasb
                           .break .ifnz
                        .endw
                    .endif
                .endw
                .endc

              .case ST_STRING
                ;-------------------------------------------------------------
                ; 6. S String - match on all equal strings if not inside quote
                ;-------------------------------------------------------------
                .while byte ptr [rsi]

                    mov rdi,line_ptr
                    .while strstr(rdi, rsi)

                        lea rdi,[rax+1]
                        .if rax >= buffer

                            mov rdx,rsi
                            mov rcx,rax
                            sub rax,buffer
                            shl eax,2
                            add rax,out_buffer
                            add rax,2

                            .while rcx < endbuf && byte ptr [rdx]

                                mov [rax],bl
                                add rdx,1
                                add rcx,1
                                add rax,4
                            .endw
                        .endif
                    .endw
                    .repeat
                        lodsb
                        test al,al
                    .untilz
                .endw
                .endc

              .case ST_START
                ;-----------------------------------------------
                ; 7. B Begin - XX string
                ;    set color XX from string to end of line
                ;-----------------------------------------------
                .while byte ptr [rsi]

                    mov rax,endbufw
                    .break .if rax <= buffer
                    sub rax,buffer
                    .if eax < 256 && xtable[rax-1] & _X_COMMENT

                        dec endbufw
                        .continue(0)
                    .endif

                    .repeat
                        movzx edx,byte ptr [rsi]
                        movzx eax,ctable[rdx]
                        .break .if !eax

                        mov rdi,buffer
                        sub rax,coffset
                        add rdi,rax

                        lea rax,[rdi-1]
                        .if rax >= endbufw

                            mov rax,endbufw
                            dec rax
                        .endif
                        .if rax < buffer
                            mov rax,buffer
                        .endif
                        sub rax,buffer
                        and eax,0xFF
                        .break .if xtable[rax] & _X_QUOTE && edx != "'"

                        lea rcx,_ltype
                        mov bh,byte ptr [rcx+rdx+1]
                        and bh,_UPPER or _LOWER

                        lea rax,[rdi-1]
                        .if rax > line_ptr && bh

                            movzx eax,byte ptr [rax-1]
                            .break .if !(byte ptr [rcx+rax+1] & _SPACE)
                        .endif

                        .while 1

                            mov rdx,rsi
                            lea rcx,[rdi-1]
                            .repeat
                                add rdx,1
                                add rcx,1
                                mov al,[rdx]
                                .break .if !al
                                .continue(0) .if al == [rcx]
                                mov ah,[rcx]
                                or  eax,0x2020
                                .continue(0) .if al == ah
                            .until 1

                            .repeat

                                .break .if al
                                .if bh

                                    movzx eax,byte ptr [rcx]
                                    lea rcx,_ltype
                                    .break .if eax == '_'
                                    .break .if byte ptr [rcx+rax+1] & _UPPER or _LOWER
                                .endif

                                mov al,bl
                                and al,0x0F
                                .if al == 8
                                    mov bh,_X_COMMENT
                                .else
                                    mov bh,_X_BEGIN
                                .endif

                                lea rax,[rdi-1]
                                mov rcx,endbufw
                                mov rdx,rax
                                .if rax < buffer
                                    mov rax,buffer
                                .endif
                                .if bh == _X_COMMENT
                                    mov endbufw,rax
                                .endif
                                sub rdx,buffer

                                .while rdi <= rcx

                                    .if rdi > buffer && edx < 256

                                        .if !(xtable[rdx] & _X_COMMENT)

                                            lea rax,[rdx*4]
                                            add rax,out_buffer
                                            mov [rax+2],bl
                                        .endif
                                        or xtable[rdx],bh
                                    .endif
                                    add rdi,1
                                    add rdx,1
                                .endw
                            .until 1

                            .break .if rdi > endbufw
                            ;
                            ; continue search
                            ;
                            mov al,[rsi]
                            mov cl,TOUPPER(al)
                            mov ch,TOLOWER(al)
                            xor edx,edx
                            .while rdi < endbufw

                                mov al,[rdi]
                                add rdi,1
                                inc edx
                                .break .if al == cl
                                .break .if al == ch
                                dec edx
                            .endw
                            .break .if !edx
                        .endw
                    .until 1
                    .repeat
                        lodsb
                        test al,al
                    .untilz
                .endw
                .endc

              .case ST_WORD
                ;-----------------------------------------------
                ; 8. W Word - match on all equal words
                ;-----------------------------------------------
                .while byte ptr [rsi]

                    mov rax,endbufw
                    .break .if rax <= buffer
                    sub rax,buffer
                    .if xtable[rax-1]
                        dec endbufw
                       .continue(0)
                    .endif

                    .repeat
                        movzx eax,byte ptr [rsi]
                        .break .if !ctable[rax]

                        mov rdi,buffer
                        movzx edx,ctable[rax]
                        sub rdx,coffset
                        add rdi,rdx

                        .while 1

                            mov rdx,rsi
                            lea rcx,[rdi-1]
                            .repeat
                                add rdx,1
                                add rcx,1
                                mov al,[rdx]
                                .break .if !al
                                .continue(0) .if al == [rcx]
                                mov ah,[rcx]
                                or  eax,0x2020
                                .continue(0) .if al == ah
                            .until 1

                            .repeat
                                .break .if al

                                lea rdx,[rdi-1]
                                .if rdx >= buffer

                                    mov rax,rdx
                                    sub rax,buffer
                                    and eax,0xFF
                                    .break .if xtable[rax] & _X_QUOTE
                                .endif
                                lea rbx,_ltype
                                .if rdx > line_ptr

                                    movzx eax,byte ptr [rdx-1]
                                    .break .if eax == '_'
                                    .break .if byte ptr [rbx+rax+1] & ( _UPPER or _LOWER or _DIGIT )
                                .endif

                                movzx eax,byte ptr [rcx]
                                .break .if al == '_'
                                .break .if byte ptr [rbx+rax+1] & ( _UPPER or _LOWER or _DIGIT )

                                sub rcx,rdi
                                lea rax,[rdi-1]
                                sub rax,buffer
                                mov edx,eax
                                imul rax,rax,4
                                add rax,out_buffer
                                add rax,2
                                inc ecx

                                mov bl,attrib
                                .repeat
                                    .break .if rdi > endbufw
                                    .if rdi > buffer

                                        .if !xtable[rdx]

                                            or  xtable[rdx],_X_WORD
                                            mov [rax],bl
                                        .endif
                                    .endif
                                    add rax,4
                                    add rdi,1
                                    add edx,1
                                .untilcxz
                            .until 1

                            .break .if rdi > endbufw
                            ;
                            ; continue search
                            ;
                            mov al,[rsi]
                            mov cl,TOUPPER(al)
                            mov ch,TOLOWER(al)
                            xor edx,edx
                            .while rdi < endbufw

                                mov al,[rdi]
                                add rdi,1
                                inc edx
                                .break .if al == cl
                                .break .if al == ch
                                dec edx
                            .endw
                            .break .if !edx
                        .endw
                    .until 1
                    .repeat
                        lodsb
                        test al,al
                    .untilz
                .endw
                .endc

              .case ST_NESTED
                ;-----------------------------------------------
                ; 9. N Nested -- /* */
                ;-----------------------------------------------
                mov rdi,line_ptr    ; find start condition
                mov eax,line_id
                xor ebx,ebx

                .if eax         ; first line ?
                    ;
                    ; seek back to last first arg (/*) */
                    ;
                    .if find_token(ti)

                        mov rbx,rax ; EBX first arg
                        .repeat     ; ESI to next token
                            lodsb
                            test al,al
                        .untilz
                        movzx eax,byte ptr [rsi]
                        ;
                        ; start, no end - ok
                        ;
                        .if eax
                            ;
                            ; find end */
                            ;
                            .if find_token(ti) > rbx
                                xor eax,eax
                            .else
                                inc eax
                            .endif
                        .else
                            inc eax
                        .endif
                    .endif
                .endif

                .if eax

                    inc rdi
                    mov ecx,line_size
                    jmp find_arg2

                .else

                    jmp find_arg1

                    clear_loop:
                    .repeat
                        inc rdi
                        .endc .if set_attrib()
                    .untilcxz

                    find_arg1:
                    .repeat

                        mov rsi,string
                        mov ecx,line_size
                        mov rax,rdi
                        sub rax,line_ptr
                        sub ecx,eax
                        .endc .ifng

                        mov al,[rsi]
                        repnz scasb
                        .endc .ifnz

                        inc rsi
                        xor eax,eax
                        xor ebx,ebx

                        .while 1
                            inc ebx
                            xor al,[rsi+rbx-1]
                            .break .ifz
                            sub al,[rdi+rbx-1]
                           .continue(01) .ifnz
                        .endw
                        .continue(0) .if TIStyleIsQuote(line_ptr, rdi)

                        .repeat
                            .endc .if set_attrib()
                            inc rdi
                            mov al,[rsi]
                            inc rsi
                           .break(1) .if !al
                        .untilcxz
                        .endc .if set_attrib()
                    .until 1

                    find_arg2:

                    .while ecx

                        mov al,[rsi]    ; find next token
                        test al,al
                        jz clear_loop

                        .repeat
                            .endc .if set_attrib()
                             dec ecx
                            .break(1) .ifz

                            mov ax,[rsi]
                            inc rdi
                            .continue(0) .if al != [rdi-2]
                            test ah,ah
                            jz find_arg1
                        .until ah == [rdi-1]
                        .continue .if TIStyleIsQuote(line_ptr, rdi)

                        xor ebx,ebx
                        .repeat
                            .endc .if set_attrib()
                             dec ecx
                            .break(1) .ifz

                            inc rdi
                            inc ebx
                            xor al,[rsi+rbx+1]
                            jz  find_arg1
                            sub al,[rdi-1]
                        .untilnz
                        .endc .if set_attrib()
                    .endw
                .endif
                .endc
            .endsw

            mov rsi,string
            .repeat
                lodsb
                .continue .if al
                lodsb
            .until !al
        .endw
    .until 1
    ret

set_attrib:
    xor eax,eax
    .if rdi > buffer
        .if rdi > endbuf
            inc eax
        .else
            lea rax,[rdi-1]     ; = offset in text line
            sub rax,buffer
            or  xtable[rax],_X_COMMENT
            shl eax,2
            add rax,out_buffer  ; = offset in screen line (*int)
            mov dl,attrib
            mov [rax+2],dl      ; set attrib for this char
            xor eax,eax
        .endif
    .endif
    retn

tistyle endp


    assume rdx:PTINFO

;  AX byte count
;  CX line count

tiselected proc private ti:PTINFO

    mov rdx,ti
    mov eax,[rdx].clip_el
    sub eax,[rdx].clip_sl
    mov ecx,eax
    .ifz
        mov eax,[rdx].clip_eo
        sub eax,[rdx].clip_so
    .endif
    ret

tiselected endp

tiputl proc private uses rsi rdi rbx wc:PCHAR_INFO, line:uint_t, ti:PTINFO

  local loff:LPSTR,    ; adress of line
        llen:uint_t,   ; length of line
        clst:uint_t,   ; clip start
        clen:uint_t    ; clip end

    mov rdx,ti
    mov eax,[rdx].clrc
    .if [rdx].flags & _T_USESTYLE
        mov eax,[rdx].stylec
    .endif

    mov rbx,wc
    mov rdi,rbx
    mov ecx,[rdx].cols
    rep stosd

    mov rdi,rbx
    mov eax,line
    .if eax
        tigetnextl(rdx)
    .else
        tigetline(ti, eax)
    .endif
    .if rax
        mov rsi,rax
        mov llen,ecx

        .if ecx > [rdx].boffs

            mov loff,rsi
            mov ecx,[rdx].boffs
            add rsi,rcx
            mov ecx,[rdx].cols
            xor eax,eax

            .repeat
                mov al,[rsi]
                add rsi,1

                .break .if !al
                .if al == TITABCHAR
                    mov al,' '
                .endif
                .if al == 9 && !( [rdx].flags & _T_SHOWTABS )
                    mov al,' '
                .endif
                mov [rdi],ax
                add rdi,4
            .untilcxz

            .if [rdx].flags & _T_USESTYLE

                mov rcx,loff
                .if byte ptr [rcx]
                    tistyle(ti, line, rcx, llen, wc)
                .endif
            .endif
        .endif

        xor eax,eax
        mov clen,eax    ; clip end to   0000
        dec eax         ; clip start to FFFF
        mov clst,eax

        .if tiselected(ti)

            xor edx,edx
            mov rsi,ti
            mov eax,line

            .if eax >= [rsi].clip_sl && eax <= [rsi].clip_el

                .if eax == [rsi].clip_sl

                    dec edx
                    mov clen,edx
                    mov ecx,eax
                    mov eax,[rsi].clip_so
                    mov edx,[rsi].boffs
                    .if eax >= edx
                        sub eax,edx
                    .else
                        xor eax,eax
                    .endif
                    mov clst,eax
                    mov eax,ecx
                    .if eax == [rsi].clip_el
                        mov eax,[rsi].clip_eo
                        sub eax,[rsi].boffs
                        mov clen,eax
                    .endif
                .else
                    mov clst,edx
                    .if eax == [rsi].clip_el
                        mov eax,[rsi].clip_eo
                        sub eax,[rsi].boffs
                        mov clen,eax
                    .else
                        dec edx
                        mov clen,edx
                    .endif
                .endif

                mov ecx,[rsi].cols
                mov rdi,wc
                add rdi,2
                movzx eax,at_background[B_Inverse]
                xor ebx,ebx
                mov edx,clst
                .repeat
                    .if ebx >= edx
                        .break .if ebx >= clen
                        mov [rdi],ax
                    .endif
                    add ebx,1
                    add rdi,4
                .untilcxz
            .endif
        .endif
    .endif
    mov eax,1
    ret

tiputl endp

tiputs proc uses rsi rdi rbx ti:PTINFO

  local wc:PCHAR_INFO,
        wcols:UINT,
        bz:COORD,
        rc:SMALL_RECT,
        cursor:CURSOR

    mov rsi,ti
    mov eax,[rsi].xpos
    add eax,[rsi].xoffs
    mov ecx,[rsi].ypos
    add ecx,[rsi].yoffs

    mov cursor.x,ax
    mov cursor.y,cx
    mov cursor.bVisible,1
    mov cursor.dwSize,CURSOR_NORMAL
    _setcursor(&cursor)

    mov eax,[rsi].cols
    mul [rsi].rows
    shl eax,2
    mov ebx,eax
    mov wc,alloca(ebx)
    mov rsi,rax

    mov ecx,ebx
    mov rdi,rsi
    xor eax,eax
    rep stosb

    mov rdx,ti
    imul eax,[rdx].cols,4
    mov wcols,eax

    mov edi,[rdx].rows
    mov ebx,[rdx].loffs
    .if ebx
        lea eax,[rbx-1]
        and eax,tigetline(ti, eax)
        jz  toend
    .endif

    .repeat
        and eax,tiputl(rsi, ebx, ti)
        jz  toend
        mov eax,wcols
        add rsi,rax
        inc ebx
        dec edi
    .untilz

    mov rsi,ti
    mov ecx,[rsi].cols
    mov bz.X,cx
    mov eax,[rsi].xpos
    mov rc.Left,ax
    add eax,ecx
    dec eax
    mov rc.Right,ax
    mov eax,[rsi].ypos
    mov rc.Top,ax
    add eax,[rsi].rows
    dec eax
    mov rc.Bottom,ax
    mov eax,[rsi].rows
    mov bz.Y,ax

    mov eax,[rsi].boffs
    mov ebx,old_boff
    mov old_boff,eax
    sub eax,ebx
    mov ecx,[rsi].loffs
    mov ebx,old_loff
    mov old_loff,ecx
    sub ecx,ebx
    sub eax,ecx
    mov edi,eax

    movzx eax,word ptr bz
    movzx ecx,word ptr bz+2
    mul ecx
    shl eax,2
    mov rdx,wc
    mov ecx,eax
    xor eax,eax
    xor ebx,ebx
    lea rsi,crctab

    .while ecx
        mov bl,al
        xor bl,[rdx]
        shr eax,8
        xor eax,[rsi+rbx*4]
        add rdx,1
        sub ecx,1
    .endw

    mov rdx,ti
    mov ebx,[rdx].crc
    mov [rdx].crc,eax
    sub eax,ebx
    add eax,edi
    .ifnz
        WriteConsoleOutput(_confh, wc, bz, 0, &rc)
    .endif
toend:
    mov rdx,ti
    ret

tiputs endp

; set clipboard to current position

ticlipset proc private ti:PTINFO

    mov rdx,ti
    mov eax,[rdx].xoffs
    add eax,[rdx].boffs
    mov [rdx].clip_so,eax
    mov [rdx].clip_eo,eax
    mov eax,[rdx].loffs
    add eax,[rdx].yoffs
    mov [rdx].clip_sl,eax
    mov [rdx].clip_el,eax
    ret

ticlipset endp

tialignx proc private uses rbx ti:PTINFO, x:UINT
    ;
    ; align xoff and boff to EAX
    ;
    mov rdx,ti
    mov ebx,[rdx].xoffs
    add ebx,[rdx].boffs

    .if ( ebx < x ) ; left or right ?

        .while 1

            .return .if !tiincx(rdx) ; go right
             inc ebx
            .return .if x == ebx
        .endw

    .elseif ( ebx > x )

        .while 1

            .return .if !tidecx(rdx) ; go left
             dec ebx
            .return .if x == ebx
        .endw
    .endif
    ret

tialignx endp

ticliptostart proc private uses rdi ti:PTINFO

    mov rdx,ti
    mov edi,[rdx].loffs
    mov eax,[rdx].yoffs
    mov ecx,edi
    add ecx,eax
    sub ecx,[rdx].clip_sl
    .ifnz
        .if eax >= ecx
            sub eax,ecx ; move cursor up
        .else
            sub ecx,eax ; scroll up..
            xor eax,eax ; screen line to 0
            sub edi,ecx ; new line offset
        .endif
    .endif
    mov [rdx].loffs,edi
    mov [rdx].yoffs,eax
    mov rax,rdx
    tialignx( rax, [rdx].clip_so )
    ret

ticliptostart endp

tigeto proc private uses rsi rdi ti:PTINFO, line:UINT, offs:UINT

    xor edi,edi
    .if tigetline(ti, line)   ; expanded line

        mov rsi,rax
        mov rdi,[rdx].flptr  ; line from file buffer
        mov ecx,offs

        .while ecx

            mov al,[rsi]
            add rsi,1
            .break .if !al

            .if al != TITABCHAR ; skip expanded tabs
                add rdi,1
            .endif
            sub ecx,1
        .endw
    .endif
    mov rax,rdi
    ret

tigeto endp

    assume rsi:PTINFO

ticlipdel proc private uses rsi rbx ti:PTINFO

    mov rsi,ti

    .if tiselected(rsi)

        ticliptostart(rsi)

        .if tigeto(rsi, [rsi].clip_sl, [rsi].clip_so)

            mov rbx,rax
            .if tigeto(rsi, [rsi].clip_el, [rsi].clip_eo)
                .if rax <= rbx
                    xor eax,eax
                .else
                    strcpy(rbx, rax)
                    or  [rsi].flags,_T_MODIFIED
                    mov eax,[rsi].clip_el
                    sub eax,[rsi].clip_sl
                    .ifnz
                        .if ( eax <= [rsi].lcount )
                            sub [rsi].lcount,eax
                        .else
                            mov [rsi].lcount,0
                        .endif
                    .endif
                    ticlipset(rsi)
                    mov eax,1
                .endif
            .endif
        .endif
    .endif
    ret

ticlipdel endp

; copy start to end pointer of selected text

ticopyselection proc private uses rsi rdi ti:PTINFO

    mov rsi,ti
    .if tigeto(rsi, [rsi].clip_sl, [rsi].clip_so)
        mov rdi,rax
        .if tigeto(rsi, [rsi].clip_el, [rsi].clip_eo)
            sub rax,rdi     ; = byte size of selected text
            ClipboardCopy(rdi, eax)
            mov eax,1
        .endif
    .endif
    ret

ticopyselection endp

ticlipcut proc private uses rsi ti:PTINFO, delete:UINT

    mov rsi,ti
    .if tiselected(rsi)
        .if !ticopyselection(rsi)
            .return
        .endif
    .endif
    .if delete
        ticlipdel(rsi)
    .endif
    ticlipset(rsi)
    xor eax,eax
    ret

ticlipcut endp

tiselectall proc private ti:PTINFO

    xor eax,eax
    mov rdx,ti
    mov [rdx].clip_sl,eax
    mov [rdx].clip_so,eax
    mov [rdx].clip_el,eax
    mov eax,[rdx].bcol
    mov [rdx].clip_eo,eax
    .if [rdx].lcount != eax
        mov eax,[rdx].lcount
        dec eax
        mov [rdx].clip_el,eax
        tiputs(rdx)
    .endif
    xor eax,eax
    ret

tiselectall endp

tiincy proc private uses rdi rbx ti:PTINFO

    mov rdx,ti
    mov ebx,[rdx].rows
    mov eax,[rdx].loffs
    mov edi,eax
    add eax,[rdx].yoffs
    inc eax
    .if eax >= [rdx].lcount
        xor eax,eax
    .else
        mov eax,[rdx].yoffs
        inc eax
        .if eax >= ebx

            mov eax,ebx
            dec eax
            inc edi
        .endif
        mov [rdx].yoffs,eax
        mov [rdx].loffs,edi
        mov eax,1
    .endif
    ret

tiincy endp

tialigny proc uses rbx ti:PTINFO, y:UINT
    ;
    ; align yoff and loff to EAX
    ;
    mov rdx,ti
    mov ebx,[rdx].yoffs
    add ebx,[rdx].loffs

    .while ( ebx > y )
        .if [rdx].yoffs
            dec [rdx].yoffs
        .else
            dec [rdx].loffs
        .endif
        dec ebx
    .endw

    .while ebx < y

       .break .if !tiincy(rdx)
        inc ebx
    .endw
    ret

tialigny endp

tihome proc private ti:PTINFO

    mov rdx,ti
    xor eax,eax
    mov [rdx].boffs,eax
    mov [rdx].xoffs,eax
    ret

tihome endp

titoend proc private uses rsi rdi ti:PTINFO

    mov rdx,ti
    .if ticurlp(rdx)

        .if stripend(rax)

            mov [rdx].bcount,ecx
            mov eax,ecx
            sub eax,[rdx].boffs
            .if eax < [rdx].cols

                mov [rdx].xoffs,eax
            .else
                mov eax,[rdx].cols
                dec eax
                .if ecx <= eax
                    mov eax,ecx
                .endif
                mov [rdx].xoffs,eax
                sub ecx,eax
                mov [rdx].boffs,ecx
            .endif
        .else
            tihome(rdx)
        .endif
        xor eax,eax
    .else
        mov eax,_TI_CMFAILED
    .endif
    ret

titoend endp

tileft proc private ti:PTINFO

    .if !tidecx(ti)
        mov eax,_TI_CMFAILED
    .else
        xor eax,eax
    .endif
    ret

tileft endp

tiup proc private ti:PTINFO

    mov rdx,ti
    xor eax,eax
    .if eax != [rdx].yoffs
        dec [rdx].yoffs
    .elseif eax != [rdx].loffs
        dec [rdx].loffs
    .else
        mov eax,_TI_CMFAILED
    .endif
    ret

tiup endp

TIOST       STRUC
buffer      LPSTR ? ; &lptr[bcol]
index       UINT ?
file_ptr    LPSTR ?
file_end    LPSTR ?
line_ptr    LPSTR ?
c           UINT ?
TIOST       ENDS
PTIOST      TYPEDEF PTR TIOST

    assume rbx:PTIOST

tio_open proc fastcall private uses rbx o:PTIOST, ti:PTINFO

    mov rbx,rcx
    .if !ticurcp(rdx)

        .return(_TI_CMFAILED)
    .endif
    mov [rbx].line_ptr,rax
    mov [rbx].index,0
    mov [rbx].file_ptr,[rdx].flptr
    mov ecx,[rdx].flbcnt
    add rax,rcx
    mov [rbx].file_end,rax
    mov eax,[rdx].bcol
    add rax,[rdx].lptr
    mov [rbx].buffer,rax
    xor eax,eax
    ret

tio_open endp

tio_putc proc private uses rbx o:PTIOST, c:UINT

    mov rbx,o
    mov ecx,[rbx].index
    mov eax,_TI_CMFAILED
    .if ( ecx < TIMAXLINE )

        add rcx,[rbx].buffer
        inc [rbx].index
        mov eax,c
        mov ah,0
        mov [rcx],ax
        xor eax,eax
    .endif
    ret

tio_putc endp

tio_copy2 proc fastcall private uses rsi rdi rbx o:PTIOST, ti:PTINFO

    mov rbx,rcx
    mov rdi,[rbx].line_ptr
    mov rsi,[rdx].lptr
    sub rdi,rsi
    .repeat
        lodsb
        .if ( al != TITABCHAR )

            .return .if tio_putc(rbx, eax)
        .endif
        dec edi
    .untilz
    .return( 0 )

tio_copy2 endp

tio_copy proc fastcall private uses rbx o:PTIOST, ti:PTINFO

    mov rbx,rcx
    mov rcx,[rbx].line_ptr

    .if ( byte ptr [rcx] == TITABCHAR )

        mov eax,0x2000 + TITABCHAR
        mov [rcx],ah

        .if [rcx+1] == al
            mov byte ptr [rcx],9
        .endif

        .if ( rcx > [rdx].lptr )

            .repeat
                dec rcx
                .break .if [rcx] != al
                mov [rcx],ah
            .until ( rcx == [rdx].lptr )
            .if byte ptr [rcx] == 9
                mov [rcx],ah
            .endif
        .endif
    .endif
    .return( tio_copy2(rbx, rdx) )

tio_copy endp

tio_trim proc fastcall private uses rbx o:PTIOST

    mov rbx,rcx
    mov ecx,[rbx].index
    mov rax,[rbx].buffer

    .while ecx

        dec ecx

        .break .if ( byte ptr [rax+rcx] != ' ' )

        mov byte ptr [rax+rcx],0
        mov [rbx].index,ecx
    .endw
    ret

tio_trim endp

tio_flush proc fastcall private uses rsi rdi rbx o:PTIOST, ti:PTINFO

    mov rbx,rcx
    mov rsi,rdx

    .if ( [rdx].flags & _T_OPTIMALFILL && [rbx].index )

        tiexpandline(rsi, [rbx].buffer)
        tioptimalfill(rsi, [rbx].buffer)

        mov rcx,rax
        mov rdi,rax
        mov [rbx].index,0

        .while 1

            mov al,[rcx]

            .break .if !al

            .if ( al != TITABCHAR )

                stosb
                inc [rbx].index
            .endif
            inc rcx
        .endw
    .endif

    mov eax,[rbx].index
    add rax,[rbx].file_ptr
    mov rcx,[rbx].file_end

    .if ( rax == rcx )

        jmp done

    .elseif ( rax > rcx )

        strlen(rcx)
        inc eax
        add rax,[rbx].file_end

        mov ecx,[rsi].bsize
        add rcx,[rsi].base
        sub rcx,256
        .if ( rax < rcx )

            sub rax,[rbx].file_end
            mov ecx,[rbx].index
            add rcx,[rbx].file_ptr
            memmove(rcx, [rbx].file_end, eax)
            jmp done
        .endif

        .if !tirealloc(rsi)

            .return(_TI_CMFAILED)
        .endif
        sub [rbx].file_end,rax
        sub [rbx].file_ptr,rax
        mov rax,[rsi].base
        add [rbx].file_end,rax
        add [rbx].file_ptr,rax
        mov eax,[rsi].bcol
        add rax,[rsi].lptr
        mov [rbx].buffer,rax
    .endif

    mov eax,[rbx].index
    add rax,[rbx].file_ptr
    strmove(rax, [rbx].file_end)

done:

    memcpy( [rbx].file_ptr, [rbx].buffer, [rbx].index)

    mov rdx,rsi
    or  [rdx].flags,_T_MODIFIED
    xor eax,eax
    ret

tio_flush endp

tio_tail proc private uses rsi o:PTIOST, ti:PTINFO, tail:LPSTR

    mov rsi,tail
    lodsb
    .while al

        .if ( al != TITABCHAR )

            .return .if tio_putc(o, eax)
        .endif
        lodsb
    .endw
    tio_trim(o)
    tio_flush(o, ti)
    ret

tio_tail endp

    assume rbx:nothing

tiputc proc private uses rsi rdi rbx ti:PTINFO, char:UINT

   .new o:TIOST

    mov rsi,ti
    movzx eax,byte ptr char
    mov o.c,eax
    lea rcx,_ltype

    .if ( byte ptr [rcx+rax+1] & _CONTROL )

        .if ( eax != 9 && eax != 10 )
            .if eax == 13
                xor eax,eax ; skip
            .else
                mov eax,_TI_RETEVENT
            .endif
            .return
        .endif
    .endif

    lea rbx,o
    .if tio_open(rbx, rsi)

        .return
    .endif
    mov rcx,o.line_ptr
    sub rcx,[rsi].lptr
    .ifnz
        .return .if tio_copy(rbx, rsi)
    .endif

    .if ( o.c == 10 )

        mov ecx,o.index
        mov rax,o.buffer

        .while ecx

            dec ecx

            .break .if ( byte ptr [rax+rcx] > ' ' )
            .break .if ( byte ptr [rax+rcx] == 10 )

            mov byte ptr [rax+rcx],0
            mov o.index,ecx
        .endw

        .if ( [rsi].flags & _T_USECRLF )

            .return .if tio_putc(rbx, 13)
        .endif
        .return .if tio_putc(rbx, 10)

        inc [rsi].lcount ; inc line count
        tihome(rsi)       ; to start of line
        tiincy(rsi)       ; one down

        .if ( [rsi].flags & _T_USEINDENT )

            mov rcx,[rsi].lptr         ; get indent size
            mov eax,' '

            .while ( [rcx] != ah && [rcx] <= al && rcx < o.line_ptr )

                inc rcx
            .endw

            sub rcx,[rsi].lptr         ; add indent
            .ifnz

                mov edi,ecx
                .repeat

                    .break .if !tiincx(rsi)
                    .return .if tio_putc(rbx, ' ')

                    dec edi
                .untilz
            .endif
        .endif

    .else

        .if !tiincx(rsi)

            .return(_TI_CMFAILED)
        .endif

        mov eax,o.c
        .if ( eax == 9 && !( [rsi].flags & _T_USETABS ) )
            mov eax,' '
        .endif
        .return .if tio_putc(rbx, eax)

        .if ( o.c == 9 )

            mov eax,[rsi].xoffs ; Align xoff and boff to next TAB
            add eax,[rsi].boffs
            mov edi,eax

            mov ebx,[rsi].tabsize
            dec bl
            and bl,TIMAXTABSIZE-1

            .if ( al & bl )

                not bl
                and bl,al
                add ebx,[rsi].tabsize

                .if ( edi > ebx ) ; Align xoff and boff to AX

                    .while 1

                        .break .if !tidecx(rsi)
                         dec edi
                        .break .if ( ebx == edi )
                    .endw

                .elseif CARRY?

                    .while 1

                        .if !( [rsi].flags & _T_USETABS )

                            .return .if tio_putc(&o, ' ')
                        .endif
                        .break .if !tiincx(rsi)
                         inc edi
                        .break .if ( ebx == edi )
                    .endw
                .endif
            .endif
        .endif
    .endif
    tio_tail(&o, rsi, o.line_ptr)
    ret

tiputc endp

tidelete proc private uses rsi rdi rbx ti:PTINFO

  local o:TIOST
  local flag:UINT

    mov rsi,ti
    lea rbx,o
    mov o.c,0

    .if tio_open(rbx, rsi)

        .return
    .endif

    mov rax,o.file_ptr
    .if ( rax == o.file_end )

        .if ( byte ptr [rax] == 13 )

            lea rcx,[rax+2]
            dec [rsi].lcount

        .elseif ( byte ptr [rax] == 10 )

            lea rcx,[rax+1]
            dec [rsi].lcount
        .else
           .return(_TI_CMFAILED)
        .endif

    .else

        .for ( rdi = &_ltype, rcx = o.line_ptr, eax = 0, ebx = 0 : : )

            mov bl,[rcx]
            inc rcx

            .break .if !ebx

            or al,[rdi+rbx+1]
        .endf

        sub rcx,o.line_ptr
        dec ecx

        .ifnz

            .if !( eax & NOT ( _SPACE or _CONTROL ) )
                ;
                ; the line is blank..
                ;
                mov rax,o.line_ptr
                mov byte ptr [rax+1],0
                sub rax,[rsi].lptr
                jz  start
            .endif

            .if !( [rsi].flags & _T_USETABS )

                mov eax,[rsi].xpos
                add eax,[rsi].xoffs
                add eax,[rsi].boffs
                add rax,o.file_ptr

                mov rcx,rax
                inc rcx
                .if ( rcx > o.file_end )

                    .return( _TI_CMFAILED )
                .endif

            .else

                mov rcx,o.line_ptr
                sub rcx,[rsi].lptr
                .ifnz
                    .if tio_copy(&o, rsi)

                        .return
                    .endif
                .endif
start:
                mov rcx,o.line_ptr
                inc rcx

                mov eax,[rsi].flags
                mov edi,eax
                and eax,not _T_OPTIMALFILL
                mov [rsi].flags,eax

                tio_tail(&o, rsi, rcx)

                and edi,_T_OPTIMALFILL
                or  [rsi].flags,edi
               .return
            .endif

        .else

            mov rcx,o.line_ptr
            sub rcx,[rsi].lptr
            .ifz
                .return( _TI_CMFAILED )
            .endif
            .if tio_copy2(&o, rsi)
                .return
            .endif
            mov rax,o.file_end
            .if ( byte ptr [rax] == 13 )
                inc rax
            .endif
            .if ( byte ptr [rax] == 10 )
                inc rax
                dec [rsi].lcount
            .endif
            mov o.file_end,rax
           .return tio_flush(&o, rsi)
        .endif
    .endif
    strcpy(rax, rcx)
    or  [rsi].flags,_T_MODIFIED
    xor eax,eax
    ret

tidelete endp

tibacksp proc private uses rsi rdi rbx ti:PTINFO

  local o:TIOST
  local x,i

    mov rsi,ti
    mov eax,[rsi].xoffs
    add eax,[rsi].boffs
    .ifz
        mov eax,[rsi].loffs
        add eax,[rsi].yoffs
        .ifz
            .return(_TI_CMFAILED)
        .endif
        tiup(rsi)
        titoend(rsi)
       .return tidelete(rsi)
    .endif

    mov o.c,0
    lea rbx,o
    .if tio_open(rbx, rsi)

        .return
    .endif

    mov rcx,o.line_ptr
    xor ebx,ebx
    .if word ptr [rcx-1] != ' '
        inc ebx
    .endif

    mov rax,[rsi].lptr
    .if ( !( [rsi].flags & _T_USEINDENT ) || rcx == rax )

        done:
        mov rdx,ti

        .if ( tileft(rdx) == 0 && ebx )

            tidelete(rdx)
        .endif
        .return
    .endif

    .while ( rax != rcx )

        cmp byte ptr [rax],' '
        ja  done
        inc rax
    .endw
    sub rax,[rsi].lptr

    mov rdx,rsi
    ;
    ; get indent from line(s) above
    ;
    mov esi,eax
    mov edi,[rdx].loffs
    add edi,[rdx].yoffs
    xor eax,eax

    .while edi

        dec edi
        .break .if !tigetline(ti, edi)

        .if ( byte ptr [rax] ) ; get indent

            mov rcx,rax
            xor eax,eax

            @@:

            .continue .if ( byte ptr [rcx+rax] == 0 )

            .if ( byte ptr [rcx+rax] <= ' ' )

                inc eax
                cmp eax,[rdx].bcol
                jb  @B

                xor eax,eax
               .break
            .endif
            .break .if ( eax < esi )
        .endif
    .endw

    mov rcx,o.line_ptr
    sub rcx,[rdx].lptr
    cmp ecx,eax
    jbe done

    sub ecx,eax
    mov edi,ecx

    mov ebx,[rdx].loffs
    add ebx,[rdx].yoffs
    mov ecx,[rdx].xoffs
    add ecx,[rdx].boffs

    mov x,ecx
    mov i,edi
    mov rsi,tigeto(ti, ebx, ecx)

    .repeat

        .break .if tileft(rdx)
        dec edi
    .untilz

    mov eax,i
    sub eax,edi
    mov ecx,x
    sub ecx,eax
    tigeto(ti, ebx, ecx)

    .if ( rsi && rax && rax < rsi )

        strcpy(rax, rsi)
    .endif
    xor eax,eax
    ret

tibacksp endp

msvalidate proc private

    mov eax,[rdx].xpos
    .if ( ecx >= eax )

        add eax,[rdx].cols
        .if ( ecx < eax )

            mov eax,[rdx].ypos
            .if ( ebx >= eax )

                add eax,[rdx].rows
                .if ( ebx < eax )

                   .return( 1 )
                .endif
            .endif
        .endif
    .endif
    xor eax,eax
    ret

msvalidate endp

    assume rbx:ptr sbyte

handle_event proc watcall private uses rsi rbx key:UINT, ti:PTINFO

    .switch eax

    .case KEY_ESC
        mov eax,_TI_RETEVENT
    .case _TI_CONTINUE
       .endc

    .case KEY_CTRLRIGHT
        ;--------------------------------------------------------------
        ; Move to Next/Prev word (Ctrl-Right, Ctrl-Left)
        ;--------------------------------------------------------------

        .if ticurcp(rdx)

            mov rcx,rax
            mov rsi,rax
            lea rbx,_ltype

            movzx eax,byte ptr [rcx]

            .while ( [rbx+rax+1] & _LABEL or _DIGIT )

                inc rcx
                mov al,[rcx]
            .endw

            .while ( eax && !( [rbx+rax+1] & _LABEL or _DIGIT ) )

                inc rcx
                mov al,[rcx]
            .endw

            .if eax

                sub rcx,rsi
                mov eax,[rdx].boffs
                add eax,[rdx].xoffs
                add eax,ecx

                .if eax <= [rdx].bcount

                    mov eax,ecx
                    add eax,[rdx].xoffs
                    mov ecx,[rdx].cols

                    .if eax >= ecx

                        dec ecx
                        sub eax,ecx
                        add [rdx].boffs,eax
                        mov [rdx].xoffs,ecx
                        xor eax,eax
                       .endc
                    .endif
                .endif

                mov [rdx].xoffs,eax
                xor eax,eax
               .endc
            .endif
            handle_event(KEY_DOWN, rdx)
           .return handle_event(KEY_HOME, rdx)
        .endif
        xor eax,eax
       .endc

    .case KEY_CTRLLEFT

        .if ticurlp(rdx)

            mov rcx,rax
            mov eax,[rdx].boffs
            add eax,[rdx].xoffs
            .ifz
                .if !tiup(rdx)

                    titoend(rdx)
                   .gotosw(KEY_CTRLLEFT)
                .endif
                .endc
            .endif

            lea rbx,_ltype
            lea rsi,[rcx+rax-1]
            movzx eax,byte ptr [rsi]
            .while ( rcx < rsi && !( [rbx+rax+1] & _LABEL or _DIGIT ) )

                dec rsi
                mov al,[rsi]
            .endw
            .while ( rcx < rsi && [rbx+rax+1] & _LABEL or _DIGIT )

                dec rsi
                mov al,[rsi]
            .endw
            .if !( [rbx+rax+1] & _LABEL or _DIGIT )

                mov al,[rsi+1]
                .if ( [rbx+rax+1] & _LABEL or _DIGIT )

                    inc rsi
                .endif
            .endif
            mov rax,rsi
            mov ebx,[rdx].boffs
            add ebx,[rdx].xoffs
            add rcx,rbx
            sub rcx,rax
            .if ecx > [rdx].xoffs

                sub ecx,[rdx].xoffs
                mov [rdx].xoffs,0
                sub [rdx].boffs,ecx
            .else
                sub [rdx].xoffs,ecx
            .endif
        .endif
        xor eax,eax
       .endc

    .case KEY_LEFT
        tileft(rdx)
       .endc

    .case KEY_RIGHT
        .if !tiincx(rdx)
            mov eax,_TI_CMFAILED
        .else
            xor eax,eax
        .endif
        .endc

    .case KEY_HOME
        tihome(rdx)
       .endc

    .case KEY_END
        titoend(rdx)
       .endc

    .case KEY_BKSP
        tibacksp(rdx)
       .endc

    .case KEY_DEL
        tidelete(rdx)
       .endc

    .case KEY_UP
        tiup(rdx)
       .endc

    .case KEY_DOWN
        mov eax,[rdx].loffs
        mov ecx,[rdx].yoffs
        add eax,ecx
        inc eax
        .if eax >= [rdx].lcount
            mov eax,_TI_CMFAILED
           .endc
        .endif
        mov eax,[rdx].rows
        dec eax
        .if ecx < eax
            inc [rdx].yoffs
            xor eax,eax
           .endc
        .endif
        mov eax,[rdx].lcount
        sub eax,[rdx].loffs
        sub eax,ecx
        .if eax < 2
            mov eax,_TI_CMFAILED
           .endc
        .endif
        inc [rdx].loffs
        xor eax,eax
       .endc

    .case KEY_PGUP
        mov eax,[rdx].rows
        .if [rdx].loffs >= eax
            sub [rdx].loffs,eax
            xor eax,eax
           .endc
        .endif

    .case KEY_CTRLHOME
        xor eax,eax
        mov [rdx].boffs,eax
        mov [rdx].xoffs,eax

    .case KEY_CTRLPGUP
        xor eax,eax
        mov [rdx].loffs,eax
        mov [rdx].yoffs,eax
       .endc

    .case KEY_PGDN
        mov eax,[rdx].rows
        add eax,eax
        add eax,[rdx].loffs
        .if eax < [rdx].lcount
            mov eax,[rdx].loffs
            add eax,[rdx].rows
            mov [rdx].loffs,eax
            xor eax,eax
           .endc
        .endif

    .case KEY_CTRLEND
        mov eax,[rdx].lcount
        .if eax
            dec eax
            mov rcx,rdx
            tialigny(rcx, eax)
            xor eax,eax
           .endc
        .endif
        mov eax,_TI_CMFAILED
       .endc

    .case KEY_CTRLPGDN
        mov eax,[rdx].rows
        dec eax
        mov [rdx].yoffs,eax
        add eax,[rdx].loffs
        .if eax >= [rdx].lcount
            xor eax,eax
           .endc
        .endif
        .gotosw(KEY_CTRLEND)

    .case KEY_CTRLUP
        xor eax,eax
        .if eax != [rdx].loffs
            dec [rdx].loffs
           .endc
        .endif
        mov eax,_TI_CMFAILED
       .endc

    .case KEY_CTRLDN
        mov eax,[rdx].loffs
        add eax,[rdx].yoffs
        inc eax
        cmp eax,[rdx].lcount
        mov eax,_TI_CMFAILED
        .endc .ifnb
        inc [rdx].loffs
        xor eax,eax
       .endc

    .case KEY_MOUSEUP
        xor eax,eax
        mov ecx,3
        .if ecx <= [rdx].loffs
            sub [rdx].loffs,ecx
           .endc
        .endif
        .if eax != [rdx].loffs
            mov [rdx].loffs,eax
           .endc
        .endif
        mov eax,_TI_CMFAILED
       .endc

      .case KEY_MOUSEDN
        mov eax,[rdx].loffs
        add eax,[rdx].yoffs
        add eax,3
        .if eax < [rdx].lcount

            add [rdx].loffs,3
            xor eax,eax
           .endc
        .endif
        mov eax,_TI_CMFAILED
       .endc

      .case KEY_ENTER
      .case KEY_KPENTER
        mov eax,10
      .default
        mov rcx,rdx
        tiputc(rcx, eax)
       .endc
    .endsw
    ret

handle_event endp

    assume rbx:nothing

ticlippaste proc private uses rsi rdi rbx ti:PTINFO

   .new flag:uint_t
   .new yoff:uint_t
   .new loff:uint_t
   .new xoff:uint_t
   .new boff:uint_t
   .new c:int_t

    mov rsi,ti
    mov eax,[rsi].flags

    .if eax & _T_OVERWRITE
        ticlipdel(rsi)
    .else
        ticlipset(rsi)
    .endif

    .if ClipboardPaste()

        mov rbx,rax
        mov flag,[rsi].flags
        mov yoff,[rsi].yoffs
        mov loff,[rsi].loffs
        mov xoff,[rsi].xoffs
        mov boff,[rsi].boffs

        and [rsi].flags,not (_T_USEINDENT or _T_OPTIMALFILL)
        mov esi,clipbsize
        mov rdi,rbx

        .repeat

            .repeat

                movzx eax,byte ptr [rdi]
                .break(1) .if !eax

                inc rdi
                mov c,eax
                .if ( tiputc(ti, eax) != _TI_CONTINUE )

                    .break( 1 )
                .endif
                dec esi
                .ifz
                    .break( 1 )
                .endif
                mov eax,c
                lea rcx,_ltype
            .until !( byte ptr [rcx+rax+1] & _SPACE )

            .if ( esi >= 128 )

                .while 1

                    mov rcx,ti
                    mov eax,[rcx].TINFO.yoffs
                    add eax,[rcx].TINFO.loffs
                    mov edx,[rcx].TINFO.xoffs
                    add edx,[rcx].TINFO.boffs
                    .break(1) .if !tigeto(rcx, eax, edx)

                    mov rbx,rax
                    strlen(rax)
                    add eax,esi
                    add rax,rbx
                    mov rdx,ti
                    mov ecx,[rdx].bsize
                    add rcx,[rdx].base
                    sub rcx,128

                    .if ( eax < ecx )

                        strins(rbx, rdi)

                        mov rdx,ti
                        mov [rdx].lcount,1
                        mov rax,[rdx].base

                        .while strchr(rax, 10)
                            mov rdx,ti
                            inc [rdx].lcount
                            inc rax
                        .endw
                        .break( 1 )
                    .endif
                    .break( 1 ) .if !tirealloc(ti)
                .endw
            .endif

            .while esi

                movzx eax,byte ptr [rdi]
                .break .if !eax
                inc rdi
                tiputc(ti, eax)
                .break .if eax != _TI_CONTINUE
                dec esi
            .endw
        .until 1

        ClipboardFree()

        mov rsi,ti
        mov [rsi].boffs,boff
        mov [rsi].xoffs,xoff
        mov [rsi].yoffs,yoff
        mov [rsi].loffs,loff
        mov eax,flag
        or  eax,_T_MODIFIED
        mov [rsi].flags,eax
    .endif
    ticlipset(rsi)
    xor eax,eax
    ret

ticlippaste endp

tievent proc private uses rsi rdi rbx ti:PTINFO, event:UINT


    .if !tiselected(ti)

        ticlipset(rdx)
    .endif

    mov rax,keyshift
    mov ecx,[rax]
    mov eax,event
    mov rsi,rdx

    .switch

    .case eax == MOUSECMD

        ;--------------------------------------------------------------
        ; Mouse Event
        ;--------------------------------------------------------------

        mousep()
        mov ebx,keybmouse_y
        mov ecx,keybmouse_x

        .if eax == KEY_MSRIGTH

            mov rbx,IDD_TEQuickMenu
            mov eax,keybmouse_x
            mov [rbx+6],al
            mov eax,keybmouse_y
            mov [rbx+7],al

            .if rsmodal(rbx)

                lea rcx,QuickMenuKeys
                PushEvent([rcx+rax*4-4])
                msloop()
            .endif
            jmp continue

        .elseif eax == KEY_MSLEFT

            .if msvalidate()

                sub ebx,[rdx].ypos
                sub ecx,[rdx].xpos
                mov [rdx].yoffs,ebx
                mov [rdx].xoffs,ecx

                ticlipset(rdx)
                mov esi,[rdx].clip_sl
                mov edi,[rdx].clip_so

                .while  1

                    tiputs(rdx)
                    Sleep(CON_SLEEP_TIME)
                    mousep()
                    mov rdx,ti
                    mov ebx,keybmouse_y
                    mov ecx,keybmouse_x
                    cmp eax,KEY_MSLEFT
                    jne return_event

                    .continue .if !msvalidate()

                    sub ebx,[rdx].ypos
                    sub ecx,[rdx].xpos
                    mov [rdx].yoffs,ebx
                    mov [rdx].xoffs,ecx
                    add ecx,[rdx].boffs
                    add ebx,[rdx].loffs

                    .if edi > ecx
                        mov [rdx].clip_so,ecx
                    .else
                        mov [rdx].clip_eo,ecx
                        .ifz
                            mov [rdx].clip_so,ecx
                        .endif
                    .endif
                    .if esi > ebx
                        mov [rdx].clip_sl,ebx
                    .else
                        mov [rdx].clip_el,ebx
                        .ifz
                            mov [rdx].clip_sl,ebx
                        .endif
                    .endif

                    mov eax,[rdx].yoffs
                    .if !eax
                        handle_event(KEY_CTRLUP, rdx)
                    .else
                        inc eax
                        .if eax == [rdx].rows
                            handle_event(KEY_CTRLDN, rdx)
                        .endif
                    .endif
                .endw
            .endif
        .endif
        jmp return_event

    .case eax == KEY_CTRLINS
    .case eax == KEY_CTRLC
        ticlipcut(rsi, 0)
        .endc

    .case eax == KEY_CTRLV
        ticlippaste(rdx)
        .endc

    .case eax == KEY_CTRLDEL
        ticlipcut(rsi, 1)
        .endc

    .case ecx & SHIFT_KEYSPRESSED

        .switch eax
        .case KEY_INS
            ticlippaste(rdx)
            jmp continue
        .case KEY_DEL
            ticlipcut(rsi, 1)
            jmp continue
        .case KEY_HOME
        .case KEY_LEFT
        .case KEY_RIGHT
        .case KEY_END
        .case KEY_UP
        .case KEY_DOWN
        .case KEY_PGUP
        .case KEY_PGDN
            handle_event(eax, rdx)
            mov ecx,event

            cmp eax,_TI_CMFAILED
            je  continue
            cmp eax,_TI_RETEVENT
            je  continue

            mov rdx,ti
            mov ebx,[rdx].loffs
            add ebx,[rdx].yoffs
            mov eax,[rdx].boffs
            add eax,[rdx].xoffs
            cmp ebx,[rdx].clip_sl
            jb  case_tostart

            cmp eax,[rdx].clip_so
            jb  case_tostart
            cmp ecx,KEY_RIGHT
            jne @F
            lea ecx,[rax-1]
            cmp ecx,[rdx].clip_so
            jne @F
            cmp ecx,[rdx].clip_eo
            jne case_tostart
            @@:
            mov [rdx].clip_eo,eax
            mov [rdx].clip_el,ebx
            jmp continue
        .endsw
        .endc

    .case eax == KEY_DEL

        .if !ticlipdel(rdx)
            jmp clipset
        .endif
        jmp continue

    .endsw

    .switch
    .case eax == KEY_ESC
    .case eax == MOUSECMD
    .case eax == KEY_BKSP
    .case eax == KEY_ENTER
    .case eax == KEY_KPENTER
    .case !al
        jmp clipset
    .endsw

    ticlipdel(rdx)

clipset:

    ticlipset(rdx)
    handle_event(event, rdx)
toend:
    ret

case_tostart:
    mov [rdx].clip_so,eax
    mov [rdx].clip_sl,ebx

continue:
    xor eax,eax
    jmp toend

return_event:
    mov eax,_TI_RETEVENT
    jmp toend

tievent endp

    assume rdx:nothing
    assume rdi:PDOBJ

tishow proc uses rsi rdi rbx ti:PTINFO

    mov rsi,ti
    .if rsi

        lea rdi,[rsi].dobj
        .if !( [rdi].flag & _D_DOPEN )

            tsetrect(rsi, tgetrect())
            mov edx,[rsi].clrc
            .if [rsi].flags & _T_USESTYLE
                mov edx,[rsi].stylec
            .endif
            shr edx,16

            .if rcopen([rdi].rc, _D_CLEAR or _D_BACKG, edx, 0, 0)

                mov [rdi].wp,rax
                mov [rdi].flag,_D_DOPEN
            .endif
        .endif

        .if ( [rdi].flag & _D_DOPEN )

            .if !( [rdi].flag & _D_ONSCR )

                dlshow(rdi)
            .endif
            xor eax,eax
            mov [rsi].crc,eax

            .if ( [rsi].flags & _T_USEMENUS )

                movzx ecx,[rdi].rc.x
                movzx ebx,[rdi].rc.y
                mov   edx,[rsi].cols
                movzx eax,at_background[B_Menus]
                or    al,at_foreground[F_Menus]
                shl   eax,16
                mov   al,' '
                lea   edi,[rcx+1]

                scputw(ecx, ebx, edx, eax)

                mov ecx,[rsi].cols
                sub ecx,19
                scpath(edi, ebx, ecx, [rsi].file)
            .endif
            tiputs(rsi)
        .endif
    .endif
    ret

tishow endp


titogglemenus proc private uses rsi ti:PTINFO

    mov rsi,ti
    .if tistate(rsi)

        tihide(rsi)

        movzx edx,[rsi].dobj.rc.y
        movzx ecx,[rsi].dobj.rc.row
        mov eax,[rsi].flags
        xor eax,_T_USEMENUS
        mov [rsi].flags,eax

        .if ( eax & _T_USEMENUS )

            inc edx
            dec ecx
        .endif
        mov [rsi].ypos,edx
        mov [rsi].rows,ecx

        tishow(rsi)
    .endif
    .return( 0 )

titogglemenus endp


    assume rsi:PTINFO
    assume rdi:PTINFO

titogglefile proc uses rsi rdi rbx old:PTINFO, new:PTINFO

    ldr rdi,old
    ldr rax,new
    mov rbx,rdi
    mov rsi,rax

    .if ( rsi != rdi && [rsi].flags & _T_TEDIT )

        mov rbx,rsi
        tishow(rsi)

        .if ( [rsi].dobj.flag & _D_DOPEN )

            and [rdi].dobj.flag,NOT (_D_DOPEN OR _D_ONSCR)
            free([rsi].dobj.wp)
            mov rax,[rdi].dobj.wp
            mov [rsi].dobj.wp,rax
        .else
            mov rbx,rdi
        .endif
    .endif
    .return(rbx)

titogglefile endp

topen proc uses rsi rdi file:LPSTR, tflag:UINT

    .if tiopen(tinfo, titabsize, tiflags)

        mov rsi,rax
        or  [rsi].flags,_T_FILE
        mov rdi,[rsi].prev
        mov tinfo,rax
        mov eax,tflag
        .if eax

            and [rsi].flags,NOT _T_TECFGMASK
            or  [rsi].flags,eax
        .endif

        mov rax,file
        .if rax

            .if ( byte ptr [strcpy([rsi].file, rax) + 1] != ':' )

                GetFullPathName(rax, _MAX_PATH * 2, rax, 0)
            .endif

            .if tireadstyle(rsi)

                tiread(rsi)
            .else
                ermsg(0, _sys_errlist[ENOMEM*size_t])
                ticlose(rsi)
                xor esi,esi
            .endif

        .else

            and [rsi].flags,NOT _T_UNREAD
            inc [rsi].TINFO.lcount ; set line count to 1
            .repeat
                inc new_id
                sprintf([rsi].file, "New (%d)", new_id)
                filexist([rsi].file)
            .until eax != 1

            .if rdi

                memcpy([rsi].style, [rdi].style, STYLESIZE)
                mov eax,[rdi].stylec
                mov [rsi].stylec,eax
            .else
                tireadstyle(rsi)
            .endif
        .endif
        mov rax,rsi
    .endif
    ret

topen endp

    assume rdi:nothing

SaveChanges proc uses rsi rdi file:LPSTR

    .if rsopen(IDD_TESave)

        mov rsi,rax
        dlshow(rax)
        xor ecx,ecx
        mov cl,[rsi][6]
        sub cl,10
        mov ax,[rsi][4]
        add ax,0x0205
        mov dl,ah
        scpath(eax, edx, ecx, file)
        mov edi,rsevent(IDD_TESave, rsi)
        dlclose(rsi)
        mov eax,edi
    .endif
    ret

SaveChanges endp

tclose proc

    .if tistate(tinfo)
        .if ecx & _T_MODIFIED
            mov rdx,tinfo
            .if SaveChanges([rdx].TINFO.file)

                tiflush(tinfo)
            .endif
        .endif
        ticlose(tinfo)
        mov tinfo,rax
    .else
        mov new_id,eax
    .endif
    ret

tclose endp

tcloseall proc

    .while tclose()
    .endw
    ret

tcloseall endp

tclosefile proc private uses rbx

    .if tclose()

        mov rbx,rax
        tishow(rax)
        mov tinfo,rbx
        xor eax,eax
    .else
        mov eax,_TI_RETEVENT
    .endif
    ret

tclosefile endp

tiupdate proc private uses rsi

    mov rsi,tinfo
    .if tistate(rsi)

        .if edx & _D_ONSCR && ecx & _T_USEMENUS

            mov eax,[rsi].loffs
            add eax,[rsi].yoffs
            mov edx,[rsi].xoffs
            add edx,[rsi].boffs

            .if eax != tiupdate_line || edx != tiupdate_offs

                mov tiupdate_offs,edx
                mov tiupdate_line,eax

                timenus(rsi)
            .endif
        .endif
    .endif
    xor eax,eax
    ret

tiupdate endp

tilseek proc private uses rsi rdi ti:PTINFO

    ldr rsi,ti
    .if rsopen(IDD_TESeek)

        mov rdi,rax
        mov ecx,[rsi].TINFO.loffs
        add ecx,[rsi].TINFO.yoffs
        inc ecx

        sprintf([rdi+TOBJ].TOBJ.data, "%u", ecx)
        dlinit(rdi)

        .if rsevent(IDD_TESeek, rdi)
            .if strtolx([rdi+TOBJ].TOBJ.data)
                dec eax
                tialigny(rsi, eax)
            .endif
        .endif
        dlclose(rdi)
        tiputs(rsi)
    .endif
    xor eax,eax
    ret

tilseek endp

    assume rsi:nothing

tnewfile proc private uses rsi

    mov rsi,tinfo
    .if topen(0, 0)

        titogglefile(rsi, rax)
        mov tinfo,rax
    .endif
    ret

tnewfile endp

tnextfile proc private

    .if tigetfile(tinfo)

        .if ecx > 1

            mov rcx,tinfo
            .if [rcx].TINFO.next
                mov rax,[rcx].TINFO.next
            .endif
            titogglefile(rcx, rax)
        .endif
        mov tinfo,rax
    .endif
    ret

tnextfile endp

MAXDLGOBJECT    equ 16
MAXOBJECTLEN    equ 38
ID_ACTIVATE     equ 17
ID_SAVE         equ 18
ID_CLOSE        equ 19

    .code

event_list proc private uses rsi rdi rbx

   .new x:int_t
   .new y:int_t

    mov rsi,rax
    mov rdi,rdx
    dlinit(rsi)

    lea rax,[rsi+TOBJ]
    mov ecx,MAXDLGOBJECT
    .repeat
        or  [rax].TOBJ.flag,_O_STATE
        lea rax,[rax+TOBJ]
    .untilcxz

    movzx eax,[rsi].DOBJ.rc.x
    movzx edx,[rsi].DOBJ.rc.y
    add   eax,4
    add   edx,2
    mov   x,eax
    mov   y,edx

    mov ebx,[rdi].LOBJ.numcel
    mov eax,[rdi].LOBJ.index
    mov rdi,[rdi].LOBJ.list
    lea rdi,[rdi+rax*PTINFO]

    .while ebx

        mov rdx,[rdi]
        .if ( [rdx].TINFO.flags & _T_MODIFIED )
            dec x
            scputc(x, y, 1, '*')
            inc x
            mov rdx,[rdi]
        .endif
        scpath(x, y, MAXOBJECTLEN, [rdx].TINFO.file)

        add rdi,size_t
        add rsi,TOBJ
        and [rsi].TOBJ.flag,not _O_STATE
        inc y
        dec ebx
    .endw
    .return( 1 )

event_list endp

tdlgopen proc uses rsi rdi rbx

  local ll:LOBJ, ti[TIMAXFILES]:size_t

    lea rdi,ll
    xor eax,eax
    mov ecx,LOBJ
    rep stosb

    lea rdi,ti
    mov ll.list,rdi
    mov ecx,sizeof(ti)
    rep stosb

    mov ll.dcount,MAXDLGOBJECT   ; number of cells (max)
    mov ll.lproc,&event_list

    .if tigetfile(tinfo)

        mov rsi,rax
        xor ebx,ebx
        mov rdi,ll.list

        .repeat

            .break .if !tistate(rsi)

            mov [rdi],rsi
            add rdi,size_t
            mov rsi,[rsi].TINFO.next
            inc ebx
        .until ( ebx >= TIMAXFILES )

        mov ll.count,ebx
        mov eax,ebx
        .if eax >= MAXDLGOBJECT
            mov eax,MAXDLGOBJECT
        .endif
        mov ll.numcel,eax

        .if rsopen(IDD_TEWindows)

            mov rdi,rax
            dlshow(rax)

            mov rax,rdi
            lea rdx,ll
            event_list()

            mov ebx,dllevent(rdi, &ll)
            mov dx,[rdi+4]
            mov rcx,IDD_TEWindows
            mov [rcx+6],dx
            dlclose(rdi)

            xor eax,eax
            .if ( ebx && ll.count != eax )

                mov eax,ll.index
                add eax,ll.celoff
                mov rax,ti[rax*size_t]
                .if rax
                    xchg rax,rbx
                    .if eax == ID_CLOSE
                        mov eax,1
                    .elseif eax == ID_SAVE
                        mov eax,2
                    .else
                        mov rax,rbx
                    .endif
                .endif
            .endif
        .endif
    .endif
    ret

tdlgopen endp

twindows proc private
    .switch tdlgopen()
      .case 2
        tiflush(tinfo)
        .endc
      .case 1
        tclosefile()
      .case 0
        .endc
      .default
        mov tinfo,titogglefile(tinfo, rax)
    .endsw
    ret
twindows endp

    assume rsi:PTINFO

twindowsize proc private uses rsi rdi rbx

    .if tigetfile(tinfo)

        mov rsi,rax
        mov rdi,rdx
        xor cflag,_C_PANELEDIT
        mov ebx,tgetrect()

        .if ebx != [rsi].dobj.rc

            .while rsi

                tihide(rsi)

                and [rsi].flags,NOT _T_PANELB
                .if cflag & _C_PANELEDIT

                    or  [rsi].flags,_T_PANELB
                    and [rsi].flags,NOT _T_USEMENUS
                    and tiflags,NOT _T_USEMENUS
                .else
                    or  [rsi].flags,_T_USEMENUS
                    or  tiflags,_T_USEMENUS
                .endif
                tsetrect(rsi, ebx)

                .break .if rsi == rdi
                mov rsi,[rsi].next
            .endw
            tishow(tinfo)
        .endif
    .endif
    ret

twindowsize endp

    assume rbx:PTINFO

tiseto proc private uses rsi rdi rbx ti:PTINFO

    ldr rbx,ti
    mov eax,[rbx].loffs         ; test current line
    add eax,[rbx].yoffs

    .if eax > [rbx].lcount
        xor eax,eax
        mov [rbx].loffs,eax
        mov [rbx].yoffs,eax
    .endif

    .if ticurlp(rbx)            ; get pointer to current line

        mov rdi,rax
        mov esi,ecx

        mov ecx,[rbx].boffs     ; strip space from end
        add ecx,[rbx].xoffs
        add rax,rcx
        stripend(rax)

        mov eax,[rbx].boffs     ; test if char is visible
        add eax,[rbx].xoffs

        .if eax > esi

            add rdi,rsi     ; length of line
            sub eax,esi
            mov ecx,eax     ; ECX to pad count
            mov eax,' '
            rep stosb
            mov [rdi],ah
            mov eax,1
        .else
            xor eax,eax
        .endif
    .endif
    mov rdx,rbx
    ret

tiseto endp

tireload proc private uses rbx ti:PTINFO

    ldr rbx,ti

    .if [rbx].flags & _T_MODIFIED

        .if !rsmodal(IDD_TEReload2)

            .return
        .endif
    .endif

    timemzero(rbx)
    .if tiread(rbx)

        tiseto(rbx)
        tiputs(rbx)
        mov eax,1
    .endif
    ret

tireload endp

    assume rbx:nothing

.enumt TOption:TOBJ {
    ID_USEMENUS = 1,
    ID_OPTIMALFILL,
    ID_OVERWRITE,
    ID_USEINDENT,
    ID_USESTYLE,
    ID_USETABS,
    ID_USEBAKFILE,
    ID_USECRLF,
    ID_TABSIZE
    }

toption proc uses rbx

    .if rsopen(IDD_TEOptions)

        mov rbx,rax
        sprintf([rbx].TOBJ.data[ID_TABSIZE], "%u", titabsize)

        mov eax,tiflags
        shr eax,5
        tosetbitflag([rbx].DOBJ.object, 8, _O_FLAGB, eax)
        dlinit(rbx)

        .if rsevent(IDD_TEOptions, rbx)

            togetbitflag([rbx].DOBJ.object, 8, _O_FLAGB)
            shl eax,5
            mov tiflags,eax

            strtolx([rbx].TOBJ.data[ID_TABSIZE])
            mov ah,al
            mov al,128
            .repeat
                shl ah,1
                .break .ifc
                shr al,1
            .untilz

            .if al > TIMAXTABSIZE
                mov al,TIMAXTABSIZE
            .elseif al < 2
                mov al,2
            .endif
            movzx eax,al
            mov titabsize,eax
        .endif
        mov rcx,rbx
        mov ebx,eax
        dlclose(rcx)
        mov eax,ebx
    .endif
    ret

toption endp

    assume rdx:PTINFO

tioption proc private uses rsi rdi ti:PTINFO

    ldr rdx,ti
    mov esi,titabsize
    mov edi,tiflags

    mov eax,[rdx].flags
    mov tiflags,eax

    mov eax,[rdx].tabsize
    mov titabsize,eax

    toption()
    .repeat

        mov eax,titabsize
        mov ecx,tiflags
        mov tiflags,edi
        mov titabsize,esi

        mov rdx,ti
        .break .if ( eax == [rdx].tabsize && ecx == [rdx].flags )

        mov esi,eax
        mov eax,[rdx].flags
        mov edi,eax
        and ecx,_T_TECFGMASK
        and eax,not _T_TECFGMASK
        or  eax,ecx
        mov [rdx].flags,eax

        mov eax,edi
        and eax,_T_USETABS
        and ecx,_T_USETABS

        .if eax != ecx || esi != [rdx].tabsize

            .if edi & _T_MODIFIED

                .if SaveChanges([rdx].file)

                    tiflush(ti)
                .endif
            .endif
            mov rdx,ti
            mov [rdx].tabsize,esi
            tireload(rdx)
        .endif
    .until 1
    ret

tioption endp

    assume rdx:nothing

tisaveas proc private uses rsi ti:PTINFO

    ldr rsi,ti

    .if tigetfilename(rsi)

        tiflush(rsi)

        xor [rsi].TINFO.flags,_T_USEMENUS
        titogglemenus(rsi)
    .endif
    xor eax,eax
    ret
tisaveas endp

tisearchsetoff proc private ti:PTINFO

    .if sflag & IO_SEARCHSET
        xor eax,eax
        mov tisearch_off,eax
        mov tisearch_line,eax
    .else
        mov rdx,ti
        mov eax,[rdx].TINFO.boffs
        add eax,[rdx].TINFO.xoffs
        mov tisearch_off,eax
        mov eax,[rdx].TINFO.loffs
        add eax,[rdx].TINFO.yoffs
        mov tisearch_line,eax
    .endif
    ret

tisearchsetoff endp

tisearchcontinue proc private uses rsi rdi rbx clear_selection:UINT, ti:PTINFO

    local offs:UINT

    .if !strlen(&searchstring)

        dec eax
    .else

        mov rdx,ti
        mov esi,eax

        tisearchsetoff(rdx)
        and sflag,not IO_SEARCHSET
        mov eax,tisearch_line
        mov ebx,eax

        .if !tigetline(ti, eax)
            dec rax
        .else
            mov eax,tisearch_off

            .if eax <= [rdx].TINFO.bcount

                mov rdi,[rdx].TINFO.lptr
                lea rdi,[rdi+rax+1]
            .else

                nextline:

                inc ebx
                .if !tigetnextl(ti)

                    notfoundmsg()
                   .return(-1)
                .endif
                mov rdi,rax
             .endif

            .if !( fsflag & IO_SEARCHCASE )

                .repeat
                    mov al,searchstring
                    and rax,strchri(rdi, eax)
                    jz  nextline
                    lea rdi,[rax+1]
                .until !_strnicmp(&searchstring, rax, esi)
            .else
                .repeat
                    mov al,searchstring
                    and rax,strchr(rdi, eax)
                    jz  nextline
                    lea rdi,[rax+1]
                .until !strncmp(&searchstring, rax, esi)
            .endif

            mov rdx,ti
            dec rdi
            sub rdi,[rdx].TINFO.lptr
            mov tisearch_line,ebx
            mov tisearch_off,edi

            tialigny(ti, ebx)
            mov eax,tisearch_off
            inc tisearch_off
            tialignx(ti, eax)
            ticlipset(rdx)
            add [rdx].TINFO.clip_eo,esi
            tiputs(rdx)
            xor eax,eax
            .if eax != clear_selection
                ticlipset(rdx)
                xor eax,eax
            .endif
        .endif
    .endif
    ret

tisearchcontinue endp

ticontsearch proc private uses rbx ti:PTINFO

    mov ebx,fsflag
    tisearchcontinue(1, ti)
    mov fsflag,ebx
    xor eax,eax
    ret

ticontsearch endp

tisearch proc private ti:PTINFO

    .if cmsearchidd(fsflag)

        mov eax,fsflag
        and eax,not IO_SEARCHMASK
        and edx,IO_SEARCHMASK
        or  eax,edx
        mov fsflag,eax
        mov sflag,eax
        ticontsearch(ti)
    .endif
    ret

tisearch endp

tisearchxy proc private ti:PTINFO

  local linebuf[256]:byte

    .if scgetword(&linebuf)

        strcpy(&searchstring, rax)
        tisearch(ti)
    .endif
    ret
tisearchxy endp

;-----------------------------------------------------------------------------
; Replace
;-----------------------------------------------------------------------------

ID_YES  equ 1
ID_ALL  equ 2
ID_NO   equ 3

iddreplaceprompt proc private uses rbx ti:PTINFO

    mov eax,1
    mov rbx,ti

    .if [rbx].TINFO.flags & _T_PROMPTONREP

        .if rsmodal(IDD_ReplacePrompt)

            lea edx,[rax-1]
            mov rbx,IDD_ReplacePrompt
            mov [rbx].RIDD.index,dl
            mov rbx,ti

            .if eax == ID_ALL
                xor [rbx].TINFO.flags,_T_PROMPTONREP
            .endif
        .endif
    .endif
    ret

iddreplaceprompt endp

ID_OLDSTRING    equ 1*TOBJ
ID_NEWSTRING    equ 2*TOBJ
ID_USECASE      equ 3*TOBJ
ID_PROMPT       equ 4*TOBJ
ID_CURSOR       equ 5*TOBJ
ID_GLOBAL       equ 6*TOBJ
ID_OK           equ 7
ID_CHANGEALL    equ 8

iddreplace proc private uses rsi rbx

    .if rsopen(IDD_Replace)

        mov rbx,rax
        mov [rbx].TOBJ.count[ID_OLDSTRING],256 shr 4
        mov [rbx].TOBJ.count[ID_NEWSTRING],256 shr 4
        lea rax,searchstring
        mov [rbx].TOBJ.data[ID_OLDSTRING],rax
        lea rax,replacestring
        mov [rbx].TOBJ.data[ID_NEWSTRING],rax
        mov eax,fsflag
        mov dl,_O_FLAGB
        .if eax & IO_SEARCHCASE
            or [rbx][ID_USECASE],dl
        .endif
        .if eax & _T_PROMPTONREP
            or [rbx][ID_PROMPT],dl
        .endif
        mov edx,_O_RADIO
        .if eax & IO_SEARCHCUR
            or  [rbx][ID_CURSOR],dl
            xor edx,edx
        .endif
        or  [rbx][ID_GLOBAL],dl
        dlinit(rbx)

        .if rsevent(IDD_Replace, rbx)

            mov eax,fsflag
            and eax,not (IO_SEARCHMASK or _T_PROMPTONREP)
            mov dl,_O_FLAGB
            .if [rbx][ID_USECASE] & dl
                or  eax,IO_SEARCHCASE
            .endif
            .if [rbx][ID_PROMPT] & dl
                or  eax,_T_PROMPTONREP
            .endif
            mov edx,IO_SEARCHSET
            .if byte ptr [rbx][ID_CURSOR] & _O_RADIO
                mov edx,IO_SEARCHCUR
            .endif
            or  edx,eax
            xor eax,eax
            .if searchstring != al
                inc eax
            .endif
        .endif
        mov esi,eax
        mov rcx,rbx
        mov ebx,edx
        dlclose(rcx)
        mov eax,esi
        mov edx,ebx
    .endif
    ret

iddreplace endp

tireplace proc private uses rsi rdi rbx ti:PTINFO

    mov rsi,ti
    mov eax,_T_PROMPTONREP
    or  [rsi].TINFO.flags,eax

    .if iddreplace()

        mov fsflag,edx
        mov sflag,edx
        .if eax == ID_CHANGEALL || !( edx & _T_PROMPTONREP )
            and [rsi].TINFO.flags,not _T_PROMPTONREP
        .endif
        .while !tisearchcontinue(0, rsi)

            .break .if !iddreplaceprompt(rsi)
            .continue .if eax == ID_NO

            ticlipdel(rsi)          ; delete text
            lea rdi,replacestring   ; add new text
            mov al,[rdi]
            .while al
                tiputc(rsi, eax)
                inc rdi
                mov al,[rdi]
            .endw
        .endw
    .endif
    tiputs(rsi)
    ticlipset(rsi)
    xor eax,eax
    ret
tireplace endp

tihandler proc private uses rsi

    mov rdx,tinfo

    .switch pascal eax

      .case KEY_F1:     view_readme(HELPID_05)
      .case KEY_F2:     tiflush(rdx)
      .case KEY_F3:     tisearch(rdx)
      .case KEY_F4:     tireplace(rdx)
      .case KEY_F5:     tnewfile()
      .case KEY_F6:     tnextfile()
      .case KEY_F7:     twindowsize()
      .case KEY_F8:     tsavefiles()
      .case KEY_F9:     tloadfiles()
      .case KEY_F11:    titogglemenus(rdx)

      .case KEY_ESC:    tihideall(rdx) : jmp return
      .case KEY_CTRLF2: tisaveas(rdx)
      .case KEY_CTRLF9: tioption(rdx)
      .case KEY_CTRLA:  tiselectall(rdx)
      .case KEY_CTRLB:  consuser()
      .case KEY_CTRLC:  titransfer()
      .case KEY_CTRLF:  mov eax,_T_OPTIMALFILL : jmp toggle
      .case KEY_CTRLG:  tilseek(rdx)
      .case KEY_CTRLI:  mov eax,_T_USEINDENT : jmp toggle
      .case KEY_CTRLL:  ticontsearch(rdx)
      .case KEY_CTRLM:  titogglemenus(rdx)
      .case KEY_CTRLO:  consuser()
      .case KEY_CTRLR:  tireload(rdx)
      .case KEY_CTRLS:  mov eax,_T_USESTYLE : jmp toggle
      .case KEY_CTRLT:  mov eax,_T_SHOWTABS : jmp toggle
      .case KEY_CTRLX:  tclosefile() : jmp toend

      .case KEY_SHIFTF1:    TIShiftFx(1)
      .case KEY_SHIFTF2:    TIShiftFx(2)
      .case KEY_SHIFTF3:    TIShiftFx(3)
      .case KEY_SHIFTF4:    TIShiftFx(4)
      .case KEY_SHIFTF5:    TIShiftFx(5)
      .case KEY_SHIFTF6:    TIShiftFx(6)
      .case KEY_SHIFTF7:    TIShiftFx(7)
      .case KEY_SHIFTF8:    TIShiftFx(8)
      .case KEY_SHIFTF9:    TIShiftFx(9)

      .case KEY_ALTF1
        mov rsi,rdx
        .if topen(strfcat(__srcfile, _pgmpath, addr DZ_INIFILE), 0)

            mov tinfo,titogglefile(rsi, rax)
        .endif

    .case KEY_ALTF2:  TIAltFx(2)
    .case KEY_ALTF3:  TIAltFx(3)
    .case KEY_ALTF4:  TIAltFx(4)
    .case KEY_ALTF5:  TIAltFx(5)
    .case KEY_ALTF6:  TIAltFx(6)
    .case KEY_ALTF7:  tipreviouserror()
    .case KEY_ALTF8:  tinexterror()
    .case KEY_ALTF9:  TIAltFx(9)
    .case KEY_ALT0:   twindows()
    .case KEY_ALTL:   tilseek(rdx)
    .case KEY_ALTS:   tisearchxy(rdx)
    .case KEY_ALTX:   tcloseall() : jmp return
    .default
        .return(_TI_NOTEVENT)
    .endsw
    mov eax,_TI_CONTINUE
toend:
    ret
toggle:
    xor [rdx].TINFO.flags,eax
    tiputs(rdx)
    xor eax,eax
    jmp toend
return:
    mov eax,_TI_RETEVENT
    jmp toend

tihandler endp

tevent proc private uses rsi rdi

    mov rsi,tinfo

    .while 1

        tiseto(rsi)
        tiputs(rsi)

        .while 1

            .if tiftime(rsi)

                .if ( eax != [rsi].time )

                    .if rsmodal(IDD_TEReload)

                        timemzero(rsi)
                        tiread(rsi)

                        mov edi,KEY_ESC
                        .break( 1 ) .if !eax

                        tiseto(rsi)
                        tiputs(rsi)
                    .endif
                .endif
            .endif

            timenus(rsi)
            tgetevent()
            mov edi,eax
            tihandler()
            mov rsi,tinfo

            .break .if eax == _TI_NOTEVENT
            .break(1) .if eax == _TI_RETEVENT
        .endw
        tievent(rsi, edi)
    .endw
    mov rdx,rsi
    mov eax,edi
    ret

tevent endp

tmodal proc uses rsi rdi rbx

    local cursor:CURSOR, update:DPROC, ftime

    .while mousep()
    .endw

    mov rsi,tinfo
    .if tistate(rsi)

        mov update,tupdate
        mov tupdate,&tiupdate
        _getcursor(&cursor)
        tishow(rsi)

        mov ftime,tiftime(rsi)
        mov edi,tevent()
        mov rax,tinfo
        cmp rax,rsi
        mov esi,0

        .ifz
            tiftime(rax)
            mov esi,ftime
            sub esi,eax
        .endif

        mov tupdate,update
        _setcursor(&cursor)

        mov edx,esi     ; zero if not modified
        mov eax,edi     ; returned key value
    .endif
    ret

tmodal endp

tedit proc fname:LPSTR, line:UINT

    .if topen(fname, 0)

        tialigny(tinfo, line)
        tmodal()
    .endif
    ret

tedit endp

    end
