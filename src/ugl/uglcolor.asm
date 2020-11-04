;; name: uglColor32
;; desc: returns the color components (RGB), for 32-bit true-color format,
;;       packed
;;
;; args: [in] red,              | => 0; <= 255
;;            green,            | => 0; <= 255
;;            blue:integer      | => 0; <= 255
;; retn: long                   | packed color
;;
;; decl: uglColor32& (byval red as integer,_
;;                    byval green as integer,_
;;                    byval blue as integer)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none

;; name: uglColor16
;; desc: returns the color components (RGB), for 16-bit high-color format,
;;       packed
;;
;; args: [in] red,              | => 0; <= 31
;;            green,            | => 0; <= 63
;;            blue:integer      | => 0; <= 31
;; retn: long                   | packed color
;;
;; decl: uglColor16& (byval red as integer,_
;;                    byval green as integer,_
;;                    byval blue as integer)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: uglColor15
;; desc: returns the color components (RGB), for 15-bit high-color format,
;;       packed
;;
;; args: [in] red,              | => 0; <= 31
;;            green,            | => 0; <= 31
;;            blue:integer      | => 0; <= 31
;; retn: long                   | packed color
;;
;; decl: uglColor15& (byval red as integer,_
;;                    byval green as integer,_
;;                    byval blue as integer)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: uglColor8
;; desc: returns the color components (RGB), for 8-bit low-color format,
;;       packed
;;
;; args: [in] red,              | => 0; <= 7
;;            green,            | => 0; <= 7
;;            blue:integer      | => 0; <= 3
;; retn: long                   | packed color
;;
;; decl: uglColor8& (byval red as integer,_
;;                    byval green as integer,_
;;                    byval blue as integer)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: uglColor
;; desc: returns the color components (RGB), for a color format, packed
;;
;; args: [in] fmt,              | color format
;;            red,              | => 0; <= 255
;;            green,            | => 0; <= 255
;;            blue:integer      | => 0; <= 255
;; retn: long                   | packed color
;;
;; decl: uglColor& (byval fmt as integer,_
;;                  byval red as integer,_
;;                  byval green as integer,_
;;                  byval blue as integer)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

;; name: uglColors
;; desc: returns the number of colors supported by a DC format
;;
;; args: [in] fmt:integer       | DC's format
;; retn: long                   | colors
;;
;; decl: uglColors& (byval fmt as integer)
;;
;; chng: sep/01 written [v1ctor]
;; obs.: none

;; name: uglColorsEx
;; desc: returns the number of colors supported by a DC
;;
;; args: [in] dc:long           | dc to check
;; retn: long                   | colors
;;
;; decl: uglColorsEx& (byval dc as long)
;;
;; chng: sep/01 [v1ctor]
;; obs.: none

                include common.inc

.code
;;::::::::::::::
;; uglColor32 (red:word, green:word, blue:word) :dword
uglColor32      proc    public red:word, green:word, blue:word

                mov     al, B blue      ;; al= 00000000:bbbbbbbb
                mov     ah, B green     ;; ah= gggggggg
                mov     dx, red         ;; dx= 00000000:rrrrrrrr
                ;; dx:ax= 0:rrrrrrrr::gggggggg:bbbbbbbb

                ret
uglColor32      endp

;;::::::::::::::
;; uglColor16 (red:word, green:word, blue:word) :dword
uglColor16      proc    public red:word, green:word, blue:word

                mov     ax, green               ;; ax= 00000000:00gggggg
                shl     ax, 5                   ;; ax= 00000ggg:ggg00000
                or      al, B blue              ;; al= gggbbbbb
                mov     dl, B red               ;; dl= 000rrrrr
                shl     dl, 3                   ;; dl= rrrrr000
                or      ah, dl                  ;; ah= rrrrrggg
                xor     dx, dx
                ;; dx:ax= 0::rrrrrggg:gggbbbbb

                ret
uglColor16      endp

