#ifndef _MATMUL_H
#define _MATMUL_H

#define SIZE_mat 4
int mat_A[SIZE_mat*SIZE_mat] = {0, 1, 2, 3,
		0, 1, 2, 3,
		0, 1, 2, 3,
		0, 1, 2, 3,
};
int mat_B[SIZE_mat*SIZE_mat] = {1, 2, 3, 4,
	5, 6, 7, 8,
	9, 10, 11, 12,
	13, 14, 15, 16,
};
int result[SIZE_mat*SIZE_mat];
#endif
