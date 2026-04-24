#include "matmul.h"

int mat_A[SIZE_mat*SIZE_mat] = {
    0, 1, 2, 3,
    0, 1, 2, 3,
    0, 1, 2, 3,
    0, 1, 2, 3,
};
int mat_B[SIZE_mat*SIZE_mat] = {
    1, 2, 3, 4,
    5, 6, 7, 8,
    9, 10, 11, 12,
    13, 14, 15, 16,
};
int result[SIZE_mat*SIZE_mat];

int* __attribute__ ( ( section ( ".mprjram" ) ) ) matmul()
{
	int i=0;
	int j;
	int k;
	int sum;
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
