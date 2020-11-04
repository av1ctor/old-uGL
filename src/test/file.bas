defint a-z
'$include: '..\..\inc\dos.bi'

DECLARE SUB int3 ()

        dim inpf as FILE, outf as FILE
        dim blk as long
 
        blk = memAlloc(65536)
        if (blk = 0) then
                print "not enough memory"
                end
        end if

        int3
        if (not fileOpen(inpf, command$, F4READ)) then
                print "file not found"
                end
        end if

        if (not fileOpen(outf, "temp.tmp", F4CREATE)) then
                print "cannot create a file"
                end
        end if

        print fileWrite(outf, blk, fileRead(inpf, blk, fileSize(inpf)))

        fileClose outf
        fileClose inpf
        end

SUB int3
  static opcode as integer
  opcode = &hCBCC
  call absolute(varptr(opcode))
end sub

