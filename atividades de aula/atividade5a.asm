;Projeto de Sistemas Embarcados - FIS01237
;Instituto de Fisica - UFRGS
;Prof. Milton A Tumelero
;
;Atividade 5a: Uso de PWM com interrupt
;
;Nesta atividade, um LED na porta B3 ? acionado por um bot?o na porta D2. Ap?s o bot?o ser acionado, o led come?ar a brilhar com luminisidade que vai de 0% a 100% aumentando gradtivamente ao longo de 10 s. Ap?s isso desliga e ? acionado novamente com um novo aperto do bot?o. O bot?o deve ser configurado com un interrupt na porta INT0. 

.include m328Pdef.inc
.org 0x0000             ; 0x0000 é o início da memória de programa, que é onde o vetor de reset (início do programa) está localizado. (quando é feito um reset no programa a proxima linha a exec é config)
rjmp	config		    
.org 0x0002             ; 0x0002, é onde o vetor para a interrupção externa INT0 é localizado no ATmega328P. 0x0004 equivale ao INT1
rjmp    ISR_ext_int0    ; Quando a interrupção INT0 é acionada (por exemplo, por um evento externo como um botão pressionado), o fluxo de execução salta para ISR_ext_int0.

;.org x0034   ;garande que codigo n?o sobrepoe nenhum vetor de Interrupt.

config:
    ;configura pilha
    ldi    R16,low(RAMEND)
    out    SPL,R16
    ldi    R16,high(RAMEND)
    out    SPH,R16
    ;configura constantes iniciais
    clr    R16
    mov    R10,R16  ; R10 - registrador dedicado a guardar intensidade do LED.
    ldi    R16,38
    mov    R12,R16   ;R12 tempo de espera para avan?ar rampa de PWM. Para cada rampa duara 10s, cada unidade do counter 2 deve levar 39ms, com PS de 64 s?o necess?rios cerca de 9843=x2673 clocks.
    clr    R20       ;Define uma contante zero
    ;configura portas digitais B como saida - depurador
    ser    R16
    out    DDRB,R16
    clr    R16
    out    PORTB,R16
    ;configura porta digital D2 - Bot?o
    ldi    R16,0b0000_1_0_00
    out    DDRD,R16	     ;configura PD2 com bot�o.
    ldi    R16,0b0000_0_1_00
    out    PORTD,R16     ;configura porta D entrada 2 como pullup.
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
    ldi    R16,0b0000_00_10      ; configura ISC01 e ISC00 -> INT0
    sts    EICRA,R16             ;configura o INT0 como falling edge -> 
    ldi    R16,0b000000_0_1
    out    EIMSK,R16             ;habilita o interrupt in INT0
    sei

;inicia loop de espera bot?o
wait_interrupt:    ; SR para esperar o aperto do bot?o.
    nop     ; Confere o pino B4.
    rjmp   wait_interrupt   ;se B4 estiver normal (set) volta para check_buttom.

ISR_ext_int0:      ;interrupt com INT0 em falling edge
    clr    R16
    out    TCNT0,R16         ; limpa timer0
    rjmp   buttom_debouncig  

buttom_debouncig: ; Espera um tempo para saber se o bot?o realmente foi apertado - deboucing filter - falling edge.
    ;espera um tempo de deboucing
    in    R16,TCNT0    ;carrega o timer 0.
    cpi   R16,0x7D     ;tempo de espera para filtro do bot?o - deboucing. Com PS de 64, 500 us s?o necess?rios 125=x7D clock de timer
    brne  buttom_debouncig ;se diferente volta para buttom_delay.
    ;confirma se bot?o ainda esta apertado
    sbic   PIND,2   ; confere D2.
    reti   ;se estiver normal volta para wait_interrupt.
    rjmp   ramp_pwm

ramp_pwm:
    inc   R10         ; Increvementa R10 - n?vel de intensidade luminosa - duty cycle.
    sts   OCR2B,R10    ; envia R10 para duty cicle - comparador
    ;depurador
    out    PORTB,R10
    ;depurador
    cpse   R10,R20     ; compara R10 com zero - para saber quando voltar para o inicio.
    cpse   R10,R10
    reti  ; se R10 = 0 volta para check_buttom
    clr   R16           
    sts   TCNT1H,R16    ;limpa o timer 1H
    sts   TCNT1L,R16     ;limpa o timer 1L
    rjmp  wait_ramp

wait_ramp:
    lds   R16,TCNT1L
    lds   R16,TCNT1H   ;carrega timer 1
    cpi   R16,0x26     ;compara com R12
    breq  ramp_pwm     ; se igual segue o c?digo para ramp_pwm e increvementar novamente o DC.
    rjmp  wait_ramp    ; se diferente volta para wait_ramp   