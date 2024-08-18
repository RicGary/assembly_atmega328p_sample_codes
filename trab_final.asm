.include "m328pdef.inc"  ; Inclui o arquivo de definicão do ATmega328P
.org   0x0000              ; Define o endereco de inicio do programa
rjmp   config

; Interrupts
.org   0x0002      ; Jogador 1 
rjmp   botao_j1
.org   0x0004      ; Jogador 2
rjmp   botao_j2

config:
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
    cbi   DDRD, PD4         ; Configura PD4 como entrada (BOTAO) -> Reset da rodada
    ser   r16               ; Seta todos os bits como 1
    out   PORTD, r16        ; Ativa o resistor pull-up no PDx

    sbi   DDRB, PB0             ; Configura PB0 como saida -> Jogador 1 vence
    sbi   DDRB, PB1             ; Configura PB1 como saida -> Jogador 2 vence
    clr	  R16				    ; Limpa R16
    out	  PORTB,R16	            ; limpa a porta B para saida - estado inicial desliga led

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
    ldi   R16, 0b00000000          ; Configura o modo do Timer 1 para Normal Mode (WGM13=0, WGM12=0, WGM11=0, WGM10=0)
    sts   TCCR1A, R16              ; Passa o valor para o TCCR1A
    ldi   R16, 0b00001100          ; CTC com prescaler de 256 (CS12 = 1)
    sts   TCCR1B, R16              ; Passa o valor para o TCCR1B

    ; Definindo constantes
    clr   pontuacao_j1
    clr   pontuacao_j2
    clr   vitorias_j1
    clr   vitorias_j2

    ; Configura interrupt para os jogadores
    ldi   r16  , 0b00001010     ; ISC01 = 1, ISC11 = 1 para borda de descida, ISC00 = 0, ISC10 = 0
    sts   EICRA, r16            ; Define borda de descida para INT0 e INT1
    ldi   r16  , 0b00000011     ; 0b00000011 corresponde a INT1 e INT0 habilitados
    out   EIMSK, r16            ; Ativa as interrupcões para INT0 e INT1
    sei                         ; Habilita interrupcões globais

wait_button:
    ser    botao_reset       ; Seta a flag indicando que o reset foi acionado
    sbic   PIND, 4           ; Confere se o PD4 esta setado (botao de reset nao pressionado)
    rjmp   buttom_debouncing ; Se o botao de reset foi pressionado, chama a rotina de debouncing
    rjmp   wait_button       ; Se o botao de reset nao foi pressionado, continua no loop

compara_e_reinicia:
    cp     pontuacao_j1, pontuacao_j2 ; Compara as pontuacoes dos dois jogadores
    clr    R16                        ; Limpa r16 para reiniciar o timer
    sts    TCNT1H, R16                ; Zera a parte alta do timer 1
    brlt   vitoria_j2                 ; Se pontuacao_j1 < pontuacao_j2, vai para a rotina de vitoria do jogador 2
    brge   vitoria_j1                 ; Se pontuacao_j1 >= pontuacao_j2, vai para a rotina de vitoria do jogador 1

vitoria_j1:  
    sbi    PORTD, PD0      ; Liga o LED do jogador 1
    lds    R16  , TCNT1H   ; Le a parte alta do timer 1
    cpi    R16  , 123      ; Compara o valor da parte alta com 123 (aproximadamente 5 segundos)
    brlo   vitoria_j1      ; Se ainda nao atingiu 123, continua verificando
    inc    vitorias_j1     ; Incrementa o contador de vitorias do jogador 1
    clr    pontuacao_j1    ; Reseta a pontuacao do jogador 1
    clr    j1_pressed      ; Reseta a flag de botao pressionado do jogador 1
    cbi    PORTD, PD0      ; Desliga o LED do jogador 1
    rjmp   wait_button     ; Retorna ao loop de espera do botao

vitoria_j2:
    sbi    PORTD, PD1      ; Liga o LED do jogador 2
    lds    R16  , TCNT1H   ; Le a parte alta do timer 1
    cpi    R16  , 123      ; Compara o valor da parte alta com 123 (aproximadamente 5 segundos)
    brlo   vitoria_j2      ; Se ainda nao atingiu 123, continua verificando
    inc    vitorias_j2     ; Incrementa o contador de vitorias do jogador 2
    clr    pontuacao_j2    ; Reseta a pontuacao do jogador 2
    clr    j2_pressed      ; Reseta a flag de botao pressionado do jogador 2
    cbi    PORTD, PD1      ; Desliga o LED do jogador 2
    rjmp   wait_button     ; Retorna ao loop de espera do botao

