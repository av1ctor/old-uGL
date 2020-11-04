''
'' ugl.bi -- UGL routines
''

Const UGL.TRUE%     = -1%
Const UGL.FALSE%    = 0%

Const DCTSIZE%      = 64%
'' dc types:
Const UGL.MEM%      = 0% * DCTSIZE%
Const UGL.BNK%      = 1% * DCTSIZE%
Const UGL.EMS%      = 2% * DCTSIZE%
Const UGL.XMS%      = 3% * DCTSIZE%

Const FMTSIZE%      = 128%
'' color formats:
Const UGL.8BIT%     = 0% * FMTSIZE%
Const UGL.15BIT%    = 1% * FMTSIZE%
Const UGL.16BIT%    = 2% * FMTSIZE%
Const UGL.32BIT%    = 3% * FMTSIZE%

'' buffer formats for uglRow Read/Write/SetPal routines
Const UGL.BF.8BIT%  = 0% * 2%
Const UGL.BF.15BIT% = 1% * 2%
Const UGL.BF.16BIT% = 2% * 2%
Const UGL.BF.32BIT% = 3% * 2%
Const UGL.BF.24BIT% = 4% * 2%
Const UGL.BF.IDX1%  = 5% * 2%
Const UGL.BF.IDX4%  = 6% * 2%
Const UGL.BF.IDX8%  = 7% * 2%

'' flipping modes:
Const UGL.VFLIP%    = 1%
Const UGL.HFLIP%    = 2%
Const UGL.VHFLIP%   = UGL.VFLIP% or UGL.HFLIP%
Const UGL.HVFLIP%	= UGL.VHFLIP%

'' Mask modes for uglTriT and uglQuadT
const UGL.MASK.FALSE = 0
const UGL.MASK.TRUE  = 2

'' uglNew/PutBMPEx options:
Const BMPOPT.NOOPT% = &h0000%
Const BMPOPT.NO332% = &h0100%
Const BMPOPT.MASK%  = &h0200%

Type CLIPRECT
        xMin    As Integer
        yMin    As Integer
        xMax    As Integer
        yMax    As Integer
End Type

'' uglDCget's struct
Type TDC
        fmt     As Integer                      '' color format (8BIT..32BIT)
        typ     As Integer                      '' type (MEM, EMS, BNK)

        bpp     As String * 1                   '' bits per pixel
        p2b     As String * 1                   '' pixel to byte conversion
        xRes    As Integer                      '' width
        yRes    As Integer                      '' height
        bps     As Integer                      '' bytes per scanline
        pages   As Integer                      '' (only for BNK DCs)
        startSL As Integer                      '' / start scanline
        size    As Long                         '' yRes * bps

        cr      As CLIPRECT                     '' clipping rectangle
End Type

'' uglPoly*'s struct
type PNT2D
        x       As Integer
        y       As Integer
End Type

Type PNT3D
        x       As Single
        y       As Single
        z       As Single
End Type

'' uglFxPoly*'s struct
type PNT2DF
        x       As Long
        y       As Long
End Type

'' uglQuadricBez's struct
Type QUADBEZ
        a       As PNT2D
        b       As PNT2D
        c       As PNT2D
End Type

'' uglCubicBez's struct
Type CUBICBEZ
        a       As PNT2D
        b       As PNT2D
        c       As PNT2D
        d       As PNT2D
End Type

Type RECT
        x1      As Integer
        y1      As Integer
        x2      As Integer
        y2      As Integer
End Type

'' uglTri#/Quad#'s structs
type vector2i
        x       as integer
        y       as integer
        u       as integer
        v       as integer
        r       as integer
        g       as integer
        b       as integer
end type

type vector3f
        x       as single
        y       as single
        z       as single
        u       as single
        v       as single
        r       as single
        g       as single
        b       as single
end type

type TriType
        v1 as vector3f
        v2 as vector3f
        v3 as vector3f
end type

type QuadType
        v1 as vector3f
        v2 as vector3f
        v3 as vector3f
        v4 as vector3f
end type


Declare Function uglInit%       ()

Declare Sub      uglEnd         ()

Declare Sub      uglRestore     ()

Declare Sub      uglVersion     (major As Integer, _
                                 minor As Integer, _
                                 stable As Integer, _
                                 build As Integer)

