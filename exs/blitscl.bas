''
'' blitscl.bas -- blit's part of an DC with scaling
''

DefInt A-Z
'$Include: '..\inc\ugl.bi'
'$Include: '..\inc\kbd.bi'
'$Include: '..\inc\2dfx.bi'
'$Include: '..\inc\pal.bi'
'$Include: '..\inc\dos.bi'

Const xRes = 320*1
Const yRes = 200*1

Const cfmt = UGL.8BIT

Const wStep = 1
Const hStep = 1

const filename = "ugl.bmp"

Const px	= 10
Const py	= 10
Const wdt	= 32
Const hgt	= 32

Declare Sub ExitError (msg As String)



'':::
    Dim kbd As TKBD
    Dim video As Long
    Dim bmp As Long, bmpDC as TDC
    dim bg as long

    '' initialize
    If (Not uglInit) Then ExitError "Init"

    '' load the BMP
    bmp = uglNewBMPEx(UGL.MEM, cfmt, filename, BMPOPT.NO332)
    If (bmp = 0) Then ExitError "BMPload"

    uglDCget bmp, bmpDC

    '' change video-mode
    video = uglSetVideoDC(cfmt, xRes, yRes, 1)
    If (video = 0) Then ExitError "SetVideoDC"

    '' show it
    kbdInit kbd

    bg = uglColor( cfmt, 255, 0, 0 )

    uglClear video, bg


    x = (xRes\2) - (bmpDC.xRes\2)
    y = (yRes\2) - (bmpDC.yRes\2)
    moved = -1

    dim xscale as single, yscale as single
    xscale = 1
    yscale = 1

    Do
        If (kbd.d) Then
        	moved = -1
        	xscale = xscale + .1
        elseif (kbd.a) Then
        	moved = -1
        	if( xscale > .1 ) then xscale = xscale - .1
        end if

        If (kbd.w) Then
        	moved = -1
        	yscale = yscale + .1
        elseif (kbd.s) Then
        	moved = -1
        	if( yscale > .1 ) then yscale = yscale - .1
        end if

        xrscl = bmpDc.xRes
        yrscl = bmpDc.yRes

        If (kbd.left) Then
            moved = -1
            x = x - wStep
            If (x + xrscl-1 < 0) Then x = xRes-1 + (x + (xrscl-1))
        Elseif (kbd.right) Then
            moved = -1
            x = x + wStep
            If (x > xRes-1) Then x = -xrscl + (x - (xRes-1))
        End If
        If (kbd.up) Then
            moved = -1
            y = y - hStep
            If (y + yrscl-1 < 0) Then y = yRes-1 + (y + (yrscl-1))
        Elseif (kbd.down) Then
            moved = -1
            y = y + hStep
            If (y > yRes-1) Then y = -yrscl + (y - (yRes-1))
        End If

        If (moved) Then
            moved = 0

            uglClear video, bg

			uglBlitMskScl video, x, y, xscale, yscale, bmp, px, py, wdt, hgt

			uglBlitMskFlipScl video, x + wdt*xscale + 1, y, xscale, yscale, UGL.HFLIP, bmp, px, py, wdt, hgt

			uglBlitMskFlipScl video, x, y + hgt*yscale + 1, xscale, yscale, UGL.VFLIP, bmp, px, py, wdt, hgt

			uglBlitMskFlipScl video, x + wdt*xscale + 1, y + hgt*yscale + 1, xscale, yscale, UGL.HVFLIP, bmp, px, py, wdt, hgt

        End If
    Loop Until (kbd.esc)

    uglRestore
    uglEnd
    End

'':::
Sub ExitError (msg As String)
    uglRestore
    uglEnd
    Print "ERROR! "; msg
    End
End Sub
