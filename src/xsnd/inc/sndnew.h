#ifndef __SNDNEW_H__
#define __SNDNEW_H__

#define         snd_default      0x0000
#define         snd_signed       0x0001
#define         snd_unsigned     0x0002

#define         DATAID          0x61746164
#define         FRMTID          0x20746d66
#define         RIFFID          0x46464952
#define         WAVEID          0x45564157
#define         WAVE_FORMAT_PCM 0x0001    
    
typedef struct
{
    uint32          riffID;
    uint32          chunkSize;
    uint32          waveID;
} WAVE_HEADER;

typedef struct
{
    uint32          chunkID;
    uint32          chunkSize;
} WAVE_CHUNK;

typedef struct
{
    uint16          formatTag;
    uint16          channels;
    uint32          smpPerSec;
    uint32          bytesPerSec;
    uint16          blockAlign;
    uint16          bitsPerSmp;
} WAVE_FMT_CHUNK;



// ::::::::::::::::::
// Interface routines
//
//
// ::::::::::::::::::





// ::::::::::::::::::
// Internal routines, do not attempt to use them from 
// outside this file. System might crash.
//
//
// ::::::::::::::::::
bool near __snd_int_load_to_mem ( XS_PSAMPLE smp, uint16 sign, UAR far* file,
                                 sint32 offs, sint32 len );
void near __snd_int_smpl_add    ( XS_PSAMPLE smpl );
void near __snd_int_smpl_del    ( XS_PSAMPLE smpl );
void far cdecl __snd_int_delall ( void );


#endif     // __sndnew_h__

