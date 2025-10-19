.text
.globl main
.include "macros.asm"

main:
    li t0, 1
loop:
    mv a0, t0
    FAC
    beqz a0, done
    addi t0, t0, 1
    j loop

done:
    addi a0, t0, -1
    li a7, 1
    ecall
    li a7, 10
    ecall

factorial:
    beqz a0, base
    li t1, 1
    beq a0, t1, base

    addi sp, sp, -8
    sw ra, 4(sp)
    sw a0, 0(sp)

    addi a0, a0, -1
    jal ra, factorial
    beqz a0, overflow

    lw t2, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8

    li t3, -1
    divu t4, t3, t2
    bgtu a0, t4, overflow_mul

    mul a0, a0, t2
    jr ra

base:
    li a0, 1
    jr ra

overflow:
    lw ra, 4(sp)
    addi sp, sp, 8
overflow_mul:
    li a0, 0
    jr ra
