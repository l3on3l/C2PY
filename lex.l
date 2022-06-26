/*Definitions*/
DIGIT       [0-9]
LETTER      [a-zA-Z_]
HEXA        [a-fA-F0-9]
EXPONENTIAL [Ee][+-]?{DIGIT}+
FS          (f|F|l|LETTER)
IS          (u|U|l|LETTER)*


/*Header*/
%{

    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    #include <ctype.h>
    #include "y.tab.h"

    /*Data structures for links in symbol lookahead*/
    struct symrec{
        char *name;             //Symbol name
        int type;               //Symbol type
        double value;           //Variable lookahead value
        int function;           //Function
        struct symrec *next;    //Next register pointer
    };

    typedef struct symrec symrec;

    /*Symbol table*/
    extern symrec *sym_table;

    /*Symbol table interactions*/
    symrec *putsym ();
    symrec *getsym ();

    int line_number;            //Line number
    void comment(void);         //Comments
    void line_comment(void);    //Line comment
    void count();               //Counter

%}

/*Tokens definition*/
%%

"/*"                                            { comment(); }
"//"                                            { line_comment(); }
"#include ""<"((_|{LETTER}*)"."{LETTER}*)">"    { }
"const"                                         { return(CONST); }

"char"                                          { yylval.type = CHAR; return(CHAR); }
"double"                                        { yylval.type = DOUBLE; return(DOUBLE); }
"float"                                         { yylval.type = FLOAT; return(FLOAT); }
"int"                                           { yylval.type = INT; return(INT); }
"long"                                          { yylval.type = LONG; return(LONG); }
"signed"                                        { yylval.type = SIGNED; return(SIGNED); }
"unsigned"                                      { yylval.type = UNSIGNED; return(UNSIGNED); }
"void"                                          { yylval.type = VOID; return(VOID); }

"continue"                                      { return CONTINUE; }
"default"                                       { return DEFAULT; }
"do"                                            { return DO; }
"if"                                            { return IF; }
"else"                                          { return ELSE; }
"switch"                                        { return SWITCH; }
"case"                                          { return CASE; }
"for"                                           { return FOR; }
"while"                                         { return WHILE; }
"return"                                        { return RETURN; }
"break"                                         { return BREAK; }

{LETTER}({LETTER}|{DIGIT})*                     { yylval.name = strdup(yytext); return(IDENTIFIER); }
0[xX]{HEXA}+{IS}?                               { yylval.name = strdup(yytext); return(CONSTANT); }
0{DIGIT}+{IS}?                                  { yylval.name = strdup(yytext); return(CONSTANT); }
{DIGIT}+{IS}?                                   { yylval.name = strdup(yytext); return(CONSTANT); }
LETTER?'(\\.|[^\\'])+'                          { yylval.name = strdup(yytext); return(CONSTANT); }

('-')?{DIGIT}+{EXPONENTIAL}{FS}?                { yylval.name = strdup(yytext); return(CONSTANT); }
('-')?{DIGIT}*"."{DIGIT}+({EXPONENTIAL})?{FS}?  { yylval.name = strdup(yytext); return(CONSTANT); }
('-')?{DIGIT}+"."{DIGIT}*({EXPONENTIAL})?{FS}?  { yylval.name = strdup(yytext); return(CONSTANT); }

">>="                                           { return(RIGHT_ASSIGN); }
"<<="                                           { return(LEFT_ASSIGN); }
"+="                                            { return(ADD_ASSIGN); }
"-="                                            { return(SUB_ASSIGN); }
"*="                                            { return(MUL_ASSIGN); }
"/="                                            { return(DIV_ASSIGN); }
"%="                                            { return(MOD_ASSIGN); }
"&="                                            { return(AND_ASSIGN); }
"^="                                            { return(XOR_ASSIGN); }
"|="                                            { return(OR_ASSIGN); }
">>"                                            { return(RIGHT_OP); }
"<<"                                            { return(LEFT_OP); }
"++"                                            { return(INC_OP); }
"--"                                            { return(DEC_OP); }
"&&"                                            { return(AND_OP); }
"||"                                            { return(OR_OP); }
"<="                                            { return(LE_OP); }
">="                                            { return(GE_OP); }
"=="                                            { return(EQ_OP); }
"!="                                            { return(NE_OP); }
";"                                             { return(';'); }
","                                             { return(','); }
("{"|"<%")                                      { return('{'); }
"-"                                             { return('-'); }
"+"                                             { return('+'); }
"*"                                             { return('*'); }
"/"                                             { return('/'); }
"%"                                             { return('%'); }
"<"                                             { return('<'); }
">"                                             { return('>'); }
"^"                                             { return('^'); }
"|"                                             { return('|'); }
"?"                                             { return('?'); }
("}"|"%>")                                      { return('}'); }
":"                                             { return(':'); }
"="                                             { return('='); }
"("                                             { return('('); }
")"                                             { return(')'); }
("["|"<:")                                      { return('['); }
("]"|":>")                                      { return(']'); }
"."                                             { return('.'); }
"&"                                             { return('&'); }
"!"                                             { return('!'); }
"~"                                             { return('~'); }

[ \t\v\f]                                       { count(); }
\n                                              { ++line_number; }
.                                               { /*Unkown chars*/ }

%%

int yywrap(){
    return(1);
}

int column = 0;

/*Counts the end of the input, spaces and tabs*/
void count(){
    int i;
    for (i = 0; yytext[i] != '\0'; i++){
        if (yytext[i] == '\n')      column = 0;
        else if (yytext[i] == '\t') column += 8 - (column % 8);
        else                        column++;
    }
}

/*Locates the cursor at the end of a comment*/
void comment(void){
    
    //Saves the actual character and the lookahead
    int cursor = input();
    int lookahead = input();

    while (lookahead != EOF && !(cursor == '*' && lookahead == '/')){
        
        //Increases the line counter
        if (cursor == '\n') ++line_number;
        
        //Forwards the cursor position and lookahead
        cursor = lookahead;
        lookahead = input();
        
    }

    //Makes sure the comment has close
    if(lookahead == EOF) printf("The comment has not been closed.\n");
    
}

/*Forwards the cursor to the end of a line comment*/
void line_comment(){
   
    //Cursor
    int cursor = input();

    //Goes through the lookahead until the new line is found
    while (cursor != '\n' && cursor != EOF) cursor = input();

    //Increases the line counter if a new line is found
    if(cursor == '\n') line_number += 1;
    
}
