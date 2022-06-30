
/*Header*/
%{

    #define _GNU_SOURCE
	#define T_INT 10
	#define T_CHAR 20
	#define T_FLOAT 30
	#define T_DOUBLE 40
	#define T_FUNCTION 50
	#define TRUE 1
	#define FALSE 0
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    /*Data structures for links in symbol lookahead*/
    struct symrec{
        char *name;             //Symbol name
        int type;               //Symbol type
        double value;           //Variable lookahead value
		int data_type;
        int function;           //Function
        struct symrec *next;    //Next register pointer
    };

    typedef struct symrec symrec;

    /*Symbol table*/
    extern symrec *sym_table;

    /*Symbol table interactions*/
    symrec *putsym ();
    symrec *getsym ();

    extern int yylex(void);
    extern FILE *yyin;      //Source file to be translated
    extern char *yytext;    //Recognizes input tokens
    extern int line_number; //Line number
	extern void print_type();

    FILE *yy_output;        //Object file
    
    symrec *sym_table = (symrec *)0;
    symrec *s;
    symrec *symtable_set_type;
    
    int yyerror(char *s);       //Error function

    int is_function=0;          //Is a function (flag)
	int is_switch = FALSE;
    int error=0;                //Error flag
    int global = 0;             //Global var falg
    int ind = 0;                //Indentation
	int current_type;
    //int function_definition = 0;//Funcion definition flag

    /*Creates an indentation*/
    void indent(){
        int temp_ind = ind;
        while (temp_ind > 0){
            fprintf(yy_output, "\t");
            temp_ind -= 1;
        }
    }

    void print(char *token) {
        fprintf(yy_output,token);
    }

%}

%union
{
	int type;
	double value;
	char *name;
	int data_type;
	struct symrec *tptr;
}

/*Op and exp tokens*/
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN SUB_ASSIGN
%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR CONTINUE BREAK RETURN

/*Types tokens*/
%token <name> IDENTIFIER CONSTANT PRINTFF STR
%token <type> CHAR INT SIGNED UNSIGNED FLOAT DOUBLE CONST VOID

/*Other*/
%type <type> type_specifier declaration_specifiers type_qualifier
%type <name> init_direct_declarator direct_declarator declarator init_declarator init_declarator_list function_definition
%type <name> parameter_type_list parameter_list parameter_declaration array_list array_declaration
%type <name> initializer initializer_list
%type <tptr> declaration

%left INC_OP DEC_OP

%nonassoc IF_AUX
%nonassoc ELSE

%start translation_unit

%%

/*If it is an identifier, saves it into the file*/
// @todo: colocar los demas tipos
primary_expr
	: IDENTIFIER { fprintf(yy_output, "%s", yytext); }
	| CONSTANT { fprintf(yy_output, "%s", yytext); }
	/* | declaration */
	| '(' { print("("); } expr ')' { print(")"); }
	;

/*Tokens into the file*/
postfix_expr
	: primary_expr
	| postfix_expr '[' { print("["); }  expr ']' { print("]"); }
	| postfix_expr '(' { print("("); } ')' { print(")"); }
	| postfix_expr '(' { print("("); } argument_expr_list ')' { print(")"); }
	| postfix_expr INC_OP { fprintf(yy_output, "+=1"); }
	| postfix_expr DEC_OP { fprintf(yy_output, "-=1"); }
	;

/*Arguments*/
argument_expr_list
	: assignment_expr
	| argument_expr_list ',' { fprintf(yy_output, ", "); } assignment_expr
	;

/*Unary exprs*/
unary_expr
	: postfix_expr
	| INC_OP { fprintf(yy_output, "+=1"); } unary_expr
	| DEC_OP { fprintf(yy_output, "-=1"); } unary_expr
	;

/*Multiplication, division and mod operators*/
multiplicative_expr
    : unary_expr
	| multiplicative_expr '*' { print("*"); } unary_expr
    | multiplicative_expr '*' { print("*"); } error { yyerrok;}
    | multiplicative_expr '/' { print("/"); } unary_expr
    | multiplicative_expr '/' { print("/"); } error { yyerrok;}
    | multiplicative_expr '%' { print(" %% "); } unary_expr
    | multiplicative_expr '%' { print(" %% "); } error { yyerrok;}
    ;

