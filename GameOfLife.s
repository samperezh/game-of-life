.global _start

//0= inactive & no cursor
//1= active & no cursor
//2= inactive & cursor
//3= active & cursor
//if move cursor to tile +2
//if move cursor away from tile -2
GoLBoard:   
	//  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 1
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 2
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 3
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 4
	.word 0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0 // 5
	.word 0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0 // 6
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 7
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 8
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 9
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // a
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // b
	
GoLBoardCopy: //temp copy of updated grid before it's updated in the screen
	//  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 1
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 2
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 3
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 4
	.word 0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0 // 5
	.word 0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0 // 6
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 7
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 8
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 9
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // a
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // b

data: .word 0 //to store keypress data
	
_start:
        bl      input_loop
end:
        b       end
		
@ TODO: copy VGA driver here.
VGA_draw_point_ASM: 
	PUSH {A1, A2, A3, V1, V2, LR}
	// Assuming, A1=x, A2=y, A3=c 
	//check if coordinates x and y are valid (x in [0,319] && y in [0,239])
	CMP A1, #0
	BLT exit_VGA_draw_point_ASM 
	LDR V1, =#319
	CMP A1, V1
	BGT exit_VGA_draw_point_ASM 

	CMP A2, #0
	BLT exit_VGA_draw_point_ASM 
	CMP A2, #239
	BGT exit_VGA_draw_point_ASM 

	// draw point in screen at x,y with color c 
	// individual pixel colors can be accessed at  0xc8000000 | (y << 10) | (x << 1)
	LDR V1, =#0xc8000000
	LSL V2, A2, #10
	ORR V1, V1, V2
	LSL V2, A1, #1
	ORR V1, V1, V2
	STRH A3, [V1] //colors encoded as 16-bit integers (half-words)


	POP {A1, A2, A3, V1, V2, LR}
	BX LR

exit_VGA_draw_point_ASM: 
	POP {A1, A2, A3, V1, V2, LR}
	BX LR
	
VGA_clear_pixelbuff_ASM:
	PUSH {A1, A2, A3, LR}
	//A1 x counter 
	//A2 y counter 
	//A3 colour 0 - clear pixel buffer
	LDR A1, =#0
	LDR A2, =#0
	LDR A3, =#0x8430 //want colour to be gray and not black
	
	BL loopX_VGA_clear_pixelbuff_ASM
	
	POP {A1, A2, A3, LR}
	BX LR
	
loopX_VGA_clear_pixelbuff_ASM:
	PUSH {V1}
	LDR V1, =#319
	CMP A1, V1
	POP {V1}
	BGT exit_loopX_VGA_clear_pixelbuff_ASM
	PUSH {LR}
	BL loopY_VGA_clear_pixelbuff_ASM
	POP {LR}
	ADD A1, A1, #1
	B loopX_VGA_clear_pixelbuff_ASM
	
exit_loopX_VGA_clear_pixelbuff_ASM:
	LDR A1, =#0 //reset X counter to 0
	BX LR
	
loopY_VGA_clear_pixelbuff_ASM:
	CMP A2, #239
	BGT exit_loopY_VGA_clear_pixelbuff_ASM
	//call VGA_draw_point_ASM with proper params to empty current location
	// Assuming, r0=x=A1, r1=y=A2, r2=c=A3 
	PUSH {LR}
	BL VGA_draw_point_ASM
	POP {LR}
	ADD A2, A2, #1
	B loopY_VGA_clear_pixelbuff_ASM

exit_loopY_VGA_clear_pixelbuff_ASM:
	LDR A2, =#0 //reset Y counter to 0 
	BX LR
		
VGA_write_char_ASM:
	PUSH {V1, V2, LR}
	// Assuming, A1=x, A2=y, A3=c 
	//check if coordinates x and y are valid (x in [0,79] && y in [0,59])
	CMP A1, #0
	BLT exit_VGA_write_char_ASM
	CMP A1, #79
	BGT exit_VGA_write_char_ASM
	
	CMP A2, #0
	BLT exit_VGA_write_char_ASM
	CMP A2, #59
	BGT exit_VGA_write_char_ASM
	
	//draw character c in screen at x,y 
	//individual character can be accessed at 0xc9000000 | (y << 7) | x
	LDR V1, =#0xc9000000
	LSL V2, A2, #7
	ORR V1, V1, V2
	ORR V1, V1, A1 
	STRB A3, [V1] //buffer of byte-sized ASCII characters
	
	POP {V1, V2, LR}
	BX LR

exit_VGA_write_char_ASM:
	POP {V1, V2, LR}
	BX LR
	
	
VGA_clear_charbuff_ASM:
	PUSH {A1, A2, A3, LR}
	//A1 x counter 
	//A2 y counter 
	//A3 colour 0 - clear pixel buffer
	LDR A1, =#0
	LDR A2, =#0
	LDR A3, =#0
	
	BL loopX_VGA_clear_charbuff_ASM
	
	POP {A1, A2, A3, LR}
	BX LR

loopX_VGA_clear_charbuff_ASM:
	PUSH {V1}
	CMP A1, #79
	POP {V1}
	BGT exit_loopX_VGA_clear_charbuff_ASM
	PUSH {LR}
	BL loopY_VGA_clear_charbuff_ASM
	POP {LR}
	ADD A1, A1, #1
	B loopX_VGA_clear_charbuff_ASM
	
