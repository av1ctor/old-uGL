//
// Sound blaster and compatible low level driver
// Compile with Watcom C++ 11.0c
//
// TODO: Nothing, unless bugs are found.
//
#include "inc\sbdrv.h"
#include "inc\sbdrvint.h"
#include "dos.h"

bool    singlecycle;
bool    testint, highspd;
uint8   inpfilt, outfilt;
uint8   irqvect, sbpoutf;
uint8   picmska, picmskb;
uint8   newmska, newmskb;
bool    blksizeset = false;

uint32   oldint;
SBDRIVER sbdrv = { 0 };




/* ============================================
 *  driver interface
 *
 * ============================================ */

 
// :::::::::::::::::
//  Init the sound blaster
//
// :::::::::::::::::
bool BDECL sbdrv_init ( uint16 base, uint16 irq, uint16 ldma, uint16 hdma )
{
    uint16 port, i;
    
    //
    // Are we required to do autodetection? (dsp 4+ only)
    //
    if ( base == 0 ) 
    {
        //
        // Detect port
        //
        for ( port = 0x200; port <= 0x280; port += 0x10 )
        {
             sbdrv.init = true;
             sbdrv.base = port;
             
             if ( sbdrv_dsp_reset() )
                 break;
             
             sbdrv.init = false;
             sbdrv.base = false;
        }
        
        if ( !sbdrv.init )
            return false;
        
        //
        // Detect IRQ
        //
        outp( sbdrv.base+0x04, 0x80 );
        switch ( inp( sbdrv.base+0x05 ) & 0x0f )
        {
            case 0x01: sbdrv.irq =  2; break;
            case 0x02: sbdrv.irq =  5; break;
            case 0x04: sbdrv.irq =  7; break;
            case 0x08: sbdrv.irq = 10; break;
            default: sbdrv.irq = false; break;
        }
        
        //
        // Detect 8 bit dma channel
        //
        outp( sbdrv.base+0x04, 0x81 );
        switch ( inp( sbdrv.base+0x05 ) & 0x0b )
        {
            case 0x01: sbdrv.ldma = 0; break;
            case 0x02: sbdrv.ldma = 1; break;
            case 0x0b: sbdrv.ldma = 1; break;
            case 0x08: sbdrv.ldma = 3; break;
            default: sbdrv.ldma = false; break;
        }
        
        //
        // Detect 16 bit dma channel
        //
        outp( sbdrv.base+0x04, 0x81 );
        switch ( inp( sbdrv.base+0x05 ) >> 5 )
        {
            case 0x01: sbdrv.hdma = 5; break;
            case 0x02: sbdrv.hdma = 6; break;
            case 0x04: sbdrv.hdma = 7; break;
            default: sbdrv.hdma = false; break;
        } 
        
        //
        // Were we able to detect all settings?
        //
        if ( (sbdrv.irq == 0) || (sbdrv.ldma == 0) )
        {
            sbdrv.init = false;
            return false;
        }
        
        if ( (sbdrv.hdma == 0) && (sbdrv.dspversion >= 4) )
        {
            sbdrv.init = false;
            return false;
        }
    }
    
    //
    // Caller has supplied the settings
    //
    else
    {  
        sbdrv.init = true;
        sbdrv.base = base;
        sbdrv.irq  = irq;
        sbdrv.ldma = ldma;
        sbdrv.hdma = hdma;
        sbdrv_dsp_reset();
    }
    
    //
    // Only sb 1.0+
    //
    if ( (sbdrv.dspversion < dspver1) || (sbdrv.dspversion >= dspver5) )
        return false;
    
    //
    // Allocated DMA memory for max buffer length supported
    //
    if ( (sbdrv.blkbase = sbdrv_dma_allocmem( SB_BUFFLEN_MAX )) == NULL )
        return false;


	//
	// Install ISR and enable IRQ
	//
    if ( sbdrv.irq > 7) 
        irqvect = sbdrv.irq - 8 + 0x70;
    else
        irqvect = sbdrv.irq + 8;
    
    newmska = (1 << sbdrv.irq);
    newmskb = (1 << sbdrv.irq)>>8;
    newmska = ~newmska;
    newmskb = ~newmskb;
    
    picmska = inp( 0x21 );
    picmskb = inp( 0xa1 );
    outp( 0x21, picmska & newmska );
    outp( 0xa1, picmskb & newmskb );   
    
    _asm cli
    oldint = _getvect( irqvect );
    _setvect( irqvect, sbdrv_isr );
    _asm sti
    
    picmska = inp( 0x21 );
    picmskb = inp( 0xa1 );        
    outp( 0x21, picmska & newmska );
    outp( 0xa1, picmskb & newmskb );
    
    sbdrv.init = true;
    return true;
}