botao_j1:
    clr    is_pressed         ; Limpa a flag is_pressed 
    clr    botao_reset        ; Limpa a flag botao_reset
    clr    R16                ; Limpa o registrador r16
    out    TCNT0, R16         ; Zera o timer 0
    call   buttom_debouncing  ; Chama a rotina de debouncing
    sbrs   is_pressed, 1      ; Se o botao nao foi pressionado, pula para a proxima instrucao
    rjmp   soma_j1            ; Se o botao foi pressionado, vai para a rotina de soma do jogador 1
    inc    j1_pressed         ; Incrementa a flag de botao pressionado do jogador 1
    rjmp   wait_button        ; Retorna ao loop de espera do botao

botao_j2:
    clr    is_pressed         ; Limpa a flag is_pressed 
    clr    botao_reset        ; Limpa a flag botao_reset
    clr    R16                ; Limpa o registrador r16
    out    TCNT0, R16         ; Zera o timer 0
    call   buttom_debouncing  ; Chama a rotina de debouncing
    sbrs   is_pressed, 1      ; Se o botao nao foi pressionado, pula para a proxima instrucao
    rjmp   soma_j2            ; Se o botao foi pressionado, vai para a rotina de soma do jogador 2
    inc    j2_pressed         ; Incrementa a flag de botao pressionado do jogador 2
    rjmp   wait_button        ; Retorna ao loop de espera do botao

soma_j1:
    call   num_aleatorio
    add    pontuacao_j1, num_final
    rjmp   wait_button

soma_j2:
    call   num_aleatorio
    add    pontuacao_j2, num_final
    rjmp   wait_button

num_aleatorio:                ; Valor vai de 0-7, faz inc para virar 1-8 e simular um dado de 8 lados (d8)
    clr   num_final           ; Limpa o registrador que vai armazenar o numero final

    ; Realiza tres leituras do ADC e combina os bits menos significativos
    call  ler_adc             ; Primeira leitura ADC
    mov   r17, r18            ; Move o resultado para r17
    andi  r17, 0x01           ; Isola o bit menos significativo
    or    num_final, r17      ; Adiciona ao numero final na posicao 0

    call  ler_adc             ; Segunda leitura ADC
    mov   r17, r18            ; Move o resultado para r17
    andi  r17, 0x01           ; Isola o bit menos significativo
    lsl   r17                 ; Desloca para a esquerda (posicao 1)
    or    num_final, r17      ; Adiciona ao numero final na posicao 1

    call  ler_adc             ; Terceira leitura ADC
    mov   r17, r18            ; Move o resultado para r17
    andi  r17, 0x01           ; Isola o bit menos significativo
    lsl   r17                 ; Desloca para a esquerda
    lsl   r17                 ; Desloca novamente para a esquerda (posicao 2)
    or    num_final, r17      ; Adiciona ao numero final na posicao 2

    inc   num_final           ; Soma 1 para transformar em um valor de 1-8
    ret

ler_adc:
    ldi  r16   , 0b1_1_000101  ; Inicia uma conversao ADC
    sts  ADCSRA, r16           ; Configura ADCSRA para iniciar a conversao

    wait_conversion:
        lds    r16, ADCSRA        ; Le o registrador ADCSRA
        sbrs   r16, 6             ; Verifica se a conversao terminou (bit ADSC = 0)
        rjmp   wait_conversion    ; Se a conversao nao terminou, fica em loop

        lds    r18, ADCL          ; Le o resultado da conversao e armazena em r18
        ret                       ; Retorna para a rotina anterior

buttom_debouncing:
    in     R16, TCNT0             ; Carrega o valor do timer 0
    cpi    R16, 0x7D              ; Compara com o valor de debouncing
    brne   buttom_debouncing      ; Continua no loop se ainda nao atingiu o tempo

    in     R16, PIND              ; Le o estado atual do PORTD
    andi   R16, 0b00011100        ; Isola os bits referentes a PD2, PD3, PD4
    cpi    R16, 0b00000000        ; Compara se algum dos botoes esta em 0 (pressionado)
    brne   buttom_debouncing      ; Se nenhum botao esta pressionado, volta ao inicio do debouncing

button_pressed:
    clr    R18                ; Limpa R18 para servir de contador de ciclo
    sbrs   botao_reset, 1     ; Verifica se a rotina foi chamada pelo reset
    rjmp   compara_e_reinicia ; Se for o reset, vai para a rotina de comparacao e reinicio
    ser    is_pressed         ; Seta a flag indicando que o botao foi pressionado
    ret