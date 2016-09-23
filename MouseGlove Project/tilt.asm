; -------------------------------------------------------------------------------------------------------------------
; 				Facultad de Ingeniería de la Universidad de Buenos Aires
;
; Materia: 	Laboratorio de Microcomputadoras
; Año: 			2° cuatrimestre 2013
; Alumnos: 	Fosco, Camilo
;				  	Sampayo, Sebastián
;				  	Schiffmacher, Christian
;
; Módulo principal
; 	Inicializaciones, manejo de interrupciones funciones de alto nivel en general.
; -------------------------------------------------------------------------------------------------------------------

PUBLIC MEDICION_X, MEDICION_Y, X_FILTRADA, Y_FILTRADA
PUBLIC ACELERACION_POSITIVA_X, ACELERACION_POSITIVA_Y
PUBLIC ACELERACION_NEGATIVA_X, ACELERACION_NEGATIVA_Y

; ---- ADC -----
EXTRN CODE(LEER_MEDICION)
EXTRN NUMBER(INPUT)
; ------- Filtro ----------
EXTRN CODE(FILTRAR_LP)
; ------- Ctrl_Mouse --------
EXTRN CODE(MOVIMIENTO, INICIALIZAR_CTRL_MOUSE)
; ------- Check Aceleracion ---------------
EXTRN CODE(ADECUAR_ACELERACION)

; --------- Margenes de Reposo ----------
; Para el reposo en el aire:
;X_MIN_REPOSO EQU 110
;X_MAX_REPOSO EQU 145
;Y_MIN_REPOSO EQU 110
;Y_MAX_REPOSO EQU 146
;X_MIN_REPOSO EQU 120
;X_MAX_REPOSO EQU 135
;Y_MIN_REPOSO EQU 120
;Y_MAX_REPOSO EQU 136
; Para el reposo sobre teclado:
 X_MIN_REPOSO EQU 110
 X_MAX_REPOSO EQU 122
 Y_MIN_REPOSO EQU 154
 Y_MAX_REPOSO EQU 166



DSEG at 0x30
MEDICION_X: ds 1
MEDICION_Y: ds 1
X_FILTRADA: ds 1
Y_FILTRADA: ds 1
ACELERACION_POSITIVA_X: ds 1
ACELERACION_NEGATIVA_X: ds 1
ACELERACION_POSITIVA_Y: ds 1
ACELERACION_NEGATIVA_Y: ds 1


BSEG at 00
REPOSO_X: dbit 1
REPOSO_Y: dbit 1


; Macros

;Utilización del filtro.
; X: x(n)     Y: y(n-1)
; Resultado se almacena en Y: Y: y(n)
filtrar MACRO X, Y
	push ACC
	push 0xF0 ; B
	mov A, Y
	mov B, X
	call FILTRAR_LP
	mov Y, A
	pop 0xF0 ; B
	pop ACC
	ENDM


; Determina si una variable se encuentra dentro o fuera de un margen (determinado por
; MIN y MAX) prendiendo o apagando el bit FLAG respectivamente
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


CSEG
ORG 0
ljmp MAIN
ORG 3h ; Interrupción externa INT0
ljmp INT0_ACTIVADA

ORG 30h
MAIN:
	; Setear INPUT para lectura
	mov INPUT, #0xFF
	
	; Dar condiciones iniciales estimadas al filtro:
	mov X_FILTRADA, #127
	mov Y_FILTRADA, #127

	; Condiciones iniciales de salida:
	call INICIALIZAR_CTRL_MOUSE
	
	; Setear Interrupción Externa en modo "activo por nivel"
	clr IT0
	; Habilitar interrupcion externa 0
	mov IE, #0x81
	; Entrar en modo de reposo IDLE
	SLEEP: mov PCON, #1  ; El resto de los bits de PCON no son utilizados
	jmp SLEEP


; Esta función se ejecuta infinitamente mientras INT0 (P3.2) se mantenga activa (en 0)
INT0_ACTIVADA:

		call LEER_MEDICION

		filtrar MEDICION_X, X_FILTRADA
		filtrar MEDICION_Y, Y_FILTRADA
		
		; Checkear que X no esté en reposo
		check_margen X_FILTRADA, X_MIN_REPOSO, X_MAX_REPOSO, REPOSO_X
		check_margen Y_FILTRADA, Y_MIN_REPOSO, Y_MAX_REPOSO, REPOSO_Y
		jnb REPOSO_X, CLASIFICAR
		jb REPOSO_Y, SALIR_INT0 ; Si ambos ejes se encuentran en reposo, no hacer nada.
		
		CLASIFICAR:
		call CLASIFICAR_DIRECCION_X
		call CLASIFICAR_DIRECCION_Y
		
		call ADECUAR_ACELERACION
		
		call MOVIMIENTO
		
	SALIR_INT0:
	reti



		
; Esta función toma los valores de X_FILTRADA, asumiendo que
; se encuentra fuera del margen de reposo, y almacenan el nivel correspondiente de
; velocidad en el eje y sentido que corresponda (ACELERACION_POSITIVA_X, 
; ACELERACION_NEGATIVA_X)
CLASIFICAR_DIRECCION_X:
	push ACC
	mov ACELERACION_POSITIVA_X, #0
	mov ACELERACION_NEGATIVA_X, #0
	jb REPOSO_X, SALIR_CLASIFICACION_X
	COMPARAR_X:
	clr C
	mov A, #X_MAX_REPOSO
	cjne A, X_FILTRADA, $+3
	jc X_POSITIVO   ; si X >= MAX ...
	X_NEGATIVO:
		; MIN - medicion
		mov A, #X_MIN_REPOSO
		subb A, X_FILTRADA
		mov ACELERACION_NEGATIVA_X, A
		jmp SALIR_CLASIFICACION_X
	X_POSITIVO:
		; medicion - MAX
		mov A, X_FILTRADA
		subb A, #X_MAX_REPOSO
		mov ACELERACION_POSITIVA_X, A
	SALIR_CLASIFICACION_X:
		pop ACC
		ret

; Esta función toma los valores de Y_FILTRADA, asumiendo que
; se encuentra fuera del margen de reposo, y almacenan el nivel correspondiente de
; velocidad en el eje y sentido que corresponda (ACELERACION_POSITIVA_Y, 
; ACELERACION_NEGATIVA_Y)
CLASIFICAR_DIRECCION_Y:
	push ACC
	mov ACELERACION_POSITIVA_Y, #0
	mov ACELERACION_NEGATIVA_Y, #0
	jb REPOSO_Y, SALIR_CLASIFICACION_Y
	COMPARAR_Y:
	clr C
	mov A, #Y_MAX_REPOSO
	cjne A, Y_FILTRADA, $+3
	jc Y_POSITIVO   ; si Y >= MAX ...
	Y_NEGATIVO:
		; MIN - medicion
		mov A, #Y_MIN_REPOSO
		subb A, Y_FILTRADA
		mov ACELERACION_NEGATIVA_Y, A
		jmp SALIR_CLASIFICACION_Y
	Y_POSITIVO:
		; medicion - MAX
		mov A, Y_FILTRADA
		subb A, #Y_MAX_REPOSO
		mov ACELERACION_POSITIVA_Y, A
	SALIR_CLASIFICACION_Y:
		pop ACC
		ret


END
