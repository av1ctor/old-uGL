
* angle can be <> 0 but no correct output can be expected (as in GDI)

* v/h aligns are ignored

* fontPrint does like QB's PRINT: expands TAB, new-line, goes to next line if
  passing from right edge of dc's clipping rectangle (it does word breaking 
  tho), orientation: left to right, top to bottom, no justification
  
* fontPrintEx can be configured to fine-tune many parameters:

FONT.FMT.EXPANDTABS  (default)
FONT.FMT.TABSTOP (default: 8)

FONT.FMT.EXTERNALLEADING

FONT.FMT.LEFT 							(default)
FONT.FMT.CENTER
FONT.FMT.RIGHT

FONT.FMT.SINGLELINE
FONT.FMT.TOP							(default)
FONT.FMT.VCENTER						(needs FMT.SINGLELINE)
FONT.FMT.BOTTOM							(needs FMT.SINGLELINE)
FONT.FMT.WORD.ELLIPSIS 					(adds `...' (needs FMT.SINGLELINE))

FONT.FMT.WORDBREAK 						(ignored If FMT.SINGLELINE)

declare fontPrint (dc:dword, x:dword, y:dword, color:dword, font:FONT, text:BASSTR)

declare fontPrintEx (dc:dword, rc:RECT, format:dword, color:dword, font:FONT, text:BASSTR)

	fontPrint video, x, y, uglColor(cFmt, 255, 0, 0), arial, "blah" + chr$(13) + "blah"
		
	dim rc as RECt
	uglGetClipRect video, rc
	rc.xMin = rc.xMin + 32
	rc.yMin = rc.yMin + 32
	rc.xMax = rc.xMax - 32
	rc.yMax = rc.yMax - 32	
	fontPrintEx video, rc, FONT.FMT.JUSTIFY, uglColor(cFmt, 255, 0, 0), "blah blah blah", arial
