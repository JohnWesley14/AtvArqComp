/*
 * File:   questao3.c
 * Author: bande
 *
 * Created on 7 de Outubro de 2026, 22:01
 */


#include <xc.h>
#include "config_pic.h"


//#define MY_INTERRUPT_C

#ifdef MY_INTERRUPT_C
u8 contador_4hz = 125;
u8 divisor_tempo = 8;
void _interrupt() interruptC(void);
#endif

volatile u8 time_flag = 0;

extern void interrupt_settings_S(void);
extern void portas_settings(void);
void _verificar_prioridade_C(void);
void _limpar_correia(void);

int main(void) {
    
    portas_settings();
    interrupt_settings_S();
    
    while (1){
        //time_flag = 1; //teste
        if(time_flag){
            _limpar_correia();
            _verificar_prioridade_C();
            //_verificar_prioridade_S()
            time_flag = 0;
        }
        
    }
    
    return 0;
}

void _verificar_prioridade_C(void){
    
    if (!P(A, 1)){ // Botões em pull-down
        P(B, 0) = 1;
    }
    else if (!P(A, 2)){
        P(B, 1) = 1;
    }
    else if (!P(A, 3)){
        P(B, 2) = 1;
    }
    else if (!P(A, 4)){
        P(B, 3) = 1;
    }
    
}

void _limpar_correia(void){
    P(B, 0) = 0; P(B, 1) = 0;
    P(B, 2) = 0; P(B, 3) = 0;
}

#ifdef MY_INTERRUPT_C
void _interrupt() interruptC(void) { 
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
                flag_leitura = 1;     // Libera a leitura dos botões no múltiplo
                divisor_tempo = 8;    // Reinicia para o próximo intervalo
            }
        }
        
    }
}
#endif