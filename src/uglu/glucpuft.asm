;; name: ugluIsMMX
;; desc: Checks if the cpu supports MMX
;;
;; args: none
;;
;; retn: -1 if MMX is supported
;;        0 if not
;;
;; decl: ugluIsMMX% ( )
;;
;; chng: sep/02 written [Blitz]
;; obs.: uglInit has to be called before this can be
;;       used

;; name: ugluIsMMXEx
;; desc: Checks if the cpu supports extended MMX
;;
;; args: none
;;
;; retn: -1 if extended MMX is supported
;;        0 if not
;;
;; decl: ugluIsMMXEx% ( )
;;
;; chng: sep/02 written [Blitz]
;; obs.: uglInit has to be called before this can be
;;       used

;; name: ugluIs3DNow
;; desc: Checks if the cpu supports 3DNow
;;
;; args: none
;;
;; retn: -1 if 3DNow is supported
;;        0 if not
;;
;; decl: ugluIs3DNow% ( )
;;
;; chng: sep/02 written [Blitz]
;; obs.: uglInit has to be called before this can be
;;       used

;; name: ugluIs3DNowEx
;; desc: Checks if the cpu supports extended 3DNow
;;
;; args: none
;;
;; retn: -1 if extended 3DNow is supported
;;        0 if not
;;
;; decl: ugluIs3DNowEx% ( )
;;
;; chng: sep/02 written [Blitz]
;; obs.: uglInit has to be called before this can be
;;       used

;; name: ugluIsSSE
;; desc: Checks if the cpu supports SSE
;;
;; args: none
;;
;; retn: -1 if SSE is supported
;;        0 if not
;;
;; decl: ugluIsSSE% ( )
;;
;; chng: sep/02 written [Blitz]
;; obs.: uglInit has to be called before this can be
;;       used

;; name: ugluIsSSE2
;; desc: Checks if the cpu supports SSE2
;;
;; args: none
;;
;; retn: -1 if SSE2 is supported
;;        0 if not
;;
;; decl: ugluIsSSE2% ( )
;;
;; chng: sep/02 written [Blitz]
;; obs.: uglInit has to be called before this can be
;;       used



		include	common.inc
		include	cpu.inc

.code
;;::::::::::::::
ugluIsMMX       proc    public

                mov     ax, ul$cpu 
                and     ax, CPU_MMX
                jz      @@exit
                
                mov     ax, -1
@@exit:         ret
ugluIsMMX       endp


ugluIsMMXEx     proc    public

                mov     ax, ul$cpu 
                and     ax, CPU_MMXEx
                jz      @@exit
                
                mov     ax, -1
@@exit:         ret
ugluIsMMXEx     endp


ugluIs3DNow     proc    public

                mov     ax, ul$cpu 
                and     ax, CPU_3DNOW
                jz      @@exit
                
                mov     ax, -1
@@exit:         ret
ugluIs3DNow     endp

                    
ugluIs3DNowEx   proc    public

                mov     ax, ul$cpu 
                and     ax, CPU_3DNOWEx
                jz      @@exit
                
                mov     ax, -1
@@exit:         ret
ugluIs3DNowEx   endp


ugluIsSSE       proc    public

                mov     ax, ul$cpu 
                and     ax, CPU_SSE 
                jz      @@exit
                
                mov     ax, -1
@@exit:         ret
ugluIsSSE       endp


ugluIsSSE2      proc    public

                mov     ax, ul$cpu 
                and     ax, CPU_SSE2 
                jz      @@exit
                
                mov     ax, -1
@@exit:         ret
ugluIsSSE2      endp
                end



