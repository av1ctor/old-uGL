'' uglPutMsk speed test (dcs allocated separated by uglNew)

DefInt A-Z
'$Include: '..\..\inc\ugl.bi'

Const FRAMES = 1000

Const xRes = 320
Const yRes = 200
Const cFmt = UGL.16BIT

Const BMPS = 8
Const bmpW = 32
Const bmpH = 32

Declare Function Test% (bmp() as long, video as long) 
Declare Sub ExitError (msg As String)
Declare Function Timer2& ()

Declare Sub int3 ()

'':::
        Dim video As Long
        Dim memBmp(0 to BMPS-1) As Long
        Dim emsBmp(0 to BMPS-1) As Long
	
	'' initialize
        If (Not uglInit) Then ExitError "Init"
	
	'' change video-mode
        video = uglSetVideoDC(cFmt, xRes, yRes, 1)
        If (video = 0) Then ExitError "SetVideoDC"

        colors& = uglColors(cFmt)

        '' allocate the bitmaps
        For i = 0 To BMPS-1
                memBmp(i) = uglNew(UGL.MEM, cFmt, bmpW, bmpH)
                If (memBmp(i) = 0) Then ExitError "New mem bmp"
                emsBmp(i) = uglNew(UGL.EMS, cFmt, bmpW, bmpH)
                If (emsBmp(i) = 0) Then ExitError "New ems bmp"

                '' fill the bitmaps
                uglBoxF memBmp(i), 0, 0, bmpW-1, bmpH-1, uglColor(cFmt,255,0,255)
                uglBoxF emsBmp(i), 0, 0, bmpW-1, bmpH-1, uglColor(cFmt,255,0,255)
                For y = 0 To bmpH-1
                        x1 = Rnd * bmpW
                        x2 = Rnd * bmpW
                        clr& = Rnd * colors&
                        uglHLine memBmp(i), x1, y, x2, clr&
                        uglHLine emsBmp(i), x1, y, x2, clr&
                Next y
                clr& = Rnd * colors&
                uglBox memBmp(i), 0, 0, bmpW-1, bmpH-1, clr&
                uglBox emsBmp(i), 0, 0, bmpW-1, bmpH-1, clr&
        Next i

        memFPS = Test(memBmp(), video)
        uglBoxF video, 0, 0, xRes-1, yRes-1, 0
        emsFPS = Test(emsBmp(), video)

        uglRestore
        Print "mem fps:"; memFPS
        Print "ems fps:"; emsFPS

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
Function Test% (bmp() as long, video as long) static

        Randomize 0
        iniTmr& = Timer2
        For f = 0 To FRAMES-1
                For y = 0 To yRes-1 Step bmpH
                        For x = 0 To xRes-1 Step bmpW
                                b = Rnd * (BMPS-1)
                                uglPutMsk video, x, y, bmp(b)
                        Next x
                Next y
        Next f
        endTmr& = Timer2

        Test = CInt((FRAMES*18.2) / (endTmr&-iniTmr&))
End Function

Sub int3
  Def Seg
  Static opcode As Integer
  opcode = &hCBCC
  Call Absolute(VarPtr(opcode))
End Sub
