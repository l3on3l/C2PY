all: flex bison gcc

flex:
	flex lex.l

bison:
	bison -yd yacc.y

gcc:
	gcc lex.yy.c y.tab.c -o c2py

clean:
	rm lex.yy.c y.tab.c y.tab.h c2py *.py
