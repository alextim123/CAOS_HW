# macros.asm — макросы для RARS

.macro READ_INPUTS
    # ввод числа
    li a7, 7          # read double
    ecall
    fmv.d ft8, fa0    # сохранить значение аргумента

    # ввод точности
    li a7, 7
    ecall
    fmv.d fa1, fa0    # точность -> fa1

    fmv.d fa0, ft8    # восстановить аргумент
.end_macro

.macro VALIDATE_INPUTS
    li t0, 0
    fcvt.d.w f0, t0

    flt.d t1, f0, fa0
    beqz t1, _bad

    flt.d t2, f0, fa1
    beqz t2, _bad
    j _ok

_bad:
    li a7, 4
    la a0, msg_err
    ecall
    li a7, 10
    ecall

_ok:
.end_macro

.macro EXECUTE_SQRT
    jal ra, compute_sqrt
.end_macro

.macro PRINT_RESULT
    li a7, 4
    la a0, msg_res
    ecall

    li a7, 3          # print double
    ecall

    li a7, 4
    la a0, msg_nl
    ecall
.end_macro

.data
msg_err: .asciz "Ошибка: оба числа должны быть положительными!\n"
msg_res: .asciz "Результат sqrt(x): "
msg_nl:  .asciz "\n"
