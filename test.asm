;Projeto de Sistemas Embarcados - FIS01237
;Instituto de Fisica - UFRGS
;Prof. Milton A Tumelero
;
;Atividade 4b: Uso de PWM
;
;Nesta atividade, um LED na porta B5 � acionado por um bot�o na porta B4. Ap�s o bot�o ser acionado, o led come�ar a brilhar com luminisidade que vai de 0% a 100% aumentando gradtivamente ao longo de 10 s. Ap�s isso desliga e � acionado novamente com um novo aperto do bot�o. 

.include m328Pdef.inc
.org 0x0000
rjmp	inicio		;vai para SR inicio

inicio:
;configura pilha
ldi    R16,low(RAMEND)
out    SPL,R16
ldi    R16,high(RAMEND)
out    SPH,R16
;chama subrotinas de configura��o
call   config_pin
call   config_tim_delay
call   config_pwm
;define constantes iniciais
clr    R16
mov    R10,R16  ; R10 � registrador dedicado a guardar intensidade do LED.
ldi    R16,0x7D
mov    R11,R16  ; R11 tempo de espera para filtro do bot�o - deboucing. Com PS de 64, 500 us s�o necess�rios 125=x7D clock de timer.
ldi    R16,0x26
mov    R12,R16   ;R12 tempo de espera para avan�ar rampa de PWM. Para cada rampa duara 10s, cada unidade do counter 2 deve levar 39ms, com PS de 64 s�o necess�rios cerca de 9843=x2673 clocks.
clr    R20       ;Define uma contante zero
rjmp   check_buttom

check_buttom:    ; SR para esperar o aperto do bot�o.
sbic   PINB,4     ; Confere o pino B4.
rjmp   check_buttom   ;se B4 estiver normal (set) volta para check_buttom.
clr    R16            ;se B4 estiver apertado (clear) segue o c�digo.
out    TCNT0,R16      ;zera o timer 0.
rjmp   buttom_delay   

buttom_delay: ; Espera um tempo para saber se o bot�o realmente foi apertado - deboucing filter.
in    R16,TCNT0    ;carrega o timer 0.
cpse  R16,R11     ;compara com R11.
rjmp  buttom_delay ;se diferente volta para buttom_delay.
rjmp  confirm_buttom  ;se igual vai para wait_buttom.

confirm_buttom: ; confirma de B4 ainda esta apertado. 
sbic   PINB,4   ; confere B4.
rjmp   check_buttom   ;se estiver normal volta para check_buttom.
rjmp   wait_buttom    ;se estiver apertado segue o c�digo.

wait_buttom:   ; espera bot�o ser solto
sbis   PINB,4   ; confere B4.
rjmp   wait_buttom  ;se ainda estiver apertado volta para wait_buttom e espera o bot�o ser solto.
rjmp   ramp_pwm   ;se estiver normal (set) segue o c�digo.

ramp_pwm:
inc   R10         ; Increvementa R10 - n�vel de intensidade luminosa - duty cycle.
sts   OCR2A,R10    ; envia R10 para duty cicle - comparador
;Inicio depurador
mov    R16,R10
out    PORTD,R16
;final depurador
cp    R10,R20     ; compara R10 com zero - para saber quando voltar para o inicio.
breq  check_buttom  ; se R10 = 0 volta para check_buttom
clr   R16           
sts   TCNT1H,R16    ;limpa o timer 1
sts   TCNT1L,R16
rjmp   wait_ramp

wait_ramp:
lds   R16,TCNT1L
lds   R16,TCNT1H   ;carrega timer 1
cpse   R16,R12     ;compara com R12
rjmp   wait_ramp   ; se diferente volta para wait_ramp
rjmp   ramp_pwm    ; se igual segue o c�digo para ramp_pwm e increvementar novamente o DC.

;Rotinas de Configura��o

config_pin:
;Configura depurador
ldi    R16,0xff
out    DDRD,R16
clr    R16
out    PORTD,R16
;final configuração depurador
ldi    R16,0b000_0_0000
out    DDRB,R16	     ;configura PB4 com botão.
ldi    R16,0b000_1_0000
out    PORTB,R16     ;configura porta de entrada 4 como pullup.
ret

config_tim_delay:
;configura timer 0 - delay para deboucing do bot�o
ldi    R16,0b00_00_00_00
out    TCCR0A,R16            ;Configura modo normal = delay
ldi    R16,0b00_00_0_010
out    TCCR0B,R16            ;Configura clk com prescaler de PS64 = 011 ou PS8 = 010.
ldi    R16,0x00
;configura timer 1 - Delay ramp
ldi    R16,0b00_00_00_00
sts    TCCR1A,R16            ;Configura modo normal
ldi    R16,0b00_0_00_011
sts    TCCR1B,R16            ;Configura clk com  PS64 = 011 ou PS8 = 010
ret

config_pwm:
ldi    R16,0b10_00_00_11
sts    TCCR2A,R16            ;Configura modo FPWM
ldi    R16,0b00_0_00_011
sts    TCCR2B,R16            ;Configura clk com prescaler de 256 = ~240Hz = 110 ou PS32 = ~1450 Hz = 011
ldi    R16,0x80
sts    OCR2A,R16
ret