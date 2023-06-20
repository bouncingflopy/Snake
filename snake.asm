IDEAL
MODEL small
STACK 100h
DATASEG

len dw 3 ; the length of the snake
user dw 'a' ; the key the user pressed, denotes the direction of the snake
gameOverMessageLength dw 9 ; the length of the game over message
gameOverMessage db 'GAME OVER' ; the game over message to be displayed when the user loses
seed dw 0DEADh ; a number which will be used to generate a different random number
snake dw 2000, 2002, 2004 ; the on-screen positions of the snake
dw 300 dup(?) ; saves space for up to 300 snake body pieces (apart from the starting snake pieces)

CODESEG
;---------------------------------------------------------------------------------
;---------------------------------------------------------------------------------
;---------------------          SETUP PROCEDURES          ------------------------

;---------------------------------------------------------------------------------
; seedSetup: sets the starting seed to a number from the computer clock
; INPUT: location of seed in memory
; OUTPUT: none
proc seedSetup
	push bp
	mov bp, sp
	push es
	push ax
	push bx
	
	mov bx, [bp+4]
	
	; change seed based on time counter
	mov ax, 40h
	mov es, ax
	mov ax, [es:6Ch]
	mov [bx], ax
	
	pop bx
	pop ax
	pop es
	pop bp
	ret 2
endp seedSetup
;---------------------------------------------------------------------------------

;---------------------------------------------------------------------------------
; screenSetup: sets all pixels in the screen to a uniform color, acting as a background
; INPUT: none
; OUTPUT: none
proc screenSetup
	push bx
	push di

	mov bh, 48
	mov bl, ' '
	
	; screenLoop: loops through every byte in the screen, from 0 to 4000
	mov di, 0
	screenLoop:
		mov [es:di], bx
		add di, 2
		cmp di, 25*80*2
		jnz screenLoop
	
	pop di
	pop bx
	ret
endp screenSetup
;---------------------------------------------------------------------------------

;---------------------------------------------------------------------------------
; snakeInit: displays the initial snake pixels on screen
; INPUT: snake starting location in memory, length of snake
; OUTPUT: the location of the head of the snake
proc snakeInit
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	push di
	
	mov cl, 7
	mov ch, 66
	
	; loops through initial snake position in memory using the inputs, and displays each one
	mov ax, [bp+6]
	mov bx, ax
	mov dx, [bp+4]
	rol dx, 1
	add bx, dx
	snakeInitLoop:
		sub bx, 2
		mov di, [bx]
		mov [es:di], cx
		cmp bx, ax
		jnz snakeInitLoop
	mov [bp+6], di
	
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret 2
endp snakeInit
;---------------------------------------------------------------------------------

;---------------------       END SETUP PROCEDURES         ------------------------
;---------------------------------------------------------------------------------
;---------------------------------------------------------------------------------


;---------------------------------------------------------------------------------
;---------------------------------------------------------------------------------
;-------------------       GENERAL PURPOSE PROCEDURES       ----------------------

;---------------------------------------------------------------------------------
; delay: stops the program for a short amount of time
; INPUT: none
; OUTPUT: none
proc delay
	push cx
	
	mov cx, 72
	loopA:
		push cx
		
		mov cx, 0FFFFh
		loopB:
		loop loopB
		
		pop cx
	loop loopA
	
	pop cx
	ret
endp delay
;---------------------------------------------------------------------------------

;---------------------------------------------------------------------------------
; input: checks for user input
; INPUT: last key pressed
; OUTPUT: if 'w', 'a', 's', 'd', or 'q' is pressed - returns what was pressed, if any other key is pressed or no key is pressed - returns the procedure input 
proc input
	push bp
	mov bp, sp
	push ax
	push dx
	
	; if no key is pressed, skip to end and return last direction
	mov ax, 100h
	int 16h
	jz endInput
	
	; if a key is pressed, get a new input
	mov ax, 0
	int 16h
	
	; make sure snake wont go back in on itself
		cmp al, 'w'
		jne afterInputW
		mov dx, [bp+4]
		cmp dx, 's'
		je endInput ; if last input was opposite of the new input, dont update input
		jmp returnInput
		afterInputW:
		
		cmp al, 'a'
		jne afterInputA
		mov dx, [bp+4]
		cmp dx, 'd'
		je endInput ; if last input was opposite of the new input, dont update input
		jmp returnInput
		afterInputA:
		
		cmp al, 's'
		jne afterInputS
		mov dx, [bp+4]
		cmp dx, 'w'
		je endInput ; if last input was opposite of the new input, dont update input
		jmp returnInput
		afterInputS:
		
		cmp al, 'd'
		jne afterInputD
		mov dx, [bp+4]
		cmp dx, 'a'
		je endInput ; if last input was opposite of the new input, dont update input
		jmp returnInput
		afterInputD:
	
	cmp al, 'q'
	jne endInput
	
	; if no new key is pressed or an invalid key is pressed, skip the return input stage,
	; leaving the program with the last key pressed which the procedure got as an input
	returnInput:
	mov ah, 0
	mov [bp+4], ax
	
	endInput:
	pop dx
	pop ax
	pop bp
	ret
