; 1.  Inicializa a Stack Pointer e os registradores R16, R17, R18 e R19.
; 2.  Configura os pinos B e D como saídas, definindo todos os bits como '1'.
; 3.  Configura o Timer/Counter 0 para operar em modo Fast PWM.
; 4.  Entra em um loop de verificação do botão, onde ele espera até que o botão seja pressionado.
; 5.  Quando o botão é pressionado, ele configura o Timer/Counter 1 para iniciar a contagem.
; 6.  Entra em um loop de programa onde incrementa o valor do registrador OCR0A a cada iteração até atingir um valor especificado (armazenado em R19), aumentando assim a luminosidade do LED.
; 7.  Se o valor do OCR0A igualar o valor armazenado em R19, ele limpa o registrador OCR0A, efetivamente desligando o PWM e reiniciando o processo.
; 8.  Verifica se o botão foi solto, caso contrário, ele continua no loop atual.
; 9.  Verifica se o timer 1 atingiu o valor de comparação, caso contrário, ele continua no loop atual.
; 10. Se o timer 1 atingir o valor de comparação, ele limpa o pino D, efetivamente desligando o LED.

.include "m328Pdef.inc" ; Inclui o arquivo de definição do microcontrolador

.org 0x0000 ; Define o endereço de início do programa 
rjmp inicio ; Salta para a  "inicio"

inicio: 
    ldi R16, low(RAMEND) ; Carrega o valor mais baixo do endereço da memória RAM em R16 
    out SPL, R16 ; Armazena o valor de R16 no registrador SPL (Stack Pointer Low) 
    ldi R16, high(RAMEND) ; Carrega o valor mais alto do endereço da memória RAM em R16 
    out SPH, R16 ; Armazena o valor de R16 no registrador SPH (Stack Pointer High) 
    clr R17 ; Limpa o registrador R17 
    ldi R18, 0x33 ; Carrega o valor hexadecimal 0x33 em R18 
    ldi R19, 0x05 ; Carrega o valor hexadecimal 0x05 em R19 
    mul R18, R19 ; Multiplica os valores de R18 e R19 e armazena o resultado em R1:R0 
    mov R19, R0 ; Move o valor do registrador R0 para o registrador R19 
    rjmp config_pin ; Salta para a "config_pin"

config_pin: 
    clr R16 ; Limpa o registrador R16 
    out DDRB, R16 ; Armazena o valor de R16 no registrador DDRB (Data Direction Register B) 
    ser R16 ; Seta todos os bits de R16 como '1' 
    out PORTB, R16 ; Armazena o valor de R16 no registrador PORTB 
    out DDRD, R16 ; Armazena o valor de R16 no registrador DDRD 
    rjmp config_PWM ; Salta para a "config_PWM"

config_PWM: 
    ldi R16, 0b0100_00_11 ; Carrega o valor binário 01000011 em R16 (WGM00, WGM01) -> 1
    out TCCR0A, R16 ; Armazena o valor de R16 no registrador TCCR0A (Timer/Counter Control Register A) 
    ldi R16, 0b000_00_100 ; Carrega o valor binário 00000100 em R16 (CS02) -> 1
    out TCCR0B, R16 ; Armazena o valor de R16 no registrador TCCR0B (Timer/Counter Control Register B) 
    clr R17 ; Limpa o registrador R17 
    out OCR0A, R17 ; Armazena o valor de R17 no registrador OCR0A (Output Compare Register A) 
    rjmp check_button ; Salta para a "check_button"

check_button: 
    sbic PINB, 0 ; Pula para a próxima instrução se o bit 0 de PINB estiver setado 
    rjmp check_button ; Salta para a "check_button" caso o botão não esteja pressionado 
    rcall debounce ; Chama a subrotina debounce
    rjmp start_timer ; Salta para a "start_timer" caso o botão esteja pressionado

debounce:
    ldi R16, 50 ; Carrega o valor 50 em R16

debounce_loop:
    dec R16 ; Decrementa o valor de R16
    brne debounce_loop ; Continua no loop se R16 não é zero
    ret ; Retorna para a chamada da subrotina

start_timer: 
    ldi R16, 0b0000_1011 ; Carrega o valor binário 00001011 em R16 
    sts TCCR1B, R16 ; Armazena o valor de R16 no registrador TCCR1B: (WGM12, CS10, CS11) -> 1
    ldi R16, high(46875) ; Carrega o valor mais alto do número 46875 em R16 -> OCR1A = 46875 para 3 segundos
    sts OCR1AH, R16 ; Armazena o valor de R16 no registrador OCR1AH (Output Compare Register 1A High) 
    ldi R16, low(46875) ; Carrega o valor mais baixo do número 46875 em R16 
    sts OCR1AL, R16 ; Armazena o valor de R16 no registrador OCR1AL (Output Compare Register 1A Low) 
    rjmp program ; Salta para a "program"

program: 
    cp R17, R19 ; Compara os valores de R17 e R19 
    breq reset_PWM ; Salta para a  "reset_PWM" se os valores forem iguais 
    add R17, R18 ; Adiciona os valores de R17 e R18 e armazena o resultado em R17 
    out OCR0A, R17 ; Armazena o valor de R17 no registrador OCR0A 
    rjmp reset_button ; Salta para a "reset_button"

reset_PWM: 
    clr R17 ; Limpa o registrador R17 
    out OCR0A, R17 ; Armazena o valor de R17 no registrador OCR0A 
    rjmp reset_button ; Salta para a "reset_button"

reset_button: 
    sbis PINB, 0 ; Pula para a próxima instrução se o bit 0 de PINB estiver setado 
    rjmp reset_button ; Salta para a "reset_button" caso o botão não esteja pressionado 
    rjmp check_button ; Salta para a "check_button" caso o botão esteja pressionado

check_timer: 
    lds R16, TIFR1 ; Carrega o valor do registrador TIFR1 (Timer/Counter Interrupt Flag Register 1) em R16 
    sbrs R16, OCF1A ; Salta para a próxima instrução se o bit OCF1A de R16 estiver setado 
    rjmp check_timer ; Salta para a "check_timer" caso a flag OCF1A não esteja setada 
    rjmp stop_LED ; Salta para a "stop_LED" caso a flag OCF1A esteja setada

stop_LED: 
    clr R16 ; Limpa o registrador R16 
    out PORTD, R16 ; Armazena o valor de R16 no registrador PORTD
