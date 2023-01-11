{
open Ast
open Parser
open Lexing
exception Eof

(* gere les positions numero de ligne + decalage dans la ligne *)
let next_line lexbuf = Lexing.new_line lexbuf

(* Potentiellement utile pour distinguer mots-clef et vrais identificateurs *)
let keyword_table = Hashtbl.create 16

let _ =
    List.iter (fun (kwd, tok) -> Hashtbl.add keyword_table kwd tok) [
        "class", CLASS;
        "object", OBJECT;
        "extends", EXTENDS;
        "is", IS;
        "var", VAR;
        "def", DEF;
        "auto", AUTO;
        "override", OVERRIDE;
        "new", NEW;
        "return", RETURN;
        "if", IF;
        "then", THEN;
        "else", ELSE;
        "not", NOT;
      ]

}

(* abréviation utiles pour les expressions rationnelles *)
let minuscule = ['a'-'z']
let majuscule = ['A'-'Z']
let lettre = (minuscule | majuscule)
let chiffre = ['0'-'9']
let chiffreHex = (chiffre | ['A'-'F' 'a'-'f'])
let LC = ( lettre | chiffre ) (* lettre ou chiffre *)
let escapesequence = ('\\' ['\\' '"' 'n' 't' 'b' 'r' ' '] 
                   | '\\' chiffre chiffre chiffre
                   | "\\x" chiffreHex chiffreHex
                   | "\\o" ['0'-'3'] ['0'-'7'] ['0'-'7']) 
let stringchar = (escapesequence | [^ '\\' '"'])

(* l'analyseur lexical est decomposé ici en deux fonctions: l'une qui est
 * specialisée dans la reconnaissance des commentaires à la C, l'autre qui
 * traite les autres tokens à reconnaire. les deux fonctions vont coopérer.
 * Tout caractere lu dans le fichier doit être reconnu quelque part !
 *)
rule
  token = parse (* a completer *)
    minuscule LC * as id     { try Hashtbl.find keyword_table id with Not_found -> ID id }
  | majuscule LC * as id { TYPENAME id }
  | [' ''\t''\r']        { token lexbuf }     (* skip blanks *)
  | '\n'                 { next_line lexbuf; token lexbuf}
  | "/*"                 {
                            (* lance la fonction specialisée dans la
                             * reconnaissance des commentaires
                             *)
                            multiline_comment lexbuf
                         }
  | "//"                 { comment lexbuf }
(* completer avec les autres regles et actions pour renvoyer le prochain token
 * significatif
 *)
  | chiffre+ as lxm      { CSTE(int_of_string lxm) }
  | '"' stringchar* '"' as str        { STRING(str) }
  | '+'                  { PLUS }
  | '-'                  { MINUS }
  | '*'                  { TIMES }
  | '/'                  { DIV }
  | '<'                  { RELOP (Ast.Lt) }
  | "<="                 { RELOP (Ast.Le) }
  | '>'                  { RELOP (Ast.Gt) }
  | ">="                 { RELOP (Ast.Ge) }
  | '='                  { RELOP (Ast.Eq) }
  | "<>"                 { RELOP (Ast.Neq) }
  | '&'                  { CONCAT }
  | ':'                  { COLON }
  | ','                  { COMMA }
  | '.'                  { DOT }
  | '{'                  { LCBRACE }
  | '}'                  { RCBRACE }
  | ":="                 { ASSIGN }
  | '('                  { LPAREN }
  | ')'                  { RPAREN }
  | ';'                  { SEMICOLON }
  | "!"                  { NOT }
  | eof                  { EOF }
  | _ as lxm             { (* On met un message et on essaye de scanner la
                            * suite. pour détecter le plus d'erreurs possibles
                            * d'un coup. Il faudrait probablement mémoriser
                            * qu'on a rencontré une erreur pour signaler à la
                            * fin que le programme était incorrect.
                            *)
             		   print_endline
                             ("undefined character: " ^ (String.make 1 lxm));
                           token lexbuf
           	         }
and
  multiline_comment = parse
  (* completer avec les autres regles qui definissent ce qu'est un commentaire
   * correct
   *)
    "*/"          { (* quand on a reconnu la fin du commentaire, on relance
                     * recursivement l'analyseur lexical pour renvoyer le
                     * prochain token à l'analyseur syntaxique puisqu'on ne
                     * transmet pas les commentaires
                     *)
                     token lexbuf
                  }
  | '\n'          { new_line lexbuf; multiline_comment lexbuf }
  | _             { multiline_comment lexbuf }
and
  comment = parse
    '\n' { new_line lexbuf; token lexbuf }
  | _    { comment lexbuf }
