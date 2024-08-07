.include m328Pdef.inc
.org 0x0000  

; Configura o ADC
ldi     r16, 0b01000000      ; ADLAR=1 (alinhamento à esquerda), REFS1=0, REFS0=1 (Vref = AVcc)
out     ADMUX, r16           ; Configura o ADMUX

ldi     r16, 0b10000111      ; ADEN=1 (habilita ADC), ADPS2=1, ADPS1=1, ADPS0=1 (prescaler 128)
out     ADCSRA, r16          ; Configura o ADCSRA

; Inicia a conversão
sbi     ADCSRA, ADSC         ; Configura o ADSC para iniciar a conversão

; Espera a conversão terminar
wait_conversion:
    sbic    ADCSRA, ADIF    ; Verifica o bit ADIF para ver se a conversão foi concluída
    rjmp    wait_conversion ; Se não, volta a esperar

; Lê o resultado da conversão
in      r16, ADCL          ; Lê o valor baixo
in      r17, ADCH          ; Lê o valor alto

; O valor final está em r16:r17