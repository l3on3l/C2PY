#include <stdio.h>

int main() {
    int i, mayor, posMayor, n;
    int vector[] = {3,4,12,1,9};
    posMayor = 0;

    mayor = vector[0];
    for(i = 1; i < n; ++i)
    {
        if(vector[i] > mayor)
        {
            mayor = vector[i];
            posMayor = i;
        }
    }

    printf("El numero mayor fue: %d (indice: %d)\n", mayor, posMayor);	
    
    return 0;
}