# MIPS Assembly Template Matching Algorithm
# Author: Justin




.data
displayBuffer:  .space 0x40000 # space for 512x256 bitmap display 
errorBuffer:    .space 0x40000 # space to store match function
templateBuffer: .space 0x100   # space for 8x8 template
imageFileName:    .asciiz "pxlcon512x256cropgs.raw" 
templateFileName: .asciiz "template8x8gs.raw"
# struct bufferInfo { int *buffer, int width, int height, char* filename }
imageBufferInfo:    .word displayBuffer  512 128  imageFileName
errorBufferInfo:    .word errorBuffer    512 128  0
templateBufferInfo: .word templateBuffer 8   8    templateFileName

.text
main:	la $a0, imageBufferInfo
	jal loadImage
	la $a0, templateBufferInfo
	jal loadImage
	la $a0, imageBufferInfo
	la $a1, templateBufferInfo
	la $a2, errorBufferInfo
	jal matchTemplateFast        # MATCHING DONE HERE
	la $a0, errorBufferInfo
	jal findBest
	la $a0, imageBufferInfo
	move $a1, $v0
	jal highlight
	la $a0, errorBufferInfo	
	jal processError
	li $v0, 10		# exit
	syscall
	

##########################################################
# matchTemplate( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplate:	
	addi $sp, $sp, -20   		# Allocate 20 bytes on the stack
	sw $ra, 16($sp)     		# Save $ra (return address)
	sw $s1, 12($sp)
	sw $s2, 8($sp)
	sw $s3, 4($sp)
	sw $s4, 0($sp)

	# Initialising the current coordinates and entering for-loop for image height
	la $t0, imageBufferInfo
	lw $t5, 8($t0)          		# image height
	addi $s1, $t5, -7       		# s1 = height - 7
	lw $t5, 4($t0)          		# image width
	addi $s2, $t5, -7       		# s2 = width - 7
	la $t0, templateBufferInfo
	lw $s3, 8($t0)           		# s3 = template height (8)
	lw $s4, 4($t0)           		# s4 = template width (8)
	
	# Load the buffer base addresses	
	lw $a0, 0($a0)			# Base address of image buffer	
	lw $a1, 0($a1)			# Base address of template buffer	
	lw $a2, 0($a2)			# Base address of error buffer
	
	move $t0, $zero			# Initialise current image height ($t0 = 0)
	move $t1, $zero			# Initialise current image width ($t1 = 0)
	move $t2, $zero			# Initialise current template height ($t2 = 0)
	move $t3, $zero			# Initialise current template width ($t3 = 0)
	jal StartImageHeight 		# For loop for image height

	# Go back to Main
	# Restore registers before returning
	lw $s4, 0($sp)
	lw $s3, 4($sp)
	lw $s2, 8($sp)
	lw $s1, 12($sp)
	lw $ra, 16($sp)
	addi $sp, $sp, 20			# Deallocate 20 bytes from the stack
	jr $ra	
	
StartImageHeight:
	# Initiating stack
	addi $sp, $sp, -4   		# Allocate 4 bytes on the stack
	sw $ra, 0($sp)        		# Save $ra (return address)
	
ForLoopImageHeight:
	# $t0 = current image height, $t1 = current image width 
	# $t2 = current template height, $t3 = current template width
	
	# Checks if image height limit has been reached
	slt $t4, $t0, $s1			# $t4 = 1 if $t0 < $s1
	beq $t4, $zero, EndImageHeight	# If limit reached then End
	
	# If limit not reached, enter for-loop for image width
	jal StartImageWidth
	
	# Increment current image height by 1
	addi $t0, $t0, 1			# y++
	move $t1, $zero			# Reset counter for image width
	j ForLoopImageHeight
	
EndImageHeight:
	# Restore the stack
	lw $ra, 0($sp)        		# Restore $ra
	addi $sp, $sp, 4     		# Deallocate stack
	jr $ra
	
StartImageWidth:
	# Initiating stack
	addi $sp, $sp, -4   		# Allocate 4 bytes on the stack
	sw $ra, 0($sp)        		# Save $ra (return address)
	
