#include"fpga_api.h"
#include<stdio.h>
#include<iostream>
#include<cstring>

using namespace std;

#define min(x,y) (((x)<(y))?(x):(y))

FPGA::FPGA(off_t data_addr, off_t output_addr, int m_size, int v_size)
{
  m_size_ = m_size;
  v_size_ = v_size;

  m1_size_ = v_size * v_size;
  m2_size_ = v_size * v_size;
  data_size_ = (m_size_+1)*v_size_; // fpga bram data size

  data_size_M = (v_size_+v_size_)*v_size_; // for Matrix matrix multiplication

  output_ = new unsigned int[m_size_];    // use output_ as tempolar output
  output_M = new unsigned int[v_size_*v_size_];

  data_ = new float[data_size_];	
  data_M = new float[data_size_M]; // for Matrix matrix multiplication

  num_block_call_ = 0;

  nonzero_idx = new int[v_size_ * v_size_];
}
FPGA::~FPGA()
{
  // delete[] output_;
  delete[] output_M;
  // delete[] data_;
  delete[] data_M;
}

float* FPGA::matrix(void)
{
  return data_ + v_size_;
}

float* FPGA::vector(void)
{
  return data_;
}

float* FPGA::matrix_M1(void)
{
  return data_M;
}

float* FPGA::matrix_M2(void)
{
  return data_M + m1_size_;
}

void FPGA::reset(void)
{
  num_block_call_ = 0;
}

int FPGA::num_block_call(void)
{
  return num_block_call_;
}

const float* FPGA::blockMM()
{
  num_block_call_ += 1;

  // cpu version
  float* m1 = this->matrix_M1();
  float* m2 = this->matrix_M2();
  float* out  = reinterpret_cast<float*>(output_M);  

  for(int i = 0; i < v_size_; ++i)
  {
    for(int j = 0; j < v_size_; ++j){    
      out[v_size_*i+j] = 0;
      for(int k = 0; k < v_size_; ++k){
        out[v_size_*i+j] += m1[v_size_*i+k] * m2[v_size_*k + j];
      }
    }
  }

  for(int i = 0; i < m1_size_; ++i)
    data_M[i] = out[i];

  return data_M;    
}

const float* FPGA::blockMV()
{
  num_block_call_ += 1;

  // cpu version
  float* vec = this->vector();
  float* mat = this->matrix();
  float* out  = reinterpret_cast<float*>(output_);  

  for(int i = 0; i < m_size_; ++i)
  {
    out[i] = 0;
    for(int j = 0; j < v_size_; ++j)
      out[i] += vec[j] * mat[v_size_*i + j];
  }

  for(int i = 0; i < m_size_; ++i)
    data_[i] = out[i];

  return data_;    
}

void FPGA::largeMM(const float* weight_mat, const float* input_mat, float* output, int num_input, int num_output, int num_matrix2)
{
  float* m1 = this->matrix_M1();
  float* m2 = this->matrix_M2();

  // 0) Initialize output vector		
  for(int i = 0; i < num_output*num_matrix2; ++i)
    output[i] = 0;

  for (int act_col = 0; act_col < num_matrix2; act_col += v_size_) {
    int block_act_col = min(v_size_, num_matrix2 - act_col);
    
    // Initialize index array & m2 (for block_act_col could be less than v_size_)
    memset(nonzero_idx, -1, v_size_ * v_size_);
    memset(m2, 0, v_size_ * v_size_);

    while (true) {
      // Search for nonzero indices in each column of activation matrix
      for (int i = 0; i < block_act_col; i++) {
        int idx = 0;
        int j = nonzero_idx[(i + 1) * v_size_ - 1] + 1;
        memset(nonzero_idx + i * v_size_, -1, v_size_);

        // Put nonzero activation in m2 and save the index
        for (; j < num_input && idx < v_size_; ++j) {
          if (input_mat[j * num_matrix2 + act_col + i] != 0) {
            m2[idx * v_size_ + i] = input_mat[j * num_matrix2 + act_col + i];
            nonzero_idx[i * v_size_ + idx] = j;
            idx += 1;
          }
        }

        // Fill in rest of m2 column with zeros
        for (; idx < v_size_; ++idx)
          m2[idx * v_size_ + i] = 0;
      }

      // Fill in m1 and execute MM; reuse m2 several times since the result is overwritten on m1
      for (int weight_row = 0; weight_row < num_output; weight_row += v_size_) {
        int block_weight_row = min(v_size_, num_output - weight_row);

        // Initialize m1 (for block_weight_row could be less than v_size_)
        memset(m1, 0, v_size_ * v_size_);

        // Fill in weights that correspond to nonzero activations
        for (int i = 0; i < block_weight_row; ++i) {
          for (int j = 0; j < v_size_; ++j)
            m1[i * v_size_ + j] = (nonzero_idx[i * v_size_ + j] == -1) ? 0 :
                                    weight_mat[(weight_row + i) * num_input + 
                                      nonzero_idx[i * v_size_ + j]];
        }

        // Execute custom IP
        const float* ret = this->blockMM();

        // Accumulate intermediate results
        for(int n = 0; n < block_weight_row; ++n)
        {
          for(int m = 0; m < block_act_col; ++m)
          {
            output[(weight_row + n) + (act_col + m)*num_output] += ret[n*v_size_ + m];
          }
        }
      }

      int exit_flag = 1;
      for (int i = 0; i < v_size_; ++i) {
        if (nonzero_idx[(i + 1) * v_size_ - 1] != -1 &&
            nonzero_idx[(i + 1) * v_size_ - 1] != num_input - 1)
          exit_flag = 0;
      }
      if (exit_flag)
        break;
    }
  }
}

