# main.asm
# Программа вычисляет квадратный корень числа с заданной точностью

.include "macros.asm"

.text
.globl main

main:
    li a7, 4
    la a0, prompt
    ecall

    READ_INPUTS
    VALIDATE_INPUTS
    EXECUTE_SQRT
    PRINT_RESULT

    li a7, 10      # выход из программы
    ecall

.data
prompt: .asciz "Введите число и точность (через Enter):\n"

.include "sqrt.asm"
