;; name: tmrInit
;; desc: installs a new ISR for PIT (Prog. Interval Timer) to process
;;       multiple high-resolution timers
;;
;; type: sub
;; args: none
;; retn: none
;;
;; decl: tmrInit ()
;;
;; chng: oct/01 written [v1ctor]
;; obs.: do _not_ use QB's PLAY routine or the PIT will be reprogrammed
;;       and the ISR won't stay in control of this module

;; name: tmrEnd
;; desc: restores original PIT mode, rate and handler
;;
;; type: sub
;; args: none
;; retn: none
;;
;; decl: tmrEnd ()
;;
;; chng: oct/01 [v1ctor]
;; obs.: needs only to be called when running in the IDE, for compiled
;;       programs, the ISR will be uninstalled automatically when finishing

;; name: tmrNew
;; desc: starts a new timer
;;
;; args: [in/out] t:TMR         | TMR struct to add to queue
;;       [in] mode:integer,     | timer mode (AUTOINIT, ONESHOT)
;;            rate:long         | timer rate (in Hertz)
;; retn: none
;;
;; decl: tmrNew (seg t as TMR, byval mode as integer,_
;;               byval rate as long)
;;
;; chng: oct/01 [v1ctor]
;;       jun/02 AUTOINIT added [v1ctor]
;;
;; obs.: - do _not_ declare the TMR struct using REDIM, declare it only
;;         using DIM and if using the '$Dynamic directive, use '$Static
;;         in the line above its declaration
;;
;;       - _never_ access TMR's fields but the 'state' (for read-only),
;;         and the 'counter' field (for AUTOINIT timers); messing with
;;         other fields can leave the system unstable
;;
;;       - if the timer is already on queue, it will be deleted and then
;;         added
;;
;;       - how timers will operate, depending on 'mode' selected:
;;           * ONESHOT: when the timer expires, its deleted
;;             from active timers queue and its state field
;;             is changed to TMR.OFF; to reactive it again,
;;             a new call to tmrNew must to be done
;;
;;           * AUTOINIT: when the timer expires, its re-added
;;             to active timers queue and its counter field
;;             is incremented by 1; that keeps going until the
;;             timer is delete or paused

;; name: tmrDel
;; desc: deletes a timer from the queue
;;
;; type: sub
;; args: [in/out] t:TMR         | TMR struct to delete from queue
;; retn: none
;;
;; decl: tmrDel (seg t as TMR)
;;
;; chng: oct/01 [v1ctor]
;; obs.: none

;; name: tmrPause
;; desc: pauses (deletes) a timer
;;
;; type: sub
;; args: [in/out] t:TMR         | TMR struct to pause
;; retn: none
;;
;; decl: tmrPause Alias "tmrDel" (seg t as TMR)
;;
;; chng: oct/01 [v1ctor]
;; obs.: none

;; name: tmrResume
;; desc: resumes a paused timer
;;
;; type: sub
;; args: [in/out] t:TMR         | TMR struct to resume
;; retn: none
;;
;; decl: tmrResume (seg t as TMR)
;;
;; chng: oct/01 [v1ctor]
;; obs.: none

;; name: tmrUs2Freq
;; desc: converts micro-seconds to PIT rate (in Hertz)
;;
;; type: function
;; args: [in] microsecs:long    | micro-seconds to convert
;; retn: long                   | rate
;;
;; decl: tmrUs2Freq& (byval microsecs as long)

;; name: tmrMs2Freq
;; desc: converts mili-seconds to PIT rate (in Hertz)
;;
;; type: function
;; args: [in] milisecs:long     | mili-seconds to convert
;; retn: long                   | rate
;;
;; decl: tmrMs2Freq& (byval milisecs as long)

;; name: tmrSec2Freq
;; desc: converts seconds to PIT rate (in Hertz)
;;
;; type: function
;; args: [in] seconds:integer   | seconds to convert
;; retn: long                   | rate
;;
;; decl: tmrSec2Freq& (byval seconds as integer)

;; name: tmrTick2Freq
;; desc: converts ticks (55ms) to PIT rate (in Hertz)
;;
;; type: function
;; args: [in] ticks:integer     | ticks to convert
;; retn: long                   | rate
;;
;; decl: tmrTicks2Freq& (byval ticks as integer)

;; name: tmrMin2Freq
;; desc: converts minutes to PIT rate (in Hertz)
;;
;; type: function
;; args: [in] minutes:integer   | minutes to convert
;; retn: long                   | rate
;;
;; decl: tmrMin2Freq& (byval minutes as integer)

                include common.inc
                include timer.inc
                include dos.inc
                include exitq.inc
                include misc.inc


                BIOS_RATE       equ 10000h      ;; PIT_FREQ / 18.2
                CYCLE_RATE      equ BIOS_RATE/8

