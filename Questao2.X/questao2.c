/*
 * File:   questao2.c
 * Author: bande
 *
 * Created on 10 de Outubro de 2026, 12:44
 */

/*
 CONTROLE DE PLANTA
 Botao I acionado -> Sistema Liga -> OK
 Ligar Evs <-> (Se, e somente se) o líquido estiver no nível A ou B -> OK
 Se o líquido estiver no nível C, a Evs deve ser desligada até ele atingir B -> OK
 Ligar Eve <-> (Se, e somente se) Botão I ligado e o líquido não estiver em A -> OK
 Se o botão I foi pressionado mais uma vez -> desligar Evs e Eve -> OK
*/
/*
 RA1 = Botao I, RA2 = A, RA3 = B, RA4 = C
 RB0 = Evs, RB1 = Eve, RB2 = Status Flag de Erro
 Flag de Erro:     
 A e B ativados, mas C desativado; ou A ativado e B e C desativados
 ou B ativado e C desativado (PORTA = 0b011I ou 0b110I ou 0b00AI)
 I é o botao q pode ser 0 ou 1 (e A tem o mesmo raciocinio)
*/

#include <xc.h>
#include "config_pic.h"

//#define MY_INTERRUPT_C // ativar no .s e no .c ou no properties

#ifdef MY_INTERRUPT_C
    u8 contador_4hz = 125;
    u8 divisor_tempo = 8;
    void __interrupt() interruptC(void);
#endif

#define  BotaoI !P(A, 1)
#define  nivelA !P(A, 2)
#define  nivelB !P(B, 3)
#define  nivelC !P(A, 4)
#define  Evs P(B, 0)
#define  Eve P(B, 1)
#define  erro_detectado P(B, 2)
#define ligar(pino)    ((pino) = 1)
#define desligar(pino) ((pino) = 0)
    
volatile u8 time_flag = 0;
volatile u8 reg_niveis = 0;
volatile u8 botao_pressionado = 0;

extern void interrupt_settings_asm(void);
extern void portas_settings_asm(void);
void _verificar_niveis_C(void);
void _limpar_niveis(void);
void _verificar_erros_C(void);


int main(void) {
    
    portas_settings_asm();
    interrupt_settings_asm();
    
    
    while (1){
        //time_flag = 1; //teste
        if(time_flag){
            reg_niveis = 0;
            erro_detectado = 0;
            _verificar_niveis_C();
            //_verificar_prioridade_S();
            time_flag = 0;
        }
        
    }
    
    return 0;
}

void _verificar_niveis_C(void){
    
	reg_niveis = 0;
	
	if (botao_pressionado) {
        desligar(Evs);
        desligar(Eve);
    }
    
    if(!P(A, 1)){ // Botão I pressionado
        botao_pressionado = 1;
        
        if (!P(A, 2)){
            reg_niveis |= 1;
            ligar(Evs);
        } else {
            ligar(Eve);
        }
        
        if (!P(A, 3)){
            reg_niveis |= (1 << 1);
            if (P(A, 2)){
                ligar(Evs);
            }
        }
        if (!P(A, 4)){
            reg_niveis |= (1 << 2);
            if (P(A, 3)){ // Se nivel B nao foi atingido
                desligar(Evs);
            }
        }
    }
    
    _verificar_erros_C();
}


void _verificar_erros_C(void){
    switch(reg_niveis){
        case 0b011: // C é o unico nao atingido
        case 0b110: // A é o unico nao atingido
        case 0b000: // Ninguem e atingido
        case 0b001: // Apenas A é atingido
            erro_detectado = 1;
            break;
        default:
            break;
    }
}


#ifdef MY_INTERRUPT_C
void __interrupt() interruptC(void) { 
    // Verifica qual módulo disparou a interrupção
    if (INTCONbits.T0IF) {
        INTCONbits.T0IF = 0; // Limpa a flag (equivalente ao bcf INTCON, 2)
        TMR0 = 6;            // Recarrega o hardware para estourar em 1 ms
        
        contador_4hz--;      // Prescaler de software
        
        if (contador_4hz == 0) {
            PORTAbits.RA0 = ~PORTAbits.RA0; // Inverte o estado do pino (Toggle)
            contador_4hz = 125;             // Reinicia a contagem dos 125 ms
            // Sub-contador para o múltiplo desejado
            divisor_tempo--;
            if (divisor_tempo == 0) {
                time_flag = 1;     // Libera a leitura dos botões no múltiplo
                divisor_tempo = 8;    // Reinicia para o próximo intervalo
            }
        }
        
    }
}
#endif