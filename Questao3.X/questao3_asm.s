; FILA DE PRIORIDADES 
;PROCESSOR 16F84A
;PROCESSOR 16F628A
#include <xc.inc>
#include "macros.inc"

config FOSC = XT, WDTE = OFF, PWRTE = OFF, CP = OFF
;global _main, start_initialization
global _portas_settings_asm, _verificar_prioridade_asm 
    
; OBS: Todos os botoes/inputs da porta A são pull-up 

    
PSECT static_vars, class=RAM, space=1
STATUS_TEMP: ds 1
W_TEMP: ds 1
    
PSECT verificacao_portas, class=CODE, space=0, reloc=2, delta=2
;start_initialization: ; Usar direto no .c
;_main:
;    call _portas_settings_asm
;    goto _verificar_prioridade_asm
    
_portas_settings_asm:
    banksel PORTA ; bsf STATUS, 5
    clrf PORTA
    clrf PORTB
    banksel TRISA ; bcf STATUS, 5
    movlf 0b00011110, TRISA ; PORTA é input em A1, A2, A3 e A4
    clrf TRISB ; PORTB inteira é output por padrao
    banksel PORTA
    retlw 0x00

_verificar_prioridade_asm:
	clrf PORTB
	btfsc PORTA, 1
	goto _elif_P2
	_if_P1:	; prioridade 1
	    bsf PORTB, 0
	    goto _end
	_elif_P2:	; prioridade 2
	    btfsc PORTA, 2
	    goto _elif_P3
	    bsf PORTB, 1
	    goto _end
	_elif_P3:	; prioridade 3
	    btfsc PORTA, 3
	    goto _else_P4
	    bsf PORTB, 2
	    goto _end
	_else_P4:	; prioridade 4
	    btfsc PORTA, 4
	    goto _end
	    bsf PORTB, 3
_end:
    ;goto _verificar_prioridade_asm
    retlw 0x00
   
    
    

