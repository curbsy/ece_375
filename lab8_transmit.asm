;***********************************************************
;*
;*   ECE 375 Lab 8 TRANSMIT REMOTE
;*	 Author: Makenzie Brian and Scott Merrill
;*	   Date: 11/15/2016
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register

.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit
; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forward Action Code
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backward Action Code
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Action Code
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Action Code
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Action Code

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer 
		LDI		mpr, LOW(RAMEND)
		OUT		SPL, mpr
		LDI		mpr, HIGH(RAMEND)
		OUT		SPH, mpr

		;I/O Ports
		LDI		R16, 0b00001000
		OUT		DDRD, R16
		LDI		R16, 0b11110011	;reciever and transmitter tied together on board
		OUT		PORTD, R16

	;USART1
		;Set baudrate at 2400bps
		LDI		mpr, high(832)			;put value here
		STS		UBRR1H, mpr
		LDI		mpr, low(832)
		STS		UBRR1L, mpr

		;Enable DDR
		LDI		MPR, (1<<U2X1);|(1<<UDRE1)
		STS		UCSR1A, MPR

		;Enable transmitter
		LDI		mpr, (1<<TXEN1)
		STS		UCSR1B, mpr				; enable transmitter interrupt
		
		;Set frame format: 8 data bits, 2 stop bits
		LDI		mpr, (1<<UCSZ10)|(1<<UCSZ11)|(1<<USBS1)
		STS		UCSR1C, mpr


		;Load robo address
		LDI		mpr, 42
		MOV		R1, mpr


;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		;Clear
		ldi		mpr, $FF

		;Turn Right
		in		mpr, PIND
		andi	mpr, 0b11110011
		cpi		mpr, 0b11110010
		breq	TRNL
		ldi		mpr, $FF

		;Turn Left
		in		mpr, PIND
		andi	mpr, 0b11110011
		cpi		mpr, 0b11110001
		breq	TRNR
		ldi		mpr, $FF

		;Don't use 2&3 because UART

		;Go forward
		in		mpr, PIND
		andi	mpr, 0b11110011
		cpi		mpr, 0b11100011
		breq	MOVF
		ldi		mpr, $FF

		;Go back
		in		mpr, PIND
		andi	mpr, 0b11110011
		cpi		mpr, 0b11010011
		breq	MOVB
		ldi		mpr, $FF

		;Freeze
		in		mpr, PIND
		andi	mpr, 0b11110011
		cpi		mpr, 0b10110011
		breq	FRZ
		ldi		mpr, $FF

		;Halt
		in		mpr, PIND
		andi	mpr, 0b11110011
		cpi		mpr, 0b01110011
		breq	STHAWP
		ldi		mpr, $FF

		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
MOVF:
		RCALL	MFCOM
		RJMP	MAIN
MOVB:
		RCALL	MBCOM
		RJMP	MAIN
TRNR:
		RCALL	TRCOM
		RJMP	MAIN
TRNL:
		RCALL	TLCOM
		RJMP	MAIN
STHAWP:
		RCALL	STCOM
		RJMP	MAIN
FRZ:
		RCALL	FZCOM
		RJMP	MAIN

		
MFCOM:
		LDS		mpr, UCSR1A
		SBRS	mpr, 5
		RJMP	MFCOM
		STS		UDR1, R1
MFCM:
		LDS		mpr, UCSR1A
		SBRS	mpr, 5
		RJMP	MFCM
		LDI		mpr, MovFwd
		STS		UDR1, mpr
		LDI		mpr, 255
		OUT		EIFR, mpr

		RET
	
MBCOM:
		LDS		mpr, UCSR1A
		SBRS	mpr, 5
		RJMP	MBCOM
		STS		UDR1, R1
MBCM:
		LDS		mpr, UCSR1A
		SBRS	mpr, 5
		RJMP	MBCM
		LDI		mpr, MovBck
		STS		UDR1, mpr
		LDI		mpr, 255
		OUT		EIFR, mpr

		RET
		
TRCOM:
		LDS		mpr, UCSR1A
		SBRS	mpr, 5
		RJMP	TRCOM
		STS		UDR1, R1
TRCM:
		LDS		mpr, UCSR1A
		SBRS	mpr, 5
		RJMP	TRCM
		LDI		mpr, TurnR
		STS		UDR1, mpr
		LDI		mpr, 255
		OUT		EIFR, mpr

		RET
		
TLCOM:
		LDS		mpr, UCSR1A
		SBRS	mpr, 5
		RJMP	TLCOM
		STS		UDR1, R1
TLCM:
		LDS		mpr, UCSR1A
		SBRS	mpr, 5
		RJMP	TLCM
		LDI		mpr, TurnL
		STS		UDR1, mpr
		LDI		mpr, 255
		OUT		EIFR, mpr

		RET


STCOM:
		LDS		mpr, UCSR1A
		SBRS	mpr, 5
		RJMP	STCOM
		STS		UDR1, R1
STCM:
		LDS		mpr, UCSR1A
		SBRS	mpr, 5
		RJMP	STCM
		LDI		mpr, Halt
		STS		UDR1, mpr
		LDI		mpr, 255
		OUT		EIFR, mpr

		RET

FZCOM:
		LDS		mpr, UCSR1A
		SBRS	mpr, 5
		RJMP	FZCOM
		STS		UDR1, R1
FZCM:
		LDS		mpr, UCSR1A
		SBRS	mpr, 5
		RJMP	FZCM
		LDI		mpr, 0b11111000
		STS		UDR1, mpr
		LDI		mpr, 255
		OUT		EIFR, mpr

		RET


;***********************************************************
;*	Stored Program Data
;***********************************************************


;***********************************************************
;*	Additional Program Includes
;***********************************************************
