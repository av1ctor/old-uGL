/*
 * dos.h -- DOS (file/conventinal memory) routines
 */

#ifndef __DOS_H__
#define __DOS_H__

#include "deftypes.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifndef UGLAPI
#define UGLAPI far pascal
#endif

void far* UGLAPI memAlloc		( long 		bytes );

void far* UGLAPI memCalloc 		( long 		bytes );
                
void UGLAPI		 memFree 		( void 		far *block );

long UGLAPI 	 memAvail 		( void );

void UGLAPI 	 memFill		( void 		far *block, 
						 		  long 		bytes, 
						 		  int 		value );

void UGLAPI      memCopy        ( void      far *dst,
                                  void      far *src,
                                  long      bytes );

#ifdef __cplusplus
}
#endif


typedef struct _DOSFILE {
	struct _DOSFILE far *prev;
	struct _DOSFILE far *next;
	long	pos;
	long	size;
	int		handle;
	int		mode;
	int		state;
} DOSFILE;
            
/* fileSeek/bfileSeek's origins: */                
#define S_START   0
#define S_CURRENT 1
#define S_END     2

/* fileOpen/bfileOpen' mode(s): */
#define F_READ   0x0001
#define F_WRITE  0x0002
#define F_RW	 (F_READ | F_WRITE)
#define F_CREATE (0x4000 | F_RW)
#define F_APPEND (0x8000 | F_WRITE)

#ifdef __cplusplus
extern "C" {
#endif

int  UGLAPI 	 fileOpen 		( DOSFILE 	far *f,
						 	  	  STRING	fname,
						 	  	  int 		mode );

void UGLAPI 	 fileClose		( DOSFILE 	far *f );

long UGLAPI 	 fileRead 		( DOSFILE 	far *f, 
						 		  void 		far *destine, 
						 		  long 		bytes );

long UGLAPI 	 fileWrite		( DOSFILE 	far *f, 
						 		  void 		far *source, 
						 		  long 		bytes );

long UGLAPI 	 fileReadH 		( DOSFILE 	far *f, 
						 		  void 		far *destine, 
						 		  long 		bytes );
                
long UGLAPI 	 fileWriteH 	( DOSFILE 	far *f, 
						  		  void 		far *source, 
						  		  long 		bytes );

int  UGLAPI 	 fileEOF 		( DOSFILE 	far *f );

long UGLAPI 	 filePos 		( DOSFILE 	far *f );

long UGLAPI 	 fileSize 		( DOSFILE 	far *f );

long UGLAPI 	 fileSeek 		( DOSFILE 	far *f, 
						 		  int 		origin, 
						 		  long 		bytes );

#ifdef __cplusplus
}
#endif


typedef struct _BFILE {
	DOSFILE	f;
	void	far *buffer;
	int		size;
	int		index;
	int		bytes;
	int		written;
	long	pos;
} BFILE;


#ifdef __cplusplus
extern "C" {
#endif

int	 UGLAPI 	 bfileOpen		( BFILE 	far *bf,
						 	 	  STRING	fname,
						 	 	  int 		mode,
						 	 	  long 		size );

void UGLAPI 	 bfileClose 	( BFILE 	far *bf);

int  UGLAPI 	 bfileBegin 	( BFILE 	far *bf,
						 	  	  void 		far *buffer,
						 	  	  long 		size );

void UGLAPI 	 bfileEnd		( BFILE 	far *bf);
                
long UGLAPI 	 bfileRead 		( BFILE 	far *bf, 
						 	 	  void 		far *destine,
					 		 	  long 		bytes );

int  UGLAPI 	 bfileRead1 	( BFILE 	far *bf);

int  UGLAPI 	 bfileRead2 	( BFILE 	far *bf);

long UGLAPI 	 bfileRead4 	( BFILE 	far *bf);

long UGLAPI 	 bfileWrite 	( BFILE 	far *bf,
						 	  	  void 		far *source,
						 	  	  long 		bytes );

int  UGLAPI 	 bfileWrite1 	( BFILE 	far *bf,
						 	   	  int 		value );

int  UGLAPI 	 bfileWrite2 	( BFILE 	far *bf, 
						 	   	  int 		value );

int  UGLAPI 	 bfileWrite4 	( BFILE 	far *bf,
						 	   	  long 		value );

int	 UGLAPI 	 bfileEOF		( BFILE 	far *bf );
		
long UGLAPI 	 bfilePos		( BFILE 	far *bf );

long UGLAPI 	 bfileSize		( BFILE 	far *bf );

long UGLAPI 	 bfileSeek		( BFILE 	far *bf,
					 		 	  int 		origin,
						 	 	  long 		bytes );

#ifdef __cplusplus
}
#endif

#endif	/* __DOS_H__ */
