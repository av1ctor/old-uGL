''
'' converts a 24-bit BMP file to 16-bit
'' usage: 24to16 filename ("24.bmp" expected at end)
''
defint a-z

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

type bmp16Hdr
        hdr as bmpHdr
        redMask as long
        greenMask as long
        blueMask as long
end type

        dim hdr as bmpHdr, hdr16 as bmp16Hdr
        dim inpBuffer as string, outBuffer as string

        open command$ + "24.bmp" for binary as #1
        open command$ + "16.bmp" for binary as #2

        get #1, , hdr

        ibps = (24 * hdr.wdt) \ 8
        padd = (4 - ibps) and 3
        ibps = ibps + padd

        obps = 2 * hdr.wdt
        padd = (4 - obps) and 3
        obps = obps + padd

        hdr16.hdr = hdr
        hdr16.hdr.bpp = 16
        hdr16.hdr.imgSize = obps * hdr.hgt
        hdr16.hdr.compression = 3
        hdr16.redMask   = &h0000F800&
        hdr16.greenMask = &h000007E0&
        hdr16.blueMask  = &h0000001F&
        hdr16.hdr.offPicData = hdr16.hdr.offPicData + 12
        hdr16.hdr.fileSize = len(hdr16) + hdr16.hdr.imgSize
        put #2, , hdr16

        inpBuffer = string$(ibps, 0)
        outBuffer = string$(obps, 0)
        for y = 1 to cint(hdr.hgt)
                get #1, , inpBuffer
                iOff = sadd(inpBuffer)
                oOff = sadd(outBuffer)
                for x = 1 to cint(hdr.wdt)
                        b = peek(iOff+0)
                        g = peek(iOff+1)
                        r = peek(iOff+2)
                        poke oOff+0, (b \ 8) or ((g * 8) and &hE0)
                        poke oOff+1, (g \ 32) or (r and &hF8)
                        iOff = iOff + 3
                        oOff = oOff + 2
                next x
                put #2, , outBuffer
        next y

        close #2
        close #1
