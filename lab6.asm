;***********************************************************
;*
;*   ECE 375 Lab 6
;*	 Author: Makenzie Brian and Scotto Merrill
;*	   Date: November 1, 2016
;*
;***********************************************************


.include "m128def.inc"			; Include definition file


;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16						; Multipurpose register 


.def	waitcnt = r17					; Wait Loop Counter
.def	ilcnt = r18						; Inner Loop Counter
.def	olcnt = r19						; Outer Loop Counter


.equ	WTime = 100						; Time to wait in wait loop


.equ	WskrR = 0						; Right Whisker Input Bit
.equ	WskrL = 1						; Left Whisker Input Bit
.equ	EngEnR = 4						; Right Engine Enable Bit
.equ	EngEnL = 7						; Left Engine Enable Bit
.equ	EngDirR = 5						; Right Engine Direction Bit
.equ	EngDirL = 6						; Left Engine Direction Bit


.equ	MovFwd = (1<<EngDirR|1<<EngDirL); Move Forward Command
.equ	MovBck = $00					; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)	; Halt Command




;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment


;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt


		; Set up interrupt vectors for any interrupts being used
.org $0002
		RCALL HitRight
		RETI


.org $0004
		RCALL HitLeft
		RETI


.org	$0046					; End of Interrupt Vectors


;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi		R16, Low(RAMEND) 
		ldi		R17, High(RAMEND)
		OUT		SPL, R16
		OUT		SPH, R17


		; Initialize Port B for output
		ldi		R16, 255
		OUT		DDRB, R16
		ldi		R16, 0
		OUT		PORTB, R16


		; Initialize Port D for input


		ldi		R16, 0
		OUT		DDRD, R16
		ldi		R16, 255
		OUT		PORTD, R16


		; Initialize external interrupts
		; Set the Interrupt Sense Control to falling edge 
		
		ldi		R16, 0b00001010
		STS		EICRA, R16


		; Configure the External Interrupt Mask
		ldi		R16, 0b00000011
		OUT		EIMSK, R16


		; Turn on interrupts
			; NOTE: This must be the last thing to do in the INIT function
		SEI


;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program


		ldi		mpr, MovFwd		; Load Move Forward command
		out		PORTB, mpr		; Send command to port


		rjmp	MAIN			; Create an infinite while loop to signify the 
								; end of the program.


;***********************************************************
;*	Functions and Subroutines
;***********************************************************


;-----------------------------------------------------------
;	You will probably want several functions, one to handle the 
;	left whisker interrupt, one to handle the right whisker 
;	interrupt, and maybe a wait function
;------------------------------------------------------------


;----------------------------------------------------------------
; Sub:	HitRight
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
HitRight:


		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr				;


		ldi		R16, 0b00000000
		OUT		EIMSK, R16


		; Move Backwards for a second
		ldi		mpr, MovBck		; Load Move Backward command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function


		; Turn left for a second
		ldi		mpr, TurnL		; Load Turn Left Command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function


		; Move Forward again	
		ldi		mpr, MovFwd		; Load Move Forward command
		out		PORTB, mpr		; Send command to port


		ldi		R16, 255
		OUT		EIFR, R16
		ldi		R16, 0b00000011
		OUT		EIMSK, R16


		pop		mpr				; Restore program state
		out		SREG, mpr		;
		pop		waitcnt			; Restore wait register
		pop		mpr				; Restore mpr
		ret						; Return from subroutine


;----------------------------------------------------------------
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr				;


		ldi		R16, 0b00000000
		OUT		EIMSK, R16


		; Move Backwards for a second
		ldi		mpr, MovBck		; Load Move Backward command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function


		; Turn right for a second
		ldi		mpr, TurnR		; Load Turn Left Command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function


		; Move Forward again	
		ldi		mpr, MovFwd		; Load Move Forward command
		out		PORTB, mpr		; Send command to port


		ldi		R16, 255
		OUT		EIFR, R16
		ldi		R16, 0b00000011
		OUT		EIMSK, R16


		pop		mpr				; Restore program state
		out		SREG, mpr		;
		pop		waitcnt			; Restore wait register
		pop		mpr				; Restore mpr
		ret						; Return from subroutine


;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register


Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt			; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt			; Decrement wait 
		brne	Loop			; Continue Wait loop	


		pop		olcnt			; Restore olcnt register
		pop		ilcnt			; Restore ilcnt register
		pop		waitcnt			; Restore wait register
		ret						; Return from subroutine


;***********************************************************
;*	Stored Program Data
;***********************************************************


; Enter any stored data you might need here


;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program

