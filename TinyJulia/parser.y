%code requires {
    #include "ast.h"
}

%{
#include "ast.h"
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

BlockStatement *statement;

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
    primitiveType primitiveType_t;
}

%token<int_t> TK_NUM
%token<bool_t> TK_TRUE TK_FALSE
%token<charPointer_t> TK_ID
%token<charPointer_t> STRING_LITERAL
%token TK_EOL TK_INC TK_DEC TK_SHIFT_RIGHT TK_SHIFT_LEFT TK_EQUALS TK_NOT_EQUALS TK_LESS_THAN_EQUALS TK_GREATER_THAN_EQUALS TK_IN
%token TK_LOGICAL_AND TL_LOGICAL_OR TK_DOUBLE_COLON TK_ADD_ASGN TK_SUB_ASGN TK_MULT_ASGN TK_DIV_ASGN TK_MOD_ASGN TK_POW_ASGN TK_BIT_AND_ASGN
%token TK_PRINT TK_PRINTLN TK_BOOL TK_INT TK_IF TK_ELSE TK_ELSEIF TK_WHILE TK_FOR TK_FUNCTION TK_RETURN TK_BIT_XOR_ASGN TK_BIT_OR_ASGN
%token TK_ARRAY TK_END TK_ERROR TK_BREAK TK_CONTINUE

%type<exprlist_t> argument_expression_list print_arguments param_list op_param_list
%type<expr_t> print_argument factor post_id unary_exp expression term exponent  aritmethic bit_and_exp shift_exp op_decAsgn
%type<expr_t> conditional_and_exp conditional_or_exp  assign_exp relational_expr param bit_or_exp bit_xor_exp
%type<statement_t> print_statement expression_statement while_statement for_statement if_statement elseif fun_statement
%type<statement_t> statement block_statement declaration_statement function_statement break_statement continue_statement return_statement
%type<blkstatement_t> statementList function_statement_list
%type<primitiveType_t> type function_type arr_type

%%

start: opEols statementList opEols {statement = $2;}
;

new_line:  new_line TK_EOL
    | TK_EOL
    | ';'
;

opEols: new_line
    | %empty
;


statementList: statementList new_line statement { $$ = $1; $$->add($3); }
    | statement { $$ = new BlockStatement; $$->add($1); }
;

function_statement_list: function_statement_list new_line fun_statement { $$ = $1; $$->add($3); }
    | fun_statement { $$ = new BlockStatement; $$->add($1);}
;

statement: print_statement  {$$ = $1;}
    | declaration_statement {$$ = $1;}
    | function_statement {$$ = $1;}
    | expression_statement  {$$ = $1;}
    | while_statement {$$ = $1;}
    | for_statement {$$ = $1;}
    | if_statement {$$ = $1;}
    | break_statement {$$ = $1;}
    | continue_statement {$$ = $1;}
    | return_statement {$$ = $1;}
;

fun_statement: print_statement  {$$ = $1;}
    | declaration_statement {$$ = $1;}
    | expression_statement  {$$ = $1;}
    | while_statement {$$ = $1;}
    | for_statement {$$ = $1;}
    | if_statement {$$ = $1;}
    | break_statement {$$ = $1;}
    | continue_statement {$$ = $1;}
    | return_statement {$$ = $1;}
;

return_statement: TK_RETURN expression  {$$ = new ReturnStatement($2); }
;

break_statement: TK_BREAK {$$ = new BreakStatement();}
;

continue_statement: TK_CONTINUE {$$ = new ContinueStatement();}
;

function_statement: TK_FUNCTION TK_ID '(' op_param_list ')' function_type block_statement TK_END { $$ = new FunctionStatement(string($2),$4,$6,$7); delete $2;}
;

function_type: type {$$ = $1;}
    | %empty {$$ =primitiveType::VOID_TYPE; }

op_param_list: param_list {$$ = $1;}
    | %empty {$$ =new ExprList;}
;

param_list: param_list ',' param {$1->push_back($3); $$=$1;}
    | param {auto exl= new ExprList; exl->push_back($1); $$=exl;}
;

param: TK_ID type { $$ = new ParamExpr(string($1),$2); delete $1;}
;

declaration_statement: TK_ID type op_decAsgn {$$ = new DeclarationStatement(string($1),$2,$3); delete $1;}
    | TK_ID arr_type '=' '[' argument_expression_list ']' {$$ = new DeclarationStatement(string($1),$2,new ArrayExpr($5)); delete $1;}
;


op_decAsgn: '=' expression {$$ = $2;}
    | %empty {$$ = new NumberExpr(0);}
;

arr_type: TK_DOUBLE_COLON TK_ARRAY'{' TK_INT '}' {$$ = primitiveType::ARRAY_INT_TYPE;}
    | TK_DOUBLE_COLON TK_ARRAY'{' TK_BOOL '}' {$$ = primitiveType::ARRAY_BOOL_TYPE;}
;

type: TK_DOUBLE_COLON TK_INT {$$ = primitiveType::INT_TYPE;}
    | TK_DOUBLE_COLON TK_BOOL {$$ = primitiveType::BOOL_TYPE;}
;

if_statement: TK_IF expression block_statement elseif {$$ = new IfStatement($2,$3,$4);}
;

elseif: TK_ELSEIF expression block_statement elseif {$$ = new IfStatement($2,$3,$4);}
    | TK_ELSE block_statement TK_END {$$ = $2;}
    | TK_END {$$=NULL;}
