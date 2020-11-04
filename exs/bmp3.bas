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
Const cFmtDst = UGL.16BIT

Const wStep = 4
Const hStep = 4

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
    bmp = uglNewBMPEx(UGL.MEM, cFmtSrc, flname, BMPOPT.NO332)
    If (bmp = 0) Then ExitError "BMPload"

    uglDCget bmp, bmpDC

    '' change video-mode
    video = uglSetVideoDC(cFmtDst, xRes, yRes, 1)
    If (video = 0) Then ExitError "SetVideoDC"

    '' show it
    kbdInit kbd

    bg = uglColor( cFmtDst, 255, 0, 0 )

    dim cr as CLIPRECT
    cr.xmin = 32
    cr.ymin = 32
    cr.xmax = xRes-32
    cr.ymax = yRes-32
    uglSetClipRect video, cr


	dim clut as long
	if( cFmtSrc = UGL.8BIT ) then
		clut = changePal( 128 )
	end if


    uglClear video, bg

    x = (xRes\2) - (bmpDC.xRes\2)
    y = (yRes\2) - (bmpDC.yRes\2)
    moved = -1
    xscale = 256
    yscale = 256
    Do
        If (kbd.d) Then
        	moved = -1
        	xscale = xscale + 1
        elseif (kbd.a) Then
        	moved = -1
        	if( xscale > 1 ) then xscale = xscale - 1
        end if

        If (kbd.w) Then
        	moved = -1
        	yscale = yscale + 1
        elseif (kbd.s) Then
        	moved = -1
        	if( yscale > 1 ) then yscale = yscale - 1
        end if

        xrscl = bmpDc.xRes '(bmpDc.xRes * xscale) \ 256
        yrscl = bmpDc.yRes '(bmpDc.yRes * yscale) \ 256

        If (kbd.left) Then
            moved = -1
            x = x - wStep
            If (x + xrscl-1 < 0) Then x = xRes-1 + (x + (xrscl-1))
        Elseif (kbd.right) Then
            moved = -1
            x = x + wStep
            If (x > xRes-1) Then x = -xrscl + (x - (xRes-1))
        End If
        If (kbd.up) Then
            moved = -1
            y = y - hStep
            If (y + yrscl-1 < 0) Then y = yRes-1 + (y + (yrscl-1))
        Elseif (kbd.down) Then
            moved = -1
            y = y + hStep
            If (y > yRes-1) Then y = -yrscl + (y - (yRes-1))
        End If

        If (moved) Then
            moved = 0

            uglClear video, bg

			tfxSetSolid 0, 0, 0
			tfxSetAlpha 128
			tfxSetFactor -255, 0, -255
			tfxBlitScl video, x+3, y+3, bmp, xscale, yscale, TFX.MASK or TFX.SOLID or TFX.ALPHA
			tfxBlitScl video, x, y, bmp, xscale, yscale, TFX.MASK

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

