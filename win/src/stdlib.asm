; STDLIB.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include stdlib.inc
include stdio.inc
include dzstr.inc
include malloc.inc
include direct.inc
include wsub.inc
include process.inc
include winbase.inc

externdef _diskflag:int_t

public _pgmpath
public envtemp

    .data
     _pgmpath       LPSTR NULL
     __pCommandCom  LPSTR default
     __pCommandArg  LPSTR command_arg
     envpath        LPSTR curpath
     envtemp        LPSTR NULL
     comspec_type   UINT 0 ; %COMSPEC% or CMD.EXE
     exetype        SBYTE ".bat",0, ".com",0, ".exe",0, ".cmd",0,0
     curpath        SBYTE ".",0
     cp_temp        SBYTE "TEMP",0
     default        SBYTE "COMMAND",0
     __comspec      SBYTE "Comspec",0
     command_arg    SBYTE "/C", 61 dup(0)

    .code

    option dotname

__xtol proc string:LPSTR

    ldr rdx,string
    xor eax,eax
    xor ecx,ecx

    .while 1

        mov cl,[rdx]
        add rdx,1
        and cl,0xDF

        .break .if cl < 0x10
        .break .if cl > 'F'

        .if cl > 0x19

            .break .if cl < 'A'
            sub cl,'A' - 0x1A
        .endif
        sub cl,0x10
        shl eax,4
        add eax,ecx
    .endw
    ret

__xtol endp

__xtoi64 proc uses rbx string:LPSTR

    ldr rbx,string
    xor eax,eax
    xor ecx,ecx
ifndef _WIN64
    xor edx,edx
endif

    .while 1

        mov cl,[rbx]
        add rbx,1
        and cl,0xDF

        .break .if cl < 0x10
        .break .if cl > 'F'

        .if cl > 0x19

            .break .if cl < 'A'
            sub cl,'A' - 0x1A
        .endif
        sub cl,0x10
ifdef _WIN64
        shl rax,1
        add rax,rcx
else
        shld edx,eax,4
        shl eax,4
        add eax,ecx
        adc edx,0
endif
    .endw
    ret

__xtoi64 endp

strtolx proc string:LPSTR

    ldr rcx,string

    .for ( rdx = rcx, al = [rdx] : al : rdx++, al = [rdx] )

        .if ( al > '9' )

            .return __xtol(rcx)
        .endif
    .endf
    .return atol(rcx)

strtolx endp

mkbstring proc uses rsi rdi buf:LPSTR, qw:qword

  local tmp[32]:byte

    sprintf(&tmp, "%I64u", qw)

    mov rsi,_strrev(&tmp)
    mov rdi,buf
    xor edx,edx
    mov ah,' '
    .while 1
        lodsb
        stosb
        .break .if !al
        inc dl
        .if dl == 3
            mov al,ah
            stosb
            xor dl,dl
        .endif
    .endw
    .if [rdi-2] == ah
        mov [rdi-2],dh
    .endif

    _strrev(buf)

    mov eax,dword ptr qw
    mov ecx,dword ptr qw+4
    xor edx,edx

    .while ecx || eax > 1024*10

        shrd eax,ecx,10
        shr ecx,10
        inc edx
    .endw
    ret

mkbstring endp

recursive proc uses rsi rdi name:LPSTR, src:LPSTR, dst:LPSTR

   .new temp[WMAXPATH]:char_t
   .new path[WMAXPATH]:char_t

    ldr rcx,name
    ldr rdx,src
    lea rsi,path
    lea rdi,temp
    strfcat(rsi, rdx, rcx)
    strcpy (rdi, dst)
    strfcat(rdi, rdi, strfn(rsi))
    strlen (rsi)
    mov word ptr [rsi+rax],0x005C
    inc eax
    .ifd _strnicmp(rsi, rdi, eax)
        mov eax,-1
    .endif
    inc eax
    ret

recursive endp

__initpath proc private uses rdi

  local path[256]

    lea rdi,path
    strcpy(rdi, _pgmptr)
    .if strfn(rdi) > rdi

        mov byte ptr [rax-1],0
        strlen(rdi)
        mov _pgmpath,malloc(&[rax+1])
        strcpy(rax, rdi)
    .endif
    ret

__initpath endp

__initcomspec proc

  local buffer[1024]:SBYTE

    .if comspec_type
        SearchPath(NULL, "cmd.exe", NULL, 1024, &buffer, NULL)
    .else
        GetEnvironmentVariable(&__comspec, &buffer, 1024)
    .endif
    .if eax
        free(__pCommandCom)
        mov  __pCommandCom,_strdup(&buffer)
    .endif
    ret

__initcomspec endp

; expand '%TEMP%' to 'C:\TEMP'

