
		include common.inc
		include dos.inc
		include lang.inc

TGA		struc
		idfieldlen	byte	?
		colormaptype	byte	?
		imagetype	byte	?

		firstcolor	word	?
		entries		word	?
		entrylen	byte	?

		xorigin		word	?
		yorigin		word	?
		imgwidth	word	?
		imgheight	word	?
		bbp		byte	?
		imgdescriptor	byte	?
TGA		ends

		TGA_NOCOLORMAP		equ	0
		TGA_COLORMAP		equ	1

		TGA_COLORMAPPED		equ	1
		TGA_UNMAPPEDRGB		equ	2
		TGA_RLECOLORMAPPED	equ	9
		TGA_RLEUNMAPPEDRGB	equ	10

		TGA_DESC_LOWERLEFT	equ	00000000b
		TGA_DESC_UPPERLEFT	equ	00100000b
		TGA_DESC_NONINTERLEAVE	equ	00000000b
		TGA_DESC_TWOWAY		equ	01000000b
		TGA_DESC_FOURWAY	equ	10000000b


.code
;;:::
h_RGBtoBGR	proc	near private uses cx di es,\
			buff:dword,\
			pixels:word

		les	di, buff
		mov	cx, pixels

@@loop:         mov	al, es:[di].RGB.blue
		xchg	es:[di].RGB.red, al
		mov	es:[di].RGB.blue, al
		add	di, 3
		dec	cx
		jnz	@@loop

		ret
h_RGBtoBGR	endp

;;::::::::::::::
ugluSaveTGA	proc	public uses bx cx,\
			dc:dword,\
                        fname:STRING

                local   bf:FILE, fPtr:dword,\
                        hdr:TGA, buffPtr:dword,\
                        bps:word

		lea	ax, bf
		mov	W fPtr+0, ax
		mov	W fPtr+2, ss

                mov     fs, W dc+2		;; fs->dc
		CHECKDC fs, @@error, uglSaveTGA: Invalid DC

		;; allocate scanline buffer (24bpp)
		xor	eax, eax
		mov	ax, fs:[DC.xRes]
		shl	ax, 1
		add	ax, fs:[DC.xRes]
		mov	bps, ax
		invoke	memAlloc, eax
		jc	@@error
                mov	W buffPtr+0, ax
		mov	W buffPtr+2, dx

		;; try creating the file
		invoke	fileOpen, fPtr, fname, F_CREATE
		jc	@@error2

                ;; create header
                mov	hdr.idfieldlen, 0
		mov	hdr.colormaptype, TGA_NOCOLORMAP
		mov	hdr.imagetype, TGA_UNMAPPEDRGB

		mov	hdr.firstcolor, 0
		mov	hdr.entries, 0
		mov	hdr.entrylen, 0

		mov	hdr.xorigin, 0
		mov	hdr.yorigin, 0
		mov	ax, fs:[DC.xRes]
		mov	hdr.imgwidth, ax
		mov	ax, fs:[DC.yRes]
		mov	hdr.imgheight, ax
		mov	hdr.bbp, 24
		mov	hdr.imgdescriptor, TGA_DESC_UPPERLEFT or TGA_DESC_NONINTERLEAVE

		invoke	fileWrite, fPtr, A hdr, T TGA
		jc	@@error3

@@:		xor	bx, bx
		mov	cx, fs:[DC.yRes]

@@loop:		invoke  uglRowRead, dc, 0, bx, fs:[DC.xRes], BF_24BIT, buffPtr
		;invoke	h_RGBtoBGR, buffPtr, fs:[DC.xRes]
		invoke	fileWrite, fPtr, buffPtr, bps
		jc	@@error3
		inc	bx			;; ++y
		dec	cx
                jnz     @@loop

@@error3:	invoke	fileClose, fPtr

@@error2:	invoke	memFree, buffPtr

@@exit:		ret

@@error:	jmp	short @@exit
ugluSaveTGA	endp
		end

