	.data
fname:	.asciiz "blank.bmp"		# input file name
outfn:	.asciiz "result.bmp"	
imgInf:	.word 512, 512, pImg, 0, 0, 0
handle: .word 0
fsize:	.word 0
# to avoid memory allocation image buffer is defined
# big enough to store 512x512 black&white image
# note that we know exactly the size of the header
# pImgae is the first byte of image itself
pFile:	.space 62
pImg:	.space 36000

	.text
main:	
	# open input file for reading
	# the file has to be in current working directory
	# (as recognized by mars simulator)
	la $a0, fname
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall
	# read the whole file at once into pFile buffer
	# (note the effective size of this buffer)
	move $a0, $v0
	sw $a0, handle
	la $a1, pFile
	la $a2, 36062
	li $v0, 14
	syscall
	# store file size for further use and print it
	move $a0, $v0
	sw $a0, fsize
	li $v0, 1
	syscall
	# close file
	li $v0, 16
	syscall
	
######################################
#PROJECT IMPLEMENTATION

	la	$t0, imgInf
	la	$a0, ($t0)
	li	$a1, 256
	li	$a2, 256
	jal 	_move_to
	
	li	$s0, 256
	li	$s1, 0
_main_loop:
	subiu	$s0, $s0, 3
	not	$s1, $s1
	la  	$a0, ($v0)
	la	$a1, ($s1)
	jal 	_set_color
	
	la	$v0, ($a0)
	la	$a1, ($s0)
	jal	_draw_circle
	
	bgtz 	$s0, _main_loop

######################################

	# open the result file for writing
	la $a0, outfn
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	# print handle of the file 
	move $a0, $v0
	sw $a0, handle
	li $v0, 1
	syscall
	# save the file (file size is restored from fsize)
	la $a1, pFile
	lw $a2, fsize
	li $v0, 15
	syscall
	# close file
	li $v0, 16
	syscall
		
	#terminate
	li $v0, 10
	syscall

	
#$a0 - imgInfo* pImg
#$a1 - int col
#v0 - imgInfo* return
_set_color:
	sgeu   	$t0, $a1, 1	
	sw 	$t0, 20($a0)
	la 	$v0, ($a0)
	jr 	$ra

#$a0 - imgInfo* pImg
#$a1 - int x
#$a2 - int y
#$v0 - imgInfo* return
#dont move x if x >= width or y < 0
#dont move y if y >= height or y < 0
_move_to:
	lw 	$t0, ($a0)
	bge	$a1, $t0, _move_to_next
	bltz	$a1, _move_to_next
	sw 	$a1, 12($a0)
_move_to_next:
	lw	$t0, 4($a0)
	bge 	$a2, $t0, _move_to_ret
	bltz 	$a2, _move_to_ret
	sw 	$a2, 16($a0)
_move_to_ret:
	la 	$v0, ($a0)
	jr	$ra

# == parameters	== #
#$a0 - imgInfo* imgptr
#$a1 - int radius
#Width =  ($a0) 		1st element of imgInfo
#Height = 4($a0) 		2nd element of imgInfo
#pointer to pImg = 8($a0)	3rd element of imgInfo
#Circle center X = 12($a0)	4th element of imgInfo
#Circle center Y = 16($a0)	5th element of imgInfo
#Drawing Colour = 20($a0)	6th element of imgInfo
# == used registers == #
#$s0 - decision parameter
#$s1 - x
#$s2 - y
#$s3 - Width
#$s4 - Height
#$s5 - CX
#$s6 - CY
#$s7 - Colour
#
#t9 - pImg

_draw_circle:
	#prolog
	sw	$s0, ($sp)
	subiu	$sp, $sp, 4
	sw	$s1, ($sp)
	subiu	$sp, $sp, 4
	sw	$s2, ($sp)
	subiu	$sp, $sp, 4
	sw	$s3, ($sp)
	subiu	$sp, $sp, 4
	sw	$s4, ($sp)
	subiu	$sp, $sp, 4
	sw	$s5, ($sp)
	subiu	$sp, $sp, 4
	sw	$s6, ($sp)
	subiu	$sp, $sp, 4
	sw	$s7, ($sp)
	subiu	$sp, $sp, 4
	#prolog end
	
	lw	$s3, ($a0)	#initialize s3 (Width): ($a0) 
	lw	$s4, 4($a0)	#initialize s4 (Height): 4($a0) 
	lw	$t9, 8($a0)	#initialize t9 (pImg): 8($a0)
	lw	$s5, 12($a0)	#initialize s5 (Cx): 12($a0) 
	lw	$s6, 16($a0)	#initialize s6 (Cy): 16($a0) 
	lw	$s7, 20($a0)	#initialize s7 (Colour): 20($a0) 
	
	li	$s1, 0		#initialize s1: x = 0
	la	$s2, ($a1)	#initialize s2: y = r
	
	addu	$t0, $s6, $a1
	bgeu 	$t0, $s4, _draw_circle_end
	addu	$t0, $s5, $a1
	bgeu	$t0, $s3, _draw_circle_end
	subu	$t0, $s6, $a1
	blez	$t0, _draw_circle_end
	subu	$t0, $s5, $a1
	blez	$t0, _draw_circle_end
	
	li	$t0, 3
	sll	$t1, $s2, 1
	subu	$s0, $t0, $t1	#d = 3 - 2r
	b  	_draw_circle_opt_end
