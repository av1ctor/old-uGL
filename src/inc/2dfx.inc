ifndef          __2dfx_inc__
		__2dfx_inc__   	equ 1


		;; type:			   x
		TFX_MASK	equ 0000000000000001b

		;; flip	modes:			 xx
		TFX_HFLIP	equ 0000000000000010b
		TFX_VFLIP	equ 0000000000000100b
		TFX_HVFLIP	equ 0000000000000110b

		;; remapping:		       xx
		TFX_SCALE	equ 0000000000001000b

		;; color manipulation:	    xxx
		TFX_SOLID	equ 0000000000100000b
		TFX_LUT		equ 0000000001000000b
		TFX_TEX		equ 0000000001100000b
		TFX_MONO	equ 0000000010000000b

		;; color manup pass 2 :	 xxx
		TFX_FACTMUL	equ 0000000100000000b
		TFX_FACTADD	equ 0000001000000000b

		;; blend modes:	     xxxx
		TFX_ALPHA	equ 0000100000000000b
		TFX_MONOMUL	equ 0001000000000000b
		TFX_SATADD	equ 0001100000000000b
		TFX_SATSUB	equ 0010000000000000b
		TFX_SATADDALPHA	equ 0010100000000000b


		TFX_TYPEMSK	equ 0000000000000001b
		TFX_FLIPMSK	equ 0000000000000110b
		TFX_RMAPMSK	equ 0000000000011000b
		TFX_COLRMSK	equ 0000000011100000b
		TFX_COL2MSK	equ 0000011100000000b
		TFX_BLNDMSK	equ 0111100000000000b

		TFX_TYPESHR	equ 0
		TFX_FLIPSHR	equ 1
		TFX_RMAPSHR	equ 3
		TFX_COLRSHR	equ 5
		TFX_COL2SHR	equ 8
		TFX_BLNDSHR	equ 11


		tfxSetSolid 	proto :word, :word, :word

		tfxGetSolid 	proto :near ptr word, :near ptr word, :near ptr word

		tfxSetAlpha 	proto :word

		tfxGetAlpha 	proto

		tfxSetLut 	proto :dword

		tfxGetLut 	proto

		tfxBlit 	proto :dword, :word, :word, :dword, :word

		tfxBlitBlit 	proto :dword, :word, :word, :dword, :word, :word, :word, :word, :word

		tfxBlitScl 	proto :dword, :word, :word, :dword, :word, :word, :word


endif           ;; __2dfx_inc__
