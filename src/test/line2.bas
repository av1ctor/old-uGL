DefInt A-Z
'$Include: '..\..\inc\ugl.bi'

const CLIP = 64

Const xRes = 320'*2
Const yRes = 200'*2
Const cFmt = UGL.8BIT

Declare Sub ExitError (msg As String)

DECLARE SUB int3 ()

'':::
        Dim video As Long

	'' initialize
        If (Not uglInit) Then ExitError "Init"
	
        video = uglSetVideoDC(cFmt, xRes, yRes, 1)
        If (video = 0) Then ExitError "SetVideoDC"

        colors& = uglColors(cFmt)

        uglBox video, CLIP-1, CLIP-1, xRes-CLIP, yRes-CLIP, -1
        uglDCsetClip video, CLIP, CLIP, xRes-1-CLIP, yRes-1-CLIP

        RANDOMIZE TIMER
        DO
                FOR i = 0 TO 3000
                        x1 = Rnd * xRes
                        y1 = Rnd * yRes
                        x2 = Rnd * xRes
                        y2 = Rnd * yRes

                        uglLine video, x1, y1, x2, y2, Rnd * colors&
                NEXT i       
        LOOP WHILE LEN(INKEY$) = 0

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

SUB int3
  def seg
  static opcode as integer
  opcode = &hCBCC
  call absolute(varptr(opcode))
end sub

