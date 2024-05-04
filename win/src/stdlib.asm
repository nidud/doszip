; STDLIB.ASM--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;

include stdlib.inc
include stdio.inc
include string.inc
include malloc.inc
include direct.inc
include wsub.inc
include process.inc
include user32.inc

    .data
     __argv         LPSTR NULL
     _environ       LPSTR NULL
     _pgmptr        LPSTR NULL
     _pgmpath       LPSTR NULL
     __pCommandCom  LPSTR default
     __pCommandArg  LPSTR command_arg
     envpath        LPSTR curpath
     envtemp        LPSTR NULL
     __argc         SINT 0
     comspec_type   UINT 0 ; %COMSPEC% or CMD.EXE
     exetype        SBYTE ".bat",0, ".com",0, ".exe",0, ".cmd",0,0
     curpath        SBYTE ".",0
     cp_temp        SBYTE "TEMP",0
     default        SBYTE "COMMAND",0
     __comspec      SBYTE "Comspec",0
     command_arg    SBYTE "/C", 61 dup(0)

    .code

    option dotname

atol proc string:string_t

    ldr     rcx,string

    xor     edx,edx
    xor     eax,eax
.0:
    mov     dl,[rcx]
    inc     rcx
    cmp     dl,' '
    je      .0
ifdef _WIN64
    mov     r8b,dl
else
    push    edx
endif
    cmp     dl,'+'
    je      .1
    cmp     dl,'-'
    jne     .2
.1:
    mov     dl,[rcx]
    inc     rcx
.2:
    sub     dl,'0'
    jb      .3
    cmp     dl,9
    ja      .3
    imul    eax,eax,10
    add     eax,edx
    mov     dl,[rcx]
    inc     rcx
    jmp     .2
.3:
ifdef _WIN64
    cmp     r8b,'-'
else
    pop     ecx
    cmp     cl,'-'
endif
    jne     .4
    neg     eax
.4:
    ret

atol endp

_atoi64 proc string:string_t

    ldr rcx,string
    xor eax,eax
    xor edx,edx

    .repeat
        mov al,[rcx]
        inc rcx
    .until al != ' '

ifdef _WIN64
    mov r8b,al
else
    push eax
endif

    .if ( al == '-' || al == '+' )

        mov al,[rcx]
        inc rcx
    .endif

ifdef _WIN64

    .while 1

        sub al,'0'

        .break .ifc
        .break .if al > 9

        mov r9,rdx
        shl rdx,3
        add rdx,r9
        add rdx,r9
        add rdx,rax
        mov al,[rcx]
        inc rcx
    .endw

    .if ( r8b == '-' )

        neg rdx
    .endif
    mov rax,rdx

else

    push esi
    push edi
    push ebx

    mov ebx,ecx
    mov ecx,eax
    xor eax,eax
    xor edx,edx

    .while 1

        sub cl,'0'

        .break .ifc
        .break .if ( cl > 9 )

        mov esi,edx
        mov edi,eax
        shld edx,eax,3
        shl eax,3
        add eax,edi
        adc edx,esi
        add eax,edi
        adc edx,esi
        add eax,ecx
        adc edx,0
        mov cl,[ebx]
        inc ebx
    .endw

    pop ebx
    pop edi
    pop esi
    pop ecx

    .if ( cl == '-' )

        neg edx
        neg eax
        sbb edx,0
    .endif
endif
    ret

_atoi64 endp

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

__isexec proc filename:string_t

    ldr rcx,filename
    .if strext( rcx )

        mov ecx,[rax+1]
        or  ecx,'   '
        xor eax,eax

        .switch pascal ecx
        .case 'dmc' : mov eax,_EXEC_CMD
        .case 'exe' : mov eax,_EXEC_EXE
        .case 'moc' : mov eax,_EXEC_COM
        .case 'tab' : mov eax,_EXEC_BAT
        .endsw
    .endif
    ret

__isexec endp

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

__allocwpath proc uses rsi rdi rbx path:LPSTR

    mov rsi,path
    xor edi,edi

    .ifd MultiByteToWideChar(0, 0, rsi, -1, 0, 0)

        mov ebx,eax
        mov rdi,malloc(&[rax*2+8])
        add rax,8

        .ifd MultiByteToWideChar(0, 0, rsi, -1, rax, ebx)

            mov dword ptr [rdi],  0x005C005C    ; "\\?\"
            mov dword ptr [rdi+4],0x005C003F
        .else
            free(rdi)
            xor edi,edi
        .endif
    .endif
    mov rax,rdi
    ret

__allocwpath endp

define MAXCOUNT 256

