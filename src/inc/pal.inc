ifndef          __pal_inc__
                __pal_inc__     equ 1

RGB		struc
		red		db	?
		green		db	?
		blue		db	?
RGB		ends


		;; uglPalSet	(idx, entries, pal)
		uglPalSet   	proto :word, :word, :far ptr RGB

		;; uglPalGet	(idx, entries, pal)
		uglPalGet   	proto :word, :word, :far ptr RGB

                ;; uglPalUsingLin (flag)
                uglPalUsingLin	proto :word

		;; uglPalBestFit% (pal, r, g, b)
		uglPalBestFit	proto :far ptr RGB, :word, :word, :word


		;; uglPalFade	(pal, idx, entries, )
		uglPalSet   	proto :word, :word, :far ptr RGB

		;; uglPalFade   (pal, idx, entries, factor)
		uglPalFade	proto :far ptr RGB, :word, :word, :word

		;; uglPalFadeIn  (pal, idx, entries, msecs, blocking)
		uglPalFadeIn	proto :far ptr RGB, :word, :word, :dword, :word

		;; uglPalFadeOut (pal, idx, entries, msecs, blocking)
		uglPalFadeOut	proto :far ptr RGB, :word, :word, :dword, :word


endif   	;; __pal_inc__
