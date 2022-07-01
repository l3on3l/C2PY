#include <stdio.h>

int main() {
    int m1 [][3] = {
        {1,4,6},
        {2,0,5},
        {8,3,3}
    };
    int m2 [3][3], i, j, total;
    
    for (i = 0; i < 3; i++) {
        for (j = 0; j < 3; j++) {
            m2[i][j] = i+j;
        }
    }

    total = 0;
    for (i = 0; i < 3; i++) {
        for (j = 0; j < 3; j++) {
            total += m1[i][j] + m2[i][j];
        }
    }
    printf("Total: %d\n", total);

    return 0;
}