// :::::::::::::::::
//  Deinit the sound blaster
//
// :::::::::::::::::
void BDECL sbdrv_end ( void )
{
    if ( sbdrv.init ) 
    {
        sbdrv_playback_stop();
	
		//
		// Remove ISR
		//
        picmska = inp( 0x21 );
        picmskb = inp( 0xa1 );
        newmska = (1 << sbdrv.irq);
        newmskb = (1 << sbdrv.irq)>>8;        
        outp( 0x21, picmska | newmska );
        outp( 0xa1, picmskb | newmskb );
        
        _asm cli
        _setvect( irqvect, (void far*)oldint );
        _asm sti
        
         //
         // Kill DMA buffer
         //
         if ( sbdrv.blkbase != NULL )
         {
             memFree( sbdrv.blkbase );
             sbdrv.blkbase = NULL;
         }
            
        sbdrv.init = false;
    }
}



// :::::::::::::::::
//  Get the capabilities of the sound blaster
//
// :::::::::::::::::
void BDECL sbdrv_getcaps ( SBCAPS far *caps )
{
    uint16 strucsize = sizeof( SBCAPS );
    
    __asm {
		les		di, caps
		xor		ax, ax
		mov		cx, strucsize
		rep		stosb
    }
    
    
    //
    // Sound blaster init ?
    //
    if ( sbdrv.init ) 
    {
        //
        // SB 1.0/SB 2.0
        //
        if ( (sbdrv.dspversion >= dspver1) || (sbdrv.dspversion < dspver2))
        {
            // 
            // 8 bit mono
            //
            caps->mono.bits8.sign = sign_false;
            caps->mono.bits8.minrate = 4000;
            caps->mono.bits8.maxrate = 23000;
            caps->mono.bits8.available = true;
            
            caps->dspver  = sbdrv.dspversion;
        }
                
        
        //
        // SB 2.x
        //
        else if ( (sbdrv.dspversion > dspver2) && (sbdrv.dspversion < dspver3) )
        {
            // 
            // 8 bit mono
            //
            caps->mono.bits8.sign = sign_false;
            caps->mono.bits8.minrate = 4000;
            caps->mono.bits8.maxrate = 44100;
            caps->mono.bits8.available = true;
            
            caps->dspver  = sbdrv.dspversion;
        }
                
        
        //
        // SB Pro
        //
        else if ( (sbdrv.dspversion >= dspver3) && (sbdrv.dspversion < dspver4) )
        {
            // 
            // 8 bit mono
            //
            caps->mono.bits8.sign = sign_false;
            caps->mono.bits8.minrate = 4000;
            caps->mono.bits8.maxrate = 44100;
            caps->mono.bits8.available = true;
            
            // 
            // 8 bit stereo
            //
            caps->stereo.bits8.sign = sign_false;
            caps->stereo.bits8.minrate = 11025;
            caps->stereo.bits8.maxrate = 22050;
            caps->stereo.bits8.available = true;
            
            caps->dspver  = sbdrv.dspversion;
        }
        
        
        //
        // SoundBlaster 16/AWE32
        //
        else if ( (sbdrv.dspversion >= dspver4) && (sbdrv.dspversion < dspver5) )
        {
            // 
            // 8 bit mono
            //
            caps->mono.bits8.sign = sign_choice;
            caps->mono.bits8.minrate = 5000;
            caps->mono.bits8.maxrate = 44100;
            caps->mono.bits8.available = true;
            
            // 
            // 16 bit mono
            //
            caps->mono.bits16.sign = sign_choice;
            caps->mono.bits16.minrate = 5000;
            caps->mono.bits16.maxrate = 44100;
            caps->mono.bits16.available = true;
            
            // 
            // 8 bit stereo
            //
            caps->stereo.bits8.sign = sign_choice;
            caps->stereo.bits8.minrate = 5000;
            caps->stereo.bits8.maxrate = 44100;
            caps->stereo.bits8.available = true;
            
            // 
            // 16 bit stereo
            //
            caps->stereo.bits16.sign = sign_choice;
            caps->stereo.bits16.minrate = 5000;
            caps->stereo.bits16.maxrate = 44100;
            caps->stereo.bits16.available = true;

            caps->dspver  = sbdrv.dspversion;
        }
    }
}



// :::::::::::::::::
//   Sets the callback routine
//
// :::::::::::::::::
void BDECL sbdrv_setcallbk ( void (cdecl far *callback)(uint8 far*, uint16) )
{
    sbdrv.blkcallbk = callback;
}


