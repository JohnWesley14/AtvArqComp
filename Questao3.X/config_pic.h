/* 
 * File:   config_pic.h
 * Author: bande
 *
 * Created on 7 de Outubro de 2026, 22:08
 */

#ifndef CONFIG_PIC_H
#define	CONFIG_PIC_H

#include <stdint.h>

#ifdef	__cplusplus
extern "C" {
#endif
    
#define P(N, X) PORT##N##bits.R##N##X // P(A, 1) = PORTAbits.RA1

typedef int8_t i8;
typedef int16_t i16;
typedef int32_t i32;
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef unsigned char uchar;


#ifdef	__cplusplus
}
#endif

#endif	/* CONFIG_PIC_H */

