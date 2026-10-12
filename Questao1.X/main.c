#include <xc.h>

#define _XTAL_FREQ 4000000 // Frequencia do cristal (4 MHz)


#pragma config FOSC = XT   // Oscilador a cristal
#pragma config WDTE = OFF  // Watchdog Timer desativado
#pragma config PWRTE = OFF // Power-up Timer desativado
#pragma config CP = OFF    // Protecao de codigo desativada

volatile unsigned char interrupt_count = 0; // Contador de estouros do Timer0

// Rotina de Interrupcao em C (executa em segundo plano a cada ~62.5 ms)
void __interrupt() tmr0Int(void) {
    if (INTCONbits.T0IF) {
        INTCONbits.T0IF = 0; // Limpa a flag de interrupção
        TMR0 = 12;           // Recarrega Timer0 para ~62.5 ms
        
        interrupt_count++;
        if (interrupt_count == 2) { // 2 x 62.5 ms = 125 ms (4 Hz)
            interrupt_count = 0;
            PORTAbits.RA0 = !PORTAbits.RA0; // Inverte o pino RA0
        }
    }
}

void main(void) {
    // Configuracao de Portas (1 = Entrada, 0 = saida)
    TRISA = 0b00000010; // RA1 entrada (sensor), RA0 saida (clock)
    TRISB = 0b00000000; // PORTB inteira como saída (LEDs)

    PORTA = 0x00;
    PORTB = 0x00;

    // Configuração do Timer0 (Prescaler 1:256)
    OPTION_REGbits.T0CS = 0; // Clock interno
    OPTION_REGbits.PSA = 0;  // Prescaler associado ao Timer0
    OPTION_REGbits.PS0 = 1;  // Prescaler configurado para 1:256
    OPTION_REGbits.PS1 = 1;
    OPTION_REGbits.PS2 = 1;

   
    INTCONbits.T0IE = 1; // Habilita interrupção do Timer0
    INTCONbits.GIE = 1;  // Habilita interrupções globais

    while(1) {
        if (PORTAbits.RA1 == 1) {
            PORTB = 0x72;
        } else {
            PORTB = 0x81;
        }
    }
}