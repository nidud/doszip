; CMSORT.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include string.inc

.code

cmsort proc private uses rsi rdi rbx panel:PPANEL, flags:uint_t
  local path[_MAX_PATH]:byte
    ldr esi,flags
    .ifd panel_state(ldr(panel))
        mov ecx,esi
        mov rdi,rax
        mov rsi,[rax].PANEL.wsub
        mov eax,[rsi].WSUB.flag
        and eax,not (_W_SORTSIZE or _W_NOSORT)
        or  eax,ecx
        mov [rsi].WSUB.flag,eax
        .if panel_curobj(rdi)
            lea rcx,path
            strcpy(rcx, rax)
            wssort(rsi)
            .ifd wsearch(rsi, &path) != -1
                mov ebx,eax
                dlclose([rdi].PANEL.xl)
                panel_setid(rdi, ebx)
                .if rdi == cpanel
                    pcell_show(rdi)
                .endif
            .endif
        .endif
        panel_putitem(rdi, 0)
        mov eax,1
    .endif
    ret
    endp

cmnosort proc private uses rbx panel:PPANEL
    .if panel_state(ldr(panel))
        mov rbx,rax
        mov rdx,[rax].PANEL.wsub
        or [rdx].WSUB.flag,_W_NOSORT
        panel_read(rax)
        panel_putitem(rbx, 0)
        mov eax,1
    .endif
    ret
    endp

cmanosort proc
    .return cmnosort(panela)
    endp
cmbnosort proc
    .return cmnosort(panelb)
    endp
cmcnosort proc
    .return cmnosort(cpanel)
    endp
cmadate proc
    .return cmsort(panela, _W_SORTDATE)
    endp
cmbdate proc
    .return cmsort(panelb, _W_SORTDATE)
    endp
cmcdate proc
    .return cmsort(cpanel, _W_SORTDATE)
    endp
cmatype proc
    .return cmsort(panela, _W_SORTTYPE)
    endp
cmbtype proc
    .return cmsort(panelb, _W_SORTTYPE)
    endp
cmctype proc
    .return cmsort(cpanel, _W_SORTTYPE)
    endp
cmasize proc
    .return cmsort(panela, _W_SORTSIZE)
    endp
cmbsize proc
    .return cmsort(panelb, _W_SORTSIZE)
    endp
cmcsize proc
    .return cmsort(cpanel, _W_SORTSIZE)
    endp
cmaname proc
    .return cmsort(panela, _W_SORTNAME)
    endp
cmbname proc
    .return cmsort(panelb, _W_SORTNAME)
    endp
cmcname proc
    .return cmsort(cpanel, _W_SORTNAME)
    endp

    END
