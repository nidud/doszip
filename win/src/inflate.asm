; INFLATE.ASM--
;
;  inflate.c -- by Mark Adler
;  explode.c -- by Mark Adler
;
; Change history:
; 2012-09-08 - Modified for DZ32
; 03/31/2010 - Removed 386 instructions
; ../../1997 - Modified for Doszip

include wsub.inc
include malloc.inc
include string.inc
include errno.inc

define BMAX  16         ; Maximum bit length of any code (16 for explode)
define N_MAX 288        ; Maximum number of codes in any set
define OSIZE 0x8000

;
; Huffman code lookup table entry--this entry is four bytes for machines
;   that have 16-bit pointers (e.g. PC's in the small or medium model).
;   Valid extra bits are 0..13.  e == 15 is EOB (end of block), e == 16
;   means that v is a literal, 16 < e < 32 means that v is a pointer to
;   the next table, which codes e - 16 bits, and lastly e == 99 indicates
;   an unused code.  If a code with e == 99 is looked up, this implies an
;   error in the data.
;
HUFT        struct size_t
e           db ?        ; number of extra bits or operation
b           db ?        ; number of bits in this code or subcode
union
 n          dd ?        ; literal, length base, or distance base
 t          PVOID ?     ; pointer to next level of table
ends
HUFT        ends
PHUFT       typedef ptr HUFT


    .data

; Tables for deflate from PKZIP's appnote.txt

cplens dw \
     3, 4, 5, 6, 7, 8, 9,10, 11, 13, 15, 17, 19, 23, 27, 31,
     35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227
lens32 dw 258, 0, 0 ; 64: 3,0,0

cplext dw \ ; Extra bits for literal codes 257..285
    0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
    3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5
lext32 dw 0, 99, 99 ; 99==invalid, 64: 16,77,74

cpdist dw \ ; Copy offsets for distance codes 0..29 64: 31
    1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
    257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145,
    8193, 12289, 16385, 24577, 32769, 49153

cpdext dw \ ; Extra bits for distance codes
    0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
    7, 7, 8, 8, 9, 9, 10, 10, 11, 11,
    12, 12, 13, 13, 14, 14 ; 64: 14, 14

; Tables for length and distance for explode

cplen2 dw \
    2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,
    18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,
    35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,
    52,53,54,55,56,57,58,59,60,61,62,63,64,65

cplen3 dw \
    3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,
    19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,
    36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,
    53,54,55,56,57,58,59,60,61,62,63,64,65,66

extra dw \
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8

cpdist4 dw \
    1,65,129,193,257,321,385,449,513,577,641,705,
    769,833,897,961,1025,1089,1153,1217,1281,1345,1409,1473,
    1537,1601,1665,1729,1793,1857,1921,1985,2049,2113,2177,
    2241,2305,2369,2433,2497,2561,2625,2689,2753,2817,2881,
    2945,3009,3073,3137,3201,3265,3329,3393,3457,3521,3585,
    3649,3713,3777,3841,3905,3969,4033

cpdist8 dw \
    1,129,257,385,513,641,769,897,1025,1153,1281,
    1409,1537,1665,1793,1921,2049,2177,2305,2433,2561,2689,
    2817,2945,3073,3201,3329,3457,3585,3713,3841,3969,4097,
    4225,4353,4481,4609,4737,4865,4993,5121,5249,5377,5505,
    5633,5761,5889,6017,6145,6273,6401,6529,6657,6785,6913,
    7041,7169,7297,7425,7553,7681,7809,7937,8065

border db 16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15

align 4
ifdef __DEBUG__
hufts dd 0 ; track memory usage
endif

fixed_bd dd 0
fixed_bl dd 0
fixed_td PHUFT 0
fixed_tl PHUFT 0

define lbits 9
define dbits 6

align size_t

bb size_t 0 ; bit buffer
bk uint_t 0 ; bits in bit buffer

mask_bits dd \
    0x0000,
    0x0001,0x0003,0x0007,0x000F,0x001F,0x003F,0x007F,0x00FF,
    0x01FF,0x03FF,0x07FF,0x0FFF,0x1FFF,0x3FFF,0x7FFF,0xFFFF

    .code

    option proc:private, dotname

fill_inbuf proc uses rcx

.0:
    mov     edx,STDI.index
    mov     ecx,STDI.cnt
    sub     ecx,edx
    jz      .2
    cmp     ecx,size_t
    jb      .3
    add     rdx,STDI.base
    mov     rdx,[rdx]
    mov     eax,size_t * 8
    sub     eax,bk
    shr     eax,3
    add     STDI.index,eax
    lea     ecx,[rax*8-size_t*8]
    neg     ecx
    shl     rdx,cl
    shr     rdx,cl
    mov     ecx,bk
    shl     rdx,cl
    or      bb,rdx
    shl     eax,3
    add     bk,eax
.1:
    ret
.2:
    ioread( &STDI )
    test    eax,eax
    jz      .1
    jmp     .0
.3:
    mov     ecx,bk
    inc     STDI.index
    add     rdx,STDI.base
    movzx   edx,byte ptr [rdx]
    shl     edx,cl
    mov     eax,1
    shl     rax,cl
    dec     rax
    and     bb,rax
    or      bb,rdx
    add     bk,8
    mov     eax,bk
    jmp     .1

fill_inbuf endp


needbits proc watcall count:int_t

.0:
    cmp     eax,bk
    ja      .2
ifdef _WIN64
    lea     rcx,mask_bits
    mov     eax,[rcx+rax*4]
else
    mov     eax,mask_bits[eax*4]
endif
    and     rax,bb
.1:
    ret
.2:
    mov     ecx,eax
    call    fill_inbuf
    test    eax,eax
    jz      .1
    mov     eax,ecx
    jmp     .0

needbits endp

getbits proc watcall count:int_t

    mov     ecx,eax
.0:
    cmp     eax,bk
    ja      .2
ifdef _WIN64
    lea     rax,mask_bits
    mov     eax,[rax+rcx*4]
else
    mov     eax,mask_bits[ecx*4]
endif
    and     rax,bb
    sub     bk,ecx  ; dec bit count
    shr     bb,cl   ; dump used bits
.1:
    ret
.2:
    call    fill_inbuf
    test    eax,eax
    jz      .1
    mov     eax,ecx
    jmp     .0

getbits endp

;
; Free the malloc'ed tables built by huft_build(), which makes a linked
; list of the tables it made, with the links in a dummy first entry of
; each table.
;

huft_free proc watcall uses rbx huft:PHUFT

    .for ( rbx = huft : rbx : )

        lea rcx,[rbx-HUFT]
        mov rbx,[rcx].HUFT.t
        free(rcx)
    .endf
    ret

huft_free endp


huft_build proc uses rsi rdi rbx \
        b:ptr dword,        ; code lengths in bits (all assumed <= BMAX)
        n:dword,            ; number of codes (assumed <= N_MAX)
        s:dword,            ; number of simple-valued codes (0..s-1)
        d:ptr word,         ; list of base values for non-simple codes
        e:ptr word,         ; list of extra bits for non-simple codes
        t:ptr HUFT,         ; result: starting table
        m:ptr sdword        ; maximum lookup bits, returns actual

  local a:dword,            ; counter for codes of length k
        c[BMAX+1]:dword,    ; bit length count table
        el:dword,           ; length of EOB code (value 256)
        f:dword,            ; i repeats in table every f entries
        g:sdword,           ; maximum code length
        h:sdword,           ; table level
        i:dword,            ; counter, current code
        j:dword,            ; counter
        k:sdword,           ; number of bits in current code
        lx[BMAX+1]:sdword,  ; memory for l[-1..BMAX-1]
        l:ptr sdword,       ; stack of bits per table
        p:ptr dword,        ; pointer into c[], b[], or v[]
        q:ptr HUFT,         ; points to current table
        r:HUFT,             ; table entry for structure assignment
        u[BMAX]:PHUFT,      ; table stack
        v[N_MAX]:dword,     ; values in order of bit length
        w:sdword,           ; bits before this table == (l * h)
        x[BMAX+1]:dword,    ; bit offsets, then code stack
        xp:ptr dword,       ; pointer into x
        y:sdword,           ; number of dummy codes added
        z:dword             ; number of entries in current table


    ; Generate counts for each bit length

    lea rdi,z
    mov rcx,rbp
    sub rcx,rdi
    shr ecx,2
    xor eax,eax
    rep stosd

    mov rdx,b
    mov eax,BMAX    ; set length of EOB code, if any
    .if ( n > 256 )
        mov eax,[rdx+256*4]
    .endif
    mov el,eax

    .for ( : ecx < n : ecx++ )

        mov eax,[rdx+rcx*4]
        inc c[rax*4] ; assume all entries <= BMAX
    .endf

    mov rdx,m
    .if ( c[0] == ecx ) ; null input--all zero length codes

        xor eax,eax
        mov [rdx],eax
        mov rcx,t
        mov [rcx],rax
       .return
    .endif

    ; Find minimum and maximum length, bound *m by those

    .for ( ecx = 1 : ecx < BMAX : ecx++ )
        .break .if c[rcx*4]
    .endf
    mov k,ecx ; minimum code length
    .if ( [rdx] < ecx )
        mov [rdx],ecx
    .endif
    .for ( ecx = BMAX : ecx : ecx-- )
        .break .if c[rcx*4]
    .endf
    mov g,ecx ; maximum code length
    .if ( [rdx] > ecx )
        mov [rdx],ecx
    .endif

    ; Adjust last length count to fill out codes, if needed

    .for ( edx = ecx, ebx = 1, ecx = k, ebx <<= cl : ecx < edx : ecx++, ebx <<= 1 )

        sub ebx,c[rcx*4]
        .ifs ( ebx < 0 )
            .return( 2 ) ; bad input: more codes than bits
        .endif
    .endf
    sub ebx,c[rdx*4]
    .ifs ( ebx < 0 )
        .return( 2 )
    .endif
    mov y,ebx
    add c[rdx*4],ebx

    ; Generate starting offsets into the value table for each length

    .for ( --edx, eax = 0, ecx = 1 : edx : edx--, ecx++ )

        add eax,c[rcx*4]
        mov x[rcx*4+4],eax
    .endf

    ; Make a table of values in order of bit lengths

    .for ( rsi = b, edx = 0 : edx < n : edx++ )

        lodsd
        .if eax
            mov ecx,x[rax*4]
            inc x[rax*4]
            mov v[rcx*4],edx
        .endif
    .endf

    ; Generate the Huffman codes and for each, make the table entries

    mov rsi,-1      ; no tables yet--level -1
    lea rax,v
    mov p,rax
    lea rdi,lx[4]

    ; go through the bit lengths (k already is bits in shortest code)

    .for ( : k <= g : k++ )

        mov eax,k
        mov a,c[rax*4]

        .while ( a )

            dec a

            ; here i is the Huffman code of length k bits for value *p

            ; make tables up to required level

            .for ( eax = w, eax+=[rdi+rsi*4] : k > eax : )

                mov w,eax ; add bits already decoded
                inc esi

                ; compute minimum size table less than or equal to *m bits

                mov rcx,m
                mov eax,g
                sub eax,w
                .if ( eax > [rcx] )
                    mov eax,[rcx]
                .endif
                mov z,eax ; upper limit

                mov ecx,k ; try a k-w bit table
                sub ecx,w
                mov ebx,1
                shl ebx,cl
                mov eax,a
                inc eax

                .if ( ebx > eax )

                    sub ebx,eax ; deduct codes from patterns left

                    ; try smaller tables up to z bits

                    .for ( edx = k, ++ecx : ecx < z : ecx++ )

                        inc edx
                        add ebx,ebx
                        .if ( ebx <= c[rdx*4] )
                            .break          ; enough codes to use up j bits
                        .endif
                        sub ebx,c[rdx*4]    ; else deduct codes from patterns
                    .endf
                .endif

                mov ebx,w
                mov edx,el
                lea eax,[rbx+rcx]
                .if ( eax > edx && ebx < edx )
                    sub edx,ebx
                    mov ecx,edx     ; make EOB code end at table
                .endif

                mov eax,1
                shl eax,cl
                mov z,eax           ; table entries for j-bit table
                mov [rdi+rsi*4],ecx ; set table size in stack
                mov j,ecx

                ; allocate and link in new table

                inc  eax
                imul eax,eax,HUFT
                malloc(eax)
                .if ( rax == NULL )

                    .if ( esi )
                        huft_free(u)
                    .endif
                    .return( ER_MEM ) ; not enough memory
                .endif

ifdef __DEBUG__
                mov ecx,z
                inc ecx
                add hufts,ecx ; track memory usage
endif
                mov rcx,t
                add rax,HUFT
                mov [rcx],rax ; link to list for huft_free()
                mov q,rax
                lea rdx,[rax-HUFT].HUFT.t
                xor ecx,ecx
                mov [rdx],rcx
                mov t,rdx
                mov u[rsi*PHUFT],rax ; table starts after link

                ; connect to last table, if there is one

                .if ( esi )

                    mov     edx,i               ; save pattern for backing up
                    mov     x[rsi*4],edx
                    mov     ecx,w               ; connect to last table
                    mov     ebx,1
                    shl     ebx,cl
                    dec     ebx
                    and     ebx,edx
                    mov     edx,[rdi+rsi*4-4]
                    sub     ecx,edx
                    shr     ebx,cl
                    imul    ebx,ebx,HUFT
                    add     rbx,u[rsi*PHUFT-PHUFT]
                    mov     [rbx].HUFT.t,rax    ; pointer to this table
                    mov     eax,j
                    add     eax,16
                    mov     [rbx].HUFT.e,al     ; bits in this table
                    mov     [rbx].HUFT.b,dl     ; bits to dump before this table
                .endif
                mov eax,w
                add eax,[rdi+rsi*4]
            .endf

            ; set up table entry in r

            mov eax,k
            sub eax,w
            mov r.b,al

            mov ecx,n
            lea rax,v[rcx*4]
            mov rbx,p
            mov edx,s

            .if ( rbx >= rax )

                mov r.e,99          ; out of values--invalid code

            .elseif ( [rbx] < edx )

                mov eax,[rbx]
                .if ( eax < 256 )   ; 256 is end-of-block code
                    mov r.e,16
                .else
                    mov r.e,15
                .endif
                mov r.n,eax         ; simple code is just the value
                add rbx,4           ;

            .else

                mov ecx,[rbx]       ; non-simple--look up in lists
                sub ecx,s
                mov rdx,e
                movzx eax,byte ptr [rdx+rcx*2]
                mov r.e,al
                mov rdx,d
                mov ax,[rdx+rcx*2]
                mov r.n,eax
                add rbx,4
            .endif
            mov p,rbx

            ; fill code-like entries with r

            mov ecx,k
            sub ecx,w
            mov edx,1
            shl edx,cl
            mov ecx,w
            mov eax,i
            shr eax,cl

            .for ( ecx = eax : ecx < z : ecx += edx )

                imul ebx,ecx,HUFT
                add rbx,q
                mov al,r.e
                mov ah,r.b
                mov [rbx].HUFT.e,al
                mov [rbx].HUFT.b,ah
                mov rax,r.t
                mov [rbx].HUFT.t,rax
            .endf

            ; backwards increment the k-bit code i

            mov ecx,k
            dec ecx
            mov eax,1
            shl eax,cl
            mov edx,i

            .for ( ecx = eax : ecx & edx : ecx >>= 1 )

                xor edx,ecx
            .endf
            xor edx,ecx
            mov i,edx

            ; backup over finished tables

            mov ecx,w
            .while 1

                mov eax,1
                shl eax,cl
                dec eax
                and eax,edx

                .if ( eax == x[rsi*4] )
                    .break
                .endif
                dec esi
                sub ecx,[rdi+rsi*4]
            .endw
            mov w,ecx
        .endw
    .endf

    ; return actual size of base table

    mov rdx,m
    mov ecx,[rdi]
    mov [rdx],ecx

    ; Return true (1) if we were given an incomplete table

    xor eax,eax
    .if ( eax != y && g != 1 )
        inc eax
    .endif
    ret

huft_build endp


;************** Decompress the codes in a compressed block

inflate_codes proc uses rsi rdi rbx tl:PHUFT, td:PHUFT, l:SINT, d:SINT

    .while 1 ; do until end of block

        mov rbx,tl
        needbits(l)

        imul  eax,eax,HUFT
        add   rbx,rax
        movzx esi,[rbx].HUFT.e

        .if ( esi > 16 )

            .repeat

                .if ( esi == 99 )

                   .return( 1 )
                .endif

                movzx ecx,[rbx].HUFT.b
                sub bk,ecx
                shr bb,cl

                sub esi,16
                needbits(esi)

                mov   rbx,[rbx].HUFT.t
                imul  eax,eax,HUFT
                add   rbx,rax
                movzx esi,[rbx].HUFT.e
            .until esi <= 16
        .endif

        movzx ecx,[rbx].HUFT.b
        sub bk,ecx
        shr bb,cl

        .if ( esi == 16 ) ; then it's a literal

            .ifd !oputc([rbx].HUFT.n)

                .return(ER_DISK)
            .endif

        .else ; it's an EOB or a length

            .if ( esi == 15 ) ; exit if end of block

                .return( 0 )
            .endif

            ; get length of block to copy

            mov edi,[rbx].HUFT.n
            add edi,getbits(esi)

            ; decode distance of block to copy

            needbits(d)

            mov   rbx,td
            imul  eax,eax,HUFT
            add   rbx,rax
            movzx esi,[rbx].HUFT.e

            .if ( esi > 16 )

                .repeat

                    .if ( esi == 99 )

                       .return( 1 )
                    .endif

                    movzx ecx,[rbx].HUFT.b
                    sub bk,ecx
                    shr bb,cl

                    sub esi,16
                    needbits(esi)

                    mov   rbx,[rbx].HUFT.t
                    imul  eax,eax,HUFT
                    add   rbx,rax
                    movzx esi,[rbx].HUFT.e
                .until esi <= 16
            .endif
            movzx ecx,[rbx].HUFT.b
            sub bk,ecx
            shr bb,cl

            mov ebx,[rbx].HUFT.n
            mov edx,getbits(esi)
            mov eax,STDO.index
            sub eax,ebx
            sub eax,edx
            mov ebx,eax

            .repeat

                mov ecx,STDO.size
                lea eax,[rcx-1]
                and ebx,eax
                mov eax,ebx
                .if ( eax <= STDO.index )
                    mov eax,STDO.index
                .endif

                sub ecx,eax
                .if ( ecx > edi )
                    mov ecx,edi
                .endif

                sub edi,ecx
                mov eax,STDO.index
                add STDO.index,ecx
                mov edx,edi
                mov rdi,STDO.base
                mov rsi,STDO.base
                add rdi,rax
                add rsi,rbx
                add ebx,ecx
                add eax,ecx
                rep movsb
                mov edi,edx

                .if ( eax >= STDO.size )

                    .ifd !ioflush( &STDO )

                        .return(ER_DISK)
                    .endif
                .endif
            .until !edi
        .endif
    .endw
    ret

inflate_codes endp

;************** Decompress an inflated type 1 (fixed Huffman codes) block

inflate_fixed proc uses rdi rbx

  local ll[288]:DWORD   ; length list for huft_build

    lea rdi,ll
    xor eax,eax
    .if ( rax == fixed_tl )

        mov rbx,rdi
        mov ecx,144         ; literal table
        mov eax,8
        rep stosd
        mov ecx,112
        mov eax,9
        rep stosd
        mov ecx,24
        mov eax,7
        rep stosd           ; make a complete, but wrong code set
        mov ecx,8
        mov eax,8
        rep stosd

        mov rdi,rbx
        mov fixed_bl,7
        .ifd huft_build( rdi, 288, 257, &cplens, &cplext, &fixed_tl, &fixed_bl )

            mov fixed_tl,NULL
           .return
        .endif

        mov rdx,rdi         ; make an incomplete code set
        mov ecx,32
        mov eax,5
        rep stosd
        mov fixed_bd,5
        mov rdi,rdx
        .ifd huft_build( rdi, 32, 0, &cpdist, &cpdext, &fixed_td, &fixed_bd )

            .if ( eax != 1 )

                mov ebx,eax
                huft_free( fixed_tl )
                mov fixed_tl,NULL
                mov eax,ebx
               .return
            .endif
        .endif
    .endif
    ;
    ; decompress until an end-of-block code
    ;
    .ifd inflate_codes( fixed_tl, fixed_td, fixed_bl, fixed_bd )

        mov eax,1
    .endif
    ret

inflate_fixed endp

;************** Decompress an inflated type 2 (dynamic Huffman codes) block

inflate_dynamic proc uses rsi rdi rbx

  local nd:dword,       ; number of distance codes
        nl:dword,       ; number of literal/length codes
        nb:dword,       ; number of bit length codes
        tl:PHUFT,       ; literal/length code table
        td:PHUFT,       ; distance code table
        l:dword,        ; lookup bits for tl (bl)
        d:dword,        ; lookup bits for td (bd)
        n:dword,        ; number of lengths to get
        ll[320]:DWORD   ; literal/length and distance code lengths

    getbits(5)
    add eax,257
    mov nl,eax          ; number of literal/length codes
    getbits(5)
    inc eax
    mov nd,eax          ; number of distance codes
    getbits(4)
    add eax,4
    mov nb,eax          ; number of bit length codes

    .if ( nl > 288 || nd > 32 )    ; PKZIP_BUG_WORKAROUND
        .return( 1 )
    .endif

    lea rbx,border
    .for ( esi = 0 : esi < nb : esi++ )

        getbits(3)
        movzx edx,byte ptr [rbx+rsi]
        mov ll[rdx*4],eax
    .endf

    .for ( : esi < 19 : esi++ )

        movzx eax,byte ptr [rbx+rsi]
        mov ll[rax*4],0
    .endf

    ; build decoding table for trees--single level, 7 bit lookup

    mov l,7
    .ifd huft_build( &ll, 19, 19, NULL, NULL, &tl, &l )

        mov esi,eax
        .if ( eax == 1 )
            huft_free(tl)
        .endif
        .return( esi ) ; incomplete code set
    .endif

    mov eax,nl
    add eax,nd
    mov n,eax

    .for ( edi = 0, esi = 0 : esi < n : )

        needbits(l)

        mov     rbx,tl
        imul    eax,eax,HUFT
        add     rbx,rax
        mov     td,rbx
        movzx   ecx,[rbx].HUFT.b
        sub     bk,ecx
        shr     bb,cl

        mov eax,[rbx].HUFT.n
        .if ( eax < 16 )

            mov edi,eax
            mov ll[rsi*4],eax
            inc esi
            xor edx,edx

        .elseif ( eax == 16 )

            getbits(2)
            add eax,3
            mov edx,eax
            add eax,esi
            .if ( eax > n )
                .return( 1 )
            .endif

        .else

            .if ( eax == 17 )

                getbits(3)
                add eax,3
            .else
                getbits(7)
                add eax,11
            .endif
            mov edx,eax
            add eax,esi
            .if ( eax > n )
                .return( 1 )
            .endif
            xor edi,edi
        .endif

        .if edx
            .repeat
                mov ll[rsi*4],edi
                inc esi
                dec edx
            .untilz
        .endif
    .endf

    ; free decoding table for trees

    huft_free( tl )


    mov l,lbits
    huft_build( &ll, nl, 257, &cplens, &cplext, &tl, &l )

    .if ( l == 0 || eax == 1 )

        huft_free( tl )
       .return( 1 )
    .endif
    .if ( eax )
        .return
    .endif

    mov d,dbits
    mov eax,nl
    lea rcx,ll[rax*4]
    huft_build( rcx, nd, 0, &cpdist, &cpdext, &td, &d )

    .if ( l == 0 && nl <= 257 )

        huft_free( tl )
       .return( 1 )
    .endif
    .if ( eax == 1 )
        xor eax,eax
    .endif
    .if ( eax )

        mov ebx,eax
        huft_free( tl )
       .return( ebx )
    .endif

    mov ebx,inflate_codes( tl, td, l, d )
    huft_free( td )
    huft_free( tl )

    mov eax,ebx
    .if ( eax )
        mov eax,1
    .endif
    ret

inflate_dynamic endp


;****** Decompress an inflated type 0 (stored) block.

inflate_stored proc uses rsi


    mov eax,bk          ; go to byte boundary
    and eax,7
    getbits(eax)

    mov esi,getbits(16) ; number of bytes in block
    getbits(16)
    not ax
    .if ( eax != esi )

        .return( 1 )
    .endif
    .if ( eax == 0 )

        .return
    .endif
    .for ( : esi : esi-- ) ; read and output the compressed data

        .ifd !oputc(getbits(8))

            .return(ER_DISK)
        .endif
    .endf
    .return( 0 )

inflate_stored endp


zip_inflate proc public uses rsi rdi rbx

    mov bb,0
    mov bk,0
    mov lens32,258
    mov lext32[0],0
    mov lext32[2],99
    mov lext32[4],99

    .if ( zip_local.method == 9 )

        mov lens32,3
        mov lext32[0],16
        mov lext32[2],77
        mov lext32[4],74
    .endif

    .while 1

        mov edi,getbits(1)
        .switch getbits(2)
        .case 0
            inflate_stored()
           .endc
        .case 1
            inflate_fixed()
           .endc
        .case 2
            inflate_dynamic()
           .endc
        .default
            mov eax,ER_ZIP
        .endsw

        mov esi,eax
        .if ( eax == 0 )

            .continue .if !edi
            .ifd !ioflush(&STDO)
                mov esi,ER_USERABORT
                .if ( STDO.flag & IO_ERROR )
                    mov esi,ER_DISK
                .endif
            .endif
        .endif
        xor eax,eax
        .if ( rax != fixed_tl )
            huft_free( fixed_td )
            huft_free( fixed_tl )
            xor eax,eax
            mov fixed_td,rax
            mov fixed_tl,rax
        .endif
        .return( esi )
    .endw
    ret

zip_inflate endp


;-------------------------------------------------------------------------
; Explode
;-------------------------------------------------------------------------

;************** Explode an imploded compressed stream

; Get the bit lengths for a code representation from the compressed
; stream. If get_tree() returns 4, then there is an error in the data.
; Otherwise zero or -1 is returned.

get_tree proc uses rsi rbx l:ptr uint_t, n:uint_t

    ; get bit lengths

    .ifd ( ogetc() == -1 )

        .return( 4 )
    .endif
    lea ebx,[rax+1] ; length/count pairs to read
    xor esi,esi     ; next code

    .repeat

        .ifd ( ogetc() == -1 )

            .return( 4 )
        .endif

        mov ecx,eax
        and eax,0x0F
        mov edx,eax
        inc edx         ; bits in code (1..16)
        and ecx,0xF0
        shr ecx,4
        inc ecx         ; codes with those bits (1..16)

        lea eax,[rcx+rsi]
        .if ( eax > n ) ; don't overflow l[]

            .return( 4 )
        .endif
        mov rax,l
        .repeat
            mov [rax+rsi*4],edx
            inc esi
        .untilcxz
        dec ebx
    .untilz
    mov eax,ebx
    .if ( esi != n )
        mov eax,4
    .endif
    ret

get_tree endp


decode_huft proc uses rsi rdi htab:PHUFT, bits:int_t

    ldr rbx,htab
    ldr ecx,bits

    mov edi,1
    shl edi,cl
    dec edi

    needbits(ecx)

    .while 1

        not  eax
        and  eax,edi
        imul eax,eax,HUFT
        add  rbx,rax

        movzx ecx,[rbx].HUFT.b
        sub bk,ecx
        shr bb,cl

        movzx esi,[rbx].HUFT.e
        .if ( esi <= 16 )
            .return( 0 )
        .endif
        .if ( esi == 99 )
            .return( 1 )
        .endif
        sub esi,16
        lea rdx,mask_bits
        mov edi,[rdx+rsi*4]
        needbits(esi)
        mov rbx,[rbx].HUFT.t
    .endw
    ret

decode_huft endp


explode_docopy proc uses rsi rdi rbx tl:PHUFT, td:PHUFT, xbl:uint_t, xbd:uint_t, bdl:uint_t,
        s:ptr uint_t, u:ptr uint_t

    mov edi,getbits(bdl)        ; get distance low bits
    .ifd decode_huft(td, xbd)    ; get coded distance high bits

        .return
    .endif

    mov edx,[rbx].HUFT.n      ; construct offset
    mov eax,STDO.index
    sub eax,edi
    sub eax,edx
    mov edi,eax

    .ifd decode_huft(tl, xbl)    ; get coded length

        .return
    .endif

    mov esi,[rbx].HUFT.n      ; get length extra bits
    .if ( [rbx].HUFT.e )

        add esi,getbits(8)
    .endif

    mov rcx,s
    xor eax,eax
    mov edx,[rcx]
    mov [rcx],eax
    mov eax,esi
    .if ( edx > eax )

        sub edx,eax
        mov [rcx],edx
    .endif

    .while esi

        and edi,OSIZE-1
        mov eax,edi
        .if ( eax <= STDO.index )

            mov eax,STDO.index
        .endif

        mov ecx,OSIZE
        sub ecx,eax
        .if ( ecx >= esi )

            mov ecx,esi
        .endif

        sub     esi,ecx
        mov     eax,STDO.index
        add     STDO.index,ecx
        push    rsi
        mov     esi,edi
        add     edi,ecx
        push    rdi
        mov     rbx,STDO.base
        mov     rdi,rbx
        add     rdi,rax
        add     rbx,rsi
        mov     rdx,u

        .if ( uint_t ptr [rdx] && eax <= esi )

            xor eax,eax
            rep stosb
        .else
            mov rsi,rbx
            rep movsb
        .endif
        pop rdi
        pop rsi

        .if ( STDO.index >= OSIZE )

            mov uint_t ptr [rdx],0
            .ifd !ioflush(&STDO)
                .return( ER_DISK )
            .endif
        .endif
    .endw
    .return( 0 )

explode_docopy endp

; Decompress the imploded data using coded literals and a sliding
; window (of size 2^(6+bdl) bytes).

explode_lit proc uses rbx tb:PHUFT, tl:PHUFT, td:PHUFT,
        xbb:uint_t, xbl:uint_t, xbd:uint_t, bdl:uint_t

   .new u:uint_t = 1 ; true if unflushed
   .new s:uint_t = zip_local.fsize

    .while ( s ) ; do until ucsize bytes uncompressed

        .ifd getbits(1) ; then literal--decode it

            dec s
            .ifd decode_huft(tb, xbb)
                .return
            .endif
            .ifd ( oputc([rbx].HUFT.n) == 0 )
                .return( ER_DISK )
            .endif

            ; flush test?

        .elseifd explode_docopy(tl, td, xbl, xbd, bdl, &s, &u)

            .return
        .endif
    .endw
    .ifd !ioflush( &STDO )
        mov eax,ER_DISK
    .else
        xor eax,eax
    .endif
    ret

explode_lit endp

; Decompress the imploded data using uncoded literals and a sliding
; window (of size 2^(6+bdl) bytes).

explode_nolit proc tl:PHUFT, td:PHUFT, xbl:uint_t, xbd:uint_t, bdl:uint_t

   .new u:uint_t = 1 ; true if unflushed
   .new s:uint_t = zip_local.fsize

    .while ( s )

        .ifd getbits(1)

            dec s
            .ifd !oputc(getbits(8))
               .return( ER_DISK )
            .endif

            ; flush test?

        .elseifd explode_docopy(tl, td, xbl, xbd, bdl, &s, &u)

            .return
        .endif
    .endw
    .ifd !ioflush( &STDO )
        mov eax,ER_DISK
    .else
        xor eax,eax
    .endif
    ret

explode_nolit endp


zip_explode proc public uses rbx

   .new r:uint_t
   .new td:PHUFT
   .new tl:PHUFT
   .new tb:PHUFT
   .new xbl:uint_t
   .new xbb:uint_t
   .new xbd:uint_t
   .new bdl:uint_t
   .new l[256]:uint_t

    mov bb,0
    mov bk,0

    mov eax,7
    mov xbl,eax
    .if ( zip_local.csize > 200000 )
        inc eax
    .endif
    mov xbd,eax

    .if ( zip_local.flag & 4 )

        mov xbb,9
        .if get_tree(&l, 256)

            .return
        .endif

        .ifd huft_build( &l, 256, 256, 0, 0, &tb, &xbb )

            .if ( eax == 1 )
                mov ebx,eax
                jmp freetb
            .endif
            .return
        .endif

        .ifd get_tree(&l, 64)

            mov ebx,eax
            jmp freetb
        .endif
        lea rdx,cplen3

    .else

        mov tb,NULL
        .ifd get_tree(&l, 64)

           .return
        .endif
        lea rdx,cplen2
    .endif

    .ifd huft_build( &l, 64, 0, rdx, &extra, &tl, &xbl )

        mov ebx,eax
        .if ( eax == 1 )
            jmp freetl
        .endif
        jmp freetb
    .endif

    .ifd get_tree(&l, 64)

        mov ebx,eax
        jmp freetl
    .endif

    mov bdl,6
    lea rdx,cpdist4
    .if ( zip_local.flag & 2 )

        lea rdx,cpdist8
        inc bdl
    .endif

    .ifd huft_build( &l, 64, 0, rdx, &extra, &td, &xbd )

        mov ebx,eax
        .if ( eax == 1 )

            jmp freetd
        .endif
        jmp freetl
    .endif

    .if ( tb == NULL )
        mov ebx,explode_nolit(tl, td, xbl, xbd, bdl)
    .else
        mov ebx,explode_lit(tb, tl, td, xbb, xbl, xbd, bdl)
    .endif
freetd:
    huft_free( td )
freetl:
    huft_free( tl )
freetb:
    huft_free( tb )
    mov eax,ebx
    ret

zip_explode endp

    end
