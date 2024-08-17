;Projeto de Sistemas Embarcados - FIS01237
;Instituto de Fisica - UFRGS
;Prof. Milton A Tumelero
;
;Prova 2

; Enunciado:
;
; Desenvolver um programa para realizacao de um sistema de controle P(ID), com as especificacoes abaixo:
; - Medir um sinal de entrada analogico, 0-5V, decorrente de um sensor, com 10 bits de resolucao.
; - Realizar N (N>16)medidas consecutivas e realizar uma m�dia aritm�tica do valor.
; - Guardar o valor das ultimas 124 medias na memoria.
; - Calcular um sinal de erro a partir da um valor de refer�ncia predeterminado no 
;   programa via uma porta analogica (0-5V)
; - Gerar um sinal de saida de controle proporcional ao sinal de erro e com escala de 8 bits.
; - Configurar um pwm com o sinal de controle.


; Solucao:

; Detalhamento do Codigo
; Detalhe aqui as configuracoes de hardware a serem utilizadas,
; portas de entrada, porta de saida, e outros perifericos a serem
; utilizados e suas respectivas configuracoes. De uma breve descricao
; sobre a estrutura escolhida para o desenvolvimento do programa.

; A entrada do Termometro sera a PC0/A0 e a potenciomentro a PC1/A1.
; Esperamos que quanto mais quente, maior a tensao na porta A0. (Isso nao foi trivial pois tivemos que inverter a funcao de erro (G-R) -> (R-G)).
; A saida do PWM sera a PB3/~11, com a porta D como debug dele para regular o ganho do codigo

; Inicio do Codigo

.include m328Pdef.inc
.org 0x0000

.def contador_medidas       = r21
.def cte_medidas            = r10
.def deslocamentos_dir      = r22   ; Deve ser N.medidas = 2 ^ deslocamentos_para_direita, nesse caso 16 = 2^4, entao 4 deslocamentos
.def deslocamentos_dir_cte  = r11   ; Valor fixo de deslocamentos
.def quantidade_medias      = r23   ; Valor responsavel por armazenar x medias
.def quantidade_medias_cte  = r12   ; Cte var. anterior                                  
.def soma_low               = r24  
.def soma_high              = r25
.def termometro             = r13
.def potenciometro          = r14
.def Kd                     = r15

; Reg usados: r10, r11, r12, r13, r14, r15, r21, r22, r23, r24, r25

; Configura pilha 
ldi    R16,low(RAMEND)
out    SPL,R16
ldi    R16,high(RAMEND)
out    SPH,R16

; Configura constantes
ldi quantidade_medias, 124          ; 124 medias salvas na memoria ate comecar a sobrescrever
mov quantidade_medias_cte, quantidade_medias
ldi r16, 16                         ; Numero de medidas realizadas para a media, precisa ser multiplo de 2, como 16=2^4
ldi deslocamentos_dir    , 4        ; desloca o valor 4 vezes para normalizar a media (r16/16)
mov deslocamentos_dir_cte, deslocamentos_dir
mov contador_medidas     , r16      ; Contador do loop_add para somar medidas
mov cte_medidas          , r16      ; Cte. do loop_add
ldi r16, 0b10000000
mov r15, r16                        ; Valor de Kd
ldi r16, 0b01_0_0_0000
mov termometro           , r16      ; Salva a escolha do ADMUX para o termometro
ldi r16, 0b01_0_0_0001
mov potenciometro        , r16      ; Salva a escolha do ADMUX para o potenciometro
; Enderecos iniciais para salvar as medias (array em Z parte alta, array em Y parte baixa)
ldi r30, low(0x0300)                ; Endereço inicial baixo para Z
ldi r31, high(0x0300)               ; Endereço inicial alto  para Z
ldi r28, low(0x0400)                ; Endereço inicial baixo para Y
ldi r29, high(0x0400)               ; Endereço inicial alto  para Y

; Configura PWM
ldi R16,0b10_00_00_11
sts TCCR2A,R16                   ;Configura modo Fast-PWM com TOP=MAX e com modo non-inverting
ldi R16,0b00_00_0_100
sts TCCR2B,R16                   ;Configura clk com prescaler de 256 = 60Hz
ldi r16,0x70
sts OCR2A,R16                    ;Set duty cycle em 44%

;debug
;Configura porta de debug
ser r16
out DDRD, r16
;debug

