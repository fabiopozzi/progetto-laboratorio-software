#include <stdio.h>
#include <curses.h>
#include <dlfcn.h>

int ctest1(int );
int ctest2(int );

int main()
{
	int x;
        int y;

	char c;
	scanf("%c",&c);
	x = ctest2(5);
        y = ctest1(10);
	printf("Valx=%d\n",x);

	return 0;
}

