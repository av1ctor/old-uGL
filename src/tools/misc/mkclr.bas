defint a-z
declare sub mkclr (rBits, gBits, bBits, bits as string)

        dim shared nameTB(0 to 15) as string

        nameTB(0) = "BLACK"
        nameTB(1) = "BLUE"
        nameTB(2) = "GREEN"
        nameTB(3) = "CYAN"
        nameTB(4) = "RED"
        nameTB(5) = "MAGENTA"
        nameTB(6) = "BROWN"
        nameTB(7) = "WHITE"
        nameTB(8) = "GREY"
        nameTB(9) = "LBLUE"
        nameTB(10) = "LGREEN"
        nameTB(11) = "LCYAN"
        nameTB(12) = "LRED"
        nameTB(13) = "LMAGENTA"
        nameTB(14) = "YELLOW"
        nameTB(15) = "BWHITE"

        mkclr 8, 8, 8, "32"
        mkclr 5, 6, 5, "16"
        mkclr 5, 5, 5, "15"
        mkclr 3, 3, 2, "8"

sub mkclr (rBits, gBits, bBits, bits as string)
        dim rh as string, gh as string, bh as string

        screen 13

        rBits = 2 ^ (8-rBits)
        gBits = 2 ^ (8-gBits)
        bBits = 2 ^ (8-bBits)

        open "ctb" for append as #1
                out &h3c7, 0
                for c = 0 to 15
                        r = inp(&h3c9)*4
                        g = inp(&h3c9)*4
                        b = inp(&h3c9)*4
                        rh = hex$(r \ rBits)                        
                        gh = hex$(g \ gBits)
                        bh = hex$(b \ bBits)
                        if len(rh)= 1 then rh = "0" + rh 
                        if len(gh)= 1 then gh = "0" + gh
                        if len(bh)= 1 then bh = "0" + bh 

                        print #1, "Const UGL."+nameTB(c)+bits+"&"+chr$(9)+"= (";
                        print #1, "&h"+rh+"&*REDP"+bits+")+(";
                        print #1, "&h"+gh+"&*GREENP"+bits+")+(";
                        print #1, "&h"+bh+"&*BLUEP"+bits+")"
                next c
                print #1, ""
        close #1
end sub
