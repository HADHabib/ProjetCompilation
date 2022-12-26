open Ast 




(* O LOAD / STORE  *)(* L PUSHL / STOREL  *)(* G PUSHG / STOREG  *)

type classtype = {name: string ;mutable champs : variable list ; mutable methode :classmethod list ;constructeur : classmethod option ; parent : classtype option}
and variable = {name :string ; typeVar : classtype ; mutable offset : Ast.offset}
and classmethod = {name : string ; returnType : classtype option; parametre : variable list ; mutable offset  :int };;




classtype integer = {name : "Integer" ; champs : [] ; methode : [] ; constructeur : None ; parent : None}
classtype classString = {name : "String" ; champs : [] ; methode : [] ; constructeur : None ; parent : None}
classmethod int_string = {name : "toString" ; returnType : classString ; parametre : [] ; offset : 0}
classmethod print = {name : "print" ; returnType : None ; parametre : [] ; offset : 0}
classmethod println = {name : "println" ; returnType : None ; parametre : [] ; offset : 0}

integer.classmethod <- [int_string]
classString.classmethod <- [print;println]













