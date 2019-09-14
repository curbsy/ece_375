;***********************************************************
;*
;*   ECE 375 Lab 5
;*	 Author: Makenzie Brian and Scotto Merrill
;*	   Date: October 25, 2016
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; A variable
.def	B = r4					; Another variable
.def	C = r5					; For extra carries

.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:							; The initialization routine
		; Initialize Stack Pointer
								; Init the 2 stack pointer registers
		LDI		R16, LOW(RAMEND);
		OUT		SPL, R16
		LDI		R16, HIGH(RAMEND)
		OUT		SPH, R16

		clr		zero			; Set the zero register to zero, maintain
								; these semantics, meaning, don't load anything
								; to it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program
		; Setup the ADD16 function direct test
		LDI		ZL, LOW(ADD16T<<1)
		LDI		ZH, HIGH(ADD16T<<1)
		LPM		R17, Z+
		LPM		R18, Z+
		LPM		R19, Z+
		LPM		R20, Z
		LDI		XL, LOW(addrA)
		LDI		XH, HIGH(addrA)
		ST		X+, R17
		ST		X+, R18
		ST		X+,	R19
		ST		X, R20
				; (IN SIMULATOR) Enter values 0xA2FF and 0xF477 into data
				; memory locations where ADD16 will get its inputs from

				; Call ADD16 function to test its correctness
				; (calculate A2FF + F477)
		LDI		ZL, LOW(ADD16)
		LDI		ZH, HIGH(ADD16)
		ICALL
				; Observe result in Memory window

		; Setup the SUB16 function direct test
		LDI		ZL, LOW(SUB16T<<1)
		LDI		ZH, HIGH(SUB16T<<1)
		LPM		R17, Z+
		LPM		R18, Z+
		LPM		R19, Z+
		LPM		R20, Z
		LDI		XL, LOW(addrA)
		LDI		XH, HIGH(addrA)
		ST		X+, R17
		ST		X+, R18
		ST		X+,	R19
		ST		X, R20
				; (IN SIMULATOR) Enter values 0xF08A and 0x4BCD into data
				; memory locations where SUB16 will get its inputs from

				; Call SUB16 function to test its correctness
				; (calculate F08A - 4BCD)
		LDI		ZL, LOW(SUB16)
		LDI		ZH, HIGH(SUB16)
		ICALL
				; Observe result in Memory window

		; Setup the MUL24 function direct test
		LDI		ZL, LOW(MUL24T<<1)
		LDI		ZH, HIGH(MUL24T<<1)
		LPM		R17, Z+
		LPM		R18, Z+
		LPM		R19, Z+
		LPM		R20, Z+
		LPM		R21, Z+
		LPM		R22, Z

		LDI		ZL, LOW(0x114)
		LDI		ZH, HIGH(0x114)
		ST		Z+, R17
		ST		Z+, R18
		ST		Z+,	R19
		ST		Z+, R20
		ST		Z+,	R21
		ST		Z, R22
				; (IN SIMULATOR) Enter values 0xFFFFFF and 0xFFFFFF into data
				; memory locations where MUL24 will get its inputs from

				; Call MUL24 function to test its correctness
				; (calculate FFFFFF * FFFFFF)
		LDI		ZL, LOW(MUL24)
		LDI		ZH, HIGH(MUL24)
		ICALL
				; Observe result in Memory window

		; Call the COMPOUND function

		LDI		ZL, LOW(COMPOUND)
		LDI		ZH, HIGH(COMPOUND)
		ICALL
				; Observe final result in Memory window

DONE:	rjmp	DONE			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;		where the high byte of the result contains the carry
;		out bit.
;-----------------------------------------------------------
ADD16:
		; Save variable by pushing them to the stack
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Execute the function here
		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		LDI		XL, LOW(addrA)
		LDI		XH, HIGH(addrA)

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(ADDRADDR)	; Load low byte
		ldi		ZH, high(ADDRADDR)  ; Load high byte
		
		LD		A, X+
		LD		B, Y+

		ADD		A, B
		ST		Z+, A

		LD		A, X
		LD		B, Y

		ADC		A, B
		ST		Z+, A
		CLR		A
		ADC		A, zero
		ST		Z+, A

		; Restore variable by popping them from the stack in reverse order
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: SUB16
; Desc: Subtracts two 16-bit numbers and generates a 16-bit
;		result.
;-----------------------------------------------------------
SUB16:
		; Save variable by pushing them to the stack
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Execute the function here
		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		LDI		XL, LOW(addrA)
		LDI		XH, HIGH(addrA)

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(SUBRADDR)	; Load low byte
		ldi		ZH, high(SUBRADDR); Load high byte		

		LD		A, X+
		LD		B, Y+

		SUB		A, B
		ST		Z+, A

		LD		A, X
		LD		B, Y

		SBC		A, B
		ST		Z, A

		; Restore variable by popping them from the stack in reverse order
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET



