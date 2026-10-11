/*
 * File:   questao3.c
 * Author: bande
 * FILA DE PRIORIDADES
 * Created on 7 de Outubro de 2026, 22:01
 */


#include <xc.h>
#include "config_pic.h"

    
// Botões em pull-up
#define patioA !P(A, 1)
#define patioB !P(A, 2)
#define patioC !P(A, 3)
#define patioD !P(A, 4)


extern void portas_settings_asm(void);
#ifdef ONLY_ASM_FUNCTIONS
   extern void verificar_prioridade_asm(void);
#elif !defined(ONLY_ASM_FUNCTIONS)
    void _verificar_prioridade_C(void);
    void _limpar_correia(void);
#endif
    
int main(void) {

    portas_settings_asm();
    
    while (1){

        #ifdef ONLY_ASM_FUNCTIONS
            verificar_prioridade_asm();
        #elif !defined(ONLY_ASM_FUNCTIONS)
            _limpar_correia();
            _verificar_prioridade_C();
        #endif
        
    }
    
    return 0;
}

#ifndef ONLY_ASM_FUNCTIONS
void _verificar_prioridade_C(void){
    
    if (patioA){
        P(B, 0) = 1;
    }
    else if (patioB){
        P(B, 1) = 1;
    }
    else if (patioC){
        P(B, 2) = 1;
    }
    else if (patioD){
        P(B, 3) = 1;
    }
    
}

void _limpar_correia(void){
    P(B, 0) = 0; P(B, 1) = 0;
    P(B, 2) = 0; P(B, 3) = 0;
}
#endif
