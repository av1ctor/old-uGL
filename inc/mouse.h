/*
 * mouse.h -- mouse module structs & prototypes
 */

#ifndef	__MOUSE_H__
#define	__MOUSE_H__

typedef struct _MOUSE {
        int		x;
        int		y;
        int		anyButton;
        int		left;
        int		middle;
        int		right;
} MOUSE;


#ifdef __cplusplus
extern "C" {
#endif

#ifndef UGLAPI
#define UGLAPI far pascal
#endif

int  UGLAPI		 mouseInit      ( PDC 		dc,
                                  MOUSE 	far *mouse );
        
void UGLAPI		 mouseEnd       ( void );
        

int  UGLAPI		 mouseReset     ( PDC 		dc,
                                  MOUSE 	far *mouse );
        
void UGLAPI		 mouseCursor    ( void		far *cursor,
                                  int		xSpot,
                                  int 		ySpot );

void UGLAPI		 mouseRange     ( int 		xmin, 
                                  int 		ymin, 
                                  int 		xmax,
                                  int 		ymax );
        
void UGLAPI		 mousePos       ( int 		x,
                                  int 		y );

void UGLAPI		 mouseRatio     ( int 		hMickeys,
                                  int 		vMickeys );

void UGLAPI		 mouseShow      ( void );

void UGLAPI		 mouseHide      ( void );

int  UGLAPI		 mouseIn        ( RECT far *box );

#ifdef __cplusplus
}
#endif

#endif	/* __MOUSE_H__ */