lui  x2, 0x87850
addi x2, x2, 0x700
addi x2, x2, 0x3BC

addi x3, x0, 96

sw   x2, 0(x3)

add  x4, x0, x0
addi x5, x0, 10
for:
add  x4, x4, x5
addi x5, x5, -1
bge  x5, x0, for

sw   x4, 4(x3)

done:
beq  x0, x0, done
