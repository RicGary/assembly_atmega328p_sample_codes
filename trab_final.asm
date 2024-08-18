.include "m328pdef.inc"  ; Inclui o arquivo de definicão do ATmega328P

.org   0x0000              ; Define o endereco de inicio do programa

; Interrupts
.org   0x0002      ; Jogador 1 
rjmp   botao_j1
.org   0x0004      ; Jogador 2
rjmp   botao_j2

; Definindo variaveis
.def   pontuacao_j1 = r20
.def   pontuacao_j2 = r21
.def   vitorias_j1  = r22
.def   vitorias_j2  = r23
.def   botao_reset  = r24
.def   num_final    = r25
.def   is_pressed   = r26
.def   j1_pressed   = r27
.def   j2_pressed   = r28

; Configura a pilha
ldi   r16, low(RAMEND)  ; Carrega o byte menos significativo do endereco de RAMEND em r16
out   SPL, r16          ; Armazena o byte menos significativo do endereco de RAMEND no registrador SPL
ldi   r16, high(RAMEND) ; Carrega o byte mais significativo do endereco de RAMEND em r16
out   SPH, r16          ; Armazena o byte mais significativo do endereco de RAMEND no registrador SPH

; Configura os pinos  Gasta mais linhas e energia mas prefiro fazer assim para deixar facil de ler as portas
cbi   DDRD, PD2         ; Configura PD2 como entrada (BOTAO) -> Jogador 1
cbi   DDRD, PD3         ; Configura PD3 como entrada (BOTAO) -> Jogador 2
cbi   DDRB, PD4         ; Configura PD4 como entrada (BOTAO) -> Reset da rodada
ser   r16               ; Seta todos os bits como 1
out   PORTB, r16        ; Ativa o resistor pull-up no PBx

sbi   DDRD, PB0             ; Configura PB0 como saida -> Jogador 1 vence
sbi   DDRD, PB1             ; Configura PB1 como saida -> Jogador 2 vence
clr	  R16				    ; Limpa R16
out	  PORTD,R16	            ; limpa a porta D para saida - estado inicial desliga led

; Configura interrupt para os jogadores
ldi   r16  , 0b00001010     ; ISC01 = 1, ISC11 = 1 para borda de descida, ISC00 = 0, ISC10 = 0
sts   EICRA, r16            ; Define borda de descida para INT0 e INT1
ldi   r16  , 0b00000011     ; 0b00000011 corresponde a INT1 e INT0 habilitados
out   EIMSK, r16            ; Ativa as interrupcões para INT0 e INT1
sei                         ; Habilita interrupcões globais

; Configura parte do ADC
ldi   r16  , 0b01_0_0_0000  ; Move valor para r16
sts   ADMUX, r16            ; Garante que sera lido no pino PC0/A0

; Configura timer do debouncing 
ldi   R16   , 0b00_00_00_00 ; Move o valor para r16
out   TCCR0A, R16           ; Configura modo normal = delay
ldi   R16   , 0b00_00_0_010 ; Move o valor para r16
out   TCCR0B, R16           ; Configura clk com prescaler de PS8 = 010

; Configura timer do LED
; Considerando apenas a parte alta, quero que o led fique ligado +- 5s
ldi   R16, 0b00000000          ; Configura o modo do Timer 1 para CTC (WGM12 = 1)
sts   TCCR1A, R16              ; Passa o valor para o TCCR1A
ldi   R16, 0b00001100          ; CTC com prescaler de 256 (CS12 = 1)
sts   TCCR1B, R16              ; Passa o valor para o TCCR1B

; Definindo constantes
clr   pontuacao_j1
clr   pontuacao_j2
clr   vitorias_j1
clr   vitorias_j2

wait_button:
    ser    botao_reset       ; Seta se for parte da rotina de reset
    sbis   PIND, 4           ; Confere se o PD4 esta setado
    rjmp   buttom_debouncing ; Vai para o filtro
    rjmp   wait_button       ; Fica em loop

compara_e_reinicia:
    cp     pontuacao_j1, pontuacao_j2 ; Compara para ver qual jogador venceu
    clr    R16                        ; Limpa r16
    sts    TCNT1H, R16                ; Zera o timer
    brlt   vitoria_j2                 ; Branch if less than, funciona ja que nao sao valores altos (espero)
    brge   vitoria_j1                 ; Branch if Greater or Equal 

vitoria_j1:  
    sbi    PORTD, PD0      ; Liga o led
    lds    R16  , TCNT1H   ; Le a parte alta do timer
    cpi    R16  , 123      ; Compara o valor alto de 5
    brlo   vitoria_j1      ; Se nao chegou volta para loop
    inc    vitorias_j1     ; Se chegou adiciona 1 vitoria ao j1
    clr    pontuacao_j1    ; Limpa pontuacao
    clr    j1_pressed      ; Nao vai ser usado
    cbi    PORTD, PD0      ; Desliga o led
    rjmp   wait_button     ; Volta ao inicio do jogo

