
module MenhirBasics = struct
  
  exception Error
  
  let _eRR =
    fun _s ->
      raise Error
  
  type token = 
    | VAR
    | UPLUS
    | UMINUS
    | TIMES
    | THEN
    | STRING of (
# 6 "tpParse.mly"
       (string)
# 20 "tpParse.ml"
  )
    | SEMICOLON
    | RPAREN
    | RETURN
    | RELOP of (
# 7 "tpParse.mly"
       (Ast.opComp)
# 28 "tpParse.ml"
  )
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
    | ID of (
# 4 "tpParse.mly"
       (string)
# 45 "tpParse.ml"
  )
    | EXTENDS
    | EOF
    | ELSE
    | DOT
    | DIV
    | DEF
    | CSTE of (
# 5 "tpParse.mly"
       (int)
# 56 "tpParse.ml"
  )
    | CONCAT
    | COMMA
    | COLON
    | CLASS
    | AUTO
    | ASSIGN
    | AND
  
end

include MenhirBasics

# 1 "tpParse.mly"
  
open Ast

# 74 "tpParse.ml"

type ('s, 'r) _menhir_state

and _menhir_box_prog = 
  | MenhirBox_prog of (Ast.progType) [@@unboxed]

let _menhir_action_1 =
  fun () ->
    (
# 30 "tpParse.mly"
           ( )
# 86 "tpParse.ml"
     : (Ast.progType))

let _menhir_print_token : token -> string =
  fun _tok ->
    match _tok with
    | AND ->
        "AND"
    | ASSIGN ->
        "ASSIGN"
    | AUTO ->
        "AUTO"
    | CLASS ->
        "CLASS"
    | COLON ->
        "COLON"
    | COMMA ->
        "COMMA"
    | CONCAT ->
        "CONCAT"
    | CSTE _ ->
        "CSTE"
    | DEF ->
        "DEF"
    | DIV ->
        "DIV"
    | DOT ->
        "DOT"
    | ELSE ->
        "ELSE"
    | EOF ->
        "EOF"
    | EXTENDS ->
        "EXTENDS"
    | ID _ ->
        "ID"
    | IF ->
        "IF"
    | IS ->
        "IS"
    | LCBRACE ->
        "LCBRACE"
    | LPAREN ->
        "LPAREN"
    | MINUS ->
        "MINUS"
    | NEW ->
        "NEW"
    | NOT ->
        "NOT"
    | OBJECT ->
        "OBJECT"
    | OR ->
        "OR"
    | OVERRIDE ->
        "OVERRIDE"
    | PLUS ->
        "PLUS"
    | RCBRACE ->
        "RCBRACE"
    | RELOP _ ->
        "RELOP"
    | RETURN ->
        "RETURN"
    | RPAREN ->
        "RPAREN"
    | SEMICOLON ->
        "SEMICOLON"
    | STRING _ ->
        "STRING"
    | THEN ->
        "THEN"
    | TIMES ->
        "TIMES"
    | UMINUS ->
        "UMINUS"
    | UPLUS ->
        "UPLUS"
    | VAR ->
        "VAR"

let _menhir_fail : unit -> 'a =
  fun () ->
    Printf.eprintf "Internal failure -- please contact the parser generator's developers.\n%!";
    assert false

include struct
  
  [@@@ocaml.warning "-4-37-39"]
  
  let rec _menhir_run_0 : type  ttv_stack. ttv_stack -> _ -> _ -> _menhir_box_prog =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | EOF ->
          let _v = _menhir_action_1 () in
          MenhirBox_prog _v
      | _ ->
          _eRR ()
  
end

let prog =
  fun _menhir_lexer _menhir_lexbuf ->
    let _menhir_stack = () in
    let MenhirBox_prog v = _menhir_run_0 _menhir_stack _menhir_lexbuf _menhir_lexer in
    v
