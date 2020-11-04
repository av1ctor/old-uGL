''
'' 2dfx.bi -- 2dfx routines
''

'' masking (use when drawing sprites)
const TFX.MASK%		= 1%

'' flip modes:
const TFX.HFLIP% 	= 2%
const TFX.VFLIP%	= 4%
const TFX.HVFLIP%	= 6%
const TFX.VHFLIP%	= TFX.HVFLIP

'' remapping:
const TFX.SCALE%	= 8%

'' color manipulation (use only with sprites):
const TFX.SOLID%	= 32%
const TFX.LUT%		= 64%
const TFX.TEX%		= 96%
const TFX.MONO%		= 128%

'' color manipulation pass 2 (use only with sprites):
const TFX.FACTMUL	= 256%
const TFX.FACTADD	= 512%

'' blend modes:
const TFX.ALPHA%		= 2048%
const TFX.MONOMUL%		= 4096%
const TFX.SATADD%		= 6144%
const TFX.SATSUB%		= 8192%
const TFX.SATADDALPHA%	= 10240%


Declare Sub      tfxBlit        (Byval dstDC As Long, _
                                 Byval x As Integer, _
                                 Byval y As Integer, _
                                 Byval srcDC As Long, _
                                 Byval mode as Integer)

Declare Sub      tfxBlitBlit	(Byval dstDC as Long, _
								 Byval x as Integer, _
								 Byval y as Integer, _
								 Byval srcDC as Long, _
								 Byval px as Integer, _
								 Byval py as Integer, _
								 Byval wdt as Integer, _
								 Byval hgt as Integer, _
								 Byval mode as Integer)

Declare Sub      tfxBlitScl 	(Byval dstDC as Long, _
								 Byval x as Integer, _
								 Byval y as Integer, _
								 Byval srcDC as Long, _
								 Byval xscale as Integer, _
								 Byval yscale as Integer, _
								 Byval mode as Integer)

Declare Sub      tfxBlitBlitScl	(Byval dstDC as Long, _
								 Byval x as Integer, _
								 Byval y as Integer, _
								 Byval srcDC as Long, _
								 Byval px as Integer, _
								 Byval py as Integer, _
								 Byval wdt as Integer, _
								 Byval hgt as Integer, _
								 Byval xscale as Integer, _
								 Byval yscale as Integer, _
								 Byval mode as Integer)


Declare Sub      tfxSetMask 	(Byval red As Integer, _
								 Byval green As Integer, _
								 Byval blue As Integer)

Declare Sub      tfxGetMask 	(red As Integer, _
								 green As Integer, _
								 blue As Integer)


Declare Sub      tfxSetSolid 	(Byval red As Integer, _
								 Byval green As Integer, _
								 Byval blue As Integer)

Declare Sub      tfxGetSolid 	(red As Integer, _
								 green As Integer, _
								 blue As Integer)


Declare Sub      tfxSetAlpha	(Byval alphaLevel As Integer)

Declare Function tfxGetAlpha%	()


Declare Sub      tfxSetLUT		(Byval clut As Long)

Declare Function tfxGetLUT&     ()


Declare Sub      tfxSetFactor 	(Byval redFactor As Integer, _
								 Byval greenFactor As Integer, _
								 Byval blueFactor As Integer)

Declare Sub      tfxGetFactor 	(redFactor As Integer, _
								 greenFactor As Integer, _
								 blueFactor As Integer)

