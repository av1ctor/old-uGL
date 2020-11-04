'' uglPSet speed test, for weirdos :P

DefInt A-Z
'$Include: '..\..\inc\ugl.bi'

Const FRAMES = 100

Const xRes = 320
Const yRes = 200
Const cFmt = UGL.8BIT

Declare Function Timer2& ()
Declare Sub ExitError (msg As String)

DECLARE SUB int3 ()

'':::
        Dim video As Long
	
	'' initialize
        If (Not uglInit) Then ExitError "Init"
	
	'' change video-mode
        video = uglSetVideoDC(cFmt, xRes, yRes, 1)
        If (video = 0) Then ExitError "SetVideoDC"
	
        colors& = uglColors(cFmt)
        iniTmr& = Timer2
        For f = 0 To FRAMES-1
                c& = Rnd * colors&
                For y = 0 To yRes-1
                        For x = 0 To xRes-1
                                uglPSet video, x, y, c&
                        Next x
                Next y
        Next f
        endTmr& = Timer2

        uglRestore
        uglEnd
        Print "fps:"; CInt((FRAMES*18.2) / (endTmr&-iniTmr&))
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

SUB int3
  def seg
  static opcode as integer
  opcode = &hCBCC
  call absolute(varptr(opcode))
end sub


