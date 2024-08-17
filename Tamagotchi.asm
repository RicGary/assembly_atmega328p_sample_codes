
;Descricao Configs

;Defs e Equs
;.equs:
.include m328Pdef.inc
.equ   decFome    = 0x20 ;      Decremento Fome
.equ   incFome    = 0xFF ;      Incremento Fome
.equ   decTroca   = 0x20 ;      Decremento Troca
.equ   decSono    = 0x20 ;      Decremento Sono
.equ   incSono    = 0xFF ;      Incremento Sono (diferente do decremento)
.equ   avsFome    = 0x60 ;      Limite Aviso Fome
.equ   avsTroca   = 0x60 ;      Limite Aviso Troca
.equ   avsSono    = 0x60 ;      Limite Aviso Sono
.equ   tempo_debouncing = 0x7D ;Tempo de espera para filtro do botao - deboucing. Com PS de 64, 500 us sao necessarios 125=x7D clock de timer

;.defs:
.def   stsFome    = R20  ;      R20 - Status Fome
.def   stsTroca   = R21  ;      R21 - Status Troca
.def   stsSono    = R22  ;      R22 - Status Sono
.def   flag_reg   = R19  ;      R23 - Flags:
.equ   fb_lumin   = 0    ;          b0 - Luminosidade
.equ   fn_lumin   = 0b00000001
.equ   fb_troca   = 1    ;          b1 - Troca
.equ   fn_troca   = 0b00000010
.equ   fb_fuga    = 2    ;          b2 - Fuga
.equ   fn_fuga    = 0b00000100
.equ   fb_normal  = 3    ;          b3 - Normal
.equ   fn_normal  = 0b00001000
.equ   fb_trocando= 4    ;          b4 - Trocando
.equ   fn_trocando= 0b00010000
.equ   fb_dormindo= 5    ;          b5 - Dormindo
.equ   fn_dormindo= 0b00100000

.equ   lim_lum    = 0x88 ;     Limite de luminosidade para dormir (0x88 = 128 = 256/2 = metade)

; ----------------- Inicio Codigo -----------------

; Vetores Interrupt
.org 0x0000
rjmp config

.org 0x0002 ; INT0 - Botao PD2 (?)
rjmp botao_int

.org 0x0004 ; INT1 - Papel PD3/3
rjmp papel_int

.org 0x001A ; Timer1 Overflow
rjmp timer_decrescimos

.org 0x002A ; ADC Complete
rjmp sensor_luz

; ----------------- Loop Principal -----------------

.org 0x0034
main_loop:
          in    r16,       PORTD
          andi  r16,     0b00001100
          out  PORTD,     r16       ;  Limpa os LEDs para atualizar mas mantem os botoes por precaucao

          ; Acende os Avisos
          cpi  stsFome,   avsFome
          brcc sem_fome             ;  Fica se o Carry da sub = 1 ( sts < avs )          ; sbic SREG,0 (?)
          sbi  PORTD,     lb_fome   ;  Atualiza Aviso Fome
sem_fome:
          cpi  stsSono,   avsSono
          brcc sem_sono
          sbi  PORTD,     lb_sono   ;  Atualiza Aviso Sono
sem_sono:
          cpi  stsTroca,  avsTroca
          brcc sem_troca
          sbi  PORTD,     lb_troca  ;  Atualiza Aviso Troca
sem_troca:

          sbrc flag_reg,  fb_fuga   ;  Caso de fuga
          rjmp main_loop            ;  Deixa apagado e volta para o loop

          ; Acende os Cenarios
          sbrc flag_reg,  fb_trocando
          rjmp ilumina_trocando     ;  Ilumina Trocando e volta para o loop
          sbrc flag_reg,  fb_dormindo
          rjmp ilumina_dormindo     ;  Ilumina Dormindo e volta para o loop
          ; Ilumina Normal
          sbi  PORTD,     lb_normal
reseta_e_espera:
          clr    R16
          out    TCNT0,R16          ; limpa timer0
          rjmp   espera_loop        ; Espera o tempo do debouncing para que o led nao fique piscando

ilumina_trocando:
          sbi  PORTD,     lb_trocando
          rjmp reseta_e_espera
