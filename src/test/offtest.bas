DefInt A-Z
'$Include: '..\..\inc\ugl.bi'

Const xRes = 320*2
Const yRes = 200*2
Const cFmt = UGL.8BIT

Declare Sub fillOffScr (offScr As Long)
Declare Sub ExitError (msg As String)

DECLARE SUB int3 ()

'':::
        Dim video As Long
        Dim emsOffScrBuff As Long, memOffScrBuff As Long
        Dim emsTDC as TDC, memTDC as TDC
	
        '' initialize
        If (Not uglInit) Then ExitError "Init"
	
        '' allocate EMS off screen buff
        int3
        emsOffScrBuff = uglNew(UGL.EMS, cFmt, xRes, yRes)
        If (emsOffScrBuff = 0) Then ExitError "New EMS offScr"

        '' allocate MEM off screen buff        
        memOffScrBuff = uglNew(UGL.MEM, cFmt, xRes, yRes)
        If (memOffScrBuff = 0) Then ExitError "New MEM offScr"

	'' change video-mode
        video = uglSetVideoDC(cFmt, xRes, yRes, 1)
        If (video = 0) Then ExitError "SetVideoDC"
	
        '' fill 'em
        fillOffScr emsOffScrBuff
        fillOffScr memOffScrBuff

        '' show 'em
        uglPut video, 0, 0, emsOffScrBuff
        sleep
        uglPut video, 0, 0, memOffScrBuff
        sleep

        uglRestore
        uglDCget emsOffScrBuff, emsTDC
        uglDCget memOffScrBuff, memTDC
        uglVersion major, minor, stable, build
        print "UGL ver:"; CSng(major) + minor / 10; "stable:"; stable; "build:"; build
        print "bpp:"; asc(memTDC.bpp); "xres:"; memTDC.xres; "yres:"; memTDC.yres; "bps:"; memTDC.bps
        print "bpp:"; asc(emsTDC.bpp); "xres:"; emsTDC.xres; "yres:"; emsTDC.yres; "bps:"; emsTDC.bps
        uglEnd
        End

'':::
Sub fillOffScr (offScr As Long)

        colors& = uglColors(cFmt)

        For y = 0 To yRes-1
                uglHLine offScr, 0, y, xRes-1, y
        Next y

        randomize 0
        For i = 0 To 9
                x1 = Rnd * xRes
                y1 = Rnd * yRes
                x2 = Rnd * xRes
                y2 = Rnd * yRes
                uglRectF offScr, x1, y1, x2, y2, Rnd * colors&
                uglRect offScr, x1, y1, x2, y2, -1
        Next i
End Sub


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
