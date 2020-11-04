                include common.inc

.code
;;::::::::::::::
;; uglHackDC (dst:dword, newx:word, newy:word )
uglHackDC       proc    public uses bx di si,\ 
                        dst:dword,\
                        newx:word, newy:word

                mov     fs, W dst+2		;; fs->dst
		CHECKDC	fs, @@exit, uglPut: Invalid dst DC
                
		mov     ax, newx
                mov     bx, newx
                
                mov     fs:[DC.xRes], ax
                mov     fs:[DC.yRes], bx
                ret
uglHackDC       endp

;;::::::::::::::
;; uglHackDC (dst:dword, newx:word, newy:word )
uglHackDCEx     proc    public uses ds bx di si,\ 
                        dst:dword, src:dword
                
                local   slines:word, srcSwitch:word, xres:word

                int     3
                mov     fs, W dst+2		;; fs->dst
                mov     gs, W src+2		;; fs->dst
                
		mov     ax, gs:[DC.xRes]
                mov     bx, gs:[DC.yRes]
                mov     slines, bx
                
                ;; from pixel to bytes
		mov	cl, gs:[DC.p2b]
                shl     ax, cl
                mov     xres, ax
                
                mov	di, fs:[DC.startSL]
                mov     si, gs:[DC.startSL]
		shl	di, 2			;; addrTB idx
		shl	si, 2			;; /
		
		;;; save ptrs to switch routines
		mov	bp, gs:[DC.typ]
                mov	bx, fs:[DC.typ]
                mov     ax, ul$dctTB[bp].rdSwitch
                mov     srcSwitch, ax
		
		;; start the dc's access
                call    ul$dctTB[bp].rdBegin
                call    ul$dctTB[bx].wrBegin

                xor     di, di
                mov     cx, ss:xres
@@oloop:        PS      cx, di, si

                mov     esi, gs:[DC_addrTB][si]
                cmp     si, ss:[bp].GFXCTX.current
                jne     @@src_change
@@ret:          shr     esi, 16
		
                shr     cx, 2
                rep     movsd
				
                PP      si, di, cx
                add     si, T dword
                add     di, cx
                dec     ss:slines
		jnz	@@oloop
		
@@exit:		ret

@@src_change:   call    ss:srcSwitch
                shr     esi, 16
                je      @@ret
                
uglHackDCEx     endp


;;::::::::::::::
;; uglHackDC (dst:dword, newx:word, newy:word )
ugluLightmap   proc    public uses ds es gs fs bx si di,\
                       dstdc:dword, lghtmap:dword,\
                       lghtmpWidth:word, lghtmpHeight:word,\
                       colmap:dword, srcdc:dword
                
                local  dsdx:dword, dtdy:dword
                
                ;;
                ;; gs -> srcdc
                ;; fs -> dstdc
                ;;
                mov     fs, W dst+2
                mov     gs, W src+2
                
                ;;
                ;; Has to be the same size
                ;;
                mov     ax, gs:[DC.xRes]
                mov     bx, gs:[DC.yRes]
                cmp     ax, fs:[DC.xRes]
                jne     @@exit
                cmp     bx, fs:[DC.yRes]
                jne     @@exit
            
                ;;
                ;; dsdx = I2FIX( lightmap_width ) / dc.xres
                ;;
                movzx   eax, lghtmpWidth
                shl     eax, 16
                xor     edx, edx
                movzx   ebx, fs:[DC.xRes]
                div     ebx
                mov     dsdx, ebx
                
                ;;
                ;; dtdy = I2FIX( lightmap_height ) / dc.yres
                ;; dtdy_int = dtdy_int * lghtmpWidth
                ;;
                movzx   eax, lghtmpHeight
                shl     eax, 16
                xor     edx, edx
                movzx   ebx, fs:[DC.yRes]
                div     ebx
                mov     ebx, eax
                shr     eax, 16
                mul     lghtmpWidth
                shl     eax, 16
                mov     ax, bx
                mov     dtdy, eax


@@loop_o:       PS      cx, di
                xor     cx, cx
                
                mov     bp, 
@@loop_i:       mov     bl, ds:[bp+si+__IMM16__]
                mov     bh, es:[di]
dsdx_frc:       add     cx, __IMM16__
dsdx_int:       adc     di, __IMM16__
                mov     al, gs:[bx]
                inc     si
                mov     fs:[bp+si+__IMM16__], al
                jnz     @@loop_i
            
                PP      di, cx
            
dtdy_int:       add     di, __IMM16__
dtdy_frc:       add     cx, __IMM16__
                jnc     @F
                add     di, lghtmpWidth

@@:             dec     lghtmpHeight
                jnz     @@loop_o

@@exit:         ret
ugluLightmap    endp
                end
