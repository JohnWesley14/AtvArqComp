#include <xc.h>
#define _XTAL_FREQ 4000000

#pragma config FOSC = XT
#pragma config WDTE = OFF
#pragma config PWRTE = ON
#pragma config CP = OFF

void main(void) {
    // Configura RA1, RA2, RA3 e RA4 como entradas (bit 1 em '1')
    TRISA = 0b00011110; 
    // Configura toda a porta B como saída
    TRISB = 0b00000000; 

    PORTA = 0x00;
    PORTB = 0x00;

    while(1) {
        if (PORTAbits.RA1 == 1) {
            PORTB = 0b00000001; // Prioridade 1: Pátio A liga RB0
        } else if (PORTAbits.RA2 == 1) {
            PORTB = 0b00000010; // Prioridade 2: Pátio B liga RB1
        } else if (PORTAbits.RA3 == 1) {
            PORTB = 0b00000100; // Prioridade 3: Pátio C liga RB2
        } else if (PORTAbits.RA4 == 1) {
            PORTB = 0b00001000; // Prioridade 4: Pátio D liga RB3
        } else {
            PORTB = 0x00;       // Desliga todas as saídas
        }
    }
}