// :::::::::::::::::
//  Sets the size of the DMA buffer
//
// :::::::::::::::::
void BDECL sbdrv_setdmasize ( uint16 *size )
{
    (*size) *= 2;

    if( (*size) > SB_BUFFLEN_MAX )
        (*size) = SB_BUFFLEN_MAX;
    else if( (*size) < SB_BUFFLEN_MIN )
        (*size) = SB_BUFFLEN_MIN;
    
    (*size) = ((*size) + 3) & ~3;
    
    sbdrv.blksizewhle = (*size);
    sbdrv.blksizehalf = (*size) / 2;

    (*size) >>= 1;                // note: returns half buffer
}


// :::::::::::::::::
//   Starts playback
//
// :::::::::::::::::
bool BDECL sbdrv_playback_start ( uint16 rate, uint16 bits, uint16 chan, bool sign, uint16 *blocksize )
{
    //
    // Store settings
    //
	sbdrv.playbits = bits;
	sbdrv.playchan = chan;
	sbdrv.playrate = rate;
    
    //
    // Allocate DMA buffer and clear it
    //
    sbdrv_setdmasize( blocksize );
    
	//
	// Call the user to fill the block
	//
	sbdrv.blkside = 0;
	sbdrv.blkcallbk( sbdrv.blkbase, sbdrv.blksizewhle );
    
    //
    // DSP supports auto-init ?
    //
    if ( (sbdrv.dspversion >= dspver1) && (sbdrv.dspversion < dspver2) )
        singlecycle = true;
    else
        singlecycle = false;
    
    //
    // SB Pro pre setup
    //
    sbdrv_dsp_sbprostereo();
    
	//
	// Setup dma for auto-init transfer
	//
    
    if ( singlecycle ) 
        sbdrv_dma_singlecycle( bits, sbdrv.blkbase, sbdrv.blksizehalf );
    else
        sbdrv_dma_autoinit( bits, sbdrv.blkbase, sbdrv.blksizewhle );

	
    //
    // Turn DAC on
    // 
    if ( sbdrv.dspversion < dspver4 )
        sbdrv_dsp_dacspeakeron();
    
    //
    // Set mixer volumes
    //
    // sbdrv_dsp_setmixer();
    
	//
	// Setup dsp 
	//
    if ( singlecycle ) 
    {
    	if ( !sbdrv_dsp_setsinglecycle( rate, bits, chan, sbdrv.blksizehalf, sign ) )
    		return false;        
    }
    else
    {
    	if ( !sbdrv_dsp_setautoinit( rate, bits, chan, sbdrv.blksizehalf, sign ) )
    		return false;        
    }


	
    return true;
}



// :::::::::::::::::
//   Stops playback
//
// :::::::::::::::::
void BDECL sbdrv_playback_stop ( void )
{
    uint8 tmp;
    
    if ( sbdrv.init ) 
    {
        //
        // SB 1.0
        //
        if ( (sbdrv.dspversion >= dspver1) && (sbdrv.dspversion < dspver2) ) 
            sbdrv_dsp_dacspeakeroff();

        //
        // SB 2.0 - SB Pro
        //        
        else if ( (sbdrv.dspversion >= dspver2) && (sbdrv.dspversion < dspver4) )
        {
            if ( highspd == 0 ) 
            {
                sbdrv_dsp_write( dsp_exitauto8 );
                sbdrv_dsp_dacspeakeroff();
            }
            
            else
            {
                if ( sbdrv.playchan == 1 ) 
                {
                    sbdrv_dsp_reset();
                    sbdrv_dsp_dacspeakeroff();
                }
                
                else
                {
                    sbdrv_dsp_reset();
                    
                    outp( sbdrv.base+0x0004, 0x0e    );
                    outp( sbdrv.base+0x0005, outfilt );
                    
                    outp( sbdrv.base+0x0004, 0x0e );
                    tmp = inp( sbdrv.base+0x0005  );
                    outp( sbdrv.base+0x0005, tmp &0xfd  );
                    
                    sbdrv_dsp_dacspeakeroff();
                }
            }
        }
        
        //
        // SoundBlaster 16/AWE32
        //
        else if ( (sbdrv.dspversion >= dspver4) && (sbdrv.dspversion < dspver5) )
            if ( sbdrv.playbits == 8)
                sbdrv_dsp_write( dsp_exitauto8  );
            else
                sbdrv_dsp_write( dsp_exitauto16 );
    }
}




/* ============================================
 *  driver internals - sb stuff
 *
 * ============================================ */