_draw_circle_loop:
	subu	$t0, $s2, $s1
	bltz	$t0, _draw_circle_end	#while(y-x >= 0)
	
	addiu	$s1, $s1, 1	#x++
	
	blez	$s0, _draw_circle_second_opt
	
	subiu	$s2, $s2, 1	#y--
	
	subu	$t0, $s1, $s2	#
	sll	$t0, $t0, 2	#
	li	$t1, 10		#
	addu	$s0, $s0, $t0	#
	addu	$s0, $s0, $t1	#d = d + 4(x-y) + 10
	b 	_draw_circle_opt_end
_draw_circle_second_opt:
	sll	$t0, $s1, 2	#
	addu	$s0, $s0, $t0	#
	addiu	$s0, $s0, 6	#d = d + 4x + 6
_draw_circle_opt_end:
#drawPixels
#putpixel(xc+x, yc+y, RED);
    	addu	$t0, $s6, $s2	#yc + y
    	sra	$t1, $s3, 3	#width adjustment to memory shift
    	mulou	$t0, $t0, $t1	
    	addu	$t3, $t9, $t0	#(y+yc)pImg
    	
    	li	$t0, 8
    	addu	$t1, $s5, $s1 	#cx + x
    	divu	$t1, $t0
    	mflo	$t1		#quotient
    	mfhi	$t2		#reminder
    	addu	$t3, $t3, $t1	#t3 - proper memory place where pixel should be put
    	
    	beqz	$s7, _draw_circle_put_pixel_1_colour_0
    	#colour 1
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0x00000080
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	or	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
    	b 	_draw_circle_put_pixel_1_end
_draw_circle_put_pixel_1_colour_0:
	#colour 0
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0xffffff7f
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	and	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
_draw_circle_put_pixel_1_end:

#putpixel(xc-x, yc+y, RED);   
    	addu	$t0, $s6, $s2	#yc + y
    	sra	$t1, $s3, 3	#width adjustment to memory shift
    	mulou	$t0, $t0, $t1	
    	addu	$t3, $t9, $t0	#(y+yc)pImg
    	
    	li	$t0, 8
    	subu	$t1, $s5, $s1 	#cx - x
    	divu	$t1, $t0
    	mflo	$t1		#quotient
    	mfhi	$t2		#reminder
    	addu	$t3, $t3, $t1	#t3 - proper memory place where pixel should be put
    	
    	beqz	$s7, _draw_circle_put_pixel_2_colour_0
    	#colour 1
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0x00000080
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	or	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
    	b 	_draw_circle_put_pixel_2_end
_draw_circle_put_pixel_2_colour_0:
	#colour 0
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0xffffff7f
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	and	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
_draw_circle_put_pixel_2_end:  	
#putpixel(xc+x, yc-y, RED); 
    	subu	$t0, $s6, $s2	#yc - y
    	sra	$t1, $s3, 3	#width adjustment to memory shift
    	mulou	$t0, $t0, $t1	
    	addu	$t3, $t9, $t0	#(y+yc)pImg
    	
    	li	$t0, 8
    	addu	$t1, $s5, $s1 	#cx + x
    	divu	$t1, $t0
    	mflo	$t1		#quotient
    	mfhi	$t2		#reminder
    	addu	$t3, $t3, $t1	#t3 - proper memory place where pixel should be put
    	
    	beqz	$s7, _draw_circle_put_pixel_3_colour_0
    	#colour 1
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0x00000080
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	or	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
    	b 	_draw_circle_put_pixel_3_end
_draw_circle_put_pixel_3_colour_0:
	#colour 0
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0xffffff7f
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	and	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
_draw_circle_put_pixel_3_end:  	
#putpixel(xc-x, yc-y, RED); 
    	subu	$t0, $s6, $s2	#yc - y
    	sra	$t1, $s3, 3	#width adjustment to memory shift
    	mulou	$t0, $t0, $t1	
    	addu	$t3, $t9, $t0	#(y+yc)pImg
    	
    	li	$t0, 8
    	subu	$t1, $s5, $s1 	#cx - x
    	divu	$t1, $t0
    	mflo	$t1		#quotient
    	mfhi	$t2		#reminder
    	addu	$t3, $t3, $t1	#t3 - proper memory place where pixel should be put
    	
    	beqz	$s7, _draw_circle_put_pixel_4_colour_0
    	#colour 1
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0x00000080
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	or	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
    	b 	_draw_circle_put_pixel_4_end