exit_loopX_VGA_clear_charbuff_ASM:
	LDR A1, =#0 //reset X counter to 0
	BX LR

loopY_VGA_clear_charbuff_ASM:
	CMP A2, #59
	BGT exit_loopY_VGA_clear_charbuff_ASM
	//call VGA_write_char_ASM with proper params to empty current location
	// Assuming, A1=x, A2=y, A3=c 
	PUSH {LR}
	BL VGA_write_char_ASM
	POP {LR}
	ADD A2, A2, #1
	B loopY_VGA_clear_charbuff_ASM

exit_loopY_VGA_clear_charbuff_ASM:
	LDR A2, =#0 //reset Y counter to 0 
	BX LR

@TODO: main input_loop
input_loop:
		//clear display
        bl VGA_clear_pixelbuff_ASM
        bl VGA_clear_charbuff_ASM
		
		//draw grid
		MOV A1, #000000 //c (black)
		bl GoL_draw_grid_ASM

		//initialize cursor at x,y = 0,0
		MOV A1, #0
		MOV A2, #0
		bl GoL_put_cursor_at_location //(A1=x, A2=y)
		
		//draw initial figure
		MOV A1, #000000 //c (black)
		bl GoL_draw_board_ASM
		
		//start game
		bl GoL_game_loop

		b end

//draws a 16x12 grid in color c.
GoL_draw_grid_ASM: //A1 = c 
	PUSH {A1 - A4, V1, LR}
	MOV V1, A1 //save colour into V1
	//draw vertical lines 
	BL GoL_draw_grid_vertical_lines
	//draw horizontal lines
	BL GoL_draw_grid_horizontal_lines
	
	POP {A1 - A4, V1, LR}
	BX LR

GoL_draw_grid_vertical_lines:
	PUSH {LR}
	//call VGA_draw_line_ASM (A1=x1, A2=y1, A3=x2, A4=y2, V1= c)
	//draw 20 vertical lines where y1 = 0 & y2 = 239 (x1=x2=0 to 319)
	MOV A2, #0 //y1 = 0
	MOV A4, #239 //y2 = 239
	MOV A1, #0 //x1=0
	BL GoL_draw_grid_vertical_lines_loop
	
	//draw last line to the right
	LDR A1, =#319
	LDR A3, =#319
	BL VGA_draw_line_ASM
	
	POP {LR}
	BX LR
	
GoL_draw_grid_vertical_lines_loop: 
	PUSH {V2, LR}
	LDR V2, =#319
	CMP A1, V2
	BGT exit_GoL_draw_grid_lines_loop
	
	MOV A3, A1
	BL VGA_draw_line_ASM
	ADD A1, A1, #20
	POP {V2, LR}
	B GoL_draw_grid_vertical_lines_loop

GoL_draw_grid_horizontal_lines:
	PUSH {LR}
	//call VGA_draw_line_ASM (A1=x1, A2=y1, A3=x2, A4=y2, V1= c)
	//draw 20 horizontal lines where x1 = 0 & x2 = 319 (y1=y2=0 to 239)
	MOV A1, #0 //x1 = 0
	LDR A3, =#319 //x2 = 319
	MOV A2, #0 //y1=0
	BL GoL_draw_grid_horizontal_lines_loop
	
	//draw last line to the bottom
	LDR A2, =#239
	LDR A4, =#239
	BL VGA_draw_line_ASM
	
	POP {LR}
	BX LR
	
GoL_draw_grid_horizontal_lines_loop: 
	PUSH {V2, LR}
	LDR V2, =#239
	CMP A2, V2
	BGT exit_GoL_draw_grid_lines_loop
	
	MOV A4, A2
	BL VGA_draw_line_ASM
	ADD A2, A2, #20
	POP {V2, LR}
	B GoL_draw_grid_horizontal_lines_loop
	
exit_GoL_draw_grid_lines_loop:
	POP {V2, LR}
	BX LR

//Changes GoLBoard memory when putting cursor at location x,y in board (x=A1, y=A2)
GoL_put_cursor_at_location: 
	PUSH {V1-V3, LR}
	
	//get GoLBoard[y][x]
	LDR V1, =GoLBoard //put the address of GoLBoard in V1
	MOV V2, #16
	MLA V2, A2, V2, A1 //V2= A2*V2 + A1= (y*16+x)
	LSL V2, V2, #2 //multiply by 4 to get offset (word = 4 bytes)
	LDR V3, [V1, V2] 
	
	ADD V3, V3, #2 //update cursor tile
	STR V3, [V1, V2]

	POP {V1-V3, LR}
	BX LR
	
//Changes GoLBoard memory when removing cursor at location x,y in board (x=A1, y=A2)
GoL_remove_cursor_at_location: 
	PUSH {V1-V3, LR}
	
	//get GoLBoard[y][x]
	LDR V1, =GoLBoard //put the address of GoLBoard in V1
	MOV V2, #16
	MLA V2, A2, V2, A1 //V2= A2*V2 + A1= (y*16+x)
	LSL V2, V2, #2 //multiply by 4 to get offset (word = 4 bytes)
	LDR V3, [V1, V2] 
	
	SUB V3, V3, #2 //update cursor tile
	STR V3, [V1, V2]

	POP {V1-V3, LR}
	BX LR

