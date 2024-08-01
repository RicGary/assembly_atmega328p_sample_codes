.include m328Pdef.inc
.org 0x0000

; Configura a pilha
ldi r16, high(RAMEND)   ; Carrega o byte mais significativo do endereço de RAMEND em r16
out SPH, r16            ; Armazena o byte mais significativo do endereço de RAMEND no registrador SPH
ldi r16, low(RAMEND)    ; Carrega o byte menos significativo do endereço de RAMEND em r16
out SPL, r16            ; Armazena o byte menos significativo do endereço de RAMEND no registrador SPL

; Configura os pinos    
cbi DDRB, PB0          ; Configura PB0 como entrada (BOTÃO)
sbi PORTB, PB0         ; Ativa o resistor pull-up no PB0
sbi DDRD, PD0          ; Configura PD0 como saída (LED ou outro dispositivo de saída)

; Espera apertar botao
loop:
sbic PINB, PB0         ; Verifica se PB0 esta pressionado
rjmp led_off
sbi  PORTD, PD0        ; Seta pull-up no PD0 (Liga o led)
rjmp loop

led_off:
cbi PORTD, PD0         ; Seta pull-down no PD0 (Desliga o led)
rjmp loop
