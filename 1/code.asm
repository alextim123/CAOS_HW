# ============================================================
# RISC-V / RARS: итеративное вычисление числа Фибоначчи
# Ввод:  a7=5 (read_int)  -> пользователь вводит N
# Вывод: строка + число F(N), затем завершение (a7=10)
#
# Принятые обозначения форматов:
#   R  — регистровый (add, sub, mul, ...)
#   I  — рег/непосредственное или load/jalr (addi, lw, jalr, ...)
#   S  — store (sw, sh, ...)
#   B  — ветвление (beq, bne, blt, ...)
#   U  — верхняя часть константы/адреса (lui/auipc)
#   J  — безусловный переход с сохранением PC (jal)
#   SYS — системная инструкция (ecall/ebreak)
#
# Псевдокоманды помечаю «[pseudo]» и показываю типичную развёртку.
# В RARS развёртка адресов через метки обычно даётся в паре U+I: lui + addi,
# либо auipc + addi для PC-relative; ниже указываю один из допустимых вариантов.
# ============================================================

# -----------------------------
# СЕКЦИЯ ДАННЫХ (глобальные объекты)
# -----------------------------
.data

fib_input:   .word 10           # начальное N (необяз.) — 32-битное слово
fib_result:  .word 0            # здесь сохраним F(N)

# Нуль-терминированные строки для консоли (RARS: print_string)
msg_input:   .asciz "Введите N: "
msg_result:  .asciz "F(N) = "

# -----------------------------
# СЕКЦИЯ КОДА
# -----------------------------
.text
.globl main                     # [директива ассемблера] экспорт точки входа

# ------------------------------------------------------------
# main — точка входа
# Регистры вызова (a0..a7) используются для аргументов/результатов и сервис-кодов.
# ------------------------------------------------------------
main:
    # ---- Печатаем приглашение "Введите N: "
    li   a7, 4                 # [pseudo] -> addi a7, x0, 4           (I)
                               # Сервис RARS: 4 = print_string
    la   a0, msg_input         # [pseudo] -> lui a0,%hi(msg_input)    (U)
                               #             addi a0,a0,%lo(msg_input) (I)
    ecall                      # SYS: системная инструкция; RARS читает номер из a7

    # ---- Читаем целое число с клавиатуры
    li   a7, 5                 # [pseudo] -> addi a7, x0, 5           (I)
                               # Сервис RARS: 5 = read_int
    ecall                      # SYS: после вызова введённое число в a0

    # ---- Вызываем функцию вычисления (a0 содержит N)
    jal  ra, compute_fibonacci # J: jal rd,label — rd=ra получает PC+4, затем переход

    # ---- Сохраняем результат в глобальную переменную fib_result
    la   t1, fib_result        # [pseudo] -> lui t1,%hi(fib_result)   (U)
                               #             addi t1,t1,%lo(fib_result) (I)
    sw   a0, 0(t1)             # S: store word — [t1+0] ← a0

    # ---- Печатаем префикс "F(N) = "
    li   a7, 4                 # [pseudo] -> addi a7,x0,4             (I)  print_string
    la   a0, msg_result        # [pseudo] -> lui a0,%hi(msg_result)    (U)
                               #             addi a0,a0,%lo(msg_result) (I)
    ecall                      # SYS

    # ---- Печатаем само число (результат)
    li   a7, 1                 # [pseudo] -> addi a7,x0,1             (I)  print_int
    # Вариант 1 (строго): загрузить адрес и затем lw с базой в регистре:
    la   t2, fib_result        # [pseudo] -> lui t2,%hi(fib_result)    (U)
                               #             addi t2,t2,%lo(fib_result) (I)
    lw   a0, 0(t2)             # I: load word — a0 ← [t2+0]
    # (В некоторых ассемблерах допустимо «lw a0, fib_result» — это тоже псевдо,
    # которое разворачивается в пару U+I с временным регистром.)
    ecall                      # SYS

    # ---- Завершаем программу
    li   a7, 10                # [pseudo] -> addi a7,x0,10            (I)  exit
    ecall                      # SYS

# ------------------------------------------------------------
# compute_fibonacci
# Вход:  a0 = N
# Выход: a0 = F(N)
# Протокол: создаём небольшой кадр стека и используем его как два локала:
#   [sp+0]  = fib_prev (F(i-2))
#   [sp+4]  = fib_curr (F(i-1))
#   [sp+8]  = ra       (сохранённый адрес возврата)
#   [sp+12] = s2       (счётчик i)
# ------------------------------------------------------------
compute_fibonacci:
    addi sp, sp, -16           # I: выделяем 16 байт под фрейм (стек растёт вниз)

    sw   s0,   0(sp)           # S: сохр. s0 (формально не обязателен — демонстрация фрейма)
    sw   s1,   4(sp)           # S: сохр. s1 (аналогично)
    sw   ra,   8(sp)           # S: обязателен при возможных вложенных вызовах
    sw   s2,  12(sp)           # S: будем использовать как счётчик итераций

    # Инициализируем F(0)=0 и F(1)=1 в локалах [sp+0] и [sp+4]
    li   t0, 0                 # [pseudo] -> addi t0,x0,0             (I)
    sw   t0, 0(sp)             # S: fib_prev = 0
    li   t0, 1                 # [pseudo] -> addi t0,x0,1             (I)
    sw   t0, 4(sp)             # S: fib_curr = 1

    # Границы: если N==0 или N==1 — возвращаем сразу
    beq  a0, x0, .ret_zero     # B: если N==0 → .ret_zero
    li   t1, 1                 # [pseudo] -> addi t1,x0,1             (I)
    beq  a0, t1, .ret_one      # B: если N==1 → .ret_one

    # Основной цикл: i от 2 до N включительно
    li   s2, 2                 # [pseudo] -> addi s2,x0,2             (I)  i=2
.loop:
    # Условие выхода: i > N ?
    # В RISC-V нет «bgt», поэтому используем «blt» в обратном виде:
    blt  a0, s2, .done         # B: если N < i  (т.е. i > N) → .done

    # t0 = fib_prev, t1 = fib_curr
    lw   t0, 0(sp)             # I: t0 ← [sp+0]
    lw   t1, 4(sp)             # I: t1 ← [sp+4]

    add  t2, t0, t1            # R: t2 = t0 + t1  (следующее число)

    sw   t1, 0(sp)             # S: fib_prev  ← прежний fib_curr
    sw   t2, 4(sp)             # S: fib_curr  ← t2

    addi s2, s2, 1             # I: i++
    j    .loop                 # [pseudo] -> jal x0, .loop            (J)

.done:
    lw   a0, 4(sp)             # I: результат ← fib_curr
    j    .epilogue             # [pseudo] -> jal x0, .epilogue        (J)

.ret_zero:
    li   a0, 0                 # [pseudo] -> addi a0,x0,0             (I)
    j    .epilogue             # [pseudo] -> jal x0, .epilogue        (J)

.ret_one:
    li   a0, 1                 # [pseudo] -> addi a0,x0,1             (I)
    j    .epilogue             # [pseudo] -> jal x0, .epilogue        (J)

.epilogue:
    lw   s0,   0(sp)           # I: восстановление сохранённого состояния
    lw   s1,   4(sp)           # I
    lw   ra,   8(sp)           # I
    lw   s2,  12(sp)           # I
    addi sp, sp, 16            # I: освобождение кадра стека
    jr   ra                    # I (jalr): возврат по адресу в ra
                               # (jr — псевдокоманда → jalr x0, 0(ra))
