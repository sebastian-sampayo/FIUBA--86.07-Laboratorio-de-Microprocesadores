;Control de velocidades

;el valor devuelto por la función (ACEL_SAL) corresponde al resultado de la
;función partida.
;f(x)= x/pend_1 		si x<margen_1  
;	   x/pend_2+cte		si margen_1< x<margen_2 
;	   x/pend_3+cte2 	si margen_2<x<margen_3 ac_max si x>margen_3

;La función verifica entre que margenes esta la aceleración medida y en 
;base a eso utiliza la función de una recta en especial
;la aceleración medida se multiplica por la pendiente (se divide por la 
;pendiente inversa) y se le suma la ordenada al origen.

;la ordenada al origen se calcula de la siguiente forma:
;suponiendo una recta que pasa por (x1,y1) con pendiente "a" la ordenada al
;origen esta dada por b=y1-a*x1

PUBLIC ADECUAR_ACELERACION

EXTRN DATA(ACELERACION_POSITIVA_X, ACELERACION_POSITIVA_Y)
EXTRN DATA(ACELERACION_NEGATIVA_X, ACELERACION_NEGATIVA_Y)

;constantes
PEND_1 EQU 2
PEND_2 EQU 4
PEND_3 EQU 5
MARGEN_1 EQU 20
MARGEN_2 EQU 60
MARGEN_3 EQU 85
MAX_AC EQU 25

;Macros
check_margen MACRO X, MIN, MAX, FLAG
LOCAL FLAG_OFF, FLAG_ON, SALIR
	push ACC
	mov A, #MAX
	clr C
	cjne A, X, $+3
	jc FLAG_OFF
	mov A, X
	clr C
	cjne A, #MIN, $+3
	jc FLAG_OFF
	FLAG_ON:
		setb FLAG
		jmp SALIR
	FLAG_OFF:   ; si X >= MAX  o X <= MIN
		clr FLAG
	SALIR:
		pop ACC
	ENDM

;Variables

CHECK_ACELERACION_DATA SEGMENT DATA
RSEG CHECK_ACELERACION_DATA
ACEL_SAL: ds 1
ACEL_MED: ds 1

CHECK_ACELERACION_BIT SEGMENT BIT
RSEG CHECK_ACELERACION_BIT
FLAG: dbit 1

CHECK_ACELERACION_CODE SEGMENT CODE
RSEG CHECK_ACELERACION_CODE


ADECUAR_ACELERACION:
	mov ACEL_MED, ACELERACION_POSITIVA_X
	call CHECK_ACELERACION
	mov ACEL_MED, ACELERACION_POSITIVA_Y
	call CHECK_ACELERACION
	mov ACEL_MED, ACELERACION_NEGATIVA_X
	call CHECK_ACELERACION
	mov ACEL_MED, ACELERACION_NEGATIVA_Y
	call CHECK_ACELERACION
	ret


CHECK_ACELERACION:
		;Guardo en stack los calores de A y de B
		PUSH ACC	
		PUSH B
		;Verifica si esta antes que el margen_1
		check_margen ACEL_MED, 0, MARGEN_1, FLAG
		;Divide la medición por la pendiente.
		;La ordenada al origen es 0
		JNB FLAG, NO_M1
		MOV B,#PEND_1
		MOV A,ACEL_MED
		DIV AB
		MOV ACEL_SAL,A
		JMP SALIR
		
		;Verifica si esta antes del margen_2
NO_M1:	check_margen ACEL_MED, MARGEN_1,MARGEN_2,FLAG
		JNB FLAG , NO_M2
		;Si esta entre el margen 1 y 2
		MOV B, #PEND_2						 
		MOV A, ACEL_MED
		
		;Divido por la pendiente inversa
		DIV AB    									
		MOV ACEL_SAL,A								
		;Calculo la ordenada al origen y la sumo
		;Para que la función sea continua, la segunda recta debe pasar por
		;el punto (MARGEN_1,PEND_1*mARGEN_1)
		MOV A,#((MARGEN_1/PEND_1)-(MARGEN_1/PEND_2))	
		ADD A, ACEL_SAL
		MOV ACEL_SAL,A 
		JMP SALIR
		
		;Verifica que este antes del margen_3
NO_M2:	check_margen ACEL_MED, MARGEN_2, MARGEN_3, FLAG
		;Divido por la pendiente
		JNB FLAG ,NO_M3
		MOV B, #PEND_3						
		MOV A, ACEL_MED
		DIV AB
		MOV ACEL_SAL,A
				
		;Calculo la ordenada al origen. La recta tiene que pasar por el punto 
		;(MARGEN_2 , MARGEN_2*PEND_2+((PEND_1*MARGEN_1)-(PEND_2*MARGEN_1))
		MOV A, #(MARGEN_2/PEND_2+((MARGEN_1/PEND_1)-(MARGEN_1/PEND_2))-MARGEN_2/PEND_3)											
		
		;Sumo la ordenada al origen
		ADD A, ACEL_SAL
		MOV ACEL_SAL,A 
		JMP SALIR
		
NO_M3:   MOV ACEL_SAL, #MAX_AC		
		
SALIR:
		;Devuelvo los valores originales de A y B
		POP B
		POP ACC
		mov ACEL_MED, ACEL_SAL
		RET
		
END
