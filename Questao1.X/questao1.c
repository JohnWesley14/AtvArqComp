/*
 * File:   questao1.c
 * Author: bande
 *
 * Created on 7 de Outubro de 2026, 22:14
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

extern void portas_settings(void);
extern void interrupt_settings_S(void);
extern void verificar_sensor_S(void);
void _verificar_sensor_C(void);

int main(void) {
    portas_settings();
    interrupt_settings_S();
    
    while(1){
        //time_flag = 1; //teste
        if(time_flag){
            time_flag = 0;
            _verificar_sensor_C();
        }
    }
    
    return 0;
}

void _verificar_sensor_C(void){
    if(P(A, 1)){ 
        PORTB = 0x72; 
    } else { 
        PORTB = 0x81; 
    }
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
