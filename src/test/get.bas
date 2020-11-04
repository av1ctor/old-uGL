DEFINT A-Z
'$INCLUDE: '..\..\inc\ugl.bi'

CONST xRes = 320
CONST yRes = 200
CONST cFmt = UGL.8BIT

DECLARE SUB fillOffScr (offScr AS LONG)
DECLARE SUB ExitError (msg AS STRING)

'':::
		DIM video AS LONG
		DIM emsOffScrBuff AS LONG, memOffScrBuff AS LONG
		DIM myGet AS LONG
	
		'' initialize
		IF (NOT uglInit) THEN ExitError "Init"
	
		'' allocate EMS off screen buff
		emsOffScrBuff = uglNew(UGL.EMS, cFmt, xRes, yRes)
		IF (emsOffScrBuff = 0) THEN ExitError "New EMS offScr"

		'' allocate MEM off screen buff
		memOffScrBuff = uglNew(UGL.MEM, cFmt, xRes, yRes)
		IF (memOffScrBuff = 0) THEN ExitError "New MEM offScr"

	'' change video-mode
		video = uglSetVideoDC(cFmt, xRes, yRes, 1)
		IF (video = 0) THEN ExitError "SetVideoDC"
	
		'' fill 'em
		fillOffScr emsOffScrBuff
		fillOffScr memOffScrBuff

		'' show 'em
		uglPut video, 0, 0, emsOffScrBuff
		SLEEP
		uglPut video, 0, 0, memOffScrBuff
		SLEEP
		uglPut emsOffScrBuff, 0, 0, memOffScrBuff

		myGet = uglNew(UGL.EMS, cFmt, 32, 32)
		RANDOMIZE TIMER
		x = RND * xRes
		y = RND * yRes

		uglGet video, x, y, myGet
		uglRect myGet, 0, 0, 31, 31, -1

		uglRect video, x, y, x + 31, y + 31, 0
		SLEEP

		FOR yy = 0 TO yRes - 1 STEP 32
				FOR xx = 0 TO xRes - 1 STEP 32
						uglPut video, xx, yy, myGet
				NEXT xx
		NEXT yy
		SLEEP

		uglGet memOffScrBuff, x, y, myGet
		uglRect myGet, 0, 0, 31, 31, -1
		FOR yy = 0 TO yRes - 1 STEP 32
				FOR xx = 0 TO xRes - 1 STEP 32
						uglPut video, xx, yy, myGet
				NEXT xx
		NEXT yy
		SLEEP

		uglGet emsOffScrBuff, x, y, myGet
		uglRect myGet, 0, 0, 31, 31, -1
		FOR yy = 0 TO yRes - 1 STEP 32
				FOR xx = 0 TO xRes - 1 STEP 32
						uglPut video, xx, yy, myGet
				NEXT xx
		NEXT yy
		SLEEP

		uglRestore
		uglEnd
		END

'':::
SUB ExitError (msg AS STRING)
		uglRestore
		uglEnd
		PRINT "ERROR! "; msg
		END
END SUB

'':::
SUB fillOffScr (offScr AS LONG)
		uglRectF offScr, 0, 0, xRes - 1, yRes - 1, uglColor(cFmt, 0, 255, 0)

		colors& = uglColors(cFmt)
		RANDOMIZE 0
		FOR i = 0 TO 15
				x1 = RND * xRes
				y1 = RND * yRes
				x2 = RND * xRes
				y2 = RND * yRes
				uglRectF offScr, x1, y1, x2, y2, RND * colors&
				uglRect offScr, x1, y1, x2, y2, -1
		NEXT i
END SUB

