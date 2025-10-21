# sqrt.asm — подпрограмма вычисления квадратного корня

.text
.globl compute_sqrt

compute_sqrt:
    fmv.d f2, fa0     # исходное число
    fmv.d f3, fa1     # точность eps

    li t0, 1
    fcvt.d.w f0, t0   # начальное приближение 1.0
    li t1, 2
    fcvt.d.w f1, t1   # константа 2.0

loop_iter:
    fdiv.d f4, f2, f0
    fadd.d f5, f0, f4
    fdiv.d f5, f5, f1
    fsub.d f6, f5, f0
    fabs.d f6, f6
    flt.d t2, f6, f3
    bnez t2, done
    fmv.d f0, f5
    j loop_iter

done:
    fmv.d fa0, f5
    jr ra
