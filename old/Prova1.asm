;Projeto de Sistemas Embarcados - FIS01237
;Instituto de Fisica - UFRGS
;Prof. Milton A Tumelero

;Prova 1

; Enunciado

; Desenvolver um controle para luminosidade de uma lampada. 
; A lampada deve possuir 5 niveis distintos de luminosidade, 
; um desligado e quatro niveis com aumento gradativo. O controle do nivel
; ser� realizado por um unico botao. A cada aperto do bota aumenta um nivel de luminosidade.
; se o botao ficar apertado por aproximadamente 3 segundo a lampada desliga e o proximo aperto
; leva para o nivel de luminosidade mais baixo.
; Lembre que todas as linhas devem estar devidamente comentadas, inclusive as subrotinas.
; O programa deve ser desenvolvido sem o uso das instrucoes call (rcall e icall)

; Solucao:

; Detalhamento do Codigo
; Detalhe aqui as configuracoes de hardware a serem utilizadas, 
; portas de entrada, porta de saida, e outros perifericos a serem 
; utilizados e suas respectivas configuracoes. De uma breve descricao 
; sobre a estrutura escolhida para o desenvolvimento do programa.

; Inicio do Codigo

.include m328Pdef.inc
.org 0x0000     


;configura pilha
ldi    R16,low(RAMEND)
out    SPL,R16
ldi    R16,high(RAMEND)
out    SPH,R16


;chama subrotinas de configuracao
ldi    R16,0b000_0_0000
out    DDRB,R16      ;configura entrada

ldi    R16,0b000_1_0000
out    PORTB,R16     ;configura PB4 com pull-up

ldi    R16,0b00_00_00_00
out    TCCR0A,R16    ;configura timer 0 no modo normal

ldi    R16,0b00_00_0_010
out    TCCR0B,R16    ;configura timer 0 com prescaler de PS8 
; PS8  2 MHz (16 MHz / 8 = 2 MHz)

ldi    R16,0b00_00_00_00
sts    TCCR1A,R16    ;configura timer 1 no modo normal

ldi    R16,0b00_0_00_010
sts    TCCR1B,R16    ;configura timer 1 com prescaler de PS8

ldi    R16,0b10_00_00_11
sts    TCCR2A,R16    ;configura timer 2 no modo FPWM

ldi    R16,0b00_0_00_010
sts    TCCR2B,R16    ;configura timer 2 com prescaler de PS8

ldi    R16,0x80
sts    OCR2A,R16     ;configura OCR2A para 50% de duty cycle

clr    R16
out    PORTD,R16    ;configura PORTD como saida

clr    R10          ;R10 guarda o nivel de luminosidade
ldi    R16,0x7D

mov    R11,R16      ;R11 guarda o tempo de espera para filtro do botao - debouncing
ldi    R16,0x26

mov    R12,R16      ;R12 guarda o tempo de espera para avancar rampa de PWM
clr    R20          ;R20 guarda a constante zero
rjmp   check_button


check_button:       ;SR para esperar o aperto do botao
sbic   PINB,4       ;Confere o pino B4
rjmp   check_button ;Se B4 estiver normal (set), volta para check_button
clr    R16          ;Se B4 estiver apertado (clear), segue o codigo
out    TCNT0,R16    ;Zera o timer 0
rjmp   button_delay


button_delay:       ;Espera um tempo para saber se o botao realmente foi apertado
in     R16,TCNT0    ;Carrega o timer 0
cpse   R16,R11      ;Compara com R11
rjmp   button_delay ;Se diferente, volta para button_delay
rjmp   confirm_button ;Se igual, vai para confirm_button


confirm_button:     ;Confirma se B4 ainda esta apertado
sbic   PINB,4       ;Confere B4
rjmp   check_button ;Se estiver normal, volta para check_button
;Se for pressionado por 3 segundos desliga
rjmp   wait_3_seconds
ldi    R16,0x00     ; Limpa o registrador R16
sts    TCNT1H,R16   ; Limpa o timer 1
sts    TCNT1L,R16


wait_3_seconds:
lds    R16,TCNT1L   ; Carrega o timer 1
lds    R17,TCNT1H
cp     R16,R11      ; Compara com R11
cpc    R17,R16
brne   check_button ; Se diferente, volta para check_button
rjmp   turn_off_led ; Se igual, vai para turn_off_led

turn_off_led:
clr    R10          ; Define o nível de luminosidade para o mais baixo (desligado)
sts    OCR2A,R10    ; Envie R10 para o duty cycle - comparador
rjmp   check_button ; Volta para check_button

ramp_pwm:
inc    R10          ; Incrementa R10 - nivel de intensidade luminosa - duty cycle
sts    OCR2A,R10    ; Envia R10 para duty cycle - comparador
;Inicio depurador
mov    R16,R10
out    PORTD,R16
;Final depurador
cp     R10,R20      ; Compara R10 com zero - para saber quando voltar para o inicio
breq   check_button ; Se R10 = 0, volta para check_button
clr    R16
sts    TCNT1H,R16   ; Limpa o timer 1
sts    TCNT1L,R16
rjmp   wait_ramp


wait_ramp:
lds    R16,TCNT1L
lds    R16,TCNT1H   ; Carrega timer 1
cpse   R16,R12      ; Compara com R12
rjmp   wait_ramp    ; Se diferente, volta para wait_ramp
rjmp   ramp_pwm     ; Se igual, segue o codigo para ramp_pwm e incrementa novamente o duty cycle