TMRQ            struc
                timers          dw      ?
                head            dd      ?
                tail            dd      ?       ;; (AUTOINIT only)
                min_cnt         dd      ?       ;; /
TMRQ            ends


;;::::::::::::::
CYCLE           macro   ??divisor:req
        ifidni  <??divisor>, <eax>
                push    eax
        endif
                ;; PIT command: counter 0, LSB + MSB, mode 2 (cycle), binary
                mov     al, PIT_SEL_CNT_0 or PIT_ACC_0_15 or\
                            PIT_MODE_2 or PIT_STL_BIN
                out     PIT_MODE, al

        ifidni  <??divisor>, <eax>
                pop     eax
        else
                mov     eax, ??divisor
        endif
                mov     cs:divisor, eax

                out     PIT_CNT_0, al           ;; lsb
                mov     al, ah
                out     PIT_CNT_0, al           ;; msb
endm

;;::::::::::::::
ZERODET         macro   ??divisor:req
        ifidni  <??divisor>, <eax>
                push    eax
        endif
                ;; PIT command: counter 0, LSB + MSB,
                ;; mode 0 (zero detection interrupt), binary
                mov     al, PIT_SEL_CNT_0 or PIT_ACC_0_15 or\
                            PIT_MODE_0 or PIT_STL_BIN
                out     PIT_MODE, al

        ifidni  <??divisor>, <eax>
                pop     eax
        else
                mov     eax, ??divisor
        endif
                mov     cs:divisor, eax

                out     PIT_CNT_0, al           ;; lsb
                mov     al, ah
                out     PIT_CNT_0, al           ;; msb
endm


.code
installed       dw      FALSE
exitq           EXITQ   <>

windowsware     dw      FALSE
working         dw      FALSE

bios_cnt        dd      BIOS_RATE               ;; to maintance system time
rate            dd      BIOS_RATE               ;; min(min(tmrs.cnt), BIOS_RATE)
divisor         dd      BIOS_RATE

oneshot_q       TMRQ    <>                      ;; oneshot delta queue
autoinit_q      TMRQ    <>                      ;; autoinit queue

prev_hnd        dd      NULL
old_int1C       dd      NULL

                PIT_RATE_US     equ        1.1927552 ;; 1,1927552   Hz p/ us
                PIT_RATE_MS     equ     1192.7552    ;; 1.192,7552  Hz p/ ms
                PIT_RATE_TICK   equ    65601.536     ;; 65.601,536  Hz p/ tick
                PIT_RATE_SEC    equ  1192755.2       ;; 1.192.755,2 Hz p/ sec
                PIT_RATE_MIN    equ 71565312         ;; 71.565.312  Hz p/ min
us2freq         dq      PIT_RATE_US
ms2freq         dq      PIT_RATE_MS
tick2freq       dq      PIT_RATE_TICK
sec2freq        dq      PIT_RATE_SEC
min2freq        dq      PIT_RATE_MIN


new_int1C:      iret                            ;; no chain

;;::::::::::::::
tmrInit         proc    public uses es ds

                cmp     cs:installed, TRUE
                je      @@exit                  ;; already installed?
                mov     cs:installed, TRUE

                ;; add tmrEnd to exit queue
                cmp     cs:exitq.stt, FALSE
                jne     @F
                invoke  ExitQ_Add, cs, O tmrEnd, O exitq, EQ_MID

@@:             ;; set vars
                mov     cs:working, FALSE
                mov     cs:chain, FALSE
                mov     cs:bios_cnt, BIOS_RATE

                ;; set a new int 1Ch ISR (to prevent stupid TSRs)
                mov     ax, DOS_INT_VECTOR_GET*256 + 1Ch
                int     DOS
                mov     W cs:old_int1C+0, bx
                mov     W cs:old_int1C+2, es

                mov     ax, cs
                mov     ds, ax
                mov     dx, O new_int1C
                mov     ax, DOS_INT_VECTOR_SET*256 + 1Ch
                int     DOS

                ;; save current handler
                mov     ax, DOS_INT_VECTOR_GET*256 + 08h
                int     DOS
                mov     W cs:prev_hnd+0, bx
                mov     W cs:prev_hnd+2, es

                ;; check if Windows is running, then select apropriated ISR
                mov     dx, O handler_zerodet   ;; assume not Windows
                mov     cs:windowsware, FALSE   ;; /
                call    winCheck
                ;jnc     @F                      ;; <-- fix bug when in raw dos
                mov     dx, O handler_cycle     ;; damn!
                mov     cs:windowsware, TRUE

