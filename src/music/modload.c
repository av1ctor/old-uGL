/*
**
** src/modload.c - protracker module loading
**
**
*/
#include "inc/modcmn.h"
#include "inc/modmain.h"
#include "inc/modload.h"
#include "inc/modplay.h"
#include "inc/modmem.h"
#include "inc/modtbl.h"


void near __mod_int_add ( lp_UGMHeader mod );
void near __mod_int_del ( lp_UGMHeader mod );
bool near __mod_int_check ( lp_UGMHeader mod );





// ::::::::::::::::::
// name: modNew
// desc: Loads a protracker module
//       Man, this is the messiest code i've ever done
//
// ::::::::::::::::::
bool UGLAPI modNew ( lp_UGMHeader mod, sint16 memtype, STRING filename )
{
    UAR    file;
    uint16 i, j;
    uint16 k, l;
    uint16 n, o;
    sint16 period;
    uint32 patsize;
    uint32 fileOffset;
    
    char far *    sign;
    lp_UGMPattern dstpat;
    uint8 far *   srcpat;
    modHeader     modHead;
    
    //
    // Has the module alredy been loaded ?
    //
    if ( mod->ID == UGMID ) 
        return false;
    
    
    //
    // Attempt to open file
    //
    if ( uarOpen( &file, filename, F_READ ) == false )
        return false;

    //
    // Load the header
    //
    if ( uarRead( &file, &modHead, sizeof( modHeader ) ) != sizeof( modHeader ) ) 
    {
        uarClose( &file );
        return false;            
    }
    
    //
    // Check the header 
    //
    mod->channels = 0;
    
    //
    // M.K. and M!K!
    //
    if ( modHead.sign[0] == 'M' ) 
        if ( (modHead.sign[1] == '.') || (modHead.sign[1] == '!') ) 
            if ( modHead.sign[2] == 'K' ) 
                if ( (modHead.sign[3] == '.') || modHead.sign[3] == '!' )
                    mod->channels = 4;
                
    //
    // FLT4
    //
    if ( modHead.sign[0] == 'F' ) 
        if ( modHead.sign[1] == 'L' ) 
            if ( modHead.sign[2] == 'T' ) 
                 mod->channels = modHead.sign[3] - '0';
            
    //
    // CD81
    //
    if ( modHead.sign[0] == 'C' ) 
        if ( modHead.sign[1] == 'D' ) 
            if ( modHead.sign[2] == '8' ) 
                if ( modHead.sign[3] == '1' ) 
                    mod->channels = 4;
                
    //
    // OKTA
    //
    if ( modHead.sign[0] == 'O' ) 
        if ( modHead.sign[1] == 'K' ) 
            if ( modHead.sign[2] == 'T' ) 
                if ( modHead.sign[3] == 'A' ) 
                    mod->channels = 4;
            
                
    //
    // xxCN and xCHN
    //
    if ( modHead.sign[3] == 'N' ) 
    {
        if ( modHead.sign[2] == 'H' )
        {
            if ( modHead.sign[1] == 'C' )
                if ( (modHead.sign[0] >= '0') && (modHead.sign[0] <= '9') )
                    mod->channels = modHead.sign[0] - '0';
        }
        
        else
        {
            if ( modHead.sign[2] == 'C' )
                if ( ((modHead.sign[0] >= '0') && (modHead.sign[0] <= '9')) && 
                     ((modHead.sign[1] >= '0') && (modHead.sign[1] <= '9')) )
                {
                    mod->channels  = modHead.sign[1] - '0';
                    mod->channels += ((uint16)(modHead.sign[0] - '0')) * 10;
                }
        }
    }
    
    //
    // xxCH
    //
    if ( modHead.sign[3] == 'H' ) 
    {
        if ( modHead.sign[2] == 'C' )
            if ( ((modHead.sign[0] >= '0') && (modHead.sign[0] <= '9')) && 
                 ((modHead.sign[1] >= '0') && (modHead.sign[1] <= '9')) )
            {
                
                mod->channels  = modHead.sign[1] - '0';
                mod->channels += ((uint16)(modHead.sign[0] - '0')) * 10;
            }
    }    
        
    
    if ( (mod->channels == 0) || (mod->channels > 64) )
    {
        uarClose( &file );
        return false;            
    }
    
    
    //
    // Convert the sample info headers
    //
    for ( i = 0; i < 31; i++ ) 
    {
        mod->instruments[i].volume = modHead.instruments[i].volume;
        mod->instruments[i].finetune = modHead.instruments[i].finetune;
        mod->instruments[i].slength = MU16_to_IU16( modHead.instruments[i].slength ) * 2L;
        mod->instruments[i].loopstr = MU16_to_IU16( modHead.instruments[i].loopStart ) * 2L;
        mod->instruments[i].loopend = MU16_to_IU16( modHead.instruments[i].loopLength ) * 2L;
        
        mod->instruments[i].loopend += mod->instruments[i].loopstr;
    }
    
    
    //
    // Copy the song order
    //
    mod->patternData.patterns = 0;
    mod->songLength = modHead.songLength;
    
    for ( i = 0; i < 128; i++ ) 
    {
        mod->songOrder[i] = modHead.songData[i];
        
        if ( mod->songOrder[i] > mod->patternData.patterns ) 
            mod->patternData.patterns = mod->songOrder[i];
    }
    mod->patternData.patterns++;
    
    
    //
    // Allocate memory for the patterns
    //
    patsize = (uint32)mod->channels*(uint32)sizeof( UGMPattern ) * 
              64L * (uint32)mod->patternData.patterns;
    
    if ( memtype == mod_mem ) 
    {
        mod->patternData.type = mod_mem;
        mod->patternData.addr = (uint32)memAlloc( patsize );
        if ( mod->patternData.addr == false ) 
        {
            uarClose( &file );
            return false;            
        }
    }
    else
    {
        mod->patternData.type = mod_ems;
        mod->patternData.hndl = emsAlloc( patsize );
        if ( mod->patternData.hndl == false ) 
        {
            uarClose( &file );
            return false;            
        }
    }
    
    //
    // Add to linked list
    //
    mod->next = false;
    mod->prev = false;
    __mod_int_add( mod );

    
    //
    // Allocate memory for temporary pattern storage
    //
    srcpat = (uint8 far *)memAlloc( mod->channels*4 );
    if ( srcpat == false ) 
    {
        modDel( mod );
        uarClose( &file );
        return false;            
    }    
    
    
    //
    // Get pattern data
    //
    for  ( i = 0; i < mod->patternData.patterns; i++ )
		for ( j = 0; j < 64; j++ )
		{
			//
			// Read a row
			// 
			if ( uarRead( &file , srcpat, mod->channels*4 ) != mod->channels*4 )
            {
                memFree( srcpat );
                modDel( mod );
                uarClose( &file );
                return false;
            }

            
			//
			// Get pointer to row and convert
			//
            dstpat = __mod_memGetRowDirect( i, j, mod );
            if ( dstpat == false ) 
            {
                memFree( srcpat );
                modDel( mod );
                uarClose( &file );
                return false;
            }
            
			for ( k = 0; k < mod->channels; k++ )
			{
				dstpat[k].inst = (srcpat[k*4+0] & 0xf0) + (srcpat[k*4+2] >> 4);
				dstpat[k].note = ((srcpat[k*4+0] & 0x0f) << 8) + srcpat[k*4+1];
				dstpat[k].effect = srcpat[k*4+2] & 0x0f;
				dstpat[k].effectpara = srcpat[k*4+3];  
                 
                if ( (dstpat[k].effect == 0) && (dstpat[k].effectpara == 0) ) 
                    dstpat[k].effect = 0xff;
                
				
				//
				// Find a note for the period
				//
                period = dstpat[k].note;
                dstpat[k].note = 0;
                
                for ( l = 0; l < 9*12; l++ )
                {
                    n = (l+24) % 12;
                    o = (l+24) / 12;
                    
					if ( period >= (S3MPeriodTable[n]>>o) )
                    {
							dstpat[k].note = l+1;
                            break;
                    }
                }
			}
		}    
    
    
    //
    // Close file and load samples
    //
    fileOffset = uarPos( &file );
    uarClose( &file );
    
    for ( i = 0; i < 31; i++ ) 
    {
        if ( mod->instruments[i].slength > 0 ) 
        {   
            mod->instruments[i].hsample = sndNewRaw( memtype, snd_s8_mono, 8363, snd_signed, filename, 
                                                     fileOffset, mod->instruments[i].slength );
            
            if ( mod->instruments[i].hsample == false ) 
            {
                memFree( srcpat );
                modDel( mod );
                return false;
            }
            
            fileOffset += mod->instruments[i].slength;
        }
    }
    
    
    //
    // Done, everything went ok
    //
    mod->ID = UGMID;
    mod->playmode = mod_onetime;
    memFree( srcpat );
    return true;
}




