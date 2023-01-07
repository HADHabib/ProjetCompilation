%{
open Ast
%}
%token <string> ID
%token <string> TYPENAME
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
%token NOT
%token EOF

%type <expType> expr
%type <valueType> value
%type <valueType> valueFst
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
%type <expType> cast

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

class_: CLASS name = TYPENAME params = delimited(LPAREN, separated_list(COMMA, param), RPAREN) e = option(extends) cons = option(bloc) IS i = delimited(LCBRACE, classIn, RCBRACE) { (false, name, params, e, cons, i) }

object_: OBJECT name = TYPENAME cons = option(bloc) IS i = delimited(LCBRACE, classIn, RCBRACE) { (true, name, [], None, cons, i) }

extends: EXTENDS name = TYPENAME args = delimited(LPAREN, separated_list(COMMA, expr), RPAREN) { (name, args) }

classIn: f = list(field) m = list(method_) { (f, m) }

field: VAR a = boption(AUTO) name = ID COLON t = TYPENAME SEMICOLON { (a, name, t) }

retType: COLON t = TYPENAME { t }

method_: DEF o = boption(OVERRIDE) name = ID params = delimited(LPAREN, separated_list(COMMA, param), RPAREN) COLON ret = TYPENAME ASSIGN e = expr { Calc(o, name, params, ret, e) }
       | DEF o = boption(OVERRIDE) name = ID params = delimited(LPAREN, separated_list(COMMA, param), RPAREN) ret = option(retType) IS b = bloc { Body(o, name, params, ret, b) }

param: name = ID COLON t = TYPENAME { (name, t) }

blocWDecl: decls = list(decl) IS instrs = list(instr) { (decls, instrs) }

bloc: instrs = delimited(LCBRACE, list(instr), RCBRACE) { ([], instrs) }
    | b = delimited(LCBRACE, blocWDecl, RCBRACE) { b }

decl: names = separated_nonempty_list(COMMA, ID) COLON t = TYPENAME SEMICOLON { (names, t) }

instr: e = expr SEMICOLON { Expr(e) }
     | b = bloc           { Bloc(b) }
     | RETURN SEMICOLON   { Return  }
     | v = value ASSIGN e = expr SEMICOLON { Assign(v, e) }
     | IF i = expr THEN t = instr ELSE e = instr { Ite(i, t, e) }

valueFst: i = ID { Id({name = i; off = O(0)}) }
        | c = CSTE   { Cste(c) }
        | s = STRING { Str (s) }

value: v = valueFst { v }
     | e = expr DOT i = ID { Access({left = e; name = i; off = O(0)}) }
     | e = expr DOT f = ID args = delimited(LPAREN, separated_list(COMMA, expr), RPAREN)     { Method({left = e;         name = f; args = args; vTableId =  0; objectName = ""; pushLeft = true ; supercall = false}) }
     | o = TYPENAME DOT f = ID args = delimited(LPAREN, separated_list(COMMA, expr), RPAREN) { Method({left = EmptyExpr; name = f; args = args; vTableId = -1; objectName =  o; pushLeft = false; supercall = false}) }

expr: v = value                       { Val(v) }
    | e1 = expr PLUS  e2 = expr       { Plus (e1, e2) }
    | e1 = expr MINUS e2 = expr       { Minus(e1, e2) }
    | e1 = expr TIMES e2 = expr       { Times(e1, e2) }
    | e1 = expr  DIV  e2 = expr       { Div  (e1, e2) }
    | e1 = expr op = RELOP e2 = expr  { Comp (e1, op, e2) }
    | NOT e = expr                    { Not  (e)      }
    | MINUS e = expr %prec UMINUS     { UMinus(e)     }
    | PLUS e = expr %prec UPLUS           { e }
    | e = delimited(LPAREN, expr, RPAREN) { e }
    | e1 = expr CONCAT e2 = expr      { Concat(e1, e2) }
    | NEW cl = TYPENAME args = delimited(LPAREN, separated_list(COMMA, expr), RPAREN) { Inst(cl, args) }
    | c = delimited(LPAREN, cast, RPAREN) { c }

cast: t = TYPENAME e = expr { Cast(t, e) }
