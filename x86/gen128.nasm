bits 32
global gen128

SECTION .data
align 4

%define BYTES_PER_ROW   1800
%define	BAR_HEIGHT      50

code128 db 2,1,2,2,2,2, 2,2,2,1,2,2, 2,2,2,2,2,1, 1,2,1,2,2,3, 1,2,1,3,2,2, 1,3,1,2,2,2, 1,2,2,2,1,3, 1,2,2,3,1,2, 1,3,2,2,1,2, 2,2,1,2,1,3, 2,2,1,3,1,2, 2,3,1,2,1,2, 1,1,2,2,3,2, 1,2,2,1,3,2, 1,2,2,2,3,1, 1,1,3,2,2,2, 1,2,3,1,2,2, 1,2,3,2,2,1, 2,2,3,2,1,1, 2,2,1,1,3,2, 2,2,1,2,3,1, 2,1,3,2,1,2, 2,2,3,1,1,2, 3,1,2,1,3,1, 3,1,1,2,2,2, 3,2,1,1,2,2, 3,2,1,2,2,1, 3,1,2,2,1,2, 3,2,2,1,1,2, 3,2,2,2,1,1, 2,1,2,1,2,3, 2,1,2,3,2,1, 2,3,2,1,2,1, 1,1,1,3,2,3, 1,3,1,1,2,3, 1,3,1,3,2,1, 1,1,2,3,1,3, 1,3,2,1,1,3, 1,3,2,3,1,1, 2,1,1,3,1,3, 2,3,1,1,1,3, 2,3,1,3,1,1, 1,1,2,1,3,3, 1,1,2,3,3,1, 1,3,2,1,3,1, 1,1,3,1,2,3, 1,1,3,3,2,1, 1,3,3,1,2,1, 3,1,3,1,2,1, 2,1,1,3,3,1, 2,3,1,1,3,1, 2,1,3,1,1,3, 2,1,3,3,1,1, 2,1,3,1,3,1, 3,1,1,1,2,3, 3,1,1,3,2,1, 3,3,1,1,2,1, 3,1,2,1,1,3, 3,1,2,3,1,1, 3,3,2,1,1,1, 3,1,4,1,1,1, 2,2,1,4,1,1, 4,3,1,1,1,1, 1,1,1,2,2,4, 1,1,1,4,2,2, 1,2,1,1,2,4, 1,2,1,4,2,1, 1,4,1,1,2,2, 1,4,1,2,2,1, 1,1,2,2,1,4, 1,1,2,4,1,2, 1,2,2,1,1,4, 1,2,2,4,1,1, 1,4,2,1,1,2, 1,4,2,2,1,1, 2,4,1,2,1,1, 2,2,1,1,1,4, 4,1,3,1,1,1, 2,4,1,1,1,2, 1,3,4,1,1,1, 1,1,1,2,4,2, 1,2,1,1,4,2, 1,2,1,2,4,1, 1,1,4,2,1,2, 1,2,4,1,1,2, 1,2,4,2,1,1, 4,1,1,2,1,2, 4,2,1,1,1,2, 4,2,1,2,1,1, 2,1,2,1,4,1, 2,1,4,1,2,1, 4,1,2,1,2,1, 1,1,1,1,4,3, 1,1,1,3,4,1, 1,3,1,1,4,1, 1,1,4,1,1,3, 1,1,4,3,1,1, 4,1,1,1,1,3, 4,1,1,3,1,1, 1,1,3,1,4,1, 1,1,4,1,3,1, 3,1,1,1,4,1, 4,1,1,1,3,1, 2,1,1,4,1,2, 2,1,1,2,1,4, 2,1,1,2,3,2, 2,3,3,1,1,1

SECTION .text
align 4

%define bitmap  	ebp+8
%define bar_width	ebp+12
%define input 		ebp+16
gen128:
	push 	ebp
	mov 	ebp, esp

	%define pos_x 			ebp-4
	%define current_char 	ebp-8
	%define checksum		ebp-12
	%define iterator		ebp-16
		
	sub		esp, 16
   
; check if text has no lower case letters
check_text:
	mov 	eax, [input]    

text_loop:                    
	cmp  BYTE [eax], 0   
	je   valid_text             
	cmp  BYTE [eax], 'a'    
	jl   next
	cmp  BYTE [eax], 'z'    
	jg   next
	jmp  error_text

next:
	inc  eax             
	jmp  text_loop         

valid_text:
	mov     ebx, dword [input]
    xor 	eax, eax
	xor     edx, edx
	xor		ecx, ecx
	
	; check bar_width
	cmp		[bar_width], dword 1
	jl		error_width
	cmp		[bar_width], dword 3
	jg		error_width

	; start barcode
	mov		ebx, [input]
	mov		[current_char], dword ebx
	mov		[checksum], dword 103
	mov		[iterator], dword 0

	; generate quiet zone
	push	dword 10				; count
	push	dword 5					; position x
	push	dword [bar_width]	
	call	space
	add		esp, 12

	; generating start symbol
	push	dword [bitmap] 	
	push	dword 103				; start A
	push	dword eax 				; position x
	push	dword [bar_width]		
	call	data
	add		esp, 16

	barcode_loop:
		mov		ebx, dword [current_char]
		xor		ecx, ecx
		mov		cl, byte [ebx]

		cmp		cl, byte 0
		je		end_barcode

		sub		cl, byte 32				; ascii to code128

		; checksum 
		add		[iterator], dword 1		; iterator ++
		mov		ebx, dword [iterator]
		imul	ebx, ecx				; i * value
		add		[checksum], dword ebx	; 103 += i * value

		; put next symbol
		push	dword [bitmap] 	
		push	dword ecx				; character
		push	dword eax 				; position x
		push	dword [bar_width]		
		call	data
		add		esp, 16

		add		[current_char], dword 1	; next character
		jmp		barcode_loop
		
