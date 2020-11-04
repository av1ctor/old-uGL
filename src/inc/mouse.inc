ifndef          __mouse_inc__
                __mouse_inc__   equ 1
		
                MOUSE           equ     33h
                MOUSE_RESET     equ     00h
                MOUSE_CUR_HIDE  equ     02h
		MOUSE_RD_MOTION	equ	0Bh
                MOUSE_HND_SET   equ     14h

MOUSEINF        struc
                x               word    ?
                y               word    ?
                any             word    ?
                left            word    ?
                middle          word    ?
                right           word    ?
MOUSEINF        ends

		;; mouseInit% 	(dc, mouse)
		mouseInit       proto :dword, :far ptr MOUSEINF
		
		;; mouseEnd 	()
		mouseEnd        proto
		
		;; mouseReset% 	(dc, mouse)
		mouseReset      proto :dword, :far ptr MOUSEINF
		
		;; mouseCursor 	(cursor, xSpot, ySpot)
		mouseCursor     proto :dword, :word, :word

		;; mouseRange 	(xmin, ymin, xmax, ymax)
		mouseRange      proto :word, :word, :word, :word
		
		;; mousePos 	(x, y)
		mousePos        proto :word, :word

		;; mouseRatio 	(hMickeys, vMickeys)
		mouseRatio      proto :word, :word
		
		;; mouseShow 	()
		mouseShow       proto

		;; mouseHide 	()
		mouseHide       proto

		;; mouseIn% 	(box:RECT)
		mouseIn       	proto :far ptr RECT

endif           ;; __mouse_inc__
