/*
**
** sndnew.c - Load and unload samples
** note: Should be compiled with Borland C++ 5 (watcom ?)
** todo: Fix the FIXMEs
*/
#include "inc\common.h"
#include "dos.h"
#include "arch.h"
#include "ems.h"
#include "inc\snd.h"
#include "inc\sndnew.h"


// :::::::::::::
// name: sndNewWave
// desc: Loads a wave
//
// :::::::::::::
XS_PSAMPLE BDECL sndNewWav ( sint16 bufftype, STRING filename )
{
    UAR file;
    XS_PSAMPLE smp;
    sint16 sign, smpfrmt;

    WAVE_CHUNK  wavChunk;
    WAVE_HEADER wavHeader;
    WAVE_CHUNK  wavDatChunk;
    WAVE_FMT_CHUNK wavFmtChunk;
    
    bool fmtChunkFound = false;
    bool datChunkFound = false; 
    
    

    //
    // Open file
    //
    if ( uarOpen( &file, filename, F_READ ) == false )
         return false;
    

    //
    // Load header
    //
    if ( uarRead( &file, &wavHeader, sizeof( WAVE_HEADER ) ) != sizeof( WAVE_HEADER ) )
    {
        uarClose( &file );
        return false;
    }
    
    
    //
    // A valid WAVE ?
    //
    if ( (wavHeader.riffID != RIFFID) || (wavHeader.waveID != WAVEID) )
    {
        uarClose( &file );
        return false;
    }


    //
    // Find the format and data chunk
    //
    do
    {
        if (  uarEOF( &file ) == true ) 
        {
            uarClose( &file );
            return false;
        }
                    
        if ( uarRead( &file, &wavChunk, sizeof( WAVE_CHUNK ) ) != 
             sizeof( WAVE_CHUNK ) )
        {
            uarClose( &file );
            return false;
        }
        
        
        if ( wavChunk.chunkID == FRMTID ) 
        {
            if ( datChunkFound == true )
            {
                uarClose( &file );
                return false;
            }
            
            if ( uarRead( &file, &wavFmtChunk, wavChunk.chunkSize ) != 
                 wavChunk.chunkSize )
            {
                uarClose( &file );
                return false;
            }
            
            if ( wavFmtChunk.formatTag != WAVE_FORMAT_PCM ) 
            {
                uarClose( &file );
                return false;
            }                
            
            fmtChunkFound = true;
        }
        
        else if ( wavChunk.chunkID == DATAID ) 
        {
            if ( fmtChunkFound == false )
            {
                uarClose( &file );
                return false;
            }

            datChunkFound = true;
            wavDatChunk.chunkID = wavChunk.chunkID;
            wavDatChunk.chunkSize = wavChunk.chunkSize;
        }
        
        else
            uarSeek( &file, S_CURRENT, wavChunk.chunkSize );
        
    } while ( (fmtChunkFound == false) || (datChunkFound == false) );

    
    //
    // Bits per sample and channels
    //
    if ( wavFmtChunk.channels == 1) 
    {
        if ( wavFmtChunk.bitsPerSmp == 8) 
        {
            sign = snd_unsigned;
            smpfrmt = XS_s8_MONO;
        }
        
        else if ( wavFmtChunk.bitsPerSmp == 16) 
        {
            sign = snd_signed;
            smpfrmt = XS_s16_MONO;
        }            
        
        else
            return false;
            
    }
    
    else if ( wavFmtChunk.channels == 2) 
    {
        if ( wavFmtChunk.bitsPerSmp == 8) 
        {
            sign = snd_unsigned;
            smpfrmt = XS_s8_STEREO;
        }
        
        else if ( wavFmtChunk.bitsPerSmp == 16) 
        {
            sign = snd_signed;
            smpfrmt = XS_s16_STEREO;
        }
        
        else
            return false;
    }
    
    else
        return false;
    

    //
    // Attempt to load wave
    //
    smp = sndNewRawEx( bufftype, smpfrmt, wavFmtChunk.smpPerSec, sign, &file, 
                       uarPos( &file ), wavDatChunk.chunkSize );
    
        
    //
    // Close file
    //
    uarClose( &file );
    
    return smp;
}



