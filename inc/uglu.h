/*
 * uglu.h -- UGL Util module routines
 */

#ifndef	__UGLU_H__
#define	__UGLU_H__

typedef struct _QUADBEZ3D {
        PNT3D	a;
        PNT3D	b;
        PNT3D	c;
} QUADBEZ3D;

typedef struct _CUBICBEZ3D {
        PNT3D	a;
        PNT3D	b;
        PNT3D	c;
        PNT3D	d;
} CUBICBEZ3D;


#ifdef __cplusplus
extern "C" {
#endif

#ifndef UGLAPI
#define UGLAPI far pascal
#endif

void UGLAPI		 ugluQuadricBez ( PNT2D 	far *storage,
                                  QUADBEZ 	far *qbz, 
                                  int 		levels);
                 
void UGLAPI		 ugluQuadricBez3D ( PNT3D 	far *storage,
                                    QUADBEZ far *qbz3D, 
                                    int 	levels );

void UGLAPI		 ugluCubicBez   ( PNT2D 	far *storage,
                                  CUBICBEZ 	far *cbz, 
                                  int 		levels );

void UGLAPI		 ugluCubicBez3D ( PNT3D 	far *storage,
                                  CUBICBEZ 	far *cbz3D, 
                                  int 		levels );

int UGLAPI       ugluIsMMX      ( );

int UGLAPI       ugluIsMMXEx    ( );

int UGLAPI       ugluIs3DNow    ( );

int UGLAPI       ugluIs3DNowEx  ( );

int UGLAPI       ugluIsSSE      ( );

int UGLAPI       ugluIsSSE2     ( );

                                 
#ifdef __cplusplus
}
#endif

#endif	/* __UGLU_H__ */