include io.inc
include time.inc
include winbase.inc
include dzlib.inc

    .code

setftime proc uses ebx h:SINT, t:SIZE_T

  local FileTime:FILETIME

    .if getosfhnd(h) != -1

        mov ebx,eax
        .if SetFileTime(ebx, 0, 0, TimeToFileTime(t, addr FileTime))

            xor eax,eax
            mov byte ptr _diskflag,2
        .else
            osmaperr()
        .endif
    .endif
    ret

setftime endp

setftime_create proc uses ebx h:SINT, t:SIZE_T

  local FileTime:FILETIME

    .if getosfhnd(h) != -1

        mov ebx,eax
        .if SetFileTime(ebx, TimeToFileTime(t, &FileTime), 0, 0)

            xor eax,eax
            mov byte ptr _diskflag,2
        .else
            osmaperr()
        .endif
    .endif
    ret

setftime_create endp

setftime_access proc uses ebx h:SINT, t:SIZE_T

  local FileTime:FILETIME

    .if getosfhnd(h) != -1

        mov ebx,eax
        .if SetFileTime(ebx, 0, TimeToFileTime(t, addr FileTime), 0)

            xor eax,eax
            mov byte ptr _diskflag,2
        .else
            osmaperr()
        .endif
    .endif
    ret

setftime_access endp

    END
