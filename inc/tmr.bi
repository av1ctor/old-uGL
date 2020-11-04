''
'' tmr.bi -- high-resolution multiple concurrent timers module
''

'' TMR.state:
Const TMR.OFF% = 0%
Const TMR.ON%  = -1%

'' TMR.mode:
Const TMR.ONESHOT%  = 0%
Const TMR.AUTOINIT% = 1%


Type TMR
    state       As Integer                  '' ON, OFF
    mode        As Integer                  '' ONESHOT, AUTOINIT
    counter     As Long                     '' user counter (AUTOINIT only)
    rate        As Long                     '' original rate   (in hertz)
    cnt         As Long                     '' current counter (/  /    )
    reserveda   as long                     '' Reserved, don't mess it with
    reservedb   as long                     '' will cause serious crashes
    prv         As Long
    nxt         As Long
End Type


Declare Sub      tmrInit        ()

Declare Sub      tmrEnd         ()


Declare Sub      tmrNew         (Seg t As TMR, _
                                 Byval mode As Integer, _
                                 Byval rate As Long)

Declare Sub      tmrDel         (Seg t As TMR)

        
Declare Sub      tmrPause       Alias "tmrDel" (Seg t As TMR)

Declare Sub      tmrResume      (Seg t As TMR)

declare sub      tmrCallbkSet   (seg t as tmr, _
                                 byval callbk as long )
                                 
declare sub      tmrCallbkCancel (seg t as tmr)

Declare Function tmrUs2Freq&    (Byval microsecs As Long)

Declare Function tmrMs2Freq&    (Byval milisecs As Long)

Declare Function tmrTick2Freq&  (Byval ticks As Long)

Declare Function tmrSec2Freq&   (Byval seconds As Integer)

Declare Function tmrMin2Freq&   (Byval minutes As Integer)