/*Addition and subtraction*/
additive_expr
	: multiplicative_expr
	| additive_expr '+' { print("+"); } multiplicative_expr
	| additive_expr '-' { print("-"); } multiplicative_expr
    | additive_expr '+' { print("+"); } error { yyerrok;}
	| additive_expr '-' { print("-"); } error { yyerrok;}
	;

/*Relation operators*/
relational_expr
	: additive_expr
    | relational_expr '<' { print("<"); } additive_expr
	| relational_expr '>' { print(">"); } additive_expr
	| relational_expr '<' { print("<"); } error {yyerrok;}
	| relational_expr '>' { print(">"); } error {yyerrok;}
	| relational_expr LE_OP { print("<="); } additive_expr
	| relational_expr GE_OP { print(">="); } additive_expr
	;

/*Equal amd not equal*/
equality_expr
	: relational_expr
    | equality_expr EQ_OP { print("=="); } relational_expr
	| equality_expr NE_OP { print("!="); } relational_expr
	| equality_expr EQ_OP { print("=="); } error {yyerrok;}
	| equality_expr NE_OP { print("!="); } error {yyerrok;}
    ;

/*'Logic AND' operator*/
logical_and_expr
	: equality_expr
	| logical_and_expr AND_OP { fprintf(yy_output, " and "); } equality_expr
	| logical_and_expr AND_OP { fprintf(yy_output, " and "); } error {yyerrok;}
    ;

/*'Logic OR' operator*/
logical_or_expr
	: logical_and_expr
	| logical_or_expr OR_OP { fprintf(yy_output, " or "); } logical_and_expr
    | logical_or_expr OR_OP { fprintf(yy_output, " or "); } error {yyerrok;}
    ;

/*Conditional expr*/
conditional_expr
	: logical_or_expr
	| logical_or_expr '?' { fprintf(yy_output, " ? "); } expr ':' { fprintf(yy_output, " : "); } conditional_expr
	;

/*Assignment expr*/
assignment_expr
	: conditional_expr
	| unary_expr assignment_operator assignment_expr
    | error assignment_operator assignment_expr {yyerrok;}
	;

/*Assignment operators*/
assignment_operator
	: '=' { fprintf(yy_output, " = "); }
	| MUL_ASSIGN { fprintf(yy_output, " *= "); }
	| DIV_ASSIGN { fprintf(yy_output, " /= "); }
	| MOD_ASSIGN { fprintf(yy_output, " %%= "); }
	| ADD_ASSIGN { fprintf(yy_output, " += "); }
	| SUB_ASSIGN { fprintf(yy_output, " -= "); }
	;

/*exprs*/
expr
	: assignment_expr
	| expr ',' { fprintf(yy_output, ", "); } assignment_expr
	;

/*Constant expr*/
constant_expr
	: conditional_expr
	;

/*Declaration*/
declaration
    : declaration_specifiers init_declarator_list ';' {print("\n"); indent();}
    {
        for(symtable_set_type=sym_table; symtable_set_type!=(symrec *)0; symtable_set_type=(symrec *)symtable_set_type->next)
			if(symtable_set_type->type==-1)
				symtable_set_type->type=$1;
	}
	| declaration_specifiers init_declarator_list error { yyerror("A \";\" (semicolon) is missing"); yyerrok; }
	;

/*Specifiers*/
declaration_specifiers
	: type_specifier
	| type_specifier declaration_specifiers
	| type_qualifier
	| type_qualifier declaration_specifiers
	;

/*Declarations*/
init_declarator_list
	: init_declarator
    {
        s = getsym($1);
    	if(s==(symrec *)0) s = putsym($1);
        else {
    		yyerror("Variable previously declared");
    		yyerrok;
    	}
		// print_type();
    }
	// @todo: ver si imprimir el salto de linea
	| init_declarator_list ',' init_declarator { fprintf(yy_output, ""); indent(); }
    {
        s = getsym($3);
        if(s==(symrec *)0) s = putsym($3);
        else {
            yyerror("Variable previously declared");
            yyerrok;
        }
    }
    | init_declarator_list ',' error { yyerror("Error. An extra ',' is received"); }
	;