loop_add: ; Soma as medidas para a media
    ; Le primeiro o termometro
    sts  ADMUX, termometro      ; Garante que sera lido no pino PC0/A0
    ldi  r16, 0b1_1_000101      ;
    sts  ADCSRA, r16            ; Inicia uma conversao
    call ler_adc                ; Espera o resultado

    add soma_low, r17           ; Adicionar parte baixa à soma
    adc soma_high, r16          ; Adicionar parte alta à soma com carry

    dec contador_medidas        ; Decrementa o contador
    brne loop_add               ; Se o contador não é zero, repete o loop

media_final:  ; Normaliza a soma para a media (ligado com a SR anterior)
    lsr soma_high              ; Desloca o bit mais baixo da parte alta para o carry
    ror soma_low               ; Rota a parte baixa para direita, puxando o carry para o bit mais alto

    dec deslocamentos_dir
    brne media_final           ; Desloca x vezes para direita

store_media:  ; Armazena as medias nos registradores Y e Z, reinicia os enderecos (ligado com a SR anterior)
    mov contador_medidas,  cte_medidas
    mov deslocamentos_dir, deslocamentos_dir_cte
    st Z+,   soma_high                ; Armazena a parte alta no endereço atual, incrementa Z
    st Y+,   soma_low                 ; Armazena a parte baixa no endereço apontado por Y, incrementa Y

calculo_erro: ; (ligado com a SR anterior)
    mov r18,  soma_high                   ; Parte high da media do termometro (se atualiza e soma 1, o que pega nao e vazio?)
    mov r19,  soma_low                    ; Parte low da media do termometro

    sts ADMUX, potenciometro    ; Garante que o pino PC1 sera lido
    ldi r16, 0b1_1_000101       ; Inicia conversao
    sts  ADCSRA, r16            ; Inicia uma conversao
    call ler_adc                ; Le o potenciometro e armazena o resultado em r16 e r17

    ; Calculo do erro = Kd * (termometro (G) - potenciometro (R))
    ; (R-G)
    sub r17,r19         ; Low
    sbc r16, r18        ; High
    brlo desliga_pwm

    ; Corrigindo pois vimos que queremos (R-G) depois de ter escrito para (G-R)
    mov r19, r17
    mov r18, r16

    ; Multiplicar o byte baixo do erro por Kd
    mul r19, Kd         ; r19 * Kd
    mov r16, r0         ; Armazena o resultado baixo
    mov r19, r1         ; Armazena o resultado alto (intermediário)

    ; Multiplicar o byte alto do erro por Kd
    mul r18, Kd         ; r18 * Kd
    mov r18, r0         ; Armazena o resultado baixo da segunda multiplicação
    mov r17, r1         ; Armazena o resultado alto da segunda multiplicação

    ; Adicionar os resultados intermediários -> numero de 16 bits [r17(H):r18(L)]
    add r18, r19        ; Adiciona o resultado alto da primeira multiplicação ao resultado baixo da segunda
    clr r5
    adc r17, r5         ; Adiciona qualquer carry ao byte mais alto

    ; Limpa os registros usados na multiplicação
    clr r0
    clr r1

    ; Normaliza o sinal do erro para colocar no PWM, reduzindo ADC*Kd = 10bit*8bit = 18bit -> 16bit
    lsr r17
    ror r18
    ror r16; divide por 2
    lsr r17
    ror r18
    ror r16; divide por 4

    ;debug
    out PORTD, r18
    ;debug

atualiza_pwm: ; Atualiza duty-cicle do PWM (ligado com a SR anterior)

    sts OCR2A,r18 ; Coloca no duty-cicle o termo intermediario do erro

    clr soma_high
    clr soma_low  ; Limpa a soma

    dec quantidade_medias
    brne loop_add

memory_reset: ; Verifica se foram escritos 124 valores na memoria para comecar a sobrescrever (ligado com a SR anterior)
    ldi YL, low(0x0400)
    ldi ZL, low(0x0300)
    mov quantidade_medias, quantidade_medias_cte
    rjmp loop_add

ler_adc:
    lds  r16, ADCSRA
    sbrc r16, 6             ; Espera a conversão de ADC0 terminar
    rjmp ler_adc
    
    lds  r16, ADCH
    lds  r17, ADCL          ; Copia as medidas para os registradores
    ret

desliga_pwm:
    clr r18                 ; Prepara o R18 para ser incluido no duty-cicle futuramente
    rjmp atualiza_pwm

