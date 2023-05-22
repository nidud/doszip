; 7ZA.ASM--
; Copyright (C) 2015 Doszip Developers -- see LICENSE.TXT
;
; This is the "inline" 7za.dll plugin for 7ZA.EXE
;

include errno.inc
include malloc.inc
include io.inc
include string.inc
include stdio.inc
include stdlib.inc
include process.inc
include time.inc
include kernel32.inc

include doszip.inc
include config.inc
include tview.inc
include confirm.inc

IDTYPE_7Z       equ 0
IDTYPE_GZ       equ 1
IDTYPE_BZ2      equ 2
IDTYPE_CAB      equ 3
IDTYPE_XZ       equ 4
IDTYPE_TAR      equ 5
IDTYPE_LZMA     equ 6

TYPE_7Z         equ 00007A37h
TYPE_GZ         equ 00008B1Fh
TYPE_BZ2        equ 00005A42h
TYPE_CAB        equ 4643534Dh
TYPE_XZ         equ 587A37FDh

.data

$LIST  LPSTR 0
$PROG  db "7ZA.EXE",0

; default value

ARG_01 db '7za l -y',0         ; 01 - Read
ARG_02 db '7za x -y',0         ; 02 - Copy - e if not include subdir
ARG_03 db '7za a -y',0         ; 03 - Add
ARG_06 db '7za d -y',0         ; 06 - Delete
ARG_08 db '7za m -e -y',0      ; 08 - Edit
ARG_09 db '7za e -y',0         ; 09 - View or copy single file (02)

; format strings

CPF_02 db ' %s -o"%s"',0       ; <archive> -o<outpath> @list
CPF_03 db ' %s',0              ; <archive> @list

; from [7ZA] config value, or default value

CMD_00 LPSTR 0    ; ARG_09 - if files only (02)
CMD_01 LPSTR 0
CMD_02 LPSTR 0
CMD_03 LPSTR 0
CMD_06 LPSTR 0
CMD_08 LPSTR 0
CMD_09 LPSTR 0

config_label LPSTR \
    ARG_09, CMD_00,
    ARG_01, CMD_01,
    ARG_02, CMD_02,
    ARG_03, CMD_03,
    0,0,
    0,0,
    ARG_06, CMD_06,
    0,0,
    ARG_08, CMD_08,
    ARG_09, CMD_09

; file types

define NUMTYPE 7

typ0 db 0
typ1 db ' -tgzip',0
typ2 db ' -tbzip2',0
typ3 db ' -tcab',0
typ4 db ' -txz',0
typ5 db ' -ttar',0
typ6 db ' -tlzma',0

label_types LPSTR typ0,typ1,typ2,typ3,typ4,typ5,typ6


;-----------------------------
; Flag bits for function calls
;-----------------------------

_DLLF_READ      equ 0001h
_DLLF_COPY      equ 0002h
_DLLF_ADD       equ 0004h
_DLLF_MOVE      equ 0008h
_DLLF_MKDIR     equ 0010h
_DLLF_DELETE    equ 0020h
_DLLF_RENAME    equ 0040h
_DLLF_EDIT      equ 0080h
_DLLF_VIEW      equ 0100h
_DLLF_ATTRIB    equ 0200h
_DLLF_ENTER     equ 0400h
_DLLF_TEST      equ 0800h
_DLLF_GLOBAL    equ 2000h
_DLLF_EDITOR    equ 4000h
                                        ;  test,enter,attrib,view,edit,ren,del,mkdir,move,add,copy,read
label_flag      dd 100100100111B        ;   x                x             x              x   x    x
                dd 100100000011B        ;   x                x                                x    x
                dd 100100000011B        ;   x                x                                x    x
                dd 100100000011B        ;   x                x                                x    x
                dd 100100000011B        ;   x                x                                x    x
                dd 100100100111B        ;   x                x             x              x   x    x
                dd 100100000011B        ;   x                x                                x    x

$TYPE           LPSTR typ0              ; current type string
$FLAG           dd 100100100111B        ; current type flag

