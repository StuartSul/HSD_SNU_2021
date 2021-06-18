import struct
from random import random

def printmatrix(mat):
    for row in mat:
        for elem in row:
            print('{:0.4f}'.format(elem), end=' ' )
        print()

def writematrix(mat, file):
    for row in mat:
        for elem in row:
            file.write('{} '.format(elem))
        file.write('\n')
    file.write('\n\n\n')

def generate_input(mat1, mat2, file):
    cnt = 0
    line = ''
    for mat in [mat1, mat2]:
        for row in mat:
            for elem in row:
                if elem >= 16:
                    line = str(hex(elem))[2:] + line
                else:
                    line = '0' + str(hex(elem))[2:] + line
                cnt += 1
                if cnt % 4 == 0:
                    file.write(line + "\n")
                    line = ''
        for i in range(64 - 16):
            file.write('0\n')
    
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
        mat1[i].append(int((random()) * 127))
        mat2[i].append(int((random()) * 127))

with open('out.txt', 'w') as file:
    writematrix(mat1, file)
    writematrix(mat2, file)
    writematrix(matmul(mat1, mat2), file)

with open('input.txt', 'w') as file:
    generate_input(mat1, mat2, file)

