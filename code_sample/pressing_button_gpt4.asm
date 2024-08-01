.include m328Pdef.inc
.org 0x0000

; Configura a pilha
ldi r16, high(RAMEND)
out SPH, r16
ldi r16, low(RAMEND)
out SPL, r16

; Configura os pinos    
cbi DDRB, PB0          ; Configura PB0 como entrada (BOTÃO)
sbi PORTB, PB0         ; Ativa o resistor pull-up no PB0
sbi DDRD, PD0          ; Configura PD0 como saída (LED)

; Variáveis de controle
ldi r22, 0             ; Contador do filtro

wait:
sbic PINB, PB0
rjmp wait              ; Se botão não pressionado, continua esperando

; Debouncing
ldi r22, 10            ; Inicializa contador do debounce
debounce_loop:
dec r22                ; Decrementa contador
brne debounce_loop     ; Se contador não zero, repete

; Verifica novamente o botão
sbic PINB, PB0
rjmp wait              ; Se botão solto durante debounce, volta a esperar

; Controle do LED
in r16, PORTD          ; Lê o estado atual de PORTD
eor r16, (1 << PD0)    ; Toggla o estado do PD0
out PORTD, r16         ; Atualiza o estado de PORTD
rjmp wait              ; Retorna ao loop de espera