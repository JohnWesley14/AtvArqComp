movvf MACRO var, reg
    movf var, 0 ; move o var (tratado como reg) para reg
    movwf reg
endm

movlf MACRO lit, reg
    movlw lit ; move o lit para port
    movwf reg
endm

xorlf MACRO lit, reg, bit
    movlw lit ; move o var para port
    xorwf reg, bit
endm
    
iorlf MACRO lit, reg, bit
    movlw lit ; move o var para port
    iorwf reg, bit
endm
    
_salvar_contexto MACRO
    movwf   W_TEMP
    swapf   STATUS, 0
    movwf   STATUS_TEMP
endm
    
_retornar_contexto MACRO
    swapf   STATUS_TEMP, 0
    movwf   STATUS
    swapf   W_TEMP, 1
    swapf   W_TEMP, 0
endm
    


