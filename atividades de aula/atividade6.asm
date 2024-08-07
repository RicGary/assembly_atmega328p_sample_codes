;Projeto de Sistemas Embarcados - FIS01237
;Instituto de Fisica - UFRGS
;Prof. Milton A Tumelero
;
;Atividade 6b: Uso de ADC para controlar tempo da rampa de incremento do led;


; Nesta atividade, um bot�o configurado com interrupt INT0 liga um LED durante um tempo de 5 s. A intensidade luminosa do LED 
; e ser� controlado por um potenciometro externo conectado a uma porta do ADC.

.include m328Pdef.inc
.org 0x0000
rjmp	config		;vai para SR config
.org 0x0002
rjmp    ISR_ext_int0

;.org x0034   ;garande que codigo n?o sobrepoe nenhum vetor de Interrupt.

config:
;configura pilha
ldi    R16,low(RAMEND)
out    SPL,R16
ldi    R16,high(RAMEND)
out    SPH,R16

;configura constantes iniciais
clr    R20       ;Define uma contante zero
;configura portas digitais B como saida - depurador
ldi    R16,0xff
out    DDRB,R16
clr    R16
out    PORTB,R16

;configura porta digital D2 - Bot?o
ldi    R16,0b0000_1_0_00
out    DDRD,R16	            ;configura PD2 com bot�o.
ldi    R16,0b0000_0_1_00
out    PORTD,R16            ;configura porta D entrada 2 como pullup.

;configura timer0 delay para deboucing
ldi    R16,0b00_00_00_00
out    TCCR0A,R16            ;Configura modo normal = delay
ldi    R16,0b00_00_0_010
out    TCCR0B,R16            ;Configura clk com prescaler de PS64 = 011 ou PS8 = 010.

;configura timer1 delay rampa PWM
ldi    R16,0b00_00_00_00
sts    TCCR1A,R16            ;Configura modo normal
ldi    R16,0b00_0_00_011
sts    TCCR1B,R16            ;Configura clk com  PS64 = 011 ou PS8 = 010

;configura timer2 pwm - comparador B - PD3
ldi    R16,0b10_10_00_11
sts    TCCR2A,R16            ;Configura modo FPWM
ldi    R16,0b00_0_00_011
sts    TCCR2B,R16            ;Configura clk com prescaler de 256 = ~240Hz = 110 ou PS32 = ~1450 Hz = 011
ldi    R16,0x80
sts    OCR2B,R16             ;configura valor inicial para duty cicle

;configura interrupt INT0
ldi    R16,0b0000_00_10
sts    EICRA,R16             ;configura o INT0 como falling edge
ldi    R16,0b000000_0_1
out    EIMSK,R16             ;habilita o interrupt in INT0
sei

;configura ADC
ldi    R16,     0b01_1_0_0001
sts    ADMUX,   R16            ; configura Vref = Vcc, Justifica para esquerda (8bits), Mux no ch 1.
ldi    R16,     0b1_1_1_00_101
sts    ADCSRA,  R16            ; configura ADC on, inicia convers�o no ADSC, usa autotrigger, e prescaler 32x
ldi    R16,     0b00000_000
sts    ADCSRB,  R16            ; configura autotrigger em free running

;inicia loop de espera bot?o
wait_interrupt: ; SR para esperar o aperto do bot?o.
    nop                     ; Confere o pino B4.
    rjmp   wait_interrupt   ;se B4 estiver normal (set) volta para check_buttom.

ISR_ext_int0: ;interrupt com INT0 em falling edge
    clr    R16
    out    TCNT0,R16         ; limpa timer0
    rjmp   buttom_debouncig  

buttom_debouncig: ; Espera um tempo para saber se o bot?o realmente foi apertado - deboucing filter - falling edge.
    ;espera um tempo de deboucing
    in    R16,TCNT0         ;carrega o timer 0.
    cpi   R16,0x7D          ;tempo de espera para filtro do bot?o - deboucing. Com PS de 64, 500 us s?o necess?rios 125=x7D clock de timer
    brne  buttom_debouncig  ;se diferente volta para buttom_delay.

    ;confirma se bot?o ainda esta apertado
    sbic   PIND,2       ; confere D2.
    reti                ;se estiver normal volta para wait_interrupt.
    clr    R18          ;limpa R18 para servir de contador de ciclo
    rjmp   update_pwm

update_pwm:
    inc    R18
    lds    R17,ADCL     ; ler adc low
    lds    R17,ADCH     ; ler adc high
    sts    OCR2B,R17    ; envia R10 para duty cicle - comparador
    ;depurador
    out    PORTB,R17
    ;depurador
    cpse   R18,R20          ; compara R10 com zero - para saber quando voltar para o inicio.
    cpse   R18,R18  
    rjmp   finish           ; se R18 = 0 vai para SR finish
    clr   R16           
    sts   TCNT1H,R16        ;limpa o timer 1H
    sts   TCNT1L,R16        ;limpa o timer 1L
    rjmp  wait_ramp

wait_ramp:
    lds   R16,TCNT1L    ; nao e necessario ler 
    lds   R16,TCNT1H    ; carrega timer 1
    cpi   R16,0x15      ; tempo de espera com pwm e LED ligado. Para 10 s, 256 clicos no update_pwm (R18), cada ciclo do update_pwm deve levar levar 39ms, no timer 1 com PS de 64 sao necessarios cerca de 9750=x2616 clocks, ou apenas 0x26 na compara��o com TCNT1H. 
    breq  update_pwm    ; se igual segue o codigo para ramp_pwm e increvementar novamente o DC.
    rjmp  wait_ramp     ; se diferente volta para wait_ramp 

finish:
    sts    OCR2B,R20
    reti