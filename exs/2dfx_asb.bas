''
'' 2dfxsub.bas -- 2DFX saturated substration + alpha blend demo
''

DefInt A-Z
'$Include: '..\inc\ugl.bi'
'$Include: '..\inc\kbd.bi'
'$Include: '..\inc\2dfx.bi'

Const xRes = 320*1
Const yRes = 200*1

Const cFmtSrc = UGL.8BIT
Const cFmtDst = UGL.8BIT

Const fileName = "mask.bmp"

Declare Sub ExitError (msg As String)

'':::
    Dim kbd As TKBD
    Dim video As Long, wind as Long
    Dim mask As Long, maskDC as TDC

    '' initialize
    If (Not uglInit) Then ExitError "Init"


    '' load mask
    mask = uglNewBMPEx(UGL.MEM, cFmtSrc, fileName, BMPOPT.NO332)
    If (mask = 0) Then ExitError "BMPload"

    uglDCget mask, maskDC


    '' change video-mode
    video = uglSetVideoDC(cFmtDst, xRes, yRes, 1)
    If (video = 0) Then ExitError "SetVideoDC"


    '' create a window
    wind = uglNew(UGL.MEM, cFmtDst, maskDC.xRes, maskDC.yRes)
    If (wind = 0) Then ExitError "New"


    kbdInit kbd


    x = (xRes\2)-(maskDC.xRes\2)
    y = (yRes\2)-(maskDC.yRes\2)
    alpha = 0
    aDir = 1
    Do
		'' 
		uglClear wind, 0
		
		'' draw onto the window
		for i = 0 to 99
			c& = uglColor( cFmtDst, rnd*255, rnd*255, rnd*255 )
			
			x1 = Rnd*maskDC.xRes
			y1 = Rnd*maskDC.yRes
			x2 = Rnd*maskDC.xRes
			y2 = Rnd*maskDC.yRes
			
			uglLine wind, x1, y1, x2, y2, c&
		next i

        '' apply the mask over the window
        tfxBlit wind, 0, 0, mask, TFX.MONO or TFX.SATSUB

        '' change position
        if( cint(rnd * 256) = 1 ) then
        	x = rnd * (xRes-maskDC.xRes)
        	y = rnd * (yRes-maskDC.yRes)
        	
        	uglClear video, 0
        end if
        
        '' draw window onto screen
        alpha = alpha + aDir
        If alpha = 256 or alpha = 0 Then aDir = -aDir

        tfxSetAlpha alpha
        tfxBlit video, x, y, wind, TFX.ALPHA

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

