include wsub.inc
include string.inc
include filter.inc
include time.inc

    .data
     filter PFILTER 0

    .code

binary proc watcall private date:uint_t, attrib:uint_t, size:size_t

    .if ( date < [rsi].FILTER.min_date ||
          ( [rsi].FILTER.max_date && date > [rsi].FILTER.max_date ) )
        .return( 0 )
    .endif
    mov eax,attrib
    and ax,[rsi]
    .if ( eax != attrib || size < [rsi].FILTER.min_size ||
         ( [rsi].FILTER.max_size && size > [rsi].FILTER.max_size ) )
        .return( 0 )
    .endif
    .return( 1 )

binary endp


_wildcards proc private uses rdi wild:LPSTR, path:LPSTR

    ldr rdi,wild

    .repeat

        .if strchr(rdi, ' ')

            mov rdi,rax
            mov byte ptr [rdi],0
            strwild(rax, path)
            mov byte ptr [rdi],' '
            inc rdi
        .else

            strwild(rdi, path)
           .break
        .endif
    .until eax
    ret

_wildcards endp


string proc private file:string_t

    .if ( [rsi].FILTER.minclude )

        .ifd !_wildcards( &[rsi].FILTER.minclude, file )
            .return
        .endif
    .endif
    .if ( [rsi].FILTER.mexclude )

        .ifd _wildcards( &[rsi].FILTER.mexclude, file )
            .return( 0 )
        .endif
    .endif
    .return( 1 )

string endp


filter_fblk proc uses rsi rdi rbx fb:PFBLK

    mov rsi,filter
    .if ( rsi == NULL )
        .return( 1 )
    .endif

    ldr rdi,fb
    mov eax,[rdi].FBLK.time
    and eax,0xFFFF0000
    .ifd ( binary(eax, [rdi].FBLK.flag, size_t ptr [rdi].FBLK.size) )

        .return string([rdi].FBLK.name)
    .endif
    ret

filter_fblk endp

filter_wblk proc uses rsi rdi rbx wf:PTR WIN32_FIND_DATA

    mov rsi,filter
    .if ( rsi == NULL )
        .return( 1 )
    .endif

    ldr rdi,wf
    FileTimeToTime( &[rdi].WIN32_FIND_DATA.ftLastWriteTime )
    and eax,0xFFFF0000
    mov edx,[rdi].WIN32_FIND_DATA.nFileSizeLow
ifdef _WIN64
    mov ecx,[rdi].WIN32_FIND_DATA.nFileSizeHigh
    shl rcx,32
    or  rdx,rcx
endif
    .ifd ( binary(eax, [rdi].WIN32_FIND_DATA.dwFileAttributes, rdx) )

        .return string(&[rdi].WIN32_FIND_DATA.cFileName)
    .endif
    ret

filter_wblk endp

    end
