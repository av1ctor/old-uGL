''
'' xms.bi -- extended memory (XMS) routines
''


Declare Function xmsCheck%  ()

Declare Function xmsAlloc%  (Byval bytes As Long)

Declare Function xmsCAlloc% (Byval bytes As Long)

Declare Sub      xmsFree    (Byval hnd As Integer)

Declare Function xmsAvail&  ()

Declare Function xmsMap%    (Byval hnd As Integer, _
                             Byval offs As Long, _
                             Byval mode As Integer)

Declare Sub      xmsFill    (Byval hnd As Integer, _
                             Byval offs As Long, _
                             Byval bytes As Long, _
                             Byval char As Integer)
