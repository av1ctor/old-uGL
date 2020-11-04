;;
;; snd.inc -- sound module
;; 

ifndef          __snd_inc__
                __snd_inc__     equ 1
		
		;;
		;; Structure IDs
		;; 
		SMPID		equ	'XSMP'
     		VOCID		equ	'XVOC'
		

		;;
		;; Misc constants
		;; 
		snd_panmin	equ    -256
		snd_panmax	equ     256
		snd_volmin	equ	0
		snd_volmax	equ	255
		snd_ratemin	equ	1
		snd_ratemax	equ	64000

		
		;;
		;; Voice state
		;;
		snd_null	equ	0
		snd_playing	equ	1
		snd_paused	equ	2
		snd_played	equ	3
		
		;;
		;; Sample access
		;;
		snd_read	equ	0
		snd_write	equ	1
		snd_rdwr	equ	2
		
		;;
		;; Sample access
		;;
		snd_read	equ	0
		snd_write	equ	1
		snd_rdwr	equ	2
		
		;;
		;; Sample memory type
		;;
		snd_mem		equ	0
		snd_ems		equ	1
		
		;;
		;; Sample format
		;;
		snd_s8_mono	equ	0
		snd_s8_stereo	equ	1
		snd_s16_mono	equ	2
		snd_s16_stereo	equ	3
		
		;;
		;; Voice interpolation
		;;
		snd_nearest	equ	0
		snd_linear	equ	1
		snd_cubic	equ	2
		
		;;
		;; Voice play mode
		;;
		snd_onetime	equ	0
		snd_repeat	equ	1
		snd_pingpong	equ	2
		
		;;
		;; Voice play direction
		;;
		snd_up		equ	0
		snd_down	equ	1
		
		;;
		;; Other constants
		;;
		     	
		
snd_bufftype	union
		memPtr		dd		?
		emsHnd		dw		?
snd_bufftype	ends


snd_sample	struc
		smpID		dd		?
		buffType	dw		?
		frmt		dw		?
		len		dd		?
		rate		dw		?
		buff		snd_bufftype	<?>
snd_sample	ends


snd_voice	struc
		vocID		dd		?
		state		dw		?
		sample		dd		?
		mode		dw		?
		dir		dw		?
		lini		dd		?
		lend		dd		?
		pos		dd		?
		vol		dw		?
		pan		dw		?
		pitch		dw		?
		prev		dd		?
		next		dd		?
snd_voice	ends


snd_ctx		struc
		state		dw		?
		frmt		dw		?
		len		dw		?
		vol		dw		?
		pan		dw		?
		rate		dw		?
		mixb		dd		?
		idx		dw		?
		head		dd		?
		tail		dd		?
snd_ctx		ends


endif   	;; __snd_inc__
