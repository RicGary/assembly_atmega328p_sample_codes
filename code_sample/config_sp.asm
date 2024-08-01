.include "m328pdef.inc"  ; Inclui o arquivo de definição do ATmega328P

.org 0x0000              ; Define o endereço de início do programa

; Configura a pilha
ldi r16, high(RAMEND) ; Carrega o byte mais significativo do endereço de RAMEND em r16
out SPH, r16          ; Armazena o byte mais significativo do endereço de RAMEND no registrador SPH
ldi r16, low(RAMEND)  ; Carrega o byte menos significativo do endereço de RAMEND em r16
out SPL, r16          ; Armazena o byte menos significativo do endereço de RAMEND no registrador SPL