; CMSWAP.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include string.inc

    .code

cmswap proc uses rsi rdi

    .if panel_stateab()

	mov esi,config.c_apath.flag
	mov edi,config.c_bpath.flag
	panel_hide(panela)
	panel_hide(panelb)
	memxchg(&config.c_fcb_indexa, &config.c_fcb_indexb, 8)
	memxchg(&spanela.fcb_index, &spanelb.fcb_index, 8)
	memxchg(&config.c_apath, &config.c_bpath, WSUB)
	xor esi,_W_PANELID
	xor edi,_W_PANELID
	mov config.c_apath.flag,edi
	mov config.c_bpath.flag,esi
	xor config.c_cflag,_C_PANELID
	panel_show(panela)
	panel_show(panelb)
	mov eax,1
    .endif
    ret

cmswap endp

    END