@@:             ;; set new handler
                mov     ax, DOS_INT_VECTOR_SET*256 + 08h
                int     DOS

                cli

                ;; set up PIC to allow INT0 interrupt (just for safeness :})
                in      al, PIC_MASK
                and     al, not 1
                out     PIC_MASK, al

                ;; program PIT depending of the handler selectioned
                cmp     cs:windowsware, FALSE
                jne     @F
                ZERODET cs:rate
                jmp     short @@done

@@:             mov     cs:rate, CYCLE_RATE
                CYCLE   CYCLE_RATE

@@done:         sti

@@exit:         ret
tmrInit         endp

;;::::::::::::::
tmrEnd          proc    public uses ax bx dx ds

                cmp     cs:installed, FALSE
                je      @@exit                  ;; installed?
                mov     cs:installed, FALSE

                ;; turn off all timers
                mov     cs:working, TRUE

                ;; oneshot queue
                lds     bx, cs:oneshot_q.head
                mov     cs:oneshot_q.head, NULL ;; no timers
                jmp     short @@os_test
@@os_loop:      mov     [bx].TMR.state, T_OFF
                mov     [bx].TMR.cnt, 0
                lds     bx, [bx].TMR.next
@@os_test:      mov     ax, ds
                test    ax, ax
                jnz     @@os_loop
                mov     cs:oneshot_q.tail, NULL
                mov     cs:oneshot_q.timers, 0

                ;; autoinit queue
                lds     bx, cs:autoinit_q.head
                mov     cs:autoinit_q.head, NULL
                jmp     short @@ai_test
@@ai_loop:      mov     [bx].TMR.state, T_OFF
                mov     [bx].TMR.cnt, 0
                mov     [bx].TMR.counter, 0
                lds     bx, [bx].TMR.next
@@ai_test:      mov     ax, ds
                test    ax, ax
                jnz     @@ai_loop
                mov     cs:autoinit_q.tail, NULL
                mov     cs:autoinit_q.timers, 0

                mov     cs:working, FALSE

                cli

                ;; restore PIT default mode and rate
                CYCLE   BIOS_RATE

                ;; restore old handler
                lds     dx, cs:prev_hnd
                mov     ax, DOS_INT_VECTOR_SET*256 + 08h
                int     DOS

                ;; and 1Ch vector
                lds     dx, cs:old_int1C
                mov     ax, DOS_INT_VECTOR_SET*256 + 1Ch
                int     DOS

                sti

                mov     cs:bios_cnt, BIOS_RATE  ;; set to default
                mov     cs:rate, BIOS_RATE      ;; /
                mov     cs:divisor, BIOS_RATE   ;; /

@@exit:         ret
tmrEnd          endp

;;::::::::::::::
tmrNew          proc    public uses di es,\
                        tmr:far ptr TMR,\
                        mode:word,\
                        _rate:dword

                mov     cs:working, TRUE        ;; don't disturb

                les     di, tmr                 ;; es:di -> new timer struct

                ;; if timer already on queue, delete it
                cmp     es:[di].TMR.state, T_OFF
                je      @@insert
                mov     es:[di].TMR.state, T_OFF;; turn off
                call    tmr_delete

@@insert:       mov     eax, _rate
                mov     dx, mode
                mov     es:[di].TMR.rate, eax   ;; save
                mov     es:[di].TMR.mode, dx    ;; /
                add     es:[di].TMR.cnt, eax    ;; timer->cnt+= freq
                jle     @@exit                  ;; timer->cnt <= 0? exit
                mov     es:[di].TMR.state, T_ON ;; turn on
                call    tmr_insert

@@exit:         mov     cs:working, FALSE
                ret
tmrNew          endp

;;::::::::::::::
tmrDel          proc    public uses di es,\
                        tmr:far ptr TMR

                mov     cs:working, TRUE        ;; don't disturb

                les     di, tmr                 ;; es:di -> timer struct

                cmp     es:[di].TMR.state, T_OFF
                je      @@exit                  ;; timer->state= OFF? exit
                mov     es:[di].TMR.state, T_OFF;; turn off
                call    tmr_delete

@@exit:         mov     cs:working, FALSE
                ret
tmrDel          endp