ilumina_dormindo:
          sbi  PORTD,     lb_dormindo
          rjmp reseta_e_espera
espera_loop:
          ; Espera um tempo de deboucing
          in    R16,TCNT0          ; carrega o timer 0.
          cpi   R16,tempo_debouncing
          brne  espera_loop   ; se diferente volta para buttom_delay.
          rjmp  main_loop     ; se igual, volta para o loop principal

; ----------------- SRs Interrupts -----------------

;                   # Botao INT0 #

botao_int:
          clr    R16
          out    TCNT0,R16         ; limpa timer0
          rjmp   buttom_debouncing

buttom_debouncing: ; Espera um tempo para saber se o botao realmente foi apertado - deboucing filter - falling edge.
          ; Espera um tempo de deboucing
          in    R16,TCNT0          ; carrega o timer 0.
          cpi   R16,tempo_debouncing
          brne  buttom_debouncing   ; se diferente volta para buttom_delay.

          ; Confirma se botao ainda esta apertado
          sbic   PIND,2            ; confere D2.
          reti                     ; se estiver normal, Volta para o loop principal.

          ; Com o botao confirmado
          sbrc  flag_reg,   fb_trocando ;       Nao come trocando
          reti
          sbrc  flag_reg,   fb_dormindo ;       Nao come dormindo
          reti
          ldi   r16,        incFome
          add   stsFome,    r16         ;       Alimenta
          brcc  fome_abaixo
          ser   stsFome                 ;       Garante que o registrador nao gire
fome_abaixo:
          reti                          ;       Volta ao Loop Principal

;                      # INT1 #

papel_int:
          sbrc  flag_reg,    fb_trocando ;      Se trocando, limpa flag de troca pois agora colocou de volta
          rjmp  limpa_troca

          sbr   flag_reg,    fn_trocando ;      Seta flag trocando
          ser   stsTroca                 ;      Reseta Status de Troca

          reti

limpa_troca:
          cbr   flag_reg,    fn_trocando ;       Limpa flag trocando
          reti                           ;      Volta ao Loop Principal

;                  # Timer Overflow #

timer_decrescimos:
          ldi   r16,        decFome
          sub   stsFome,    r16          ;      Decresce Status de Fome
          brlo  fuga_sts_zero            ;      Se zera, foge

          sbrs  flag_reg,    fb_trocando ;      Se Trocando, nao decresce Status de Troca
          call  decresce_trocando        ;      Decresce Status de Troca

          sbrs  flag_reg,    fb_dormindo ;      Se Dormindo, nao decresce Status de Sono
          call  decresce_dormindo

          sbrc  flag_reg,    fb_dormindo ;      Se Dormindo, incrementa Sono
          call  incrementa_dormindo

          reti                           ;      Volta para o loop principal

fuga_sts_zero:
         ;debug
         ser   r16
         out   PORTB, r16
         ;debug

         ;            Desabilita os Interrupts

         ;     Int0 - Botao (falling edge ou low level) e Int1 - Papel (logical change)
         ldi    r16,     0b000000_0_0       ;       Disable Int1 e Int0
         out    EIMSK,   r16

         ;     TOV1 - Timer 1 Overflow
         ldi    r16,     0b0_0_000_0_0_0    ;       Desativa Interrupt do Overflow para decrescimos
         sts    TIMSK1,  r16

         ;     ADC - Sensor de Luminosidade

         ldi    R16,     0b0_0_0_0_0_101    ;debug       0b [desabilita ADC] [ADSC] [ADATE] [ADIF] [ADIE desativa interrupt] [PS 32]
         sts    ADCSRA,  R16

         ;

         sbr    flag_reg,    fn_fuga     ;      Seta Flag Fuga
         reti                            ;      Volta para o loop principal

decresce_trocando:
          ldi   r16,        decTroca
          sub   stsTroca,   r16          ;      Decresce Status de Sono
          brlo  fuga_sts_zero            ;      Se zera, foge
          ret

decresce_dormindo:
          ldi   r16,        decSono
          sub   stsSono,    r16          ;      Decresce Status de Sono
          brlo  fuga_sts_zero            ;      Se zera, foge
          ret

