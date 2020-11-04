/*
 * tmr.h -- high-resolution multiple concurrent timers module
 */

#ifndef	__TMR_H__
#define	__TMR_H__

/* TMR_state: */
#define TMR_OFF  0
#define TMR_ON   -1

/* TMR_mode: */
#define TMR_ONESHOT   0
#define TMR_AUTOINIT  1

#define TCALLBK     far pascal


typedef struct _TMR {
    int         state;                      /* ON, OFF */
    int         mode;                       /* ONESHOT, AUTOINIT */
    long        counter;                    /* user counter (AUTOINIT only) */
    long        rate;                       /* original rate   (in hertz) */
    long        cnt;                        /* current counter (/  /    ) */
    long        reserved[2];                /* Reserved, don't mess it with */
    struct _TMR far *prv;
    struct _TMR far *nxt;
} TMR;


#ifdef __cplusplus
extern "C" {
#endif

#ifndef UGLAPI
#define UGLAPI far pascal
#endif

void UGLAPI		 tmrInit        ( void );

void UGLAPI		 tmrEnd         ( void );


void UGLAPI		 tmrNew         ( TMR 		far *tmr,
                                  int		mode,
                                  long		rate );

void UGLAPI		 tmrDel         ( TMR far *tmr );

        
#define 		 tmrPause( tmr ) tmrDel( tmr )

void UGLAPI		 tmrResume      ( TMR far *tmr );

void UGLAPI		 tmrCallbkSet   ( TMR far *tmr, 
                                  void (TCALLBK *callbk)(void) );

void UGLAPI		 tmrCallbkCancel( TMR far *tmr );

long UGLAPI		 tmrUs2Freq     ( long microsecs );

long UGLAPI		 tmrMs2Freq     ( long milisecs );

long UGLAPI		 tmrTick2Freq   ( long ticks );

long UGLAPI		 tmrSec2Freq    ( int seconds );

long UGLAPI		 tmrMin2Freq    ( int minutes );

#ifdef __cplusplus
}
#endif

#endif	/*_TMR_H__ */
