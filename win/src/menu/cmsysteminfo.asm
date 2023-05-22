; CMSYSTEMINFO.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include malloc.inc
include string.inc
include stdlib.inc
include sselevel.inc

    .data
     idleh DPROC 0
     count dd 0

    .code

UpdateMemoryStatus proc private uses rsi rdi rbx dialog:PDOBJ
ifdef _WIN95
  local M:MEMORYSTATUS
endif
  local MS:MEMORYSTATUSEX, value[32]:byte

    lea rdi,MS
    mov ecx,MEMORYSTATUSEX
    xor eax,eax
    rep stosb
    mov MS.dwLength,MEMORYSTATUSEX

ifdef _WIN95
    .if GetModuleHandle("kernel32.dll")

        .if GetProcAddress(eax, "GlobalMemoryStatusEx")

            lea  ecx,MS
            push ecx
            call eax
        .else
            GlobalMemoryStatus(addr M)

            mov MS.dwMemoryLoad,M.dwMemoryLoad
            mov dword ptr MS.ullTotalPhys,M.dwTotalPhys
            mov dword ptr MS.ullAvailPhys,M.dwAvailPhys
            mov dword ptr MS.ullTotalPageFile,M.dwTotalPageFile
            mov dword ptr MS.ullAvailPageFile,M.dwAvailPageFile
            mov dword ptr MS.ullTotalVirtual,M.dwTotalVirtual
            mov dword ptr MS.ullAvailVirtual,M.dwAvailVirtual
        .endif
    .endif
else
    GlobalMemoryStatusEx(addr MS) ; min WinXP
endif
    mov rsi,dialog
    mov ebx,[rsi].DOBJ.rc
    add ebx,0x0D03
    movzx edi,bh
    movzx ebx,bl
    mkbstring(&value, MS.ullTotalPhys)
    scputf(ebx, edi, 0, 0, "%17s", &value)

    inc edi
ifdef _WIN64
    mov rax,MS.ullTotalPhys
    sub rax,MS.ullAvailPhys
    mkbstring(addr value, rax)
else
    mov eax,dword ptr MS.ullTotalPhys
    mov edx,dword ptr MS.ullTotalPhys[4]
    sub eax,dword ptr MS.ullAvailPhys
    sbb edx,dword ptr MS.ullAvailPhys[4]
    mkbstring(addr value, edx::eax)
endif
    scputf(ebx, edi, 0, 0, "%17s", &value)

    sub edi,1
    add ebx,18
    mkbstring(addr value, MS.ullTotalPageFile)
    scputf(ebx, edi, 0, 0, "%17s", &value)

    inc edi
ifdef _WIN64
    mov rax,MS.ullTotalPageFile
    sub rax,MS.ullAvailPageFile
    mkbstring(addr value, rax)
else
    mov eax,dword ptr MS.ullTotalPageFile
    mov edx,dword ptr MS.ullTotalPageFile[4]
    sub eax,dword ptr MS.ullAvailPageFile
    sbb edx,dword ptr MS.ullAvailPageFile[4]
    mkbstring(addr value, edx::eax)
endif
    scputf(ebx, edi, 0, 0, "%17s", &value)
    ret

UpdateMemoryStatus endp

sysinfoidle proc private

    .if count == 156

        UpdateMemoryStatus(tdialog)
        mov count,0
    .endif
    inc count
    idleh()
    ret

sysinfoidle endp

