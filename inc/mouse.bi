''
'' mouse.bi -- mouse module structs & prototypes
''

Type MOUSEINF
        x               As Integer
        y               As Integer
        anyButton       As Integer
        left            As Integer
        middle          As Integer
        right           As Integer
End Type


Declare Function mouseInit%     (Byval dc As Long, _
                                 Seg mouse As MOUSEINF)
        
Declare Sub      mouseEnd       ()
        

Declare Function mouseReset%    (Byval dc As Long, _
                                 Seg mouse As MOUSEINF)
        
Declare Sub      mouseCursor    (Byval cursor As Long, _
                                 Byval xSpot As Integer, _
                                 Byval ySpot As Integer)

Declare Sub      mouseRange     (Byval xmin As Integer, _ 
                                 Byval ymin As Integer, _ 
                                 Byval xmax As Integer, _
                                 Byval ymax As Integer)
        
Declare Sub      mousePos       (Byval x As Integer, _
                                 Byval y As Integer)

Declare Sub      mouseRatio     (Byval hMickeys As Integer, _
                                 Byval vMickeys As Integer)

Declare Sub      mouseShow      ()

Declare Sub      mouseHide      ()

Declare Function mouseIn%       (Seg box As RECT)