expenviron proc string:LPSTR

   .new buffer:LPSTR = malloc(0x8000)

    ExpandEnvironmentStrings(string, buffer, 0x8000-1 )
    strcpy(string, buffer)
    free(buffer)
    mov rax,string
    ret

expenviron endp


getenvp proc private enval:LPSTR

  local buf[2048]:byte

    .ifd GetEnvironmentVariable(enval, &buf, 2048)

        _strdup(&buf)
    .endif
    ret

getenvp endp


GetEnvironmentSize proc private EnvironmentStrings:LPSTR

    mov rdx,rdi
    mov rdi,EnvironmentStrings
    xor eax,eax
    mov ecx,-1
    .while al != [rdi]
        repnz scasb
    .endw
    mov rdi,rdx
    sub eax,ecx
    ret

GetEnvironmentSize endp


GetEnvironmentPATH proc

    .if getenvp("PATH")

        mov rcx,envpath
        mov envpath,rax
        lea rax,envpath
        .if rcx != rax
            free(rcx)
        .endif
    .endif
    mov rax,envpath
    ret

GetEnvironmentPATH endp

GetEnvironmentTEMP proc

    free(envtemp)
    mov envtemp,getenvp(&cp_temp)

    .if !rax

        mov rax,_pgmpath
        .if rax
            mov envtemp,_strdup(rax)
            SetEnvironmentVariable(&cp_temp, rax)
            mov rax,envtemp
        .endif
    .endif
    ret

GetEnvironmentTEMP endp

removefile proc uses rbx file:LPSTR

    ldr rcx,file

    mov rbx,_utftows(rcx)
    _wsetfattr(rbx, 0)
    _wremove(rbx)
    ret

removefile endp

removetemp proc uses rbx path:LPSTR

   .new buffer[1024]:char_t

    mov rbx,_utftows(strfcat(&buffer, envtemp, path))
    _wsetfattr(rbx, 0)
    _wremove(rbx)
    ret

removetemp endp

ReadEnvironment proc uses rsi rdi rbx FileName:LPSTR

  local CurrentEnvironment:ptr sbyte,
    CurrentEnvSize:sdword,
    NewEnvironment:ptr sbyte,
    NewEnvSize:sdword,
    Result:sdword

    mov Result,0

    .if GetEnvironmentStrings()
        ;
        ; Read the current environment block
        ;
        mov rdi,rax
        mov esi,GetEnvironmentSize(rax)
        mov CurrentEnvSize,esi
        mov CurrentEnvironment,memcpy(alloca(esi), rdi, esi)
        FreeEnvironmentStrings(rdi)
        ;
        ; Read the new environment block
        ;
        .ifd osopen(FileName, _FA_NORMAL, M_RDONLY, A_OPEN) != -1

            mov edi,eax
            mov ebx,_filelength(eax)
            mov rsi,alloca(eax)
            mov byte ptr [rsi],0
            osread(edi, rsi, ebx)
            xchg eax,edi
            _close(eax)
            mov NewEnvironment,rsi

            test ebx,ebx    ; Exit on zero file or IO error
            jz toend
            cmp edi,ebx
            jne toend
            ;
            ; Get size of new block
            ;
            GetEnvironmentSize(rsi)
            mov rdi,rsi
            mov esi,eax
            mov NewEnvSize,esi
            .if esi == CurrentEnvSize

                mov ecx,esi
                mov rdx,rdi
                mov rsi,CurrentEnvironment
                repz cmpsb
                mov rsi,rdx
                jz  directory   ; Skip if equal
            .endif
            ;
            ; The new block differ from the current
            ; - delete the current block
            ;
            mov rsi,CurrentEnvironment
            .while byte ptr [rsi]

                lea rax,[rsi+1]
                .if strchr(rax, '=')

                    mov byte ptr [rax],0
                    mov rbx,rax
                    SetEnvironmentVariable(rsi, 0)
                    mov byte ptr [rbx],'='
                .endif
                strlen(rsi)
                lea rsi,[rsi+rax+1]
            .endw
            ;
            ; - set the new block
            ;
            mov rsi,NewEnvironment
            .while byte ptr [rsi]

                lea rax,[rsi+1]
                .if strchr(rax, '=')

                    mov byte ptr [rax],0
                    lea rbx,[rax+1]
                    SetEnvironmentVariable(rsi, rbx)
                    mov byte ptr [rbx-1],'='
                .endif
                strlen(rsi)
                lea rsi,[rsi+rax+1]
            .endw
            inc rsi
directory:
            SetCurrentDirectory(rsi)
            inc Result
        .endif
    .endif
toend:
    mov eax,Result
    ret

ReadEnvironment endp

