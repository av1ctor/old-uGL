'' uglPut speed test (dcs allocated in same seg/ems page by uglNewMult)

DefInt A-Z
'$Include: '..\..\inc\ugl.bi'

Const xRes = 320
Const yRes = 200

Const BMPS = 8
Const bmpW = 64
Const bmpH = 64

Declare Function Test& (bmp() as long, video as long)
Declare Sub ExitError (msg As String)
Declare Function Timer2& ()
Declare function parseCmmLine% (bpp as string, dct as string, mhz as long)

DECLARE SUB int3 ()

        dim shared frames as integer
'':::
        Dim video As Long
        Dim memBmp(0 to BMPS-1) As Long
        Dim emsBmp(0 to BMPS-1) As Long
        dim bpp as string, dct as string, mhz as long
	
        if parseCmmLine(bpp, dct, mhz) < 3 then
                ExitError "usage: put2 bpp dct mhz"
        end if

        select case bpp
        case "32"
                cFmt = UGL.32BIT
                bps& = xRes * 4
        case "16"
                cFmt = UGL.16BIT
                bps& = xRes * 2
        case "15"
                cFmt = UGL.15BIT
                bps& = xRes * 2
        case "8"
                cFmt = UGL.8BIT
                bps& = xRes
        case else
                ExitError "usage: put2 bpp dct mhz"
        end select
	
	'' initialize
        If (Not uglInit) Then ExitError "Init"
	
        select case lcase$(dct)
	case "mem"
                video = uglNew(UGL.MEM, cFmt, xRes, yRes)
                If (video = 0) Then ExitError "New offscreen"
                frames = 10000 \ (bps& \ xRes)
	case "ems"
                video = uglNew(UGL.EMS, cFmt, xRes, yRes)
                If (video = 0) Then ExitError "New offscreen"
                frames = 1500 \ (bps& \ xRes)
        case "bnk"
                video = uglSetVideoDC(cFmt, xRes, yRes, 1)
                If (video = 0) Then ExitError "SetVideoDC"
                frames = 3000 \ (bps& \ xRes)
        case else
                ExitError "usage: put2 bpp dct mhz"
	end select

        colors& = uglColors(cFmt)

        '' allocate the bitmaps
        If (Not uglNewMult(memBmp(), BMPS, UGL.MEM, cFmt, bmpW, bmpH)) Then
                ExitError "New mem bmp"
        End If
        If (Not uglNewMult(emsBmp(), BMPS, UGL.EMS, cFmt, bmpW, bmpH)) Then
                ExitError "New ems bmp"
        End If

        '' fill the bitmaps
        For i = 0 To BMPS-1
                For y = 0 To bmpH-1
                        clr& = Rnd * colors&
                        uglHLine memBmp(i), 0, y, bmpW-1, clr&
                        uglHLine emsBmp(i), 0, y, bmpW-1, clr&
                Next y
                clr& = Rnd * colors&
                uglRect memBmp(i), 0, 0, bmpW-1, bmpH-1, clr&
                uglRect emsBmp(i), 0, 0, bmpW-1, bmpH-1, clr&
        Next i    

        memFPS& = Test(memBmp(), video)
        emsFPS& = Test(emsBmp(), video)

        if (lcase$(dct) <> "bnk") then
                v& = uglSetVideoDC(cFmt, xRes, yRes, 1)
                If (v& <> 0) Then
                        uglPut v&, 0, 0, video
                        sleep
                end if 
        end if

        uglRestore
        cls
        width 80, 25
        Print "mem fps:"; memFPS&; "cpp:"; (mhz*1000000) / ((bps& * yRes) * memFPS&)
        Print "ems fps:"; emsFPS&; "cpp:"; (mhz*1000000) / ((bps& * yRes) * emsFPS&)

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
Function Test& (bmp() as long, video as long) static
        dim vtx(3) as vector2i
        
        vtx(0).x = 0: vtx(0).y = 0: vtx(0).u = 0: vtx(0).v = 0
        vtx(1).x = 0: vtx(1).y = BmpH-1: vtx(1).u = 0: vtx(1).v = BmpH-1
        vtx(2).x = BmpH-1: vtx(2).y = BmpH-1: vtx(2).u = BmpW-1: vtx(2).v = BmpH-1
        vtx(3).x = BmpH-1: vtx(3).y = 0: vtx(3).u = BmpW-1: vtx(3).v = 0

        uglClear video, 0

        'int3
        iniTmr& = timer2&
        For f = 1 To FRAMES
                For y = 0 To yRes-1-0 Step bmpH
                        For x = 0 To xRes-1 Step bmpW
                                b = (b + 1) and (BMPS-1)
                                uglPut video, x+d, y, bmp(b)                                
                                d = (d + 1) and 3
                        Next x
                Next y
        Next f
        endTmr& = timer2&

        Test = Clng((FRAMES*18.2) / (endTmr&-iniTmr&))
End Function

'':::
function parseCmmLine% (bpp as string, dct as string, mhz as long)
	dim cmd as string

	cmd = Command$
        if len(cmd) = 0 then exit function
	
        sp1 = instr(cmd, " ")
        if (sp1 = len(cmd)) or (sp1 <= 1) then exit function
        sp2 = instr(sp1+1, cmd, " ")
        if (sp2 = len(cmd)) or (sp2 <= sp1) then exit function

        bpp = mid$(cmd, 1, sp1-1)
        dct = mid$(cmd, sp1+1, sp2 - sp1 - 1)
        mhz = val(mid$(cmd, sp2+1, len(cmd) - sp))
        parseCmmLine = 3
end function

SUB int3
  def seg
  static opcode as integer
  opcode = &hCBCC
  call absolute(varptr(opcode))
end sub
