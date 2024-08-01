;Projeto de Sistemas Embarcados - FIS01237
;Instituto de Fisica - UFRGS
;Prof. Milton A Tumelero
;
;Atividade 4a: Piscar led com Timers
;
;Nesta atividade o objetivo � fazer um led piscar, com tempo toff e outro tempo ton, utilizando timers e um bot�o de liga e desliga.
.include m328Pdef.inc
.org 0x0000

ldi  R16,low(RAMEND)            ; configura pilha em RAMEND
out  SPL,R16
ldi  R16,high(RAMEND)
out  SPH,R16

call  config_pins  ; chama subrotina config_pins
call  config_timer ; chama rotina de configura��o do timer

clr  R13                ; Limpa R13 - contador delay
clr  R20                ; limpa R20 - registrador de controle de bot�o
clr  R21                ; limpa R21 - registrador de controle de led
clr  R22                ; constante R22 = 0
ldi  R16,0xff
mov  R14,R16            ; R14 = 0xff - reg. de compara��o delay

wait:                   ; Espera bot�o ser apertado
sbis  PINB,0            ; Confere se porta B0 est� apertada - no estado low
rjmp  filter_delay      ; "se" sim - vai para SR filter_delay
sbrc  R20,0             ; "se" bot�o n�o esta apertado, confere estado do led
rjmp  LED_state         ; "se" estad do led � piscando ent�o vai para led state
rjmp  wait              ; "se" n�o - ent�o volta para SR wait

filter_delay:           ; Espera R14 ciclos de clock - 255 * Tclock
inc   R13               ; Soma R12 (um) no contador R13
cpse  R13,R14           ; Compara R13 - contagem atual com R14 - contagem m�xima
rjmp  filter_delay      ; "se" desigual retorna para filter_delay
rjmp  filter_check_button      ; "se" igual ent�o vai para check_button

filter_check_button:    ; Confere se o bot�o continua apertado
clr   R13
sbic  PINB,0            ; Confere se porta b3 est� apertada - no estado low
rjmp  wait              ; "se" n�o - ent�o volta para SR wait
rjmp  button            ; "se" sim - vai para SR filter_delay

button:                 ; Analisa a fun��o do bot�o
cpse  R20,R22           ; compara R20 e R22=0
rjmp  led_off           ; "se" R20 = 1 led esta ligado e bot�o vai desligar vai para led_off
rjmp  led_blink         ; "se" R20 = 0 o led esta desligado e o bot�o vai ligar, vai para led_on

led_off:                ; Rotina para desligar LED
dec  R20                ;Leva R20 para 0 - indicador que esta desligado
clr  R16                ; Limpa R16
out  PORTD,R16          ; seta low nsa saida da porta D         ;
rjmp filter_reset       ;Vai para filter_reset

led_blink:             ; Rotina para ligar o LED
inc  R20               ; leva R20 para 1 - indicador que o led esta aceso
rjmp filter_reset      ; vai para filter_reset

filter_reset:       ; Filtro para confirmar que bot�o foi solto
sbis  PINB,3          ; confere o estado do pino B3 o bot�o
rjmp  filter_reset     ; "se" esta low - continua apertado - volta para filter_reset
rjmp  wait             ; "se" esta high - foi solto - vai para wait

LED_state:               ; define o estado do led piscando
sbrs  R21,0              ; confere estado do led
rjmp  led_blink_on       ; "se" led esta off ent�o liga
rjmp  led_blink_off      ; "se" led esta on ent�o desliga

led_blink_on:          ; liga led
inc  R21               ; incrementa R21 - indica que led foi ligado
ser  R16               ; seta R16
out  PORTD,R16         ; seta high nsa saida da porta D
call reset_timer       ; Reseta timer
ldi  R16,0x40          ; Ajusta compara��o do timer - tempo on
rjmp wait_blink        ; vai para wait_blink

led_blink_off:         ; desliga led
dec  R21               ; decrementa R21 - indica que led foi desligado
clr  R16               ; Limpa R16
out  PORTD,R16         ; seta low nsa saida da porta D
call reset_timer       ; Reseta timer
ldi  R16,0x20          ; Ajusta compara��o do timer - tempo off
rjmp wait_blink        ; vai para wait_blink

wait_blink:            ; espera led para piscar
lds  R18,TCNT1L        ; leiruta do TCNT1L
lds  R17,TCNT1H        ; leitura do TCNT1H
cpse R16,R17           ; compara com tempo
rjmp wait_blink        ; "se" n�o passou tempo volta para wait_blink
rjmp wait              ; "se" passou o tempo volta para wait

config_pins:        ; configuras as portas IO
cbi DDRB, PB0       ; Configura PB0 como entrada (BOTÃO)
sbi PORTB, PB0      ; Ativa o resistor pull-up no PB0
sbi DDRD, PD0       ; Configura PD0 como saída (LED ou outro dispositivo de saída)
clr	R16				; Limpa R16
out	PORTD,R16	    ; limpa a porta D para saída - estado inicial desliga led
ret                 ; retorna para call

config_timer:
ldi  R16,0b00_00_00_00
sts  TCCR1A,R16            ;Configura modo normal sem portas OC
ldi  R16,0b00_0_00_101
sts  TCCR1B,R16            ;Configura clk com prescaler de 1024
ldi  R16,0x0a              ; Ajusta R16 para 10
sts  OCR1AH,R16            ;Ajusta o comparador A high do timer 1 para 10
clr  R16                   ; Limpar R16
sts  OCR1AL,R16            ;Ajusta o comparador A low do timer 1 para 0
ret

reset_timer:
clr  R16               ; Limpa R16
sts  TCNT1H,R16        ; Limpa timer 1H
sts  TCNT1L,R16        ; Limpa timer 1L
ret