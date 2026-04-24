#define TIMES_RERUN 3

extern void fir();

void main()
{
	for(int i=0;i<TIMES_RERUN;i++)
		fir();
}