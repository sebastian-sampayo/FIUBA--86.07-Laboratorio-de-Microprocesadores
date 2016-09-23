; -------------------------------------------------------------------------------------------------------------------
; El siguiente código aplica un filtro de tipo pasa-bajos cuya ecuación en diferencias
; es la siguiente:
; 							 y(n) = y(n-1)*(N-1)/N  +  x(n) / N
; Uso:
;	x(n):			B
; 	y(n-1): 	A	
;	y(n):			A
;	N:			N_PROMEDIO
; 
; Internamente la operación:   y(n-1)*(N-1)/N   se realiza en 16 bits para obtener
; mejor precisión.
; -------------------------------------------------------------------------------------------------------------------

N_PROMEDIO EQU 5


PUBLIC FILTRAR_LP
PUBLIC AUX1, AUX2

; Division16bits
EXTRN CODE(div16_16)


FILTRO_DATA SEGMENT DATA
RSEG FILTRO_DATA
AUX1: ds 1
AUX2: ds 1

FILTRO_CODE SEGMENT CODE
RSEG FILTRO_CODE


; Macros
; X_H, X_L   =   X_H, X_L  /   Z_H, Z_L
div16 MACRO X_H, X_L, Z_H, Z_L
	mov R1, X_H
	mov R0, X_L
	mov R3, Z_H
	mov R2, Z_L
	call div16_16
	mov X_H, R5
	mov X_L, R4
	ENDM

; Suma de un numero de 16 bits (X = B, A) con otro de 8 bits (Z)
; El resultado se almacena en X (B, A)
; X_H debe ser B
; X_L debe ser A
add16_8 MACRO X_H, X_L, Z
	push AUX2
	clr C
	add A, Z
	mov AUX2, A
	mov A, B
	addc A, #0
	mov B, A
	mov A, AUX2
	pop AUX2
	ENDM
	
	
; y(n) = y(n-1)*(N-1)/N  +  x(n) / N
;  A          A					  	   B
; Algoritmo:
;	(y(n-1)*(N-1) + x(n) ) / N
FILTRAR_LP:
	; Agrego condición de descarte para evitar ciertos errores de truncamiento:
	;	Si x(n) = y(n-1)  => y(n) = y(n-1)
	cjne A, B, MULTIPLICACION
	jmp SALIR
	
	MULTIPLICACION:
	; Multiplico y(n-1) * (N-1)
	; Almaceno B -x(n)- antes de perderlo
	mov AUX1, B
	mov B, #(N_PROMEDIO - 1)
	mul AB

	; Sumo y(n-1)*(N-1) + x(n)
	add16_8 B, A, AUX1   ; Ojo esto puede tener OV (se prende el Carry) en casos límites
	
	; Corrección por truncamiento... Probar si mejora en todos los casos
	mov AUX1, #(N_PROMEDIO / 2)
	add16_8 B, A, AUX1
	
	; Divido por N, en 16 bits
	div16 B, A, #0x00, #N_PROMEDIO ; => B,A = y(n-1)*(N-1)/N
	; (N-1)/N  < 1 => el resultado nunca puede ser mayor que 255.
	; => desecho MSB
	; El resultado ya queda en el Acumulador A.
	

	SALIR:
	ret
	
END



