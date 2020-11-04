/*
 * xms.h -- extended memory (XMS) routines
 */

#ifndef	__EMS_H__
#define	__EMS_H__

#ifdef __cplusplus
extern "C" {
#endif

#ifndef UGLAPI
#define UGLAPI far pascal
#endif

int  UGLAPI		 xmsCheck   ( void );

int  UGLAPI		 xmsAlloc   ( long 		bytes );

int  UGLAPI		 xmsCAlloc  ( long 		bytes );
        
void UGLAPI		 xmsFree    ( int 		hnd );

long UGLAPI		 xmsAvail   ( void );

int  UGLAPI		 xmsMap     ( int 		hnd,
                              long 		offs, 
                              int 		mode );

void UGLAPI		 xmsFill    ( int 		hnd,
                              long 		offs,
                              long 		bytes,
                              int 		fchar );

#ifdef __cplusplus
}
#endif

#endif	/* __EMS_H__ */