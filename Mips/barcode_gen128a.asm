# Code 128 (Code A) Barcode Generator
# Baran Korkmaz 302809

# constants
.eqv	BMP_FILE_SIZE 90122
.eqv 	BYTES_PER_ROW 1800
.eqv 	MAX_LENGTH 15

.data

fname:		.asciiz "source.bmp"
resultfile:	.asciiz "output.bmp"

input_text: 	.space 	MAX_LENGTH
prompt1:	.asciiz "Enter width of the narrowest bar (from 1, 2, 3):\n"
prompt2:	.asciiz "\nEnter the text:\n"
prompt3:	.asciiz "\nThe data to be encoded: \n"
prompt4:	.asciiz "\nWidth is: "

.align 4
res:	.space 2
image:	.space 	BMP_FILE_SIZE

.include	"code128.asm"
.text

main:
	#getting the bar width
	jal ask_width
	move $s0, $v0
	
   	#displaying the prompt
        li $v0, 4		
        la $a0, prompt2	
        syscall

	#getting the input text
        li $v0, 8	
    	la $a0, input_text	
    	li $a1, MAX_LENGTH	
	syscall
	
	
	jal 	format
	jal	read_bmp
	
	move	$a1, $s0	#bar width
	jal	barcode
	jal	save_bmp
	
exit:
	li $v0, 10
	syscall
# ============================================================================	
ask_width:
#description: 
#	asks the user for bar width input between 1-3
	sub 	$sp, $sp, 4	
	sw 	$ra,($sp)
	
	li $v0, 4
    	la $a0, prompt1
    	syscall
	#getting user input for width and storing at $s0
   	li $v0, 5
   	syscall
   	move $t1, $v0

check_width:
#description: 
#	If statement for checking if input is between 1-3		
    	beq $t1, 0, correct_width
    	blt $t1, 1, ask_width
    	bgt $t1, 3, ask_width

correct_width:   	
#description: 
#	cheks if input width is between 1-3
#return value: bar width
	li $v0, 4
    	la $a0, prompt4
    	syscall
	
	li $v0, 1
	move $a0, $t1
	syscall
	move 	$v0, $a0
	
	lw 	$ra, ($sp)	
	add 	$sp, $sp, 4
	jr 	$ra
# ============================================================================	   	
format:
#description: 
#	turn lowercase letters to uppercase letters
	sub 	$sp, $sp, 4	
	sw 	$ra,($sp)
	li $t0, 0
	
format_loop:		
   	lb $t1, input_text($t0)
    	beq $t1, 0, end
    	blt $t1, 'a', capital
    	bgt $t1, 'z', capital
    	sub $t1, $t1, 32
    	sb $t1, input_text($t0)  
capital:
   	addi $t0, $t0, 1
    	jal format_loop
end:
	li $v0, 4
    	la $a0, prompt3
    	syscall
	li $v0, 4
    	la $a0, input_text
    	syscall

	lw 	$ra, ($sp)	
	add 	$sp, $sp, 4
	jr 	$ra

# ============================================================================	
barcode:
#description: 
#	generates quite zone and start symbol
#arguments:
#	$a0 - x position
#	$a1 - bar width
#	$a2 - count
#return value: none	
	sub 	$sp, $sp, 4	
	sw 	$ra,($sp)
	sub 	$sp, $sp, 4	
	sw 	$s0, ($sp)
	sub 	$sp, $sp, 4	
	sw 	$s1, ($sp)
	sub 	$sp, $sp, 4	
	sw 	$s2, ($sp)
	sub 	$sp, $sp, 4	
	sw 	$s3, ($sp)
	
	la  	$s1, input_text	#input text
	li	$s2, 103	#code A start
	li	$s3, 0		#i for loop
	
	# generate quiet zone
	li	$a0, 0		
	li	$a2, 10		
	jal	space
	
	# generate start character
	move	$a0, $v0
	move	$a1, $s0	
	li 	$a2, 103	#code A start
	jal	generate