Declare Function uglSetVideoDC& (Byval fmt As Integer, _
                                 Byval xRes As Integer, _
                                 Byval yRes As Integer, _
                                 Byval vidPages As Integer)

Declare Function uglGetVideoDC& ()

Declare Sub      uglSetVisPage  (Byval visPage As Integer)

Declare Sub      uglSetWrkPage  (Byval wrkPage As Integer)


Declare Function uglNew&        (Byval typ As Integer, _
                                 Byval fmt As Integer, _
                                 Byval xRes As Integer, _
                                 Byval yRes As Integer)

Declare Function uglNewMult%    (dcArray() As Long, _
                                 Byval dcs As Integer, _
                                 Byval typ As Integer, _
                                 Byval fmt As Integer, _
                                 Byval xRes As Integer, _
                                 Byval yRes As Integer)

Declare Function uglNewBMP&     (Byval typ As Integer, _
                                 Byval fmt As Integer, _
                                 flname As string)

Declare Function uglNewBMPEx&   (Byval typ As Integer, _
                                 Byval fmt As Integer, _
                                 flname As string, _
                                 Byval opt As Integer)

Declare Sub      uglDel         (Seg dc As Long)

Declare Sub      uglDelMult     (dcArray() As Long)


Declare Sub      uglSetClipRect (Byval dc As Long, _
                                 Seg cr As CLIPRECT)

Declare Sub      uglGetClipRect (Byval dc As Long, _
                                 Seg cr As CLIPRECT)

Declare Sub      uglGetSetClipRect _
                                (Byval dc As Long, _
                                 Seg inCr As CLIPRECT, _
                                 Seg outCr As CLIPRECT)

Declare Sub      uglDCGet       (Byval dc As Long, _
                                 Seg dcInfo As TDC)

Declare Function uglDCAccessRd& (Byval dc As Long, _
                                 Byval y As Integer)

Declare Function uglDCAccessWr& (Byval dc As Long, _
                                 Byval y As Integer)

Declare Function uglDCAccessRdWr& (Byval dc As Long, _
                                 Byval y As Integer, _
                                 rdPtr As Long)


Declare Function uglColor32&    (Byval red As Integer, _
                                 Byval green As Integer, _
                                 Byval blue As Integer)

Declare Function uglColor16&    (Byval red As Integer, _
                                 Byval green As Integer, _
                                 Byval blue As Integer)

Declare Function uglColor15&    (Byval red As Integer, _
                                 Byval green As Integer, _
                                 Byval blue As Integer)

Declare Function uglColor8&     (Byval red As Integer, _
                                 Byval green As Integer, _
                                 Byval blue As Integer)

Declare Function uglColor&      (Byval fmt As Integer, _
                                 Byval red As Integer, _
                                 Byval green As Integer, _
                                 Byval blue As Integer)

Declare Function uglColors&     (Byval fmt As Integer)

Declare Function uglColorsEx&   (Byval dc As Long)


Declare Sub      uglPSet        (Byval dc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval clr As long)

Declare Function uglPGet&       (Byval dc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer)


Declare Sub      uglHLine       (Byval dc As Long, _
                                 Byval x1 As Integer, _
                                 Byval y As Integer, _
                                 Byval x2 As Integer, _
                                 Byval clr As long)

Declare Sub      uglVLine       (Byval dc As Long, _
                                 Byval x As Integer, _
                                 Byval y1 As Integer, _
                                 Byval y2 As Integer, _
                                 Byval clr As long)

Declare Sub      uglLine        (Byval dc As Long, _
                                 Byval x1 As Integer, _
                                 Byval y1 As Integer, _
                                 Byval x2 As Integer, _
                                 Byval y2 As Integer, _
                                 Byval clr As long)


Declare Sub      uglRect        (Byval dc As Long, _
                                 Byval x1 As Integer, _
                                 Byval y1 As Integer, _
                                 Byval x2 As Integer, _
                                 Byval y2 As Integer, _
                                 Byval clr As Long)

Declare Sub      uglRectF       (Byval dc As Long, _
                                 Byval x1 As Integer, _
                                 Byval y1 As Integer, _
                                 Byval x2 As Integer, _
                                 Byval y2 As Integer, _
                                 Byval clr As Long)