/*Declarations*/
init_declarator
	: declarator
	| init_direct_declarator '=' initializer { fprintf(yy_output, "%s", $3); }
	;

/*Types*/
type_specifier
	: CHAR {current_type = T_CHAR;}
	| INT  {current_type = T_INT;}
	| FLOAT {current_type = T_FLOAT;}
	| DOUBLE {current_type = T_DOUBLE;}
	| SIGNED
	| UNSIGNED
	| VOID
	;

/*Declarator*/
declarator
	: direct_declarator
	;

/*Functions and arrays*/
direct_declarator
    : IDENTIFIER { if (is_function) /*fprintf(yy_output, "", $1); else */is_function = 0; }
    | IDENTIFIER '[' ']' { if (!is_function) fprintf(yy_output, " %s = [] \n", $1); else is_function = 0; }
	| IDENTIFIER array_list { if (!is_function) fprintf(yy_output, "%s = [%s] \n", $1, $2); else is_function = 0; indent();}
    | IDENTIFIER '[' CONSTANT ']' {fprintf(yy_output, "%s = [0 for i in range(%s)] \n",$1,$3);	indent();}
    | IDENTIFIER '(' ')' { if (!is_function)fprintf(yy_output, "def %s():", $1); else is_function = 0; }
	| IDENTIFIER '(' parameter_type_list ')' { if (!is_function) fprintf(yy_output, "def %s(%s):", $1, $3); else is_function = 0; }
    ;

/*Arrays*/
init_direct_declarator
	: IDENTIFIER { if (!is_function) fprintf(yy_output, "%s = ", $1); else is_function = 0; }
	| IDENTIFIER array_declaration { if (!is_function) fprintf(yy_output, "%s = ", $1); else is_function = 0; } //@todo indent()
	| IDENTIFIER array_list { if (!is_function) fprintf(yy_output, "%s = ", $1); else is_function = 0; }
	;

/*Arrays list*/
array_list
	: array_declaration
	| array_list array_declaration { asprintf(&$$, "%s,%s", $1, $2); }
	;

/*Arrays declaration*/
array_declaration
	: '[' ']' { asprintf(&$$, "[] "); } //@todo indent()
	| '[' CONSTANT ']' { asprintf(&$$, "[0 for i in range(%s)] ",$2);  } //@todo indent()
	;

/*Parameter type*/
parameter_type_list
	: parameter_list
	;

/*Parameter list*/
parameter_list
	: parameter_declaration
	| parameter_list ',' parameter_declaration { asprintf(&$$, "%s, %s", $1, $3); }
	;

/*Parameter declaration*/
parameter_declaration
	: { is_function = 1; } declaration_specifiers declarator { $$ = $3; }
	;

/*Parameter initializer*/
initializer_list
	: initializer
	| initializer_list ',' initializer { asprintf(&$$, "%s, %s", $1, $3); }
	;

/*Exp initializer*/
initializer
	: IDENTIFIER
	| CONSTANT
	| '{' initializer_list '}' { asprintf(&$$, "[%s] \n", $2); }
	;

/*Type qualifier*/
type_qualifier
	: CONST { fprintf(yy_output, "const "); }
	;

output_list
	: IDENTIFIER {fprintf(yy_output, "%s", $1);}
	| output_list ',' IDENTIFIER {fprintf(yy_output, ",%s", $3);}

output
	: PRINTFF '(' STR ')' ';' {fprintf(yy_output, "print(%s)\n", $3); indent();}
	| PRINTFF '(' STR ',' {fprintf(yy_output, "print(%s % (", $3);} output_list ')' ';' {print("))\n"); indent();}

/*Statements*/
statement
	: labeled_statement
	| output
	| compound_statement
	| expr_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	;

/*Open scope*/
open_curly
    : '{'
    {
  		fprintf(yy_output,"\n");
  		ind += 1; 
		indent();
  	}
  	;