void FPGA::largeMV(const float* large_mat, const float* input, float* output, int num_input, int num_output)
{
  float* vec = this->vector();
  float* mat = this->matrix();

  // 0) Initialize output vector		
  for(int i = 0; i < num_output; ++i)
    output[i] = 0;

  for(int i = 0; i < num_output; i += m_size_)
  {
    for(int j = 0; j < num_input; j += v_size_)
    {			
      // 0) Initialize input vector
      int block_row = min(m_size_, num_output-i);
      int block_col = min(v_size_, num_input-j);

      // 1) Assign a vector
      // IMPLEMENT THIS
			memcpy(vec, input + j, sizeof(float) * block_col);
			memset(vec + block_col, 0, sizeof(float) * (v_size_ - block_col));

      // 2) Assign a matrix
      // IMPLEMENT THIS
			for (int row = 0; row < block_row; ++row)
			{
				memcpy(mat + row * v_size_, large_mat + (row + i) * 
							num_input + j, sizeof(float) * block_col);
				memset(mat + row * v_size_ + block_col, 0, sizeof(float) * (v_size_ - block_col));
			}
      for (int row = block_row; row < m_size_; ++row) {
				memset(mat + row * v_size_, 0, sizeof(float) * v_size_);
      }

      // 3) Call a function `blockMV() to execute MV multiplication
      const float* ret = this->blockMV();

      // 4) Accumulate intermediate results
      for(int row = 0; row < block_row; ++row)
        output[i + row] += ret[row];
    } 
  }
}

void FPGA::convLowering(const std::vector<std::vector<std::vector<std::vector<float>>>>& cnn_weights,
    std::vector<std::vector<float>>& new_weights,
    const std::vector<std::vector<std::vector<float>>>& inputs,
    std::vector<std::vector<float>>& new_inputs) {
  /*
   * Arguments:
   *
   * conv_weights: [conv_channel, input_channel, conv_height, conv_width]
   * new_weights: [?, ?]
   * inputs: [input_channel, input_height, input_width]
   * new_inputs: [?, ?]
   *
   */

  int conv_channel = cnn_weights.size();
  int input_channel = cnn_weights[0].size();
  int conv_height = cnn_weights[0][0].size();
  int conv_width = cnn_weights[0][0][0].size();
  //int input_channel = cnn_weights.size();
  int input_height = inputs[0].size();
  int input_width = inputs[0][0].size();

  // IMPLEMENT THIS
  // For example,
  // new_weights[0][0] = cnn_weights[0][0][0][0];
  // new_inputs[0][0] = inputs[0][0][0];
  for (int i = 0; i < conv_channel; i++) {
    for (int j = 0; j < input_channel; j++) {
      for (int k = 0; k < conv_height; k++) {
        for (int l = 0; l < conv_width; l++) {
          new_weights[i][j * conv_height * conv_width +
            k * conv_width + l] = cnn_weights[i][j][k][l];
        }
      }
    }
  }
  for (int i = 0; i < input_channel; i++) {
    for (int j = 0; j < input_height - conv_height + 1; j++) {
      for (int k = 0; k < input_width - conv_width + 1; k++) {
        for (int l = 0; l < conv_height; l++) {
          for (int m = 0; m < conv_width; m++) {
            new_inputs[i * conv_height * conv_width + l * conv_width + m][j * (input_height - conv_height + 1) + k] = 
              inputs[i][j + l][k + m];
          }
        }
      }
    }
  }
}
