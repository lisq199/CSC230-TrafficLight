@ CSC230 --  Traffic Light simulation program
@ Latest edition: Fall 2011
@ Author:  Micaela Serra 
@ Modified by: Siqi Li V00768565 <---- PUT YOUR NAME AND ID HERE!!!! 

@===== STAGE 0
@  	Sets initial outputs and screen for INIT
@ Calls StartSim to start the simulation,
@	polls for left black button, returns to main to exit simulation

        .equ    SWI_EXIT, 		0x11		@terminate program
        @ swi codes for using the Embest board
        .equ    SWI_SETSEG8, 		0x200	@display on 8 Segment
        .equ    SWI_SETLED, 		0x201	@LEDs on/off
        .equ    SWI_CheckBlack, 	0x202	@check press Black button
        .equ    SWI_CheckBlue, 		0x203	@check press Blue button
        .equ    SWI_DRAW_STRING, 	0x204	@display a string on LCD
        .equ    SWI_DRAW_INT, 		0x205	@display an int on LCD  
        .equ    SWI_CLEAR_DISPLAY, 	0x206	@clear LCD
        .equ    SWI_DRAW_CHAR, 		0x207	@display a char on LCD
        .equ    SWI_CLEAR_LINE, 	0x208	@clear a line on LCD
        .equ 	SEG_A,			0x80	@ patterns for 8 segment display
	.equ 	SEG_B,			0x40
	.equ 	SEG_C,			0x20
	.equ 	SEG_D,			0x08
	.equ 	SEG_E,			0x04
	.equ 	SEG_F,			0x02
	.equ 	SEG_G,			0x01
	.equ 	SEG_P,			0x10                
        .equ    LEFT_LED, 		0x02	@patterns for LED lights
        .equ    RIGHT_LED, 		0x01
        .equ    BOTH_LED, 		0x03
        .equ    NO_LED, 		0x00       
        .equ    LEFT_BLACK_BUTTON, 	0x02	@ bit patterns for black buttons
        .equ    RIGHT_BLACK_BUTTON,	0x01
        @ bit patterns for blue keys 
        .equ    Ph1, 			0x0100	@ =8
        .equ    Ph2, 			0x0200	@ =9
        .equ    Ps1, 			0x0400	@ =10
        .equ    Ps2, 			0x0800	@ =11

	@ timing related
	.equ    SWI_GetTicks, 		0x6d	@get current time 
	.equ    EmbestTimerMask, 	0x7fff	@ 15 bit mask for Embest timer
						@(2^15) -1 = 32,767        										
        .equ	OneSecond,		1000	@ Time intervals
        .equ	TwoSecond,		2000
	@define the 2 streets
	@	.equ	MAIN_STREET		0
	@	.equ	SIDE_STREET		1
 
       .text           
       .global _start

@===== The entry point of the program
_start:		
	@ initialize all outputs
	BL Init				@ void Init ()
	@ Check for left black button press to start simulation
RepeatTillBlackLeft:
	swi     SWI_CheckBlack
	cmp     r0, #LEFT_BLACK_BUTTON	@ start of simulation
	beq		StrS
	cmp     r0, #RIGHT_BLACK_BUTTON	@ stop simulation
	beq     StpS

	bne     RepeatTillBlackLeft
StrS:	
	BL StartSim		@else start simulation: void StartSim()
	@ on return here, the right black button was pressed
StpS:
	BL EndSim		@clear board: void EndSim()
EndTrafficLight:
	swi	SWI_EXIT
	
@ === Init ( )-->void
@   Inputs:	none	
@   Results:  none 
@   Description:
@ 		both LED lights on
@		8-segment = point only
@		LCD = ID only
Init:
	stmfd	sp!,{r1-r10,lr}
	@ LCD = ID on line 1
	mov	r1, #0			@ r1 = row
	mov	r0, #0			@ r0 = column 
	ldr	r2, =lineID		@ identification
	swi	SWI_DRAW_STRING
	@ both LED on
	mov	r0, #BOTH_LED	@LEDs on
	swi	SWI_SETLED
	@ display point only on 8-segment
	mov	r0, #10			@8-segment pattern off
	mov	r1,#1			@point on
	BL	Display8Segment

