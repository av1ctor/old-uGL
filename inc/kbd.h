/*
 * kbd.bi -- multiple keys press processing module structs & prototypes
 */

#ifndef	__KBD_H__
#define	__KBD_H__

typedef struct _KBD {
        int		lastkey;
        int		esc;
        int		one;
        int		two;
        int		three;
        int		four;
        int		five;
        int		six;
        int		seven;
        int		eight;
        int		nine;
        int		zero;
        int		less;
        int		equal;
        int		backspc;
        int		tabk;
        int		q;
        int		w;
        int		e;
        int		r;
        int		t;
        int		y;
        int		u;
        int		i;
        int		o;
        int		p;
        int		opnBrck;
        int		clsBrck;
        int		enter;
        int		ctrl;
        int		a;
        int		s;
        int		d;
        int		f;
        int		g;
        int		h;
        int		j;
        int		k;
        int		l;
        int		semicol;
        int		apost;
        int		tilde;
        int		lshift;
        int		bslash;
        int		z;
        int		x;
        int		c;
        int		v;
        int		b;
        int		n;
        int		m;
        int		comma;
        int		dot;
        int		slash;
        int		rshift;
        int		prt;
        int		alt;
        int		spcbar;
        int		caps;
        int		f1;
        int		f2;
        int		f3;
        int		f4;
        int		f5;
        int		f6;
        int		f7;
        int		f8;
        int		f9;
        int		f10;
        int		numlock;
        int		scroll;
        int		home;
        int		up;
        int		pgup;
        int		min;
        int		left;
        int		mid;
        int		right;
        int		plus;
        int		endk;
        int		down;
        int		pgdw;
        int		ins;
        int		del;
        int		sysreq;
        int		reserv0[2];
        int		f11;
        int		f12;
        int		reserv1[40];
} KBD;


#ifdef __cplusplus
extern "C" {
#endif

#ifndef UGLAPI
#define UGLAPI far pascal
#endif

void UGLAPI		 kbdInit        ( KBD 		far *kbd );

void UGLAPI		 kbdEnd         ( void );

void UGLAPI		 kbdPause       ( void );

void UGLAPI		 kbdResume      ( void );

#ifdef __cplusplus
}
#endif

#endif	/* __KBD_H__ */