// ::::::::::::::::::
// name: modDel
// desc: Delete a module from memory
//
// ::::::::::::::::::
void UGLAPI modDel ( lp_UGMHeader mod )
{
    //
    // Check if it's a valid module
    //
    if ( mod->ID == UGMID ) 
    {
        if ( modctx.srcmod == mod ) 
            modStop( );
        
        //
        // Tag as invalid module
        //
        mod->ID = false;
    
        //
        // Free memory used by module
        //
        if ( mod->patternData.type == mod_mem ) 
            memFree( (void far *)mod->patternData.addr );
        
        else if ( mod->patternData.type == mod_ems ) 
            emsFree( mod->patternData.hndl );
        
        //
        // Remove from linked list
        //
        __mod_int_del( mod );
    }
}






// :::::::::::::
// name: __mod_int_add
// desc: Add to linked list
//
// :::::::::::::
static void near __mod_int_add ( lp_UGMHeader mod )
{
    //
    // First mod
    //
    if ( modctx.head == false ) 
    {
        modctx.head = mod;
        mod->prev = false;
    }
    
    //
    // Add it to the end of the list
    //
    else
    {
        modctx.tail->next = mod;
        mod->prev = modctx.tail;
    }
    
    modctx.tail = mod;
    mod->next = false;
}


// :::::::::::::
// name: __snd_int_voc_del
// desc: Delete from linked list
//
// :::::::::::::
static void near __mod_int_del ( lp_UGMHeader mod )
{   
    
    if ( mod->prev == false ) 
        modctx.head = mod->next;
    else
        mod->prev->next = mod->next;

    if ( mod->next == false ) 
        modctx.tail = mod->prev;
    else
        mod->next->prev = mod->prev;
}
