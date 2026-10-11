; CONTROLE DE PLANTA
; Botao I acionado -> Sistema Liga -> OK
; Ligar Evs <-> (Se, e somente se) o líquido estiver no nível A ou B -> OK
; Se o líquido estiver no nível C, a Evs deve ser desligada até ele atingir B -> OK
; Ligar Eve <-> (Se, e somente se) Botão I ligado e o líquido não estiver em A -> OK
; Se o botão I foi pressionado mais uma vez -> desligar Evs e Eve -> OK
; OBS: De baixo pra cima: C, B e A. Com as valvulas de entrada Eve e a de saida Evs
; RA1 = Botao I, RA2 = A, RA3 = B, RA4 = C
; RB0 = Evs, RB1 = Eve, RB2 = Status Flag de Erro
; Flag de Erro:     
; A e B ativados, mas C desativado; ou A ativado e B e C desativados
; ou B ativado e C desativado (PORTA = 0b011I ou 0b110I ou 0b00AI)
; I é o botao q pode ser 0 ou 1 (e A tem o mesmo raciocinio)
    
; OBS: Todos os botoes/inputs da porta A são pull-up 
   
;PROCESSOR 16F84A
;PROCESSOR 16F628A
#include <xc.inc>
#include "macros.inc"

;#define MY_INTERRUPT_C  ; ativar no .s e no .c ou no properties
    
config FOSC = XT, WDTE = OFF, PWRTE = OFF, CP = OFF
;global  _main, start_initialization ; Nao utilizar
    
global _portas_settings_asm, _verificar_niveis_asm
global _time_flag, _estado_sistema, _estado_anterior_botao
    
#ifndef NAO_USAR_TIMER
    global _interrupt_settings_asm
    global _contador_4hz, _divisor_tempo
#endif    
    
_ligarEvs macro 
    bsf PORTB, 0
endm
_desligarEvs macro 
    bcf PORTB, 0
endm
_ligarEve macro
    bsf PORTB, 1
endm
_desligarEve macro
    bcf PORTB, 1
endm
    
_resetar_variaveis macro
    clrf _time_flag
    clrf _estado_sistema
    clrf _estado_anterior_botao
endm

#ifndef NAO_USAR_TIMER
_setar_variaveis_timer macro
    movlf 125, _contador_4hz
    movlf   8, _divisor_tempo
endm
#endif
    
PSECT static_vars, class=RAM, space=1
STATUS_TEMP: ds 1
W_TEMP: ds 1
#ifdef ONLY_ASM_FUNCTIONS
    _estado_sistema: ds 1	; 0 = Desligado, 1 = Ligado
    _estado_anterior_botao: ds 1	; Guarda o estado fisico anterior do botao I
    _time_flag: ds 1   ; Vai ser definido por padrao no .c
#endif   
#if !defined(MY_INTERRUPT_C) && !defined(NAO_USAR_TIMER)
    _contador_4hz: ds 1
    _divisor_tempo: ds 1
#endif 
    
#if !defined(MY_INTERRUPT_C) && !defined(NAO_USAR_TIMER)
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

	_ifint_ok: ; 4 Hz
	    banksel PORTA
	    movlf   125, _contador_4hz ; 0x0C <- 0x7D
	    _if_time_flag_up:
		banksel _divisor_tempo
		decfsz  _divisor_tempo, 1
		goto    _sair_int       ; Se o múltiplo ainda não zerou, sai
		movlf   1, _divisor_tempo ; Reinicia o divisor para o próximo ciclo
		movlf   1, _time_flag
	    _retornar_contexto
	retfie ; return e GIE = 1 (habilita de novo)
#endif
    
PSECT verificacao_portas, class=CODE, space=0, reloc=2, delta=2
; start_initialization: ; Usar direto no .c
; _main:
;     call _portas_settings_asm
;     call _interrupt_settings_asm
;     goto _verificar_niveis_asm
	
