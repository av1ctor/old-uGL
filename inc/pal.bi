''
'' pal.bi -- palette routines
''
''

'' uglPalLoad's 'fmt' parameter:
Const PALRGB% = 0%
Const PALBGR% = 1%

type tRGB
		red    as string * 1
        green  as string * 1
        blue   as string * 1
end type


Declare Sub      uglPalSet      (Byval idx As Integer, _
                                 Byval entries As Integer, _
                                 Byval pal As Long)

Declare Sub      uglPalSetBuff alias "uglPalSet" (Byval idx As Integer, _
                                 Byval entries As Integer, _
                                 Seg pal As tRGB)

Declare Sub      uglPalGet      (Byval idx As Integer, _
                                 Byval entries As Integer, _
                                 Byval pal As Long)

Declare Sub      uglPalGetBuff  alias "uglPalGet" (Byval idx As Integer, _
                                 Byval entries As Integer, _
                                 Seg pal As tRGB)

Declare Function uglPalLoad&    (flname As String, _
                                 Byval fmt As Integer)


Declare Sub      uglPalUsingLin (byval linpal as integer)



Declare Function uglPalBestFit%	(Byval pal As Long, _
								 Byval r As Integer, _
								 Byval g As Integer, _
								 Byval b As Integer)

Declare Function uglPalBestFitBuff%	alias "uglPalBestFit" (Seg pal As tRGB, _
								 Byval r As Integer, _
								 Byval g As Integer, _
								 Byval b As Integer)



Declare Sub      uglPalFade     (Byval pal As Long, _
								 Byval idx As Integer, _
                                 Byval entries As Integer, _
                                 Byval factor As Integer )

Declare Sub      uglPalFadeBuff alias "uglPalFade" (Seg pal As tRGB, _
								 Byval idx As Integer, _
                                 Byval entries As Integer, _
                                 Byval factor As Integer )

Declare Sub      uglPalFadeIn   (Byval pal As Long, _
								 Byval idx As Integer, _
                                 Byval entries As Integer, _
                                 Byval msecs As Long, _
                                 byval blocking as integer)

Declare Sub      uglPalFadeInBuff alias "uglPalFadeIn" (Seg pal As tRGB, _
								 Byval idx As Integer, _
                                 Byval entries As Integer, _
                                 Byval msecs As Long, _
                                 byval blocking as integer)

Declare Sub      uglPalFadeOut   (Byval pal As Long, _
								 Byval idx As Integer, _
                                 Byval entries As Integer, _
                                 Byval msecs As Long, _
                                 byval blocking as integer)

Declare Sub      uglPalFadeOutBuff alias "uglPalFadeOut" (Seg pal As tRGB, _
								 Byval idx As Integer, _
                                 Byval entries As Integer, _
                                 Byval msecs As Long, _
                                 byval blocking as integer)

Declare Sub		uglPalClear		(Byval idx As Integer, _
                                 Byval entries As Integer, _
								 Byval red As Integer, _
								 Byval green As Integer, _
								 Byval blue As Integer )

Declare Function uglPalFaded%   ( )