vitoria_j2:
    sbi    PORTD, PD1      ; Liga o led
    lds    R16  , TCNT1H   ; Le a parte alta do timer
    cpi    R16  , 123      ; Compara o valor alto de 5
    brlo   vitoria_j2      ; Se nao chegou volta para loop
    inc    vitorias_j2     ; Se chegou adiciona 1 vitoria ao j2
    clr    pontuacao_j2    ; Limpa pontuacao
    clr    j2_pressed      ; Nao vai ser usado
    cbi    PORTD, PD1      ; Desliga o led
    rjmp   wait_button     ; Volta ao inicio do jogo

botao_j1:
    clr    is_pressed         ; Limpa is_pressed 
    clr    botao_reset        ; Limpa botao_reset
    clr    R16                ; Limpa r16
    out    TCNT0, R16         ; Limpa timer0
    call   buttom_debouncing  ; Chama a rotina
    sbrs   is_pressed, 1      ; Checa se o botao foi pressionado
    rjmp   soma_j1            ; Vai para rotina de soma
    inc    j1_pressed         ; Nao vai ser utilizado
    rjmp   wait_button        ; Vai para rotina de loop

botao_j2:
    clr    is_pressed         ; Limpa is_pressed 
    clr    botao_reset        ; Limpa botao_reset
    clr    R16                ; Limpa r16
    out    TCNT0, R16         ; Limpa timer0
    call   buttom_debouncing  ; Chama a rotina
    sbrs   is_pressed, 1      ; Checa se o botao foi pressionado
    rjmp   soma_j2            ; Vai para rotina de soma
    inc    j2_pressed         ; Nao vai ser utilizado
    rjmp   wait_button        ; Vai para rotina de loop

soma_j1:
    call   num_aleatorio
    add    pontuacao_j1, num_final
    rjmp   wait_button

soma_j2:
    call   num_aleatorio
    add    pontuacao_j2, num_final
    rjmp   wait_button

num_aleatorio:                ; Valor vai de 0-7, faz inc para virar 1-8 e virar um d8
    clr   num_final           ; Limpa registrador que vai armazenar o número final

    ; Poderia virar um loop
    call  ler_adc             ; Primeira leitura ADC
    mov   r17, r18            ; Move resultado para r17
    andi  r17, 0x01           ; Isola o bit menos significativo
    or    num_final, r17      ; Adiciona ao número final na (posição 0)

    call  ler_adc             ; Primeira leitura ADC
    mov   r17, r18            ; Move resultado para r17
    andi  r17, 0x01           ; Isola o bit menos significativo
    or    num_final, r17      ; Adiciona ao número final na (posição 0)

    call  ler_adc             ; Terceira leitura ADC
    mov   r17, r18            ; Move resultado para r17
    andi  r17, 0x01           ; Isola o bit menos significativo
    lsl   r17                 ; Desloca para a esquerda
    lsl   r17                 ; Desloca novamente para a esquerda (posição 2)
    or    num_final, r17      ; Adiciona ao número final

    inc   num_final           ; Soma 1 para virar um d8
    ret

ler_adc:
    ldi  r16   , 0b1_1_000101  ; Move o valor para r16
    sts  ADCSRA, r16           ; Inicia uma conversão

wait_conversion:
    lds    r16, ADCSRA        ; Le o valor de ADCSRA para ver se a flag mudou
    sbrs   r16, 6             ; Verifica se a conversão terminou
    rjmp   wait_conversion    ; Se a conversao nao terminou, fica em loop

    lds    r18, ADCL          ; Armazena o resultado da conversão em r18
    ret                       ; Retorna para ultimo call

buttom_debouncing:
    in     R16, TCNT0             ; Carrega o valor do timer 0
    cpi    R16, 0x7D              ; Compara com o valor de debouncing
    brne   buttom_debouncing      ; Continua no loop se ainda não atingiu o tempo

    in     R16, PIND              ; Lê o estado atual do PORTD
    andi   R16, 0b00011100        ; Isola os bits referentes a PD2, PD3, PD4
    cpi    R16, 0b00000000        ; Compara se algum dos botões está em 0
    brne   buttom_debouncing      ; Se nenhum botão está pressionado, volta ao início do debouncing

button_pressed:
    clr    R18                ; Limpa R18 para servir de contador de ciclo
    sbrs   botao_reset, 1     ; Checa qual rotina chamou o debouncing
    rjmp   compara_e_reinicia ; Se for rotina do reset vai para rotina final
    ser    is_pressed
    ret