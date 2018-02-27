%code requires {
    #include "ast.h"
}

%{
#include <stdio.h>
#include <list>
#include <iostream>
#include <string>
using namespace std;
int yylex();
extern int yylineno;

void yyerror(const char* msg){
    printf("%s  in Line : %d\n",msg,yylineno);
}

#define YYERROR_VERBOSE 1  
%}

%union {
    char *charPointer_t;
    int  int_t;
    bool bool_t;
    Statement *statement_t;
	BlockStatement *blkstatement_t;
    Expr *expr_t;
    ExprList *exprlist_t;
}

%token<int_t> TK_NUM
%token<bool_t> TK_TRUE TK_FALSE
%token<charPointer_t> TK_ID
%token<charPointer_t> STRING_LITERAL
%token TK_EOL TK_INC TK_DEC TK_SHIFT_RIGHT TK_SHIFT_LEFT TK_EQUALS TK_NOT_EQUALS TK_LESS_THAN_EQUALS TK_GREATER_THAN_EQUALS
%token TK_LOGICAL_AND TL_LOGICAL_OR TK_DOUBLE_COLON TK_ADD_ASGN TK_SUB_ASGN TK_MULT_ASGN TK_DIV_ASGN TK_MOD_ASGN TK_POW_ASGN
%token TK_PRINT TK_PRINTLN TK_BOOL TK_INT TK_IF TK_ELSE TK_ELSEIF TK_WHILE TK_FOR TK_FUNCTION TK_RETURN
%token TK_ARRAY TK_END TK_ERROR

%type<exprlist_t> argument_expression_list
%type<expr_t> print_argument factor post_id  unary_exp expression term exponent shift_exp
%type<statement_t> print_statement
%type<statement_t> statement
%type<blkstatement_t> statementList

%%

start: opEols statementList opEols {$2->execute();}
;

new_line:  new_line TK_EOL
    | TK_EOL
;

opEols: new_line
    | %empty
;

statementList: statementList TK_EOL statement { $$ = $1; $$->add($3); }
    | statement { $$ = new BlockStatement; $$->add($1); }
;

statement: print_statement  {$$ = $1;}
;

print_statement: TK_PRINT '(' print_argument ')' {$$ = new PrintStatement($3,false);}
    | TK_PRINTLN '(' print_argument ')' {$$ = new PrintStatement($3,true);}
;

print_argument: STRING_LITERAL {$$ = new StringExpr(string($1)); delete $1;}
    | expression
;

argument_expression_list: argument_expression_list ',' expression {$1->push_back($3); $$=$1; }
    | expression {$$ = new ExprList;}
;

expression: shift_exp {$$ = $1;}
;

shift_exp: shift_exp TK_SHIFT_LEFT term {$$ = new LeftShiftExpr($1,$3);}
    | shift_exp TK_SHIFT_RIGHT term {$$ = new RightShiftExpr($1,$3);}
    | term { $$ = $1;}
;

term: term '*' exponent { $$ = new MulExpr($1,$3);}
    | term '/' exponent { $$ = new DivExpr($1,$3);}
    | term '%' exponent { $$ = new ModExpr($1,$3);}
    | exponent  { $$ = $1; }
;

exponent: exponent '^' unary_exp {$$ = new ExponentExpr($1,$3);}
    | unary_exp {$$ = $1;}
;

unary_exp: '-' unary_exp {$$ = new UnarySubExpr($2);}
    | '+' unary_exp {$$ = new UnaryAddExpr($2);}
    | '~' unary_exp {$$ = new UnaryDistintExpr($2);}
    | '!' unary_exp {$$ = new UnaryNotExpr($2);}
    | post_id {$$ = $1;}
;

post_id: factor {$$ = $1;}
    | TK_ID '(' argument_expression_list ')' {$$ = new ParenthesisPosIdExpr(string($1),$3); delete $1;}
    | TK_ID '(' ')' {$$ = new ParenthesisPosIdExpr(string($1)); delete $1;}
    | TK_ID '[' TK_NUM ']' {$$ = new BracketPostIdExpr(string($1),$3); delete $1;}
;

factor: TK_NUM  {$$ = new NumberExpr($1);}
    | TK_TRUE   {$$ = new BoolExpr($1);}
    | TK_FALSE {$$ = new BoolExpr($1);}
    | TK_ID     {$$ = new VarExpr(string($1)); delete $1;}
    | '(' expression ')' {$$ = $2;}
;
%%