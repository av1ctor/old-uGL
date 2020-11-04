'' comparing uglPut to uglGet, to measure the difference between
'' writing and reading to/from VRAM

DefInt A-Z
'$Include: '..\..\inc\ugl.bi'

Const FRAMES = 2000

Const xRes = 320
Const yRes = 200
Const cFmt = UGL.8BIT

Const bmpW = 32
Const bmpH = 32

Declare Function putTest% (bmp as long, video as long)
Declare Function getTest% (bmp as long, video as long) 
Declare Sub ExitError (msg As String)
Declare Function Timer2& ()

'':::
        Dim video As Long
        Dim putBmp As Long
        Dim getBmp As Long
	
	'' initialize
        If (Not uglInit) Then ExitError "Init"
	
        '' change video-mode
        video = uglSetVideoDC(cFmt, xRes, yRes, 1)
        If (video = 0) Then ExitError "SetVideoDC"

        colors& = uglColors(cFmt)

        '' allocate the bitmaps
        putBmp = uglNew(UGL.MEM, cFmt, bmpW, bmpH)
        getBmp = uglNew(UGL.MEM, cFmt, bmpW, bmpH)

        foo& = uglNew(UGL.MEM, cFmt, bmpW, bmpH)

        For y = 0 To bmpH-1
                uglHLine putBmp, 0, y, bmpW-1, Rnd * colors&
        Next y
        uglRect putBmp, 0, 0, bmpW-1, bmpH-1, Rnd * colors&

        putFPS = putTest(putBmp, video)
        getFPS = getTest(getBmp, video)

        uglRestore
        Print "put fps:"; putFPS
        Print "get fps:"; getFPS
        sleep

        uglEnd
        End

'':::
Sub ExitError (msg As String)
        uglRestore
        uglEnd
        Print "ERROR! "; msg
        End
End Sub

'':::
Function Timer2& Static
        def seg = &h40

        lsb1 = peek(&h6C+0)
        msb1 = peek(&h6C+1)
        lsb2 = peek(&h6C+2)
        msb2 = peek(&h6C+3)
        Timer2 = ((msb2 * 256& + lsb2) * 65536&) + (msb1 * 256& + lsb1)
End Function

'':::
Function putTest% (bmp as long, video as long) static

        iniTmr& = Timer2
        For f = 0 To FRAMES-1
                For y = 0 To (yRes-1)\2 Step bmpH
                        For x = 0 To xRes-1 Step bmpW
                                uglPut video, x, y, bmp
                        Next x
                Next y
        Next f
        endTmr& = Timer2

        putTest = CInt((FRAMES*18.2) / (endTmr&-iniTmr&))
End Function

'':::
Function getTest% (bmp as long, video as long) static

        iniTmr& = Timer2
        For f = 0 To FRAMES-1
                For y = 0 To (yRes-1)\2 Step bmpH
                        For x = 0 To xRes-1 Step bmpW
                                uglGet video, x, y, bmp
                        Next x
                Next y
        Next f
        endTmr& = Timer2

        getTest = CInt((FRAMES*18.2) / (endTmr&-iniTmr&))
End Function
