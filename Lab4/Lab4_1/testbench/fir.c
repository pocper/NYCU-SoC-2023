#include "fir.h"

void __attribute__((section(".mprjram"))) initfir()
{
	// initial your fir
	for(int i = 0; i < N; i++) {
		inputbuffer[i] = 0;
		outputsignal[i] = 0;
	}
}

int *__attribute__((section(".mprjram"))) fir()
{
	initfir();
//--------write down your fir-----------------LAB4-1
		for (int i = 0; i < N; i++)
	{
		for (int j = 0; j < i; j++)
		{
			outputsignal[i] += taps[i - j] * inputsignal[j];
		}
	}
	return outputsignal;
//---------------------------------------------LAB4-1
}

int *__attribute__((section(".mprjram"))) generate_x(int n)
{
//--------write down your fir-----------------LAB4-1

		int t = (n+1) % (4 * amplitude);

        if (t <= amplitude) {
            x[0] = t ;
        } else if (t <= 3 * amplitude) {
            x[0] =( 2 * amplitude - t);
        } else {
            x[0] =( t - 4 * amplitude);
        }
	return x ;

}

int __attribute__((section(".mprjram"))) get_length()
{

	return length ;

}

int *__attribute__((section(".mprjram"))) get_tap()
{

	return taps ;

}