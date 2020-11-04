defint a-z
'$include: '..\inc\ugl.bi'
defdbl a-z

const SCR_WIDTH% = 320
const SCR_HEIGHT% = 200
const SCR_BITS%	= UGL.8BIT

const MAX% = 128\2
const SX = -2.025 	' start value real
const SY = -1.125 	' start value imaginary
const EX = 0.6    	' end value real
const EY = 1.125  	' end value imaginary

declare sub mandelbrot ( )
declare function DotsColor( byval xval, byval yval )
declare function HSBtoRGB( byval hue, byval saturation, byval brightness ) as long

   	dim shared xstart, ystart
   	dim shared xzoom, yzoom	
	dim shared buffer as long, video as long

	if( not uglInit ) then
		end 1
	end if
	
	buffer = uglNew( UGL.MEM, SCR_BITS, SCR_WIDTH, SCR_HEIGHT )
	if( buffer = 0 ) then
		end 1
	end if

	video = uglSetVideoDC( SCR_BITS, SCR_WIDTH, SCR_HEIGHT, 1 )
	if( video = 0 ) then
		end 1
	end if

   	xstart = SX
   	ystart = SY
   	xend = EX
   	yend = EY

   	fac = 0.99   
   	finc = .01
   	
   	do      
      	xend = xend * fac
      	yend = yend * fac
      	xstart = xstart * fac
      	ystart = ystart * fac
      	xzoom = (xend - xstart) / SCR_WIDTH
      	yzoom = (yend - ystart) / SCR_HEIGHT
      	mandelbrot
      	
      	fac = fac - finc
      	if( fac <= 0.91 ) then
      		fac = 0.93
      		finc = -finc
      	elseif( fac >= 1.1 ) then
      		fac = .99
      		finc = -finc
   			xstart = SX
   			ystart = SY
   			xend = EX
   			yend = EY
      	end if      	
      
      	uglPut video, 0, 0, buffer
      	
	loop while( inkey$ = "" )
	
	uglRestore
	uglEnd

END

' -------------------------------------------------------------
' -=  Mandelbrot  =-
' -------------------------------------------------------------
' calculate all points
sub mandelbrot
   dim x as integer, y as integer
   dim col as integer   
   
   FOR y = 0 TO SCR_HEIGHT-1
   	FOR x = 0 TO SCR_WIDTH-1
         
         h = DotsColor( xstart + xzoom * x, ystart + yzoom * y )
         
         IF h <> old then
            b = 1.0 - h * h ' brightness
			col = HSBtoRGB( h, 0.8, b )            
            old = h
         END IF
         uglPSet buffer, x, y, col
      NEXT x
   NEXT y
end sub


' ------------------------------------------------------------- '
' -=  DotsColor  =-
' ------------------------------------------------------------- '
' color value from 0.0 to 1.0 by iterations
function DotsColor( byval xval, byval yval )
   dim j as integer
   
   do WHILE (j < MAX) AND (m < 4.0)
      j = j + 1
      m = r * r - i * i
      i = 2.0 * r * i + yval
      r = m + xval
   loop   
   
   DotsColor = j / MAX
   
end function



' -------------------------------------------------------------
' -=  HSB2RGB  =-
' -------------------------------------------------------------
function HSBtoRGB( byval hue, byval saturation, byval brightness ) as long static
   dim red, green, blue, domainOffset

   IF brightness = 0.0 THEN 
   		HSBtoRGB = 0
   		exit function
   end if

   select case hue
   case is < 1.0/6.0
      ' red domain; green ascends
      domainOffset = hue
      red   = brightness
      blue  = brightness * (1.0 - saturation)
      green = blue + (brightness - blue) * domainOffset * 6.0
   
   case is < 2.0/6.0
      ' yellow domain; red descends
      domainOffset = hue - 1.0/6.0
      green = brightness
      blue  = brightness * (1.0 - saturation)
      red   = green - (brightness - blue) * domainOffset * 6.0
   
   case is < 3.0/6.0
	  ' green domain; blue ascends
      domainOffset = hue - 2.0/6.0
      green = brightness
      red   = brightness * (1.0 - saturation)
      blue  = red + (brightness - red) * domainOffset * 6.0
   
   case is < 4.0/6.0
	  ' cyan domain; green descends
      domainOffset = hue - 3.0/6.0
      blue  = brightness
      red   = brightness * (1.0 - saturation)
      green = blue - (brightness - red) * domainOffset * 6.0
   
   case is < 5.0/6.0
	  ' blue domain; red ascends
      domainOffset = hue - 4.0/6.0
      blue  = brightness
      green = brightness * (1.0 - saturation)
      red   = green + (brightness - green) * domainOffset * 6.0
   
   case else
	  ' magenta domain; blue descends
      domainOffset = hue - 5.0/6.0
      red   = brightness
      green = brightness * (1.0 - saturation)
      blue  = red - (brightness - green) * domainOffset * 6.0
   ENd select
   
   HSBtoRGB = uglColor( SCR_BITS, cint(red*255.0), cint(green*255.0), cint(blue*255.0) )

end function