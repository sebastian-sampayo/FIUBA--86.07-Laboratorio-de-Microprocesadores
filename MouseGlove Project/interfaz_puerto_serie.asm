PUBLIC INICIALIZAR_COMUNICACION, IMPRIMIR_VALOR, OUTCHAR
PUBLIC ASCII_SEPARADOR, ASCII_CR, ASCII_LF

INTERFAZ_PUERTO_SERIE_CODE SEGMENT CODE
RSEG INTERFAZ_PUERTO_SERIE_CODE

; ------- Output Debug -----
ASCII_0 EQU 48
ASCII_CR EQU 13
ASCII_LF EQU 10
ASCII_GUION EQU 150
ASCII_COMA EQU 44
ASCII_SEPARADOR EQU ASCII_COMA
; ------- Timer reload count ----------
; Overflow = timer frec / Baud Rate / 16  -- SCON=1
;TH1_RELOAD EQU -1 ;  Baud Rate: 57600
TH1_RELOAD EQU -4 ;  Baud Rate: 15625
;TH1_RELOAD EQU -13 ;  Baud Rate: 4800


INICIALIZAR_COMUNICACION:
; Configuración del Timer
	mov TMOD, #20h ; Timer 0, mode 2 (8 bit timer mode)
	mov TH1, #TH1_RELOAD	; baud reload value
	setb TR1		; Start Timer 0
	; Configuración del Puerto Serial
	mov SCON, #42h	;Serial Port, mode 1
	; SMOD = 1
	mov A, PCON
	setb ACC.7
	mov PCON, A
	
	ret

; Recibe un numero en R0 y lo convierte en 3 caracteres, estos son enviados a SBUF
IMPRIMIR_VALOR:
	; divido por 10 me quedo con el resto en B y le sumo el bias de ASCII_0
	mov R1, #3
	LOOP1:
		mov A, R0
		mov B, #10
		div AB
		mov R0, A
		mov A, B
		add A, #ASCII_0
		push ACC
		djnz R1, LOOP1
		
	mov R1, #3
	LOOP2:
		pop ACC
		call OUTCHAR
		djnz R1, LOOP2
	ret
	
; Recibe un caracter en el ACUMULADOR y lo envía a SBUF
OUTCHAR:
	jnb TI, $
	clr TI
	mov SBUF, A
	ret
	
END