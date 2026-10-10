; PORTAS E TIMER
; PA1 é um botão pull-up
; if(PA1 == 0){ PB = 0x72 } else { PB = 0x81 }
; PA0 = 1 // A cada 4 Hz
; PA1 é input, PA0 e PB é output
    
PROCESSOR 16F84A
#include <xc.inc>
#include "macros.inc"

config FOSC = XT, WDTE = OFF, PWRTE = OFF, CP = OFF
;global _main, start_initialization 
global _portas_settings_asm, _verificar_sensor_asm
    
    
varAHigh equ 0x2C ; pode ser tratado como regsitrador nas instruções
varALow equ 0x2E

 
; OBS: Todos os botoes/inputs da porta A são pull-up 
 
PSECT static_vars, class=RAM, space=1
STATUS_TEMP: ds 1
W_TEMP: ds 1

    
PSECT verificacao_portas, class=CODE, space=0, reloc=2, delta=2
;start_initialization:
;_main:
;    call _portas_settings_asm
;    movlf 0x81, varALow
;    movlf 0x72, varAHigh
;    goto _verificar_sensor_asm
    
_portas_settings_asm:
    banksel PORTA ; bsf STATUS, 5
    clrf PORTA
    clrf PORTB
    banksel TRISA ; bcf STATUS, 5
    clrf TRISA ; PORTA é output por padrao
    bsf TRISA, 1 ; RA1 é input
    clrf TRISB ; PORTB inteira é output
    banksel PORTA
    retlw 0x00
    
_verificar_sensor_asm:
    banksel PORTA
    btfss PORTA, 1 ; Se o bit RA1 == 1 pula a próxima instrucao
    goto _else_if1
    _if1_PA1_HIGH: ; Se o RA1 == 1
	movvf varAHigh, PORTB
	goto _end
    _else_if1: ; Se o RA1 == 0
	movvf varALow, PORTB

_end:
    goto _verificar_sensor_asm
    