comment `
--------------------------------------------------------------------------------
DATA TYPE 2:  Unmapped RGB images.                                             |
_______________________________________________________________________________|
| Offset | Length |                     Description                            |
|--------|--------|------------------------------------------------------------|
|--------|--------|------------------------------------------------------------|
|    0   |     1  |  Number of Characters in Identification Field.             |
|        |        |                                                            |
|        |        |  This field is a one-byte unsigned integer, specifying     |
|        |        |  the length of the Image Identification Field.  Its value  |
|        |        |  is 0 to 255.  A value of 0 means that no Image            |
|        |        |  Identification Field is included.                         |
|        |        |                                                            |
|--------|--------|------------------------------------------------------------|
|    1   |     1  |  Color Map Type.                                           |
|        |        |                                                            |
|        |        |  This field contains either 0 or 1.  0 means no color map  |
|        |        |  is included.  1 means a color map is included, but since  |
|        |        |  this is an unmapped image it is usually ignored.  TIPS    |
|        |        |  ( a Targa paint system ) will set the border color        |
|        |        |  the first map color if it is present.                     |
|        |        |                                                            |
|--------|--------|------------------------------------------------------------|
|    2   |     1  |  Image Type Code.                                          |
|        |        |                                                            |
|        |        |  This field will always contain a binary 2.                |
|        |        |  ( That's what makes it Data Type 2 ).                     |
|        |        |                                                            |
|--------|--------|------------------------------------------------------------|
|    3   |     5  |  Color Map Specification.                                  |
|        |        |                                                            |
|        |        |  Ignored if Color Map Type is 0; otherwise, interpreted    |
|        |        |  as follows:                                               |
|        |        |                                                            |
|    3   |     2  |  Color Map Origin.                                         |
|        |        |  Integer ( lo-hi ) index of first color map entry.         |
|        |        |                                                            |
|    5   |     2  |  Color Map Length.                                         |
|        |        |  Integer ( lo-hi ) count of color map entries.             |
|        |        |                                                            |
|    7   |     1  |  Color Map Entry Size.                                     |
|        |        |  Number of bits in color map entry.  16 for the Targa 16,  |
|        |        |  24 for the Targa 24, 32 for the Targa 32.                 |
|        |        |                                                            |
|--------|--------|------------------------------------------------------------|
|    8   |    10  |  Image Specification.                                      |
|        |        |                                                            |
|    8   |     2  |  X Origin of Image.                                        |
|        |        |  Integer ( lo-hi ) X coordinate of the lower left corner   |
|        |        |  of the image.                                             |
|        |        |                                                            |
|   10   |     2  |  Y Origin of Image.                                        |
|        |        |  Integer ( lo-hi ) Y coordinate of the lower left corner   |
|        |        |  of the image.                                             |
|        |        |                                                            |
|   12   |     2  |  Width of Image.                                           |
|        |        |  Integer ( lo-hi ) width of the image in pixels.           |
|        |        |                                                            |
|   14   |     2  |  Height of Image.                                          |
|        |        |  Integer ( lo-hi ) height of the image in pixels.          |
|        |        |                                                            |
|   16   |     1  |  Image Pixel Size.                                         |
|        |        |  Number of bits in a pixel.  This is 16 for Targa 16,      |
|        |        |  24 for Targa 24, and .... well, you get the idea.         |
|        |        |                                                            |
|   17   |     1  |  Image Descriptor Byte.                                    |
|        |        |  Bits 3-0 - number of attribute bits associated with each  |
|        |        |             pixel.  For the Targa 16, this would be 0 or   |
|        |        |             1.  For the Targa 24, it should be 0.  For     |
|        |        |             Targa 32, it should be 8.                      |
|        |        |  Bit 4    - reserved.  Must be set to 0.                   |
|        |        |  Bit 5    - screen origin bit.                             |
|        |        |             0 = Origin in lower left-hand corner.          |
|        |        |             1 = Origin in upper left-hand corner.          |
|        |        |             Must be 0 for Truevision images.               |
|        |        |  Bits 7-6 - Data storage interleaving flag.                |
|        |        |             00 = non-interleaved.                          |
|        |        |             01 = two-way (even/odd) interleaving.          |
|        |        |             10 = four way interleaving.                    |
|        |        |             11 = reserved.                                 |
|        |        |                                                            |
|--------|--------|------------------------------------------------------------|
|   18   | varies |  Image Identification Field.                               |
|        |        |  Contains a free-form identification field of the length   |
|        |        |  specified in byte 1 of the image record.  It's usually    |
|        |        |  omitted ( length in byte 1 = 0 ), but can be up to 255    |
|        |        |  characters.  If more identification information is        |
|        |        |  required, it can be stored after the image data.          |
|        |        |                                                            |
|--------|--------|------------------------------------------------------------|
| varies | varies |  Color map data.                                           |
|        |        |                                                            |
|        |        |  If the Color Map Type is 0, this field doesn't exist.     |
|        |        |  Otherwise, just read past it to get to the image.         |
|        |        |  The Color Map Specification describes the size of each    |
|        |        |  entry, and the number of entries you'll have to skip.     |
|        |        |  Each color map entry is 2, 3, or 4 bytes.                 |
|        |        |                                                            |
|--------|--------|------------------------------------------------------------|
| varies | varies |  Image Data Field.                                         |
|        |        |                                                            |
|        |        |  This field specifies (width) x (height) pixels.  Each     |
|        |        |  pixel specifies an RGB color value, which is stored as    |
|        |        |  an integral number of bytes.                              |
|        |        |                                                            |
|        |        |  The 2 byte entry is broken down as follows:               |
|        |        |  ARRRRRGG GGGBBBBB, where each letter represents a bit.    |
|        |        |  But, because of the lo-hi storage order, the first byte   |
|        |        |  coming from the file will actually be GGGBBBBB, and the   |
|        |        |  second will be ARRRRRGG. "A" represents an attribute bit. |
|        |        |                                                            |
|        |        |  The 3 byte entry contains 1 byte each of blue, green,     |
|        |        |  and red.                                                  |
|        |        |                                                            |
|        |        |  The 4 byte entry contains 1 byte each of blue, green,     |
|        |        |  red, and attribute.  For faster speed (because of the     |
|        |        |  hardware of the Targa board itself), Targa 24 images are  |
|        |        |  sometimes stored as Targa 32 images.                      |
|        |        |                                                            |
--------------------------------------------------------------------------------
`

