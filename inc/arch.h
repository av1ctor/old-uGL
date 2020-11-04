/*
 * arch.bi -- UAR (UGL ARchive) routines
 */

#ifndef	__ARCH_H__
#define	__ARCH_H__

#include "deftypes.h"


typedef struct _UARHDR {
    long	sig;
    long 	dirOffset;
    long 	dirLength;
} UARHDR;

typedef struct _UARDIR {
	char 	fileName[56];
	long 	filePos;
	long 	fileLength;
} UARDIR;

typedef struct _UARCTX {
    UARHDR	hdr;
    long 	fileOffset;
    long 	fileSize;
} UARCTX;

typedef struct _UAR {
	DOSFILE f;
	UARCTX	ctx;
} UAR;


#ifdef __cplusplus
extern "C" {
#endif

#ifndef UGLAPI
#define UGLAPI far pascal
#endif

int  UGLAPI		 uarOpen        ( UAR 		far *uar,
								  STRING 	fname,
								  int 		mode );

void UGLAPI		 uarClose       ( UAR 		far *uar );

long UGLAPI		 uarRead        ( UAR 		far *uar,
								  void 		far *destine,
								  long 		bytes );

long UGLAPI		 uarReadH       ( UAR 		far *uar,
								  void 		far *destine,
								  long 		bytes );

long UGLAPI		 uarSeek        ( UAR 		far *uar,
								  int 		origin,
								  long 		bytes );

int  UGLAPI		 uarEOF         ( UAR far *uar );

long UGLAPI		 uarPos         ( UAR far *uar );

long UGLAPI		 uarSize        ( UAR far *uar );


#ifdef __cplusplus
}
#endif


/*
 * uar routines using buffers
 */
typedef struct _UARB {
	BFILE	bf;
	UARCTX	ctx;
} UARB;


#ifdef __cplusplus
extern "C" {
#endif

int  UGLAPI		 uarbOpen       ( UARB 		far *uarb,
								  STRING 	fname,
								  int 		mode,
								  long 		bufferSize );

void UGLAPI		 uarbClose      ( UARB 		far *uarb );

long UGLAPI		 uarbRead       ( UARB 		far *uarb,
                                  void 		far *destine,
                                  long 		bytes );

int  UGLAPI		 uarbRead1      ( UARB 		far *uarb );

int  UGLAPI		 uarbRead2      ( UARB 		far *uarb );

long UGLAPI		 uarbRead4      ( UARB 		far *uarb );

long UGLAPI		 uarbSeek       ( UARB 		far *uarb,
                                  int 		origin,
                                  long 		bytes );

int  UGLAPI		 uarbEOF        ( UARB 		far *uarb );

long UGLAPI		 uarbPos        ( UARB 		far *uarb );

long UGLAPI		 uarbSize       ( UARB 		far *uarb );


/*
 * direct management of archives (use with care!)
 */
int  UGLAPI		 uarFileFind    ( UAR 		far *uar,
                                  UARDIR 	*pdir,
                                  STRING 	fname );
        
int  UGLAPI		 uarFileSeek    ( UAR 		far *uar,
                                  UARDIR 	*pdir );

int  UGLAPI		 uarFileExtract ( UAR 		far *uar,
                                  UARDIR 	*pdir,
                                  STRING 	outFile );

int  UGLAPI		 uarFileAdd     ( UAR 		far *uar,
                                  STRING 	srcFile,
                                  STRING 	fileName );

int  UGLAPI		 uarFileDel     ( UAR 		far *uar,
                                  UARDIR 	*pdir );

int  UGLAPI		 uarCreate      ( UAR 		far *uar,
                                  STRING 	archiveName );

#ifdef __cplusplus
}
#endif

#endif	/* __ARCH_H__ */