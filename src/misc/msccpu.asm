;;
;; mscCpu.asm -- cpu ident and etc...
;;
                
		.model  medium, pascal
                .586

                include equ.inc
		include cpu.inc

.code
checked		dw	0
cpu		dw	0

;;::::::::::::::
mmxCheck        proc    near uses ebx ecx edx

		mov	ax, cs:cpu
		test	cs:checked, CPU_MMX
		jnz	@@exit

		pushfd
		pop 	eax
		mov 	ebx, eax
                xor     eax, 00200000h          ;; toggle bit 21
		push 	eax
		popfd
		pushfd
		pop 	eax
		cmp 	eax, ebx 		;; see if bit 21 has changed
		jz 	@@nommx 		;; if no change, no CPUID

                mov 	eax, 1 			;; setup function 1
		cpuid
                test    edx, 800000h            ;; test 23rd bit
		jz 	@@nommx 		;; not supported?
		
		mov	ax, CPU_MMX		;; return TRUE

@@done:         or      cs:checked, CPU_MMX
		or	cs:cpu, ax

@@exit:		and	ax, CPU_MMX
		ret

@@nommx:	xor	ax, ax			;; return FALSE
		jmp	short @@done
mmxCheck	endp

;;::::::::::::::
sseCheck        proc    near uses ebx ecx edx

		mov	ax, cs:cpu
		test    cs:checked, CPU_SSE
		jnz	@@exit
                test    cs:cpu, CPU_MMX
                jz     	@@nosse

                mov 	eax, 1 			;; setup function 1
		cpuid
                test    edx, 02000000h          ;; test 25th bit
		jz 	@@nosse 		;; not supported?
		
		mov	ax, CPU_SSE

@@done:		or	cs:cpu, ax
		or      cs:checked, CPU_SSE

@@exit:		and	ax, CPU_SSE
		ret

@@nosse:	xor	ax, ax			;; return FALSE
		jmp	short @@done
sseCheck	endp

;;::::::::::::::
sse2Check       proc    near uses ebx ecx edx

		mov	ax, cs:cpu
		test    cs:checked, CPU_SSE2
		jnz	@@exit
                test    cs:cpu, CPU_SSE
                jz     	@@nosse2

                mov 	eax, 1 			;; setup function 1
		cpuid
                test    edx, 04000000h          ;; test 26th bit
		jz 	@@nosse2 		;; not supported?
		
		mov	ax, CPU_SSE2

@@done:		or	cs:cpu, ax
		or      cs:checked, CPU_SSE2

@@exit:		and	ax, CPU_SSE2
		ret

@@nosse2:	xor	ax, ax			;; return FALSE
		jmp	short @@done
sse2Check	endp

;;::::::::::::::
aMMXExCheck     proc    near uses ebx ecx edx

		mov	ax, cs:cpu
		test    cs:checked, CPU_MMXEx
		jnz	@@exit
                test    cs:cpu, CPU_MMX
                jz      @@noMMXEx

                mov 	eax, 80000000h		;; check for extended functions
		cpuid
		cmp	eax, 80000000h		
		jbe	@@noMMXEx		;; No extended function = no ext. mmx
		
		mov	eax, 80000001h
		cpuid
		
                test    edx, 00400000h          ;; test 22 bit
		jz 	@@noMMXEx 		;; not supported?
		
		mov	ax, CPU_MMXEx

@@done:		or	cs:cpu, ax
		or      cs:checked, CPU_MMXEx

@@exit:		and	ax, CPU_MMXEx
		ret

@@noMMXEx:	xor	ax, ax			;; return FALSE
		jmp	short @@done
aMMXExCheck	endp

;;::::::::::::::
k3dCheck        proc    near uses ebx ecx edx

		mov	ax, cs:cpu
		test    cs:checked, CPU_3DNOW
		jnz	@@exit
                test    cs:cpu, CPU_MMX
                jz      @@nok3d

                mov 	eax, 80000000h		;; check for extended functions
		cpuid
		cmp	eax, 80000000h		
		jbe	@@nok3d			;; No extended function = no 3DNow!
		
		mov	eax, 80000001h
		cpuid
		
                test    edx, 80000000h          ;; test 31 bit
		jz 	@@nok3d 		;; not supported?
		
		mov	ax, CPU_3DNOW

@@done:		or	cs:cpu, ax
		or      cs:checked, CPU_3DNOW

@@exit:		and	ax, CPU_3DNOW
		ret

@@nok3d:	xor	ax, ax			;; return FALSE
		jmp	short @@done
k3dCheck	endp

;;::::::::::::::
k3dExCheck      proc    near uses ebx ecx edx

		mov	ax, cs:cpu
		test    cs:checked, CPU_3DNOWEx
		jnz	@@exit
                test    cs:cpu, CPU_3DNOW
                jz      @@nok3dEx

                mov 	eax, 80000000h		;; check for extended functions
		cpuid
		cmp	eax, 80000000h		
		jbe	@@nok3dEx		;; No extended function = no ext. 3DNow!
		
		mov	eax, 80000001h
		cpuid
		
                test    edx, 40000000h          ;; test 30 bit
		jz 	@@nok3dEx 		;; not supported?
		
		mov	ax, CPU_3DNOWEx

@@done:		or	cs:cpu, ax
		or      cs:checked, CPU_3DNOWEx

@@exit:		and	ax, CPU_3DNOWEx
		ret

@@nok3dEx:	xor	ax, ax			;; return FALSE
		jmp	short @@done
k3dExCheck	endp
		
;;:::
;; cpuFeatures% ()
cpuFeatures 	proc    public uses bx

                xor	bx, bx			;; assume no features
		
		call	mmxCheck                ;; MMX capable?
                or	bx, ax
		call	sseCheck                ;; SSE?
                or	bx, ax
                call	sse2Check               ;; SSE2?
                or	bx, ax
                call	aMMXExCheck             ;; AMD's ext. MMX?
                or	bx, ax
                call	k3dCheck                ;; 3DNow!?
                or	bx, ax
                call	k3dExCheck              ;; ext. 3DNow!?
                or	ax, bx

		ret
cpuFeatures     endp
		end