# ============================================================================		
barcode_loop:   	
#description: 
#	loop for barcode generation 
#arguments:
#	$a0 - x position
#	$a1 - bar width
#	$a2 - symbol value
#return value: none
	lbu	$t1, ($s1)	#input text
	sub	$t1, $t1, 32	
	add	$s3, $s3, 1	#i++
	mul	$t2, $s3, $t1	#i * value
	add	$s2, $s2, $t2	#103 += i * value
	
	move	$a0, $v0	
	move	$a1, $s0	
	move 	$a2, $t1	
	jal	generate

	add 	$s1, $s1, 1	#input text++	
	lbu	$t1, ($s1)	#input text
	sub	$t1, $t1, 32		
	bgez 	$t1, barcode_loop #run loop until input text finished
	
	#calculate and generate check digit
	divu	$s2, $s2, 103	#check symbol value / 103
	mfhi 	$t1		#move remainder from HI register to t1
	move	$a0, $v0	
	move	$a1, $s0	
	move 	$a2, $t1	#check digit value
	jal	generate
	
	#generate stop character
	move	$a0, $v0
	move	$a1, $s0	
	li 	$a2, 106	
	jal	generate
	
	# putting last bar since stop code = 4 bar 3 space
	move	$a0, $v0		
	move	$a1, $s0	
	li	$a2, 2		#count
	jal	bar
	
	#generate quiet zone
	li	$a0, 0		
	move	$a1, $s0	
	li	$a2, 10		#no of space
	jal	space
	
	lw 	$s3, ($sp)	
	add 	$sp, $sp, 4
	lw 	$s2, ($sp)	
	add 	$sp, $sp, 4
	lw 	$s1, ($sp)	
	add 	$sp, $sp, 4
	lw 	$s0, ($sp)	
	add 	$sp, $sp, 4
	lw 	$ra, ($sp)	
	add 	$sp, $sp, 4
	jr 	$ra
# ============================================================================	
generate:
#description: 
#	generating encoded data
#arguments:
#	$a0 - x position
#	$a1 - bar width
#	$a2 - character value
#return value: none
	sub 	$sp, $sp, 4	
	sw 	$ra,($sp)
	subi 	$sp, $sp, 4	
	sw 	$s0, ($sp)
	sub 	$sp, $sp, 4	
	sw 	$s1, ($sp)
	sub 	$sp, $sp, 4	
	sw 	$s2, ($sp)
	
	move	$s0, $a1	
	move	$s1, $a2	
	la	$s2, Code128	#width table
	mul	$t1, $s1, 6	#6 * symbol value -since every character has 6 width values
	add	$s2, $s2, $t1	#table + 6 * value
	
	# generating 3 bar, 3 space in order with the given widths 
	move	$a1, $s0	#width
	lb	$a2, ($s2)	#count
	jal	bar
	
	add	$s2, $s2, 1	#table++
	
	move	$a0, $v0	
	move	$a1, $s0	
	lb	$a2, ($s2)	
	jal	space
		
	add	$s2, $s2, 1
	move	$a0, $v0
	move	$a1, $s0	
	lb	$a2, ($s2)	
	jal	bar
	
	add	$s2, $s2, 1
	move	$a0, $v0
	move	$a1, $s0	
	lb	$a2, ($s2)	
	jal	space
		
	add	$s2, $s2, 1
	move	$a0, $v0
	move	$a1, $s0		
	lb	$a2, ($s2)	
	jal	bar
	
	add	$s2, $s2, 1
	move	$a0, $v0
	move	$a1, $s0	
	lb	$a2, ($s2)	
	jal	space
	
	lw 	$s2, ($sp)	
	add 	$sp, $sp, 4
	lw 	$s1, ($sp)	
	add 	$sp, $sp, 4
	lw 	$s0, ($sp)	
	add 	$sp, $sp, 4
	lw 	$ra, ($sp)	
	add 	$sp, $sp, 4
	jr 	$ra
