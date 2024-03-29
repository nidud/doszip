include wsub.inc
include string.inc
include filter.inc
include time.inc
include kernel32.inc

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

string proc private file:string_t

    .if ( [rsi].FILTER.minclude )

        .if !cmpwargs( file, &[rsi].FILTER.minclude )
            .return
        .endif
    .endif
    .if ( [rsi].FILTER.mexclude )

        .if cmpwargs( file, &[rsi].FILTER.mexclude )
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
    .if ( binary(eax, [rdi].FBLK.flag, size_t ptr [rdi].FBLK.size) )

        .return string(&[rdi].FBLK.name)
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
    .if ( binary(eax, [rdi].WIN32_FIND_DATA.dwFileAttributes, rdx) )

        .return string(&[rdi].WIN32_FIND_DATA.cFileName)
    .endif
    ret

filter_wblk endp

    end