;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit 
;		result.
;-----------------------------------------------------------
MUL24:
		; Save variable by pushing them to the stack
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(0x117)	; Load low byte
		ldi		YH, high(0x117)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(L24ADDRP)	; Load low byte
		ldi		ZH, high(L24ADDRP); Load high byte

		; Begin outer for loop
		ldi		oloop, 3		; Load counter
MUL24_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(0x114)	; Load low byte
		ldi		XH, high(0x114)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 3		; Load counter
MUL24_ILOOP:
		clr		C
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A, B			; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		ld		C, Z
		adc		C, zero
		st		Z, C			; Store third byte to memory
		st		-Z, A			; Store 4th byte
		st		-Z, hi			; Store second byte to memory
		st		-Z, rlo			; Store third byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1			
		dec		iloop			; Decrement counter
		brne	MUL24_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		sbiw	ZH:ZL, 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL24_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		; Restore variable by popping them from the stack in reverse order 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET
		; Execute the function here
		

;-----------------------------------------------------------
; Func: COMPOUND
; Desc: Computes the compound expression ((D - E) + F)^2
;		by making use of SUB16, ADD16, and MUL24.
;
;		D, B, and F are declared in program memory, and must
;		be moved into data memory for use as input operands
;
;		All result bytes should be cleared before beginning.
;-----------------------------------------------------------
COMPOUND:
		; Save variable by pushing them to the stack
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics
		; Execute the function here
		LDI		ZL, LOW(OperandD<<1)
		LDI		ZH, HIGH(OperandD<<1)
		LPM		R17, Z+
		LPM		R18, Z
		LDI		XL, LOW(addrA)
		LDI		XH, HIGH(addrA)
		ST		X+, R17
		ST		X, R18
		LDI		ZL, LOW(OperandE<<1)
		LDI		ZH, HIGH(OperandE<<1)
		LPM		R17, Z+
		LPM		R18, Z
		LDI		XL, LOW(addrB)
		LDI		XH, HIGH(addrB)
		ST		X+, R17
		ST		X, R18
		LDI		ZL, LOW(SUB16)
		LDI		ZH, HIGH(SUB16)
		ICALL
		LDI		ZL, LOW(SUBRADDR)
		LDI		ZH, HIGH(SUBRADDR)
		LD		R17, Z+
		LD		R18, Z
		LDI		XL, LOW(addrA)
		LDI		XH, HIGH(addrA)
		ST		X+, R17
		ST		X, R18
		LDI		ZL, LOW(OperandF<<1)
		LDI		ZH, HIGH(OperandF<<1)
		LPM		R17, Z+
		LPM		R18, Z
		LDI		XL, LOW(addrB)
		LDI		XH, HIGH(addrB)
		ST		X+, R17
		ST		X, R18
		LDI		ZL, LOW(ADD16)
		LDI		ZH, HIGH(ADD16)
		ICALL
		LDI		ZL, LOW(ADDRADDR)
		LDI		ZH, HIGH(ADDRADDR)
		LD		R17, Z+
		LD		R18, Z+
		LD		R19, Z
		LDI		ZL, LOW(0x114)
		LDI		ZH, HIGH(0x114)
		ST		Z+, R17
		ST		Z+, R18
		ST		Z, R19
		LDI		ZL, LOW(0x117)
		LDI		ZH, HIGH(0x117)
		ST		Z+, R17
		ST		Z+, R18
		ST		Z, R19
		LDI		ZL, LOW(MUL24)
		LDI		ZH,	HIGH(MUL24)
		ICALL
		; Restore variable by popping them from the stack in reverse order
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;			A - Operand A is gathered from address $0101:$0100
;			B - Operand B is gathered from address $0103:$0102
;			Res - Result is stored in address 
;					$0107:$0106:$0105:$0104
;		You will need to make sure that Res is cleared before
;		calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter
MUL16_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A, B			; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store third byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1			
		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variable by pushing them to the stack

		; Execute the function here
		
		; Restore variable by popping them from the stack in reverse order\
		ret						; End a function with RET


;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

ADD16T:
	.DB	0xFF, 0xA2, 0x77, 0xF4 ; Test values for ADD16 (A B)
SUB16T: .DB 0x8A, 0xF0, 0xCD, 0x4B ; Test values for SUB16 (A B First - Second)
MUL24T:
	.DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF ; Test values for MUL24
OperandD:
	.DB	0x51, 0xFD			; test value for operand D
OperandE:
	.DB	0xFF, 0x1E			; test value for operand E
OperandF:
	.DB	0xFF, 0xFF			; test value for operand F

.dseg
.org	$0100
addrA:	.byte 2
addrB:	.byte 2
LAddrP:	.byte 3
ADDRADDR: .BYTE 3
SUBRADDR: .BYTE 2
L24ADDRP: .BYTE 6



;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program