/*Close scope*/
close_curly
    : '}'
    {
  		fprintf(yy_output,"\n");
  		ind -= 1; 
		indent();
  	}
  	;

/*Compound statements*/
compound_statement
    : open_curly close_curly
    | open_curly statement_list close_curly
    | open_curly declaration_list close_curly
    | open_curly declaration_list statement_list close_curly
    | '{' error { yyerror("A \"}\" (close curly) is missing"); yyerrok; }
    ;

/*Declarations*/
declaration_list
	: declaration
	| declaration_list declaration
	;

/*Statements*/
statement_list
	: statement
	| statement_list statement
	;

/*expr statement*/
expr_statement
	: ';' { print("\n"); indent(); }
	| expr ';' { print("\n"); indent(); }
    | expr error { yyerror("A \";\" (semicolon) is missing into the statement");yyerrok; }
	;

// INIC CONDITIONAL
// @todo: hacer if anidados el tema del switch.
/*'Else' statement*/
else_statement
	: ELSE { print("else:"); } statement
	| %prec IF_AUX
	;

/*Conditional*/
selection_statement
	: IF { print("if"); } '(' { print("("); } expr ')' { print("):"); } statement  else_statement
    | IF { print("if"); } error expr ')' { print("):"); } statement { yyerror("A \"(\" (open parenthesis) is missing after the 'if' statement");yyerrok; }
	| SWITCH { fprintf(yy_output, "match "); is_switch = TRUE;}'(' expr ')' { print(":"); } statement {is_switch = FALSE;}
	;

/*Labeled statements*/
labeled_statement
	: CASE { fprintf(yy_output, "case "); } constant_expr ':' { fprintf(yy_output, ":\n\t"); indent();} statement {print("\t");}
	| DEFAULT { fprintf(yy_output, "case _ "); } ':' { fprintf(yy_output, ":\n\t "); indent();} statement
	;

// END conditional

// INIC LOOPS
/*While*/
while
    : WHILE { print("while "); }
  	;

// INIC loops
postfix_for
	: IDENTIFIER INC_OP { fprintf(yy_output, "):\t"); indent();}
	| IDENTIFIER DEC_OP { fprintf(yy_output, ",-1):\t"); indent();}
	| INC_OP IDENTIFIER { fprintf(yy_output, "):\t"); indent();}
	| DEC_OP IDENTIFIER { fprintf(yy_output, ",-1):\t"); indent();}
	;

/* assignment_expr */
loops_relational
    : IDENTIFIER '<' CONSTANT ';' { fprintf(yy_output, "%s", $3);} postfix_for ')'
    | IDENTIFIER LE_OP CONSTANT ';' { int n = atoi($3)+1; fprintf(yy_output, "%d", n);} postfix_for ')'
	| IDENTIFIER '<' IDENTIFIER ';' { fprintf(yy_output, "%s", $3);} postfix_for ')'
    | IDENTIFIER LE_OP IDENTIFIER ';' { int n = atoi($3)+1; fprintf(yy_output, "%d", n);} postfix_for ')'
	| IDENTIFIER '>' CONSTANT ';' { fprintf(yy_output, "%s", $3);} postfix_for ')'
    | IDENTIFIER GE_OP CONSTANT ';' { int n = atoi($3)+1; fprintf(yy_output, "%d", n);} postfix_for ')'
	| IDENTIFIER '>' IDENTIFIER ';' { fprintf(yy_output, "%s", $3);} postfix_for ')'
    | IDENTIFIER GE_OP IDENTIFIER ';' { int n = atoi($3)+1; fprintf(yy_output, "%d", n);} postfix_for ')'


/*loops*/
iteration_statement
    : while '(' {print("(");} expr ')' {print("):");} statement
    | while error expr ')' statement { yyerror("A \"(\" (open parenthesis) is missing");yyerrok; }
    | DO { print("while(1):"); indent();} statement WHILE '(' { print("\tif not ("); } expr ')' { print("):\n\t"); indent(); print("\tbreak\n"); } ';' {indent();}
    | FOR '(' IDENTIFIER '=' CONSTANT ';' { fprintf(yy_output, "for %s in range(%s,", $3, $5); } loops_relational
	| FOR '(' IDENTIFIER '=' IDENTIFIER ';' { fprintf(yy_output, "for %s in range(%s,", $3, $5); } loops_relational
	;
