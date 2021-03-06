#ifndef _AST_H_
#define _AST_H_

#include <string>
#include <list>
#include <map>

using namespace std;

extern map<string, int> vars;

enum ExprKind {
  LT_EXPR,
  LTE_EXPR,
  GT_EXPR,
  GTE_EXPR,
  NE_EXPR,
  EQ_EXPR,
  ADD_EXPR,
  SUB_EXPR,
  MULT_EXPR,
  DIV_EXPR,
  MOD_EXPR,
  EXPT_EXPR,
  NUM_EXPR,
  ID_EXPR,
  STRING_EXPR
};

class Expr;
typedef list<Expr*> ExprList;

class Expr {
public:
    virtual int evaluate() = 0;
    virtual int getKind() = 0;
    bool isA(int kind) { return (getKind() == kind); }
};

class BinaryExpr: public Expr {
public:
    BinaryExpr(Expr *expr1, Expr *expr2) {
        this->expr1 = expr1;
        this->expr2 = expr2;
    }

    Expr *expr1;
    Expr *expr2;
};

class LTExpr: public BinaryExpr {
public:
    LTExpr(Expr *expr1, Expr *expr2): BinaryExpr(expr1, expr2) {}

    int evaluate() { return expr1->evaluate() < expr2->evaluate(); }
    int getKind() { return LT_EXPR; }
};

class GTExpr: public BinaryExpr {
public:
    GTExpr(Expr *expr1, Expr *expr2): BinaryExpr(expr1, expr2) {}

    int evaluate() { return expr1->evaluate() > expr2->evaluate(); }
    int getKind() { return GT_EXPR; }
};

class LTEExpr: public BinaryExpr {
public:
    LTEExpr(Expr *expr1, Expr *expr2): BinaryExpr(expr1, expr2) {}

    int evaluate() { return expr1->evaluate() <= expr2->evaluate(); }
    int getKind() { return LTE_EXPR; }
};

class GTEExpr: public BinaryExpr {
public:
    GTEExpr(Expr *expr1, Expr *expr2): BinaryExpr(expr1, expr2) {}

    int evaluate() { return expr1->evaluate() >= expr2->evaluate(); }
    int getKind() { return GTE_EXPR; }
};

class NEExpr: public BinaryExpr {
public:
    NEExpr(Expr *expr1, Expr *expr2): BinaryExpr(expr1, expr2) {}

    int evaluate() { return expr1->evaluate() != expr2->evaluate(); }
    int getKind() { return NE_EXPR; }
};

class EQExpr: public BinaryExpr {
public:
    EQExpr(Expr *expr1, Expr *expr2): BinaryExpr(expr1, expr2) {}

    int evaluate() { return expr1->evaluate() == expr2->evaluate(); }
    int getKind() { return NE_EXPR; }
};

class AddExpr: public BinaryExpr {
public:
    AddExpr(Expr *expr1, Expr *expr2): BinaryExpr(expr1, expr2) {}

    int evaluate() { return expr1->evaluate() + expr2->evaluate(); }
    int getKind() { return ADD_EXPR; }
};

class SubExpr: public BinaryExpr {
public:
    SubExpr(Expr *expr1, Expr *expr2): BinaryExpr(expr1, expr2) {}

    int evaluate() { return expr1->evaluate() - expr2->evaluate(); }
    int getKind() { return SUB_EXPR; }
};

class MultExpr: public BinaryExpr {
public:
    MultExpr(Expr *expr1, Expr *expr2): BinaryExpr(expr1, expr2) {}

    int evaluate() { return expr1->evaluate() * expr2->evaluate(); }
    int getKind() { return MULT_EXPR; }
};

class DivExpr: public BinaryExpr {
public:
    DivExpr(Expr *expr1, Expr *expr2): BinaryExpr(expr1, expr2) {}

    int evaluate() { return expr1->evaluate() / expr2->evaluate(); }
    int getKind() { return DIV_EXPR; }
};

class ModExpr: public BinaryExpr {
public:
    ModExpr(Expr *expr1, Expr *expr2): BinaryExpr(expr1, expr2) {}

    int evaluate() { return expr1->evaluate() % expr2->evaluate(); }
    int getKind() { return EXPT_EXPR; }
};

int expt(int p, unsigned int q);

class ExponentExpr: public BinaryExpr {
public:
    ExponentExpr(Expr *expr1, Expr *expr2): BinaryExpr(expr1, expr2) {}

    int evaluate() { return expt(expr1->evaluate(), expr2->evaluate()); }
    int getKind() { return MOD_EXPR; }
};

class NumExpr: public Expr {
public:
    NumExpr(int value) { this->value = value; }
    int evaluate() { return value; }
    int getKind() { return NUM_EXPR; }

    int value;
};

class IdExpr: public Expr {
public:
    IdExpr(string id) { this->id = id; }
    int evaluate() { return vars[id]; }
    int getKind() { return ID_EXPR; }

    string id;
};

class StringExpr: public Expr {
public:
    StringExpr(string str) { this->str = str; }
    int evaluate() { return 0; }
    int getKind() { return STRING_EXPR; }

    string str;
};

enum StatementKind {
    BLOCK_STATEMENT,
    PRINT_STATEMENT,
    ASSIGN_STATEMENT,
    IF_STATEMENT,
    WHILE_STATEMENT,
	FOR_STATEMENT,
	PASS_STATEMENT
};

class Statement {
public:
    virtual void execute() = 0;
    virtual StatementKind getKind() = 0;
};

class BlockStatement: public Statement {
public:
    BlockStatement() {}
    void execute();
    StatementKind getKind() { return BLOCK_STATEMENT; }
	void add(Statement *st) { stList.push_back(st); }

    list<Statement *> stList;
};

class PrintStatement: public Statement {
public:
    PrintStatement(ExprList lexpr) { this->lexpr = lexpr; }
    void execute();
    StatementKind getKind() { return PRINT_STATEMENT; }

    ExprList lexpr;
};

class AssignStatement: public Statement {
public:
    AssignStatement(string id, Expr *expr) {
        this->id = id;
        this->expr = expr;
    }
    void execute();
    StatementKind getKind() { return ASSIGN_STATEMENT; }

    string id;
    Expr *expr;
};

class IfStatement: public Statement {
public:
    IfStatement(Expr *cond, Statement *trueBlock, Statement *falseBlock) {
        this->cond = cond;
        this->trueBlock = trueBlock;
        this->falseBlock = falseBlock;
    }
    void execute();
    StatementKind getKind() { return IF_STATEMENT; }

    Expr *cond;
    Statement *trueBlock;
    Statement *falseBlock;
};

class WhileStatement: public Statement {
public:
    WhileStatement(Expr *cond, Statement *block) {
        this->cond = cond;
        this->block = block;
    }
    void execute();
    StatementKind getKind() { return WHILE_STATEMENT; }

    Expr *cond;
    Statement *block;
};

class ForStatement: public Statement {
public:
    ForStatement(string id, Expr *startExpr, Expr *endExpr, Statement *block) {
        this->id = id;
		this->startExpr = startExpr;
		this->endExpr = endExpr;
		this->block = block;
    }
    void execute();
    StatementKind getKind() { return FOR_STATEMENT; }

    string id;
	Expr *startExpr;
	Expr *endExpr;
	Statement *block;
};

#endif
