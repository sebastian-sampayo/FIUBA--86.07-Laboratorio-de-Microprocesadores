; -------------------------------------------------------------------------------------------------------------------
; El siguiente código realiza la operación de división para número de 16 bits (2 bytes)
; devolviendo el cociente en 16 bits (2 bytes).
; Uso:
;						MSB	LSB
; 	Dividendo: 	  R1		 R0
; 	Divisor:	 	  R3		 R2
; 	Resultado: 	  R5		 R4
; Tanto el algoritmo como el código fueron encontrados en www.8052.com/div16
; -------------------------------------------------------------------------------------------------------------------

PUBLIC div16_16

DIVISION16_CODE SEGMENT CODE
RSEG DIVISION16_CODE

div16_16:
  CLR C       ;Clear carry initially
  MOV R4,#00h ;Clear R4 working variable initially
  MOV R5,#00h ;CLear R5 working variable initially
  MOV B,#00h  ;Clear B since B will count the number of left-shifted bits
div1:
  INC B      ;Increment counter for each left shift
  MOV A,R2   ;Move the current divisor low byte into the accumulator
  RLC A      ;Shift low-byte left, rotate through carry to apply highest bit to high-byte
  MOV R2,A   ;Save the updated divisor low-byte
  MOV A,R3   ;Move the current divisor high byte into the accumulator
  RLC A      ;Shift high-byte left high, rotating in carry from low-byte
  MOV R3,A   ;Save the updated divisor high-byte
  JNC div1   ;Repeat until carry flag is set from high-byte
div2:        ;Shift right the divisor
  MOV A,R3   ;Move high-byte of divisor into accumulator
  RRC A      ;Rotate high-byte of divisor right and into carry
  MOV R3,A   ;Save updated value of high-byte of divisor
  MOV A,R2   ;Move low-byte of divisor into accumulator
  RRC A      ;Rotate low-byte of divisor right, with carry from high-byte
  MOV R2,A   ;Save updated value of low-byte of divisor
  CLR C      ;Clear carry, we don't need it anymore
  MOV 07h,R1 ;Make a safe copy of the dividend high-byte
  MOV 06h,R0 ;Make a safe copy of the dividend low-byte
  MOV A,R0   ;Move low-byte of dividend into accumulator
  SUBB A,R2  ;Dividend - shifted divisor = result bit (no factor, only 0 or 1)
  MOV R0,A   ;Save updated dividend 
  MOV A,R1   ;Move high-byte of dividend into accumulator
  SUBB A,R3  ;Subtract high-byte of divisor (all together 16-bit substraction)
  MOV R1,A   ;Save updated high-byte back in high-byte of divisor
  JNC div3   ;If carry flag is NOT set, result is 1
  MOV R1,07h ;Otherwise result is 0, save copy of divisor to undo subtraction
  MOV R0,06h
div3:
  CPL C      ;Invert carry, so it can be directly copied into result
  MOV A,R4 
  RLC A      ;Shift carry flag into temporary result
  MOV R4,A   
  MOV A,R5
  RLC A
  MOV R5,A		
  DJNZ B,div2 ;Now count backwards and repeat until "B" is zero
  MOV R3,05h  ;Move result to R3/R2
  MOV R2,04h  ;Move result to R3/R2
  RET
  
END