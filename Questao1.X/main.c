//#include <xc.h>
//
//// Configuração do clock exigido pela questão: 4 MHz
//#define _XTAL_FREQ 4000000
////#define MY_INTERRUPT_C
//
////// Configurações do PIC (Configuration Bits) necessárias para funcionar no simulador/hardware
////#pragma config FOSC = XT  // Oscilador a Cristal (para 4 MHz)
////#pragma config WDTE = OFF // Watchdog Timer desativado
////#pragma config PWRTE = ON // Power-up Timer ativado
////#pragma config CP = OFF   // Proteção de código desativada
//
//void main(void) {
//
//
//    // 2. LOOP INFINITO (Verificação contínua)
//    while(1) {
//        
//        // --- PARTE A: Verificação do Sensor A[cite: 1] ---
//        // Verifica o pino RA1
//        if (PORTAbits.RA1 == 1) {
//            PORTB = 0x72; // Se for 1, envia 0x72 pela porta B[cite: 1]
//        } else {
//            PORTB = 0x81; // Caso contrário, envia 0x81 pela porta B[cite: 1]
//        }
//
//        // --- PARTE B: Sinal Quadrado de 4 Hz no pino RA0[cite: 1] ---
//        // A frequência é de 4 Hz, o que significa 4 ciclos completos por segundo.
//        // Um ciclo completo dura 1/4 = 0,25 segundos = 250 milissegundos.
//        // O sinal quadrado passa metade do tempo em nível alto (1) e metade em baixo (0).
//        // Portanto: 125 ms ligado e 125 ms desligado.
//        
//        PORTAbits.RA0 = 1; // Coloca o sinal em nível alto
//        __delay_ms(125);   // Espera 125 milissegundos
//        
//        // (Opcional) Lemos o sensor de novo no meio do ciclo para garantir uma 
//        // resposta mais rápida caso o botão seja solto, mantendo a verificação contínua[cite: 1]
//        if (PORTAbits.RA1 == 1) {
//            PORTB = 0x72;
//        } else {
//            PORTB = 0x81;
//        }
//
//        PORTAbits.RA0 = 0; // Coloca o sinal em nível baixo
//        __delay_ms(125);   // Espera 125 milissegundos
//    }
//}