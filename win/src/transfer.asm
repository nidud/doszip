include conio.inc
include malloc.inc
include string.inc
include stdio.inc
include stdlib.inc
include io.inc
include errno.inc
include direct.inc
include config.inc
include wsub.inc
include process.inc

define MAXALTCMD   6
define MAXSHIFTCMD 9
define MAXEXTCMD   (MAXALTCMD + MAXSHIFTCMD)

history_event_list proto

    .data

MAXERROR    equ 100     ; read .err file from compile

ERFILE      STRUC
m_file      db _MAX_PATH dup(?)
m_info      db 256 dup(?)
m_line      dd ?
ERFILE      ENDS

cp_AltFX    db 'AltF'
cp_AltX     db '1',0
cp_ShiftFX  db 'ShiftF'
cp_ShiftX   db '1',0,0,0
error_count dd 0
error_id    dd 0
err_file    LPSTR 0
file_ext    LPSTR 0
chars       db "\abcdefghijklmnopqrstuvwxyz0123456789_@",0

    .code

    option proc:private
;
; Parse output from Edit command
;
; WCC    '<file>(<line>): Error! <id>: <message>'
; JWasm  '<file>(<line>) : Error <id>: <message>: <text>'
; Masm   '<file>(<line>) : error <id>: <message>'
;

clear_error proc
    free(err_file)
    xor eax,eax
    mov err_file,rax
    mov error_id,eax
    mov error_count,eax
    ret
clear_error endp

    assume rbx:ptr ERFILE

ParseLine proc uses rcx rdi rsi rbx

    mov eax,sizeof(ERFILE)
    mul error_count
    add rax,err_file
    mov rbx,rax
    mov al,[rsi]

    .switch al
      .case 'A'..'Z'
        or al,20h
    .endsw

    lea rdi,chars
    mov ecx,sizeof( chars )
    repne scasb

    .if byte ptr [rdi-1]

        mov rdi,rsi

        .if strchr(rdi, 40)

            mov cl,[rax+1]
            .if cl >= '0' && cl <= '9'

                mov rsi,rax
                mov byte ptr [rsi],0
                inc rsi
                atol(rsi)
                inc rsi
                mov [rbx].m_line,eax
                strnzcpy(&[rbx].m_file, rdi, _MAX_PATH-1)

                .if byte ptr [rax+1] != ':'

                    GetFullPathName(rax, _MAX_PATH, rax, 0)
                .endif

                .if strchr(rsi, ':')

                    inc rax
                    mov rsi,rax
                .endif

                strnzcpy(&[rbx].m_info, rsi, 255)
                inc error_count
            .endif
        .endif
    .endif
    ret

ParseLine endp

    assume rbx:nothing

ParseOutput proc uses rsi rdi rbx

  local pBuffer:LPSTR, bSize:UINT, FName[_MAX_PATH]:byte

    clear_error()

    mov rdx,tinfo
    mov rax,[rdx].TINFO.file
    lea rdi,FName

    .ifd osopen(setfext(strcpy(rdi, strfn(rax)), ".err"), 0, M_RDONLY, A_OPEN) != -1

        mov esi,eax
        inc _filelength(esi)
        mov bSize,eax

        .if malloc(eax)

            mov pBuffer,rax
            mov rdi,rax
            mov ebx,bSize
            dec ebx
            osread(esi, rax, ebx)
            mov byte ptr [rdi+rbx],0
            _close(esi)

            .if malloc(MAXERROR*sizeof(ERFILE))

                mov err_file,rax
                memset(rax, 0, MAXERROR*sizeof(ERFILE))
                mov rsi,rdi
                mov ecx,bSize

                .while error_count < MAXERROR-1

                    mov al,10
                    repne scasb
                    .break .if !ecx
                    mov byte ptr [rdi-2],0
                    ParseLine()
                    mov rsi,rdi
                .endw
                ParseLine()
            .endif
            free(pBuffer)
        .else
            _close(esi)
        .endif
    .endif
    mov eax,error_count
    ret

ParseOutput endp

GetMessageId proc id

    mov rax,err_file
    .if rax
        mov eax,sizeof(ERFILE)
        mul id
        add rax,err_file
    .endif
    ret

GetMessageId endp

tifindfile proc uses rsi rbx fname:LPSTR

    .if tigetfile(tinfo)

        mov rsi,rax
        mov rbx,rdx
        .repeat
            .ifd !_stricmp(fname, [rsi].TINFO.file)

                mov rax,rsi
                .break
            .endif
            xor eax,eax
            cmp rsi,rbx
            mov rsi,[rsi].TINFO.next
        .untilz
    .endif
    ret

tifindfile endp

LoadMessageFile proc uses rsi rdi rbx M:ptr

    mov rsi,tinfo
    mov rdi,M

    .repeat
        .if !tifindfile(&[rdi].ERFILE.m_file)

            .break .if !topen(&[rdi].ERFILE.m_file, 0)

            mov rax,tinfo
        .endif

        .if rax != rsi

            mov tinfo,rsi
            mov tinfo,titogglefile(rsi, rax)
            mov rsi,tinfo
        .endif

        mov eax,[rdi].ERFILE.m_line
        .if eax

            dec eax
        .endif

        tialigny(rsi, eax)
        tiputs(rsi)

        lea rax,[rdi].ERFILE.m_info
        mov ebx,[rsi].TINFO.ypos
        add ebx,[rsi].TINFO.yoffs
        inc ebx
        .if ebx > [rsi].TINFO.rows
            sub ebx,2
        .endif

        scputs([rsi].TINFO.xpos, ebx, 0x4F, [rsi].TINFO.cols, rax)
        xor eax,eax
        mov [rsi].TINFO.crc,eax
        inc eax
    .until  1
    ret