__setenvp proc private uses rsi rdi rbx envp:string_t

    .new offs[MAXCOUNT]:int_t

    ; size up the environment

    .for ( rdi = GetEnvironmentStringsA(),
           rsi = rax, ; save start of block in ESI
           eax = 0,
           ebx = 0,
           ecx = -1 : al != [rdi] && ebx < MAXCOUNT : )

        .if ( byte ptr [rdi] != '=' )

            mov  rdx,rdi    ; save offset of string
            sub  rdx,rsi
            mov  offs[rbx*int_t],edx
            inc  rbx        ; increase count
        .endif
        repnz scasb         ; next string..
    .endf

    inc ebx                 ; count strings plus NULL
    sub rdi,rsi             ; EDI to size
    malloc( &[rdi+rbx*size_t] ) ; pointers plus size of environment

    mov rcx,envp            ; return result
    mov [rcx],rax
    .if ( rax == NULL )
        .return
    .endif
    mov rcx,rdi
    mov rdi,rax
                            ; new adderss of block
    memcpy( &[rax+rbx*size_t], rsi, rcx )

    xchg rax,rsi            ; ESI to block
    FreeEnvironmentStringsA(rax)

    .for ( ebx--, ecx = 0 : ecx < ebx : ecx++ )

        mov eax,offs[rcx*int_t]
        add rax,rsi
        mov [rdi+rcx*string_t],rax
    .endf
    xor eax,eax
    mov [rdi+rcx*string_t],rax
   .return( rdi )

__setenvp endp

define MAXARGCOUNT 256
define MAXARGSIZE  0x8000  ; Max argument size: 32K

setargv proc private uses rsi rdi rbx argc:ptr int_t, cmdline:string_t

  local argv[MAXARGCOUNT]:string_t
  local buffer:string_t
  local i:int_t

    ldr rcx,argc
    ldr rsi,cmdline
    mov dword ptr [rcx],0
    mov buffer,malloc(MAXARGSIZE)
    mov rdi,rax
    lodsb

    .while al

        xor ecx,ecx     ; Add a new argument
        xor edx,edx     ; "quote from start" in EDX - remove
        mov [rdi],cl

        .for ( : al == ' ' || ( al >= 9 && al <= 13 ) : )
            lodsb
        .endf
        .break .if !al  ; end of command string

        .if ( al == '"' )
            add edx,1
            lodsb
        .endif
        .while ( al == '"' ) ; ""A" B"
            add ecx,1
            lodsb
        .endw

        .while al

            .break .if ( !edx && !ecx && ( al == ' ' || ( al >= 9 && al <= 13 ) ) )

            .if ( al == '"' )

                .if ecx
                    dec ecx
                .elseif edx
                    mov al,[rsi]
                    .break .if ( al == ' ' || ( al >= 9 && al <= 13 ) )
                    dec edx
                .else
                    inc ecx
                .endif
            .else
                stosb
            .endif
            lodsb
        .endw

        xor ecx,ecx
        mov [rdi],ecx
        lea rbx,[rdi+1]
        mov rdi,buffer
        .break .if ( cl == [rdi] )

        mov i,eax
        sub rbx,rdi
        memcpy(malloc(rbx), rdi, rbx)
        mov rdx,argc
        mov ecx,[rdx]
        mov argv[rcx*size_t],rax
        inc dword ptr [rdx]
        mov eax,i

        .break .if !( ecx < MAXARGCOUNT )
    .endw

    xor eax,eax
    mov rdx,argc
    mov ebx,[rdx]
    lea rdi,argv
    mov [rdi+rbx*size_t],rax
    lea rbx,[rbx*size_t+size_t]
    mov rsi,malloc(rbx)
    free(buffer)
    memcpy(rsi, rdi, rbx)
    ret

setargv endp

__initargv proc private uses rdi

  local pgname[260]:SBYTE

    __setenvp( &_environ )
    mov __argv,setargv(&__argc, GetCommandLineA())
    mov rax,[rax]

    .if ( byte ptr [rax+1] != ':' )

        free(rax)
        ;
        ; Get the program name pointer from Win32 Base
        ;
        GetModuleFileNameA(0, &pgname, 260)
        malloc(&[rax+1])
        lea rcx,pgname
        strcpy(rax, rcx)
        mov rcx,__argv
        mov [rcx],rax

        .if byte ptr [rax] == '"'
            mov rdi,rax
            strcpy(rdi, &[rax+1])
            .if strrchr(rdi, '"')
                mov byte ptr [rax],0
            .endif
            mov rax,rdi
        .endif
    .endif
    mov _pgmptr,rax
    ret

__initargv endp

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

removefile proc file:LPSTR

    setfattr(file, 0)
    remove(file)
    ret

removefile endp

removetemp proc path:LPSTR

  local nbuf[_MAX_PATH]:byte

    removefile(strfcat(&nbuf, envtemp, path))
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
    .ifd osopen(FileName, _A_NORMAL, M_RDONLY, A_OPEN) != -1

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

        .ifd osopen(FileName, _A_NORMAL, M_WRONLY, A_CREATETRUNC) != -1

            mov edi,eax
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
                remove(FileName)
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
    mov isexec,__isexec(rbx)

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

.pragma init(__initargv, 4)
.pragma init(__initpath, 5)
.pragma init(__initcomspec, 60)
.pragma init(GetEnvironmentPATH, 101)
.pragma init(GetEnvironmentTEMP, 102)

    end