// END LOOPS

/*Jumps*/
jump_statement
	: CONTINUE { print("continue");} ';' { print("\n"); indent(); }
	| BREAK    { if(!is_switch) print("break"); } ';' { print("\n"); indent(); }
	| RETURN   { print("return");  } ';' { print("\n"); indent(); }
	| RETURN   { print("return "); } expr ';' { print("\n"); indent(); }
	| CONTINUE error { yyerror("A \";\" (semicolon) is missing after 'continue'"); yyerrok; }
	| BREAK error { yyerror("A \";\" (semicolon) is missing after 'break'"); yyerrok;}
	;

/*Declarations*/
external_declaration
	: function_definition
	| declaration
	;

/*Functions*/
function_definition
	: declaration_specifiers declarator compound_statement
	{
		s = getsym($2);
		if(s==(symrec *)0) s = putsym($2,$1,1);
		else {
			printf("Function already declared.");
			yyerrok;
		}
	}
	| declarator declaration_list compound_statement
  	| declarator compound_statement
	;

/*Translation*/
translation_unit
	: external_declaration
	| translation_unit external_declaration
	;

%%

#include <stdio.h>

/*Error function*/
int yyerror(char *s) {
	error=1;
	printf("Error in the line number %d near \"%s\": (%s)\n", line_number, yylval.name, s);
}

/*Symbol put*/
symrec * putsym(char *sym_name, int sym_type, int b_function) {
	symrec *ptr;
	ptr = (symrec *) malloc(sizeof(symrec));
	ptr->name = (char *) malloc(strlen(sym_name) + 1);
	strcpy(ptr->name, sym_name);
	ptr->type = sym_type;
	ptr->value = 0;
	ptr->function = b_function;
	ptr->data_type = current_type;
	ptr->next =(struct symrec *) sym_table;
	sym_table = ptr;
	return ptr;
	
}

/*Symbol get*/
symrec * getsym(char *sym_name) {
	symrec *ptr;
	for(ptr = sym_table; ptr != (symrec*)0; ptr = (symrec *)ptr->next)
		if(strcmp(ptr->name, sym_name) == 0) return ptr;
	return 0;
}

void print_sym_table()
{
	printf("\n\n\t\t\tSym Table\n");
    symrec *ptr;
    for (ptr = sym_table; ptr != (symrec *)0; ptr = (symrec *)ptr->next) {
        printf("ID:%s\t\t\t Type: %d\t\t data_type: %d\n", ptr->name, ptr->type, ptr->data_type);
	}	
}

void print_type() {
	switch(current_type) {
		case T_INT:
			printf("Int\n"); break;
		case T_CHAR:
			printf("Char\n"); break;
		case T_FLOAT:
			printf("Float\n"); break;
		case T_DOUBLE:
			printf("Double\n"); break;
	}

}

/*Main function*/
int main(int argc,char **argv){
    
	/*Args error*/
	if (argc<3){
		printf("There is missings parameters\n Example of use: %s code.c code.rb\n", argv[0]);
		return 0;
	}
    
    /*File error*/
	if ((yyin = fopen(argv[1],"rt")) == NULL){
		printf("The file could not be opened.\n");
        return 0;
	}
    
    /*File error*/
	if ((yy_output=fopen(argv[2], "w")) == NULL){
		printf("The file could not be opened.\n");
        return 0;
	}

	/*Init translation*/
	yyparse();

	/*Close files adding 'main' at the bottom*/
    print("if __name__ == '__main__':\n");
    print("\tmain()\n");
	fclose(yyin);
	fclose(yy_output);
	// @REMOVE print_sym_table()
	/* print_sym_table(); */
    /*Translation finished: messages*/
	if(error)   printf("ERROR in the translation: %s\n", argv[1]);
	else        printf("SUCCESS translating %s\nTranslated file: %s\n", argv[1], argv[2]);

	return 0;
    
}
