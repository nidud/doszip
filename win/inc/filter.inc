ifndef __FILTER_INC
define __FILTER_INC

define FILT_MAXSTRING 128

FILTER		STRUC
flag		dd ?
max_date	dd ?
min_date	dd ?
max_size	size_t ?
min_size	size_t ?
minclude	db FILT_MAXSTRING dup(?)
mexclude	db FILT_MAXSTRING dup(?)
FILTER		ENDS
PFILTER		typedef ptr FILTER

externdef	filter:PFILTER
filter_fblk	PROTO :PFBLK
filter_wblk	PROTO :PTR WIN32_FIND_DATA

endif