void interrupt far sbdrv_isr ( void )
{
    static uint8 far *blkbase;
    
    if ( testint == false ) 
    {
        //
        // Single cycle transfer
        //
        if ( singlecycle ) 
        {
            if ( sbdrv.blkside == 1 ) 
                blkbase = sbdrv.blkbase;
            else if ( sbdrv.blkside == 0 )
                blkbase = sbdrv.blkbase+sbdrv.blksizehalf;
                                
            //
            // Reprogram DMA and DSP
            //
            sbdrv_dma_singlecycle( sbdrv.playbits, blkbase, sbdrv.blksizehalf );
            
            sbdrv_dsp_setsinglecycle( sbdrv.playrate, sbdrv.playbits, 
                                      sbdrv.playchan, sbdrv.blksizehalf, false );
        }            
        
        
    	//
    	// Call the user to fill the other half of the block
    	//
    	if ( sbdrv.blkside == 0 )
    		sbdrv.blkcallbk( sbdrv.blkbase, sbdrv.blksizehalf );
    	else if ( sbdrv.blkside == 1 )
    		sbdrv.blkcallbk( sbdrv.blkbase+sbdrv.blksizehalf, sbdrv.blksizehalf );
        sbdrv.blkside ^= 1;
    }
    

	
	//
	// Acknowledge interrupt
	//
    if ( sbdrv.playbits == 8 ) 
        inp( sbdrv.base+dsp_intack8  );
    else
        inp( sbdrv.base+dsp_intack16 );
    

    if ( sbdrv.irq > 7 ) 
        outp( 0xA0, 0x20 );
    outp( 0x20, 0x20 );

    //asm sti
    
}






/* ============================================
 *  driver internals - dsp
 *
 * ============================================ */


// :::::::::::::::::
// Reset the sound blaster and get dsp version
//
// :::::::::::::::::
static bool sbdrv_dsp_reset ( void )
{
    uint16 i;
    
    if ( sbdrv.init ) 
    {
        outp( sbdrv.base+dsp_reset, 0x01 );
        for ( i = 0; i < 6; i++)
            inp( sbdrv.base+dsp_write );
        outp( sbdrv.base+dsp_reset, 0x00 );
        
        if ( !sbdrv_dsp_datavail() )
            return false;
        
        
        for ( i = 0; i < 1000; i++ ) 
            if ( inp( sbdrv.base+dsp_read ) == dsp_ready )
                return sbdrv_dsp_getver();
    }
    
    return false;
}



// :::::::::::::::::
//  Get sb dsp version
//
// :::::::::::::::::
static bool sbdrv_dsp_getver ( void )
{
    uint8 vMaj, vMin;
    
    if ( sbdrv.init ) 
    {
        //
        // Request version
        // 
        if ( !sbdrv_dsp_write( dsp_version ) )
            return false;
    
        //
        // Fetch
        //     
        if ( !sbdrv_dsp_datavail() || 
             !sbdrv_dsp_read( &vMaj ) ||
             !sbdrv_dsp_read( &vMin ) )
            return false;
            
        sbdrv.dspversion = (((uint16)vMaj)<<8) + (uint16)vMin;
        return true;
    }
    
    return false;
}



// :::::::::::::::::
//  Check if there's data waiting
//
// :::::::::::::::::
static bool sbdrv_dsp_datavail ( void )
{
    uint16 i;
    
    if ( sbdrv.init ) 
        for ( i = 0; i < 1000; i++ ) 
            if ( (inp( sbdrv.base+dsp_status ) & 0x80) != false )
                return true;
    
    return false;
}



// :::::::::::::::::
//  Check if the sb is ready to recive data
//
// :::::::::::::::::
static bool sbdrv_dsp_wait ( void )
{
    uint16 i;
    
    if ( sbdrv.init ) 
        for ( i = 0; i < 1000; i++ ) 
            if ( (inp( sbdrv.base+dsp_write ) & 0x80) == 0 )
                return true;
    
    return false;
}



// :::::::::::::::::
//  Get a byte from the sb
//
// :::::::::::::::::
static bool sbdrv_dsp_read ( uint8 *val )
{
    uint16 i;
    
    if ( sbdrv.init )
    {
        if ( !sbdrv_dsp_datavail() )
            return false;
        
        val[0] = inp( sbdrv.base+dsp_read );
    }

    return true;
}



// :::::::::::::::::
//  Send a byte to the sb 
//
// :::::::::::::::::
static bool sbdrv_dsp_write ( uint8 val )
{
    uint16 i;
    
    if ( sbdrv.init )
    {   
        if ( !sbdrv_dsp_wait() )
            return false;
        
        outp( sbdrv.base+dsp_write, val );
    }

    return true;
}



