defint a-z

'$include: '..\..\inc\dos.bi'

        dim src as long
        dim dst as long

        src = memAlloc( 100000 )
        if src = 0 then end

        dst = memAlloc( 100000 )
        if dst = 0 then end

        memFill src, 100000, &hCC

        memCopy dst, src, 100000


        dim f as FILE

        if not fileOpen( f, "dst.tmp", F4CREATE ) then end


        bRet& = fileWriteH( f, dst, 100000 )

        fileClose f

        memFree dst

        memFree src

        end

