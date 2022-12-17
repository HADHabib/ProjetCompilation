%{
open Ast
%}
%token <string> ID
%token <int> CSTE
%token <string> STRING
%token <Ast.opComp> RELOP
%token PLUS MINUS TIMES DIV UMINUS UPLUS
%token LPAREN RPAREN SEMICOLON
%token LCBRACE RCBRACE COLON COMMA DOT
%token CONCAT
%token CLASS EXTENDS OBJECT IS VAR DEF OVERRIDE AUTO NEW RETURN
%token ASSIGN
%token IF THEN ELSE
%token AND OR NOT
%token EOF

%left OR
%left AND
%left RELOP
%left PLUS MINUS
%left TIMES DIV
%right NOT UMINUS UPLUS

(* l'axiome est aussi le nom de la fonction a appeler pour faire l'analyse 
 * syntaxique
 *)
%start<Ast.progType> prog
%%
prog: loption(classOrObject) bloc EOF { }

classOrObject: class 
             | object

class: CLASS ID LPARENS separated_list(COMMA, param) RPARENS option(extends) option(bloc) IS LCBRACE classIn RCBRACE

object: OBJECT

extends: EXTENDS ID LPARENS separated_list(COMMA, param) RPARENS

classIn: loption(champ) loption(method)

champ: VAR boption(AUTO) ID COLON ID SEMICOLON

method: DEF boption(OVERRIDE) ID LPARENS separated_list(COMMA, param) RPARENS COLON ID ASSIGN expr
      | DEF boption(OVERRIDE) ID LPARENS separated_list(COMMA, param) RPARENS option(COLON ID) IS bloc

param: ID COLON ID

bloc: LCBRACE loption(instr) RCBRACE
    | LCBRACE list(decl) IS list(instr) RCBRACE

decl: separated_nonempty_list(COMMA, ID) COLON ID SEMICOLON

instr: expr SEMICOLON
     | bloc
     | RETURN SEMICOLON
     | lvalue ASSIGN expr SEMICOLON
     | IF expr THEN instr ELSE instr

lvalue: ID
      | ID LPARENS separated_list(COMMA, expr) RPARENS
      | lvalue DOT lvalue

rvalue: lvalue
      | CSTE
      | STRING

expr: rvalue
    | expr PLUS expr
    | expr MINUS expr
    | expr TIMES expr
    | expr DIV expr
    | expr RELOP expr
    | expr AND expr
    | expr OR expr
    | NOT expr
    | MINUS expr %prec UMINUS
    | PLUS expr %prec UPLUS 
    | delimited(LPARENS, expr, RPARENS)
    | expr CONCAT expr
    [ NEW ID LPARENS separated_list(COMMA, expr) RPARENS