DoneInit:
	LDMFD	sp!,{r1-r10,pc}

@===== EndSim()
@   Inputs:  none
@   Results: none
@   Description:
@      Clear the board and display the last message
EndSim:	
	stmfd	sp!, {r0-r2,lr}
	mov	r0, #10				@8-segment pattern off
	mov	r1,#0
	BL	Display8Segment		@Display8Segment(R0:number;R1:point)
	mov	r0, #NO_LED
	swi	SWI_SETLED
	swi	SWI_CLEAR_DISPLAY
	mov	r0, #5
	mov	r1, #7
	ldr	r2, =Goodbye
	swi	SWI_DRAW_STRING  	@ display goodbye message on line 7
	ldmfd	sp!, {r0-r2,pc}
	
@ === StartSim ( )-->void
@   Inputs:	none	
@   Results:  none 
@   Description:
@ 		XXX
StartSim:
	stmfd	sp!,{r1-r10,lr}
	mov	r4,#2		@avoid jumping to S5 or end of the program
InfiniteLoop:
	BL	CarCycle
	cmp	r4,#0
	beq	DoneStartSim
	cmp	r4,#3
	beq	InfiniteLoop
	BL	PedCycle
	cmp	r4,#0
	beq	DoneStartSim
	bal	InfiniteLoop
DoneStartSim:
	LDMFD	sp!,{r1-r10,pc}

@ === int CarCycle(status r4)
@ inputs: r4 = 1 - coming from I1/I2
@              2 - coming from I3
@ results: r4 = 0 - exit the program
@               1 - I1/I2
@               2 - I3
@ Description: Car Cycle
CarCycle:
	stmfd sp!,{r0-r3,r5-r10,lr}
	cmp	r4,#1
	beq	S5C
@@@start of S1 (where I3 returns)
S1C:	@state
	mov	r10,#1		@S1 state #
	BL	DrawState
	@led
	mov	r0, #LEFT_LED
	swi	SWI_SETLED
	@8-seg
	mov	r0,#10		@8-segment pattern off
	mov	r1,#1		@point on
	BL	Display8Segment
	mov	r3,#4		@r3 as counter
S1Loop:	
	@@@S1.1
	@screen
	mov	r10,#1		@S1.1 screen #
	BL	DrawScreen 
	@duration
	mov	r10,#TwoSecond
	BL	Wait
	@@@S1.2
	@screen
	mov	r10,#2		@S1.2 screen #
	BL	DrawScreen
	@duration
	mov	r10,#OneSecond
	BL	Wait
	sub	r3,r3,#1
	cmp	r3,#0
	bne	S1Loop
@@@end of S1
@@@check right black button
	swi	SWI_CheckBlack
	cmp	r0, #RIGHT_BLACK_BUTTON
	beq	CarCycleBlack	@stop simulation
@@@Check I1
	swi	SWI_CheckBlue
	and	r0,r0,#0x0f00	@eliminate everything except 8-11
	cmp	r0,#0
	bne	CarCycleI1
@@@start of S2
	@state
	mov	r10,#2		@S2 state #
	BL	DrawState
	mov	r3,#2		@r3 as counter
S2Loop:
	@@@S2.1
	@screen
	mov	r10,#1		@S2.1 screen #
	BL	DrawScreen
	@led (same)
	@8-seg (same)
	@duration
	mov	r10,#TwoSecond
	BL	WaitAndPoll
	@check right black and blue button
	cmp	r5,#1
	beq	CarCycleBlack	@poll black
	cmp	r5,#2
	beq	CarCycleI1	@poll blue
	@@@S2.2
	@screen
	mov	r10,#2		@S2.2 screen #
	BL	DrawScreen
	@led (same)
	@8-seg (same)
	@duration
	mov	r10,#OneSecond
	BL	WaitAndPoll
	@check right black and blue button
	cmp	r5,#1
	beq	CarCycleBlack	@poll black
	cmp	r5,#2
	beq	CarCycleI1	@poll blue
	sub	r3,r3,#1
	cmp	r3,#0
	bne	S2Loop
