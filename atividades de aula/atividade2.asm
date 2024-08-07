;Projeto de Sistemas Embarcados - FIS01237
;Instituto de Física - UFRGS
;Prof. Milton A Tumelero
;
;Atividade 1b: Sequencia de Fibonacci                               ;
; O Código desta atividade gera a sequencia de Fibonacci, F(i)=F(i-1)+F(i-2) e guarda em unidades de 2bytes da mram (2x8bits)  ;

; Definiþ§es e diretivas

.def f1h = R16   ; define byte maior para F(i-1)
.def f1l = R17   ; define byte menor para F(i-1)
.def f2h = R18   ; define byte maior para F(i-2)
.def f2l = R19   ; define byte menor para F(i-2)
.def varl = R20   ; define a parte "low" da variavel var de 16 bits
.def varh = R21   ; define a parte "high" da variavel var de 16 bits

.include "m328Pdef.inc"
.cseg
.org 0x0000

; inicializa a sequencia

ldi		f2h,0x00	;Carrega 0 em f2h
ldi		f2l,0x00	;Carrega 0 em f2l --> f2 = 0x0000 - Primeiro termo da sequencia
ldi		f1h,0x00	;Carrega 0 em f1h
ldi		f1l,0x01	;Carrega 0 em f1l --> f1 = 0x0001 - Segundo termo da Sequencia
ldi  	varl,0x02     ;Carrega 2 em varl
ldi  	varh,0x00     ;Carrega 0 em varh --> var = 0x0002 ou d2
ldi   	YH,0x01      ;Ajusta o ponteiro de memoria Y em 0x0100
ldi   	YL,0x00      ;Ajusta o ponteiro de memoria Y em 0x0100
sts		0x0100,f2h		;Salva f2 na MRAM
sts		0x0101,f2l		;Salva f2 na MRAM
sts		0x0102,f1h		;Salva f1 na MRAM
sts		0x0103,f1l		;Salva f1 na MRAM

; inicia a soma

SOMA:	
    add		f1l,f2l		; Soma bytes menores
    adc		f1h,f2h		; Soma bytes maiores + carry
    std		Y+4,f1h		; Salva na MRAM em Y+4 o novo termo da sequencias gravado em f1h atual
    std		Y+5,f1l		; Salva na MRAM em Y+4 o novo termo da sequencias gravado em f1l atual
    ldd		f2h,Y+2   ; Carrega f2l com valor presente em Y+2 (f1l anterior)
    ldd     f2l,Y+3   ; Carrega f2h com valor presente em Y+3 (f1h anterior)
    BRCS	FIM		; Confere o SREG carry, da ultima soma (adc f1h,f2h) se for um pula para FIM, senao para SOMA. Isso poderia ser feito com outras comparaþ§es, por exemplo: BRBS 0,FIM ou entÒo SBIS SREG,0
    add   YL,R20 ; Soma 2 no apontador YL
    adc   YH,R21 ; Soma 0 no apontador YL + carry --> Desloca o ponteiro Y para escrever o proximo termo da sequencia em nova unidade de memória.
    rjmp	SOMA	; Pula para soma
		
FIM:	nop				; Loop infinito de FIM.
    rjmp	FIM   