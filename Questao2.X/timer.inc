#include "macros.inc"
    
PSECT interrrupt_settings, class=CODE, space=0, reloc=2, delta=2

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