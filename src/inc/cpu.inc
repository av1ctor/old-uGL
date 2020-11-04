;;
;; cpu.inc --
;; 

ifndef          __cpu_inc__
                __cpu_inc__    	equ 1

		CPU_MMX		equ 1
		CPU_SSE		equ 2
		CPU_SSE2	equ 4
		CPU_MMXEx	equ 8
		CPU_3DNOW	equ 16
		CPU_3DNOWEx	equ 32
                
                extrn           ul$cpu:word
                		
		;; cpuFeatures%	()
		cpuFeatures	proto

endif           ;; __cpu_inc__
