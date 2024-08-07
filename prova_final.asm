;Projeto de Sistemas Embarcados - FIS01237
;Instituto de Fisica - UFRGS
;Prof. Milton A Tumelero
;
;Prova 2

; Enunciado:
;
; Desenvolver um programa para realiza��o de um sistema de controle P(ID), com as especifica��es abaixo:
; FEITO
; - Medir um sinal de entrada anal�gico, 0-5V, decorrente de um sensor, com 10 bits de resolu��o.

; FEITO
; - Realizar N (N>16)medidas consecutivas e realizar uma m�dia aritm�tica do valor. 

; - Guardar o valor das �ltimas 124 m�dias na mem�ria.

; - Calcular um sinal de erro a partir da um valor de refer�ncia predeterminado no 

;   programa via uma porta anal�gica (0-5V)

; - Gerar um sinal de sa�da de controle proporcional ao sinal de erro e com escala de 8 bits.

; - Configurar um pwm com o sinal de controle.


; Solu��o:

; Detalhamento do C�digo
; Detalhe aqui as configura��es de hardware a serem utilizadas, 
; portas de entrada, porta de saida, e outros perif�ricos a serem 
; utilizados e suas respectivas configura��es. De uma breve descri��o 
; sobre a estrutura escolhida para o desenvolvimento do programa.

; Inicio do C�digo

.include m328Pdef.inc
.org 0x0000

.def contador_medidas = r20
.def soma_low    = r30
.def soma_high   = r31

; Configura pilha 
ldi    R16,low(RAMEND)
out    SPL,R16
ldi    R16,high(RAMEND)
out    SPH,R16

; Configura constantes
ldi r20, 16                 ; Contador do loop para armazenar 16 medidas ou mais  
ldi r21, 16                 ; Cte. do loop 
ldi r26, low(0x0300)        ; Endereço inicial baixo para Z
ldi r27, high(0x0300)       ; Endereço inicial alto  para Z
ldi r28, low(0x0400)        ; Endereço inicial baixo para Y
ldi r29, high(0x0400)       ; Endereço inicial alto  para Y

; Configura o ADC -> termometro PC0
ldi    R16,     0b01_0_0_0000 ; REFS1,REFS0 (01) = Vref igual ao Vcc, ADLAR (0) 8 bits ADCL 2 bits ADCH, MUX (0000) ADC0 porta PC0
sts    ADMUX,   R16            
ldi    R16,     0b1_1_1_0_0_101 ; ADEN (1) habilita ADC, ADSC (1) habilita para iniciar conversao, ADATE (1) conversao automatica, ADIF (0) e ADIE (0) nao serao utilizados, ADPSx (101) prescaler de 32
sts    ADCSRA,  R16            
ldi    R16,     0b0000_0_000 ; ACME (0) utiliza entrada padrao do ADC, ADTSx (000) ADC automaticamente inicia uma nova conversao assim que a anterior for feita
sts    ADCSRB,  R16            ; configura autotrigger em free running

loop_store:
    lds r16, ADCH
    lds r17, ADCL
    st Z+,   r16            ; Armazena a parte alta no endereço atual, incrementa Z
    st Y+,  r17             ; Armazena a parte baixa no endereço apontado por Y, incrementa Y
    add soma_low, r16  ; Adicionar parte baixa à soma
    adc soma_high, r17 ; Adicionar parte alta à soma com carry
    dec contador_medidas    ; Decrementa o contador
    brne loop_store         ; Se o contador não é zero, repete o loop

media_final:
    mov contador_medidas, r21
    ; faz divisao de um num. de 16 bits por um de 8 bits