; CONTROLE DE PLANTA
; Botao I acionado -> Sistema Liga -> OK
; Ligar Evs <-> (Se, e somente se) o líquido estiver no nível A ou B -> OK
; Se o líquido estiver no nível C, a Evs deve ser desligada até ele atingir B -> OK
; Ligar Eve <-> (Se, e somente se) Botão I ligado e o líquido não estiver em A -> OK
; Se o botão I foi pressionado mais uma vez -> desligar Evs e Eve -> OK
    
; RA1 = Botao I, RA2 = A, RA3 = B, RA4 = C
; RB0 = Evs, RB1 = Eve, RB2 = Status Flag de Erro
; Flag de Erro:     
; A e B ativados, mas C desativado; ou A ativado e B e C desativados
; ou B ativado e C desativado (PORTA = 0b011I ou 0b110I ou 0b00AI)
; I é o botao q pode ser 0 ou 1 (e A tem o mesmo raciocinio)
    
; OBS: Todos os botoes/inputs da porta A são pull-up 
   
PROCESSOR 16F84A
#include <xc.inc>
#include "macros.inc"

//#define MY_INTERRUPT_C  // ativar no .s e no .c ou no properties
    
config FOSC = XT, WDTE = OFF, PWRTE = OFF, CP = OFF
;global _main, start_initialization
global _portas_settings_asm, _interrupt_settings_asm

;global _verificar_niveis_asm

global _time_flag, _reg_niveis, _botao_pressionado

#ifdef MY_INTERRUPT_C
    global _contador_4hz, _divisor_tempo
#endif    
    
_if_erro_detectado MACRO
    btfsc PORTB, 2
    goto _end
ENDM
 
_resetar_variaveis MACRO
    movlf 0x00, _time_flag
    movlf 0x00, _botao_pressionado
    movlf 0x00, reg_niveis
ENDM

_setar_variaveis_timer MACRO
    movlf 125, _contador_4hz
    movlf   8, _divisor_tempo
ENDM
    
PSECT static_vars, class=RAM, space=1
STATUS_TEMP: ds 1
W_TEMP: ds 1
;_botao_pressionado: ds 1
;_reg_niveis: ds 1
;_time_flag: ds 1
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
;    goto _verificar_niveis_asm
    
_portas_settings_asm:
    banksel PORTA ; bsf STATUS, 5
    clrf PORTA
    clrf PORTB
    banksel TRISA ; bcf STATUS, 5
    movlf 0b00011110, TRISA ; PORTA é input em A1, A2, A3 e A4
    clrf TRISB ; PORTB inteira é output por padrao
    bsf TRISB, 3 ; B2 como input para alerta de erro
    banksel PORTA
    _setar_variaveis_timer
    ;_resetar_variaveis
    retlw 0x00


_verificar_niveis_asm:
    _if_timeup:
	btfss _time_flag, 0
	goto _end
	movlf 0x00, _time_flag
	movlf 0x00, _reg_niveis
	bcf PORTB, 2 ; limpa registro de erro
	
	movf _botao_pressionado, 1
	btfss STATUS, 2
	call _if_botao_pressionado

	btfsc PORTA, 1
	goto if_nivC
	if_botaoHigh:
	    movlf 0x01, _botao_pressionado
	    btfsc PORTA, 2
	    goto if1_nivB
	    if1_nivA:
		bsf _reg_niveis, 0
		call _ligarEvs
	    if1_nivB:
		btfsc PORTA, 3
		goto if_nivC
		bsf _reg_niveis, 1
		btfss _reg_niveis, 0 ; não liga de novo se A já ligou
		call _ligarEvs
	    if_nivC:
		btfsc PORTA, 4
		goto if_not_nivA
		bsf _reg_niveis, 2
		btfsc _reg_niveis, 1
		call _desligarEvs
	    if_not_nivA:
		btfsc _reg_niveis, 0 ; se tiver apertado (low/0) -> pula a próxima
		call _ligarEve
_verificar_erros:
    xorlf  0b011, _reg_niveis, 0
    call _verificar_zero
    _if_erro_detectado
    xorlf 0b110, _reg_niveis, 0
    call _verificar_zero
    _if_erro_detectado
    xorlf 0b000, _reg_niveis, 0
    call _verificar_zero
    _if_erro_detectado
    xorlf 0b001, _reg_niveis, 0
    call _verificar_zero
    _if_erro_detectado
_end:
    goto _verificar_niveis_asm
	
	
    

_ligarEvs:
    bsf PORTB, 0
    return
_desligarEvs:
    bcf PORTB, 0
    return
_ifC_desligarEvs:
    bcf PORTB, 0
    btfsc PORTA, 1
    return
    goto if1_nivB
_ligarEve:
    bsf PORTB, 1
    return
_desligarEve:
    bcf PORTB, 1
    return
_if_botao_pressionado:
    call _desligarEvs
    call _desligarEve
    movlf 0x00, _botao_pressionado
    return

_verificar_zero:
    btfsc STATUS, 2
    bsf PORTB, 2
    return

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
    

