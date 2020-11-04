#ifndef __bas_h__
#define __bas_h__

typedef unsigned char UBYTE;
typedef char BYTE;
typedef unsigned short UWORD;
typedef short WORD;
typedef unsigned long UDWORD;
typedef long DWORD;
typedef short BOOL;

#define BDECL pascal far
#define BAS_TRUE -1
#define BAS_FALSE 0

typedef struct _BASARRAY {
	void		far *farptr;
	short		next_dsc;
	short		next_dsc_size;
	char		dimensions;
	char		type_storage;		// 1=far,2=huge,64=static,128=string
	short		adjs_offset;
	short		element_len;
	short		last_dim_elemts;
	short		last_dim_first;
} BASARRAY;

typedef struct _BASSTR {
#ifndef __FAR_STRINGS__
	WORD len;       						/* QB's near strg descriptor */
	char near *ofs;
#else
	UWORD near **ofs_tb;       			    /* QBX's far strg descriptor */
	UWORD near **seg_tb;
#endif
} BASSTR;

#ifdef __FAR_STRINGS__
typedef struct _FSTRG { 					/* QBX's far string */
	WORD len;
	BYTE data[1];							/* ... */
} FSTRG;
#endif

/*::::::::::::::*/
/* get address and lenght of a BASIC string*/
#ifndef  __FAR_STRINGS__
#define BSTRG(bStr, p, l) 													\
		l = bStr.len;                                                       \
        (UWORD)*(&p+0) = bStr.ofs;                                          \
        (UWORD)*(&p+2) = _DS;
#else
#define BSTRG(bStr, p, l) 													\
		l = bStr.
#endif

#endif	/* __bas_h__ */
