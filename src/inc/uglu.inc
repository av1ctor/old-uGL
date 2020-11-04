;;
;; uglu.inc -- ugl utils prototypes
;;

ifndef          __uglu_inc__
                __uglu_inc__  	equ 1
                		
QBEZ3D          struc                           ;; quadricbez3d
                _a               PNT3D   <>
                _b               PNT3D   <>
                _c               PNT3D   <>
QBEZ3D        	ends

CBEZ3D        	struc				;; cubicbez3d
                _a               PNT3D   <>
                _b               PNT3D   <>
                _c               PNT3D   <>
		_d               PNT3D   <>
CBEZ3D        	ends

                ;; ugluQuadricBez (pntArray, qbz, levels)
                ugluQuadricBez  proto :far ptr PNT2D, :far ptr QBEZ, :word

		;; ugluCubicBez (pntArray, cbz, levels)
                ugluCubicBez    proto :far ptr PNT2D, :far ptr CBEZ, :word
		
                ;; ugluQuadricBez3D (pntArray, qbz, levels)
                ugluQuadricBez3D proto :far ptr PNT3D, :far ptr QBEZ3D, :word

                ;; ugluCubicBez3D (pntArray, cbz, levels)
                ugluCubicBez3D  proto :far ptr PNT3D, :far ptr CBEZ3D, :word

endif   	;; __uglu_inc__
