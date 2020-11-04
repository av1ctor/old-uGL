'' for testing how cache matters, change the bpp constant below to 16 after
'' running this test with it set to 8, and the speed for filling the
'' buffer will not drop in half as expected (as the double of bytes will
'' have to be filled in 16 bpp), it will be ~10 times slower than. This 
'' happens because the whole 64k (320x200x8bit) of memory will be in cache
'' for 8bpp, while for 16 bpp, every new restart will get only cache misses.
'' Soluttion? Put all in offscreen VRAM and use hardware blitting/accel to
'' write/read/copy/access the bitmap, of course it can be only done when
'' working in LFB mode and having a driver for each video-card around :P

defint a-z
'$include: '..\bi\b4g.bi'

const FRAMES = 10000

const xRes = 320&
const yRes = 200&

Declare Function Timer2& ()

'':::
        dim buffer as long
    
        if (b4ginit > 0) then
                print "ERROR! cannot switch to pmode""
                end
        end if

        select case command$
        case "32"
                bpp = 32
        case "15", "16"
                bpp = 16
        case else
                bpp = 8
        end select

        dim buffSize as long
        buffSize = (xRes * (bpp\8)) * yRes

        buffer = xmalloc(buffSize)
        if (buffer = 0) then end

        iniTmr& = Timer2
        for f = 0 to FRAMES-1
                xmfill buffer, buffSize, -1
        next f
        endTmr& = Timer2

        Print "xRes:"; xRes; " yRes:"; yRes; " bpp:"; bpp
        Print "bytes written per frame:"; buffSize        
        Print "fps:"; Clng((FRAMES*18.2) / (endTmr&-iniTmr&))

        xmfree buffer
        b4gdone
