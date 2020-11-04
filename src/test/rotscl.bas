''
''  ugfrmwrk.bas - UGL frame for the contest, the code in here does
''                 not count as extra lines. But any code you add to
''                 it does. If you do not like this template and want
''                 to do it differently then you may make your own and
''                 send it to the judge(s) for approval.
''                 Best viewed in a text editor and NOT qb's IDE.
''
''         Note:   For those of you that don't know how to use UGL at
''                 all, you add your code in the doMain sub where it says
''                 Your code here. This template automatically clears the 
''                 screen. And as for the destination DC you use Env.hVideoDC.
''                 If you don't want to clear the screen each frame you just
''                 have to remove the part that says:
''
''                 '' Page flipping
''                 wait &h3da, 8
''                 uglSetVisPage Env.ViewPage
''                 uglSetWrkPage Env.WorkPage
''        
''                 '' Clear screen 
''                 uglClear Env.hVideoDC, 0
''
''
defint a-z
'$include: '..\..\inc\ugl.bi'
'$include: '..\..\inc\kbd.bi'
'$include: '..\..\inc\font.bi'

const xRes = 320
const yRes = 240
const cFmt = UGL.16BIT
const FALSE = 0
const PAGES = 16


type EnvType    
    hFont       as long
    hVideoDC    as long    
    hSpritDC    as long
    Keyboard    as TKBD
    FPS         as single
    ViewPage    as integer
    WorkPage    as integer
end type


declare sub doMain      ( )
declare sub doInit      ( )
declare sub doTerminate ( )
declare sub ExitError   ( msg as string )


    '' Your code goes in doMain ( )
    
    dim shared Env as EnvType
    
    doInit
    doMain
    doTerminate
    
    

defint a-z
sub ExitError ( msg as string )

    '' Terminate UGL
    '
    kbdEnd
    uglRestore
    uglEnd
    
    '' Print error message
    '' and end
    '
    print "Error: " + msg
    end
    
end sub


defint a-z
sub doInit

    '' Init UGL
    ''
    if ( uglInit = FALSE ) then 
        ExitError "0x0000, UGL init failed..."
    end if        
    
    
    '' Set video mode with x pages where
    '' x = PAGES
    ''
    Env.hVideoDC = uglSetVideoDC( cFmt, xRes, yRes, PAGES )
    if ( Env.hVideoDC = FALSE ) then ExitError "0x0001, Could not set video mode..."
    
    
    '' Init keyboard handler
    ''
    kbdInit Env.Keyboard
    
    
    '' Anything else
    Env.hSpritDC = uglNewBMP( UGL.MEM, cFmt, "ugllog.bmp" )
    if ( Env.hSpritDC = FALSE ) then ExitError "0x0002, Could not load test.bmp..."
    
end sub


defint a-z
sub doTerminate

    '' Terminate UGL
    ''
    kbdEnd
    uglRestore
    uglEnd
    
    '' Print FPS
    cls    
    print "Frames per second:" + str$( cint(Env.FPS) )    
        
end sub


defint a-z
sub doMain    
    static angle as single
    static frmCounter as single    
    static tmrIni as single, tmrEnd as single
    static scalex as single, scaley as single
    static scalexk as single, scaleyk as single
    
    angle  = 0.0
    scalex = 1.0
    scaley = 1.0
    scalexk = 0.001
    scaleyk = 0.001    

    tmrIni = timer
    frmCounter = 0

    do
        '' Page flipping        
        uglSetVisPage Env.ViewPage
        uglSetWrkPage Env.WorkPage
        
        '' Clear screen 
        uglClear Env.hVideoDC, -1
        
        
        '' -= Your code here =-
        ''        
        if ( masked = FALSE ) then
            uglPutScl Env.hVideoDC, 10, 10, 1.5, 1.5, Env.hSpritDC
        else 
            uglPutSclMsk Env.hVideoDC, 0, 0, 1.5, 1.5, Env.hSpritDC
        end if        
        
        
        if ( Env.Keyboard.p = FALSE ) then 
            angle = angle + 0.1
            scalex = scalex + scalexk
            scaley = scaley + scaleyk        
            
            if ( Env.Keyboard.m ) then masked = not masked        
            if ( scalex <= 0.5 ) or ( scalex >= 1.2 ) then scalexk = -scalexk
            if ( scaley <= 0.5 ) or ( scaley >= 1.2 ) then scaleyk = -scaleyk
        end if
        
        
        '' Do this last
        frmCounter   = frmCounter + 1.0!
        Env.ViewPage = Env.WorkPage        
        Env.WorkPage = (Env.WorkPage+1) mod PAGES
        
    loop until ( Env.Keyboard.Esc )
    
    tmrEnd = timer    
    Env.FPS = frmCounter / (tmrEnd-tmrIni)    
        
end sub