endp input
;---------------------------------------------------------------------------------

;---------------------------------------------------------------------------------
; displayGameOver: displays a game over message on screen
; INPUT: location of beginning of message in memory, amouunt of characters to be displayed
; OUTPUT: none
proc displayGameOver
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push di
	
	mov ax, [bp+4]
	mov bx, [bp+6]
	
	; calculates starting position for text
	mov cx, ax
	and cx, 0FFFEh
	mov di, 1998
	sub di, cx
	
	mov ch, 16
	
	; loop through every character in memory, and display it
	displayGameOverLoop:
		mov cl, [bx]
		add di, 2
		mov [es:di], cx
		
		inc bx
		dec ax
		cmp ax, 0
		jne displayGameOverLoop
	
	pop di
	pop cx
	pop bx
	pop ax
	pop bp
	ret 4
endp displayGameOver
;---------------------------------------------------------------------------------

;-------------------       GENERAL PURPOSE PROCEDURES       ----------------------
;---------------------------------------------------------------------------------
;---------------------------------------------------------------------------------


;---------------------------------------------------------------------------------
;---------------------------------------------------------------------------------
;---------------       DIRECTIONALLY SPECIFIC PROCEDURES       -------------------

;---------------------------------------------------------------------------------
; moveUp: moves the position of the head of the snake up
; INPUT: the position of the head of the snake
; OUTPUT: the new position of the head of the snake, 4004 if hit a wall
proc moveUp
	push bp
	mov bp, sp
	push di
	
	mov di, [bp+4]
	cmp di, 160 ; check if hitting a wall
	jl upReturn4004
	sub di, 160
	mov [bp+4], di
	jmp endMoveUp
	
	upReturn4004:
	mov di, 4004
	mov [bp+4], di
	
	endMoveUp:
	pop di
	pop bp
	ret
endp moveUp
;---------------------------------------------------------------------------------

;---------------------------------------------------------------------------------
; moveLeft: moves the position of the head of the snake left
; INPUT: the position of the head of the snake
; OUTPUT: the new position of the head of the snake, 4004 if hit a wall
proc moveLeft
	push bp
	mov bp, sp
	push ax
	push cx
	push dx
	push di
	
	mov di, [bp+4]
	mov ax, di
	mov cx, 160
	mov dx, 0
	div cx
	cmp dx, 0 ; check if hitting a wall
	je leftReturn4004
	sub di, 2
	mov [bp+4], di
	jmp endMoveLeft
	
	leftReturn4004:
	mov di, 4004
	mov [bp+4], di
	
	endMoveLeft:
	pop di
	pop dx
	pop cx
	pop ax
	pop bp
	ret
endp moveLeft
;---------------------------------------------------------------------------------

;---------------------------------------------------------------------------------
; moveDown: moves the position of the head of the snake down
; INPUT: the position of the head of the snake
; OUTPUT: the new position of the head of the snake, 4004 if hit a wall
proc moveDown
	push bp
	mov bp, sp
	push di
	
	mov di, [bp+4]
	cmp di, 4000-160 ; check if hitting a wall
	jae downReturn4004
	add di, 160
	mov [bp+4], di
	jmp endMoveDown
	
	downReturn4004:
	mov di, 4004
	mov [bp+4], di
	
	endMoveDown:
	pop di
	pop bp
	ret
endp moveDown
;---------------------------------------------------------------------------------

;---------------------------------------------------------------------------------
; moveRight: moves the position of the head of the snake right
; INPUT: the position of the head of the snake
; OUTPUT: the new position of the head of the snake, 4004 if hit a wall
proc moveRight
	push bp
	mov bp, sp
	push ax
	push cx
	push dx
	push di
	
	mov di, [bp+4]
	mov ax, di
	mov cx, 160
	mov dx, 0
	div cx
	cmp dx, 158 ; check if hitting a wall
	je rightReturn4004
	add di, 2
	mov [bp+4], di
	jmp endMoveRight
	
	rightReturn4004:
	mov di, 4004
	mov [bp+4], di
	
	endMoveRight:
	pop di
	pop dx
	pop cx
	pop ax
	pop bp
	ret
