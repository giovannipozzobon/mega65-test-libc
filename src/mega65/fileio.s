
	.rtmodel version,"1"
	.rtmodel codeModel,"plain"
	.rtmodel core,"45gs02"
	.rtmodel target,"mega65"
	.extern _Zp
	.extern version
	.extern filenametoopen

    .section code_2,text
	.public toggle_rom_write_protect, hyppo_mount_d81_0, chdir, findfile, read512, open, closeall, close, chdirroot, gethyppoversion	


hyppo_mount_d81_0:
	jsr copy_string_to_0100
	jsr setname_0100	
	lda #0x40
	sta 0xd640
	clv
	rts


toggle_rom_write_protect:
	lda #0x70
	sta 0xd640
	clv
	;ldx #0
	lda #0x00
	rts


chdir:
	;; Get pointer to file name
	;sta ptr1+0
	;stx ptr1+1	
	jsr copy_string_to_0100
	jsr setname_0100	

	;; Find file
	; Look for file on FAT file system via hypervisor calls
	lda #0x34
	sta 0xd640
	clv
	bcs chdir_file_exists

	;; No such file.
	lda #0xff
	;tax
	rts

chdir_file_exists:	
	;; Actually call chdir
	lda #0x0C
	sta 0xd640
	clv
	lda #0x18
	sta 0xD640
	clv
	;ldx #0x00
	lda #0x00
	rts



findfile:
	;; Get pointer to file name

	jsr copy_string_to_0100
	jsr setname_0100	

	;; Find file
	; Look for file on FAT file system via hypervisor calls
	lda #0x34
	sta 0xd640
	clv
	bcs file_exists

	;; No such file.
	lda #0xff
file_exists:
	rts



read512:
	;;  Get pointer to buffer
	;sta ptr1+0
	;stx ptr1+1
	;; Select current file
	;; XXX - Not currently implemented
	;; Read the next sector of data
	lda #0x1A
	sta 0xD640
	clv
	ldx #0x00
	;; Number of bytes read returned in X and Y
	;; Store these for returning
	stx tmp2
	sty tmp3
	;; Make sure SD buffer is selected, not FDC buffer
	lda #0x80
	tsb 0xD689
	;; Copy the full 512 bytes from the sector buffer at 0xFFD6E00
	;; (This saves the need to mess with mapping/unmapping the sector
	;; buffer).
	;; Get address to save to
	lda _Zp
	sta copysectorbuffer_destaddr+0
	lda _Zp+1
	sta copysectorbuffer_destaddr+1

	;; Execute DMA job
	lda #0x00
	sta 0xd702
	sta 0xd704
	;lda #>dmalist_copysectorbuffer
	lda #.byte1(dmalist_copysectorbuffer)
	sta 0xd701
	lda #.byte0(dmalist_copysectorbuffer)
	sta 0xd705

	;; Retrieve the return value
	lda tmp2
	sta _Zp
	lda tmp3
	sta _Zp+1
	rts	


copy_string_to_0100:	
    ;; Copy file name
	phy
	ldy #0
NameCopyLoop:
	lda (_Zp),y
	sta 0x0100,y
	iny
	cmp #0
	bne NameCopyLoop
	ply
	rts	

setname_0100:
	;;  Call dos_setname()
	;ldy #>0x0100
	;ldx #<0x0100
	ldy #.byte1(0x0100)
	ldx #.byte0(0x0100)	
	lda #0x2E                ; dos_setname Hypervisor trap
	sta 0xD640               ; Do hypervisor trap
	clv                     ; Wasted instruction slot required following hyper trap instruction
	;; XXX Check for error (carry would be clear)
	bcs setname_ok
	lda #0xff
setname_ok:
	rts
	

open:
	;; Get pointer to file name
	;sta ptr1+0
	;stx ptr1+1
	
	jsr copy_string_to_0100
	jsr setname_0100	

	;; Find file
	; Look for file on FAT file system via hypervisor calls
	lda #0x34
	sta 0xd640
	nop
	bcs open_file_exists
	;; No such file.
	lda #0xff
	tax
	rts

open_file_exists:	
	;; Actually call open
	lda #0x00; hyppo_getversion
	sta 0xd640; Seems unused; sets A, X, Y, Z
	clv
	lda #0x18
	sta 0xD640
	clv
	ldx #0x00
	ldz #0x00; clear Z due to hyppo_getversion
	rts


closeall:
	lda #0x22
	sta 0xD640
	clv
	;ldx #0x00
	lda #0x00
	rts


close:
	tax
	lda #0x20
	sta 0xD640
	clv
	;ldx #0x00
	lda #0x00
	rts

chdirroot:
	;; Change to root directory of volume
	lda #0x3C
	sta 0xd640
	clv
	;ldx #0x00
	lda #0x00
	rts


gethyppoversion:
	lda #0
	sta 0xD640    ; output to A, X, Y, Z
	clv

	sta version+0
	stx version+1
	sty version+2
	stz version+3
	
	rts

	.section data, data

dmalist_copysectorbuffer:
	;; Copy 0xFFD6E00 - 0xFFD6FFF down to low memory 
	;; MEGA65 Enhanced DMA options
        .byte 0x0A  ;; Request format is F018A
        .byte 0x80,0xFF ;; Source is 0xFFxxxxx
        .byte 0x81,0x00 ;; Destination is 0xFF
        .byte 0x00  ;; No more options
        ;; F018A DMA list
        ;; (MB offsets get set in routine)
        .byte 0x00 ;; copy + last request in chain
        .word 0x0200 ;; size of copy is 512 bytes
        .word 0x6E00 ;; starting at 0x6E00
        .byte 0x0D   ;; of bank 0xD
copysectorbuffer_destaddr:	
        .word 0x8000 ;; destination address is 0x8000
        .byte 0x00   ;; of bank 0x0
        .word 0x0000 ;; modulo (unused)

tmp2:
	.byte 0x00
tmp3:
	.byte 0x00