// :::::::::::::::::
//  Tells the dsp what freq data will be at
//
// :::::::::::::::::
static bool sbdrv_dsp_sendfreq( uint16 rate, uint16 bits, uint16 chan )
{
    uint8   timeconst;
    
	if ( sbdrv.init )
	{
        //
        // SB 1.0/SB 2.0/SB Pro
        //
        if ( sbdrv.dspversion < dspver4 ) 
        {
            
            //timeconst = 65536L - (256000000L / ((long)(rate*chan)));
            //timeconst = ((timeconst & 0x0000ff00)>>8L);

            __asm {
				mov		ax, rate
				mul		chan
				movzx	ebx, ax
				mov		eax, 0x0f424000
				cdq
				div		ebx
				mov		edx, 0x00010000
				sub		edx, eax
				mov		timeconst, dh
            }

            if ( !sbdrv_dsp_write( dsp_timeconst )  ||
                 !sbdrv_dsp_write( timeconst     )  )
                return false;
        }
        
        //
        // SB 16/SB AWE
        //
        else if ( sbdrv.dspversion >= dspver4 ) 
        {

            if ( !sbdrv_dsp_write( dsp_samplerate ) ||
                 !sbdrv_dsp_write( (rate & 0xff00)>>8 ) ||
                 !sbdrv_dsp_write( (rate & 0x00ff)    ) )
                 return false;
        }
        
		return true;
	}
	
	return false;
}



// :::::::::::::::::
//  Tells the dsp how many bytes the buffer is
//
// :::::::::::::::::
static bool sbdrv_dsp_sendlength( uint16 bytes, uint16 bits )
{
	if ( sbdrv.init )
	{
        if ( bits == 8 )
            bytes -= 1;
        else 
            bytes = (bytes/2)-1;

		if ( !sbdrv_dsp_write( (bytes & 0x00ff) ) ||
			 !sbdrv_dsp_write( (bytes >> 8    ) ) )
			return false;
		
		return true;
	}
	
	return false;
}


// :::::::::::::::::
//  Setup sb pro for stereo output
//  
// :::::::::::::::::
static void sbdrv_dsp_sbprostereo ( void )
{
    uint8 tmp;
    
    //
    // Setup is only needed for sb pro, 8 bits, stereo
    //
    if ( (sbdrv.dspversion >= dspver3) && (sbdrv.dspversion < dspver4) ) 
        if ( (sbdrv.playbits == 8) && (sbdrv.playchan == 2) )
            if ( (sbdrv.playrate >= 11025) && (sbdrv.playrate <= 22050) )
            {
                testint = true;
                
                //  
                //  Set stereo mode
                // 
                outp( sbdrv.base+0x0004, 0x0e );
                tmp = inp( sbdrv.base+0x0005  );
                outp( sbdrv.base+0x0005, tmp | 0x02  );
                
                //
                // Program DMA controller for one byte single-cycle 
                //
                sbdrv_dma_singlecycle( sbdrv.playbits, sbdrv.blkbase, 1 );
                
                //
                // Program the dsp to output a single silent byte
                //
                sbdrv.blkbase[0] = 0x80;
                sbdrv_dsp_write( 0x14 );
                sbdrv_dsp_write( 0x00 );
                sbdrv_dsp_write( 0x00 );
                sbdrv.blkbase[0] = 0x00;
                
                testint = false;
            }
}



// :::::::::::::::::
//  Tells the dsp what sort of data to expect
//
// :::::::::::::::::
static bool sbdrv_dsp_setsinglecycle ( uint16 freq, uint16 bits, uint16 chans, 
                                       uint16 bytes, bool sign )
{
    if ( sbdrv.init )
    {
        //
        // Let the ISR know that it's not a test
        //
        testint = false;
        
        //
        // SB 1.0
        //
        if ( (sbdrv.dspversion >= dspver1) && (sbdrv.dspversion < dspver2) ) 
        {
            //
            // DSP only supports unsigned data
            //
            if ( sign )
                return false;
            
            if ( bits == 8 ) 
            {
                //
                // 8 bit, mono
                //
                if ( chans == 1 ) 
                {
                    //
                    // Auto init, 8 bit mono
                    //
                    if ( (freq >= 4000) && (freq <= 23000) ) 
                    {
                        highspd = false;
                        sbdrv_dsp_sendfreq( freq, bits, chans );
                        sbdrv_dsp_write( 0x14 );
                        sbdrv_dsp_sendlength( bytes, bits );
                    }    
                    
                    //
                    // Not supported by dsp
                    //
                    else
                        return false;
                }
                
                //
                // Not supported by dsp
                //
                else
                    return false;
            }
            
            //
            // Not supported by dsp
            //
            else
                return false;
        }
        
        //
        // Not supported by dsp
        //
        else
            return false;
    }
    
    //
    // SB not init
    //
    else
        return false;    
    
    return true;
}


