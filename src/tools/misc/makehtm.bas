
'' tool to automatize the doc creation for the routines, using the text
'' about them in theirs source-code files
'' go to the directory with the .ASM files you want to process, and 
'' execute it, a file with the name of that dir + .HTM will be created

defint a-z
declare sub adddoc (flname as string)
declare sub addline (lin as string)
declare function right2$ (strg as string, char as integer)

        dim flname as string
        dim docname as string

        docname = right2(curdir$, asc("\")) + ".htm"

        open docname for output as #1

        print #1, "<html><head><title>" + docname "</title></head><body><table width=100%>"

        flname = dir$("*.asm")
        do while len(flname) <> 0
                adddoc flname
                flname = dir$
        loop

        print #1, "</table></body></html>"
        close #1

'':::
sub adddoc (flname as string)
        dim lin as string

        open flname for input as #2

        do while (not eof(2))
                
                line input #2, lin

                if (len(lin) >= 2) then
                        if (cvi(lin) = &h3B3B) then
                                if (instr(lin, "name:")) then                                        
                                        print #1, "<tr><td><pre>"
                                        print #1, "<hr noshade size=1>"

                                        do while (len(lin) >= 2)
                                                if (cvi(lin) <> &h3B3B) then
                                                   exit do
                                                end if
                                                addline lin
                                                line input #2, lin
                                        loop

                                        print #1, "</pre></td></tr>"
                                end if
                        end if
                end if

                if (instr(lin, "include")) then
                        exit do
                elseif (instr(lin, ".model")) then
                        exit do
                end if
        loop

        close #2
end sub

'':::
sub addline (lin as string)
        print #1, "  " + right$(lin, len(lin) - 2)
end sub

'':::
function right2$ (strg as string, char as integer)
        l = len(strg)
        if (l <= 1) then exit function
        if (asc(mid$(strg, l, 1)) = char) then exit function

        for i = l-1 to 1 step -1
                if (asc(mid$(strg, i, 1)) = char) then
                        right2 = right$(strg, l-i)
                        exit function
                end if
        next i
        right2 = strg
end function
