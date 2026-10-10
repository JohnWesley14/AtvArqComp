/*
 * File:   questao1.c
 * Author: bande
 *
 * Created on 7 de Outubro de 2026, 22:14
 */

/* 
 PORTAS E TIMER
 PA1 é um botão pull-up, portanto PA1 é default = 1
 if(PA1 == 1){ PB = 0x72 } else { PB = 0x81 }
 PA0 = 1 // A cada 4 Hz
 PA1 é input, PA0 e PB é output
*/

#include <xc.h>
#include "config_pic.h"


extern void portas_settings_asm(void);
extern void verificar_sensor_asm(void);
void _verificar_sensor_C(void);

int main(void) {
    portas_settings_asm();
    
    while(1){
        _verificar_sensor_C();
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