// :::::::::::::::::
//  Tells the dsp what sort of data to expect
//
// :::::::::::::::::
static bool sbdrv_dsp_setautoinit ( uint16 freq, uint16 bits, uint16 chans, 
                                    uint16 bytes, bool sign )
{
    uint16 i;
    uint8  chan, mask, cmnd;

            
    if ( sbdrv.init )
    {
        //
        // Let the ISR know that it's not a test
        //
        testint = false;
        
        
        //
        // SB 2.0 - SBPro
        //
        if ( (sbdrv.dspversion >= dspver2) && (sbdrv.dspversion < dspver4) ) 
        {
            //
            // DSP only supports unsigned data
            //
            if ( sign )
                return false;
            
            
            if ( bits == 8 ) 
            {
                //
                // 8 bit, mono
                //
                if ( chans == 1 ) 
                {
                    //
                    // Auto init, 8 bit mono
                    //
                    if ( (freq >= 4000) && (freq <= 23000) && 
                         (sbdrv.dspversion >= dspver2) ) 
                    {
                        highspd = false;
                        sbdrv_dsp_sendfreq( freq, bits, chans );
                        sbdrv_dsp_write( 0x48 );
                        sbdrv_dsp_sendlength( bytes, bits );
                        sbdrv_dsp_write( 0x1c );
                    }
                    
                    //
                    // Auto init, 8 bit mono (high speed)
                    //
                    else if ( (freq > 23000) && (freq <= 44100) && 
                              (sbdrv.dspversion > dspver2) ) 
                    {
                        highspd = true;
                        sbdrv_dsp_sendfreq( freq, bits, chans );
                        sbdrv_dsp_write( 0x48 );
                        sbdrv_dsp_sendlength( bytes, bits );
                        sbdrv_dsp_write( 0x90 );
                    }
                    
                    //
                    // Unknown mode
                    //
                    else
                        return false;
                }
                
                //
                // 8 bit, stereo
                //            
                else if ( chans == 2 ) 
                {
                    //
                    // Auto init, 8 bit stereo (high speed)
                    //
                    if ( (freq >= 11025) && (freq <= 22050) && 
                         (sbdrv.dspversion >= dspver3) ) 
                    {
                        highspd = true;
                        sbdrv_dsp_sendfreq( freq, bits, chans );
                        
                        outp( sbdrv.base+0x0004, 0x0e );
                        outfilt = inp( sbdrv.base+0x0005  );
                        outp( sbdrv.base+0x0005, outfilt | 0x20  );
                        
                        sbdrv_dsp_write( 0x48 );
                        sbdrv_dsp_sendlength( bytes, bits );
                        sbdrv_dsp_write( 0x90 );
                    }
                    
                    //
                    // Unknown mode
                    //
                    else
                        return false;
                }
                
                //
                // Unknown mode
                //
                else 
                    return false;
            }
            
            //
            // 16 bit not supported
            //
            else 
                return false;
            
            
        }
        
        
        //
        // SB 16+
        //
        else if ( (sbdrv.dspversion >= dspver4) && (sbdrv.dspversion <= dspver5) ) 
        {   
            
            //
            // Normal dsp range
            //
    		if ( (freq >= 5000) && (freq <= 44100) && ((bits == 8) || (bits == 16)) && 
                 ((chans == 1) || (chans == 2)) )
    		{
                chan = (chans>>1) << 5;
                mask = (sign & 1) << 4;
                cmnd = (bits == 8) ? 0xc6 : 0xb6;
                
                if( !sbdrv_dsp_sendfreq( freq, bits, chans ) ||
                    !sbdrv_dsp_write( cmnd ) ||
                    !sbdrv_dsp_write( chan | mask ) ||
                    !sbdrv_dsp_sendlength( bytes, bits ) )
                    return false;
            }
            
            //
            // Not supported by dsp 4.xx
            //
            else
                return false;
        }
        
		//
		// Unknow DSP
		// 
		else
            return false;
    }
    else
        return false;
                
    return true;
}


// :::::::::::::::::
//  Tells the dsp to turn the speaker off
//
// :::::::::::::::::
static void sbdrv_dsp_dacspeakeroff ( void )
{
    sbdrv_dsp_write( dsp_speakeroff );
}