;;::::::::::::::
tmrResume       proc    public uses di es,\
                        tmr:far ptr TMR

                mov     cs:working, TRUE        ;; don't disturb

                les     di, tmr                 ;; es:di -> timer struct

                cmp     es:[di].TMR.state, T_ON
                je      @@exit                  ;; timer->state= ON? exit

                mov     eax, es:[di].TMR.cnt
                test    eax, eax
                jle     @@exit                  ;; timer->cnt <= 0? exit
                mov     es:[di].TMR.state, T_ON ;; turn on
                call    tmr_insert

@@exit:         mov     cs:working, FALSE
                ret
tmrResume       endp

;;::::::::::::::
tmrCallbkSet    proc    public uses di es,\
                        tmr:far ptr TMR,\
                        callbk:dword

                mov     cs:working, TRUE        ;; don't disturb

                les     di, tmr                 ;; es:di -> timer struct
                mov     eax, callbk
                mov     es:[di].TMR.callbkProc, eax
                mov     es:[di].TMR.callbkID, T_CALLBKID

                mov     cs:working, FALSE
                ret
tmrCallbkSet    endp

;;::::::::::::::
tmrCallbkCancel proc    public uses di es,\
                        tmr:far ptr TMR

                mov     cs:working, TRUE        ;; don't disturb

                les     di, tmr                 ;; es:di -> timer struct
                mov     es:[di].TMR.callbkProc, 0
                mov     es:[di].TMR.callbkID, 0

                mov     cs:working, FALSE
                ret
tmrCallbkCancel endp

;;::::::::::::::
tmrUs2Freq      proc    public microsecs:dword
                local   result:dword

                fild    microsecs
                fmul    cs:us2freq
                fistp   result

                mov     ax, W result+0
                mov     dx, W result+2

                ret
tmrUs2Freq      endp

;;::::::::::::::
tmrMs2Freq      proc    public milisecs:dword
                local   result:dword

                fild    milisecs
                fmul    cs:ms2freq
                fistp   result

                mov     ax, W result+0
                mov     dx, W result+2

                ret
tmrMs2Freq      endp

;;::::::::::::::
tmrTick2Freq    proc    public ticks:dword
                local   result:dword

                fild    ticks
                fmul    cs:tick2freq
                fistp   result

                mov     ax, W result+0
                mov     dx, W result+2

                ret
tmrTick2Freq    endp

;;::::::::::::::
tmrSec2Freq     proc    public seconds:word
                local   result:dword

                fild    seconds
                fmul    cs:sec2freq
                fistp   result

                mov     ax, W result+0
                mov     dx, W result+2

                ret
tmrSec2Freq     endp

;;::::::::::::::
tmrMin2Freq     proc    public minutes:word
                local   result:dword

                fild    minutes
                fmul    cs:min2freq
                fistp   result

                mov     ax, W result+0
                mov     dx, W result+2

                ret
tmrMin2Freq     endp

;;::::::::::::::
;;  in: eax= rate
;;
;; out: eax= divisor
oneshot_update  proc    near uses edx si ds

                cmp     cs:oneshot_q.head, NULL
                je      @@default               ;; no timers?

                lds     si, cs:oneshot_q.head   ;; ds:si -> head

                sub     [si].TMR.cnt, eax       ;; timer.cnt-= rate
                jg      @@done                  ;; > 0?

@@del_timer:    cmp     [si].TMR.callbkID, T_CALLBKID
                jne     @F

		PS      ds, es
                mov	edx, [si].TMR.callbkProc
                push	@data
                pop	ds
		pushad
                PS	cs, O @@ret
                push	edx
                retf
@@ret:          popad
                PP      es, ds

@@:		dec     cs:oneshot_q.timers     ;; delete from queue
                mov     [si].TMR.state, T_OFF   ;; turn off
                mov     edx, [si].TMR.cnt       ;; get timer.cnt
                lds     si, [si].TMR.next       ;; timer= timer.next
                mov     ax, ds
                test    ax, ax
                jz      @@empty                 ;; last timer?

                ;; timer.cnt-= -timer.prev.cnt
                add     [si].TMR.cnt, edx
                jle     @@del_timer             ;; delete this timer too?

                mov     W cs:oneshot_q.head+0, si ;; head= timer
                mov     W cs:oneshot_q.head+2, ds ;; /
                mov     [si].TMR.prev, NULL     ;; head.prev= NULL

                ;; if timer.cnt < max rate, return it
@@done:         mov     eax, [si].TMR.cnt
                cmp     eax, BIOS_RATE
                jg      @@default
                ret

@@empty:        mov     cs:oneshot_q.head, NULL ;; head= NULL

@@default:      mov     eax, BIOS_RATE          ;; max divisor
                ret