Declare Sub      uglCircle      (Byval dc As Long, _
                                 Byval cx As Integer, _
                                 Byval cy As Integer, _
                                 Byval radius As Long, _
                                 Byval clr As long)

Declare Sub      uglCircleF     (Byval dc As Long, _
                                 Byval cx As Integer, _
                                 Byval cy As Integer, _
                                 Byval radius As Long, _
                                 Byval clr As long)

Declare Sub      uglEllipse     (Byval dc As Long, _
                                 Byval cx As Integer, _
                                 Byval cy As Integer, _
                                 Byval rx As Integer, _
                                 Byval ry As Integer, _
                                 Byval clr As long)

Declare Sub      uglEllipseF    (Byval dc As Long, _
                                 Byval cx As Integer, _
                                 Byval cy As Integer, _
                                 Byval rx As Integer, _
                                 Byval ry As Integer, _
                                 Byval clr As long)


Declare Sub      uglPoly        (Byval dc As Long, _
                                 Seg pntArray As PNT2D, _
                                 Byval points As Integer, _
                                 Byval clr As Long)

Declare Sub      uglPolyF       (Byval dc As Long, _
                                 Seg pntArray As PNT2D, _
                                 Byval points As Integer, _
                                 Byval clr As Long)

Declare Sub      uglPolyPoly    (Byval dc As Long, _
                                 Seg pntArray As PNT2D, _
                                 Seg cntArray As Integer, _
                                 Byval polygons As Integer, _
                                 Byval clr As Long)

Declare Sub      uglPolyPolyF   (Byval dc As Long, _
                                 Seg pntArray As PNT2D, _
                                 Seg cntArray As Integer, _
                                 Byval points As Integer, _
                                 Byval polygons As Integer, _
                                 Byval clr As Long)

Declare Sub      uglFxPoly      (Byval dc As Long, _
                                 Seg pntArray As PNT2DF, _
                                 Byval points As Integer, _
                                 Byval clr As Long)

Declare Sub      uglFxPolyF     (Byval dc As Long, _
                                 Seg pntArray As PNT2DF, _
                                 Byval points As Integer, _
                                 Byval clr As Long)

Declare Sub      uglFxPolyPoly  (Byval dc As Long, _
                                 Seg pntArray As PNT2DF, _
                                 Seg cntArray As Integer, _
                                 Byval polygons As Integer, _
                                 Byval clr As Long)

Declare Sub      uglFxPolyPolyF (Byval dc As Long, _
                                 Seg pntArray As PNT2DF, _
                                 Seg cntArray As Integer, _
                                 Byval points As Integer, _
                                 Byval polygons As Integer, _
                                 Byval clr As Long)


Declare Sub      uglQuadricBez  (Byval dc As Long, _
                                 Seg cbz As QUADBEZ, _
                                 Byval levels As Integer, _
                                 Byval clr As long)

Declare Sub      uglCubicBez    (Byval dc As Long, _
                                 Seg cbz As CUBICBEZ, _
                                 Byval levels As Integer, _
                                 Byval clr As long)


Declare Sub      uglClear       (Byval dc As Long, _
                                 Byval clr As Long)


Declare Sub      uglRowRead     (Byval dc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval pixels As Integer, _
                                 Byval bufferFmt As Integer, _
                                 Byval buffer As Long)

Declare Sub      uglRowReadBuff	Alias "uglRowRead" (Byval dc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval pixels As Integer, _
                                 Byval bufferFmt As Integer, _
                                 Byval buffer As Long)

Declare Sub      uglRowWrite    (Byval dc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval pixels As Integer, _
                                 Byval bufferFmt As Integer, _
                                 Byval buffer As Long)

Declare Sub      uglRowWriteBuff Alias "uglRowWrite" (Byval dc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval pixels As Integer, _
                                 Byval bufferFmt As Integer, _
                                 Seg buffer As Any)

Declare Sub      uglRowWriteEx  (Byval dc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval pixels As Integer, _
                                 Byval bufferFmt As Integer, _
                                 Byval buffer As Long, _
                                 Byval opt As Integer)

Declare Sub      uglRowSetPal   (Byval dcFmt As Integer, _
                                 Byval bufferFmt As Integer, _
                                 Byval pallete As Long, _
                                 Byval entries As Integer)


