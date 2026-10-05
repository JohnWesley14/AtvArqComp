; FILA DE PRIORIDADES 
PROCESSOR 16F84A
#include <xc.inc>
#include "macros.inc"

config FOSC = XT, WDTE = OFF, PWRTE = OFF, CP = OFF
global _main, start_initialization
    
    
PSECT verificacao_portas, class=CODE, space=0, reloc=2, delta=2
start_initialization:
_main:
    call _portas_settings
    goto _verifica_prioridade
    
_portas_settings:
    banksel PORTA ; bsf STATUS, 5
    clrf PORTA
    clrf PORTB
    banksel TRISA ; bcf STATUS, 5
    movlf 0b00011110, TRISA ; PORTA é input em A1, A2, A3 e A4
    clrf TRISB ; PORTB inteira é output por padrao
    banksel PORTA
    retlw 0x00

_verifica_prioridade:
    clrf PORTB
    btfss PORTA, 1
    goto _elif_P2
    _if_P1:	; prioridade 1
	bsf PORTB, 0
	goto _end
    _elif_P2:	; prioridade 2
	btfss PORTA, 2
	goto _elif_P3
	bsf PORTB, 1
	goto _end
    _elif_P3:	; prioridade 3
	btfss PORTA, 3
	goto _else_P4
	bsf PORTB, 2
	goto _end
    _else_P4:	; prioridade 4
	btfss PORTA, 4
	goto _end
	bsf PORTB, 3
_end:
    goto _verifica_prioridade
    
    
    