oneshot_update  endp

;;::::::::::::::
;;  in: eax= rate
;;
;; out: eax= divisor
autoinit_update proc    near uses ecx edx si ds

                mov     ecx, BIOS_RATE          ;; max rate

                cmp     cs:autoinit_q.head, NULL
                je      @@done                  ;; no timers?

                lds     si, cs:autoinit_q.head  ;; ds:si -> head

@@loop:         sub     [si].TMR.cnt, eax       ;; timer.cnt-= rate
                jg      @@next                  ;; > 0?

                ;;
                ;; The callback
                ;;
                cmp     [si].TMR.callbkID, T_CALLBKID
                jne     @F
                PS      ds, es
                mov	edx, [si].TMR.callbkProc
                push	@data
                pop     ds
                pushad
                PS	cs, O @@ret
                push	edx
                retf
@@ret:          popad
                PP      es, ds

@@:             inc     [si].TMR.counter        ;; ++timer.counter
                mov     edx, [si].TMR.rate      ;; timer.cnt= timer.rate
                add     [si].TMR.cnt, edx       ;; /

@@next:         cmp     [si].TMR.cnt, ecx
                jge     @F                      ;; cnt >= current min cnt?
                mov     ecx, [si].TMR.cnt

@@:             lds     si, [si].TMR.next       ;; timer= timer.next
                mov     dx, ds
                test    dx, dx
                jnz     @@loop                  ;; not last timer?

@@done:         mov     cs:autoinit_q.min_cnt, ecx
                mov     eax, ecx
                ret
autoinit_update endp

;;:::
chain           word    FALSE
handler_zerodet proc
                cmp     cs:working, FALSE
                je      @F                      ;; not working?

                ;; queue being modified. try later
                push    ax
                add     cs:rate, 2000h          ;; update rate
                ZERODET 2000h                   ;; reprogram PIT

                mov     al, PIC_EOI             ;; non-specific EOI for PIC
                out     PIC_OCW, al             ;; /
                pop     ax
                iret

@@:             PS      eax, edx
                mov     cs:working, TRUE        ;; do not disturb

                mov     eax, cs:rate

                sub     cs:bios_cnt, eax        ;; bios_cnt-= rate
                jg      @F                      ;; > 0?
                add     cs:bios_cnt, BIOS_RATE  ;; no, re-set
                mov     cs:chain, TRUE          ;; must chain to old handler

@@:             ;; update both queues (oneshot and autoinit)
                push    eax
                call    oneshot_update
                mov     edx, eax
                pop     eax
                call    autoinit_update
                cmp     eax, edx
                jle     @F
                mov     eax, edx

@@:             ;; if bios_cnt < new rate, new rate= bios_cnt
                cmp     eax, cs:bios_cnt
                jle     @F
                mov     eax, cs:bios_cnt

@@:             ;; rate too tiny?
                cmp     eax, 400h
                jge     @F
                mov     eax, 400h               ;; set a safe value

@@:             mov     cs:rate, eax            ;; save new rate
                ZERODET eax                     ;; reprogram PIT

                mov     cs:working, FALSE

                ;; chain to old handler?
                cmp     cs:chain, TRUE
                je      @F

                mov     al, PIC_EOI             ;; non-specific EOI for PIC
                out     PIC_OCW, al             ;; /
                PP      edx, eax
                iret

@@:             mov     cs:chain, FALSE
                PP      edx, eax
                jmp     cs:prev_hnd             ;; chain
handler_zerodet endp

;;:::
handler_cycle   proc
		cmp     cs:working, FALSE
                je      @F                      ;; not working?

                ;; queue being modified. try next time
                add     cs:rate, CYCLE_RATE     ;; update rate

                push    ax
                mov     al, PIC_EOI             ;; non-specific EOI for PIC
                out     PIC_OCW, al             ;; /
                pop     ax
                iret

@@:             PS      eax
                mov     cs:working, TRUE        ;; do not disturb

                ;; eax= rate; rate= CYCLE_RATE
                mov     eax, CYCLE_RATE
                xchg    eax, cs:rate

                sub     cs:bios_cnt, eax        ;; bios_cnt-= rate
                ja      @F                      ;; > 0?
                add     cs:bios_cnt, BIOS_RATE  ;; no, re-set

                ;; call old handler
                pushf
                call    cs:prev_hnd
                jmp     short @@update

@@:             ;; allow hardware ints to occur
                push    ax
                mov     al, PIC_EOI             ;; non-specific EOI for PIC
                out     PIC_OCW, al             ;; /
                pop     ax