//fills grid locations (x, y), 0 ≤ x < 16, 0 ≤ y < 12 with color c depending of GoLBoard[y][x].
GoL_draw_board_ASM:
	//Assume A1 = c
	PUSH {A1, A2, A3, LR} //A3=c
	MOV A3, A1
	MOV A1, #0 //x counter (0 ≤ x < 16)
	MOV A2, #0 //y counter (0 ≤ y < 12)
	BL GoL_draw_board_ASM_loopX
	POP {A1, A2, A3, LR}
	BX LR

GoL_draw_board_ASM_loopX:
	PUSH {LR}
	CMP A1, #15
	BGT exit_GoL_draw_board_ASM_loop
	BL GoL_draw_board_ASM_loopY
	ADD A1, A1, #1
	MOV A2, #0 //reset y counter to 0
	POP {LR}
	B GoL_draw_board_ASM_loopX

GoL_draw_board_ASM_loopY:
	PUSH {LR}
	CMP A2, #11
	BGT exit_GoL_draw_board_ASM_loop
	BL GoL_draw_board_ASM_check
	ADD A2, A2, #1
	POP {LR}
	B GoL_draw_board_ASM_loopY

GoL_draw_board_ASM_check:
	PUSH {A3, V1, V2, LR} //A1 = x , A2 = y
	//get GoLBoard[y][x]
	LDR V1, =GoLBoard //put the address of GoLBoard in V1
	MOV V2, #16
	MLA V2, A2, V2, A1 //V2= A2*V2 + A1= (y*16+x)
	LSL V2, V2, #2 //multiply by 4 to get offset (word = 4 bytes)
	LDR V1, [V1, V2] 

	//check if GoLBoard[y][x] == 
	LDR A3, =#0x8430 //default: 0= inactive & no cursor (gray)
	CMP V1, #1 
	LDREQ A3, =#0 //1= active & no cursor (black)
	CMP V1, #2
	LDREQ A3, =#0xFD7A //2= inactive & cursor (lavender pink)
	CMP V1, #3 
	LDREQ A3, =#0xD8D0 //3= active & cursor (barbie pink)
	//if yes, call GoL_fill_gridxy_ASM (A1=x, A2=y) (A3=c)
	BL GoL_fill_gridxy_ASM
	POP {A3, V1, V2, LR}
	BX LR
	
exit_GoL_draw_board_ASM_loop:
	POP {LR}
	BX LR

//fills the area of grid location (x, y) with color c ((x, y), 0 ≤ x < 16, 0 ≤ y < 12)
GoL_fill_gridxy_ASM:
	PUSH {A1 - A4,V1, V2, V3, V4, LR}
	//Assume A1=x, A2=y, A3=c
	MOV V1, A3 //move colour c to V1
	MOV V2, A1 //move x to V2
	MOV V3, A2 //move y to V3
	MOV V4, #20
	
	//set up x coordinates
	MUL A1, V2, V4 //A1=x1 (x1 = x*20)
	ADD A3, A1, #20 //A3=x2 (x2 = x1 + 19) //to review
	
	//set up y coordinates 	
	MUL A2, V3, V4 //A2=y1 (y1 = y*20)
	ADD A4, A2, #20 //A4=y2 (y2 = y1 + 19) //to review
	
	BL VGA_draw_rect_ASM //(A1=x1, A2=y1, A3=x2, A4=y2, V1=c)
	
	POP {A1 - A4, V1, V2, V3, V4, LR}
	BX LR


//draws a rectangle from pixel (x1, y1) to (x2, y2) in color c
VGA_draw_rect_ASM:
	//Assume A1=x1, A2=y1, A3=x2, A4=y2, V1=c
	PUSH {V2, LR}
	//ensure x1 < x2 
	MOV V2, A1
	CMP A1, A3
	MOVGT A1, A3
	MOVGT A3, V2

	//ensure y1 < y2
	MOV V2, A2
	CMP A2, A4
	MOVGT A2, A4
	MOVGT A4, V2
	
	BL VGA_draw_rect_ASM_loop
	
	POP {V2, LR}
	BX LR
	

VGA_draw_rect_ASM_loop: 
	PUSH {LR}
	CMP A1, A3
	BGT exit_VGA_draw_rect_ASM_loop
	CMP A2, A4
	BGT exit_VGA_draw_rect_ASM_loop
	ADD A1, A1, #1
	SUB A3, A3, #1
	ADD A2, A2, #1
	SUB A4, A4, #1
	BL VGA_draw_empty_rect_ASM
	POP {LR}
	B VGA_draw_rect_ASM_loop
	
	//call VGA_draw_empty_rect_ASM

