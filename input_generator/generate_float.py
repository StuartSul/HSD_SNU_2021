import struct
from random import random

def printmatrix(mat):
    for row in mat:
        for elem in row:
            print('{:0.4f}'.format(elem), end=' ' )
        print()

def float_to_hex(f):
    val = hex(struct.unpack('<I', struct.pack('<f', f))[0])
    return str(val)[2:] if (f != 0) else '00000000'

def writematrix(mat, file):
    for row in mat:
        for elem in row:
            file.write('{:0.4f} '.format(elem))
        file.write('\n')
    file.write('\n\n\n')

def generate_input(mat1, mat2, file):
    for row in mat1:
        for elem in row:
            file.write(float_to_hex(elem) + '\n')
    for row in mat2:
        for elem in row:
            file.write(float_to_hex(elem) + '\n')
    
def matmul(mat1, mat2):
    mat3 = []
    for i in range(len(mat1)):
        mat3.append([])
        for j in range(len(mat2[i])):
            mat3[i].append(0)
            for k in range(len(mat2)):
                mat3[i][j] += mat1[i][k] * mat2[k][j]
    return mat3

mat1 = []
mat2 = []
mat_len = 8

for i in range(mat_len):
    mat1.append([])
    mat2.append([])
    for j in range(mat_len):
        mat1[i].append(random())
        mat2[i].append(random())
        # mat1[i].append((i + j) * 0.1)
        # mat2[i].append(1. if (i <= j) else 0.)

with open('out.txt', 'w') as file:
    writematrix(mat1, file)
    writematrix(mat2, file)
    writematrix(matmul(mat1, mat2), file)

with open('input.txt', 'w') as file:
    generate_input(mat1, mat2, file)

