/*
 * ems.h -- expanded memory (EMS) routines
 */

#ifndef	__EMS_H__
#define	__EMS_H__

typedef struct _EMS_SAVECTX {
    unsigned char __internal[64];
} EMS_SAVECTX;

#ifdef __cplusplus
extern "C" {
#endif

#ifndef UGLAPI
#define UGLAPI far pascal
#endif

int  UGLAPI		 emsCheck   ( void );

int  UGLAPI		 emsSave    ( EMS_SAVECTX far *ctx );

int  UGLAPI		 emsRestore ( EMS_SAVECTX far *ctx );

int  UGLAPI		 emsAlloc   ( long 		bytes );

int  UGLAPI		 emsCAlloc  ( long 		bytes );
        
void UGLAPI		 emsFree    ( int 		hnd );

long UGLAPI		 emsAvail   ( void );

int  UGLAPI		 emsMap     ( int 		hnd,
                              long 		offs, 
                              long 		bytes );

void UGLAPI		 emsFill    ( int 		hnd,
                              long 		offs,
                              long 		bytes,
                              int 		fchar );

#ifdef __cplusplus
}
#endif

#endif	/* __EMS_H__ */