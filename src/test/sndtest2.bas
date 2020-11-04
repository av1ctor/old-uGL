''
''
''
''
defint a-z
option explicit
'$include: '..\..\inc\ugl.bi'
'$include: '..\..\inc\dos.bi'
'$include: '..\..\inc\snd.bi'
'$include: '..\..\inc\kbd.bi'
'$include: '..\..\inc\ems.bi'

const true  = -1
const false =  0
const MAXVOICES = 32

declare sub ExitError ( msg as string )

DECLARE FUNCTION DQBinstallSB(BYVAL VolActive,BYVAL Channels,BYVAL Freq, BYVAL BaseAddr,BYVAL IRQ,BYVAL DMA)
DECLARE sub DQBremoveSB ( )

dim kbd as TKBD
dim hFilea as FILE, hFileb as FILE
dim sampls( 5 ) as long
dim voices( 0 to MAXVOICES-1 ) as sndvoice


    '' Load samples
    ''       
    print "_ - [ L O A D I N G ] - _"
    sampls(0) = sndNewWav( snd.mem, "samples\samplea.wav" )
    if ( sampls(0) <> false ) then print " - s0 ok."
    sampls(1) = sndNewWav( snd.mem, "samples\sampleb.wav" )
    if ( sampls(1) <> false ) then print " - s1 ok."
    sampls(2) = sndNewWav( snd.mem, "samples\samplec.wav" )
    if ( sampls(2) <> false ) then print " - s2 ok."
    sampls(3) = sndNewWav( snd.mem, "samples\sampled.wav" )
    if ( sampls(3) <> false ) then print " - s3 ok."
    sampls(4) = sndNewWav( snd.mem, "samples\samplee.wav" )    
    if ( sampls(4) <> false ) then print " - s4 ok."

   

   if ( sampls(0) = false ) or _ 
      ( sampls(1) = false ) or _
      ( sampls(2) = false ) or _
      ( sampls(3) = false ) or _
      ( sampls(4) = false ) then
   '   ExitError "Could not load samples..."
   else
      print "- done."
   end if
   

    if ( DQBinstallSB( 0, 0, 22050, &h220, 5, 1 ) = false ) then
        ExitError "Could not init sound module..."
    end if
    
    
    kbdInit kbd
    
    ''
    '' Set output format
    ''
    print "_ - [ O P E N I N G ] - _"
    
    dim i as integer
    dim blah as long
    
    ''
    ''
    ''
    for i = 0 to MAXVOICES-1
        sndVoiceSetDefault voices(i) 
    next i
    
    sndVoiceSetLoopMode voices(0), snd.pingpong
    'sndVoiceSetDir voices(0), snd.down
    sndVoiceSetDir voices(1), snd.down
    sndVoiceSetLoopMode voices(4), snd.repeat
    
    
    print "Press keys 1-5 to play samples"    
    do        
        if ( kbd.one ) then 
            sndPlay voices(0), sampls(0)
            while ( kbd.one )
            wend
        end if
        
        if ( kbd.plus ) then 
           sndVoiceSetRate voices(0), voices(0).pitch + 1000
           while ( kbd.plus )
           wend
         end if

        if ( kbd.min ) then 
            sndVoiceSetRate voices(0), voices(0).pitch - 1000
            while ( kbd.min )
            wend
         end if

        if ( kbd.two ) then 
            sndPlay voices(1), sampls(1)
            while ( kbd.two )
            wend
        end if
        
        if ( kbd.three ) then 
            sndPlay voices(2), sampls(2)
            while ( kbd.three )
            wend
        end if
        
        if ( kbd.four ) then 
            sndPlay voices(3), sampls(3)
            while ( kbd.four )
            wend
        end if
        
        if ( kbd.five ) then 
            sndPlay voices(4), sampls(4)
            while ( kbd.five )
            wend
        end if        

    loop until ( kbd.esc )    

    
    DQBremoveSB
    
    


'' ::::::::::
'' name: ExitError
'' desc:
''
'' ::::::::::
defint a-z
sub ExitError ( msg as string )
    print "Error: " + msg
    
    uglEnd
    
    end 
end sub