ForLoopImageWidth:
	# $t0 = current image height, $t1 = current image width 
	# $t2 = current template height, $t3 = current template width
	
	# Checks if image width limit has been reached
	slt $t4, $t1, $s2			# $t1 = 1 if $t1 < $s2
	beq $t4, $zero, EndImageWidth	# if limit reached then EndImageWidth
	
	# If limit not reached, enter for-loop for template length
	move $t8, $zero
	jal StartTemplateHeight
	
	# Compute and store the SAD in error buffer
	la $t5, imageBufferInfo
	lw $t5,4($t5)         		# $t5 = image width
	mul $t6, $t0, $t5      		# t6 = y * width
	add $t6, $t6, $t1      		# t6 = (y * width) + x
	sll $t6, $t6, 2        		# multiply by 4 to get byte offset
	add $t6, $t6, $a2      		# t6 = errorBufferBase + offset
	sw $t8, 0($t6)         		# store SAD in error buffer
	
	# Increment current image width by 1
	addi $t1, $t1, 1			# x++
	move $t2, $zero			# Reset counter for template height	
	j ForLoopImageWidth
	
EndImageWidth:
	# Restore the stack and return to image width loop
	lw $ra, 0($sp)        		# Restore $ra
	addi $sp, $sp, 4     		# Deallocate stack
	
	jr $ra                		# Return to caller
	
StartTemplateHeight:
	# Initiating stack
	addi $sp, $sp, -4   		# Allocate 4 bytes on the stack
	sw $ra, 0($sp)        		# Save $ra (return address)
	
ForLoopTemplateHeight:
	# $t0 = current image height, $t1 = current image width 
	# $t2 = current template height, $t3 = current template width
	
	# Checks if template height limit has been reached
	slt $t4, $t2, $s3			# $t4 = 1 if $t2 < $s3
	beq $t4, $zero, EndTemplateHeight	# if limit reached then EndTemplateHeight
	
	# If limit not reached, enter for-loop for template width
	jal ForLoopTemplateWidth
	
	# Increment current template height by 1
	addi $t2, $t2, 1			# j++
	move $t3, $zero			# Reset counter for template width
    	j ForLoopTemplateHeight		# Repeat template height loop

EndTemplateHeight:
	# Restore the stack and return to image width loop
	lw $ra, 0($sp)        		# Restore $ra
	addi $sp, $sp, 4     		# Deallocate stack
	jr $ra                		# Return to caller
	
ForLoopTemplateWidth:
	# $t0 = current image height, $t1 = current image width 
	# $t2 = current template height, $t3 = current template width
	
	# Checks if template width limit has been reached
	slt $t4, $t3, $s4			# $t3 = 1 if $t3 < $s4
	beq $t4, $zero, EndTemplateWidth	# if limit reached then EndTemplateWidth
	
	# ALGORITHM IMPLEMENTATION HERE:
	
	# Calculating image pixel offset
	la $t4, imageBufferInfo		
	lw $t4, 4($t4)			# Loading image width in $t4
	
	add $t5, $t0, $t2			# $t5 = y + j
	add $t6, $t1, $t3			# $t6 = x + i
	
	mul $t4, $t5, $t4			# $t4 = (y + j) * max image width
	add $t4, $t4, $t6			# $t4 = $t4 + (x + i)
	sll $t4, $t4, 2			# Multiply by 4 to convert to byte offset
	
	# Calculating template pixel offset
	la $t5, templateBufferInfo		
	lw $t5, 4($t5)			# Loading template width in $t5	
	mul $t5, $t2, $t5			# $t5 = j * max template width
	add $t5, $t5, $t3			# $t8 = $t8 + i
	sll $t5, $t5, 2			# Multiply by 4 to convert to byte offset
	
	# Adding offsets to base addresses
	add $t6, $a0, $t4			# $t6 = address for image pixel
	add $t7, $a1, $t5			# $t7 = address for template pixel
	
	# Loading pixel brightness values
	lbu $t4, 0($t6)			# $t4 = brightness of image pixel
	lbu $t5, 0($t7)			# $t5 = brightness of template pixel 
	
	# Computing absolute difference
	sub $t6, $t4, $t5			# $t6 = image brightness - template brightness
	bgez $t6, Continue		# If $t6 is positive then branch to Continue
	sub $t6, $zero, $t6		# If $t6 is negative
