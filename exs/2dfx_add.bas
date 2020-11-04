''
'' 2dfxadd.bas -- 2DFX saturated addition demo
''

DefInt A-Z
'$Include: '..\inc\ugl.bi'
'$Include: '..\inc\kbd.bi'
'$Include: '..\inc\2dfx.bi'

Const xRes = 1024
Const yRes = 768

Const cFmtSrc = UGL.8BIT
Const cFmtDst = UGL.32BIT

Const fileName = "flare.bmp"

Declare Sub ExitError (msg As String)

'':::
    Dim kbd As TKBD
    Dim video As Long
    Dim bmp As Long, bmpDC as TDC

    '' initialize
    If (Not uglInit) Then ExitError "Init"


    '' load the flare
    bmp = uglNewBMPEx(UGL.MEM, cFmtSrc, fileName, BMPOPT.NO332)
    If (bmp = 0) Then ExitError "BMPload"

    uglDCget bmp, bmpDC


    '' change video-mode
    video = uglSetVideoDC(cFmtDst, xRes, yRes, 1)
    If (video = 0) Then ExitError "SetVideoDC"


    kbdInit kbd


    cnt = 100
    Do
		if( cnt >= 100 ) then
			cnt = 0
			for i = 0 to yRes-1
				c& = uglColor( cFmtDst, i, i mod (yRes\2), i mod (yRes\4) )
				uglLine video, 0, i, xRes-1, i, c&
			next i
		end if
        cnt = cnt + 1


    	x = (xRes * rnd)
    	y = (yRes * rnd)

        tfxBlit video, x, y, bmp, TFX.MONO or TFX.SATADD

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

