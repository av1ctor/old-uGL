'' uglPut speed test (dcs allocated separated by uglNew)

DefInt A-Z
'$Include: '..\..\inc\ugl.bi'

Const FRAMES = 1000

Const xRes = 320
Const yRes = 200

Const BMPS = 16
Const bmpW = 32
Const bmpH = 32

Declare Function Test% (bmp() as long, video as long) 
Declare Sub ExitError (msg As String)
Declare Function Timer2& ()
Declare sub parseCmmLine (bpp as string, dct as string)

Declare Sub int3 ()

'':::
        Dim video As Long
        Dim memBmp(0 to BMPS-1) As Long
        Dim emsBmp(0 to BMPS-1) As Long
        dim bpp as string, dct as string
	
        parseCmmLine bpp, dct

        select case bpp
        case "32"
                cFmt = UGL.32BIT
        case "16"
                cFmt = UGL.16BIT
        case "15"
                cFmt = UGL.15BIT
        case "8"
                cFmt = UGL.8BIT
        case else
                ExitError "usage: put bpp dct"
        end select
	
	'' initialize
        If (Not uglInit) Then ExitError "Init"
	
        select case lcase$(dct)
	case "mem"
                video = uglNew(UGL.MEM, cFmt, xRes, yRes)
                If (video = 0) Then ExitError "New offscreen"
	case "ems"
                video = uglNew(UGL.EMS, cFmt, xRes, yRes)
                If (video = 0) Then ExitError "New offscreen"
        case "bnk"
                video = uglSetVideoDC(cFmt, xRes, yRes, 1)
                If (video = 0) Then ExitError "SetVideoDC"
        case else
                ExitError "usage: put bpp dct"
	end select

        colors& = uglColors(cFmt)

        '' allocate the bitmaps

        '' mem
        For i = 0 To BMPS-1
                memBmp(i) = uglNew(UGL.MEM, cFmt, bmpW, bmpH)
                If (memBmp(i) = 0) Then ExitError "New mem bmp"

                '' fill the bitmap
                For y = 0 To bmpH-1
                        uglHLine memBmp(i), 0, y, bmpW-1, Rnd * colors&
                Next y
                uglRect memBmp(i), 0, 0, bmpW-1, bmpH-1, Rnd * colors&
        Next i

        '' ems
        For i = 0 To BMPS-1
                emsBmp(i) = uglNew(UGL.EMS, cFmt, bmpW, bmpH)
                If (emsBmp(i) = 0) Then ExitError "New ems bmp"

                '' fill the bitmap
                For y = 0 To bmpH-1
                        uglHLine emsBmp(i), 0, y, bmpW-1, Rnd * colors&
                Next y
                uglRect emsBmp(i), 0, 0, bmpW-1, bmpH-1, Rnd * colors&
        Next i

        memFPS = Test(memBmp(), video)
        uglRectF video, 0, 0, xRes-1, yRes-1, 0
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
                                uglPut video, x, y, bmp(b)
                        Next x
                Next y
        Next f
        endTmr& = Timer2

        Test = CInt((FRAMES*18.2) / (endTmr&-iniTmr&))
End Function

'':::
sub parseCmmLine (bpp as string, dct as string)
	dim cmd as string

	cmd = Command$
	if len(cmd) = 0 then exit sub
	
        sp = instr(cmd, " ")
        if (sp = len(cmd)) or (sp <= 1) then exit sub
        bpp = mid$(cmd, 1, sp-1) 
        dct = mid$(cmd, sp+1, len(cmd) - sp)
end sub

Sub int3
  Def Seg
  Static opcode As Integer
  opcode = &hCBCC
  Call Absolute(VarPtr(opcode))
End Sub
