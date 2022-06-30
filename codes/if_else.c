#include <stdio.h>

int main() {
	int x;
    x = 5;
		
	if(x >= 0) {
		printf("El valor es positivo.\n");
	} else {
		printf("El valor es negativo.\n");
	}
	
	if(x >= 0 && x <= 9) {
		printf("El valor tiene un digito.\n");
	} else {
		printf("El valor tiene mas de un digito.\n");
	}
	
	return 0;
}