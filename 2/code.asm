# ============================================================
# RISC-V / RARS
# ЦЕЛОЧИСЛЬНОЕ ДЕЛЕНИЕ СО ЗНАКОМ (через вычитания и циклы)
#
# Ввод:  два целых числа (делимое, делитель)
# Вывод: частное и остаток (по правилам C/C++)
# Проверка: деление на ноль
#
# Особенности:
#  - Используются только вычитания, ветвления и циклы
#  - Остаток имеет тот же знак, что делимое
#  - Корректно обрабатываются все комбинации знаков
#
# ============================================================

.data
msg_dividend: .asciz "Введите делимое: "
msg_divisor:  .asciz "Введите делитель: "
msg_result_q: .asciz "Частное: "
msg_result_r: .asciz "Остаток: "
msg_err_div0: .asciz "Ошибка: деление на ноль!\n"
newline:      .asciz "\n"

.text
.globl main

# ------------------------------------------------------------
# main — точка входа
# ------------------------------------------------------------
main:
    # ---- Запрос делимого ----
    li   a7, 4                 # [pseudo] -> addi a7,x0,4 (I) — print_string
    la   a0, msg_dividend      # [pseudo] -> lui a0,%hi(msg_dividend); addi a0,a0,%lo(msg_dividend)
    ecall                      # SYS

    li   a7, 5                 # [pseudo] -> addi a7,x0,5 (I) — read_int
    ecall
    mv   s0, a0                # [pseudo] -> add s0,a0,x0 (R)

    # ---- Запрос делителя ----
    li   a7, 4
    la   a0, msg_divisor
    ecall

    li   a7, 5
    ecall
    mv   s1, a0

    # ---- Проверка деления на ноль ----
    beq  s1, x0, .div_zero     # B: если делитель == 0 → ошибка

    # ---- Вызов деления ----
    mv   a0, s0                # делимое
    mv   a1, s1                # делитель
    jal  ra, division_signed   # J: jal rd,label — вызов функции

    mv   s2, a0                # частное
    mv   s3, a1                # остаток

    # ---- Вывод частного ----
    li   a7, 4
    la   a0, msg_result_q
    ecall

    li   a7, 1
    mv   a0, s2
    ecall

    li   a7, 4
    la   a0, newline
    ecall

    # ---- Вывод остатка ----
    li   a7, 4
    la   a0, msg_result_r
    ecall

    li   a7, 1
    mv   a0, s3
    ecall

    li   a7, 4
    la   a0, newline
    ecall

    # ---- Завершение ----
    li   a7, 10
    ecall

.div_zero:
    li   a7, 4
    la   a0, msg_err_div0
    ecall
    li   a7, 10
    ecall

# ------------------------------------------------------------
# division_signed — деление со знаком (итеративное)
# Вход: a0 = dividend, a1 = divisor
# Выход: a0 = quotient, a1 = remainder
# ------------------------------------------------------------
division_signed:
    addi sp, sp, -12           # I: создаём фрейм
    sw   ra,  0(sp)
    sw   s0,  4(sp)
    sw   s1,  8(sp)

    # ---- Подготовка: определяем знаки ----
    mv   s0, a0                # s0 = делимое
    mv   s1, a1                # s1 = делитель
    li   t6, 0                 # флаг знака частного (0=+, 1=-)

    bltz s0, .neg_dividend     # если делимое < 0
    j    .check_divisor

.neg_dividend:
    sub  s0, x0, s0            # s0 = -s0
    xori t6, t6, 1             # переключаем знак результата
    j    .check_divisor

.check_divisor:
    bltz s1, .neg_divisor
    j    .init

.neg_divisor:
    sub  s1, x0, s1
    xori t6, t6, 1

# ---- Инициализация ----
.init:
    li   t0, 0                 # quotient = 0
    mv   t1, s0                # remainder = dividend

.loop:
    blt  t1, s1, .done         # пока remainder >= divisor
    sub  t1, t1, s1
    addi t0, t0, 1
    j    .loop

.done:
    # ---- Коррекция знаков ----
    beqz t6, .skip_sign        # если знак положительный — пропускаем
    sub  t0, x0, t0            # quotient = -quotient

.skip_sign:
    # ---- Коррекция остатка по C/C++ ----
    # Остаток имеет знак делимого, если делимое < 0 и remainder != 0 → remainder = -remainder
    mv   a0, s0
    mv   a1, t1
    bltz a0, .check_nonzero
    j    .finish

.check_nonzero:
    beqz a1, .finish
    sub  a1, x0, a1

.finish:
    mv   a0, t0                # a0 = quotient
    # a1 уже содержит корректный remainder

    # ---- Восстанавливаем стек ----
    lw   ra,  0(sp)
    lw   s0,  4(sp)
    lw   s1,  8(sp)
    addi sp, sp, 12
    jr   ra                    # [pseudo] -> jalr x0, 0(ra)