// :::::::::::::
// name: sndNewRaw
// desc: Loads raw sound, the user defines how the sound should be 
//       interpreted.
//
// :::::::::::::
XS_PSAMPLE BDECL sndNewRaw ( sint16 bufftype, sint16 smpfrmt, sint32 smprate, 
                            sint16 sign, STRING filename, sint32 offs, 
                            sint32 len )
{   
    UAR file;
    XS_PSAMPLE smp;
    
    //
    // Open file
    //
    if ( uarOpen( &file, filename, F_READ ) == false )
         return false;
    
    //
    // Attempt to load sample
    //
    smp = sndNewRawEx( bufftype, smpfrmt, smprate, sign, &file, offs, len );
    
    
    //
    // Close file
    //
    uarClose( &file );
    
    return smp;
}

 

// :::::::::::::
// name: sndNewRawEx
// desc: Loads raw sound, the user defines how the sound should be 
//       interpreted. It takes a pointer to a already opened file.
// note: Preserves the file cursor.
//
// :::::::::::::
XS_PSAMPLE BDECL sndNewRawEx ( sint16 bufftype, sint16 smpfrmt, sint32 smprate, 
                               sint16 sign, UAR far *file, sint32 offs, 
                               sint32 len )
{   
    sint32 sdiv;
    uint32 filepos;
    XS_PSAMPLE smp;
    
    //
    // Preserve file position
    //
    filepos = uarPos( file );


    //
    // Everything withing range ?
    //
    if ( (smprate < 0) || (smprate > 64000) ) 
        return false;
    
    if ( (smpfrmt != XS_s8_MONO) && (smpfrmt != XS_s8_STEREO) )
        if ( (smpfrmt != XS_s16_MONO) && (smpfrmt != XS_s16_STEREO) )
            return false;

        
    //
    // Sample is to be stored in conventional memory
    //
    if ( bufftype == XS_MEM ) 
    {
        smp = memAlloc( len + sizeof( XS_SAMPLE ) );
        if ( smp == false ) 
            return false;
        
        smp->buf.ptr = ((uint8 far *)smp) + sizeof( XS_SAMPLE );
    }

    //
    // Sample is to be stored in conventional ems
    //    
    else if ( bufftype == XS_EMS )
    {
        smp = memAlloc( sizeof( XS_SAMPLE ) );
        if ( smp == false ) 
            return false;
        
        smp->buf.hnd = emsAlloc( len );
        if ( smp->buf.hnd == false ) 
        {
            memFree( smp );
            return false;
        }
    }
    
    //
    // Error in argument
    //
    else
        return false;
    
    
    //
    // Fill sample struct and load it
    //
    smp->smpID = SMPID;    
    smp->frmt = smpfrmt;
    smp->rate = smprate;
    smp->type = bufftype;

    // convert to samples
    sdiv = 1;
    switch( smpfrmt )
    {
        case XS_s8_STEREO:
        case XS_s16_MONO:
            sdiv = 2;
        break;
        case XS_s16_STEREO:
            sdiv = 4;
        break;
    }
            
    smp->len  = len / sdiv;
    
    
    //
    // Add to linked list
    //
    __snd_int_smpl_add( smp );    
    
    //
    // Load sample to memory
    //
    if ( __snd_int_load_to_mem( smp, sign, file, offs, len ) == false )
    {
        sndDel( smp );
        return false;
    }
    
            
    //
    // Restore file position and return
    //
    uarSeek( file, S_START, filepos );
            
    return smp;
}




// :::::::::::::
// name: sndDel
// desc: Unloads a sample created with sndNew/Wav/Raw/RawEx
//
// :::::::::::::
void BDECL sndDel ( XS_PSAMPLE smp )
{
    
    if ( smp->smpID == SMPID ) 
    {
        //
        // Remove from list
        //
        __snd_int_smpl_del( smp );
            
        
        //
        // If it's a convetional memory sample we just need to free
        // the sample struct memory since it was all allocated in
        // one block.
        //
        if ( smp->type == XS_MEM ) 
            memFree( smp );
            
        //
        // If it's a EMS sample we need to free the ems memory
        // and then the conventional memory used by the sample struct.
        //
        else if ( smp->type == XS_EMS )
        {
            emsFree( smp->buf.hnd );
            memFree( smp );
        }
    }
}


// :::::::::::::
// name: __snd_int_8u_to_8s
// desc: Converts 8 bit unsigned data to signed
// note: length is in bytes
//
// :::::::::::::
static void near __snd_int_8u_to_8s ( uint8 far *data, uint16 len )
{
    uint16 i;
    
    for ( i = 0; i < len; i++ )
        data[i] ^= 0x80;

}



