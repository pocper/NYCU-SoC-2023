#include "qsort.h"

int __attribute__ ( ( section ( ".mprjram" ) ) ) partition(int low,int hi){
	int pivot = arr_A[hi];
	int i = low-1,j;
	int temp;
	for(j = low;j<hi;j++){
		if(arr_A[j] < pivot){
			i = i+1;
			temp = arr_A[i];
			arr_A[i] = arr_A[j];
			arr_A[j] = temp;
		}
	}
	if(arr_A[hi] < arr_A[i+1]){
		temp = arr_A[i+1];
		arr_A[i+1] = arr_A[hi];
		arr_A[hi] = temp;
	}
	return i+1;
}

void __attribute__ ( ( section ( ".mprjram" ) ) ) sort(int low, int hi){
	if(low < hi){
		int p = partition(low, hi);
		sort(low,p-1);
		sort(p+1,hi);
	}
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) qsort(){
	sort(0,SIZE_arr-1);
	return arr_A;
}
