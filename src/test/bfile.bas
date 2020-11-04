defint a-z
'$include: '..\..\inc\dos.bi'

        dim inpf as BFILE, outf as BFILE

        if (not bfileOpen(inpf, command$, F4READ, 8192)) then
                print "file not found"
                end
        end if
                
        if (not bfileOpen(outf, "temp.tmp", F4CREATE, 8192)) then
                print "cannot create a file"
                end
        end if

        do while (not bfileEOF(inpf))
                bfileWrite1 outf, bfileRead1(inpf)
        loop

        bfileClose outf
        bfileClose inpf
        end
