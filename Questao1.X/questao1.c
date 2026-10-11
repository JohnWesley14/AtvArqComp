/*
 * File:   questao1.c
 * Author: bande
 * PORTAS E TIMER
 * Created on 7 de Outubro de 2026, 22:14
 */

/* 
 PORTAS E TIMER
 PA1 � um bot�o pull-up, portanto PA1 � default = 1
 if(PA1 == 1){ PB = 0x72 } else { PB = 0x81 }
 PA0 = 1 // A cada 4 Hz
 PA1 � input, PA0 e PB � output
*/

#include <xc.h>
#include "config_pic.h"

#ifdef MY_INTERRUPT_C
u8 contador_4hz = 125;
void _interrupt() interruptC(void);
#endif

extern void portas_settings_asm(void);
extern void interrupt_settings_asm(void);
#ifdef ONLY_ASM_FUNCTIONS
    extern void verificar_sensor_asm(void);
#elif !defined(ONLY_ASM_FUNCTIONS)
    void _verificar_sensor_C(void);
#endif

int main(void) {
    portas_settings_asm();
    interrupt_settings_asm();
    
    while(1){
        #ifdef ONLY_ASM_FUNCTIONS
            verificar_sensor_asm();
        #elif !defined(ONLY_ASM_FUNCTIONS)
            _verificar_sensor_C();
        #endif
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
    // Verifica qual m?dulo disparou a interrup??o
    if (INTCONbits.T0IF) {
        INTCONbits.T0IF = 0; // Limpa a flag (equivalente ao bcf INTCON, 2)
        TMR0 = 6;            // Recarrega o hardware para estourar em 1 ms
        
        contador_4hz--;      // Prescaler de software
        
        if (contador_4hz == 0) {
            PORTAbits.RA0 = ~PORTAbits.RA0; // Inverte o estado do pino (Toggle)
            contador_4hz = 125;             // Reinicia a contagem dos 125 ms
        }
    }
}
#endif