'' uglRectF speed test

DefInt A-Z
'$Include: '..\..\inc\ugl.bi'

Const FRAMES = 3000

Const xRes = 320
Const yRes = 200

Declare Function Timer2& ()
Declare Sub ExitError (msg As String)
Declare Sub parseCmmLine (bpp as string, dct as string)

DECLARE SUB int3 ()

'':::
        Dim video As Long
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
                ExitError "usage: rectf bpp dct"
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
				ExitError "usage: boxf bpp dct"
		end select

        colors& = uglColors(cFmt)
        
        iniTmr& = Timer2
        For f = 0 To FRAMES-1
                uglRectF video, 0, 0, xRes-1, yRes-1, Rnd * colors&
        Next f
        endTmr& = Timer2

        uglRestore
        uglEnd
        Print "fps:"; Clng((FRAMES*18.2) / (endTmr&-iniTmr&))
        End

'':::
Sub ExitError (msg As String)
        uglRestore
        uglEnd
        Print "ERROR! "; msg
        End
End Sub

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
