;Projeto de Sistemas Embarcados - FIS01237
;Instituto de Física - UFRGS
;Prof. Milton A Tumelero
;
;Atividade 1: Acesso a Memoria
;
;Nesta atividade a medoria de dados SRAM será acessada de diferentes modos - Acompanhar os endereçamentos com o simulador


.include m328Pdef.inc
.org 0x0000

;Configuração do Stacker Pointer -> Define o SP no final da memória SRAM x08ff
ldi	R16,LOW(RAMEND)
out	SPL,R16
ldi	R16,HIGH(RAMEND)
out	SPL,R16

;Endereçamento Direto
ldi	R16,0x00
sts	0x0100,R16  ;Carrega a memória x0100 com o valor de R16 = x00 = d0

;Endereçamento Indireto
ldi	R17,0x01
ldi	XL,0x01   ;Carrega X com x0101
ldi	XH,0x01
st	X,R17     ;Carrega a memória x0101 com o valor de R17 = x01 = d1

;Endereçamento Indireto com Incremento
ldi	R18,0x02
ldi	XL,0x02   ;Carrega X com x0102
ldi	XH,0x01	
st	X+,R18		;Carrega a memória x0102 com o valor de R18 = x02 = d2 e incrementa X em uma unidade X = X + 1 = x0103
ldi	R19,0x03
st	X,R19		;Carrega a memória x0103 com o valor de R19 = x03 = d3

;Endereçamento Indireto com Decremento
ldi	XL,0x05		;Carrega X com x0105
ldi	XH,0x01
ldi	R20,0x04
st	-X,R20		;Primeiro decrementa X em uma unidade X = X - 1 = x0104 e Carrega a memória x0104 com o valor de R20 = x04 = d4

;Endereçamento Indireto com Deslocamento
ldi	YL,0x04		;Carrega Y com x0105
ldi	YH,0x01
ldi	R21,0x05
std	Y+1,R21		;Carrega a memória Y+1 = x0105 com o valor de R21 = x05 = d5
ldi	R22,0x06
std	Y+2,R22		;Carrega a memória Y+2 = x0106 com o valor de R22 = x06 = d6

;Endereçamento com Pilha -> Escrita
ldi	R23,0xff
push	R23		;Carrega a memória indicada em SP = x08ff com o valor de R23 = xff = d255 e decrementa uma unidade de SP = SP - 1 = x08fe
ldi	R23,0xfe
push	R23		;Carrega a memória indicada em SP = x08fe com o valor de R23 = xfe = d254 e decrementa uma unidade de SP = SP - 1 = x08fd
ldi	R23,0xfd	
push	R23		;Carrega a memória indicada em SP = x08fd com o valor de R23 = xfd = d253 e decrementa uma unidade de SP = SP - 1 = x08fc
ldi	R23,0xfc	
push 	R23		;Carrega a memória indicada em SP = x08fc com o valor de R23 = xfc = d252 e decrementa uma unidade de SP = SP - 1 = x08fb

;Endereçamento com Pilha -> Leitura
pop	R15			;Carrega R15 com o valor na memória SP + 1 = x08fc que é xfc = d252
pop	R14			;Carrega R14 com o valor na memória SP + 1 = x08fd que é xfd = d253
pop	R13			;Carrega R13 com o valor na memória SP + 1 = x08fe que é xfe = d254
pop	R12			;Carrega R12 com o valor na memória SP + 1 = x08ff que é xff = d255

;Loop infinito
LOOP:		nop
rjmp	LOOP