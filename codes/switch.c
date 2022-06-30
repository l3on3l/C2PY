#include <stdio.h>

int main()
{
    int dia;

    dia = 2;

    switch ( dia )
    {
         case 1 : 
            printf( "\nLunes" );
            break;
         case 2 : 
            printf( "\nMartes" );
            break;
         case 3 : 
            printf( "\nMiercoles");
            break;
         case 4 : 
            printf( "\nJueves" );
            break;
         case 5 : 
            printf( "\nViernes" );
            break;
         case 6 : 
            printf( "\nSabado");
            break;
         case 7 : 
            printf( "\nDomingo" );
            break;
        default : 
            printf( "\nERROR: Dia incorrecto.");
    }

    return 0;
}