;

for_statement: TK_FOR TK_ID for_tk expression  ':' expression block_statement TK_END {$$= new ForStatement(string($2),$4,$6,$7); delete $2;}
;

for_tk: '='
    | TK_IN
;

while_statement: TK_WHILE expression block_statement TK_END {$$ = new WhileStatement($2,$3);}
;

block_statement: TK_EOL opEols function_statement_list opEols {$$ = $3;}
    | TK_EOL opEols { auto bs = new BlockStatement(); bs->stList = list<Statement*>(); $$ = new BlockStatement();}
;

print_statement: TK_PRINT '(' print_arguments ')' {$$ = new PrintStatement($3,false);}
    | TK_PRINTLN '(' print_arguments ')' {$$ = new PrintStatement($3,true);}
;

print_arguments: print_arguments ',' print_argument {$1->push_back($3); $$=$1; }
    | print_argument {auto exl= new ExprList; exl->push_back($1); $$=exl;}
;

print_argument: STRING_LITERAL {$$ = new StringExpr(string($1)); delete $1;}
    | expression {$$ = $1;}
;

expression_statement: expression {$$ = new ExprStatement($1);}
;

argument_expression_list: argument_expression_list ',' expression {$1->push_back($3); $$=$1; }
    | expression {auto exl= new ExprList; exl->push_back($1); $$=exl;}
;

expression: assign_exp {$$ = $1;}
;

assign_exp: post_id '=' assign_exp {$$ = new AssignExpr($1,$3);}
    | post_id TK_ADD_ASGN assign_exp {$$ = new AssignExpr($1,new AddExpr($1,$3));}
    | post_id TK_SUB_ASGN assign_exp {$$ = new AssignExpr($1,new SubExpr($1,$3));}
    | post_id TK_MULT_ASGN assign_exp {$$ = new AssignExpr($1,new MulExpr($1,$3));}
    | post_id TK_DIV_ASGN assign_exp {$$ = new AssignExpr($1,new DivExpr($1,$3));}
    | post_id TK_MOD_ASGN assign_exp {$$ = new AssignExpr($1,new ModExpr($1,$3));}
    | post_id TK_POW_ASGN assign_exp {$$ = new AssignExpr($1,new ExponentExpr($1,$3));}
    | conditional_or_exp {$$ = $1;}
;

conditional_or_exp: conditional_or_exp TL_LOGICAL_OR conditional_and_exp {$$ = new LogicalOrExpr($1,$3);}
    | conditional_and_exp {$$ =$1;}
;

conditional_and_exp: conditional_and_exp TK_LOGICAL_AND bit_or_exp {$$ = new LogicalAndExpr($1,$3);}
    | bit_or_exp {$$ = $1;}
;

bit_or_exp: bit_or_exp '|' bit_xor_exp {$$ = new BitOrExpr($1,$3);}
    | bit_xor_exp {$$ =$1;}
;

bit_xor_exp: bit_xor_exp '$' bit_and_exp {$$ = new BitXorExpr($1,$3);}
    | bit_and_exp {$$ =$1;}
;

bit_and_exp: bit_and_exp '&' relational_expr {$$ = new BitAndExpr($1,$3);}
    | relational_expr {$$ = $1;}
;
relational_expr: relational_expr TK_EQUALS aritmethic {$$ = new EqualExpr($1,$3);} 
    | relational_expr TK_NOT_EQUALS aritmethic {$$ = new NotEqualExpr($1,$3);} 
    | relational_expr '>' aritmethic {$$ = new GreaterThanExpr($1,$3);}
    | relational_expr '<' aritmethic {$$ = new LessThanExpr($1,$3);}
    | relational_expr TK_GREATER_THAN_EQUALS aritmethic {$$ = new GreaterThanEqualsExpr($1,$3);}
    | relational_expr TK_LESS_THAN_EQUALS aritmethic {$$ = new LessThanEqualsExpr($1,$3);}
    | aritmethic {$$ =$1;}
;

aritmethic: aritmethic '-' shift_exp {$$ = new SubExpr($1,$3);}
    | aritmethic '+' shift_exp {$$ = new AddExpr($1,$3);}
    | shift_exp {$$ = $1;}
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

unary_exp: '-' unary_exp {$$ = new UnarySubExpr(new MulExpr($2,new NumberExpr(-1)));}
    | '~' unary_exp {$$ = new UnaryNotExpr($2);}
    | '+' unary_exp {$$ = new UnaryAddExpr($2);}
    | '!' unary_exp {$$ = new UnaryDistintExpr($2);}
    | post_id {$$ = $1;}
;

post_id: factor {$$ = $1;}
    | TK_ID '(' argument_expression_list ')' {$$ = new ParenthesisPosIdExpr(string($1),$3); delete $1;}
    | TK_ID '(' ')' {$$ = new ParenthesisPosIdExpr(string($1)); delete $1;}
    | TK_ID '[' expression ']' {$$ = new BracketPostIdExpr(string($1),$3); delete $1;}
;

factor: TK_NUM  {$$ = new NumberExpr($1);}
    | TK_TRUE   {$$ = new BoolExpr(true);}
    | TK_FALSE {$$ = new BoolExpr(false);}
    | TK_ID     {$$ = new VarExpr(string($1)); delete $1;}
    | '(' expression ')' {$$ = $2;}
;
%%