_portas_settings_asm:
    banksel PORTA ; bsf STATUS, 5
    clrf PORTA
    clrf PORTB
    banksel TRISA ; bcf STATUS, 5
    movlf 0b00011110, TRISA ; PORTA é input em A1, A2, A3 e A4
    clrf TRISB ; PORTB inteira é output por padrao; B2 como output para alerta de erro
    banksel PORTA
    #ifndef NAO_USAR_TIMER
    _setar_variaveis_timer
    #endif
    _resetar_variaveis
    retlw 0x00


_verificar_niveis_asm:
    banksel PORTA
    #ifndef NAO_USAR_TIMER
	btfss _time_flag, 0	; não passou o tempo minimo
	goto _end
    #endif
    btfsc PORTA, 1  ; Se o botão I estiver solto (1), pula para _botao_solto
    goto _botao_solto
    
_botao_pressionado:
    btfsc _estado_anterior_botao, 0 ; Se já estava pressionado no loop anterior, ignora
    goto _fim_deteccao 
    
    ; Inverte o estado do sistema
    xorlf 0x01, _estado_sistema, 1
    bsf _estado_anterior_botao, 0   ; Atualiza o estado físico para pressionado
    goto _fim_deteccao
    
_botao_solto:
    bcf _estado_anterior_botao, 0   ; Atualiza o estado fisico para solto
    
_fim_deteccao:
    bcf PORTB, 2 ; Limpa o LED (a flag) de erro por padrao
    
    ; Erro 1: A atingido (RA2=0) mas B vazio (RA3=1)
    btfsc PORTA, 2
    goto _testa_erro_2
    btfsc PORTA, 3
    goto _erro_encontrado
    
_testa_erro_2:
    ; Erro 2: A atingido (RA2=0) mas C vazio (RA4=1)
    btfsc PORTA, 2
    goto _testa_erro_3
    btfsc PORTA, 4
    goto _erro_encontrado
    
_testa_erro_3:
    ; Erro 3: B atingido (RA3=0) mas C vazio (RA4=1)
    btfsc PORTA, 3
    goto _sem_erros
    btfsc PORTA, 4
    goto _erro_encontrado
    
_sem_erros:
    goto _logica_valvulas

_erro_encontrado:
    bcf PORTB, 0    ; Desliga Evs por segurança
    bcf PORTB, 1    ; Desliga Eve por segurança
    bsf PORTB, 2    ; Liga o alerta de erro
    goto _end  ; Aborta a lógica das valvulas

_logica_valvulas:
    btfsc _estado_sistema, 0	; Se o sistema estiver desligado (0), fecha as valvulas
    goto _sistema_ativo
    
    _desligarEvs
    _desligarEve
    goto _end
    
_sistema_ativo:
    ; Eve (RB1): Liga apenas se A nao foi atingido (RA2=1)
    btfss PORTA, 2  ; Testa o sensor A primeiro
    goto _desligar_eve  ; Se A=0 (atingido), pula para desligar
_ligar_eve:
	bsf PORTB, 1    ; Se A=1, liga Eve
	goto _logica_evs	; Pula o desligar para nao executar ambos
    _desligar_eve:
	bcf PORTB, 1    ; Desliga Eve

    _logica_evs:
	; EVS (RB0): Liga se atingiu A(RA2=0) ou atingiu B(RA3=0)
	btfss PORTA, 2  ; Testa A. Se for 0, pula o goto
	goto _liga_evs
	btfss PORTA, 3  ; Testa B. Se for 0, pula o goto
	goto _liga_evs
	goto _desliga_evs	; Se nenhum for 0, então desliga

    _liga_evs:
	bsf PORTB, 0
	goto _end
    _desliga_evs:
	bcf PORTB, 0
    
_end:
    retlw 0x00
    ;goto _verificar_niveis_asm

    
; Interrupt functions

#ifndef NAO_USAR_TIMER
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
#endif 