Continue:
	add $t8, $t8, $t6			# SAD value += SAD
	
	# Increment current template width by 1
	addi $t3, $t3, 1			# i++
	
	# Continues template width for-loop until limit is reached
	j ForLoopTemplateWidth
	
EndTemplateWidth:
	# Return to template height loop
	jr $ra
	
##########################################################
# matchTemplateFast( bufferInfo imageBufferInfo, bufferInfo templateBufferInfo, bufferInfo errorBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
matchTemplateFast:	
	# Save registers
	addi $sp, $sp, -40         # Allocate 40 bytes on the stack
	sw $ra, 36($sp)            # Save $ra (return address)
	sw $s0, 32($sp)
	sw $s1, 28($sp)
	sw $s2, 24($sp)
	sw $s3, 20($sp)
	sw $s4, 16($sp)		# y
	sw $s5, 12($sp)		# x
	sw $s6, 8($sp)		# j (byte offset)
	sw $s7, 4($sp)		# errorBufferBase

	# Initialising the constants
	lw $t5, 8($a0)             # image height
	addi $s1, $t5, -7          # s1 = max image height (y)
	lw $t5, 4($a0)             # image width
	addi $s2, $t5, -7          # s2 = max image width (x)
	li $s3, 256             	# s3 = 256 (max template height byte offset: 8*32)
	
	lw $a1, 0($a1)             # a1 = templateBase
	lw $a3, 4($a0)             # a3 = image width (512)
	lw $s0, 0($a0)             # s0 = imageBase
	lw $s7, 0($a2)             # s7 = errorBufferBase
	
	move $s4, $zero            # y = 0
	move $s5, $zero            # x = 0
	move $s6, $zero            # j = 0 (offset)
	jal StartTemplateHeightF   # For loop for template height

	# Restore registers before returning
	lw $s7, 4($sp)
	lw $s6, 8($sp)
	lw $s5, 12($sp)
	lw $s4, 16($sp)
	lw $s3, 20($sp)
	lw $s2, 24($sp)
	lw $s1, 28($sp)
	lw $s0, 32($sp)
	lw $ra, 36($sp)
	addi $sp, $sp, 40          # Deallocate 40 bytes from the stack
	jr $ra

StartTemplateHeightF: # j
	addi $sp, $sp, -4          # Allocate 4 bytes on the stack
	sw $ra, 0($sp)             # Save $ra (return address)

ForLoopTemplateHeightF:	#j
	slt $t9, $s6, $s3          	# limit: s6 < 256 (8 rows * 32 bytes)
	beq $t9, $zero, EndTemplateHeightF
	
	# Load entire template row into t0-t7
	add $t9, $a1, $s6
	lbu $t0, 0($t9)
	lbu $t1, 4($t9)
	lbu $t2, 8($t9)
	lbu $t3, 12($t9)
	lbu $t4, 16($t9)
	lbu $t5, 20($t9)
	lbu $t6, 24($t9)
	lbu $t7, 28($t9)
	
	jal StartImageHeightF

	addi $s6, $s6, 32          # next template row (+32 bytes)
	move $s4, $zero            # y = 0
	j ForLoopTemplateHeightF

EndTemplateHeightF:
	lw $ra, 0($sp)             # Restore $ra
	addi $sp, $sp, 4           # Deallocate stack
	jr $ra                     # Return to caller

StartImageHeightF:             # y
	addi $sp, $sp, -4
	sw $ra, 0($sp)

ForLoopImageHeightF:
	slt $t9, $s4, $s1          # limit: s4 < s1
	beq $t9, $zero, EndImageHeightF

	jal StartImageWidthF

	addi $s4, $s4, 1           # y++
	move $s5, $zero            # x = 0
	j ForLoopImageHeightF

EndImageHeightF:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

StartImageWidthF:              # x
	addi $sp, $sp, -4
	sw $ra, 0($sp)

ForLoopImageWidthF:
	slt $t9, $s5, $s2          # limit: s5 < s2
	beq $t9, $zero, EndImageWidthF

	jal TemplateWidthF
	addi $s5, $s5, 1           # x++
	j ForLoopImageWidthF
	