Declare Sub      uglGet         (Byval srcDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval dstDc As Long)

Declare Sub      uglGetConv     (Byval srcDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval dstDc As Long)

Declare Sub      uglPut         (Byval dstDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval srcDc As Long)

Declare Sub      uglPutFlip     (Byval dstDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval mode As Integer, _
                                 Byval srcDc As Long)

declare sub      uglPutRot      (Byval dstDC As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval angle As Single, _
                                 Byval srcDC As Long )

declare sub      uglPutScl      (Byval dstDC As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval xScale As Single, _
                                 Byval yScale As Single, _
                                 Byval srcDC As Long )

declare sub      uglPutFlipScl  (Byval dstDC As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval xScale As Single, _
                                 Byval yScale As Single, _
                                 Byval mode As Integer, _
                                 Byval srcDC As Long )

declare sub      uglPutRotScl   (Byval dstDC As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval angle As Single, _
                                 Byval xScale As Single, _
                                 Byval yScale As Single, _
                                 Byval srcDC As Long )

Declare Sub      uglPutAB       (Byval dstDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval alpha As Integer, _
                                 Byval srcDc As Long)

Declare Sub      uglPutABFlip   (Byval dstDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval alpha As Integer, _
                                 Byval mode As Integer, _
                                 Byval srcDc As Long)

Declare Sub      uglPutConv     (Byval dstDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval srcDc As Long)

Declare Sub      uglPutMsk      (Byval dstDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval srcDc As Long)

Declare Sub      uglPutMskFlip  (Byval dstDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval mode As Integer, _
                                 Byval srcDc As Long)

declare sub      uglPutMskRot   (Byval dstDC As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval angle As Single, _
                                 Byval srcDC As Long )

declare sub      uglPutMskScl   (Byval dstDC As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval xScale As Single, _
                                 Byval yScale As Single, _
                                 Byval srcDC As Long )

declare sub      uglPutMskFlipScl (Byval dstDC As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval xScale As Single, _
                                 Byval yScale As Single, _
                                 Byval mode As Integer, _
                                 Byval srcDC As Long )

declare sub      uglPutMskRotScl(Byval dstDC As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval angle As Single, _
                                 Byval xScale As Single, _
                                 Byval yScale As Single, _
                                 Byval srcDC As Long )

Declare Sub      uglPutMskAB    (Byval dstDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval alpha As Integer, _
                                 Byval srcDc As Long)

Declare Sub      uglPutMskABFlip(Byval dstDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval alpha As Integer, _
                                 Byval mode As Integer, _
                                 Byval srcDc As Long)

Declare Sub      uglPutMskConv  (Byval dstDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval srcDc As Long)

Declare Function uglPutBMP%     (Byval dstDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 flname As string)

Declare Function uglPutBMPEx%   (Byval dstDc As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 flname As string, _
                                 Byval opt As Integer)


Declare Sub      uglBlit		(byval dst as long, _
								 byval x as integer, _
								 byval y as integer, _
								 byval src as long, _
								 byval px as integer, _
								 byval py as integer, _
								 byval wdt as integer, _
								 byval hgt as integer)

Declare Sub      uglBlitMsk		(byval dst as long, _
								 byval x as integer, _
								 byval y as integer, _
								 byval src as long, _
								 byval px as integer, _
								 byval py as integer, _
								 byval wdt as integer, _
								 byval hgt as integer)

Declare Sub      uglBlitScl		(byval dst as long, _
								 byval x as integer, _
								 byval y as integer, _
                                 Byval xScale As Single, _
                                 Byval yScale As Single, _
								 byval src as long, _
								 byval px as integer, _
								 byval py as integer, _
								 byval wdt as integer, _
								 byval hgt as integer)

Declare Sub      uglBlitMskScl	(byval dst as long, _
								 byval x as integer, _
								 byval y as integer, _
                                 Byval xScale As Single, _
                                 Byval yScale As Single, _
								 byval src as long, _
								 byval px as integer, _
								 byval py as integer, _
								 byval wdt as integer, _
								 byval hgt as integer)