// :::::::::::::::::
//  Tells the dsp to trun the speaker on
//
// :::::::::::::::::
static void sbdrv_dsp_dacspeakeron ( void )
{
    sbdrv_dsp_dacspeakeroff();
    sbdrv_dsp_write( dsp_speakeron );
}


// :::::::::::::::::
//  Set mixer volumes
//
// :::::::::::::::::
static void sbdrv_dsp_setmixer ( void )
{
    outp( sbdrv.base+dsp_mixaddr, dsp_mixmicvol );
    outp( sbdrv.base+dsp_mixaddr, 0x00          );
    
    outp( sbdrv.base+dsp_mixaddr, dsp_mixvocvol );
    outp( sbdrv.base+dsp_mixaddr, 0xff          );    
}



/* ============================================
 *  driver internals - dma
 *
 * ============================================ */

uint16 dmapageport, dmamaskreg, dmaclearreg, dmamodereg, controlbyte;
uint16 modebyte, controlbytemask, dmaaddrport, dmacountport, dmachannel;



// :::::::::::::::::
//  Set dma channel
//
// :::::::::::::::::
static bool sbdrv_dma_setchan ( uint16 chan )
{
    //
    // Reset status
    //
    modebyte        = false;
    dmamaskreg      = false;
    dmamodereg      = false;    
    dmaclearreg     = false;
    dmapageport     = false;
    dmaaddrport     = false;
    dmacountport    = false;
    controlbyte     = false;
    controlbytemask = false;
    
    //
    // Set channel
    //
    if ( chan > 7 )
        return false;
    dmachannel = chan;
    
    //
    // Set ports
    //
    switch ( dmachannel )
    {
		// 8-bit dma
		case 0: dmaaddrport = 0x00; dmacountport = 0x01; dmapageport = 0x87; break;
		case 1: dmaaddrport = 0x02; dmacountport = 0x03; dmapageport = 0x83; break;
		case 2: dmaaddrport = 0x04; dmacountport = 0x05; dmapageport = 0x81; break;
		case 3: dmaaddrport = 0x06; dmacountport = 0x07; dmapageport = 0x82; break;
		
		// 16-bit dma
		case 4: dmaaddrport = 0xc0; dmacountport = 0xc2; dmapageport = 0x8f; break;
		case 5: dmaaddrport = 0xc4; dmacountport = 0xc6; dmapageport = 0x8b; break;
		case 6: dmaaddrport = 0xc8; dmacountport = 0xca; dmapageport = 0x89; break;
		case 7: dmaaddrport = 0xcc; dmacountport = 0xce; dmapageport = 0x8a; break;
	}
 
	
	if ( dmachannel < 4 ) 
	{
		dmamaskreg  = 0x0a;
		dmaclearreg = 0x0c;
		dmamodereg  = 0x0b;
	}

	else
	{
		dmamaskreg  = 0xd4;
		dmaclearreg = 0xd8;
		dmamodereg  = 0xd6;
	}		
	
	return true;
}



// :::::::::::::::::
//  Set the dma control byte mask
//
// :::::::::::::::::
static void sbdrv_dma_setctrlbmask ( uint16 mask )
{
	controlbytemask  = mask;
	controlbytemask += (dmachannel % 4);
}



// :::::::::::::::::
//  Set the dma control byte
//
// :::::::::::::::::
static void sbdrv_dma_setctrl ( void )
{
	outp( dmamodereg, controlbytemask );
}



// :::::::::::::::::
//  Enable the dma channel
//
// :::::::::::::::::
static void sbdrv_dma_enablechan ( void )
{   
	uint8 mask = dmachannel % 4;
	outp( dmamaskreg, mask );
}



// :::::::::::::::::
//  Disable the dma channel
//
// :::::::::::::::::
static void sbdrv_dma_disablechan ( void )
{   
	uint8 mask = 4 + (dmachannel % 4) ;
	outp( dmamaskreg, mask );
}



// :::::::::::::::::
//  Clear the dma flipflop (uhhh) =)
//
// :::::::::::::::::
static void sbdrv_dma_clearflipflop ( void )
{   
	outp( dmaclearreg, 0x00 );
}
 