@@update:       sti
                ;; update both queues (oneshot and autoinit)
                push    eax
                call    oneshot_update
                pop     eax
                call    autoinit_update

                mov     cs:working, FALSE
                PP      eax
                iret
handler_cycle   endp

;;:::
;; out: edx= (rate - divisor) + (divisor - pit.rate)
elapsed         proc    near uses eax ebx

                cmp     cs:installed, TRUE
                jne     @@not_running

                mov     al, PIT_SEL_CNT_0 or PIT_LATCH_CMD or PIT_STL_BIN
                out     PIT_MODE, al

                mov     edx, cs:rate

                xor     ebx, ebx
                in      al, PIT_CNT_0           ;; lsb
                mov     bl, al
                in      al, PIT_CNT_0           ;; msb
                mov     bh, al

                mov     eax, cs:divisor
                sub     edx, eax

                sub     eax, ebx
                jc      @@cycle                 ;; cycle mode?
                add     edx, eax
                ret

@@cycle:        add     eax, 10000h             ;; 64k - -(divisor - pit.cnt)
                add     edx, eax
                ret

@@not_running:  xor     edx, edx                ;; return 0
                ret
elapsed         endp

;;:::
;;  in: eax= new rate
;;      ecx= elapsed
;;
;; out: CF set if reprog'ed
reprog          proc    near

                cmp     cs:windowsware, TRUE
                je      @@cycle
                cmp     cs:installed, TRUE
                jne     @@not_running

                sub     cs:bios_cnt, ecx        ;; bios_cnt-= elapsed

                ;; bios_cnt < new rate? new rate= bios_cnt
                cmp     eax, cs:bios_cnt
                jle     @F
                mov     eax, cs:bios_cnt

@@:             ;; rate too tiny?
                cmp     eax, 400h
                jge     @F
                mov     eax, 400h               ;; set a safe value

@@:             mov     cs:rate, eax            ;; save new rate
                ZERODET eax                     ;; reprogram PIT
                stc
                ret

@@cycle:        mov     cs:rate, CYCLE_RATE
                clc
                ret

@@not_running:  ;; bios_rate < new rate? new rate= bios_rate
                cmp     eax, BIOS_RATE
                jle     @F
                mov     cs:rate, BIOS_RATE
                ret

@@:             ;; rate too tiny?
                cmp     eax, 400h
                jge     @F
                mov     eax, 400h               ;; set a safe value
@@:             mov     cs:rate, eax            ;; save new rate
                ret
reprog          endp

;;:::
;;  in: eax= new rate
;;      ecx= elapsed
;;
;; out: CF set if reprog'ed
oneshot_reprog  proc    near uses si ds

                ;; new rate < autoinit queue min rate?
                cmp     cs:autoinit_q.min_cnt, 0
                jle     @F
                cmp     eax, cs:autoinit_q.min_cnt
                jge     @@exit