incrementa_dormindo:
          ldi   r16,        incSono
          add   stsSono,    r16          ;      Incrementa Status de Sono
          brcc  sono_abaixo
          ser   stsSono                  ;      Garante que o registrador nao gire
sono_abaixo:
          reti
;                 # ADC Complete #

sensor_luz:
          lds   r16,         ADCL
          lds   r17,         ADCH        ;      Le o ADC do sensor de luminosidade
          cpi   r17,         lim_lum     ;      Compara a leitura com o limite
          brcc  acorda                   ;      Se a Medida > Limite, acorda

          sbrc  flag_reg,    fb_trocando ;      Se trocando, acorda
          rjmp  acorda

          sbr   flag_reg,    fn_dormindo ;      Seta Flag Dormindo
          reti                           ;      Volta para o loop principal

acorda:
          cbr   flag_reg,    fn_dormindo ;      Limpa Flag Dormindo
          reti                           ;      Volta para o loop principal




; ----------------- Configuracoes -----------------

config:
;configura pilha
ldi    R16,low(RAMEND)
out    SPL,R16
ldi    R16,high(RAMEND)
out    SPH,R16

config_ctes:
ser   stsFome
ser   stsTroca
ser   stsSono
clr   flag_reg

config_pins:             ;        LEDs ligados na Porta D:
ldi    r16,   0b1111_0_0_11 ;     0b [Dormindo] [Trocando] [Normal] [Aviso Sono]      [INT1]       [INT0]     [Aviso Troca] [Aviso Fome]
out    DDRD,  r16
ldi    r16,   0b0010_1_1_00 ;     0b [Dormindo] [Trocando] [Normal] [Aviso Sono] [INT1 PullUp] [INT0 PullUp] [Aviso Troca] [Aviso Fome]
out    PORTD, r16        ;        LEDs:
.equ   lb_fome    = 0    ;      Aviso Fome
.equ   lb_troca   = 1    ;      Aviso Troca
.equ   lb_sono    = 4    ;      Aviso Sono
.equ   lb_normal  = 5    ;      Normal
.equ   lb_trocando= 6    ;      Trocando
.equ   lb_dormindo= 7    ;      Dormindo
;debug
ser    r16
out    DDRB,  r16
clr    r16
out    PORTB, r16
;debug


config_timer:
;    Timer 0 - Debouncing Delay
ldi    r16,    0b00_00_00_00;      [OC0A Disconnected(Normal)][OC0B Disconnected(Normal)][-][Modo Normal]
out    TCCR0A, r16
ldi    r16,    0b00_00_0_011;      [-][-][Modo Normal][PS 64]
out    TCCR0B, r16

;    Timer 1 - (16bit) Período Principal dos Decréscimos
ldi    r16,    0b00_00_00_00       ;      [OC1A Disconnected(Normal)][OC1B Disconnected(Normal)][-][Modo Normal]
sts    TCCR1A, r16
ldi    r16,    0b00_00_0_101       ;      [-][-][Modo Normal][PS 1024]
sts    TCCR1B, r16
ldi    r16,     0b0_0_000_0_0_1    ;      Ativa Interrupt do Overflow para decrescimos
sts    TIMSK1,  r16

config_adc:
;    ADC     -  Sensor de Luminosidade
ldi    R16,     0b01_1_0_0000      ;       0b [Vref igual ao Vcc] [2 bits ADCL 8 bits ADCH] [-] [ADC0/PC0]
sts    ADMUX,   R16
ldi    R16,     0b1_1_1_0_1_101    ;debug       0b [habilita ADC] [ADSC] [ADATE] [ADIF] [ADIE ativa interrupt] [PS 32]
sts    ADCSRA,  R16
ldi    R16,     0b0000_0_000       ;       0b [-][entrada padrao do ADC][free running]
sts    ADCSRB,  R16

config_interrupts:
;     Int0 - Botao (falling edge ou low level) e Int1 - Papel (logical change)
ldi    r16,     0b000000_1_1       ;       Enable Int1 e Int0
out    EIMSK,   r16
ldi    r16,     0b0000_01_10       ;       [-][INT1 logical change][INT0 falling edge]
sts    EICRA,   r16

sei                                ;       Habilita Global Interrupt do sREG

rjmp main_loop
