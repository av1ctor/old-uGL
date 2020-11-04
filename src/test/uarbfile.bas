defint a-z
'$include: '..\..\inc\dos.bi'
'$include: '..\..\inc\arch.bi'

        dim inpf as UARB, outf as BFILE

        if (not uarbOpen(inpf, command$, F4READ, 8192)) then
                print "file not found"
                end
        end if
                
        if (not bfileOpen(outf, "temp.tmp", F4CREATE, 8192)) then
                print "cannot create a file"
                end
        end if

        do while (not uarbEOF(inpf))
                bfileWrite1 outf, uarbRead1(inpf)
        loop

        bfileClose outf
        uarbClose inpf
        end