@@:             ;; update autoinit queue (change all timers' counters)
                lds     si, cs:autoinit_q.head
                jmp     short @@test
@@loop:         sub     ds:[si].TMR.cnt, ecx    ;; timer->cnt-= elapsed
                lds     si, ds:[si].TMR.next
@@test:         mov     dx, ds
                test    dx, dx
                jnz     @@loop

                call    reprog

@@exit:         ret
oneshot_reprog  endp

;;:::
;;  in: es:di -> timer struct
;;      eax= timer.cnt
;;      edx= time elapsed
oneshot_insert  proc    near

                mov     ecx, edx                ;; save
                neg     edx                     ;; -time elapsed

                inc     cs:oneshot_q.timers     ;; ++timers

                mov     ebx, cs:oneshot_q.head  ;; t= queue head
                test    ebx, ebx
                jz      @@first                 ;; head= NULL?

@@loop:         mov     si, bx                  ;; ds:si= t
                ror     ebx, 16                 ;; /
                mov     ds, bx                  ;; /

                add     edx, ds:[si].TMR.cnt    ;; edx+= t->cnt
                cmp     eax, edx
                jl      @@check                 ;; timer->cnt < edx?

                mov     ebx, ds:[si].TMR.next   ;; t= t->next
                test    ebx, ebx
                jnz     @@loop                  ;; t != NULL? loop

                ;; timer will be the tail of queue
                sub     es:[di].TMR.cnt, edx    ;; timer->cnt-= (counters-elapsed)
                mov     W es:[di].TMR.prev+0, si;; timer->prev= t
                mov     W es:[di].TMR.prev+2, ds;; /
                mov     W ds:[si].TMR.next+0, di;; t->next= timer
                mov     W ds:[si].TMR.next+2, es;; /
                mov     es:[di].TMR.next, ebx   ;; timer->next= NULL
                jmp     short @@exit

@@check:        sub     edx, ds:[si].TMR.cnt    ;; edx-= t->cnt
                jnle    @@middle                ;; t->cnt <= 0?

                mov     eax, es:[di].TMR.cnt    ;; t->cnt-= timer->cnt +
                add     edx, eax                ;;          elapsed
                sub     ds:[si].TMR.cnt, edx    ;; /

@@first:        ;; timer will be the head of queue
                rol     ebx, 16                 ;; restore ebx
                mov     es:[di].TMR.next, ebx   ;; timer->next= t

                test    ebx, ebx
                jz      @F                      ;; t= NULL?
                mov     W ds:[si].TMR.prev+0, di;; t->prev= timer
                mov     W ds:[si].TMR.prev+2, es;; /

@@:             mov     es:[di].TMR.prev, NULL  ;; timer->prev= NULL

                mov     W cs:oneshot_q.head+0, di ;; head= timer
                mov     W cs:oneshot_q.head+2, es ;; /

                call    oneshot_reprog          ;; reprog(timer->cnt)
                jc      @@exit                  ;; reprog'ed?
                add     es:[di].TMR.cnt, ecx    ;; timer->cnt+= elapsed
                jmp     short @@exit

@@middle:       ;; tmr is in the middle of queue
                sub     es:[di].TMR.cnt, edx    ;; timer->cnt-= (prev cnts-elapsed)
                mov     eax, es:[di].TMR.cnt
                sub     ds:[si].TMR.cnt, eax    ;; t->cnt-= timer->cnt

                mov     W es:[di].TMR.next+0, si;; timer->next= t
                mov     W es:[di].TMR.next+2, ds;; /
                mov     ebx, ds:[si].TMR.prev   ;; ebx=ds:bx= t->prev
                mov     ax, W ds:[si].TMR.prev+2;; /
                mov     es:[di].TMR.prev, ebx   ;; timer->prev= t->prev
                mov     W ds:[si].TMR.prev+0, di;; t->prev= timer
                mov     W ds:[si].TMR.prev+2, es;; /
                mov     ds, ax
                mov     W ds:[bx].TMR.next+0, di;; t->prev->next= timer
                mov     W ds:[bx].TMR.next+2, es;; /

@@exit:         ret
oneshot_insert  endp

;;:::
;;  in: eax= new rate
;;      ecx= elapsed
;;
;; out: CF set if reprog'ed
autoinit_reprog proc    near uses si ds

                ;; new rate < oneshot queue min rate?
                cmp     cs:oneshot_q.head, NULL
                je      @F
                lds     si, cs:oneshot_q.head
                cmp     eax, ds:[si].TMR.cnt
                jge     @@exit

                ;; update onshot queue (change 1st timer' counter)
                sub     ds:[si].TMR.cnt, ecx    ;; timer->cnt-= elapsed

@@:             call    reprog

@@exit:         ret
autoinit_reprog endp

;;:::
;;  in: es:di -> timer struct
;;      eax= timer.cnt
;;      edx= time elapsed
autoinit_insert proc    near

                mov     ecx, edx                ;; save

                inc     cs:autoinit_q.timers    ;; ++timers

                mov     ebx, cs:autoinit_q.tail
                mov     W cs:autoinit_q.tail+0, di ;; tail= timer
                mov     W cs:autoinit_q.tail+2, es ;; /
                mov     es:[di].TMR.prev, ebx   ;; timer->prev= tail
                mov     es:[di].TMR.next, NULL  ;; timer->next= NULL
                test    ebx, ebx
                jz      @@first                 ;; tail= NULL?
                mov     si, bx                  ;; ds:si-> tail
                shr     ebx, 16                 ;; /
                mov     ds, bx                  ;; /
                mov     W ds:[si].TMR.next+0, di;; tail->next= timer
                mov     W ds:[si].TMR.next+2, es;; /
                jmp     short @@min

@@first:        mov     W cs:autoinit_q.head+0, di ;; head= timer
                mov     W cs:autoinit_q.head+2, es ;; /

@@min:          ;; timer.cnt < min.cnt?
                cmp     cs:autoinit_q.min_cnt, 0
                jle     @@rep
                cmp     eax, cs:autoinit_q.min_cnt
                jge     @F
@@rep:          mov     cs:autoinit_q.min_cnt, eax
                call    autoinit_reprog
                jnc     @F                      ;; not reprog'ed?

@@exit:         ret

@@:             add     es:[di].TMR.cnt, ecx    ;; timer->cnt+= elapsed
                jmp     short @@exit
autoinit_insert endp

;;:::
;;  in: es:di -> timer struct
tmr_insert      proc    near uses es ds
                pushad

                call    elapsed

                mov     eax, es:[di].TMR.cnt

                cmp     es:[di].TMR.mode, T_ONESHOT
                jne     @F
                call    oneshot_insert
                jmp     short @@exit

@@:             call    autoinit_insert

@@exit:         popad
                ret
tmr_insert      endp

;;:::
;;  in: es:di -> timer struct
oneshot_delete  proc    near

                dec     cs:oneshot_q.timers     ;; --timers

                mov     eax, es:[di].TMR.cnt

                mov     esi, es:[di].TMR.prev   ;; esi=ds:si= timer->prev
                mov     ds, W es:[di].TMR.prev+2;; /
                mov     ebx, es:[di].TMR.next   ;; ebx=es:bx= timer->next
                mov     es, W es:[di].TMR.next+2;; /

                test    ebx, ebx
                jz      @F                      ;; timer->next= NULL?
                add     es:[bx].TMR.cnt, eax    ;; timer->next->cnt+= timer->cnt
                mov     es:[bx].TMR.prev, esi   ;; timer->next->prev= timer->prev

@@:             test    esi, esi
                jz      @@set_head              ;; timer->prev= NULL?
                mov     ds:[si].TMR.next, ebx   ;; timer->prev->next= timer->next

@@exit:         ret

@@set_head:     mov     cs:oneshot_q.head, ebx  ;; head= timer->next

                mov     eax, BIOS_RATE          ;; assume no next
                test    ebx, ebx
                jz      @F                      ;; timer->next= NULL?
                mov     eax, ds:[bx].TMR.cnt
                call    elapsed
                sub     eax, edx
                mov     ds:[bx].TMR.cnt, eax    ;; timer->next->cnt-= elapsed

@@:             mov     ecx, edx
                call    oneshot_reprog          ;; reprog(timer->next->cnt)
                jmp     short @@exit
oneshot_delete  endp

;;:::
;;  in: es:di -> timer struct
autoinit_delete proc    near

                dec     cs:autoinit_q.timers    ;; --timers

                mov     eax, es:[di].TMR.cnt
                mov     es:[di].TMR.cnt, 0      ;; timer->cnt= 0

                mov     esi, es:[di].TMR.prev   ;; esi=ds:si= timer->prev
                mov     ds, W es:[di].TMR.prev+2;; /
                mov     ebx, es:[di].TMR.next   ;; ebx=es:bx= timer->next
                mov     es, W es:[di].TMR.next+2;; /

                test    ebx, ebx
                jz      @@set_tail              ;; timer->next= NULL?
                mov     es:[bx].TMR.prev, esi   ;; timer->next->prev= timer->prev
                jmp     short @@prev

@@set_tail:     mov     cs:autoinit_q.tail, esi ;; tail= timer->prev

@@prev:         test    esi, esi
                jz      @@set_head              ;; timer->prev= NULL?
                mov     ds:[si].TMR.next, ebx   ;; timer->prev->next= timer->next
                jmp     short @@min

@@set_head:     mov     cs:autoinit_q.head, ebx ;; head= timer->next
                test    ebx, ebx
                jnz     @@min                   ;; no timers?
                mov     cs:autoinit_q.min_cnt, 0
                jmp     short @@exit

@@min:          ;; timer.cnt= min cnt?
                cmp     eax, cs:autoinit_q.min_cnt
                jne     @@exit
                mov     eax, BIOS_RATE

                ;; search by new min cnt in autoinit queue
                lds     si, cs:autoinit_q.head
@@loop:         cmp     ds:[si].TMR.cnt, eax
                jge     @@next
                mov     eax, ds:[si].TMR.cnt
@@next:         lds     si, ds:[si].TMR.next
                mov     dx, ds
                test    dx, dx
                jnz     @@loop

                mov     cs:autoinit_q.min_cnt, eax

                ;; reprog if needed
                call    elapsed
                mov     ecx, edx
                call    autoinit_reprog         ;; reprog(min cnt)

@@exit:         ret
autoinit_delete endp

;;:::
;;  in: es:di -> timer struct
tmr_delete      proc    near uses es ds
                pushad

                cmp     es:[di].TMR.mode, T_ONESHOT
                jne     @F
                call    oneshot_delete
                jmp     short @@exit

@@:             call    autoinit_delete

@@exit:         popad
                ret
tmr_delete      endp
                end
