;***********************************************************
;*
;*   ECE 375 Lab 8 RECIEVE BOT
;*	 Author: Makenzie Brian and Scotto Merrills
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	PSTATE = R18
.def	waitcnt = r17					; Wait Loop Counter

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Action Code

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0002
		RCALL	TRNRI
		RETI
		RCALL	TRNLI
		RETI

.org	$003C
		RCALL	RECI
		RETI

;Should have Interrupt vectors for:
;- Left whisker
;- Right whisker
;- USART receive

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	; Initialize Stack Pointer
		ldi		R16, Low(RAMEND) 
		ldi		R17, High(RAMEND)
		OUT		SPL, R16
		OUT		SPH, R17

		; Initialize Port B for output
		ldi		R16, 255
		OUT		DDRB, R16
		ldi		R16, MOVFWD
		OUT		PORTB, R16

		; Initialize Port D for input

		ldi		R16, 0
		OUT		DDRD, R16
		ldi		R16, 0b11110011
		OUT		PORTD, R16

	;USART1
		;Set baudrate at 2400bps
		LDI		mpr, high(832)			;put value here
		STS		UBRR1H, mpr
		LDI		mpr, low(832)
		STS		UBRR1L, mpr

		;Set double data rate
		ldi		mpr, (1<<U2X1)
		sts		UCSR1A, mpr

		;Enable receiver and enable receive interrupts
		LDI		mpr, (1<<RXEN1)|(1<<RXCIE1)|(1<<TXEN1)
		STS		UCSR1B, mpr				; enable Reciever interrupt

		;Set frame format: 8 data bits, 2 stop bits
		LDI		mpr, (1<<UCSZ10)|(1<<UCSZ11)|(1<<USBS1)
		STS		UCSR1C, mpr

	;External Interrupts
		;Configure External Interrupts, if needed
		LDI		R16, 0b00001010
		STS		EICRA, R16

		;Configure the External Interrupt Mask
		LDI		R16, 0b00000011
		OUT		EIMSK, R16

		;Load robo address
		LDI		MPR, 42
		MOV		R1, MPR

	;Set up TCNT1
		LDI		MPR, 0b00000000
		OUT		TCCR1A, MPR
		LDI		MPR, 0b00000100
		OUT		TCCR1B, MPR

	;Set FRZCNT to 0
		LDI		MPR, 0
		STS		FRZCNT, MPR
	;Other
		SEI

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;----------------------------------------------------------------
; Sub:	HitRight
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
TRNRI:

		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr				;

		ldi		R16, 0b00000000
		OUT		EIMSK, R16

		; Get the current motor state
		IN		PSTATE, PINB
		; Move Backwards for a second
		ldi		mpr, MovBck		; Load Move Backward command
		out		PORTB, mpr		; Send command to port
		LDI		MPR, LOW(3035)
		OUT		TCNT1L, MPR
		LDI		MPR, HIGH(3035)
		OUT		TCNT1H, MPR
		LDI		MPR, 255
		OUT		TIFR, MPR
RTWAIT1:		
		IN		MPR, TIFR
		SBRS	MPR, 2
		RJMP	RTWAIT1

		; Turn left for a second
		ldi		mpr, TurnL		; Load Turn Left Command
		out		PORTB, mpr		; Send command to port
		LDI		MPR, LOW(3035)
		OUT		TCNT1L, MPR
		LDI		MPR, HIGH(3035)
		OUT		TCNT1H, MPR
		LDI		MPR, 255
		OUT		TIFR, MPR
RTWAIT2:		
		IN		MPR, TIFR
		SBRS	MPR, 2
		RJMP	RTWAIT2

		; Return to previous motor state
		out		PORTB, PSTATE		; Send command to port
		LDS		MPR, UDR1
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
TRNLI:
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr				;

		ldi		R16, 0b00000000
		OUT		EIMSK, R16

		; Get the current motor state
		IN		PSTATE, PINB
		; Move Backwards for a second
		ldi		mpr, MovBck		; Load Move Backward command
		out		PORTB, mpr		; Send command to port
		LDI		MPR, LOW(3035)
		OUT		TCNT1L, MPR
		LDI		MPR, HIGH(3035)
		OUT		TCNT1H, MPR
		LDI		MPR, 255
		OUT		TIFR, MPR
