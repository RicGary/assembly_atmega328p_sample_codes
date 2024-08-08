.include "m328Pdef.inc"

.org 0x0000

    ; Exemplo de multiplicação de 8 bits por 16 bits
    ; r16 = número de 8 bits
    ; r17:r18 = número de 16 bits (r17 = low byte, r18 = high byte)
    ; Resultado esperado em r19:r20:r21 (r21 = high byte, r19 = low byte)

    ; Inicializa os registradores
    ldi r16, 2       ; Valor de 8 bits

    ldi r17, low(1000)       ; Low byte do valor de 16 bits
    ldi r18, high(1000)      ; High byte do valor de 16 bits

    ; Multiplicar o low byte
    mul r16, r17        ; r16 * r17
    mov r19, r0         ; Low part of result
    mov r20, r1         ; High part of result

    ; Multiplicar o high byte
    mul r16, r18        ; r16 * r18
    mov r21, r0         ; High byte of the full result
    add r21, r1         ; Add the overflow from the previous multiplication

    ; Corrigir o resultado final
    ; Se necessário, adicione código aqui para ajustar os overflows adicionais

    ; Encerra a multiplicação para limpar os registros de multiplicação
    clr r1              ; Clear r1 after multiplication as per the AVR conventions

    ; Resultado agora está em r19:r20:r21
