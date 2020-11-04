''
''  blitrot.bas - Using uglBlitMskRotScl to rotate and
''                scale just part of a bitmap
''
''
''

DEFINT A-Z
'$INCLUDE: '..\inc\ugl.bi'
'$INCLUDE: '..\inc\kbd.bi'
'$INCLUDE: '..\inc\font.bi'

CONST xRes = 320
CONST yRes = 200
CONST cFmt = UGL.8BIT
CONST FALSE = 0
CONST PAGES = 1


TYPE EnvType
	hFont       AS LONG
	hVideoDC    AS LONG
	hTextrDC    AS LONG
	Keyboard    AS TKBD
	ViewPage    AS INTEGER
	WorkPage    AS INTEGER
END TYPE


DECLARE SUB doMain ()
DECLARE SUB doInit ()
DECLARE SUB doTerminate ()
DECLARE SUB ExitError (msg AS STRING)


	'' Your code goes in doMain ( )

	DIM SHARED Env AS EnvType

	doInit
	doMain
	doTerminate

SUB doInit

	'' Init UGL
	''
	IF (uglInit = FALSE) THEN
		ExitError "0x0000, UGL init failed..."
	END IF


	'' Set video mode with x pages where
	'' x = PAGES
	''
	Env.hVideoDC = uglSetVideoDC(cFmt, xRes, yRes, PAGES)
	IF (Env.hVideoDC = FALSE) THEN ExitError "0x0001, Could not set video mode..."


	'' Init keyboard handler
	''
	kbdInit Env.Keyboard


	'' Load UGL logo
	Env.hTextrDC = uglNewBMP(UGL.MEM, cFmt, "ugl.bmp")
	IF (Env.hTextrDC = FALSE) THEN ExitError "0x0002, Could not load data/ugl.bmp..."

END SUB

SUB doMain
	STATIC angle AS SINGLE, anglek AS SINGLE
	STATIC scale  AS SINGLE, scalek AS SINGLE

	scale = 1
	scalek = .1!
	anglek = 1!

	cx = xres\2
	cy = yres\2

	DO
		'' Clear screen
		'uglClear Env.hVideoDC, 0

		'' Rotate DC
		uglBlitMskRotScl Env.hVideoDC, (cx - 32 * scale) / 2, (cy - 32 * scale) / 2, _
			 						   angle, scale, scale, Env.hTextrDC, 10, 40, 32, 32


		IF (Env.Keyboard.p = FALSE) THEN
			angle = angle + anglek
			scale = scale + scalek

			IF (angle >= 360! AND anglek > 0) THEN
				angle = 0
			ELSEIF (angle <= 0! AND anglek < 0) THEN
				angle = 360
			END IF

			IF (scale >= 10) THEN
				scalek = -scalek
			ELSEIF (scale <= .1) THEN
				scalek = -scalek
			END IF
		END IF

		IF (Env.Keyboard.up) THEN cy = cy - 1
		IF (Env.Keyboard.down) THEN cy = cy + 1
		IF (Env.Keyboard.left) THEN cx = cx - 1
		IF (Env.Keyboard.right) THEN cx = cx + 1



	LOOP UNTIL (Env.Keyboard.Esc)


END SUB

SUB doTerminate

	'' Terminate UGL
	''
	kbdEnd
	uglRestore
	uglEnd

END SUB

SUB ExitError (msg AS STRING)

	'' Terminate UGL
	'
	kbdEnd
	uglRestore
	uglEnd

	'' Print error message
	'' and end
	'
	PRINT "Error: " + msg
	END

END SUB

