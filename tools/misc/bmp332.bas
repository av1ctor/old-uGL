
'' gen a 1x1x8 windows bmp file w/ a 332 palette

DefInt A-Z

type ARGB
        b as string * 1
        g as string * 1
        r as string * 1
        a as string * 1
end type

type bmpHdr
                sign            as string * 2
                fileSize        as long
                reserved        as long
                offPicData      as long
                infHdrSize      as long
                wdt             as long
                hgt             as long
                planes          as integer
                bpp             as integer
                compression     as long
                imgSize         as long
                wdtPPM          as long
                hgtPPM          as long
                usedColors      as long
                impColors       as long
end type

Declare sub makehdr ()
Declare sub genpal ()

dim shared pal(0 to 255) as ARGB
dim shared hdr as bmpHdr
'':::
	
        genpal
        makehdr

        open "332.bmp" for binary as #1
                put #1, , hdr

                for i = 0 to 255
                        put #1, , pal(i)
                next i

                dword& = &h000000FF
                put #1, , dword&
        close #1
	
        End

'':::
sub genpal static
  dim c as integer

  for c = 0 to 255
      pal(c).r = chr$(((c \ 32) and 7) * (255/7))
      pal(c).g = chr$(((c \ 4) and 7) * (255/7))
      pal(c).b = chr$((c and 3) * (255/3))
  next c
end sub

'':::
sub makehdr
        hdr.sign = "BM"
        hdr.fileSize = 40 + 1024 + 1
        hdr.offPicData = len(hdr) + 1024
        hdr.infHdrSize = 40
        hdr.wdt = 1
        hdr.hgt = 1
        hdr.planes = 1
        hdr.bpp = 8
        hdr.compression = 0
        hdr.imgSize = 1
        hdr.usedColors = 0
        hdr.impColors = 0
end sub