VGA_draw_empty_rect_ASM:
	PUSH {V2, LR} //V2 temp variable
	//draw horizontal line 1 (at y1)
	MOV V2, A4
	MOV A4, A2 //A4(line)=y2(line)=y1(rectangle)=A2(rectangle)
	BL VGA_draw_line_ASM //(A1=x1, A2=y1, A3=x2, A4=y2, V1= c)
	MOV A4, V2
	
	//draw horizontal line 2 (at y2)
	MOV V2, A2
	MOV A2, A4 //A2(line)=y1(line)=y2(rectangle)=A4(rectangle)
	BL VGA_draw_line_ASM //(A1=x1, A2=y1, A3=x2, A4=y2, V1= c)
	MOV A2, V2
	
	//draw vertical line 1 (at x1)
	MOV V2, A3
	MOV A3, A1 //A3(line)=x2(line)=x1(rectangle)=A1(rectangle)
	BL VGA_draw_line_ASM //(A1=x1, A2=y1, A3=x2, A4=y2, V1= c)
	MOV A3, V2
	
	//draw vertical line 2 (at x2)
	MOV V2, A1
	MOV A1, A3 //A1(line)=x1(line)=x2(rectangle)=A3(rectangle)
	BL VGA_draw_line_ASM //(A1=x1, A2=y1, A3=x2, A4=y2, V1= c)
	MOV A1, V2
	
	POP {V2, LR}
	BX LR

exit_VGA_draw_rect_ASM_loop:
	POP {LR}
	BX LR

//draws a line from pixel (x1, y1) to (x2, y2) in color c
VGA_draw_line_ASM: 
	//Assume A1=x1, A2=y1, A3=x2, A4=y2, V1= c
	//case x1 == x2 -> draw vertical line 
	//case y1 == y2 -> draw a horizontal line
	PUSH {A1-A4, LR}
	CMP A1, A3
	BLEQ VGA_draw_vertical_line
	CMP A2, A4
	BLEQ VGA_draw_horizontal_line
	
	POP {A1-A4, LR}
	BX LR

VGA_draw_vertical_line: //A1 == A3
	PUSH {A3, V2, V3, LR}
	//counter from V2 to V3
	MOV V2, A2
	MOV V3, A4
	CMP A2, A4 
	MOVGT V2, A4
	MOVGT V3, A2
	MOV A3, V2
	BL VGA_draw_vertical_line_loop
	POP {A3, V2, V3, LR}
	BX LR	
	
VGA_draw_vertical_line_loop:
	PUSH {A2, A3, V2, LR}
	MOV V2, A3
	
	CMP V2, V3
	BGT exit_draw_line_loop
	//VGA_draw_point_ASM: Assuming, A1=x, A2=y, A3=c 
	//A1 = x already 
	//A2 = V2 = y current 
	//A3 = V1 = color = 0 = black
	MOV A2, V2
	MOV A3, V1

	BL VGA_draw_point_ASM
	POP {A2, A3, V2, LR}
	ADD A3, A3, #1
	B VGA_draw_vertical_line_loop

VGA_draw_horizontal_line: //A2 = A4
	PUSH {A4, V2, V3, LR}
	//counter from V2 to V3
	MOV V2, A1
	MOV V3, A3
	CMP A1, A3 
	MOVGT V2, A3
	MOVGT V3, A1
	MOV A4, V2
	BL VGA_draw_horizontal_line_loop
	POP {A4, V2, V3, LR}
	BX LR

VGA_draw_horizontal_line_loop:
	PUSH {A1, A4, V2, LR}
	MOV V2, A4
	
	CMP V2, V3
	BGT exit_draw_line_loop
	//VGA_draw_point_ASM: Assuming, A1=x, A2=y, A3=c 
	//A1 = V2 = x current
	//A2 = y already
	//A3 = V1 = color = 0 = black
	MOV A1, V2
	MOV A3, V1

	BL VGA_draw_point_ASM
	POP {A1, A4, V2, LR}
	ADD A4, A4, #1
	B VGA_draw_horizontal_line_loop
	
exit_draw_line_loop:
	POP {A1, A4, V2, LR}
	BX LR
	
@ TODO: insert PS/2 driver here.
//checks the RVALID bit in the PS/2 Data Register
//if valid -> data should be read, stored at the address data & return 1
//if not valid -> return 0
//input char * data (address) - r0 (A1)
//output 1 = valid, 0 = not valid - r0 (A1)
read_PS2_data_ASM:
	PUSH {A2, V1, LR}
	//get RVALID bit 
	LDR V1, =#0xff200100
	LDR V1, [V1]
	
	//store lowest 8 bits in A2 (data)
	AND A2, V1, #0b011111111
	LSR V1, V1, #15
	AND V1, V1, #0x1
	
	CMP V1, #1
	MOVNE A1, #0
	BLEQ read_PS2_data
	
	POP {A2, V1, LR}
	BX LR

read_PS2_data:
	//data should be read, stored at the address data (r0)
	PUSH {V1}
	STRB A2, [A1] //storing 8 bits (= 1 byte)
	MOV A1, #1
	POP {V1}
	BX LR
	
GoL_game_loop: 
	//check for keypress
	//call read_PS2_data_ASM
	//input: A1 (address)
	//output: A1 (1=valid, 0=not valid)
	LDR A1, =data 
	BL read_PS2_data_ASM
	CMP A1, #1
	BLEQ GoL_key_pressed //valid
	
	//rest of game logic
	
	B GoL_game_loop

