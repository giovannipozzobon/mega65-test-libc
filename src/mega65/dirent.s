	.rtmodel version,"1"
	.rtmodel codeModel,"plain"
	.rtmodel core,"45gs02"
	.rtmodel target,"mega65"
	.extern _Zp
    .extern m65_dirent_exchange

    .section code_2,text
	.public opendir, readdir, closedir	
	

	;; closedir takes file descriptor as argument (appears in A)
closedir:
	tax
	lda #0x16
	sta 0xD640
	clv
	ldx #0x00
	rts
	
	;; Opendir takes no arguments and returns File descriptor in A
opendir:
	lda #0x12
	sta 0xD640
	clv
	ldx #0x00
	rts

	;; readdir takes the file descriptor returned by opendir as argument
	;; and gets a pointer to a MEGA65 DOS dirent structure.
	;; Again, the annoyance of the MEGA65 Hypervisor requiring a page aligned
	;; transfer area is a nuisance here. We will use 0x0400-0x04FF, and then
	;; copy the result into a regular C dirent structure
	;;
	;; d_ino = first cluster of file
	;; d_off = offset of directory entry in cluster
	;; d_reclen = size of the dirent on disk (32 bytes)
	;; d_type = file/directory type
	;; d_name = name of file
readdir:
	pha
	phx
	sty m65_struct_dir_addr
	;; First, clear out the dirent
	ldx #0
	txa
l1:
	sta m65_struct_dir_addr,x	
	dex
	bne l1

	;; Third, call the hypervisor trap
	;; File descriptor gets passed in in X.
	;; Result gets written to transfer area we setup at 0x0400
	plx
	pla
;	ldy #>0x0400 		; write dirent to 0x0400 
	ldy #.byte1 0x0400 		
	lda #0x14
	sta 0xD640
	clv
	bcs readDirSuccess
	;;  Return end of directory
	lda #0x00
	ldx #0x00
	rts

readDirSuccess:
	;;  Copy file name
	ldx #0x3f
l2:
	lda 0x0400,x
	sta m65_struct_dir_addr+4+2+4+2,x
	dex
	bpl l2
	;; make sure it is null terminated
	ldx 0x0400+64
	lda #0x00
	sta m65_struct_dir_addr+4+2+4+2,x

	;; Inode = cluster from offset 64+1+12 = 77
	ldx #0x03
l3:
	lda 0x0477,x
	sta m65_struct_dir_addr+0,x
	dex
	bpl l3
	;; d_off stays zero as it is not meaningful here
	;; d_reclen we preload with the length of the file (this saves calling stat() on the MEGA65)
	ldx #3
l4:
	lda 0x0400+64+1+12+4,x
	sta m65_struct_dir_addr+4+2,x
	dex
	bpl l4
	;; File type and attributes
	;; XXX - We should translate these to C style meanings
	lda 0x0400+64+1+12+4+4
	sta m65_struct_dir_addr+4+2+4
	;; Return address of dirent structure
	;lda #<zp:m65_dirent_exchange
	;ldx #>zp:m65_dirent_exchange	
	;lda #.byte0 m65_dirent_exchange
	;ldx #.byte1 m65_dirent_exchange	

	rts

	.section data, data

	m65_struct_dir_addr: .word 0x00   