endp moveRight
;---------------------------------------------------------------------------------

;---------------       DIRECTIONALLY SPECIFIC PROCEDURES       -------------------
;---------------------------------------------------------------------------------
;---------------------------------------------------------------------------------


;---------------------------------------------------------------------------------
;---------------------------------------------------------------------------------
;-------------------       SNAKE HANDELING PROCEDURES       ----------------------

;---------------------------------------------------------------------------------
; updateMemory: updates the snake locations stored in the memory
; INPUT: length of snake, location of head of snake in memory, position of the head of the snake
; OUTPUT: position of tail of the snake
proc updateMemory
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	
	; sets bx to the location of the last pixel of the snake
	mov ax, [bp+8]
	mov cx, [bp+6]
	rol ax, 1
	add ax, cx
	mov bx, ax
	sub bx, 2
	
	; returns the position of the tail, so it can be deleted in updateScreen
	mov ax, [bx]
	mov [bp+8], ax
	
	; cycles through memory, shifting everything one to the right
	updateMemoryLoop:
		cmp bx, cx
		je afterUpdateMemoryLoop
		mov ax, [bx-2]
		mov [bx], ax
		sub bx, 2
		jmp updateMemoryLoop
	afterUpdateMemoryLoop:
	
	; insert head of the snake in memory
	mov ax, [bp+4]
	mov [bx], ax
	
	pop cx
	pop bx
	pop ax
	pop bp
	ret 4
endp updateMemory
;---------------------------------------------------------------------------------

;---------------------------------------------------------------------------------
; deleteTail: removes the tail of the snake on screen
; INPUT: position of the tail of the snake
; OUTPUT: none
proc deleteTail
	push bp
	mov bp, sp
	push di
	push cx
	
	mov ch, 48
	mov cl, ' '
	mov di, [bp+4]
	mov [es:di], cx
	
	pop cx
	pop di
	pop bp
	ret 2
endp deleteTail
;---------------------------------------------------------------------------------

;---------------------------------------------------------------------------------
; displayHead: displays the new head of the snake on screen
; INPUT: position of the head of the snake
; OUTPUT: none
proc displayHead
	push bp
	mov bp, sp
	push di
	push cx
	
	mov cl, 7
	mov ch, 66
	mov di, [bp+4]
	mov [es:di], cx
	
	pop cx
	pop di
	pop bp
	ret 2
endp displayHead
;---------------------------------------------------------------------------------

;---------------------------------------------------------------------------------
; updateScreen: displays the new head of the snake on screen, removes the tail of the snake on screen
; INPUT: position of the tail of the snake, position of the head of the snake
; OUTPUT: none
proc updateScreen
	push bp
	mov bp, sp
	push di
	push cx
	
	; delete the tail of the snake
	push [bp+6]
	call deleteTail
	
	; display the new head of the snake
	push [bp+4]
	call displayHead
	
	pop cx
	pop di
	pop bp
	ret 4
endp updateScreen
;---------------------------------------------------------------------------------

;---------------------------------------------------------------------------------
; checkDeath: check if the snake bumped into a wall, or bumped into itself
; INPUT: position of the head of the snake
; OUTPUT: 4004 if death, input if not
proc checkDeath
	push bp
	mov bp, sp
	push ax
	push cx
	push di
	
	mov cx, 7
	mov di, [bp+4]
	mov ax, [es:di]
	cmp cl, al
	jne endCheckDeath
	mov [bp+4], 4004
	
	endCheckDeath:
	pop di
	pop cx
	pop ax
	pop bp
	ret
endp checkDeath
;---------------------------------------------------------------------------------

;-------------------       SNAKE HANDELING PROCEDURES       ----------------------
;---------------------------------------------------------------------------------
;---------------------------------------------------------------------------------


;---------------------------------------------------------------------------------
;---------------------------------------------------------------------------------
;-------------------       FOOD HANDELING PROCEDURES        ----------------------

;---------------------------------------------------------------------------------
; eat: increases the length of the snake, adds a pixel to the snake, and calls spawnFood
; INPUT: length of snake, location of head of snake in memory
; OUTPUT: new length of snake
proc eat
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	
	; copy position of tail, to grow the snake
	mov ax, [bp+6]
	mov cx, [bp+4]
	rol ax, 1
	add ax, cx
	mov bx, ax
	mov ax, [bx-2]
	mov [bx], ax
	
	; increases the length by one
	mov ax, [bp+6]
	inc ax
	mov [bp+6], ax
	
	pop cx
	pop bx
	pop ax
	pop bp
	ret 2