GoL_key_pressed: 
	PUSH {A1, A2, A3, A4, LR}
	MOV A2, #0 //initialize counter to 0
	
	//get cursor coordinates and stores them in (A3,A4)=(x,y)
	BL Get_cursor_coord 
	
	//check what is stored in data 
	LDR A1, =data
	LDRB A1, [A1]
	
	//case w: 
	CMP A1, #0x1D
	BLEQ move_cursor_up_loop
	
	//case a:
	CMP A1, #0x1C
	BLEQ move_cursor_left_loop
	
	//case s:
	CMP A1, #0x1B
	BLEQ move_cursor_down_loop
	
	//case d:
	CMP A1, #0x23
	BLEQ move_cursor_right_loop
	
	//case space bar:
	CMP A1, #0x29
	BLEQ space_bar_pressed_loop
	
	//case n:
	CMP A1, #0x31
	BLEQ n_pressed_loop
	
	//update board visually
	BL GoL_draw_board_ASM
	
	POP {A1, A2, A3, A4, LR}
	BX LR

move_cursor_up_loop:
	PUSH {A1, LR}
	//A2 counter 
	CMP A2, #2
	BEQ move_cursor_up
	
	LDR A1, =data 
	BL read_PS2_data_ASM
	CMP A1, #1
	ADDEQ A2, A2, #1 
	
	POP {A1, LR}
	B move_cursor_up_loop
	
move_cursor_left_loop:
	PUSH {A1, LR}
	//A2 counter 
	CMP A2, #2
	BEQ move_cursor_left
	
	LDR A1, =data 
	BL read_PS2_data_ASM
	CMP A1, #1
	ADDEQ A2, A2, #1 
	
	POP {A1, LR}
	B move_cursor_left_loop
	
move_cursor_right_loop:
	PUSH {A1, LR}
	//A2 counter 
	CMP A2, #2
	BEQ move_cursor_right
	
	LDR A1, =data 
	BL read_PS2_data_ASM
	CMP A1, #1
	ADDEQ A2, A2, #1 
	
	POP {A1, LR}
	B move_cursor_right_loop
	
move_cursor_down_loop:
	PUSH {A1, LR}
	//A2 counter 
	CMP A2, #2
	BEQ move_cursor_down
	
	LDR A1, =data 
	BL read_PS2_data_ASM
	CMP A1, #1
	ADDEQ A2, A2, #1 
	
	POP {A1, LR}
	B move_cursor_down_loop

space_bar_pressed_loop:
	PUSH {A1, LR}
	//A2 counter 
	CMP A2, #2
	BEQ space_bar_pressed
	
	LDR A1, =data 
	BL read_PS2_data_ASM
	CMP A1, #1
	ADDEQ A2, A2, #1 
	
	POP {A1, LR}
	B space_bar_pressed_loop
	
n_pressed_loop:
	PUSH {A1, LR}
	//A2 counter 
	CMP A2, #2
	BEQ n_pressed
	
	LDR A1, =data 
	BL read_PS2_data_ASM
	CMP A1, #1
	ADDEQ A2, A2, #1 
	
	POP {A1, LR}
	B n_pressed_loop

//loop initializer -> loopX
//loopX -> loopY
//loopCurrent (x,y) 
	//check how many active neighbours it has 
	//(don't forget to check if x,y neighbor is off-grid before actually checking GoLBoard[x][y]
	//depending on number of active neighbours and whether it's active or not active
		//do 4 cases -> 4 func? if first case doesn't work call next case? 
		//store new state of (x,y) in GoLBoardCopy
		
//copy the GoLBoardCopy into GoLBoard
//call GoL_draw_board_ASM to update UI on screen 
n_pressed:
	POP {A1, LR} 
	PUSH {A1, A2, LR}
	MOV A1, #0 //x counter (0 ≤ x < 16)
	MOV A2, #0 //y counter (0 ≤ y < 12)
	BL n_pressed_loopX
	
	//part 3
	//copy the GoLBoardCopy into GoLBoard
	BL GoLBoard_Copy
	
	//call GoL_draw_board_ASM to update UI on screen 
	BL GoL_draw_board_ASM
	
	POP {A1, A2, LR}
	BX LR
	
n_pressed_loopX:
	PUSH {LR}
	CMP A1, #15
	BGT exit_n_pressed_loop
	BL n_pressed_loopY
	ADD A1, A1, #1
	MOV A2, #0 //reset y counter to 0
	POP {LR}
	B n_pressed_loopX
	
n_pressed_loopY:
	PUSH {LR}
	CMP A2, #11
	BGT exit_n_pressed_loop
	BL n_pressed_current
	ADD A2, A2, #1
	POP {LR}
	B n_pressed_loopY

