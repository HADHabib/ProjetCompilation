open Ast 

type classtype = {name: string; mutable champs : variable list; mutable methode : classmethod list; mutable constructeur : classmethod option; mutable parent : classtype option}
and variable = {name :string; typeVar : classtype; mutable offset : Ast.offset}
and classmethod = {name : string; returnType : classtype option; parametre : variable list; mutable offset : int }

type objectType = {name: string; mutable champs : variable list; mutable methode : classmethod list; mutable constructeur : classmethod option}

let classInteger = {name = "Integer"; champs = []; methode = []; constructeur = None; parent = None}
let classString = {name = "String"; champs = []; methode = []; constructeur = None; parent = None}
let integer_toString = {name = "toString" ; returnType = Some classString ; parametre = []; offset = 0}
let string_print = {name = "print"; returnType = None; parametre = []; offset = 0}
let string_println = {name = "println"; returnType = None; parametre = []; offset = 1}

let rec verifValue v classes objects variables =
    match v with
    | Id(var) -> None (* check if variable exists (don't forget 'this'), annotate AST, return type of variable *)
    | Method(call) -> let typ = verifExpr call.left classes objects variables in None (* check method exist in typ, annotate AST, verif parameters, return type of return value *) (* do something for objects *)
    | Access(acc) -> let typ = verifExpr acc.left classes objects variables in None (* check field exist and is accessible in typ, annotate AST, return type of field *)
    | Cste(i) -> Some classInteger
    | Str(s) -> Some classString
and verifExpr e classes objects variables =
    match e with
    | Val(v) -> verifValue v classes objects variables
    | Plus(e1, e2) -> let t1 = verifExpr e1 classes objects variables in let t2 = verifExpr e2 classes objects variables in Some classInteger (* verif if both types are integer *)
    | Times(e1, e2) -> let t1 = verifExpr e1 classes objects variables in let t2 = verifExpr e2 classes objects variables in Some classInteger (* verif if both types are integer *)
    | Minus(e1, e2) -> let t1 = verifExpr e1 classes objects variables in let t2 = verifExpr e2 classes objects variables in Some classInteger (* verif if both types are integer *)
    | Div(e1, e2) -> let t1 = verifExpr e1 classes objects variables in let t2 = verifExpr e2 classes objects variables in Some classInteger (* verif if both types are integer *)
    | And(e1, e2) -> let t1 = verifExpr e1 classes objects variables in let t2 = verifExpr e2 classes objects variables in Some classInteger (* verif if both types are integer *)
    | Or(e1, e2) -> let t1 = verifExpr e1 classes objects variables in let t2 = verifExpr e2 classes objects variables in Some classInteger (* verif if both types are integer *)
    | Concat(e1, e2) -> let t1 = verifExpr e1 classes objects variables in let t2 = verifExpr e2 classes objects variables in Some classString (* verif if both types are string *)
    | UMinus(e) -> let t = verifExpr e classes objects variables in Some classInteger (* verif if t is integer *)
    | Not(e) -> let t = verifExpr e classes objects variables in Some classInteger (* verif if t is integer *)
    | Inst(n, a) -> (* verif args, return class of name n*) None
    | Comp(e1, c, e2) -> match c with
    | Eq -> let t1 = verifExpr e1 classes objects variables in let t2 = verifExpr e2 classes objects variables in Some classInteger (* verif if both types are integer *)
    | Neq -> let t1 = verifExpr e1 classes objects variables in let t2 = verifExpr e2 classes objects variables in Some classInteger (* verif if both types are integer *)
    | Lt -> let t1 = verifExpr e1 classes objects variables in let t2 = verifExpr e2 classes objects variables in Some classInteger (* verif if both types are integer *)
    | Le -> let t1 = verifExpr e1 classes objects variables in let t2 = verifExpr e2 classes objects variables in Some classInteger (* verif if both types are integer *)
    | Gt -> let t1 = verifExpr e1 classes objects variables in let t2 = verifExpr e2 classes objects variables in Some classInteger (* verif if both types are integer *)
    | Ge -> let t1 = verifExpr e1 classes objects variables in let t2 = verifExpr e2 classes objects variables in Some classInteger (* verif if both types are integer *)

let rec verifInstr i classes objects variables =
    match i with
    | Expr(e) -> ignore (verifExpr e classes objects variables)
    | Bloc(b) -> verifBloc b classes objects variables
    | Return -> () (* IDK, verif reachable statement ? *)
    | Assign(lv, e) -> () (* match types of lv and e, check lv writable and annotate AST *)
    | Ite(e, i1, i2) -> if (verifExpr e classes objects variables <> Some classInteger) then () else (* should be integer *) verifInstr i1 classes objects variables; verifInstr i2 classes objects variables
and verifBloc b classes objects variables =
    (match (fst b) with
     | [] -> ()
     | l -> () (* verif class existance and add variable to variables list *)
    ); ()
    (* loop on all instrs and call verifInstr *)

let verifMethod m classes objects =
    match m with
    | Calc(override, name, params, retType, expr) -> ()
       (* if override, check if parent type has the same method *)
       (* create a list of variables that contains the params with the correct offset *)
       (* check expr and compare return type *)
    | Body(override, name, params, retType, bloc) -> ()
       (* if override, check if parent type has the same method *)
       (* create a list of variables that contains the params and the result variable if retType is not None with the correct offset *)
       (* check bloc *)

let verifObject ob classes objects =
    let newobj = {name = "name"; champs = []; methode = []; constructeur = None} in
    (* same as class *)
    (classes, newobj::objects)

let verifClass cl classes objects =
    match cl with (obj, name, args, ext, bl, inner) ->
    if obj then verifObject cl classes objects else begin
        (* use correct name *)
        let newclass = {name = name; champs = []; methode = []; constructeur = None; parent = None} in
        (* put methods, fields (check type exist), constructor and parent in newclass *)
        (* check for duplicate field or method *)
        (* create getter for 'auto' fields *)
        (* check all methods *)
        (newclass::classes, objects)
    end

(* verify all classes and add them to a list, then verify the main bloc *)
let verifProg prog =
    classInteger.methode <- [integer_toString];
    classString.methode <- [string_print; string_println];
    let classes = [classInteger; classString] in
    let objects = [] in
    let allClassesObjects = List.fold_left (fun lists cl -> verifClass cl (fst lists) (snd lists)) (classes, objects) (fst prog) in
    verifBloc (snd prog) (fst allClassesObjects) (snd allClassesObjects) []
