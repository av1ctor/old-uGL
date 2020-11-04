DefInt A-Z
'$Include: '..\..\inc\ugl.bi'

Const xRes = 320
Const yRes = 200

Declare Sub ExitError (msg As String)

DECLARE SUB int3 ()

'':::
        Dim video As Long
        Dim bmp As Long
	
	'' initialize
        If (Not uglInit) Then ExitError "Init"
	
	'' change video-mode
        video = uglSetVideoDC(UGL.16BIT, xRes, yRes, 1)
        If (video = 0) Then ExitError "SetVideoDC"

        int3
        bmp = uglNew(UGL.MEM, UGL.16BIT, 32, 32)
        If (bmp = 0) Then ExitError "New"

        fuck& = uglNew(UGL.MEM, UGL.16BIT, 32, 32)
	
        for y = 0 to 31
                clr& = Rnd * 65536
                for x = 0 to 31
                        uglPset bmp, x, y, clr&
                next x
        next y

        int3
        For y = 0 To 31
                For x = 0 To 31
                        uglPSet video, x, y, uglPGet(bmp, x, y)
                Next x
        Next y
        sleep

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

SUB int3
  def seg
  static opcode as integer
  opcode = &hCBCC
  call absolute(varptr(opcode))
end sub
