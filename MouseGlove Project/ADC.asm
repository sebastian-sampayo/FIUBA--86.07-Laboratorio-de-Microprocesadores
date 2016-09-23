; -------------------------------------------------------------------------------------------------------------------
; El siguiente módulo contiene las funciones de bajo nivel para la comunicación con
; un conversor Analógico/Digital -ADC0808-
; Uso: (constantes utilizadas)
;	INPUT: Puerto del 8051 que recibe los datos
;	START_ADC: Pin del 8051 conectado al pin START del ADC0808
;	CTRL_ADC: Pin del 8051 conectado al pin de control 2 del ADC0808 
;							(selecciona entre la entrada 0 y la entrada 4 del multiplexor del ADC0808)
;	CONVERSION_TIME: Tiempo de retardo estimado por la hoja de datos del ADC0808
;											para realizar una conversión.
;	
; Los resultados de la medición de la entrada 0 y la 4 se almacenan en MEDICION_X 
; y MEDICION_Y respectivamente.
; -------------------------------------------------------------------------------------------------------------------

PUBLIC LEER_MEDICION
PUBLIC INPUT

EXTRN DATA(MEDICION_X, MEDICION_Y)

ADC_CODE SEGMENT CODE
RSEG ADC_CODE

; ------- ADC ------
INPUT EQU P2
START_ADC EQU P1.0
CTRL_ADC EQU P1.1
CONVERSION_TIME EQU 130

; MACROS
; Seleccionar entrada correspondiente a la aceleración en X
seleccionarX MACRO
	clr CTRL_ADC
	ENDM
; Seleccionar entrada correspondiente a la aceleración en Y
seleccionarY MACRO
	setb CTRL_ADC
	ENDM


;Leer MEDICION:
LEER_MEDICION:
	; X
	seleccionarX
;	Pulso en pin1:
	setb START_ADC
	clr START_ADC
;	Delay_conversion_time
	call DELAY_CONVERSION_TIME
;	MEDICION <- INPUT
	mov MEDICION_X, INPUT
	
	; Y
	seleccionarY
;	Pulso en pin1:
	setb START_ADC
	clr START_ADC
;	Delay_conversion_time
	call DELAY_CONVERSION_TIME
;	MEDICION <- INPUT
	mov MEDICION_Y, INPUT
	ret

; >100 us
DELAY_CONVERSION_TIME: 
	mov R0, #(CONVERSION_TIME/2)
	djnz R0, $
	ret
	
	

END