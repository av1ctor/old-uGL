
'' WARNING: Don't run this in the IDE!

DefInt a-z
'$include: '..\..\inc\ems.bi'
'$include: '..\..\inc\ugl.bi'

Const PASSES% = 1%
Const HANDLES% = 16%
Const BYTES& = 54321&

Declare Sub delay (ticks As Integer)
Declare Sub ExitError (msg As String)

        Dim hndTB(0 to (HANDLES*PASSES)-1) as integer
        Dim lineBuff(0 to 79) as integer

        If (Not uglInit) then
                ExitError "uglInit"
        End If

        availBefore& = emsAvail

        dim ectx as EMSSAVECTX
        bleh% = emsSave(ectx)
        if( bleh% <> 0 ) then ExitError "emsSave()" + str$(bleh%)

        For p = 0 to (HANDLES*PASSES)-1 step HANDLES
                cls
                print p

                For i = 0 to HANDLES-1
                        hnd = emsAlloc(BYTES)
                        If hnd = 0 Then
                                ExitError "emsAlloc" + str$(p + i)
                        End If
                        hndTB(p + i) = hnd
                Next i
	
                For i = 0 to HANDLES-1
                        frame = emsMap(hndTB(p + i), 0, BYTES)
                        If frame = 0 Then
                                ExitError "emsMap" + str$(p + i)
                        End If
		
                        char = 65 + i
                        Def Seg = frame
                        For src& = 0 to BYTES-1
                                poke src&, char
                        Next src&
                Next i

                For i = 0 to HANDLES-1
                        frame = emsMap(hndTB(p + i), 0, BYTES)
                        If frame = 0 Then
                                Print "ERROR: re-mapping!"; p + i
                                End
                        End If
		
                        delay 3

                        clr = i and 7

                        src& = 0
                        dst = 0
                        For y = 0 to 25-1
                                Def Seg = frame
                                For x = 0 to 80-1
                                        lineBuff(x) = peek(src&)
                                        src& = src& + 1
                                Next x
			
                                Def Seg = &hB800
                                For x = 0 to 80-1
                                        poke dst+0, lineBuff(x)
                                        poke dst+1, clr 
                                        dst = dst + 2
                                Next x
                        Next y
                Next i
	
                If p = 0 Then
                        For i = 0 to HANDLES-1
                                emsFree hndTB(p + i)
                        Next i
                End If
        Next p

        cls
        For p = 0 to (HANDLES*PASSES)-1 step HANDLES
                For i = 0 to HANDLES-1
                        print hex$(hndTB(p + i)); " ";
                Next i
                print
        Next p

        if( emsRestore(ectx) <> 0 ) then ExitError "emsRestore()"

        availAfter& = emsAvail

        print availBefore&, availAfter&

        uglEnd
        End

'':::
Sub delay (ticks as integer) static
        Dim last as integer, curr as integer

        Def Seg = &h40

        For i = 1 To ticks
                last = Peek(&h6C)
                Do
                    curr = Peek(&h6C)
                Loop While (curr = last)
        Next i
End Sub

'':::
Sub ExitError (msg As String)
        Print "ERROR! "; msg
        uglEnd
        End
End Sub