TemplateWidthF:
	# Calculate error buffer offset for (x, y)
	# errorOffset = (y * 512 + x) * 4
	mul $v0, $s4, $a3        # v0 = y * 512
	add $v0, $v0, $s5        # v0 = (y * 512) + x
	sll $v0, $v0, 2          # byte offset
	add $v1, $v0, $s7        # v1 = errorBufferBase + errorOffset
	lw $t8, 0($v1)           # t8 = current SAD value

	# Calculate image offset for (x, y + j)
	# s6 is j * 32. We need true row index `j` which is s6 / 32
	# row = y + (s6 / 32)
	srl $t9, $s6, 5          # t9 = j (0 to 7)
	add $t9, $t9, $s4        # t9 = y + j
	mul $t9, $t9, $a3        # t9 = (y + j) * 512
	add $t9, $t9, $s5        # t9 = (y + j) * 512 + x
	sll $t9, $t9, 2          # byte offset
	add $t9, $t9, $s0        # t9 = imageBase + imageOffset
	
	# i = 0
	lbu $v0, 0($t9)          # load image pixel
	sub $v0, $v0, $t0        # diff
	bgez $v0, pos0
	sub $v0, $zero, $v0      # abs
pos0:	add $t8, $t8, $v0        # add to SAD
	
	# i = 1
	lbu $v0, 4($t9)
	sub $v0, $v0, $t1
	bgez $v0, pos1
	sub $v0, $zero, $v0
pos1:	add $t8, $t8, $v0
	
	# i = 2
	lbu $v0, 8($t9)
	sub $v0, $v0, $t2
	bgez $v0, pos2
	sub $v0, $zero, $v0
pos2:	add $t8, $t8, $v0
	
	# i = 3
	lbu $v0, 12($t9)
	sub $v0, $v0, $t3
	bgez $v0, pos3
	sub $v0, $zero, $v0
pos3:	add $t8, $t8, $v0
	
	# i = 4
	lbu $v0, 16($t9)
	sub $v0, $v0, $t4
	bgez $v0, pos4
	sub $v0, $zero, $v0
pos4:	add $t8, $t8, $v0
	
	# i = 5
	lbu $v0, 20($t9)
	sub $v0, $v0, $t5
	bgez $v0, pos5
	sub $v0, $zero, $v0
pos5:	add $t8, $t8, $v0
	
	# i = 6
	lbu $v0, 24($t9)
	sub $v0, $v0, $t6
	bgez $v0, pos6
	sub $v0, $zero, $v0
pos6:	add $t8, $t8, $v0
	
	# i = 7
	lbu $v0, 28($t9)
	sub $v0, $v0, $t7
	bgez $v0, pos7
	sub $v0, $zero, $v0
pos7:	add $t8, $t8, $v0
	
	sw $t8, 0($v1)         	 # store updated SAD in error buffer
	jr $ra
	
EndImageWidthF:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra                		# Return to caller
	
###############################################################
# loadImage( bufferInfo* imageBufferInfo )
# NOTE: struct bufferInfo { int *buffer, int width, int height, char* filename }
loadImage:	lw $a3, 0($a0)  # int* buffer
		lw $a1, 4($a0)  # int width
		lw $a2, 8($a0)  # int height
		lw $a0, 12($a0) # char* filename
		mul $t0, $a1, $a2 # words to read (width x height) in a2
		sll $t0, $t0, 2	  # multiply by 4 to get bytes to read
		li $a1, 0     # flags (0: read, 1: write)
		li $a2, 0     # mode (unused)
		li $v0, 13    # open file, $a0 is null-terminated string of file name
		syscall
		move $a0, $v0     # file descriptor (negative if error) as argument for read
  		move $a1, $a3     # address of buffer to which to write
		move $a2, $t0	  # number of bytes to read
		li  $v0, 14       # system call for read from file
		syscall           # read from file
        		# $v0 contains number of characters read (0 if end-of-file, negative if error).
        		# We'll assume that we do not need to be checking for errors!
		# Note, the bitmap display doesn't update properly on load, 
		# so let's go touch each memory address to refresh it!
		move $t0, $a3	   # start address
		add $t1, $a3, $a2  # end address
loadloop:	lw $t2, ($t0)
		sw $t2, ($t0)
		addi $t0, $t0, 4
		bne $t0, $t1, loadloop
		jr $ra
		
		