_draw_circle_put_pixel_4_colour_0:
	#colour 0
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0xffffff7f
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	and	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
_draw_circle_put_pixel_4_end:  	
#putpixel(xc+y, yc+x, RED); 
    	addu	$t0, $s6, $s1	#yc + x
    	sra	$t1, $s3, 3	#width adjustment to memory shift
    	mulou	$t0, $t0, $t1	
    	addu	$t3, $t9, $t0	#(y+yc)pImg
    	
    	li	$t0, 8
    	addu	$t1, $s5, $s2 	#cx + y
    	divu	$t1, $t0
    	mflo	$t1		#quotient
    	mfhi	$t2		#reminder
    	addu	$t3, $t3, $t1	#t3 - proper memory place where pixel should be put
    	
    	beqz	$s7, _draw_circle_put_pixel_5_colour_0
    	#colour 1
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0x00000080
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	or	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
    	b 	_draw_circle_put_pixel_5_end
_draw_circle_put_pixel_5_colour_0:
	#colour 0
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0xffffff7f
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	and	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
_draw_circle_put_pixel_5_end:  	
#putpixel(xc-y, yc+x, RED); 
    	addu	$t0, $s6, $s1	#yc + x
    	sra	$t1, $s3, 3	#width adjustment to memory shift
    	mulou	$t0, $t0, $t1	
    	addu	$t3, $t9, $t0	#(y+yc)pImg
    	
    	li	$t0, 8
    	subu	$t1, $s5, $s2 	#cx - y
    	divu	$t1, $t0
    	mflo	$t1		#quotient
    	mfhi	$t2		#reminder
    	addu	$t3, $t3, $t1	#t3 - proper memory place where pixel should be put
    	
    	beqz	$s7, _draw_circle_put_pixel_6_colour_0
    	#colour 1
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0x00000080
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	or	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
    	b 	_draw_circle_put_pixel_6_end
_draw_circle_put_pixel_6_colour_0:
	#colour 0
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0xffffff7f
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	and	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
_draw_circle_put_pixel_6_end:  	
#putpixel(xc+y, yc-x, RED); 
    	subu	$t0, $s6, $s1	#yc - x
    	sra	$t1, $s3, 3	#width adjustment to memory shift
    	mulou	$t0, $t0, $t1	
    	addu	$t3, $t9, $t0	#(y+yc)pImg
    	
    	li	$t0, 8
    	addu	$t1, $s5, $s2 	#cx + y
    	divu	$t1, $t0
    	mflo	$t1		#quotient
    	mfhi	$t2		#reminder
    	addu	$t3, $t3, $t1	#t3 - proper memory place where pixel should be put
    	
    	beqz	$s7, _draw_circle_put_pixel_7_colour_0
    	#colour 1
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0x00000080
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	or	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
    	b 	_draw_circle_put_pixel_7_end
_draw_circle_put_pixel_7_colour_0:
	#colour 0
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0xffffff7f
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	and	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
_draw_circle_put_pixel_7_end:  	
#putpixel(xc-y, yc-x, RED); 
    	subu	$t0, $s6, $s1	#yc - x
    	sra	$t1, $s3, 3	#width adjustment to memory shift
    	mulou	$t0, $t0, $t1	
    	addu	$t3, $t9, $t0	#(y+yc)pImg
    	
    	li	$t0, 8
    	subu	$t1, $s5, $s2 	#cx - y
    	divu	$t1, $t0
    	mflo	$t1		#quotient
    	mfhi	$t2		#reminder
    	addu	$t3, $t3, $t1	#t3 - proper memory place where pixel should be put
    	
    	beqz	$s7, _draw_circle_put_pixel_8_colour_0
    	#colour 1
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0x00000080
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	or	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
    	b 	_draw_circle_put_pixel_8_end
_draw_circle_put_pixel_8_colour_0:
	#colour 0
    	lb	$t1, ($t3)	#mask in memory at pixel pos
    	li	$t0, 0xffffff7f
    	srav	$t0, $t0, $t2	#proper mask adjustment
    	and	$t0, $t0, $t1	#update mask at memory location
    	sb	$t0, ($t3)	#store updated mask at memory location
_draw_circle_put_pixel_8_end:  	
	b 	_draw_circle_loop

_draw_circle_end:
	#epilog
	addiu	$sp, $sp, 4
	lw 	$s7, ($sp)
	addiu	$sp, $sp, 4
	lw	$s6, ($sp)
	addiu	$sp, $sp, 4
	lw	$s5, ($sp)
	addiu	$sp, $sp, 4
	lw	$s4, ($sp)
	addiu	$sp, $sp, 4
	lw	$s3, ($sp)
	addiu	$sp, $sp, 4
	lw	$s2, ($sp)
	addiu	$sp, $sp, 4
	lw	$s1, ($sp)
	addiu	$sp, $sp, 4
	lw	$s0, ($sp)
	#epilog end
	jr	$ra