// :::::::::::::
// name: __snd_int_16u_to_16s
// desc: Converts 16 bit unsigned data to signed
// note: length is in bytes
//
// :::::::::::::
static void near __snd_int_16u_to_16s ( uint16 far *data, uint16 len )
{
    uint16 i;
    
    for ( i = 0; i < len/2; i++ )
        data[i] ^= 0x8000;
}



// :::::::::::::
// name: __snd_int_load_to_mem
// desc: Loads a sample to memory converting to signed if needed
//
// :::::::::::::
static bool near __snd_int_load_to_mem ( XS_PSAMPLE smp, uint16 sign, 
                                         UAR far* file, sint32 offs, 
                                         sint32 len )
{
    uint16 blksize;
    sint32 bytesread;
    uint32 addr, fptr;
    
    
    //
    // Set the file cursor to the begining of the sample
    //
    if ( uarSeek( file, S_START, offs ) != offs )
        return false;
    
    
    //
    // Load sample into conventional memory
    //
    if ( smp->type == XS_MEM ) 
    {
        //
        // Load to mem
        //
        if ( uarReadH( file, smp->buf.ptr, len ) != len )
            return false;
        
        //
        // Convert to signed
        //
        if ( sign == snd_unsigned ) 
        {
            bytesread = 0;
            addr = (uint32)smp->buf.ptr;
            addr = ((addr >> 16) << 4) + (addr & 0x0000ffff);
            
            do
            {
                //
                // Calc adress and size of block
                //
                fptr = ((addr >> 4) << 16) + (addr & 15);
                blksize = ((bytesread+8192) <= len) ? 8192 : (len-bytesread);
                
                //
                // Convert to signed
                //
                if ( (smp->frmt == XS_s8_MONO) || (smp->frmt == XS_s8_STEREO) ) 
                    __snd_int_8u_to_8s( (uint8 far *)fptr, blksize );
                else
                    __snd_int_16u_to_16s( (uint16 far *)fptr, blksize );
                
                
                addr += blksize;
                bytesread += blksize;
            } while ( bytesread < len );
        }
    }
    
    
    //
    // Load sample to EMS
    //
    else if ( smp->type == XS_EMS ) 
    {
        bytesread = 0;
        
        do
        {
            //
            // Calc block size
            //
            blksize = ((bytesread+32768) <= len) ? 32768 : (len-bytesread);
            
            //
            // Map ems mem
            //
            fptr = emsMap( smp->buf.hnd, bytesread, blksize );
            if ( fptr == false ) 
                return false;
            fptr = fptr << 16;
            
            //
            // Load sound data
            //
            if ( uarRead( file, (void far*)fptr, blksize ) != blksize )
                return false;
            
            
            //
            // Convert to signed
            //
            if ( sign == snd_unsigned ) 
            {
                if ( (smp->frmt == XS_s8_MONO) || (smp->frmt == XS_s8_STEREO) ) 
                    __snd_int_8u_to_8s( (uint8 far *)fptr, blksize );
                else
                    __snd_int_16u_to_16s( (uint16 far *)fptr, blksize );
            }
            

            bytesread += blksize;
        } while ( bytesread < len );        
        
    }
    
    //
    // Unknown memory type
    //
    else
        return false;
    
    return true;
}


// :::::::::::::
// name: __snd_int_smpl_add
// desc: Add to linked list
//
// :::::::::::::
static void near __snd_int_smpl_add ( XS_PSAMPLE smp )
{
    
    //
    // Check if it's valid
    //
    if ( smp->smpID != SMPID )
        return;
    
    
    //
    // First sample
    //
    if ( xs_ctx.shead == NULL ) 
    {
        xs_ctx.shead = smp;
        smp->prev = NULL;
    }
    
    //
    // Add it to the end of the list
    //
    else
    {
        xs_ctx.stail->next = smp;
        smp->prev = xs_ctx.stail;
    }
    
    xs_ctx.stail = smp;
    smp->next = NULL;
}


// :::::::::::::
// name: __snd_int_smpl_del
// desc: Delete from linked list
//
// :::::::::::::
static void near __snd_int_smpl_del ( XS_PSAMPLE smp )
{   
    
    //
    // Check if it's valid
    //
    if ( smp->smpID != SMPID )
        return;
    
    if ( smp->prev == NULL ) 
        xs_ctx.shead = smp->next;
    else
        smp->prev->next = smp->next;
    
    if ( smp->next == NULL ) 
        xs_ctx.stail = smp->prev;
    else
        smp->next->prev = smp->prev;
}