@@@end of S2
@@@start of S3
	@state
	mov	r10,#3		@S3 state #
	BL	DrawState
	@screen
	mov	r10,#3		@S3 screen #
	BL	DrawScreen
	@8-seg
	mov	r0,#10		@8-segment pattern off
	mov	r1,#0		@point off
	BL	Display8Segment
	@duration
	mov	r10,#500	@half a second
	mov	r3,#4		@r3 as counter
	@led
	mov	r0,#NO_LED
S3Loop:
	@led
	eor	r0,r0,#BOTH_LED	@change between no led and both led
	swi	SWI_SETLED
	@duration
	BL	Wait
	sub	r3,r3,#1
	cmp	r3,#0
	bne	S3Loop
@@@end of S3
@@@start of S4
	@state
	mov	r10,#4		@S4 state #
	BL	DrawState
	@screen
	mov	r10,#4		@S4 screen #
	BL	DrawScreen
	@led
	mov	r0,#BOTH_LED
	swi	SWI_SETLED
	@8-seg (same)
	@duration
	mov	r10,#OneSecond
	BL	Wait
@@@end of S4
@@@start of S5 (where I1/I2 returns)
S5C:	@state
	mov	r10,#5		@S5 state #
	BL	DrawState
	@screen
	mov	r10,#5		@S5 screen #
	BL	DrawScreen
	@led
	mov	r0,#RIGHT_LED
	swi	SWI_SETLED
	@8-seg
	mov	r0,#10		@8-segment pattern off
	mov	r1,#1		@point on
	BL	Display8Segment
	@duration
	mov	r10,#TwoSecond
	BL	Wait
	BL	Wait
	BL	Wait		@wait 3*2=6 seconds
@@@end of S5
@@@start of S6
	@state
	mov	r10,#6		@S6 state #
	BL	DrawState
	@screen
	mov	r10,#6		@S6 screen #
	BL	DrawScreen
	@led (same)
	@8-seg
	mov	r0,#10		@8-segment pattern off
	mov	r1,#0		@point off
	BL	Display8Segment
	@duration
	mov	r10,#TwoSecond
	BL	Wait
@@@end of S6
@@@start of S7
	@state
	mov	r10,#7		@S7 state #
	BL	DrawState
	@screen
	mov	r10,#4		@S7 screen #
	BL	DrawScreen
	@led
	mov	r0,#BOTH_LED
	swi	SWI_SETLED
	@8-seg (same)
	@duration
	mov	r10,#OneSecond
	BL	Wait
@@@end of S7
@@@check right black button
	swi	SWI_CheckBlack
	cmp	r0, #RIGHT_BLACK_BUTTON
	beq	CarCycleBlack	@stop simulation
@@@Check I3
	swi	SWI_CheckBlue
	and	r0,r0,#0x0f00	@eliminate everything except 8-11
	cmp	r0,#0
	bne	CarCycleI3
@@@if still no ped cycle
	bal	S1C		@go back to S1
CarCycleBlack:
	mov	r4,#0
	bal	CarCycleDone
CarCycleI1:
	mov	r4,#1
	bal	CarCycleDone
CarCycleI3:
	mov	r4,#2
CarCycleDone:
	ldmfd sp!,{r0-r3,r5-r10,pc}

@ === int PedCycle(status r4)
@ inputs: r4 = 1 - coming from I1/I2
@              2 - coming from I3
@ results: r4 = 0 - exit the program
@               1 - I1/I2
@               2 - I3
@ Description: Ped Cycle
PedCycle:
	stmfd sp!,{r0-r3,r5-r10,lr}
	cmp	r4,#2
	beq	P3C
@@@start of P1
	@state
	mov	r10,#11		@P1 state #
	BL	DrawState
	@screen
	mov	r10,#3		@P1 screen #
	BL	DrawScreen
	@8-seg
	mov	r0,#10		@8-segment pattern off
	mov	r1,#0		@point off
	BL	Display8Segment
	@duration
	mov	r10,#500	@half a sec
	mov	r3,#4		@r3 as counter
	@led
	mov	r0,#NO_LED
P1Loop:
	@led
	eor	r0,r0,#BOTH_LED	@change between no led and both led
	swi	SWI_SETLED
	@duration
	BL	Wait
	sub	r3,r3,#1
	cmp	r3,#0
	bne	P1Loop
