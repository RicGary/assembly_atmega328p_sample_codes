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

.def contador_medidas       = r20
.def cte_medidas            = r11
.def deslocamentos_dir      = r22   ; Deve ser N.medidas = 2 ^ deslocamentos_para_direita, nesse caso 16 = 2^4, entao 4 deslocamentos
.def deslocamentos_dir_cte  = r12   ; Valor fixo de deslocamentos                                  
.def soma_low               = r13   ; mudei pois esse é o endereco do Z
.def soma_high              = r21

; Configura pilha 
ldi    R16,low(RAMEND)
out    SPL,R16
ldi    R16,high(RAMEND)
out    SPH,R16

; Configura constantes
ldi r16, 16                     ; Numero de medidas realizadas, precisa ser multiplo de 2, como 16=2^4 desloca o valor 4 vezes para 
ldi deslocamentos_dir    , 4    ; r16/4 
mov deslocamentos_dir_cte, deslocamentos_dir
mov contador_medidas     , r16  ; Contador do loop para armazenar medidas
mov cte_medidas          , r16  ; Cte. do loop 
ldi r30, low(0x0300)            ; Endereço inicial baixo para Z (X?) , Endereço maximo = Endereço inicial + 124 (7C)
ldi r31, high(0x0300)           ; Endereço inicial alto  para Z (X?)
ldi r28, low(0x0400)            ; Endereço inicial baixo para Y
ldi r29, high(0x0400)           ; Endereço inicial alto  para Y

; Configura o ADC -> termometro PC0
ldi    R16,     0b01_0_0_0000   ; REFS1,REFS0 (01) = Vref igual ao Vcc, ADLAR (0) 8 bits ADCL 2 bits ADCH, MUX (0000) ADC0 porta PC0
sts    ADMUX,   R16            
ldi    R16,     0b1_1_1_0_0_101 ; ADEN (1) habilita ADC, ADSC (1) habilita para iniciar conversao, ADATE (1) conversao automatica, ADIF (0) e ADIE (0) nao serao utilizados, ADPSx (101) prescaler de 32
sts    ADCSRA,  R16            
ldi    R16,     0b0000_0_000    ; ACME (0) utiliza entrada padrao do ADC, ADTSx (000) ADC automaticamente inicia uma nova conversao assim que a anterior for feita
sts    ADCSRB,  R16             ; Configura autotrigger em free running

;debug
ldi r24, 1               ; usar para simular o ADC
;debug
loop_store:
    cpi YL, 124                ; Verifica se a parte low do Y = 124
    breq memory_reset          ; Se sim, reseta a memoria
    lds r16, ADCH
    lds r17, ADCL
    ;debug
    mov r16, r24
    mov r17, r24
    ;debug
    st Z+,   r16                ; Armazena a parte alta no endereço atual, incrementa Z
    st Y+,   r17                ; Armazena a parte baixa no endereço apontado por Y, incrementa Y
    add soma_low, r16           ; Adicionar parte baixa à soma
    adc soma_high, r17          ; Adicionar parte alta à soma com carry
    dec contador_medidas        ; Decrementa o contador
    brne loop_store             ; Se o contador não é zero, repete o loop

media_final: ; esta ligado com a SR anterior
    mov contador_medidas, cte_medidas
    ; lsr da soma_high para que o carry va para o soma_low
    lsr soma_high            ; Desloca o bit mais baixo da parte alta para o carry
    ror soma_low             ; Rota a parte baixa para direita, puxando o carry para o bit mais alto
    dec deslocamentos_dir
    brne media_final         ; Desloca x vezes para direita
    rjmp loop_store

memory_reset: ; Verifica se foram escritos 124 valores na memoria para comecar a sobrescrever
    ldi YL, low(0x0400)
    ldi ZL, low(0x0300)
    rjmp loop_store