n_pressed_current:
	//A1 = x , A2 = y
	PUSH {A1, A2, A3, A4, V1, V2, V3, V4, LR} 
	//V1: variable, V2: offset, 
	//V3:x neighbour, V4:y neighbour 
	//A3: counter of active neighbours
	//A4: off-grid status of neighbour or active/inactive status
	
	MOV A3, #0 //initialize counter of active neighbours 

	//part 1
	//Loop through each neighbour (8) 
	//Check if "neighbour" is off-grid
	//if neighbour active, increase counter
	
	//neighbour #1 (top)
	MOV V3, A1 //same x
	SUB V4, A2, #1 // y-1 	
	//check if off-grid 
	MOV A4, #0 //initialize off-grid status
	BL check_off_grid_status_of_tile ////returns in A4 #1(off-grid), #0 else
	//check active/inactive status if not off-grid 
	CMP A4, #0 //if 0, not off-grid
	MOV A4, #0 //assume inactive
	BLEQ check_active_status_of_tile //returns in A4 #0(inactive) #1(active)
	CMP A4, #1 //if active, increase active neighbours counter
	ADDEQ A3, A3, #1  
	
	//neighbour #2 (top - right)
	ADD V3, A1, #1 //x+1
	SUB V4, A2, #1 // y-1 
	//check if off-grid 
	MOV A4, #0 //initialize off-grid status
	BL check_off_grid_status_of_tile ////returns in A4 #1(off-grid), #0 else
	//check active/inactive status if not off-grid 
	CMP A4, #0 //if 0, not off-grid
	MOV A4, #0 //assume inactive
	BLEQ check_active_status_of_tile //returns in A4 #0(inactive) #1(active)
	CMP A4, #1 //if active, increase active neighbours counter
	ADDEQ A3, A3, #1 
	
	//neighbour #3 (right)
	ADD V3, A1, #1 //x+1
	MOV V4, A2 //same y 
	//check if off-grid 
	MOV A4, #0 //initialize off-grid status
	BL check_off_grid_status_of_tile ////returns in A4 #1(off-grid), #0 else
	//check active/inactive status if not off-grid 
	CMP A4, #0 //if 0, not off-grid
	MOV A4, #0 //assume inactive
	BLEQ check_active_status_of_tile //returns in A4 #0(inactive) #1(active)
	CMP A4, #1 //if active, increase active neighbours counter
	ADDEQ A3, A3, #1 
	
	//neighbour #4 (bottom - right)
	ADD V3, A1, #1 //x+1
	ADD V4, A2, #1 //y+1
	//check if off-grid 
	MOV A4, #0 //initialize off-grid status
	BL check_off_grid_status_of_tile ////returns in A4 #1(off-grid), #0 else
	//check active/inactive status if not off-grid 
	CMP A4, #0 //if 0, not off-grid
	MOV A4, #0 //assume inactive
	BLEQ check_active_status_of_tile //returns in A4 #0(inactive) #1(active)
	CMP A4, #1 //if active, increase active neighbours counter
	ADDEQ A3, A3, #1 
	
	//neighbour #5 (bottom)
	MOV V3, A1 //same x
	ADD V4, A2, #1 //y+1
	//check if off-grid 
	MOV A4, #0 //initialize off-grid status
	BL check_off_grid_status_of_tile ////returns in A4 #1(off-grid), #0 else
	//check active/inactive status if not off-grid 
	CMP A4, #0 //if 0, not off-grid
	MOV A4, #0 //assume inactive
	BLEQ check_active_status_of_tile //returns in A4 #0(inactive) #1(active)
	CMP A4, #1 //if active, increase active neighbours counter
	ADDEQ A3, A3, #1 
	
	//neighbour #6 (bottom - left)
	SUB V3, A1, #1 // x-1
	ADD V4, A2, #1 //y+1
	//check if off-grid 
	MOV A4, #0 //initialize off-grid status
	BL check_off_grid_status_of_tile ////returns in A4 #1(off-grid), #0 else
	//check active/inactive status if not off-grid 
	CMP A4, #0 //if 0, not off-grid
	MOV A4, #0 //assume inactive
	BLEQ check_active_status_of_tile //returns in A4 #0(inactive) #1(active)
	CMP A4, #1 //if active, increase active neighbours counter
	ADDEQ A3, A3, #1 
	
	//neighbour #7 (left)
	SUB V3, A1, #1 // x-1
	MOV V4, A2 //same y
	//check if off-grid 
	MOV A4, #0 //initialize off-grid status
	BL check_off_grid_status_of_tile ////returns in A4 #1(off-grid), #0 else
	//check active/inactive status if not off-grid 
	CMP A4, #0 //if 0, not off-grid
	MOV A4, #0 //assume inactive
	BLEQ check_active_status_of_tile //returns in A4 #0(inactive) #1(active)
	CMP A4, #1 //if active, increase active neighbours counter
	ADDEQ A3, A3, #1 
	
	//neighbour #8 (top - left)
	SUB V3, A1, #1 // x-1
	SUB V4, A2, #1 //y-1
	//check if off-grid 
	MOV A4, #0 //initialize off-grid status
	BL check_off_grid_status_of_tile ////returns in A4 #1(off-grid), #0 else
	//check active/inactive status if not off-grid 
	CMP A4, #0 //if 0, not off-grid
	MOV A4, #0 //assume inactive
	BLEQ check_active_status_of_tile //returns in A4 #0(inactive) #1(active)
	CMP A4, #1 //if active, increase active neighbours counter
	ADDEQ A3, A3, #1 
	
	//part2
	//check if current is active or inactive 
	MOV V3, A1
	MOV V4, A2
	//input V3=x, V4=y 
	//ouput stored in A4 #0 if inactive, #1 if active
	BL check_active_status_of_tile //A4=active status of current
	
	//loop through 4 cases based on # active neighbours (A3)
	BL check_state_case_1 
	//return instead A4=toggle active status (if #1 (inactive <->active))
	
	//store new state of (x,y) in GoLBoardCopy
	//get GoLBoard[y][x]
	LDR V1, =GoLBoard //put the address of GoLBoard in V1
	MOV V2, #16
	MLA V2, A2, V2, A1 //V2= A2*V2 + A1= (y*16+x)
	LSL V2, V2, #2 //multiply by 4 to get offset (word = 4 bytes)
	LDR A3, [V1, V2] //old status with cursor status A3
	
	//A4 new toggle(#1)/no toggle(#0) status of current 
	CMP A4, #1
	BLEQ toggle_status_with_cursor_status
	
	//store A3 in GoLBoardCopy
	LDR V1, =GoLBoardCopy //put the address of GoLBoard in V1
	STR A3, [V1, V2] //new status with cursor status A3
	
	POP {A1, A2, A3, A4, V1, V2, V3, V4, LR}
	BX LR