Declare Sub      uglBlitFlipScl	(byval dst as long, _
								 byval x as integer, _
								 byval y as integer, _
                                 Byval xScale As Single, _
                                 Byval yScale As Single, _
								 byval mode as integer, _
								 byval src as long, _
								 byval px as integer, _
								 byval py as integer, _
								 byval wdt as integer, _
								 byval hgt as integer)

Declare Sub      uglBlitMskFlipScl (byval dst as long, _
								 byval x as integer, _
								 byval y as integer, _
                                 Byval xScale As Single, _
                                 Byval yScale As Single, _
								 byval mode as integer, _
								 byval src as long, _
								 byval px as integer, _
								 byval py as integer, _
								 byval wdt as integer, _
								 byval hgt as integer)

Declare Sub      uglBlitRotScl	(byval dst as long, _
								 byval x as integer, _
								 byval y as integer, _
								 Byval angle As Single, _
                                 Byval xScale As Single, _
                                 Byval yScale As Single, _
								 byval src as long, _
								 byval px as integer, _
								 byval py as integer, _
								 byval wdt as integer, _
								 byval hgt as integer)

Declare Sub      uglBlitMskRotScl (byval dst as long, _
								 byval x as integer, _
								 byval y as integer, _
								 Byval angle As Single, _
                                 Byval xScale As Single, _
                                 Byval yScale As Single, _
								 byval src as long, _
								 byval px as integer, _
								 byval py as integer, _
								 byval wdt as integer, _
								 byval hgt as integer)


Declare sub      uglTriF        (Byval dc As Long, _
                                 seg vtx As TriType, _
                                 Byval col As Long)

Declare Sub      uglTriG        (Byval dc As Long, _
                                 seg vtx As TriType)

Declare Sub      uglTriT        (Byval dstDC As Long, _
                                 seg vtx As TriType, _
                                 Byval mask As Integer, _
                                 Byval srcDC As Long)

Declare Sub      uglTriTP       (Byval dstDC As Long, _
                                 seg vtx As TriType, _
                                 Byval mask As Integer, _
                                 Byval srcDC As Long)

Declare Sub      uglTriTG       (Byval dstDC As Long, _
                                 seg vtx As TriType, _
                                 Byval mask As Integer, _
                                 Byval srcDC As Long)

Declare Sub      uglTriTPG      (Byval dstDC As Long, _
                                 seg vtx As TriType, _
                                 Byval mask As Integer, _
                                 Byval srcDC As Long)

Declare Sub      uglQuadF       (Byval dc As Long, _
                                 seg vtx As QuadType, _
                                 Byval col As Long)

Declare Sub      uglQuadT       (Byval dstDC As Long, _
                                 seg vtx As QuadType, _
                                 Byval mask As Integer, _
                                 Byval srcDC As Long)

Declare Sub      uglSetLUT 		(byval lut as long)



'' some constants for commonly used colors
Const REDP32&   = 65536&                        '' 2^16
Const GREENP32& = 256&                          '' 2^8
Const BLUEP32&  = 1&                            '' 2^0

Const REDP16&   = 2048&                         '' 2^11
Const GREENP16& = 32&                           '' 2^5
Const BLUEP16&  = 1&                            '' 2^0

Const REDP15&   = 1024&                         '' 2^10
Const GREENP15& = 32&                           '' 2^5
Const BLUEP15&  = 1&                            '' 2^0

Const REDP8&    = 32&                           '' 2^5
Const GREENP8&  = 4&                            '' 2^2
Const BLUEP8&   = 1&                            '' 2^0

