                .model  medium, pascal
		.586
		.mmx
                option  proc:private

                include ugl.inc

                include dcclip.inc

                include 2dfx.inc


		TFX_MAX_WIDTH	equ (640 + 8)		;; +8 f/ remainder



		TFXGRP	group tfx_const, tfx_data, tfx_bss

tfx_const	segment para READONLY public use16 'TFXCONST'
tfx_const	ends
tfx_data	segment para public use16 'TFXDATA'
tfx_data	ends
tfx_bss		segment para public use16 'TFXBSS'
tfx_bss		ends


		;; UGL_CODE
		externdef       tfx$scale_sel:near
		externdef       tfx$invert_sel:near
		externdef       tfx$unpk_sel:near, tfx$dst_unpk_sel:near
		externdef       tfx$solid_sel:near, tfx$lut_sel:near, tfx$mono_sel:near
		externdef       tfx$clrsub2_sel:near
		externdef       tfx$blend_sel:near
		externdef       tfx$pack_sel:near

		tfx$set_stack	proto near :word


		;; tfx_const
		externdef       tfx_mask8:qword, tfx_mask15:qword, tfx_mask16:qword, tfx_mask32:qword

		;; tfx_bss
		externdef       tfx_srcMask:byte
		externdef       tfx_srcRed:byte, tfx_srcGreen:byte, tfx_srcBlue:byte
		externdef       tfx_dstRed:byte, tfx_dstGreen:byte, tfx_dstBlue:byte
		externdef       tfx_srcBuffer:byte

		;; tfx_data
		externdef       tfx_stack:word
		externdef       tfx_solid_r:qword, tfx_solid_g:qword, tfx_solid_b:qword
		externdef       tfx_alpha:qword
		externdef       tfx_clut:dword
		externdef       tfx_factor_r:qword, tfx_factor_g:qword, tfx_factor_b:qword

		;; data
		externdef       tfx_u:dword, tfx_v:dword, tfx_du:dword, tfx_dv:dword



