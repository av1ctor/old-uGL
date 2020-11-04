''
'' ems.bi -- expanded memory (EMS) routines
''

type EMSSAVECTX
    internalarray as string * 64
end type


Declare Function emsCheck%  ()

Declare Function emsSave%   (Seg ctx As EMSSAVECTX)

Declare Function emsRestore%(Seg ctx As EMSSAVECTX)

Declare Function emsAlloc%  (Byval bytes As Long)

Declare Function emsCAlloc% (Byval bytes As Long)
        
Declare Sub      emsFree    (Byval hnd As Integer)

Declare Function emsAvail&  ()

Declare Function emsMap%    (Byval hnd As Integer, _ 
                             Byval offs As Long, _  
                             Byval bytes As Long)

Declare Sub      emsFill    (Byval hnd As Integer, _
                             Byval offs As Long, _ 
                             Byval bytes As Long, _
                             Byval char As Integer)