Const UGL.BLACK32&      = (&h00&*REDP32)+(&h00&*GREENP32)+(&h00&*BLUEP32)
Const UGL.BLUE32&       = (&h00&*REDP32)+(&h00&*GREENP32)+(&hA8&*BLUEP32)
Const UGL.GREEN32&      = (&h00&*REDP32)+(&hA8&*GREENP32)+(&h00&*BLUEP32)
Const UGL.CYAN32&       = (&h00&*REDP32)+(&hA8&*GREENP32)+(&hA8&*BLUEP32)
Const UGL.RED32&        = (&hA8&*REDP32)+(&h00&*GREENP32)+(&h00&*BLUEP32)
Const UGL.MAGENTA32&    = (&hA8&*REDP32)+(&h00&*GREENP32)+(&hA8&*BLUEP32)
Const UGL.BROWN32&      = (&hA8&*REDP32)+(&h54&*GREENP32)+(&h00&*BLUEP32)
Const UGL.WHITE32&      = (&hA8&*REDP32)+(&hA8&*GREENP32)+(&hA8&*BLUEP32)
Const UGL.GREY32&       = (&h54&*REDP32)+(&h54&*GREENP32)+(&h54&*BLUEP32)
Const UGL.LBLUE32&      = (&h54&*REDP32)+(&h54&*GREENP32)+(&hFF&*BLUEP32)
Const UGL.LGREEN32&     = (&h54&*REDP32)+(&hFF&*GREENP32)+(&h54&*BLUEP32)
Const UGL.LCYAN32&      = (&h54&*REDP32)+(&hFF&*GREENP32)+(&hFF&*BLUEP32)
Const UGL.LRED32&       = (&hFF&*REDP32)+(&h54&*GREENP32)+(&h54&*BLUEP32)
Const UGL.LMAGENTA32&   = (&hFF&*REDP32)+(&h54&*GREENP32)+(&hFF&*BLUEP32)
Const UGL.YELLOW32&     = (&hFF&*REDP32)+(&hFF&*GREENP32)+(&h54&*BLUEP32)
Const UGL.BWHITE32&     = (&hFF&*REDP32)+(&hFF&*GREENP32)+(&hFF&*BLUEP32)
Const UGL.BPINK32&      = (&hFF&*REDP32)+(&h00&*GREENP32)+(&hFF&*BLUEP32)

Const UGL.BLACK16&      = (&h00&*REDP16)+(&h00&*GREENP16)+(&h00&*BLUEP16)
Const UGL.BLUE16&       = (&h00&*REDP16)+(&h00&*GREENP16)+(&h15&*BLUEP16)
Const UGL.GREEN16&      = (&h00&*REDP16)+(&h2A&*GREENP16)+(&h00&*BLUEP16)
Const UGL.CYAN16&       = (&h00&*REDP16)+(&h2A&*GREENP16)+(&h15&*BLUEP16)
Const UGL.RED16&        = (&h15&*REDP16)+(&h00&*GREENP16)+(&h00&*BLUEP16)
Const UGL.MAGENTA16&    = (&h15&*REDP16)+(&h00&*GREENP16)+(&h15&*BLUEP16)
Const UGL.BROWN16&      = (&h15&*REDP16)+(&h15&*GREENP16)+(&h00&*BLUEP16)
Const UGL.WHITE16&      = (&h15&*REDP16)+(&h2A&*GREENP16)+(&h15&*BLUEP16)
Const UGL.GREY16&       = (&h0A&*REDP16)+(&h15&*GREENP16)+(&h0A&*BLUEP16)
Const UGL.LBLUE16&      = (&h0A&*REDP16)+(&h15&*GREENP16)+(&h1F&*BLUEP16)
Const UGL.LGREEN16&     = (&h0A&*REDP16)+(&h3F&*GREENP16)+(&h0A&*BLUEP16)
Const UGL.LCYAN16&      = (&h0A&*REDP16)+(&h3F&*GREENP16)+(&h1F&*BLUEP16)
Const UGL.LRED16&       = (&h1F&*REDP16)+(&h15&*GREENP16)+(&h0A&*BLUEP16)
Const UGL.LMAGENTA16&   = (&h1F&*REDP16)+(&h15&*GREENP16)+(&h1F&*BLUEP16)
Const UGL.YELLOW16&     = (&h1F&*REDP16)+(&h3F&*GREENP16)+(&h0A&*BLUEP16)
Const UGL.BWHITE16&     = (&h1F&*REDP16)+(&h3F&*GREENP16)+(&h1F&*BLUEP16)
Const UGL.BPINK16&      = (&h1F&*REDP16)+(&h00&*GREENP16)+(&h1F&*BLUEP16)

