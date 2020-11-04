DEFINT A-Z
'$Include: '..\..\inc\ugl.bi'

Const xRes = 320
Const yRes = 200
Const cFmt = UGL.8BIT

Declare Sub ExitError (msg As String)

DECLARE SUB int3 ()

'':::
        Dim video As Long
        Dim cbz As CUBICBEZ

	'' initialize
        If (Not uglInit) Then ExitError "Init"
	
        video = uglSetVideoDC(cFmt, xRes, yRes, 1)
        If (video = 0) Then ExitError "SetVideoDC"

        cbz.a.x = 0:   cbz.a.y = 199
        cbz.b.x = 0:   cbz.b.y = 0
        cbz.c.x = 319: cbz.c.y = 0
        cbz.d.x = 319: cbz.d.y = 199
        uglCubicBez video, cbz, 16, uglColor(cFmt, 0, 255, 0)

        cbz.a.x = 0:   cbz.a.y = 0
        cbz.b.x = 0:   cbz.b.y = 199
        cbz.c.x = 319: cbz.c.y = 199
        cbz.d.x = 319: cbz.d.y = 0
        uglCubicBez video, cbz, 16, uglColor(cFmt, 0, 0, 255)

        cbz.a.x = 0:   cbz.a.y = 0
        cbz.b.x = 319: cbz.b.y = 0
        cbz.c.x = 319: cbz.c.y = 199
        cbz.d.x = 0:   cbz.d.y = 199
        uglCubicBez video, cbz, 16, uglColor(cFmt, 255, 0, 0)

        cbz.a.x = 319: cbz.a.y = 0
        cbz.b.x = 0:   cbz.b.y = 0
        cbz.c.x = 0:   cbz.c.y = 199
        cbz.d.x = 319: cbz.d.y = 199
        uglCubicBez video, cbz, 16, uglColor(cFmt, 255, 255, 255)

        sleep

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
