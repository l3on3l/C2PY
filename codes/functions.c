#include <stdio.h>

void fibbonacci (int n) {
    int t1, t2, nextTerm;
	t1 = 0;
	t2 = 1; 
	nextTerm = 0;

	printf("Fibonacci Series: %d, %d, ", t1, t2);
	nextTerm = t1 + t2;

	while (nextTerm <= n) {
		printf("%d, ", nextTerm);
		t1 = t2;
		t2 = nextTerm;
		nextTerm = t1 + t2;
	}
}

int main() {
    fibbonacci(10);

    return 0;
}