Const UGL.BLACK15&      = (&h00&*REDP15)+(&h00&*GREENP15)+(&h00&*BLUEP15)
Const UGL.BLUE15&       = (&h00&*REDP15)+(&h00&*GREENP15)+(&h15&*BLUEP15)
Const UGL.GREEN15&      = (&h00&*REDP15)+(&h15&*GREENP15)+(&h00&*BLUEP15)
Const UGL.CYAN15&       = (&h00&*REDP15)+(&h15&*GREENP15)+(&h15&*BLUEP15)
Const UGL.RED15&        = (&h15&*REDP15)+(&h00&*GREENP15)+(&h00&*BLUEP15)
Const UGL.MAGENTA15&    = (&h15&*REDP15)+(&h00&*GREENP15)+(&h15&*BLUEP15)
Const UGL.BROWN15&      = (&h15&*REDP15)+(&h0A&*GREENP15)+(&h00&*BLUEP15)
Const UGL.WHITE15&      = (&h15&*REDP15)+(&h15&*GREENP15)+(&h15&*BLUEP15)
Const UGL.GREY15&       = (&h0A&*REDP15)+(&h0A&*GREENP15)+(&h0A&*BLUEP15)
Const UGL.LBLUE15&      = (&h0A&*REDP15)+(&h0A&*GREENP15)+(&h1F&*BLUEP15)
Const UGL.LGREEN15&     = (&h0A&*REDP15)+(&h1F&*GREENP15)+(&h0A&*BLUEP15)
Const UGL.LCYAN15&      = (&h0A&*REDP15)+(&h1F&*GREENP15)+(&h1F&*BLUEP15)
Const UGL.LRED15&       = (&h1F&*REDP15)+(&h0A&*GREENP15)+(&h0A&*BLUEP15)
Const UGL.LMAGENTA15&   = (&h1F&*REDP15)+(&h0A&*GREENP15)+(&h1F&*BLUEP15)
Const UGL.YELLOW15&     = (&h1F&*REDP15)+(&h1F&*GREENP15)+(&h0A&*BLUEP15)
Const UGL.BWHITE15&     = (&h1F&*REDP15)+(&h1F&*GREENP15)+(&h1F&*BLUEP15)
Const UGL.BPINK15&      = (&h1F&*REDP15)+(&h00&*GREENP15)+(&h1F&*BLUEP15)

Const UGL.BLACK8&       = (&h00&*REDP8)+(&h00&*GREENP8)+(&h00&*BLUEP8)
Const UGL.BLUE8&        = (&h00&*REDP8)+(&h00&*GREENP8)+(&h02&*BLUEP8)
Const UGL.GREEN8&       = (&h00&*REDP8)+(&h05&*GREENP8)+(&h00&*BLUEP8)
Const UGL.CYAN8&        = (&h00&*REDP8)+(&h05&*GREENP8)+(&h02&*BLUEP8)
Const UGL.RED8&         = (&h05&*REDP8)+(&h00&*GREENP8)+(&h00&*BLUEP8)
Const UGL.MAGENTA8&     = (&h05&*REDP8)+(&h00&*GREENP8)+(&h02&*BLUEP8)
Const UGL.BROWN8&       = (&h05&*REDP8)+(&h02&*GREENP8)+(&h00&*BLUEP8)
Const UGL.WHITE8&       = (&h05&*REDP8)+(&h05&*GREENP8)+(&h02&*BLUEP8)
Const UGL.GREY8&        = (&h02&*REDP8)+(&h02&*GREENP8)+(&h01&*BLUEP8)
Const UGL.LBLUE8&       = (&h02&*REDP8)+(&h02&*GREENP8)+(&h03&*BLUEP8)
Const UGL.LGREEN8&      = (&h02&*REDP8)+(&h07&*GREENP8)+(&h01&*BLUEP8)
Const UGL.LCYAN8&       = (&h02&*REDP8)+(&h07&*GREENP8)+(&h03&*BLUEP8)
Const UGL.LRED8&        = (&h07&*REDP8)+(&h02&*GREENP8)+(&h01&*BLUEP8)
Const UGL.LMAGENTA8&    = (&h07&*REDP8)+(&h02&*GREENP8)+(&h03&*BLUEP8)
Const UGL.YELLOW8&      = (&h07&*REDP8)+(&h07&*GREENP8)+(&h01&*BLUEP8)
Const UGL.BWHITE8&      = (&h07&*REDP8)+(&h07&*GREENP8)+(&h03&*BLUEP8)
Const UGL.BPINK8&       = (&h07&*REDP8)+(&h00&*GREENP8)+(&h03&*BLUEP8)
