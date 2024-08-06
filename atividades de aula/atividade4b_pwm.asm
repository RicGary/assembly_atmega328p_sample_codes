; Projeto de Sistemas Embarcados - FIS01237
; Instituto de Fisica - UFRGS
; Prof. Milton A Tumelero
;
; Atividade 4b: Uso de PWM
;
; Nesta atividade, um LED na porta B3 e acionado por um botao na porta B4. Apos o botao ser acionado,
; o led come�ar a brilhar com luminisidade que vai de 0% a 100% aumentando gradtivamente ao longo de 10 s. 
; Ap�s isso desliga e � acionado novamente com um novo aperto do bot�o. 

.include m328Pdef.inc
.org 0x0000

; Configura pilha
ldi    R16,low(RAMEND)
out    SPL,R16
ldi    R16,high(RAMEND)
out    SPH,R16

; Configura os pinos
cbi DDRB, PB4       ; Configura PB0 como entrada (BOTÃO)
sbi PORTB, PB4      ; Ativa o resistor pull-up no PB0
sbi DDRD, PB5       ; Configura PD0 como saída (LED ou outro dispositivo de saída)
clr	R16				; Limpa R16
out	PORTD,R16	    ; limpa a porta D para saída - estado inicial desliga led

; Configura o timer do botao (debouncing)
ldi    R16,0b00_00_00_00
out    TCCR0A,R16            ; Configura modo normal = delay
ldi    R16,0b00_00_0_010     
out    TCCR0B,R16            ; Prescaler de 8, clock vai para 2.000.000
ldi    R16,0x00              
; Configura o timer do ramp 
ldi    R16,0b00_00_00_00
sts    TCCR1A,R16            ; Configura modo normal
ldi    R16,0b00_0_00_011
sts    TCCR1B,R16            ; Prescaler de 64, clock vai para 250.000

; Configura o F-PWM e PR64
ldi r16, 0b10_00_00_11  ; clear OC2A on compare match, set OC2A at BOTTOM
sts TCCR2A, r16
ldi r16, 0b0000_0_11
sts TCCR2B, r16
ldi r16, 128        ; Duty cycle 50%
sts OCR2A, r16

; Configuracoes iniciais
clr R10          ; Reg. intensidade do led
ldi r16, 125
mov r11, r16     ; R11 tempo de espera para filtro do bot�o - deboucing. Com PS de 64, 500 us s�o necess�rios 125=x7D clock de timer.
ldi r16, 38
mov r12, r16     ; R12 tempo de espera para avan�ar rampa de PWM. Para cada rampa duara 10s, cada unidade do counter 2 deve levar 39ms, com PS de 64 s�o necess�rios cerca de 9843=x2673 clocks.
clr R20          ; Cte em 0

; Rotinas do botao
check_buttom: ; SR para esperar o aperto do bot�o.
    sbic   PINB,4         ; Confere o pino B4.
    rjmp   check_buttom   ; se B4 estiver normal (set) volta para check_buttom.
    clr    R16            ; se B4 estiver apertado (clear) segue o c�digo.
    out    TCNT0,R16      ; zera o timer 0.
    rjmp   buttom_delay 

buttom_delay: ; Espera um tempo para saber se o bot�o realmente foi apertado - deboucing filter.
    in    R16, TCNT0        ; Carrega o timer 0.
    cpse  R16, R11          ; Compara com R11.
    rjmp  buttom_delay      ; Se diferente volta para buttom_delay.
    rjmp  confirm_buttom    ; Se igual vai para confirm_buttom.

confirm_buttom: ; confirma de B4 ainda esta apertado. 
    sbic   PINB,4         ; confere B4.
    rjmp   check_buttom   ; se estiver normal volta para check_buttom.
    rjmp   wait_buttom    ; se estiver apertado segue o c�digo.

wait_buttom:   ; espera bot�o ser solto
    sbis   PINB,4           ; confere B4.
    rjmp   wait_buttom      ; se ainda estiver apertado volta para wait_buttom e espera o bot�o ser solto.
    rjmp   ramp_pwm         ; se estiver normal (set) segue o c�digo.


; Inicio atividades com PWM
ramp_pwm:
    inc   R10          ; Increvementa R10 - nivel de intensidade luminosa - duty cycle.
    sts   OCR2A,R10    ; envia R10 para duty cicle - comparador
    ;Inicio depurador
    mov   R16,R10
    out   PORTD,R16
    ;final depurador
    cp    R10,R20       ; compara R10 com zero - para saber quando voltar para o inicio.
    breq  check_buttom  ; se R10 = 0 volta para check_buttom
    clr   R16           
    sts   TCNT1H,R16    ;limpa o timer 1
    sts   TCNT1L,R16
    rjmp  wait_ramp

wait_ramp:
    lds   R16,TCNT1L
    lds   R16,TCNT1H   ;carrega timer 1
    cpse  R16,R12     ;compara com R12
    rjmp  wait_ramp   ; se diferente volta para wait_ramp
    rjmp  ramp_pwm    ; se igual segue o c�digo para ramp_pwm e increvementar novamente o DC.