SaveEnvironment proc uses rsi rdi rbx FileName:LPSTR

   .new CurrentDirectory[WMAXPATH]:sbyte
   .new retval:int_t = 0

    .if GetEnvironmentStrings()

        mov rsi,rax
        mov rbx,rax

        .ifd osopen(FileName, _FA_NORMAL, M_WRONLY, A_CREATETRUNC) != -1

            mov edi,eax
            mov _diskflag,1
            oswrite(edi, rsi, GetEnvironmentSize(rsi))

            lea rsi,CurrentDirectory
            .if GetCurrentDirectory(WMAXPATH, rsi)

                strlen(rsi)
                inc eax
                oswrite(edi, rsi, eax)
                inc retval
            .endif
            _close(edi)

            .if ( retval == 0 )

                _wremove(_utftows(FileName))
            .endif
        .endif
        FreeEnvironmentStrings(rbx)
    .endif
    .return(retval)

SaveEnvironment endp

TestPath proc private uses rsi rdi rbx file:LPSTR, buffer:LPSTR

  local temp[_MAX_PATH*2]:sbyte

    lea rdi,temp
    mov rsi,GetEnvironmentPATH()
    .if rsi

        .repeat

            .if strchr(rsi, ';')
                sub rax,rsi
            .else
                strlen(rsi)
            .endif
            .break .if !eax

            mov ebx,eax
            memcpy(rdi, rsi, eax)
            mov word ptr [rdi+rbx],'\'
            .ifd filexist(strcat(rdi, file)) == 1
                .if ( buffer )
                    strcpy(buffer, rdi)
                .endif
                .return
            .endif
            lea rsi,[rsi+rbx+1]
        .until byte ptr [rsi-1] == 0
    .endif
    xor eax,eax
    ret

TestPath endp


TestPathExt proc private uses rsi rdi file:LPSTR, path:LPSTR, buffer:LPSTR

  local temp[_MAX_PATH*2]:sbyte

    lea rdi,temp
    lea rsi,exetype
    .while byte ptr [rsi]
        .ifd filexist(strcat(strfcat(rdi, path, file), rsi)) == 1

            .if ( buffer )
                strcpy(buffer, rdi)
            .endif
            .return
        .endif
        add rsi,5
    .endw
    xor eax,eax
    ret

TestPathExt endp

searchp proc uses rsi rdi rbx fname:LPSTR, buffer:LPSTR

  local path[_MAX_PATH]:byte
  local file[_MAX_PATH]:byte
  local isexec:int_t

    xor eax,eax
    mov rbx,fname
    .if ( rax == rbx || al == [rbx] )
        .return
    .endif

    ;
    ; Test valid extension
    ;
    mov isexec,_aisexec(rbx)

    lea rsi,path
    lea rdi,file
    _getcwd(rsi, _MAX_PATH)
    ;
    ; If valid extension and exist
    ;
    .if ( isexec )

        .ifd ( filexist(rbx) == 1 )

            .if ( strfn(rbx) == rbx )

                strfcat(rdi, rsi, rbx)
            .else

                mov ecx,[rbx]
                xor eax,eax
                .if ( ch != ':' )
                    .ifd GetFullPathName(rbx, _MAX_PATH*2, rdi, 0)
                        mov rax,rdi
                    .endif
                .endif
                .if !rax
                    strcpy(rdi, rbx)
                .endif
            .endif
            .if ( buffer )
                strcpy(buffer, rdi)
            .endif
            .return
        .endif
    .endif
    ;
    ; If full or relative path
    ;
    .if ( strfn(rbx) != rbx )

        .if isexec
            ;
            ; do not exist
            ;
            .return(NULL)
        .endif

        strcpy(rdi, rax)
        strpath(strcpy(rsi, rbx))
       .return TestPathExt(rdi, rsi, buffer)
    .endif
    ;
    ; Case filename
    ;
    .if isexec

        .return TestPath(rbx, buffer)
    .endif
    ;
    ; case name, no ext
    ;
    .ifd TestPathExt(rbx, rsi, buffer)

        .return
    .endif

    mov rsi,GetEnvironmentPATH()
    .repeat
        .if strchr(rsi, ';')
            sub rax,rsi
        .else
            strlen(rsi)
        .endif
        .break .if !eax

        mov ecx,eax
        rep movsb
        mov byte ptr [rdi],0
        lea rdi,file
        .break .ifd TestPathExt(rbx, rdi, buffer)
        lodsb
    .until !eax
    ret

searchp endp

.pragma init(__initpath, 5)
.pragma init(__initcomspec, 60)
.pragma init(GetEnvironmentPATH, 101)
.pragma init(GetEnvironmentTEMP, 102)

    end