@@@end of P1
@@@start of P2
	@state
	mov	r10,#12		@P2 state #
	BL	DrawState
	@screen
	mov	r10,#4		@P2 screen #
	BL	DrawScreen
	@led
	mov	r0,#BOTH_LED
	swi	SWI_SETLED
	@8-seg
	mov	r0,#10		@8-segment pattern off
	mov	r1,#0		@point off
	BL	Display8Segment
	@duration
	mov	r10,#OneSecond
	BL	Wait
@@@end of P2
@@@start of P3
P3C:	@state
	mov	r10,#13		@P3 state #
	BL	DrawState
	@screen
	mov	r10,#7		@P3 screen #
	BL	DrawScreen
	@led
	mov	r0,#BOTH_LED
	swi	SWI_SETLED
	@8-seg
	mov	r1,#0		@point off
	BL	Display8Segment
	@duration
	mov	r10,#OneSecond
	mov	r3,#6		@r3 as counter
P3Loop:
	@8-seg
	mov	r0,r3		@8-segment pattern - 6 to 3
	BL	Display8Segment
	@duration (same)
	BL	Wait
	sub	r3,r3,#1
	cmp	r3,#2
	bne	P3Loop
@@@end of P3
@@@start of P4
	@@@0-1s
	@state
	mov	r10,#14		@P4 state #
	BL	DrawState
	@screen
	mov	r10,#8		@P4 screen #
	BL	DrawScreen
	@led (same)
	@8-seg
	mov	r0,#2		@8-segment pattern - 2
	mov	r1,#0		@point off
	BL	Display8Segment
	@duration
	mov	r10,#OneSecond
	BL	Wait
	@@@1-2s
	@state (same)
	@screen (same)
	@led (same)
	@8-seg
	mov	r0,#1		@8-segment pattern - 1
	mov	r1,#0		@point off
	BL	Display8Segment
	@duration (same)
	BL	Wait
@@@end of P4
@@@start of P5
	@state
	mov	r10,#15		@P5 state #
	BL	DrawState
	@screen
	mov	r10,#4		@P5 screen #
	BL	DrawScreen
	@led (same)
	@8-seg
	mov	r0,#0		@8-segment pattern - 0
	mov	r1,#0		@point off
	BL	Display8Segment
	@duration
	mov	r10,#OneSecond
	BL	Wait
@@@end of P5
@@@check right black button
	swi	SWI_CheckBlack
	cmp	r0, #RIGHT_BLACK_BUTTON
	beq	PedCycleBlack	@stop simulation
@@@return to S5
	bal	PedCycleDone
PedCycleBlack:
	mov	r4,#0
PedCycleDone:
	ldmfd sp!,{r0-r3,r5-r10,pc}

@ ==== void Wait(Delay:r10) 
@   Inputs:  R10 = delay in milliseconds
@   Results: none
@   Description:
@      Wait for r10 milliseconds using a 15-bit timer 
Wait:
	stmfd	sp!, {r0-r2,r7-r10,lr}
	ldr     r7, =EmbestTimerMask
	swi     SWI_GetTicks		@get time T1
	and		r1,r0,r7			@T1 in 15 bits
WaitLoop:
	swi SWI_GetTicks			@get time T2
	and		r2,r0,r7			@T2 in 15 bits
	cmp		r2,r1				@ is T2>T1?
	bge		simpletimeW
	sub		r9,r7,r1			@ elapsed TIME= 32,676 - T1
	add		r9,r9,r2			@    + T2
	bal		CheckIntervalW
simpletimeW:
		sub		r9,r2,r1		@ elapsed TIME = T2-T1
CheckIntervalW:
	cmp		r9,r10				@is TIME < desired interval?
	blt		WaitLoop
WaitDone:
	ldmfd	sp!, {r0-r2,r7-r10,pc}	

@ ==== void WaitAndPoll(Delay:r10) 
@   Inputs:  R10 = delay in milliseconds
@   Results: r5 = 0 - nothing happened
@                 1 - the program should stop (right black is pressed)
@                 2 - go to ped cycle (blue is pressed)
@   Description:
@      Wait for r10 milliseconds using a 15-bit timer and check for right black 
@	button at the same time
WaitAndPoll:
	stmfd	sp!, {r0-r2,r7-r10,lr}
	mov	r5,#0				@reset r5
	ldr     r7, =EmbestTimerMask
	swi     SWI_GetTicks			@get time T1
	and	r1,r0,r7			@T1 in 15 bits
