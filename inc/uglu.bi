''
'' uglu.bi -- UGL Util module routines
''

Type QUADBEZ3D
        a       As PNT3D
        b       As PNT3D
        c       As PNT3D
End Type

Type CUBICBEZ3D
        a       As PNT3D
        b       As PNT3D
        c       As PNT3D
        d       As PNT3D
End Type


Declare Sub      ugluSaveTGA	( byval dc as long, _
                        		  filename as string )

Declare Sub      ugluQuadricBez (Seg storage As PNT2D, _
                                 Seg qbz As QUADBEZ, _
                                 Byval levels As Integer)

Declare Sub      ugluQuadricBez3D (Seg storage As any, _
                                   Seg qbz As any, _
                                   Byval levels As Integer)

Declare Sub      ugluCubicBez   (Seg storage As PNT2D, _
                                 Seg cbz As CUBICBEZ, _
                                 Byval levels As Integer)

Declare Sub      ugluCubicBez3D (Seg storage As any, _
                                 Seg cbz As any, _
                                 Byval levels As Integer)

declare function ugluIsMMX%     ( )

declare function ugluIsMMXEx%   ( )

declare function ugluIs3DNow%   ( )

declare function ugluIs3DNowEx% ( )

declare function ugluIsSSE%     ( )

declare function ugluIsSSE2%    ( )