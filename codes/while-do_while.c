#include <stdio.h>

int main() {
	int x;

	x = 0;
	while(x < 10) {
		x++;
	}
    printf("while, x: %d\n", x);

	x = 0;
	do {
        x++;
    } while (x < 10);
    printf("do while, x: %d\n", x);

	return 0;
}