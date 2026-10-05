; CONTROLE DE PLANTA
; Botao I acionado -> Sistema Liga -> OK
; Ligar Evs <-> (Se, e somente se) o líquido estiver no nível A ou B -> OK
; Se o líquido estiver no nível C, a Evs deve ser desligada até ele atingir B -> OK
; Ligar Eve <-> (Se, e somente se) Botão I ligado e o líquido não estiver em A -> OK
; Se o botão I foi pressionado mais uma vez -> desligar Evs e Eve -> OK
PROCESSOR 16F84A
#include <xc.inc>
#include "macros.inc"

config FOSC = XT, WDTE = OFF, PWRTE = OFF, CP = OFF
global _main, start_initialization

; RA1 = Botao I, RA2 = A, RA3 = B, RA4 = C
; RB0 = Evs, RB1 = Eve, RB2 = Status Flag de Erro
; Flag de Erro:     
; A e B ativados, mas C desativado; ou A ativado e B e C desativados
; ou B ativado e C desativado (PORTA = 0b011I ou 0b110I ou 0b00AI)
; I é o botao q pode ser 0 ou 1 e A tbm
    
    
_if_erro_detectado MACRO
    btfsc PORTB, 2
    goto _end
ENDM

PSECT static_vars, class=RAM, space=1
botao_pressionado: ds 1
reg_niveis: ds 1
reg_niveis_temp: ds 1
    
PSECT verificacao_portas, class=CODE, space=0, reloc=2, delta=2
start_initialization:
_main:
    call _portas_settings
    movlf 0x00, botao_pressionado
    movlf 0x00, reg_niveis
    goto _verifica_niveis
    
_portas_settings:
    banksel PORTA ; bsf STATUS, 5
    clrf PORTA
    clrf PORTB
    banksel TRISA ; bcf STATUS, 5
    movlf 0b00011110, TRISA ; PORTA é input em A1, A2, A3 e A4
    clrf TRISB ; PORTB inteira é output por padrao
    bsf TRISB, 3 ; B2 como input para alerta de erro
    banksel PORTA
    retlw 0x00
    
_verifica_niveis:
    movf botao_pressionado, 1
    btfss STATUS, 2
    call _if_botao_pressionado
    
    btfss PORTA, 1
    goto if_nivC
    if_botaoHigh:
	movlf 0x01, botao_pressionado
	btfss PORTA, 2
	goto if1_nivB
	if1_nivA:
	    bsf reg_niveis, 0
	    call _ligarEvs
	if1_nivB:
	    btfss PORTA, 3
	    goto if_nivC
	    bsf reg_niveis, 1
	    call _desligarEvs
	    call _desligarEve
    if_nivC:
	btfsc PORTA, 4
	bsf reg_niveis, 2
	call _desligarEvs
	call _ligarEve
_verifica_erros:
    movf reg_niveis, 0
    movwf reg_niveis_temp
    xorlf  0b011, reg_niveis, 0
    call _verifica_zero
    _if_erro_detectado
    xorlf 0b110, reg_niveis, 0
    call _verifica_zero
    _if_erro_detectado
    xorlf 0b000, reg_niveis, 0
    call _verifica_zero
    _if_erro_detectado
    xorlf 0b001, reg_niveis, 0
    call _verifica_zero
    _if_erro_detectado
    movlf 0x00, reg_niveis
    movf reg_niveis_temp, 0
    movwf reg_niveis
_end:
    goto _verifica_niveis
	
	
	
_ligarEvs:
    bsf PORTB, 0
    return
_desligarEvs:
    bcf PORTB, 0
    return
_ifC_desligarEvs:
    bcf PORTB, 0
    btfss PORTA, 1
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
    call _desligarEvs
    movlf 0x00, botao_pressionado
    return

_verifica_zero:
    btfsc STATUS, 2
    bsf PORTB, 2
    return


