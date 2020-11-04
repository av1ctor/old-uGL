''
''  putscl.bas - Using uglPutScl to scale DCs
''
''
''

defint a-z
'$include: '..\inc\ugl.bi'
'$include: '..\inc\kbd.bi'
'$include: '..\inc\font.bi'

const xRes = 320
const yRes = 200
const cFmt = UGL.8BIT
const FALSE = 0
const PAGES = 1


type EnvType
    hFont       as long
    hVideoDC    as long
    hTextrDC    as long
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


    '' Load UGL logo
    Env.hTextrDC = uglNewBMP( UGL.MEM, cFmt, "ugl.bmp" )
    if ( Env.hTextrDC = FALSE ) then ExitError "0x0002, Could not load data/ugl.bmp..."

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
    static frmCounter as single
    static scale  as single, scalek as single
    static tmrIni as single, tmrEnd as single

    scale  = 0.5
    scalek = -0.01

    tmrIni = timer
    frmCounter = 0

    x = (xRes-128*scale)/2
    y = (yRes-128*scale)/2
    do
        '' Scale DC
        uglPutMskScl Env.hVideoDC, x, y, scale, scale, Env.hTextrDC

        if ( Env.keyboard.p = FALSE ) then
            scale = scale + scalek

            if ( scale <= 0.1 OR scale >= 2.1 ) then
                scalek = -scalek
            end if
        end if

        If (Env.keyboard.left) Then
            x = x - 1
        Elseif (Env.keyboard.right) Then
            x = x + 1
        End If
        If (Env.keyboard.up) Then
            y = y - 1
        Elseif (Env.keyboard.down) Then
            y = y + 1
        End If


        '' Update some frame counter
        '' etc etc
        frmCounter   = frmCounter + 1.0!
        Env.ViewPage = Env.WorkPage
        Env.WorkPage = (Env.WorkPage+1) mod PAGES

    loop until ( Env.Keyboard.Esc )

    tmrEnd = timer
    Env.FPS = frmCounter / (tmrEnd-tmrIni)

end sub
