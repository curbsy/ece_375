;***********************************************************
;*
;*   ECE 375 Lab 7
;*	 Author: Makenzie Brian and Scott Merrill
;*	   Date: 11/8/2016
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	MPR2 = R17

.equ	EngEnR = 4				; right Engine Enable Bit
.equ	EngEnL = 7				; left Engine Enable Bit
.equ	EngDirR = 5				; right Engine Direction Bit
.equ	EngDirL = 6				; left Engine Direction Bit

.equ	MovFwd = (1<<EngDirR|1<<EngDirL); Move Forward Command
.equ	MovBck = $00					; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)	; Halt Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

		; place instructions in interrupt vectors here, if needed
.org	0x0002
		RJMP	SPDUP
		RETI
		RJMP	SPDDN
		RETI
		RJMP	SPDMX
		RETI
		RJMP	SPDMN
		RETI

.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		LDI		mpr, LOW(RAMEND)
		OUT		SPL, mpr
		LDI		mpr, HIGH(RAMEND)
		OUT		SPH, mpr
		
		; Configure I/O ports
		LDI		R16, 255
		OUT		DDRB, R16
		LDI		R16, 0
		OUT		PORTB, R16

		LDI		R16, 0
		OUT		DDRD, R16
		LDI		R16, 255
		OUT		PORTD, R16

		; Configure External Interrupts, if needed
		LDI		R16, 0b10101010
		STS		EICRA, R16

		; Configure the External Interrupt Mask
		LDI		R16, 0b00001111
		OUT		EIMSK, R16

		; Configure 8-bit Timer/Counters
		LDI		MPR, (1<<3|1<<6|1<<4|1<<5|1<<0)
		OUT		TCCR0, MPR		
		LDI		MPR, (1<<3|1<<6|1<<4|1<<5|1<<0)
		OUT		TCCR2, MPR
								; no prescaling

		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL)
		LDI		MPR, MovFwd
		OUT		PORTB, MPR

		; Set initial speed, display on Port B pins 3:0
		LDI		MPR, 0
		STS		SPD, MPR
		STS		LED, MPR
		OUT		OCR0, MPR
		OUT		OCR2, MPR

		; Enable global interrupts (if any are used)
		SEI

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:

								; if pressed, adjust speed
								; also, adjust speed indication

		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:	; Begin a function with a label

		; If needed, save variables by pushing to the stack

		; Execute the function here
		
		; Restore any saved variables by popping from stack

		ret						; End a function with RET

SPDUP:
		PUSH	MPR
		PUSH	MPR2
		LDS		MPR, SPD
		LDS		MPR2, LED
		CPI		MPR, 255
		BREQ	UPDATE
		SUBI	MPR, -17
		INC		MPR2
		RJMP	UPDATE
SPDDN:
		PUSH	MPR
		PUSH	MPR2
		LDS		MPR, SPD
		LDS		MPR2, LED
		CPI		MPR, 0
		BREQ	UPDATE
		SUBI	MPR, 17
		DEC		MPR2
		RJMP	UPDATE
UPDATE:	
		STS		SPD, MPR
		STS		LED, MPR2
		OUT		OCR0, MPR
		OUT		OCR2, MPR
		LDI		MPR, 0xFF
		EOR		MPR2, MPR
		OUT		PORTB, MPR2
		LDI		MPR, 255
		OUT		EIFR, MPR
		POP		MPR2
		POP		MPR
		RETI

SPDMX:
		PUSH	MPR
		PUSH	MPR2
		LDI		MPR, 255
		LDI		MPR2, 15
		RJMP	UPDATE

SPDMN:
		PUSH	MPR
		PUSH	MPR2
		LDI		MPR, 0
		LDI		MPR2, 0
		RJMP	UPDATE
;***********************************************************
;*	Stored Program Data
;***********************************************************
.dseg
.org	0x0100 
SPD:	.BYTE	1
LED:	.BYTE	1

;***********************************************************
;*	Additional Program Includes
;***********************************************************