WaitAndPollLoop:
	mov	r8,r0				@save r0 to r8
	swi	SWI_CheckBlack			@check right black button
	cmp	r0,#RIGHT_BLACK_BUTTON		
	beq	WaitAndPollBlack
	swi	SWI_CheckBlue
	and	r0,r0,#0x0f00			@eliminate everything except 8-11
	cmp	r0,#0
	bne	WaitAndPollBlue
	mov	r0,r8				@restore r0
	swi	SWI_GetTicks			@get time T2
	and	r2,r0,r7			@T2 in 15 bits
	cmp	r2,r1				@ is T2>T1?
	bge	simpletimeWP
	sub	r9,r7,r1			@ elapsed TIME= 32,676 - T1
	add	r9,r9,r2			@    + T2
	bal	CheckIntervalWP
simpletimeWP:
	sub	r9,r2,r1			@ elapsed TIME = T2-T1
CheckIntervalWP:
	cmp	r9,r10				@is TIME < desired interval?
	blt	WaitAndPollLoop
	bal	WaitAndPollDone
WaitAndPollBlue:
	mov	r5,#2
	bal	WaitAndPollDone
WaitAndPollBlack:
	mov	r5,#1
WaitAndPollDone:
	ldmfd	sp!, {r0-r2,r7-r10,pc}

