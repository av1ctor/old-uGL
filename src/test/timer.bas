Defint A-Z
'$Include: '..\..\inc\tmr.bi'

const TIMERS = 23

        Dim t(0 to TIMERS-1) As TMR
        Dim idx(0 to TIMERS-1) As Integer
    
        Randomize Timer
        for i = 0 to TIMERS-1
                tmrNew t(i), TMR.ONESHOT, tmrTick2Freq(Rnd * 182)
                idx(i) = i
        next i
        
        for j = 0 to TIMERS-1
                for i = 0 to TIMERS-2
                        a = idx(i)
                        b = idx(i+1)
                        if t(a).rate > t(b).rate then swap idx(i), idx(i+1)
                next i
        next j

        Cls
        tmrInit

        Do
            Locate 1, 1
            state = 0
            for j = 0 to TIMERS-1
                i = idx(j)
                Print Using "t:& state:& counter:&   "; Hex$(i); Hex$(t(i).state and 1); Hex$(t(i).cnt)
                state = state + t(i).state
            next j
            
        Loop Until (state = 0) or (Len(Inkey$) > 0)
     
        tmrEnd
        End
