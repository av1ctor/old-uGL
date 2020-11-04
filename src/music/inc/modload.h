/*
**
** inc/modload.h - protracker module loading
**
**
*/
#include "inc\modcmn.h"

#ifndef         __modload_h__
#define         __modload_h__


//
// Constants
//
#define UGMID               0x4d475558

#define mod_mem             0
#define mod_ems             1

//
// Structure definitions
//
typedef struct
{
    sint16      note;
    uint8       inst;
    uint8       effect;
    uint8       effectpara;
} UGMPattern, far *lp_UGMPattern;

typedef struct
{
    uint8       type;
    uint8       patterns;
	union {
		uint16      hndl;
		void far *  addr;
	};
} UGMPatternCtx;


typedef struct
{   
    uint32      slength;
    sint8       finetune;
    uint8       volume;
    uint32      loopstr;
    uint32      loopend;
    uint32      hsample;
} UGMInst;

typedef struct _UGMHeader
{   
    uint32      ID;
    uint16      state;
    uint8       playmode;
    uint8       channels;
    uint8       songLength;
    uint8       songOrder[128];
    UGMInst     instruments[31];
    UGMPatternCtx patternData;
    
    uint8       bps;
    uint8       speed;
    uint8       currPat;
    uint8       currRow;
    uint8       currTick;
    uint8       jumpFlags;
    struct _UGMHeader far * next;
    struct _UGMHeader far * prev;
} UGMHeader, far* lp_UGMHeader;


typedef struct
{
    char        iname[22];              /* instrument name */
    uint16      slength;                /* sample length */
    uint8       finetune;               /* sample finetune value */
    uint8       volume;                 /* sample default volume */
    uint16      loopStart;              /* sample loop start, in words */
    uint16      loopLength;             /* sample loop length, in words */
} modInstHdr;


typedef struct
{
    char        songName[20];           /* song name */
    modInstHdr  instruments[31];        /* instrument headers */
    uint8       songLength;             /* song length */
    uint8       restart;                /* unused by Protracker, song restart
                                           position in some modules */
    uint8       songData[128];          /* pattern playing orders */
    char        sign[4];                /* module signature */
} modHeader;



//
// Routines
//
bool UGLAPI modNew                 ( lp_UGMHeader mod, 
                                      sint16 memtype, 
                                      STRING filename );

void UGLAPI modDel                 ( lp_UGMHeader mod );




#endif       /* __modload_h__ */