modified        db 1
startstring     db '------------------- '
quote           db '"',0


        .code


;-------------------------------------------------------------------------
; Read
;-------------------------------------------------------------------------

lline_getdate proc private uses rsi rbx ; 2008-04-28

    mov ebx,atol(rdi)
    mov esi,atol(&[rdi+5])
    atol(&[rdi+8])

    mov     dl,al
    mov     eax,esi
    mov     dh,al
    mov     eax,ebx
    sub     ax,DT_BASEYEAR
    shl     ax,9
    xchg    ax,dx
    mov     cl,al
    mov     al,ah
    xor     ah,ah
    shl     ax,5
    xchg    ax,dx
    or      ax,dx
    or      al,cl
    ret

lline_getdate endp

lline_gettime proc private uses rsi rdi rbx ; 02:19:00

    mov ebx,atol(&[rdi+11])
    mov esi,atol(&[rdi+14])
    atol(&[rdi+17])
    mov     ecx,esi
    mov     ch,bl
    mov     dh,al
    xor     eax,eax ; DH = second
    mov     al,dh   ; CH = hour
    shr     ax,1    ; CL = minute
    mov     edx,eax
    mov     al,ch
    mov     ch,ah
    shl     cx,5
    shl     eax,11
    or      eax,ecx
    or      eax,edx ; hhhhhmmmmmmsssss
    ret

lline_gettime endp

lline_getattrib proc private

    xor eax,eax
    .if BYTE PTR [rdi+20] == 'D'
        or al,_A_SUBDIR
    .endif
    .if BYTE PTR [rdi+21] == 'R'
        or al,_A_RDONLY
    .endif
    .if BYTE PTR [rdi+22] == 'H'
        or al,_A_HIDDEN
    .endif
    .if BYTE PTR [rdi+23] == 'S'
        or al,_A_SYSTEM
    .endif
    .if BYTE PTR [rdi+24] == 'A'
        or al,_A_ARCH
    .endif
    ret

lline_getattrib endp

;
;   Date      Time    Attr         Size   Compressed  Name
;------------------- ----- ------------ ------------  ------------------------
;                    .....                    790027  7z922.tar
;------------------- ----- ------------ ------------  ------------------------
;                                             790027  1 files, 0 folders
;

lline_findnext proc private

    .if !ogets()

        .return
    .endif

    mov al,[rdi]        ; 2008-04-28

    .if ( al == ' ' )

        .if ( strlen(rdi) < 52 )

            .return( 0 )
        .endif

    .elseif ( al < '0' || al > '9' || BYTE PTR [rdi+4] != '-' )

        .return( 0 )
    .endif

    xor eax,eax
    mov [rdi+4],al
    mov [rdi+7],al
    mov [rdi+10],al
    mov [rdi+13],al
    mov [rdi+16],al
    mov [rdi+19],al
    mov [rdi+38],al
    mov [rdi+51],al
    mov al,[rdi+52]
    ret

lline_findnext endp


lline_findfirst proc private

    .while 1

        .return   .if !ogets()
        .continue .if BYTE PTR [rdi] != '-'
        .break    .if !strncmp(rdi, &startstring, sizeof(startstring))
    .endw
    .return( lline_findnext() )

lline_findfirst endp


createlist PROC PRIVATE USES rsi rdi wsub:PWSUB

  local batf[256]:char_t
  local arch[256]:char_t
  local cmd[512]:char_t

    .if ( $LIST == 0 )

        .if _strdup( strfcat( &cmd, envtemp, "ziplst.tmp" ) )
            mov $LIST,rax
        .endif
    .endif

    mov rsi,wsub
    mov arch,'"'
    strcat( strfcat( &arch[1], [rsi].WSUB.path, [rsi].WSUB.file ), &quote )
    mov rsi,strfcat( &batf, envtemp, "dzcmd.bat" )
    mov edi,osopen( rax, 0, M_WRONLY, A_CREATETRUNC )
    inc eax
    .if eax

        sprintf( &cmd, "%s%s > %s\r\n", CMD_01, &arch, $LIST )
        oswrite( edi, &cmd, strlen( &cmd ) )
        _close( edi )

        CreateConsole( &batf, _P_WAIT or CREATE_NEW_CONSOLE )
        remove( &batf )

        mov _diskflag,0
        mov eax,1
    .endif
    ret

