DefInt a-z
'$include: '..\..\inc\ugl.bi'
'$include: '..\..\inc\font.bi'

Const xRes = 320'*2
Const yRes = 200'*2
Const cFmt = UGL.8BIT

Declare Sub ExitError (msg As String)

DECLARE SUB int3 ()

'':::
        Dim video as long
        Dim uvf as long, uvf18 as long
	
        If ( not uglInit ) Then ExitError "Init"
	
        uvf = fontNew("d:\arial.uvf")
        If ( uvf = 0 ) Then ExitError "fontNew arial"
        uvf18 = fontNew("d:\arial18.uvf")
        If ( uvf18 = 0 ) Then ExitError "fontNew arial18"
	
        video = uglSetVideoDC(cFmt, xRes, yRes, 1)
        If ( video = 0 ) Then ExitError "SetVideoDC"
	
        fontSetAlign FONT.HALIGN.CENTER, FONT.VALIGN.BASELINE
        'fontSetUnderline FONT.TRUE
        ''fontSetStrikeOut FONT.TRUE
        'fontSetBGMode FONT.BG.OPAQUE
        'fontSetBGColor &h80
        ''fontSetOutline FONT.TRUE
                
        s = 18
        for a = 0 to 359 step 3
            uglClear video, 0            
            fontSetSize s
            fontSetAngle a
            fontTextOut video, xRes\2, yRes\2, uglColor(cFmt, 255,0,0), uvf, "ABCD0123vwxyz"

            fontSetSize s
            fontSetAngle a
            fontTextOut video, xRes\2, 180, uglColor(cFmt, 255,0,0), uvf18, "ABCD0123vwxyz"

            s = s + 1
            while len(inkey$) = 0:wend
        next a

        fontDel uvf18
        fontDel uvf
    
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