LTWAIT1:		
		IN		MPR, TIFR
		SBRS	MPR, 2
		RJMP	LTWAIT1

		; Turn right for a second
		ldi		mpr, TurnR		; Load Turn Left Command
		out		PORTB, mpr		; Send command to port
		LDI		MPR, LOW(3035)
		OUT		TCNT1L, MPR
		LDI		MPR, HIGH(3035)
		OUT		TCNT1H, MPR
		LDI		MPR, 255
		OUT		TIFR, MPR
LTWAIT2:		
		IN		MPR, TIFR
		SBRS	MPR, 2
		RJMP	LTWAIT2			; Call wait function

		; Return to previous motor state
		out		PORTB, PSTATE		; Send command to port
		LDS		MPR, UDR1
		ldi		R16, 255
		OUT		EIFR, R16
		ldi		R16, 0b00000011
		OUT		EIMSK, R16

		pop		mpr				; Restore program state
		out		SREG, mpr		;
		pop		waitcnt			; Restore wait register
		pop		mpr				; Restore mpr
		ret						; Return from subroutine 
RECI:
		PUSH	MPR
		PUSH	WAITCNT
		LDS		MPR, UDR1
		CP		MPR, R1
		BREQ	GETCMD
		CPI		MPR, 0b01010101
		BREQ	FRZ
RETRECI:
		LDI		MPR, 255
		OUT		EIFR, MPR

		POP		WAITCNT
		POP		MPR
		RET

GETCMD:
		LDS		MPR, UCSR1A
		SBRS	MPR, 7
		RJMP	GETCMD
		LDS		MPR, UDR1
		SBRS	MPR, 7
		RJMP	RETRECI
		CPI		MPR, 0b10110000
		BREQ	FWD
		CPI		MPR, 0b10000000
		BREQ	BCK
		CPI		MPR, 0b10100000
		BREQ	TRNR
		CPI		MPR, 0b10010000
		BREQ	TRNL
		CPI		MPR, 0b11001000
		BREQ	STHAWP
		CPI		MPR, 0b11111000
		BREQ	FRZCMD
		RJMP	RETRECI

FWD:
		LDI		MPR, MOVFWD
		OUT		PORTB, mpr
		RJMP	RETRECI

BCK:
		LDI		MPR, MOVBCK
		OUT		PORTB, mpr
		RJMP	RETRECI

TRNR:
		LDI		MPR, TURNR
		OUT		PORTB, mpr
		RJMP	RETRECI

TRNL:
		LDI		MPR, TURNL
		OUT		PORTB, mpr
		RJMP	RETRECI

STHAWP:
		LDI		MPR, HALT
		OUT		PORTB, mpr
		RJMP	RETRECI

FRZCMD:
		LDI		MPR, 0b01010101
		STS		UDR1, MPR
CHECK:
		LDS		MPR, UCSR1A
		SBRS	MPR, RXC1
		RJMP	CHECK
		LDS		MPR, UDR1
		RJMP	RETRECI

FRZ:
		IN		PSTATE, PINB
		LDI		MPR, HALT
		OUT		PORTB, mpr
		LDS		MPR, FRZCNT
		INC		MPR
		CPI		MPR, 3
		BREQ	DED
		STS		FRZCNT, MPR
		LDI		WAITCNT, 0
LOAD:
		LDI		MPR, 255
		OUT		TIFR, MPR
		LDI		MPR, LOW(3035)
		OUT		TCNT1L, MPR
		LDI		MPR, HIGH(3035)
		OUT		TCNT1H, MPR
WAIT:
		IN		MPR, TIFR
		SBRS	MPR, 2
		RJMP	WAIT
		INC     WAITCNT
		CPI		WAITCNT, 5
		BREQ	RETRETRECI
		RJMP	LOAD

RETRETRECI:
		OUT		PORTB, PSTATE
		RJMP	RETRECI
DED: 
		RJMP	DED


;***********************************************************
;*	Stored Program Data
;***********************************************************

.dseg
.org	0x0100
FRZCNT:	.BYTE	1

;***********************************************************
;*	Additional Program Includes
;***********************************************************