end_barcode:
	mov		ecx, eax 

	; check symbol calculation
	mov 	eax, [checksum] 		; dividend low half
	xor 	edx, edx            		
	mov 	ebx, 103            		
	div 	ebx       				; check value/103
	
	; put check symbol
	push	dword [bitmap] 	
	push	dword edx				; check value mod 103
	push	dword ecx 				; position x
	push	dword [bar_width]		
	call	data
	add		esp, 16

	; generate stop symbol
	push	dword [bitmap] 	
	push	dword 106				; stop symbol 
	push	dword eax 				; position x
	push	dword [bar_width]		
	call	data
	add		esp, 16

	; putting last bar of stop symbol
	push	dword [bitmap]		
	push	dword 2					; count
	push	dword eax				; position x
	push	dword [bar_width]	
	call	bar
	add		esp, 16

	; generate quiet zone
	push	dword 10				; count
	push	dword [pos_x]	
	push	dword [bar_width]		
	call	space
	add		esp, 12

    mov     eax, dword 0
exit:
	add		esp, 16
	leave
	ret
		
%define d_bar_width	 ebp+8
%define d_pos_x	 ebp+12
%define	d_char	 ebp+16
%define d_bitmap	 ebp+20
data:
	push 	ebp
	mov 	ebp, esp

	%define d_address ebp-4
	
	sub		esp, 4

	; character address
	mov		eax, dword [d_char]
	imul	eax, dword 6
	add		eax, code128
	mov		[d_address], eax

	xor		ecx, ecx
				
	mov		cl, byte [eax] 

	push	dword [d_bitmap]		
	push	dword ecx				; count
	push	dword [d_pos_x]	
	push	dword [d_bar_width]	
	call	bar
	add		esp, 16

	add		[d_address], dword 1
	xor		ecx, ecx
	mov		edx, dword [d_address]
	mov		cl, byte [edx]

	push	dword ecx				; count
	push	dword eax				; position x
	push	dword [d_bar_width]	
	call	space
	add		esp, 12

	add		[d_address], dword 1
	xor		ecx, ecx
	mov		edx, dword [d_address]
	mov		cl, byte [edx]

	push	dword [d_bitmap]	
	push	dword ecx				; count
	push	dword eax				; position x
	push	dword [d_bar_width]	
	call	bar
	add		esp, 16

	add		[d_address], dword 1
	xor		ecx, ecx
	mov		edx, dword [d_address]
	mov		cl, byte [edx]

	push	dword ecx				; count
	push	dword eax				; position x
	push	dword [d_bar_width]	
	call	space
	add		esp, 12

	add		[d_address], dword 1
	xor		ecx, ecx
	mov		edx, dword [d_address]
	mov		cl, byte [edx]

	push	dword [d_bitmap]	
	push	dword ecx				; count
	push	dword eax				; position x
	push	dword [d_bar_width]	
	call	bar
	add		esp, 16

	add		[d_address], dword 1
	xor		ecx, ecx
	mov		edx, dword [d_address]
	mov		cl, byte [edx]

	push	dword ecx				; count
	push	dword eax				; position x
	push	dword [d_bar_width]	
	call	space
	add		esp, 12

	add		esp, 4
	leave
	ret

%define s_bar_width	ebp+8
%define s_pos_x 	ebp+12
%define	s_count 		ebp+16
space:
	push 	ebp
	mov 	ebp, esp

	mov		eax, dword [s_bar_width]
	imul	eax, dword [s_count]
	add		eax, dword [s_pos_x]

	leave
	ret

%define b_bar_width 	ebp+8
%define b_pos_x 		ebp+12
%define	b_count 		ebp+16
%define b_bitmap		ebp+20
bar:
	push 	ebp
	mov 	ebp, esp

	%define b_final_pos			ebp-4
	%define b_width				ebp-8
	%define b_current_height	ebp-12
	%define b_current_width		ebp-16
	
	sub		esp, 16

	mov		eax, dword [b_bar_width]
	imul	eax, dword [b_count]
	mov		[b_width], dword eax
	add		eax, dword [d_pos_x]
	mov		[b_final_pos], dword eax
	
	mov		ebx, [b_pos_x]
	imul	ebx, 3 				
	add		ebx, [b_bitmap] 	; ebx = posInBytes
	mov		edx, ebx			; edx = copy of posInBytes 
	
	mov		[b_current_height], dword 0
	mov		[b_current_width], dword 0
	mov		ecx, [b_width]

	bar_loop:
		mov 	[ebx], byte 0
		mov 	[ebx+1], byte 0
		mov 	[ebx+2], byte 0

		add		[b_current_width], dword 1
		add		ebx, dword 3

		cmp		[b_current_width], ecx
		jl		bar_loop

		mov		ebx, edx
		mov		[b_current_width], dword 0
		add		ebx, BYTES_PER_ROW
		add		edx, BYTES_PER_ROW

		add		[b_current_height], dword 1
		cmp		[b_current_height], dword BAR_HEIGHT
		jl		bar_loop

	mov		eax, [b_final_pos]
	add		esp, 16
	leave
	ret
	
error_text:
	mov     eax, 1
	jmp		exit

error_width:
	mov     eax, 2
	jmp		exit