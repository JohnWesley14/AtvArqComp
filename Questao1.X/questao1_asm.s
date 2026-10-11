; PORTAS E TIMER
; PA1 � um bot�o pull-up
; if(PA1 == 0){ PB = 0x72 } else { PB = 0x81 }
; PA0 = 1 // A cada 4 Hz
; PA1 � input, PA0 e PB � output
    
;PROCESSOR 16F84A
;PROCESSOR 16F628A
#include <xc.inc>
#include "macros.inc"

config FOSC = XT, WDTE = OFF, PWRTE = OFF, CP = OFF
;global _main, start_initialization 
global _portas_settings_asm, _interrupt_settings_asm, _verificar_sensor_asm
    
    
varAHigh equ 0x2C ; pode ser tratado como regsitrador nas instru��es
varALow equ 0x2E

; OBS: Todos os botoes/inputs da porta A s�o pull-up 
 
PSECT static_vars, class=RAM, space=1
STATUS_TEMP: ds 1
W_TEMP: ds 1
#ifndef MY_INTERRUPT_C
    contador_4hz: ds 1
#endif


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
	goto    _sair_int   ; Se n?o chegou a 0, sai e espera o pr?ximo estouro (de 2ms)
	
    _ifint_ok: ; 4 Hz
	banksel PORTA
	xorlf	0b00000001, PORTA, 1 ; altera s? esse PA0
	movlf	125, contador_4hz ; 0x0C <- 0x7D
	_retornar_contexto
    retfie ; return e GIE = 1 (habilita de novo)
#endif   
    
PSECT verificacao_portas, class=CODE, space=0, reloc=2, delta=2
;start_initialization: ; Usar direto no .c
;_main:
;    call _portas_settings_asm
;    goto _verificar_sensor_asm
    
_portas_settings_asm:
    banksel PORTA ; bsf STATUS, 5
    clrf PORTA
    clrf PORTB
    banksel TRISA ; bcf STATUS, 5
    clrf TRISA ; PORTA � output por padrao
    bsf TRISA, 1 ; RA1 � input
    clrf TRISB ; PORTB inteira � output
    banksel PORTA
    movlf 125, contador_4hz
    movlf 0x81, varALow
    movlf 0x72, varAHigh
    retlw 0x00
    
_verificar_sensor_asm:
    banksel PORTA
    btfss PORTA, 1 ; Se o bit RA1 == 1 pula a pr�xima instrucao
    goto _else_if1
    _if1_PA1_HIGH: ; Se o RA1 == 1
	movvf varAHigh, PORTB
	goto _end
    _else_if1: ; Se o RA1 == 0
	movvf varALow, PORTB

_end:
    retlw 0x00
    ;goto _verificar_sensor_asm

    
_interrupt_settings_asm:
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