LoadMessageFile endp

cmspawnini proc uses rsi rbx IniSection:ptr

  local screen:DOBJ, cursor:CURSOR

    _getcursor(&cursor)

    mov rbx,tinfo
    xor esi,esi
    .ifd dlscreen(&screen, 0007h) ; edx

        .if [rbx].TINFO.flags & _T_MODIFIED

            tiflush(rbx)
        .endif

        .if CFExpandCmd(__srcfile, [rbx].TINFO.file, IniSection)

            mov rbx,rax
            dlshow(&screen)

            .ifd !CreateConsole(rbx, _P_WAIT)

                mov eax,errno
                lea rcx,_sys_errlist
                mov rax,[rcx+rax*size_t]
                ermsg(0, "Unable to execute command:\n\n%s\n\n'%s'", __srcfile, rax)
                xor eax,eax
            .endif
        .endif
        mov esi,eax
        dlclose(&screen)
    .endif
    _setcursor(&cursor)
    mov eax,esi
    ret

cmspawnini endp

tiexecuteini proc uses rbx

    mov rbx,rax
    clear_error()

    .ifd cmspawnini(rbx)

        .ifd ParseOutput()

            tinexterror()
        .endif
    .endif
    ret
tiexecuteini endp

    option proc:PUBLIC

tipreviouserror proc

    .if error_count

        .if GetMessageId(error_id)

            LoadMessageFile(rax)

            .if error_id

                dec error_id
            .else

                mov eax,error_count
                dec eax
                mov error_id,eax
            .endif
        .endif
    .endif
    mov eax,_TI_CONTINUE
    ret

tipreviouserror endp

tinexterror proc

    .if error_count

        .if GetMessageId(error_id)

            LoadMessageFile(rax)

            mov eax,error_id
            inc eax
            .if eax >= error_count

                xor eax,eax
            .endif
            mov error_id,eax
        .endif
    .endif
    mov eax,_TI_CONTINUE
    ret

tinexterror endp

TIAltFx proc id

    clear_error()

    mov eax,id
    add al,'0'
    mov cp_AltX,al

    .ifd cmspawnini(&cp_AltFX)

        .ifd ParseOutput()

            tinexterror()
        .endif
    .endif
    ret
TIAltFx endp

TIShiftFx proc id

    clear_error()
    mov eax,id
    add al,'0'
    mov cp_ShiftX,al

    .ifd cmspawnini(&cp_ShiftFX)

        .ifd ParseOutput()

            tinexterror()
        .endif
    .endif
    ret

TIShiftFx endp

transfer_initsection proc private

    movzx eax,[rdi].DOBJ.index
    inc eax
    .if eax >= 7

        lea edx,[rax-6+'0']
        mov cp_ShiftX,dl
        lea rbx,cp_ShiftFX
    .else
        lea edx,[rax+1+'0']
        .if eax == 6
            add edx,2
        .endif
        mov cp_AltX,dl
        lea rbx,cp_AltFX
    .endif
    imul eax,eax,TOBJ
    mov rsi,[rdi+rax].TOBJ.data
    ret

transfer_initsection endp

transfer_edit proc private uses rsi rbx

    transfer_initsection()

    .ifd tgetline("Edit Transfer Command", rsi, 60, 256)

        .if CFAddSection(rbx)

            INIAddEntryX(rax, "%s=%s", file_ext, rsi)
        .endif
        dlinit(rdi)
    .endif
    ret

transfer_edit endp

event_transfer proc private uses rdi

    .whiled dlxcellevent() == KEY_F4

        mov rdi,tdialog
        transfer_edit()
    .endw
    ret

event_transfer endp

titransfer proc uses rsi rdi rbx

  local ext[_MAX_PATH]:sbyte

    mov rbx,tinfo
    mov rax,[rbx].TINFO.file
    lea rbx,ext
    mov file_ext,rbx

    .if strrchr(strcpy(rbx, strfn(rax)), '.')

        mov byte ptr [rax],0
        inc rax
        .if byte ptr [rax]
            strcpy(rbx, rax)
        .endif
    .endif

    .repeat

        .break .if !rsopen(IDD_DZTransfer)
        mov rdi,rax
        lea rdx,event_transfer
        mov ecx,MAXEXTCMD
        .repeat
            add rax,sizeof(TOBJ)
            mov [rax].TOBJ.tproc,rdx
        .untilcxz

        mov esi,2
        .while esi < 10

            lea eax,[rsi+'0']
            mov cp_AltX,al

            .if CFGetSection(&cp_AltFX)

                .if INIGetEntry(rax, rbx)

                    lea ecx,[rsi-1]
                    .if esi == 9
                        sub ecx,2
                    .endif
                    imul ecx,ecx,TOBJ
                    strcpy([rdi+rcx].TOBJ.data, rax)
                .endif
            .endif

            inc esi
            .if esi == 7
                mov esi,9
            .endif
        .endw

        .for ( esi = 1 : esi < 10 : esi++ )

            lea eax,[rsi+'0']
            mov cp_ShiftX,al

            .if CFGetSection(&cp_ShiftFX)

                .if INIGetEntry(rax, rbx)

                    lea ecx,[rsi+6]
                    imul ecx,ecx,TOBJ
                    strcpy([rdi+rcx].TOBJ.data, rax)
                .endif
            .endif
        .endf

        dlshow(rdi)
        dlinit(rdi)

        .while rsevent(IDD_DZTransfer, rdi)

            transfer_initsection()
            .if byte ptr [rsi] == 0

                transfer_edit()
            .else
                dlclose(rdi)
                mov rax,rbx
                tiexecuteini()
               .break( 1 )
            .endif
        .endw
        dlclose(rdi)
        xor eax,eax
    .until 1
    ret

titransfer endp

    end
