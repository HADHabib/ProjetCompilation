type opComp =
  Eq | Neq | Lt | Le | Gt | Ge

type offset = | O of int | L of int | G of int

type valueTypeMethod = {left: expType; name: string; args: expType list; mutable vTableId: int; mutable objectName: string; mutable pushLeft: bool; mutable supercall: int}
and valueTypeAccess = {left: expType; name: string; mutable off: offset}
and valueTypeId = {name: string; mutable off: offset}

and valueType =
  Id of valueTypeId
| Method of valueTypeMethod
| Access of valueTypeAccess
| Cste of int
| Str of string
and expType =
  Val of valueType
| Plus of expType*expType
| Times of expType*expType
| Minus of expType*expType
| Div of expType*expType
| UMinus of expType
| Comp of expType * opComp * expType
| Not of expType
| Concat of expType * expType
| Inst of string * (expType list)
| Cast of string * expType
| EmptyExpr

type declType = (string list) * string

type instrType =
  Expr of expType
| Bloc of blocType
| Return
| Assign of valueType * expType
| Ite of expType * instrType * instrType  (* if then else *)
and blocType = (declType list) * (instrType list)

type paramType = string * string   (*a : Integer*)

type methodType =
  Calc of bool * string * (paramType list) * string * expType
| Body of bool * string * (paramType list) * string option * blocType

type fieldType = bool * string * string  

type classInType = (fieldType list) * (methodType list)

type extendType = string * (expType list)

type classType = bool * string * (paramType list) * (extendType option) * (blocType option) * classInType (* boolean to differentiate classe and object*)

type progType = (classType list) * blocType

let rec printSeparated l pm s =
  match l with
  | [] -> ()
  | x :: [] -> pm x
  | x :: r -> pm x; Printf.printf "%s" s; printSeparated r pm s
let rec printList l pm =
  match l with
  | [] -> ()
  | x :: r -> pm x; printList r pm

let printASTprintAST ast =
  let rec printVal v =
    match v with
    | Id(var) -> Printf.printf "%s" var.name
    | Method(call) -> printExpr call.left; Printf.printf ".%s(" call.name; printSeparated call.args printExpr ", "; Printf.printf ")"
    | Access(acc) -> printExpr acc.left; Printf.printf ".%s" acc.name
    | Cste(i) -> Printf.printf "%d" i
    | Str(s) -> Printf.printf "%s" s
  and printExpr e =
    match e with
    | Val(v) -> printVal v
    | Plus(e1, e2) -> Printf.printf "("; printExpr e1; Printf.printf " + "; printExpr e2; Printf.printf ")"
    | Times(e1, e2) -> Printf.printf "("; printExpr e1; Printf.printf " * "; printExpr e2; Printf.printf ")"
    | Minus(e1, e2) -> Printf.printf "("; printExpr e1; Printf.printf " - "; printExpr e2; Printf.printf ")"
    | Div(e1, e2) -> Printf.printf "("; printExpr e1; Printf.printf " / "; printExpr e2; Printf.printf ")"
    | Concat(e1, e2) -> Printf.printf "("; printExpr e1; Printf.printf " & "; printExpr e2; Printf.printf ")"
    | UMinus(e) -> Printf.printf "-"; printExpr e
    | Not(e) -> Printf.printf "not "; printExpr e
    | Inst(n, a) -> Printf.printf "new %s(" n; printSeparated a printExpr ", "; Printf.printf ")"
    | Cast(t, e) -> Printf.printf "(%s " t; printExpr e; Printf.printf ")";
    | Comp(e1, c, e2) -> (match c with
    | Eq -> Printf.printf "("; printExpr e1; Printf.printf " = "; printExpr e2; Printf.printf ")"
    | Neq -> Printf.printf "("; printExpr e1; Printf.printf " <> "; printExpr e2; Printf.printf ")"
    | Lt -> Printf.printf "("; printExpr e1; Printf.printf " < "; printExpr e2; Printf.printf ")"
    | Le -> Printf.printf "("; printExpr e1; Printf.printf " <= "; printExpr e2; Printf.printf ")"
    | Gt -> Printf.printf "("; printExpr e1; Printf.printf " > "; printExpr e2; Printf.printf ")"
    | Ge -> Printf.printf "("; printExpr e1; Printf.printf " >= "; printExpr e2; Printf.printf ")")
    | _ -> ()
  in
  let printParams pl = printSeparated pl (fun p -> Printf.printf "%s: %s" (fst p) (snd p)) ", " in
  let printExtend e = Printf.printf "extends %s(" (fst e); printSeparated (snd e) printExpr ", "; Printf.printf ") " in
  let printDecl d = printSeparated (fst d) (fun s -> Printf.printf "%s" s) ", "; Printf.printf ": %s;\n" (snd d) in
  let rec printInstr i =
    match i with
    | Expr(e) -> printExpr e; Printf.printf ";\n"
    | Bloc(b) -> printBloc b
    | Return -> Printf.printf "return;\n"
    | Assign(lv, e) -> printVal lv; Printf.printf " := "; printExpr e; Printf.printf ";\n"
    | Ite(e, i1, i2) -> Printf.printf "if "; printExpr e; Printf.printf " then "; printInstr i1; Printf.printf " else "; printInstr i2
  and printBloc b =
    Printf.printf "{\n";
    (match (fst b) with
     | [] -> ()
     | l -> printList l printDecl; Printf.printf " is\n"
    );
    printList (snd b) printInstr;
    Printf.printf "}\n"
  in
  let printField f =
    match f with (auto, name, t) ->
      Printf.printf "var ";
      (if auto then Printf.printf "auto " else ());
      Printf.printf "%s: %s;\n" name t
  in
  let printMethod m =
    Printf.printf "def ";
    match m with
    | Calc(override, name, params, ret, e) ->
       (if override then Printf.printf "override " else ());
       Printf.printf "%s(" name; printParams params; Printf.printf ") : %s := " ret;
       printExpr e;
       Printf.printf "\n"
    | Body(override, name, params, ret, b) ->
       (if override then Printf.printf "override " else ());
       Printf.printf "%s(" name; printParams params; Printf.printf ") ";
       (match ret with None -> Printf.printf "is " | Some s -> Printf.printf ": %s is " s);
       printBloc b;
       Printf.printf "\n"
  in
  let printClass c =
    match c with (static, name, params, extend, constructor, inner) ->
      (if static then Printf.printf "object %s " name else (Printf.printf "class %s(" name; printParams params; Printf.printf ") "));
    (match extend with None -> () | Some e -> printExtend e);
    (match constructor with None -> () | Some b -> printBloc b);
    Printf.printf "is {\n";
    printList (fst inner) printField;
    printList (snd inner) printMethod;
    Printf.printf "}\n"
  in
  printSeparated (fst ast) printClass "\n";
  Printf.printf "\n\n";
  printBloc (snd ast)

exception VC_Error of string
exception RUN_Error of string
exception MISC_Error of string
