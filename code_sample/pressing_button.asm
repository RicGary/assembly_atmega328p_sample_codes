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

clr r19                ; Constante
clr r20                ; Vai controlar se o botao esta ligado ou nao
ldi r23, 1             ; Usado para somar 

wait:   ; Espera o botão ser apertado
sbic PINB, PB0         ; Verifica se o botão na porta PB0 foi pressionado 
rjmp wait

; Debouncing
ldi r21, 255             ; Contador do filtro
filter_delay:
dec  r21
brne filter_delay

check_button:
sbic PINB, PB0         ; Verifica se o botão na porta PB0 foi pressionado 
rjmp wait

led_control:
clr r22
cpse r19, r20
rjmp led_off
rjmp led_on

led_on:
inc r20
sbi PORTD, PD0         ; Seta pull-down no PD0 (Desliga o led)
rjmp wait

led_off:
dec r20
cbi PORTD, PD0         ; Seta pull-down no PD0 (Desliga o led)
rjmp wait