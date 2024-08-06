.include "m328pdef.inc"  ; Inclui o arquivo de definição do ATmega328P

.org 0x0000              ; Define o endereço de início do programa

.equ TIMER_VALUE = 15625

; Configura a pilha
ldi r16, high(RAMEND) ; Carrega o byte mais significativo do endereço de RAMEND em r16
out SPH, r16 ; Armazena o byte mais significativo do endereço de RAMEND no registrador SPH
ldi r16, low(RAMEND) ; Carrega o byte menos significativo do endereço de RAMEND em r16
out SPL, r16 ; Armazena o byte menos significativo do endereço de RAMEND no registrador SPL

; Configura os pinos
ser r16
out DDRD, r16 ; Configura todos os pinos como saida
ser r16
out PORTD, r16 ; Configura pull-up na Dx

; Configura o timer
ldi r16, 0b00_00_00_00
sts TCCR1A, r16
ldi r16, 0b00_0_00_101 ; Prescaler de 1024, levando clock para 15.625 Hz
sts TCCR1B, r16
ldi r16, high(TIMER_VALUE)
sts OCR1AH, r16           ; Sempre escrever primeiro valor alto e depois o valor baixo, para ler e o contrario
ldi r16, low(TIMER_VALUE) ; Valor escolhido para cada ciclo levar 1s
sts OCR1AL, r16


; Comeca a piscar os leds
main_loop:
    sbis TIFR1, 1       ; Reg responsavel por setar a flag do OCRnx quando o timer chegar no valor marcado
    rjmp main_loop

    ; Altera o estado dos leds
    in r16, PORTD       ; Le o valor da portaD (leds)
    com r16             ; Inverte o valor de todos os bits
    out PORTD, r16      ; Atualiza o estado do led

    clr r16
    sts TCNT1H, r16
    sts TCNT1L, r16
    cbi TIFR1, 1
    rjmp main_loop