;;::::::::::::::
;; uglColor15 (red:word, green:word, blue:word) :dword
uglColor15      proc    public red:word, green:word, blue:word

                mov     ax, green               ;; ax= 00000000:000ggggg
                shl     ax, 5                   ;; ax= 000000gg:ggg00000
                or      al, B blue              ;; al= gggbbbbb
                mov     dl, B red               ;; dl= 000rrrrr
                shl     dl, 2                   ;; dl= 0rrrrr00
                or      ah, dl                  ;; ah= 0rrrrrgg
                xor     dx, dx
                ;; dx:ax= 0::0rrrrrgg:gggbbbbb

                ret
uglColor15      endp

;;::::::::::::::
;; uglColor8 (red:word, green:word, blue:word) :dword
uglColor8       proc    public red:word, green:word, blue:word

                mov     ax, green               ;; ax= 00000000:00000ggg
                shl     al, 2                   ;; ax= 00000000:000ggg00
                or      al, B blue              ;; al= 000gggbb
                mov     dl, B red               ;; dl= 00000rrr
                shl     dl, 5                   ;; dl= rrr00000
                or      al, dl                  ;; ah= rrrgggbb
                xor     dx, dx
                ;; dx:ax= 0::0:rrrgggbb

                ret
uglColor8       endp

;;::::::::::::::
;; uglColor (fmt:word, red:word, green:word, blue:word) :dword
uglColor        proc    public uses bx,\
                        fmt:word, red:word, green:word, blue:word

                mov     bx, fmt
                mov     ax, blue                ;; ax= 00000000:bbbbbbbb

                cmp     ul$cfmtTB[bx].shift, 1
                jg      @@32
                mov     dh, B red               ;; dh= rrrrrrrr
                mov     dl, B green             ;; dl= gggggggg
                jl      @@8
                cmp     ul$cfmtTB[bx].bpp, 15
                je      @@15

		shr	al, 3          		;; al= 000bbbbb
                mov     ah, dl                  ;; ah= gggggggg
                and     dx, 1111100000011100b   ;; dx= rrrrr000:000ggg00
                shr     ah, 5                   ;; ah= 00000ggg
                shl     dl, 3                   ;; dl= ggg00000
                or      ax, dx                  ;; ax= rrrrrggg:gggbbbbb
                xor     dx, dx
                ;; dx:ax= 0::rrrrrggg:gggbbbbb
                ret

@@15:           shr     al, 3                   ;; al= 000bbbbb
                mov     ah, dl                  ;; ah= gggggggg
                and     dx, 1111100000111000b   ;; dx= rrrrr000:00ggg000
                shr     ah, 6                   ;; ah= 000000gg
                shr     dh, 1                   ;; dh= 0rrrrr00
                shl     dl, 2                   ;; dl= ggg00000
                or      ax, dx                  ;; ax= 0rrrrrgg:gggbbbbb
                xor     dx, dx
                ;; dx:ax= 0::0rrrrrgg:gggbbbbb
                ret

@@8:            shr     al, 6                   ;; al= 000000bb
                and     dx, 1110000011100000b   ;; dx= rrr00000:ggg0000
                shr     dl, 3                   ;; dl= 000ggg00
                or      dl, dh                  ;; dl= rrrggg00
                or      al, dl                  ;; al= rrrgggbb
                xor     dx, dx
                ;; dx:ax= 0::0:rrrgggbb
                ret

@@32:           mov     ah, B green             ;; ah= gggggggg
                mov     dx, red                 ;; dx= 00000000:rrrrrrrr
                ;; dx:ax= 0:rrrrrrrr::gggggggg:bbbbbbbb
                ret
uglColor        endp

;;::::::::::::::
;; uglColors (fmt:word) :dword
uglColors       proc    public uses bx, fmt:word
                mov     bx, fmt
                mov     edx, ul$cfmtTB[bx].colors
                mov     ax, dx
                shr     edx, 16
                ret
uglColors       endp

;;::::::::::::::
;; uglColorsEx (dc:dword) :dword
uglColorsEx     proc    public uses bx, dc:dword
                mov     fs, W dc+2
                mov     bx, fs:[DC.fmt]
                mov     edx, ul$cfmtTB[bx].colors
                mov     ax, dx
                shr     edx, 16
                ret
uglColorsEx     endp
                end
