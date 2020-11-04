''
'' bmp.bas -- BMP loading ex
''

DefInt A-Z
'$Include: '..\inc\ugl.bi'
'$Include: '..\inc\kbd.bi'
'$Include: '..\inc\2dfx.bi'
'$Include: '..\inc\pal.bi'
'$Include: '..\inc\dos.bi'

Const xRes = 320*1
Const yRes = 200*1

Const cFmtSrc = UGL.8BIT
Const cFmtDst = UGL.8BIT

Const wStep = 1
Const hStep = 1

Declare Sub ExitError (msg As String)
DECLARE Function changePal&( factor as integer )

'':::
    Dim kbd As TKBD
    Dim video As Long
    Dim bmp As Long, bmpDC as TDC
    Dim flname As String
    dim bg as long

    If (Len(Command$) = 0) Then
        Print "usage: bmp filename (w/out .bmp extension)"
        Print "           or an UAR (PAK) archive: arc_path\arc_file.pak::filepath/somebmp"
        End
    Else
        flname = Command$ + ".bmp"
    End If

    '' initialize
    If (Not uglInit) Then ExitError "Init"

    '' load the BMP
    bmp = uglNewBMPEx(UGL.XMS, cFmtSrc, flname, BMPOPT.NO332)
    If (bmp = 0) Then ExitError "BMPload"

    uglDCget bmp, bmpDC

    '' change video-mode
    video = uglSetVideoDC(cFmtDst, xRes, yRes, 1)
    If (video = 0) Then ExitError "SetVideoDC"

    '' show it
    kbdInit kbd

    bg = uglColor( cFmtDst, 255, 0, 0 )


	dim clut as long
	if( cFmtSrc = UGL.8BIT ) then
		clut = changePal( 128 )
	end if


    uglClear video, bg

    x = (xRes\2) - (bmpDC.xRes\2)
    y = (yRes\2) - (bmpDC.yRes\2)
    moved = -1
    px= 10
    py = 10
    wdt = 64
    hgt = 64
    Do
        if (kbd.pgup) Then
        	'do while( kbd.pgup ): loop
        	moved = -1
        	wdt = wdt + 1
        	hgt = hgt + 1
        elseif (kbd.pgdw) Then
        	'do while( kbd.pgdw ): loop
        	moved = -1
        	if( wdt > 1 ) then wdt = wdt - 1
        	if( hgt > 1 ) then hgt = hgt - 1
        end if

        If (kbd.d) Then
        	'do while( kbd.d ): loop
        	moved = -1
        	px = px + 1
        elseif (kbd.a) Then
        	'do while( kbd.a ): loop
        	moved = -1
        	''if( px > 1 ) then
        	px = px - 1
        end if

        If (kbd.w) Then
        	'do while( kbd.w ): loop
        	moved = -1
        	''if( py > 1 ) then
        	py = py - 1
        elseif (kbd.s) Then
        	'do while( kbd.s ): loop
        	moved = -1
        	py = py + 1
        end if

        If (kbd.left) Then
            moved = -1
            uglRectF video, x+bmpDc.xRes-wStep, y, _
                            x+bmpDc.xRes-1, y+bmpDc.yRes-1, bg
            x = x - wStep
            If (x + bmpDc.xRes-1 < 0) Then x = xRes-1 + (x + (bmpDc.xRes-1))
        Elseif (kbd.right) Then
            moved = -1
            uglRectF video, x, y, x+wStep, y+bmpDc.yRes-1, bg
            x = x + wStep
            If (x > xRes-1) Then x = -bmpDc.xRes + (x - (xRes-1))
        End If
        If (kbd.up) Then
            moved = -1
            uglRectF video, x, y+bmpDc.yRes-hStep, _
                            x+bmpDc.xRes-1, y+bmpDc.yRes-1, bg
            y = y - hStep
            If (y + bmpDc.yRes-1 < 0) Then y = yRes-1 + (y + (bmpDc.yRes-1))
        Elseif (kbd.down) Then
            moved = -1
            uglRectF video, x, y, x+bmpDc.xRes-1, y+hStep, bg
            y = y + hStep
            If (y > yRes-1) Then y = -bmpDc.yRes + (y - (yRes-1))
        End If

        If (moved) Then
            moved = 0

            uglClear video, bg

			uglRect video, x, y, x+bmpDC.xRes-1, y+bmpDC.yRes-1, 0
			'uglBlitMsk video, x, y, bmp, px, py, wdt, hgt

			tfxBlitBlit video, x, y, bmp, px, py, wdt, hgt, TFX.SPRITE

        End If
    Loop Until (kbd.esc)

    uglRestore
    uglEnd
    End

'':::
Sub ExitError (msg As String)
    uglRestore
    uglEnd
    Print "ERROR! "; msg
    End
End Sub

'':::::::::::::::::
function changePal&( factor as integer )
	dim ofs as long
	dim pal(0 to 255) as tRGB
	dim clut as long

	uglPalGetBuff 0, 256, pal(0)

	clut = memAlloc( 256 * 4 )

	def seg = clut \ &h10000&
	ofs = clut and &h0000FFFF&
	for i = 0 to 255
		b = (asc( pal(255-i).blue  ) * 256) \ 256
		g = (asc( pal(255-i).green ) * 256) \ 256
		r = (asc( pal(255-i).red   ) * 256) \ 256
		poke ofs+0, b
		poke ofs+1, g
		poke ofs+2, r
		ofs = ofs + 4
	next i

	changePal = clut
end function