// :::::::::::::::::
//  Set transfer source adress
//
// :::::::::::::::::
static void sbdrv_dma_setsource ( uint8 far *buffer, uint16 length )
{   
	uint8  pag;
    uint32 adrs, phys;
	uint16 len, offs;
	
    _asm {
		mov		eax, buffer
		mov		ecx, buffer
		and		eax, 0xffff0000
		and		ecx, 0x0000ffff
		shr		eax, 12
		or		eax, ecx
		mov		phys, eax
    }
    
	// 
	// 8-bit transfer
	//
	if ( dmachannel < 4 ) 
	{
		//
		// Write adress in words
		//
		//offs = phys & 0x0000ffff;
        _asm mov    eax, phys
        _asm mov    offs, ax
		outp( dmaaddrport, offs & 0xff );
		outp( dmaaddrport, offs >> 8   );
	
		//
		// Buffer page
		//
        _asm mov    eax, phys
        _asm shr    eax, 16
        _asm mov    pag, al
		outp( dmapageport, pag );

		outp( dmaclearreg, 0x00 );
        
        //
		// Write length in words
		//
		len = length-1;
		outp( dmacountport, len & 0xff );
		outp( dmacountport, len >> 8   );                
    }
	
	// 
	// 16-bit transfer
	//
	else
	{
		//
		// Write adress in words
		//
		//offs = phys/2 & 0x0000ffff;
        _asm mov    eax, phys
        _asm shr    eax, 1
        _asm mov    offs, ax
		outp( dmaaddrport, offs & 0xff );
		outp( dmaaddrport, offs >> 8   );
		
        //
		// Buffer page
		//
        _asm mov    eax, phys
        _asm shr    eax, 16
        _asm mov    pag, al
		outp( dmapageport, pag );
                
		outp( dmaclearreg, 0x00 );
        
        //
		// Write length in words
		//
		len = (length/2)-1;
		outp( dmacountport, len & 0xff );
		outp( dmacountport, len >> 8   );
	}
}


// :::::::::::::::::
//  Setup the dma for auto-init transfer
//
// :::::::::::::::::
static void sbdrv_dma_autoinit ( uint16 bits, 
                                 void far *blkbase, uint16 blksize )
{
    if ( bits == 8)
        sbdrv_dma_setchan( sbdrv.ldma );
    else
        sbdrv_dma_setchan( sbdrv.hdma );
    
    _asm cli
	sbdrv_dma_disablechan();
	sbdrv_dma_clearflipflop();
	sbdrv_dma_setctrlbmask( 0x58 );
	sbdrv_dma_setctrl();
	sbdrv_dma_setsource( blkbase, blksize );
	sbdrv_dma_enablechan();
    _asm sti

}


// :::::::::::::::::
//  Setup the dma for single-cycle transfer
//
// :::::::::::::::::
static void sbdrv_dma_singlecycle ( uint16 bits,
                                    void far *blkbase, uint16 blksize )
{
    if ( bits == 8)
        sbdrv_dma_setchan( sbdrv.ldma );
    else
        sbdrv_dma_setchan( sbdrv.hdma );
    
    _asm cli
	sbdrv_dma_disablechan();
	sbdrv_dma_clearflipflop();
	sbdrv_dma_setctrlbmask( 0x48 );
	sbdrv_dma_setctrl();
	sbdrv_dma_setsource( blkbase, blksize );
	sbdrv_dma_enablechan();
    _asm sti

}


// :::::::::::::::::
//  Allocate a dma buffer
//
// :::::::::::::::::
static void far * sbdrv_dma_allocmem ( uint16 blksize )
{   
	uint32 phys, adrs;
	uint16 stackp = 0;
    void far * blkbase = NULL;
	static void far *pStack[32] = { 0 };
    
    do
	{   
		//
		// Everything ok, allocate the sound buffer and return
		//
		pStack[stackp] = (uint8 far *) memCalloc( blksize );
		if ( pStack[stackp] == NULL )
            break;
		
		adrs = (uint32)pStack[stackp++];
		phys = ((adrs & 0xffff0000)>>12) + (adrs & 0x0000ffff);
		
	} while ( ((phys>>16) != ((phys+sbdrv.blksizewhle)>>16)) && (stackp < 32) );
    
	
    //
	// Were we able to allocate memory that doesn't cross
	// pages ?
	// 
	if ( ((phys>>16) != ((phys+blksize)>>16)) ) 
	{
		if ( stackp-- > 0 )
			for ( ; stackp >= 0; stackp-- )
				if ( pStack[stackp] != NULL )
					memFree( pStack[stackp] );
			
		return false;
	}


	//
	// Memory allocated more then once, keep the last allocation
	// and free the others
	// 
    blkbase = pStack[stackp-1];
	if ( stackp-- > 1 ) 
	{
		blkbase = pStack[stackp--];
		
		for ( ; stackp >= 0; stackp-- )
			if ( pStack[stackp] != NULL )
				memFree( pStack[stackp] );
	}
        
    return blkbase;
}