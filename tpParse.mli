
(* The type of tokens. *)

type token = 
  | VAR
  | UPLUS
  | UMINUS
  | TIMES
  | THEN
  | STRING of (string)
  | SEMICOLON
  | RPAREN
  | RETURN
  | RELOP of (Ast.opComp)
  | RCBRACE
  | PLUS
  | OVERRIDE
  | OR
  | OBJECT
  | NOT
  | NEW
  | MINUS
  | LPAREN
  | LCBRACE
  | IS
  | IF
  | ID of (string)
  | EXTENDS
  | EOF
  | ELSE
  | DOT
  | DIV
  | DEF
  | CSTE of (int)
  | CONCAT
  | COMMA
  | COLON
  | CLASS
  | AUTO
  | ASSIGN
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val prog: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.progType)