endp eat
;---------------------------------------------------------------------------------

;---------------------------------------------------------------------------------
; spawnFood: spawns one piece of food onto the screen, making sure it's not on the snake
; INPUT: the seed
; OUTPUT: new seed
proc spawnFood
	push bp
	mov bp, sp
	push ax
	push cx
	push dx
	push di
	
	; generate a random number between 0 and 2000
	generateRandom:
		; xoroshiro16+
		mov ax, [bp+4]
		xor ah, al
		mov cl, al
		rol cl, 6
		xor cl, ah
		mov ch, cl
		shl ch, 1
		xor cl, ch
		mov al, cl
		mov ch, ah
		rol ch, 3
		mov ah, ch
		
		; output the new number generated, so it can be used to generate a different number next time
		inc ax
		mov [bp+4], ax
		
		mov dx, 0
		mov cx, 2000
		div cx
		mov di, dx
		
	; check if randomly chosen location isn't occupied by snake - if it is, chose a different locaiton
	rol di, 1
	mov ax, [es:di]
	cmp al, 7
	je generateRandom
	
	; display the randomly placed food
	mov cl, 3
	mov ch, 125
	mov [es:di], cx
	
	pop di
	pop dx
	pop cx
	pop ax
	pop bp
	ret
endp spawnFood
;---------------------------------------------------------------------------------

;-------------------       FOOD HANDELING PROCEDURES        ----------------------
;---------------------------------------------------------------------------------
;---------------------------------------------------------------------------------


start:

	;---------------------------------------------------------------------------------
	;--------------------------             SETUP           --------------------------
	;---------------------------------------------------------------------------------
	; setup writting to screen
	mov ax, @data
	mov ds, ax
	mov ax, 0b800h
	mov es, ax
	
	; seed setup
	mov bx, offset seed
	push bx
	call seedSetup
	
	; initialize all content on screen:
		; backgrouund
		call screenSetup
		
		; snake
		mov bx, offset snake
		push bx
		mov bx, offset len
		push [bx]
		call snakeInit
		pop di
		
		; food
		mov bx, offset seed
		push [bx]
		call spawnFood
		pop [bx]
	;---------------------------------------------------------------------------------
	;---------------------------------------------------------------------------------
	
	
	;---------------------------------------------------------------------------------
	;-------------------------            MAIN LOOP          -------------------------
	;---------------------------------------------------------------------------------
	mainLoop:
		call delay
		
		; user input
		mov bx, offset user
		push [bx]
		call input
		pop ax
		
		; store key pressed denoting direction
		mov bx, offset user
		mov [bx], ax
		
		; if input is 'q', end the program
		cmp al, 'q'
		jz exit
		
		; manage movements:
			; up
			cmp al, 'w'
			jnz afterW
			push di
			call moveUp
			pop di
			afterW:
			
			; left
			cmp al, 'a'
			jnz afterA
			push di
			call moveLeft
			pop di
			afterA:
			
			; down
			cmp al, 's'
			jnz afterS
			push di
			call moveDown
			pop di
			afterS:
			
			; right
			cmp al, 'd'
			jnz afterD
			push di
			call moveRight
			pop di
			afterD:
		
		; manage death
		push di
		call checkDeath
		pop di
		cmp di, 4004
		jz death
		
		; manage eating:
			; check if touched food
			mov cx, [es:di]
			cmp cl, 3
			jnz dontEat
			
			; if touched food:
				; eat
				mov bx, offset len
				push [bx]
				mov bx, offset snake
				push bx
				call eat
				pop dx
			
				; spawn new piece of food
				mov bx, offset seed
				push [bx]
				call spawnFood
				pop [bx]
				mov [len], dx
		dontEat:
		
		; update the snake positions stored in the memory
		mov bx, offset len
		push [bx]
		mov bx, offset snake
		push bx
		push di
		call updateMemory
		
		; update the snake seen on screen
		push di
		call updateScreen
		
		jmp mainLoop
		;---------------------------------------------------------------------------------
		;---------------------------------------------------------------------------------
	
	death:
		mov bx, offset gameOverMessage
		push bx
		mov bx, offset gameOverMessageLength
		push [bx]
		call displayGameOver
	
exit:
	mov ax, 4c00h
	int 21h
END start


