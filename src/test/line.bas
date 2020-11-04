DefInt A-Z
'$Include: '..\..\inc\ugl.bi'

Const xRes = 320
Const yRes = 200
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

        'screen 13

        uglBox video, 32-1, 32-1, xRes-32, yRes-32, -1
        uglDCsetClip video, 32, 32, xRes-1-32, yRes-1-32

        RANDOMIZE TIMER
        DO
                uglClear video, 0
                FOR i = 0 TO 0
                        x1 = Rnd * xRes
                        y1 = Rnd * yRes
                        x2 = Rnd * xRes
                        y2 = Rnd * yRes
                        
                        'Line (x1, y1)-(x2, y2), 8, , &HAAAA
                        uglLine video, x1, y1, x2, y2, Rnd * colors&
                        uglPSet video, x1, y1, -1
                        uglPSet video, x2, y2, uglColor(cFmt, 255, 0, 0)
                NEXT i
       
                DO
                        k$ = INKEY$
                LOOP WHILE LEN(k$) = 0
        LOOP UNTIL (ASC(k$) = 27)

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

