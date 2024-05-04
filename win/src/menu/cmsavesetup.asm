; CMSAVESETUP.ASM--
; Copyright (C) 2016 Doszip Developers -- see LICENSE.TXT

include doszip.inc
include errno.inc

    .code

cmsavesetup proc

    .ifd rsmodal(IDD_DZSaveSetup)

        .ifd !config_save()

            eropen(__srcfile)
            inc eax
        .endif
    .endif
    ret

cmsavesetup endp

    END