cmsysteminfo proc uses rsi rdi rbx

  local CPU[80]:byte, MinorVersion, MajorVersion
  local q:Q64

    mov edi,sselevel
    setsselevel()
    mov sselevel,edi
    mov ebx,eax
    xor edi,edi
    mov count,edi

    .if rsopen(IDD_DZSystemInfo)

        mov rsi,rax
        mov rdx,[rsi].DOBJ.wp
        mov ecx,'x'
        mov eax,ebx

        .if eax & SSE_AVXOS
            mov [rdx+516*4],cl
        .endif
        .if eax & SSE_AVX512F
            mov [rdx+579*4],cl
        .endif
        .if eax & SSE_AVX2
            mov [rdx+617*4],cl
        .endif
        .if eax & SSE_AVX
            mov [rdx+554*4],cl
        .endif
        .if eax & SSE_SSE42
            mov [rdx+491*4],cl
        .endif
        .if eax & SSE_SSE41
            mov [rdx+428*4],cl
        .endif
        .if eax & SSE_SSSE3
            mov [rdx+606*4],cl
        .endif
        .if eax & SSE_SSE3
            mov [rdx+543*4],cl
        .endif
        .if eax & SSE_SSE2
            mov [rdx+480*4],cl
        .endif
        .if eax & SSE_SSE
            mov [rdx+417*4],cl
        .endif

        dlshow(rsi)

        .if GetModuleHandle("kernel32.dll")

            mov     ecx,[rax].IMAGE_DOS_HEADER.e_lfanew
            add     rax,rcx
            movzx   ecx,[rax].IMAGE_NT_HEADERS.OptionalHeader.MajorOperatingSystemVersion
            movzx   edx,[rax].IMAGE_NT_HEADERS.OptionalHeader.MinorOperatingSystemVersion
            mov     MajorVersion,ecx
            mov     MinorVersion,edx
            mov     dh,cl

            .switch edx
            .case _WIN32_WINNT_NT4:     lea rax,@CStr("NT4"):   .endc
            .case _WIN32_WINNT_WIN2K:   lea rax,@CStr("2K"):    .endc
            .case _WIN32_WINNT_WINXP:   lea rax,@CStr("XP"):    .endc
            .case _WIN32_WINNT_WS03:    lea rax,@CStr("WS03"):  .endc
            .case _WIN32_WINNT_VISTA:   lea rax,@CStr("VISTA"): .endc
            .case _WIN32_WINNT_WIN7:    lea rax,@CStr("7"):     .endc
            .case _WIN32_WINNT_WIN8:    lea rax,@CStr("8"):     .endc
            .case _WIN32_WINNT_WINBLUE: lea rax,@CStr("BLUE"):  .endc
            .case _WIN32_WINNT_WIN10:   lea rax,@CStr("10"):    .endc
            .default
                lea rax,@CStr("10+")
            .endsw

            movzx ecx,[rsi].DOBJ.rc.x
            movzx edx,[rsi].DOBJ.rc.y
            add   ecx,4
            add   edx,2
            mov   rdi,rax

            scputf(ecx, edx, 0, 0, "Windows %s Version %d.%d", rdi, MajorVersion, MinorVersion)
        .endif

        .if ebx
ifndef _WIN64
            .686
            .xmm
endif
            push rsi
            lea  rdi,CPU
            xor  esi,esi
            .repeat
                lea eax,[rsi+80000002h]
                cpuid
                mov [rdi],eax
                mov [rdi+4],ebx
                mov [rdi+8],ecx
                mov [rdi+12],edx
                add rdi,16
                inc esi
            .until esi == 3
            lea rdi,CPU
            mov rsi,rdi
            mov ecx,3*16
            lodsb
            .repeat
                .if !( al == ' ' && al == [rsi] )
                    stosb
                .endif
                lodsb
            .untilcxz
            mov [rdi],cl
            pop rsi
            mov ebx,[rsi].DOBJ.rc
            mov cl,bh
            add bl,4
            add cl,4
            scputs(ebx, ecx, 0, 0, &CPU)
        .endif

        UpdateMemoryStatus(rsi)
        __coreleft()
        mov q.q_h,0

        mov edi,ecx
        sub ecx,eax
        mov ebx,ecx
        mov q.q_l,edi
        mkbstring(&CPU, q)
        mov ecx,[rsi].DOBJ.rc
        mov dl,ch
        add cl,39
        add dl,13
        scputf(ecx, edx, 0, 0, "%15s", &CPU)

        mov q.q_l,ebx
        mkbstring(addr CPU, q)
        mov ecx,[rsi].DOBJ.rc
        mov dl,ch
        add cl,39
        add dl,14
        scputf(ecx, edx, 0, 0, "%15s", &CPU)

        mov idleh,tdidle
        mov tdidle,&sysinfoidle
        dlmodal(rsi)
        mov tdidle,idleh
    .endif
    ret

cmsysteminfo endp

    END