exit_n_pressed_loop:
	POP {LR}
	BX LR

//Any active cell with 0 or 1 active neighbors becomes inactive.
//input: A3:active neighbours counter, A4:active/inactive status of current
//output: A4: new active/inactive status of current (#0 inactive, #1 active)
check_state_case_1:
	CMP A4, #0 //jump directly to case 4
	BEQ check_state_case_4
	CMP A3, #1
	BGT check_state_case_2
	MOV A4, #1 //toggle
	BX LR
	
//Any active cell with 2 or 3 active neighbors remains active.	
check_state_case_2:
	CMP A3, #3
	BGT check_state_case_3
	MOV A4, #0 //no toggle
	BX LR

//Any active cell with 4 or more active neighbors becomes inactive.
check_state_case_3:
	MOV A4, #1 //toggle
	BX LR
	
//Any inactive cell with exactly 3 active neighbors becomes active.
check_state_case_4:
	MOV A4, #0 //assume no toggle
	CMP A3, #3
	MOVEQ A4, #1 //toggle
	BX LR
	
//input A3: old active status with cursor status
//output A3: new active status with cursor status
toggle_status_with_cursor_status:
	PUSH {V1}
	CMP A3, #0
	MOVEQ V1, #1
	
	CMP A3, #1
	MOVEQ V1, #0
	
	CMP A3, #2
	MOVEQ V1, #3
	
	CMP A3, #3
	MOVEQ V1, #2
	
	MOV A3, V1
	
	POP {V1}
	BX LR
	

//checks the active/inactive status of the given tile 
//input V3=x, V4=y 
//ouput stored in A4 #0 if inactive, #1 if active
check_active_status_of_tile:
	PUSH {V1, V2}
	//get GoLBoard[y][x]
	LDR V1, =GoLBoard //put the address of GoLBoard in V1
	MOV V2, #16
	MLA V2, V4, V2, V3 //V2= V4*V2 + V3= (y*16+x)
	LSL V2, V2, #2 //multiply by 4 to get offset (word = 4 bytes)
	LDR V1, [V1, V2] 
	
	//assume inactive (V1=0, 2)
	MOV A4, #0
	CMP V1, #1
	MOVEQ A4, #1
	CMP V1, #3
	MOVEQ A4, #1
	
	POP {V1, V2}
	BX LR

//checks the given tile is off-grid
//input V3=x, V4=y 
//ouput stored in A4 #1 if off-grid, #0 else
check_off_grid_status_of_tile:
	CMP V3, #0 
	MOVLT A4, #1
	CMP V3, #15
	MOVGT A4, #1 
	CMP V4, #0 
	MOVLT A4, #1
	CMP V4, #11
	MOVGT A4, #1
	BX LR

GoLBoard_Copy:
	PUSH {A1, A2, LR}
	MOV A1, #0 //x counter (0 ≤ x < 16)
	MOV A2, #0 //y counter (0 ≤ y < 12)
	BL GoLBoard_Copy_loopX
	POP {A1, A2, LR}
	BX LR
	
GoLBoard_Copy_loopX:
	PUSH {LR}
	CMP A1, #15
	BGT exit_GoLBoard_Copy_loop
	BL GoLBoard_Copy_loopY
	ADD A1, A1, #1
	MOV A2, #0 //reset y counter to 0
	POP {LR}
	B GoLBoard_Copy_loopX
	
GoLBoard_Copy_loopY:
	PUSH {LR}
	CMP A2, #11
	BGT exit_GoLBoard_Copy_loop
	BL GoLBoard_Copy_check
	ADD A2, A2, #1
	POP {LR}
	B GoLBoard_Copy_loopY
	
GoLBoard_Copy_check:
	PUSH {V1, V2, V3, LR} //A1 = x , A2 = y
	
	//get GoLBoard[y][x]
	LDR V1, =GoLBoardCopy //put the address of GoLBoardCopy in V1
	MOV V2, #16
	MLA V2, A2, V2, A1 //V2= A2*V2 + A1= (y*16+x)
	LSL V2, V2, #2 //multiply by 4 to get offset (word = 4 bytes)
	LDR V3, [V1, V2] 
	
	LDR V1, =GoLBoard //put the address of GoLBoard in V1
	STRB V3, [V1, V2] 

	POP {V1, V2, V3, LR}
	BX LR

