; FILA DE PRIORIDADES 
PROCESSOR 16F84A
#include <xc.inc>
#include "macros.inc"

config FOSC = XT, WDTE = OFF, PWRTE = OFF, CP = OFF
;global _main, start_initialization
global _portas_settings_asm, _interrupt_settings_asm, _verifica_prioridade_asm

; OBS: Todos os botoes/inputs da porta A são pull-up 

global _time_flag
    
#ifdef MY_INTERRUPT_C
    global _contador_4hz, _divisor_tempo
#endif    
    
#ifndef MY_INTERRUPT_C
    _setar_variaveis_timer MACRO
	movlf 125, _contador_4hz
	movlf   8, _divisor_tempo
    ENDM
#endif
    
PSECT static_vars, class=RAM, space=1
STATUS_TEMP: ds 1
W_TEMP: ds 1
; _time_flag: ds 1
#ifndef MY_INTERRUPT_C
    _contador_4hz: ds 1
    _divisor_tempo: ds 1
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
	decfsz  _contador_4hz, 1
	goto    _sair_int   ; Se não chegou a 0, sai e espera o próximo estouro (de 2ms)
	
    _ifint_ok: ; 2 Hz
	banksel PORTA
	movlw   0b00000001
	xorwf   PORTA, 1 ; altera só esse PA0
	movlf   125, _contador_4hz ; 0x0C <- 0x7D
	_if_time_flag_up:
	    banksel _divisor_tempo
	    decfsz  _divisor_tempo, 1
	    goto    _sair_int       ; Se o múltiplo ainda não zerou, sai
	    movlf   8, _divisor_tempo ; Reinicia o divisor para o próximo ciclo
	    movlf   1, _time_flag
	_retornar_contexto
    retfie ; return e GIE = 1 (habilita de novo)
#endif
    
PSECT verificacao_portas, class=CODE, space=0, reloc=2, delta=2
;start_initialization:
;_main:
;    call _portas_settings_asm
;    call _interrupt_settings_asm
;    goto _verifica_prioridade_asm
    
_portas_settings_asm:
    banksel PORTA ; bsf STATUS, 5
    clrf PORTA
    clrf PORTB
    banksel TRISA ; bcf STATUS, 5
    movlf 0b00011110, TRISA ; PORTA é input em A1, A2, A3 e A4
    clrf TRISB ; PORTB inteira é output por padrao
    banksel PORTA
    ;movlf 0x00, _time_flag
    _setar_variaveis_timer
    retlw 0x00

_verifica_prioridade_asm:
    _if_timeup:
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
    goto _verifica_prioridade_asm
    
    
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
    
    
    

