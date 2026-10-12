#include <xc.h>
#define _XTAL_FREQ 4000000

#pragma config FOSC = XT
#pragma config WDTE = OFF
#pragma config PWRTE = ON
#pragma config CP = OFF

void main(void) {
    TRISA = 0b00011110; // RA1 a RA4 como entradas
    TRISB = 0b00000000; // PORTB inteira como saída

    PORTA = 0x00;
    PORTB = 0x00;

    while(1) {
        
        if (PORTAbits.RA1 == 0) {
            PORTB = 0b00000001; // Prioridade 1: Pátio A (RB0)
        } else if (PORTAbits.RA2 == 0) {
            PORTB = 0b00000010; // Prioridade 2: Pátio B (RB1)
        } else if (PORTAbits.RA3 == 0) {
            PORTB = 0b00000100; // Prioridade 3: Pátio C (RB2)
        } else if (PORTAbits.RA4 == 0) {
            PORTB = 0b00001000; // Prioridade 4: Pátio D (RB3)
        } else {
            PORTB = 0x00;       
        }
    }
}