#####################################################
# (offset, score) = findBest( bufferInfo errorBuffer )
# Returns the address offset and score of the best match in the error Buffer
findBest:	lw $t0, 0($a0)     # load error buffer start address	
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		li $v0, 0		# address of best match	
		li $v1, 0xffffffff 	# score of best match	
		lw $a1, 4($a0)    # load width
        		addi $a1, $a1, -7 # initialize column count to 7 less than width to account for template
fbLoop:		lw $t9, 0($t0)        # score
		sltu $t8, $t9, $v1    # better than best so far?
		beq $t8, $zero, notBest
		move $v0, $t0
		move $v1, $t9
notBest:		addi $a1, $a1, -1
		bne $a1, $0, fbNotEOL # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
fbNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, fbLoop
		lw $t0, 0($a0)     # load error buffer start address	
		sub $v0, $v0, $t0  # return the offset rather than the address
		jr $ra
		

#####################################################
# highlight( bufferInfo imageBuffer, int offset )
# Applies green mask on all pixels in an 8x8 region
# starting at the provided addr.
highlight:	lw $t0, 0($a0)     # load image buffer start address
		add $a1, $a1, $t0  # add start address to offset
		lw $t0, 4($a0) 	# width
		sll $t0, $t0, 2	
		li $a2, 0xff00 	# highlight green
		li $t9, 8	# loop over rows
highlightLoop:	lw $t3, 0($a1)		# inner loop completely unrolled	
		and $t3, $t3, $a2
		sw $t3, 0($a1)
		lw $t3, 4($a1)
		and $t3, $t3, $a2
		sw $t3, 4($a1)
		lw $t3, 8($a1)
		and $t3, $t3, $a2
		sw $t3, 8($a1)
		lw $t3, 12($a1)
		and $t3, $t3, $a2
		sw $t3, 12($a1)
		lw $t3, 16($a1)
		and $t3, $t3, $a2
		sw $t3, 16($a1)
		lw $t3, 20($a1)
		and $t3, $t3, $a2
		sw $t3, 20($a1)
		lw $t3, 24($a1)
		and $t3, $t3, $a2
		sw $t3, 24($a1)
		lw $t3, 28($a1)
		and $t3, $t3, $a2
		sw $t3, 28($a1)
		add $a1, $a1, $t0	# increment address to next row	
		add $t9, $t9, -1		# decrement row count
		bne $t9, $zero, highlightLoop
		jr $ra

######################################################
# processError( bufferInfo error )
# Remaps scores in the entire error buffer. The best score, zero, 
# will be bright green (0xff), and errors bigger than 0x4000 will
# be black.  This is done by shifting the error by 5 bits, clamping
# anything bigger than 0xff and then subtracting this from 0xff.
processError:	lw $t0, 0($a0)     # load error buffer start address
		lw $t2, 4($a0)	   # load width
		lw $t3, 8($a0)	   # load height
		addi $t3, $t3, -7  # height less 8 template lines minus one
		mul $t1, $t2, $t3
		sll $t1, $t1, 2    # error buffer size in bytes	
		add $t1, $t0, $t1  # error buffer end address
		lw $a1, 4($a0)     # load width as column counter
        		addi $a1, $a1, -7  # initialize column count to 7 less than width to account for template
pebLoop:		lw $v0, 0($t0)        # score
		srl $v0, $v0, 5       # reduce magnitude 
		slti $t2, $v0, 0x100  # clamp?
		bne  $t2, $zero, skipClamp
		li $v0, 0xff          # clamp!
skipClamp:	li $t2, 0xff	      # invert to make a score
		sub $v0, $t2, $v0
		sll $v0, $v0, 8       # shift it up into the green
		sw $v0, 0($t0)
		addi $a1, $a1, -1        # decrement column counter	
		bne $a1, $0, pebNotEOL   # Need to skip 8 pixels at the end of each line
		lw $a1, 4($a0)        # load width to reset column counter
        		addi $a1, $a1, -7     # column count for next line is 7 less than width
        		addi $t0, $t0, 28     # skip pointer to end of line (7 pixels x 4 bytes)
pebNotEOL:	add $t0, $t0, 4
		bne $t0, $t1, pebLoop
		jr $ra
