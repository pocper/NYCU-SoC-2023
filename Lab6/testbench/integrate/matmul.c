#include "matmul.h"

int* __attribute__ ( ( section ( ".mprjram" ) ) ) matmul()
{
	int i=0;
	int j;
	int k;
	int sum;
	int kk;
	unsigned int count = 0;
	for (i=0; i<SIZE_mat; i++){
		for (j=0; j<SIZE_mat; j++){
			sum = 0;
			for(k = 0;k<SIZE_mat;k++)
				sum += mat_A[(i*SIZE_mat) + k] * mat_B[(k*SIZE_mat) + j];
			result[(i*SIZE_mat) + j] = sum;
		}
	}
	return result;
}
