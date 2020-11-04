DefInt A-Z
'$Include: '..\..\inc\ugl.bi'

Const xRes = 320'*2
Const yRes = 200'*2
Const cFmt = UGL.8BIT

Const bmpW = 16
Const bmpH = 16

Const wStep = 1
Const hStep = 1

Declare Sub ExitError (msg As String)

'':::
        Dim video As Long
        Dim bmp As Long, bmpDC as TDC
	
        '' initialize
        If (Not uglInit) Then ExitError "Init"
	
        bmp = uglNew(UGL.MEM, cFmt, bmpW, bmpH)
        If (bmp = 0) Then ExitError "new"

        colors& = uglColors(cFmt)

        '' fill the bitmaps
                uglBoxF bmp, 0, 0, bmpW-1, bmpH-1, uglColor(cFmt,255,0,255)
                For y = 0 To bmpH-1
                        x1 = Rnd * bmpW
                        x2 = Rnd * bmpW
                        clr& = Rnd * colors&
                        uglHLine bmp, x1, y, x2, clr&
                Next y
                clr& = Rnd * colors&
                uglBox bmp, 0, 0, bmpW-1, bmpH-1, clr&

        uglDCget bmp, bmpDC

	'' change video-mode
        video = uglSetVideoDC(cFmt, xRes, yRes, 1)
        If (video = 0) Then ExitError "SetVideoDC"

        '' show it

        x = (xRes\2) - (bmpDC.xRes\2)
        y = (yRes\2) - (bmpDC.yRes\2)
        show = -1
        Do                                
                If (show) Then
                        show = 0
                        uglClear video, 0
                        uglPutMsk video, x, y, bmp
                End If
                
                do
                        k$ = inkey$
                loop while (len(k$) = 0)

                if len(k$) = 1 then kcd = asc(k$) else kcd = cvi(k$)

                select case kcd
                case 52, &h4b00
                        show = -1
                        uglBoxF video, x+bmpDc.xRes-wStep, y, x+bmpDc.xRes-1, y+bmpDc.yRes-1, 0
                        x = x - wStep
                        If (x + bmpDc.xRes-1 < 0) Then x = xRes-1 + (x + (bmpDc.xRes-1))
                case 54, &h4d00
                        show = -1
                        uglBoxF video, x, y, x+wStep, y+bmpDc.yRes-1, 0
                        x = x + wStep
                        If (x > xRes-1) Then x = -bmpDc.xRes + (x - (xRes-1))
                case 56, &h4800
                        show = -1
                        uglBoxF video, x, y+bmpDc.yRes-hStep, x+bmpDc.xRes-1, y+bmpDc.yRes-1, 0
                        y = y - hStep
                        If (y + bmpDc.yRes-1 < 0) Then y = yRes-1 + (y + (bmpDc.yRes-1))
                case 50, &h5000
                        show = -1
                        uglBoxF video, x, y, x+bmpDc.xRes-1, y+hStep, 0
                        y = y + hStep
                        If (y > yRes-1) Then y = -bmpDc.yRes + (y - (yRes-1))
                End Select

        Loop Until (kcd = 27)

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