createlist ENDP

;
; Returns 0 if entry not part of basepath,
; else _A_ARCH or _A_SUBDIR.
;
testentryname PROC PRIVATE USES rsi rdi rbx wsub:PWSUB, name:LPSTR

    ldr rbx,wsub
    ldr rsi,name
    mov edi,strlen( [rbx].WSUB.arch )
    .ifd ( strlen(rsi) <= edi )

        .return( 0 )
    .endif

    .ifs ( edi > 0 )

        .if _strnicmp( name, [rbx].WSUB.arch, edi )

            .return( 0 )
        .endif
        .if ( byte ptr [rsi+rdi] != '\' )

            .return( 0 )
        .endif

        strcpy( rsi, &[rsi+rdi+1] )
        .while ( byte ptr [rsi] == ',' )

            strcpy( rsi, &[rsi+1] )
        .endw
    .endif

    mov edi,_A_ARCH

    .while 1

        lodsb
        .break .if !al
        .continue .if al != '\'

        xor eax,eax
        mov [rsi-1],al
        mov edi,_A_SUBDIR
       .break
    .endw

    mov esi,1
    .if ( [rbx].WSUB.count <= esi )

        .return( edi )
    .endif

    .while ( [rbx].WSUB.count <= esi )

        mov rax,[rbx].WSUB.fcb
        mov rax,[rax+rsi*size_t]
        add rax,FBLK.name
        .if !_stricmp( name, rax )

            .return( 0 )
        .endif
        inc esi
    .endw
    .return( edi )

testentryname ENDP


warcread PROC USES rsi rdi rbx wsub:PWSUB

  local fblk:PFBLK, fattrib:DWORD, name:LPSTR

    ldr rsi,wsub

    .if !searchp( &$PROG, NULL )

        ermsg( 0, "File not found:\n%s", &$PROG )
       .return( ER_READARCH )
    .endif

    wsfree( rsi )

    .if fbupdir( _W_ARCHEXT )

        mov [rsi].WSUB.count,1
        mov rbx,[rsi].WSUB.fcb
        mov [rbx],rax

        .if modified

            createlist( rsi )
        .endif

        .if ogetl( $LIST, entryname, 512 )

            mov rdi,entryname
            lea rax,[rdi+53]
            mov name,rax

            lline_findfirst()

            .while rax

                .if testentryname( rsi, name )

                    mov fattrib,eax
                    and eax,_A_SUBDIR
                    .ifz
                        cmpwarg( name, [rsi].WSUB.mask )
                    .endif

                    .if ( eax )

                        strlen( name )
                        add eax,FBLK

                        .break .if !malloc( eax )

                        mov rbx,rax
                        mov ecx,fattrib
                        or  ecx,_FB_ARCHEXT
                        mov [rax].FBLK.flag,ecx
                        add rax,FBLK.name
                        strcpy( rax, name )
                        _atoi64( &[rdi+26] )
ifdef _WIN64
                        mov [rbx].FBLK.size,rax
else
                        mov DWORD PTR [rbx].FBLK.size,eax
                        mov DWORD PTR [rbx].FBLK.size+4,edx
endif
                        lline_gettime()
                        mov [rbx].FBLK.time,eax
                        lline_getdate()
                        shl eax,16
                        or [rbx].FBLK.time,eax
                        lline_getattrib()
                        or [rbx],al

                        mov eax,[rsi].WSUB.count
                        mov rdx,[rsi].WSUB.fcb
                        mov [rdx+rax*size_t],rbx
                        inc [rsi].WSUB.count
                        mov eax,[rsi].WSUB.count
                        .if eax >= [rsi].WSUB.maxfb
                            .break .if !wsextend(rsi)
                        .endif
                    .endif
                .endif
                lline_findnext()
            .endw

            ioclose( &STDI )
            mov modified,0
            mov eax,[rsi].WSUB.count
        .endif
    .endif
    ret

warcread endp

;-------------------------------------------------------------------------
; Copy
;-------------------------------------------------------------------------

warccopy PROC uses rsi rdi rbx wsub:PWSUB, fblk:PFBLK, outp:LPSTR, subdcount:int_t

  local cmd[_MAX_PATH]:char_t
  local path[_MAX_PATH]:char_t
  local list[256]:char_t

    lea rsi,cmd
    ldr rbx,outp
    ;
    ; remove '\' from end of outpath (C:\)
    ;
    strlen( strcpy( &path, rbx ) )
    lea rbx,[rbx+rax-1]
    mov eax,'\'
    .if [rbx] == al
        mov [rbx],ah
    .endif
    ;
    ; make a list file
    ;
    mov mklist.flag,_MKL_MASK
    mov mklist.count,0
    .if mkziplst_open(&list)

        .if mkziplst()
            xor eax,eax
        .else
            or eax,mklist.count
        .endif
    .endif

    .if eax
        mov rdi,CMD_00  ; singel file (excluding directory)
        .if subdcount
            mov rdi,CMD_02
        .endif
        mov rbx,wsub
        sprintf( rsi, rdi, [rbx].WSUB.file, &path )
        CreateConsole( &cmd, _P_WAIT or CREATE_NEW_CONSOLE )
        remove( &list )
        xor eax,eax
    .endif
    ret

warccopy ENDP

;-------------------------------------------------------------------------
; Add
;
; - add files to <archive>\ root directory only
;-------------------------------------------------------------------------

warcadd PROC dest:LPSTR, wsub:PWSUB, fblk:PFBLK

  local cmd[256]:char_t
  local path[_MAX_PATH]:char_t
  local list[256]:char_t

    .if $FLAG & _DLLF_ADD

        mov eax,1
        ldr rdx,dest
        mov rdx,[rdx].WSUB.arch
        .if [rdx] != ah
            rsmodal( IDD_ConfirmAddFiles ) ; OK == 1, else 0
        .endif

        .if eax

            mov mklist.flag,_MKL_MASK
            mov mklist.count,0
            .if mkziplst_open(&list)

                .if mkziplst()
                    xor eax,eax
                .else
                    mov eax,mklist.count
                .endif
            .endif
            .if eax
                mov rdx,dest
                strfcat( &path, [rdx].WSUB.path, [rdx].WSUB.file )
                sprintf( &cmd, CMD_03, rax )
                CreateConsole( &cmd, _P_WAIT or CREATE_NEW_CONSOLE )
                remove( &list )
                inc modified
            .endif
        .endif
    .endif
    xor eax,eax
    ret

warcadd ENDP

;-------------------------------------------------------------------------
; Delete
;-------------------------------------------------------------------------

warcdelete PROC USES rsi rdi wsub:PWSUB, fblk:PFBLK

  local cmd[256]:char_t
  local list[256]:char_t

    .if $FLAG & _DLLF_DELETE

        ;----------------------------
        ; use mask in directory\[*.*]
        ;----------------------------

        mov mklist.flag,_MKL_MASK
        mov mklist.count,0
        .if mkziplst_open(&list)
            .if mkziplst()
                xor eax,eax
            .else
                or  eax,mklist.count
            .endif
        .endif
        .if eax

            mov rsi,wsub
            mov rdi,fblk
            mov ecx,[rdi].FBLK.flag
            lea rax,[rdi].FBLK.name

            .if confirm_delete_file( rax, ecx ) && eax != -1

                sprintf( &cmd, CMD_06, [rsi].WSUB.file, &list )
                CreateConsole( &cmd, _P_WAIT or CREATE_NEW_CONSOLE )
                remove( &list )
                inc modified
            .endif
        .endif
    .endif
    xor eax,eax
    ret

warcdelete ENDP

;-------------------------------------------------------------------------
; View
;-------------------------------------------------------------------------

warcview PROC USES rsi rdi rbx wsub:PWSUB, fblk:PFBLK

  local fbname[_MAX_PATH]:char_t
  local cmd[_MAX_PATH]:char_t

    ldr rsi,wsub
    ldr rdx,fblk
    lea rdi,cmd
    lea rbx,[rdx].FBLK.name

    strfcat( &fbname, [rsi].WSUB.arch, rbx )
    sprintf( rdi, CMD_09, [rsi].WSUB.file, envtemp, rax )
    CreateConsole( rdi, _P_WAIT or CREATE_NEW_CONSOLE )

    .if filexist( strfcat( rdi, envtemp, rbx ) ) == 1

        tview ( rdi, 0 )
        remove( rdi )
        mov _diskflag,0
    .endif
    ret

warcview ENDP

;-------------------------------------------------------------------------
; Test
;-------------------------------------------------------------------------

warcgettype PROC PRIVATE uses rbx fblk:PFBLK, sign:int_t

    ldr eax,sign
    ldr rdx,fblk

    .if eax == TYPE_CAB
        mov eax,IDTYPE_CAB+1
    .elseif eax == TYPE_XZ
        mov eax,IDTYPE_XZ+1
    .else
        and eax,0000FFFFh
        .if eax == TYPE_7Z
            mov eax,IDTYPE_7Z+1
        .elseif eax == TYPE_GZ
            mov eax,IDTYPE_GZ+1
        .elseif eax == TYPE_BZ2
            mov eax,IDTYPE_BZ2+1
        .elseif strext( &[rdx].FBLK.name )
            mov rbx,rax
            .if !_stricmp( rax, ".tar" )
                mov eax,IDTYPE_TAR+1
            .elseif !_stricmp( rbx, ".lzma" )
                mov eax,IDTYPE_LZMA+1
            .else
                xor eax,eax
            .endif
        .endif
    .endif
    ret

warcgettype ENDP

find proc private uses rbx

    lea rdi,config_label
    imul ebx,ecx,LPSTR*2
    add rdi,rbx

    .if !CFGetSectionID( "7ZA", ecx )
        mov rax,[rdi]
    .endif
    mov rdi,[rdi+LPSTR]
    mov rcx,[rdi]
    .if !rcx

        mov rbx,rax
        malloc( 128 )
        mov [rdi],rax
        mov rcx,rax
        mov rax,rbx
    .endif
    strcat( strcpy( rcx, rax ), $TYPE )
    ret

find endp

warctest PROC USES rsi rdi rbx fblk:PFBLK, sign:int_t

  local list[256]:char_t

    .if !searchp( &$PROG, NULL )

        .return
    .endif

    lea rbx,list
    mov eax,"@ "
    mov [rbx],eax

    strfcat( &[rbx+2], envtemp, &cp_ziplst )

    .if warcgettype( fblk, sign )

        lea     edx,[rax-1]
        lea     rcx,label_types
        mov     rax,[rcx+rdx*LPSTR]
        mov     $TYPE,rax
        lea     rcx,label_flag
        mov     eax,[rcx+rdx*4]
        mov     $FLAG,eax
        mov     ecx,1           ; READ
        call    find
        strcat( rax, " " )
        mov     ecx,0
        call    find
        strcat( rax, addr CPF_02 )
        strcat( rax, rbx )
        mov     ecx,2           ; COPY
        call    find
        strcat( rax, addr CPF_02 )
        strcat( rax, rbx )
        mov     ecx,3           ; ADD
        call    find
        strcat( rax, addr CPF_03 )
        strcat( rax, rbx )
        mov     ecx,6           ; DELETE
        call    find
        strcat( rax, addr CPF_03 )
        strcat( rax, rbx )
        mov     ecx,8           ; EDIT
        call    find
        strcat( rax, " %s %s" )
        mov     ecx,9           ; VIEW
        call    find
        strcat( rax, " %s -o%s %s" )
        mov     eax,1
        mov     modified,al
    .endif
    ret

warctest ENDP

    END
