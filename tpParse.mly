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

%type <expType> expr
%type <valueType> value
%type <valueType> valueFst
%type <valueType> valueNxt
%type <instrType> instr
%type <blocType> bloc
%type <blocType> blocWDecl
%type <declType> decl
%type <paramType> param
%type <methodType> method_
%type <fieldType> field
%type <classInType> classIn
%type <extendType> extends
%type <classType> classOrObject
%type <classType> class_
%type <classType> object_
%type <string> retType


%left OR
%left AND
%left RELOP
%left CONCAT
%left PLUS MINUS
%left TIMES DIV
%right NOT UMINUS UPLUS

%left DOT

(* l'axiome est aussi le nom de la fonction a appeler pour faire l'analyse
 * syntaxique
 *)
%start<Ast.progType> prog
%%
prog: classes = list(classOrObject) code = bloc EOF { (classes, code) }

classOrObject: c = class_ { c }
             | o = object_ { o }

class_: CLASS name = ID params = delimited(LPAREN, separated_list(COMMA, param), RPAREN) e = option(extends) cons = option(bloc) IS i = delimited(LCBRACE, classIn, RCBRACE) { (false, name, params, e, cons, i) }

object_: OBJECT name = ID cons = option(bloc) IS i = delimited(LCBRACE, classIn, RCBRACE) { (true, name, [], None, cons, i) }

extends: EXTENDS name = ID args = delimited(LPAREN, separated_list(COMMA, expr), RPAREN) { (name, args) }

classIn: f = list(field) m = list(method_) { (f, m) }

field: VAR a = boption(AUTO) name = ID COLON t = ID SEMICOLON { (a, name, t) }

retType: COLON t = ID { t }

method_: DEF o = boption(OVERRIDE) name = ID params = delimited(LPAREN, separated_list(COMMA, param), RPAREN) COLON ret = ID ASSIGN e = expr { Calc(o, name, params, ret, e) }
       | DEF o = boption(OVERRIDE) name = ID params = delimited(LPAREN, separated_list(COMMA, param), RPAREN) ret = option(retType) IS b = bloc { Body(o, name, params, ret, b) }

param: name = ID COLON t = ID { (name, t) }

blocWDecl: decls = list(decl) IS instrs = list(instr) { (decls, instrs) }

bloc: instrs = delimited(LCBRACE, list(instr), RCBRACE) { ([], instrs) }
    | b = delimited(LCBRACE, blocWDecl, RCBRACE) { b }

decl: names = separated_nonempty_list(COMMA, ID) COLON t = ID SEMICOLON { (names, t) }

instr: e = expr SEMICOLON { Expr(e) }
     | b = bloc           { Bloc(b) }
     | RETURN SEMICOLON   { Return  }
     | v = value ASSIGN e = expr SEMICOLON { Assign(v, e) }
     | IF i = expr THEN t = instr ELSE e = instr { Ite(i, t, e) }

valueFst: i = ID { Id(i) }
        | c = CSTE   { Cste(c) }
        | s = STRING { Str (s) }

valueNxt: i = ID { Id(i) }
        | f = ID args = delimited(LPAREN, separated_list(COMMA, expr), RPAREN) { Func(f, args) }

value: v = valueFst { v }
     (*| v1 = value DOT v2 = valueNxt { Access(v1, v2) }*)
     | e = expr DOT v = valueNxt { Access(e, v) }


expr: v = value                       { Val(v) }
    | e1 = expr PLUS  e2 = expr       { Plus (e1, e2) }
    | e1 = expr MINUS e2 = expr       { Minus(e1, e2) }
    | e1 = expr TIMES e2 = expr       { Times(e1, e2) }
    | e1 = expr  DIV  e2 = expr       { Div  (e1, e2) }
    | e1 = expr  AND  e2 = expr       { And  (e1, e2) }
    | e1 = expr  OR   e2 = expr       { Or   (e1, e2) }
    | e1 = expr op = RELOP e2 = expr  { Comp (e1, op, e2) }
    | NOT e = expr                    { Not  (e)      }
    | MINUS e = expr %prec UMINUS     { UMinus(e)     }
    | PLUS e = expr %prec UPLUS           { e }
    | e = delimited(LPAREN, expr, RPAREN) { e }
    | e1 = expr CONCAT e2 = expr      { Concat(e1, e2) }
    | NEW cl = ID args = delimited(LPAREN, separated_list(COMMA, expr), RPAREN) { Inst(cl, args) }
