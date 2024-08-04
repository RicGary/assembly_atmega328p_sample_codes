.include "m328pdef.inc"  ; Inclui o arquivo de definição do ATmega328P

.org 0x0000              ; Define o endereço de início do programa

.equ TIMER_VALUE_HIGH = 0x3D
.equ TIMER_VALUE_LOW  = 0xB9

; Configura a pilha
ldi r16, high(RAMEND) ; Carrega o byte mais significativo do endereço de RAMEND em r16
out SPH, r16          ; Armazena o byte mais significativo do endereço de RAMEND no registrador SPH
ldi r16, low(RAMEND)  ; Carrega o byte menos significativo do endereço de RAMEND em r16
out SPL, r16          ; Armazena o byte menos significativo do endereço de RAMEND no registrador SPL

; Configura os pinos
ser r16 
out DDRD, r16   ; Configura todos os pinos como saida
ser r16
out PORTD, r16  ; Configura pull-up na Dx

; Configura o timer 
ldi r16, 0b00_00_00_00
sts TCCR1A, r16
ldi r16, 0b00_0_00_101  ; Prescaler de 1024, levando clock para 15.625 Hz
sts TCCR1B, r16
ldi r16, low(TIMER_VALUE_LOW)     ; Valor escolhido para cada ciclo levar 1s
sts OCR1AL, r16
ldi r16, high(TIMER_VALUE_HIGH)
sts OCR1AH, r16

; Comeca a piscar os leds
main_loop:
    lds r17, TCNT1L
    lds r16, TCNT1H

    ; Verifica se o timer chegou nos valores
    cpi r16, high(TIMER_VALUE_HIGH)    ; Compara a parte alta do valor, se o resultado for zero aciona o flag (Z)
    brne main_loop
    cpi r17, low(TIMER_VALUE_LOW)     ; Subtrai a parte low do valor da parte low do timer e levanta uma flag
    brlo main_loop          ; Pula para loop se TCNT1L < low(15625) pois seta flag Carry 

    ; Altera o estado dos leds
    in r16, PORTD           ; Le o valor da portaD (leds)
    com r16                 ; Inverte o valor de todos os bits
    out PORTD, r16          ; Atualiza o estado do led

    clr r16
    sts TCNT1L, r16
    sts TCNT1H, r16
    rjmp main_loop

        