# ============================================================================	
space:
#description: 
#	generating space
#arguments:
#	$a0 - x starting position
#	$a1 - bar width
#	$a2 - space count
#return value: final x position
	subi 	$sp, $sp, 4		
	sw 	$ra,($sp)
	
	mul	$t1, $a1, $a2
	add	$t1, $t1, $a0
	move	$v0, $t1		
	
	lw 	$ra, ($sp)		
	add 	$sp, $sp, 4
	jr 	$ra
# ============================================================================	
bar:
#description: 
#	generating bar
#arguments:
#	$a0 - x starting position
#	$a1 - bar width
#	$a2 - bar count
#return value: none
	sub 	$sp, $sp, 4		
	sw 	$ra,($sp)
	sub	$sp, $sp, 4		
	sw 	$s0, ($sp)
	sub	$sp, $sp, 4		
	sw 	$s1, ($sp)
	sub 	$sp, $sp, 4		
	sw 	$s2, ($sp)

	mul	$s0, $a1, $a2	#bar width * count = x max width 
	add	$s0, $s0, $a0	#x starting position + x current position
	move 	$s1, $a0	#x starting position
	li 	$s2, 15		#y position
# ============================================================================	
bar_loop:
#description: 
#	loop for generating bar
#arguments:
#	$a0 - x position
#	$a1 - y position
#	$a2 - pixel color
#return value: final x position
	move	$a0, $s1	
	move	$a1, $s2	
	li 	$a2, 0x000000	
	jal 	put_pixel
	
	add	$s2, $s2, 1		#y position++
	bne 	$s2, 50, bar_loop	#cont. if not reach the top
	li	$s2, 15			#y position
	add	$s1, $s1, 1		#x position++
	bne	$s1, $s0, bar_loop	#new line until reaching total width
	move	$v0, $s1	
	
	lw 	$s2, ($sp)		
	add 	$sp, $sp, 4
	lw 	$s1, ($sp)		
	add 	$sp, $sp, 4
	lw 	$s0, ($sp)		
	add 	$sp, $sp, 4
	lw 	$ra, ($sp)		
	add 	$sp, $sp, 4
	jr 	$ra
# ============================================================================	
read_bmp:
#description: 
#	reads the contents of a bmp file into memory
#arguments:
#	none
#return value: none
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, ($sp)
#open file
	li $v0, 13
        la $a0, fname		#file name 
        li $a1, 0		#flags: 0-read file
        li $a2, 0		#mode: ignored
        syscall
	move $s1, $v0      	# save the file descriptor
	
#check for errors - if the file was opened
#...

#read file
	li $v0, 14
	move $a0, $s1
	la $a1, image
	li $a2, BMP_FILE_SIZE
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall
	
	lw $s1, ($sp)		#restore (pop) $s1
	add $sp, $sp, 4
	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

# ============================================================================
save_bmp:
#description: 
#	saves bmp file stored in memory to a file
#arguments:
#	none
#return value: none
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, ($sp)
#open file
	li $v0, 13
        la $a0, resultfile		#file name 
        li $a1, 1		#flags: 1-write file
        li $a2, 0		#mode: ignored
        syscall
	move $s1, $v0      # save the file descriptor
	
#check for errors - if the file was opened
#...

#save file
	li $v0, 15
	move $a0, $s1
	la $a1, image
	li $a2, BMP_FILE_SIZE
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall
	
	lw $s1, ($sp)		#restore (pop) $s1
	add $sp, $sp, 4
	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
# ============================================================================
put_pixel:
#description: 
#	sets the color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#	$a2 - 0RGB - pixel color
#return value: none
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)

	la $t1, image + 10	#adress of file offset to pixel array
	lw $t2, ($t1)		#file offset to pixel array in $t2
	la $t1, image		#adress of bitmap
	add $t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul $t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move $t3, $a0		
	sll $a0, $a0, 1
	add $t3, $t3, $a0	#$t3= 3*x
	add $t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	#pixel address 
	
	#set new color
	sb $a2,($t2)		#store B
	srl $a2,$a2,8
	sb $a2,1($t2)		#store G
	srl $a2,$a2,8
	sb $a2,2($t2)		#store R

	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
# ============================================================================


		
	