@ *** void Display8Segment (Number:R0; Point:R1) ***
@   Inputs:  R0=bumber to display; R1=point or no point
@   Results:  none
@   Description:
@ 		Displays the number 0-9 in R0 on the 8-segment
@ 		If R1 = 1, the point is also shown
Display8Segment:
	STMFD 	sp!,{r0-r2,lr}
	ldr 	r2,=Digits
	ldr 	r0,[r2,r0,lsl#2]
	tst 	r1,#0x01 @if r1=1,
	orrne 	r0,r0,#SEG_P 			@then show P
	swi 	SWI_SETSEG8
	LDMFD 	sp!,{r0-r2,pc}
	
@ *** void DrawScreen (PatternType:R10) ***
@   Inputs:  R10: pattern to display according to state
@   Results:  none
@   Description:
@ 		Displays on LCD screen the 5 lines denoting
@		the state of the traffic light
@	Possible displays:
@	1 => S1.1 or S2.1- Green High Street
@	2 => S1.2 or S2.2	- Green blink High Street
@	3 => S3 or P1 - Yellow High Street   
@	4 => S4 or S7 or P2 or P5 - all red
@	5 => S5	- Green Side Road
@	6 => S6 - Yellow Side Road
@	7 => P3 - all pedestrian crossing
@	8 => P4 - all pedestrian hurry
DrawScreen:
	STMFD 	sp!,{r0-r2,lr}
	cmp	r10,#1
	beq	S11
	cmp	r10,#2
	beq	S12
	cmp	r10,#3
	beq	S3
	@more to do
	cmp	r10,#4
	beq	S4
	cmp	r10,#5
	beq	S5
	cmp	r10,#6
	beq	S6
	cmp	r10,#7
	beq	P3
	cmp	r10,#8
	beq	P4
	bal	EndDrawScreen
S11:
	ldr	r2,=line1S11
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S11
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S11
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
S12:
	ldr	r2,=line1S12
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S12
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S12
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
S3:
	ldr	r2,=line1S3
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S3
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S3
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
S4:
	ldr	r2,=line1S4
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S4
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S4
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
S5:
	ldr	r2,=line1S5
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S5
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S5
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
S6:
	ldr	r2,=line1S6
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S6
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S6
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
P3:
	ldr	r2,=line1P3
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3P3
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5P3
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
P4:
	ldr	r2,=line1P4
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3P4
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5P4
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
@ MORE PATTERNS TO BE IMPLEMENTED
EndDrawScreen:
	LDMFD 	sp!,{r0-r2,pc}
	
@ *** void DrawState (PatternType:R10) ***
@   Inputs:  R10: number to display according to state
@   Results:  none
@   Description:
@ 		Displays on LCD screen the state number
@		on top right corner
DrawState:
	STMFD 	sp!,{r0-r2,lr}
	cmp	r10,#1
	beq	S1draw
	cmp	r10,#2
	beq	S2draw
	cmp	r10,#3
	beq	S3draw
	cmp	R10,#4
	beq	S4draw
	cmp	R10,#5
	beq	S5draw
	cmp	R10,#6
	beq	S6draw
	cmp	R10,#7
	beq	S7draw
	cmp	R10,#11
	beq	P1draw
	cmp	R10,#12
	beq	P2draw
	cmp	R10,#13
	beq	P3draw
	cmp	R10,#14
	beq	P4draw
	cmp	R10,#15
	beq	P5draw
	@ MORE TO IMPLEMENT......
	bal	EndDrawScreen
S1draw:
	ldr	r2,=S1label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S2draw:
	ldr	r2,=S2label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S3draw:
	ldr	r2,=S3label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S4draw:
	ldr	r2,=S4label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S5draw:
	ldr	r2,=S5label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S6draw:
	ldr	r2,=S6label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S7draw:
	ldr	r2,=S7label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
P1draw:
	ldr	r2,=P1label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
P2draw:
	ldr	r2,=P2label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
P3draw:
	ldr	r2,=P3label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
P4draw:
	ldr	r2,=P4label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState

P5draw:
	ldr	r2,=P5label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
@ MORE TO IMPLEMENT.....

EndDrawState:
	LDMFD 	sp!,{r0-r2,pc}
	
@@@@@@@@@@@@=========================
	.data
	.align
Digits:							@ for 8-segment display
	.word SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_G 	@0
	.word SEG_B|SEG_C 							@1
	.word SEG_A|SEG_B|SEG_F|SEG_E|SEG_D 		@2
	.word SEG_A|SEG_B|SEG_F|SEG_C|SEG_D 		@3
	.word SEG_G|SEG_F|SEG_B|SEG_C 				@4
	.word SEG_A|SEG_G|SEG_F|SEG_C|SEG_D 		@5
	.word SEG_A|SEG_G|SEG_F|SEG_E|SEG_D|SEG_C 	@6
	.word SEG_A|SEG_B|SEG_C 					@7
	.word SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_F|SEG_G @8
	.word SEG_A|SEG_B|SEG_F|SEG_G|SEG_C 		@9
	.word 0 									@Blank 
	.align
lineID:		.asciz	"Traffic Light -- Siqi Li, V00768565"
@ patterns for all states on LCD
line1S11:		.asciz	"        R W        "
line3S11:		.asciz	"GGG W         GGG W"
line5S11:		.asciz	"        R W        "

line1S12:		.asciz	"        R W        "
line3S12:		.asciz	"  W             W  "
line5S12:		.asciz	"        R W        "

line1S3:		.asciz	"        R W        "
line3S3:		.asciz	"YYY W         YYY W"
line5S3:		.asciz	"        R W        "

line1S4:		.asciz	"        R W        "
line3S4:		.asciz	" R W           R W "
line5S4:		.asciz	"        R W        "

line1S5:		.asciz	"       GGG W       "
line3S5:		.asciz	" R W           R W "
line5S5:		.asciz	"       GGG W       "

line1S6:		.asciz	"       YYY W       "
line3S6:		.asciz	" R W           R W "
line5S6:		.asciz	"       YYY W       "

line1P3:		.asciz	"       R XXX       "
line3P3:		.asciz	"R XXX         R XXX"
line5P3:		.asciz	"       R XXX       "

line1P4:		.asciz	"       R !!!       "
line3P4:		.asciz	"R !!!         R !!!"
line5P4:		.asciz	"       R !!!       "

S1label:		.asciz	"S1"
S2label:		.asciz	"S2"
S3label:		.asciz	"S3"
S4label:		.asciz	"S4"
S5label:		.asciz	"S5"
S6label:		.asciz	"S6"
S7label:		.asciz	"S7"
P1label:		.asciz	"P1"
P2label:		.asciz	"P2"
P3label:		.asciz	"P3"
P4label:		.asciz	"P4"
P5label:		.asciz	"P5"

Goodbye:
	.asciz	"*** Traffic Light program ended ***"

	.end

