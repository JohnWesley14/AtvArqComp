; PORTAS E TIMER
; if(PA1 == 1){ PB = 0x72 } else { PB = 0x81 }
; PA0 = 1 // A cada 4 Hz
; PA1 é input, PA0 e PB é output
    
PROCESSOR 16F84A
#include <xc.inc>
#include "macros.inc"

config FOSC = XT, WDTE = OFF, PWRTE = OFF, CP = OFF
;global _main, start_initialization 
global _portas_settings, _verificar_sensor_S, _interrupt_settings_S
; #define:
varAHigh equ 0x2C ; pode ser tratado como regsitrador nas instruções
varALow equ 0x2E
global _time_flag
 
; OBS: Todos os botoes/inputs da porta A são pull-up 
 
 
PSECT static_vars, class=RAM, space=1
contador_4hz: ds 1
divisor_tempo: ds 1
STATUS_TEMP: ds 1
W_TEMP: ds 1
    
#ifndef MY_INTERRUPT_C
PSECT intCode, class=CODE, delta=2, abs
ORG 0x0004
_interruptVector: ; GIE = 0 -> impede novas interrupts
    _salvar_contexto
    BANKSEL INTCON
    btfss   INTCON, 2 ; T0IF: TMR0 que interrompeu
    goto    _sair_int

    ; Recarrega o TMR0 com 250 (256 - 6)
    _recarregaTMR0:
	bcf INTCON, 2
	BANKSEL TMR0
	movlf  6, TMR0
    ; Decrementa contador_4hz (O "Prescaler" de software)
	decfsz  contador_4hz, 1
	goto    _sair_int   ; Se não chegou a 0, sai e espera o próximo estouro (de 2ms)
	
    _ifint_ok: ; 2 Hz
	banksel PORTA
	movlw   0b00000001
	xorwf   PORTA, 1 ; altera só esse PA0
	movlf   125, contador_4hz ; 0x0C <- 0x7D
	_if_time_flag_up:
	    banksel divisor_tempo
	    decfsz  divisor_tempo, 1
	    goto    _sair_int       ; Se o múltiplo ainda não zerou, sai
	    movlf   8, divisor_tempo ; Reinicia o divisor para o próximo ciclo
	    movlf   1, _time_flag
	_retornar_contexto
    retfie ; return e GIE = 1 (habilita de novo)
#endif
   
    
PSECT verificacao_portas, class=CODE, space=0, reloc=2, delta=2
;start_initialization:
;_main:
;    call _portas_settings
;    movlf 0x81, varALow
;    movlf 0x72, varAHigh
;    call _interrupt_settings_S
;    goto _verificar_sensor_S
    
_portas_settings:
    banksel PORTA ; bsf STATUS, 5
    clrf PORTA
    clrf PORTB
    banksel TRISA ; bcf STATUS, 5
    clrf TRISA ; PORTA é output por padrao
    bsf TRISA, 1 ; RA1 é input
    clrf TRISB ; PORTB inteira é output
    banksel PORTA
    #ifndef MY_INTERRUPT_C
	call _setar_variaveis
    #endif
    retlw 0x00

#ifndef MY_INTERRUPT_C
    _setar_variaveis:
	movlf 125, contador_4hz
	movlf   8, divisor_tempo
	return
#endif
    
_verificar_sensor_S:
    banksel PORTA
    btfss PORTA, 1 ; Se o bit RA1 == 1 pula a próxima instrucao
    goto _else_if1
_if1_PA1_HIGH: ; Se o RA1 == 1
    movvf varAHigh, PORTB
    goto _end
_else_if1: ; Se o RA1 == 0
    movvf varALow, PORTB
 
_end:
    goto _verificar_sensor_S
    

_interrupt_settings_S:
    banksel OPTION_REG
    movlw   0b10000001	; T0CS=0, PSA=0, Prescaler=1:4 (001)
    movwf   OPTION_REG
    
    banksel INTCON
    bsf     INTCON, 5	; T0IE = 1 -> timer 0 ligado
    bsf     INTCON, 7	; GIE = 1 -> habilita interrupts
    return

_sair_int:
    bcf     INTCON, 2	; T0IF <- 0
    _retornar_contexto
    retfie
