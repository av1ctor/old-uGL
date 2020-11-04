DefInt A-Z
'$Include: '..\..\inc\ugl.bi'

Const xRes = 320
Const yRes = 200
Const cFmt = UGL.8BIT

Declare Sub ExitError (msg As String)

'':::
        Dim video As Long
	
	'' initialize
        If (Not uglInit) Then ExitError "Init"
	
	'' change video-mode
        video = uglSetVideoDC(cFmt, xRes, yRes, 2)
        If (video = 0) Then ExitError "SetVideoDC"

        uglSetWrkPage 1

        uglBoxF video, 0, 0, xRes-1, yRes-1, uglColor(cFmt, 255, 255, 255)

        uglSetVisPage 1

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