exit_GoLBoard_Copy_loop:
	POP {LR}
	BX LR

//toggle the state of the grid location where the cursor is located.
space_bar_pressed: //cursor location A3,A4
	POP {A1, LR} 
	PUSH {V1-V3, LR}
	
	//get GoLBoard[y][x]
	LDR V1, =GoLBoard //put the address of GoLBoard in V1
	MOV V2, #16
	MLA V2, A4, V2, A3 //V2= A4*V2 + A3= (y*16+x)
	LSL V2, V2, #2 //multiply by 4 to get offset (word = 4 bytes)
	LDR V3, [V1, V2] 
	
	//Toggle
	CMP V3, #3 //Tile = 3 -> active (&cursor) 
	MOV V3, #3 //default assume tile =2 (inactive) make tile 3 -> active (&cursor)
	MOVEQ V3, #2 //make tile 2 -> inactive (&cursor)
	
	STR V3, [V1, V2]

	POP {V1-V3, LR}
	BX LR

move_cursor_up:	//cursor location A3,A4
	POP {A1, LR}
	PUSH {A1, A2, LR}
	//check if goes off grid
	CMP A4, #0
	BEQ moving_cursor_off_grid
	
	MOV A1, A3
	MOV A2, A4
	BL GoL_remove_cursor_at_location //(A1=x, A2=y)
	
	SUB A2, A2, #1
	BL GoL_put_cursor_at_location //(A1=x, A2=y)
	
	POP {A1, A2, LR}
	BX LR
	
move_cursor_left: //cursor location A3,A4
	POP {A1, LR}
	PUSH {A1, A2, LR}
	//check if goes off grid
	CMP A3, #0
	BEQ moving_cursor_off_grid
	
	MOV A1, A3
	MOV A2, A4
	BL GoL_remove_cursor_at_location //(A1=x, A2=y)
	
	SUB A1, A1, #1
	BL GoL_put_cursor_at_location //(A1=x, A2=y)
	
	POP {A1, A2, LR}
	BX LR

move_cursor_down: //cursor location A3,A4
	POP {A1, LR}
	PUSH {A1, A2, LR}
	//check if goes off grid
	CMP A4, #11
	BEQ moving_cursor_off_grid
	
	MOV A1, A3
	MOV A2, A4
	BL GoL_remove_cursor_at_location //(A1=x, A2=y)
	
	ADD A2, A2, #1
	BL GoL_put_cursor_at_location //(A1=x, A2=y)
	
	POP {A1, A2, LR}
	BX LR

move_cursor_right: //cursor location A3,A4
	POP {A1, LR}
	PUSH {A1, A2, LR}
	//check if goes off grid
	CMP A3, #15
	BEQ moving_cursor_off_grid
	
	MOV A1, A3
	MOV A2, A4
	BL GoL_remove_cursor_at_location //(A1=x, A2=y)
	
	ADD A1, A1, #1
	BL GoL_put_cursor_at_location //(A1=x, A2=y)
	
	POP {A1, A2, LR}
	BX LR

moving_cursor_off_grid:
	POP {A1, A2, LR}
	BX LR


Get_cursor_coord:
	PUSH {A1, A2, LR}
	MOV A1, #0 //x counter (0 ≤ x < 16)
	MOV A2, #0 //y counter (0 ≤ y < 12)
	BL Get_cursor_coord_loopX
	POP {A1, A2, LR}
	BX LR

Get_cursor_coord_loopX:
	PUSH {LR}
	CMP A1, #15
	BGT exit_Get_cursor_coord_loop
	BL Get_cursor_coord_loopY
	ADD A1, A1, #1
	MOV A2, #0 //reset y counter to 0
	POP {LR}
	B Get_cursor_coord_loopX
	
Get_cursor_coord_loopY:
	PUSH {LR}
	CMP A2, #11
	BGT exit_Get_cursor_coord_loop
	BL Get_cursor_coord_check
	ADD A2, A2, #1
	POP {LR}
	B Get_cursor_coord_loopY
	
Get_cursor_coord_check:
	PUSH {V1, V2, LR} //A1 = x , A2 = y
	//get GoLBoard[y][x]
	LDR V1, =GoLBoard //put the address of GoLBoard in V1
	MOV V2, #16
	MLA V2, A2, V2, A1 //V2= A2*V2 + A1= (y*16+x)
	LSL V2, V2, #2 //multiply by 4 to get offset (word = 4 bytes)
	LDR V1, [V1, V2] 

	//check if GoLBoard[y][x] == 
	CMP V1, #2 //2= inactive & cursor
	MOVEQ A3, A1
	MOVEQ A4, A2

	CMP V1, #3 //3= active & cursor
	MOVEQ A3, A1
	MOVEQ A4, A2

	POP {V1, V2, LR}
	BX LR
	
exit_Get_cursor_coord_loop:
	POP {LR}
	BX LR
