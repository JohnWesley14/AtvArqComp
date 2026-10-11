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
#define  nivelB !P(A, 3)
#define  nivelC !P(A, 4)
#define  Evs P(B, 0)
#define  Eve P(B, 1)
#define erro_flag P(B, 2)
#define ligar(pino)    ((pino) = 1)
#define desligar(pino) ((pino) = 0)
    
static u8 botao_atual = 0;
static u8 sensA = 0;
static u8 sensB = 0;
static u8 sensC = 0;

#ifdef ONLY_ASM_FUNCTIONS
    // Avisa o C que estas variáveis foram criadas no ficheiro Assembly
    extern volatile u8 time_flag;
#else
    volatile u8 time_flag = 0;
    volatile u8 estado_sistema = 0;
    volatile u8 estado_anterior_botao = 0;
#endif

volatile u8 erro_detectado = 0;

#ifndef NAO_USAR_TIMER
    extern void interrupt_settings_asm(void);
#endif
extern void portas_settings_asm(void);
#ifdef ONLY_ASM_FUNCTIONS
   extern u8 verificar_niveis_asm(void);
#elif !defined(ONLY_ASM_FUNCTIONS)
    u8 _verificar_niveis_C(void);
#endif



int main(void) {
    
    portas_settings_asm();
    #ifndef NAO_USAR_TIMER
        interrupt_settings_asm();
    #endif
    
    while (1){

        //time_flag = 1; //teste
        #ifndef NAO_USAR_TIMER
        if(time_flag){
        #endif
        
            #ifdef ONLY_ASM_FUNCTIONS
                time_flag = verificar_niveis_asm(); // time_flag = 0
            #elif !defined(ONLY_ASM_FUNCTIONS)
                time_flag = _verificar_niveis_C(); // time_flag = 0
            #endif

        #ifndef NAO_USAR_TIMER
        }
        #endif
    }
    
    return 0;
}

#ifndef ONLY_ASM_FUNCTIONS
u8 _verificar_niveis_C(void){
    
    botao_atual = !P(A, 1);
	sensA = !P(A, 2);
    sensB = !P(A, 3);
    sensC = !P(A, 4);
    
    // Botao apertado e antes não apertado -> entra
    if (botao_atual && !estado_anterior_botao) {
        estado_sistema = !estado_sistema;
    }
    
    estado_anterior_botao = botao_atual;
    erro_detectado = ((sensA && !sensB) || (sensA && !sensC) || (sensB && !sensC));
    // Verificação de Erros (A sua lógica de reg_niveis está correta, mas pode ser direta)
    if (erro_detectado) {
        desligar(Evs); 
        desligar(Eve);
        ligar(erro_flag);
        
    } else {
        
        desligar(erro_flag);
        
        if(estado_sistema){
            
            if (sensA){ // Nivel A (Último nível)
                desligar(Eve);
            } else { // Não
                ligar(Eve);
            }

            if (sensB || sensA){ // Nivel B ou A
                ligar(Evs);
            }
            
            else if (sensC && !sensB){ // Atingiu o Nível C, mas não o B
                desligar(Evs);
            }
        } else {
            desligar(Evs);
            desligar(Eve);
        }    
    }
    return 0;
}
#endif

#ifdef MY_INTERRUPT_C
void __interrupt() interruptC(void) { 
    // Verifica qual módulo disparou a interrupção
    if (INTCONbits.T0IF) {
        INTCONbits.T0IF = 0; // Limpa a flag (equivalente ao bcf INTCON, 2)
        TMR0 = 6;   // Recarrega o hardware para estourar em 1 ms
        
        contador_4hz--; // Prescaler de software
        
        if (contador_4hz == 0) {
            contador_4hz = 125; // Reinicia a contagem dos 125 ms
            // Sub-contador para o múltiplo desejado
            divisor_tempo--;
            if (divisor_tempo == 0) {
                time_flag = 1;  // Libera a leitura dos botões no múltiplo
                divisor_tempo = 1;  // Reinicia para o próximo intervalo
            }
        }
        
    }
}
#endif