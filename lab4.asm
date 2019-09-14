;***********************************************************
;*
;*   ECE 375 Lab 4
;*	 Author: Makenzie Brian and Scott Merrill
;*	   Date: October 18, 2016
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is
								; required for LCD Driver
.def	counter = r23
.equ	limit = 12

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		LDI		R16, LOW(RAMEND)  ; Low byte of End SRAM Address
		OUT		SPL, R16          ; Write byte to SPL
		LDI		R16, HIGH(RAMEND) ; High byte of End SRAM Address
		OUT		SPH, R16          ; Write byte to SPH
		
		; Initialize LCD Display
		rcall	LCDInit				; Initialize LCD peripheral interface

		; Move strings from Program Memory to Data Memory
		LDI		ZL, LOW(STRING_BEG<<1)    ;
		LDI		ZH, HIGH(STRING_BEG<<1)   ;
		clr counter
		LDI XL, 0x00					; initialize to first line of LCD
		LDI XH, 0x01

		WHIL: cpi	counter, limit		; compare counter with limit
			brsh	NEXT				; when not counter<limit, goto NEXT
			LPM		R0, Z+
			ST		X+, R0
			inc		counter				; increment counter
			rjmp	WHIL

		NEXT:
			clr		counter
			LDI		XL, 0x10				; initialized to second line of LCD
			LDI		XH, 0x01
			LDI		ZL, LOW(STRING_END<<1)    ;
			LDI		ZH, HIGH(STRING_END<<1)   ;
			rjmp	WHIL2

		WHIL2:cpi	counter, limit		; compare counter with limit
			brsh	MAIN				; when not counter<limit, goto NEX
			LPM		R0, Z+
			ST		X+, R0
			inc	counter					; increment counter
			rjmp	WHIL2


		; NOTE that there is no RET or RJMP from INIT, this
		; is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		; Display the strings on the LCD Display
		rcall	LCDWrite		; write to both line of LCD

		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variables by pushing them to the stack

		; Execute the function here
		
		; Restore variables by popping them from the stack,
		; in reverse order

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING_BEG:
.DB		"Kenzie Scott"		; Declaring data in ProgMem
STRING_END:
.DB		"Hello World "		; Declaring data in ProgMem 
;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

