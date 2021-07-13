# HSD_SNU_2021

This is my project repository for **Hardware System Design** course at Seoul National University, 2021 Spring semester.

The goal of my final project (which are inside the folders whose names start with "project_...") was to build a hardware accelerator that accelerates matrix-matrix multiplication operation. Along with building the hardware accelerator itself, I added additional features of 8-bit quantization, zero-skipping, and DMA module in order to speed up the operation even further. The resulting HW-SW system was tested on convolutional and dense layers, and attained up to 2x speedup compared to pure software implementation. The implementation was done with Verilog and C++, and deployed on ZedBoard.

Final Grade : A+
