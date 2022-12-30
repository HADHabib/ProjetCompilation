open Ast 

type classVerifType = {name : string; mutable champs : variable list; mutable methode : classmethod list; mutable constructeur : classmethod option; mutable parent : classVerifType option}
and variable = {name : string; typeVar : classVerifType; mutable offset : Ast.offset}
and classmethod = {name : string; returnType : classVerifType option; parametre : variable list; mutable offset : int }
type objectVerifType = {name : string; mutable champs : variable list; mutable methode : classmethod list; mutable constructeur : classmethod option}

(* builtin classes and methods *)
let classInteger : classVerifType = {name = "Integer"; champs = []; methode = []; constructeur = None; parent = None}
let classString : classVerifType = {name = "String"; champs = []; methode = []; constructeur = None; parent = None}
let integer_toString : classmethod = {name = "toString" ; returnType = Some classString ; parametre = []; offset = -1}
let string_print : classmethod = {name = "print"; returnType = None; parametre = []; offset = -1}
let string_println : classmethod = {name = "println"; returnType = None; parametre = []; offset = -1}

(* helper class and object *)
let classOBJECTCALL : classVerifType = {name = "_object_"; champs = []; methode = []; constructeur = None; parent = None} (* Should be used for objects *)
let objEmpty : objectVerifType = {name = "_empty_"; champs = []; methode = []; constructeur = None;} (* Should never be used *)

(* helper functions *)
let findClass  (name : string) (classes   : classVerifType list) : classVerifType option = List.find_opt (fun (a : classVerifType) -> name = a.name) classes
let findVar    (name : string) (variables : variable       list) : variable       option = List.find_opt (fun (a : variable      ) -> name = a.name) variables
let findMethod (name : string) (methodes  : classmethod    list) : classmethod    option = List.find_opt (fun (a : classmethod   ) -> name = a.name) methodes

let identIsObject (name : string) (objects : objectVerifType list) : bool = match List.find_opt (fun (a : objectVerifType) -> name = a.name) objects with None -> false | Some o -> true
let getObjectFromExpr (v : Ast.expType) (objects : objectVerifType list) : objectVerifType = match v with | Val(Id(ob)) -> List.find (fun  (a : objectVerifType) -> ob.name = a.name) objects | _ -> objEmpty
let optTypeAsNonOpt (cl : classVerifType option) (err : string) : classVerifType = (match cl with | None -> raise (VC_Error err) | Some t -> t)

(* verif functions *)

let rec verifValue (v : Ast.valueType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) : classVerifType option =
    match v with
    | Id(var) ->
        if identIsObject var.name objects then Some classOBJECTCALL else begin (* if this references an object : return classOBJECTCALL *)
            let var_ : variable option = findVar var.name variables in (* get variable *)
            match var_ with | None -> (let str : string = Printf.sprintf "Undefined variable : %s" var.name in raise (VC_Error str)) (* check if variable exists *)
            | Some v -> var.off <- v.offset; Some v.typeVar (* annotate AST and return type of variable *)
        end
    | Method(call) ->
        let typ_ : classVerifType option = verifExpr call.left classes objects variables in (* get type of left expression *)
        let typ : classVerifType = optTypeAsNonOpt typ_ "Can't call method on void" in
        if typ = classOBJECTCALL then begin
            let obj : objectVerifType = getObjectFromExpr call.left objects in
            let methode_ : classmethod option = findMethod call.name obj.methode in (* check method exist in obj *)
            let methode : classmethod = (match methode_ with | None -> (let str = Printf.sprintf "Undefined method : %s::%s" obj.name call.name in raise (VC_Error str)) | Some m -> m) in
            (if (List.length methode.parametre) <> (List.length call.args) then raise (VC_Error "Wrong arguments") else ()); (* verif parameters *)
            List.iter2 (fun (carg : Ast.expType) (marg : variable) -> if (optTypeAsNonOpt (verifExpr carg classes objects variables) "Argument can't be void") <> marg.typeVar then raise (VC_Error "Wrong type argument")) call.args methode.parametre;
            call.vTableId <- -1; (* annotate AST *)
            call.objectName <- obj.name;
            call.pushLeft <- false;
            methode.returnType (* return type of return value *)
        end else begin
            let methode_ : classmethod option = findMethod call.name typ.methode in (* check method exist in typ *)
            let methode : classmethod = (match methode_ with | None -> (let str = Printf.sprintf "Undefined method : %s::%s" typ.name call.name in raise (VC_Error str)) | Some m -> m) in
            (if (List.length methode.parametre) <> (List.length call.args) then raise (VC_Error "Wrong arguments") else ()); (* verif parameters *)
            List.iter2 (fun (carg : Ast.expType) (marg : variable) -> if (optTypeAsNonOpt (verifExpr carg classes objects variables) "Argument can't be void") <> marg.typeVar then raise (VC_Error "Wrong type argument")) call.args methode.parametre;
            call.vTableId <- methode.offset; (* annotate AST *)
            (* special cases : *)
            (if methode = integer_toString then (call.objectName <- "Integer"; call.pushLeft <- true) else ());
            (if methode = string_print then (call.objectName <- "String"; call.pushLeft <- true) else ());
            (if methode = string_println then (call.objectName <- "String"; call.pushLeft <- true) else ());
            methode.returnType (* return type of return value *)
        end
    | Access(acc) ->
        let var_ : variable option = findVar "this" variables in (* you can only access this *)
        let var : variable = (match var_ with | None -> raise (VC_Error "Couldn't find 'this'") | Some v -> v) in
        let this : Ast.valueTypeId = match acc.left with Val(Id(v)) -> if v.name <> "this" then raise (VC_Error "Variable can't be accessed") else v | _ -> raise (VC_Error "Only access a variable") in
        this.off <- var.offset; (* annotate AST left *)
        (* check if this is object - *)
        if var.typeVar = classOBJECTCALL then begin
            let obj : objectVerifType = getObjectFromExpr acc.left objects in
            let field_ : variable option = findVar acc.name obj.champs in
            let field : variable = (match field_ with | None -> raise (VC_Error "Couldn't find field") | Some v -> v) in
            acc.off <- field.offset;
            Some field.typeVar
        end else begin
            let field_ : variable option = findVar acc.name var.typeVar.champs in
            let field : variable = (match field_ with | None -> raise (VC_Error "Couldn't find field") | Some v -> v) in
            acc.off <- field.offset;
            Some field.typeVar
        end
    | Cste(i) -> Some classInteger
    | Str(s) -> Some classString

and verifExpr (e : Ast.expType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) : classVerifType option =
    match e with
    | Val(v) -> verifValue v classes objects variables
    | Plus(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                      let t2 : classVerifType option = verifExpr e2 classes objects variables in
                      (if t1 <> Some classInteger || t2 <> Some classInteger then raise (VC_Error "Addition is between integer")); Some classInteger
    | Times(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                       let t2 : classVerifType option = verifExpr e2 classes objects variables in
                       (if t1 <> Some classInteger || t2 <> Some classInteger then raise (VC_Error "Multiplication is between integer")); Some classInteger
    | Minus(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                       let t2 : classVerifType option = verifExpr e2 classes objects variables in
                       (if t1 <> Some classInteger || t2 <> Some classInteger then raise (VC_Error "Subtractiontion is between integer")); Some classInteger
    | Div(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                     let t2 : classVerifType option = verifExpr e2 classes objects variables in
                     (if t1 <> Some classInteger || t2 <> Some classInteger then raise (VC_Error "Division is between integer")); Some classInteger
    | And(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                     let t2 : classVerifType option = verifExpr e2 classes objects variables in
                     (if t1 <> Some classInteger || t2 <> Some classInteger then raise (VC_Error "And is between integer")); Some classInteger
    | Or(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                    let t2 : classVerifType option = verifExpr e2 classes objects variables in
                    (if t1 <> Some classInteger || t2 <> Some classInteger then raise (VC_Error "Or is between integer")); Some classInteger
    | Comp(e1, _, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                         let t2 : classVerifType option = verifExpr e2 classes objects variables in
                         (if t1 <> Some classInteger || t2 <> Some classInteger then raise (VC_Error "Comparison is between integer")); Some classInteger
    | Concat(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                        let t2 : classVerifType option = verifExpr e2 classes objects variables in
                        (if t1 <> Some classString || t2 <> Some classString then raise (VC_Error "Concatenation is between strings")); Some classString
    | UMinus(e) -> let t : classVerifType option = verifExpr e classes objects variables in
                   (if t <> Some classInteger then raise (VC_Error "Negation is for integer")); Some classInteger
    | Not(e) -> let t : classVerifType option = verifExpr e classes objects variables in
                (if t <> Some classInteger then raise (VC_Error "Not is for integer")); Some classInteger
    | Inst(n, a) ->
        let classe_ : classVerifType option = findClass n classes in (* Check class n exists *)
        let classe : classVerifType = (match classe_ with | None -> raise (VC_Error "Couldn't find class") | Some c -> c) in
        let cons_args : variable list = (match classe.constructeur with | None -> [] | Some c -> c.parametre) in
        (if (List.length cons_args) <> (List.length a) then raise (VC_Error "Wrong arguments") else ()); (* verif parameters *)
        List.iter2 (fun (carg : Ast.expType) (marg : variable) -> if (optTypeAsNonOpt (verifExpr carg classes objects variables) "Argument can't be void") <> marg.typeVar then raise (VC_Error "Wrong type argument")) a cons_args;
        Some classe (* Return the class n *)

let verifStore (lv : Ast.valueType) (e : Ast.expType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) : unit =
    let t : classVerifType option = verifExpr e classes objects variables in
    () (* match types of lv and e, check lv writable and annotate AST *)

let rec verifInstr (i : Ast.instrType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) : unit =
    match i with
    | Expr(e) -> ignore (verifExpr e classes objects variables)
    | Bloc(b) -> verifBloc b classes objects variables
    | Return -> () (* IDK, verif reachable statement ? *)
    | Assign(lv, e) -> verifStore lv e classes objects variables
    | Ite(e, i1, i2) -> if (verifExpr e classes objects variables <> Some classInteger) then raise (VC_Error "Expression in if statement should return an integer") else (verifInstr i1 classes objects variables; verifInstr i2 classes objects variables)
and verifBloc (b : Ast.blocType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) : unit =
    (match (fst b) with
     | [] -> ()
     | l ->
         () (* verif class existance and add variable to variables list *)
    );
    List.iter (fun (x : Ast.instrType) -> verifInstr x classes objects variables) (snd b)

let verifMethod (m : Ast.methodType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) : unit =
    match m with
    | Calc(override, name, params, retType, expr) -> ()
       (* if override, check if parent type has the same method *)
       (* create a list of variables that contains the params with the correct offset *)
       (* check expr and compare return type *)
    | Body(override, name, params, retType, bloc) -> ()
       (* if override, check if parent type has the same method *)
       (* create a list of variables that contains the params and the result variable if retType is not None with the correct offset *)
       (* check bloc *)

let verifObject (ob : Ast.classType) (classes : classVerifType list) (objects : objectVerifType list) : classVerifType list * objectVerifType list =
    let newobj : objectVerifType = {name = "name"; champs = []; methode = []; constructeur = None} in
    (* same as class *)
    (classes, newobj::objects)

let verifClass (cl : Ast.classType) (classes : classVerifType list) (objects : objectVerifType list) : classVerifType list * objectVerifType list =
    match cl with (obj, name, args, ext, bl, inner) ->
    if obj then verifObject cl classes objects else begin
        let newclass : classVerifType = {name = name; champs = []; methode = []; constructeur = None; parent = None} in
        (* create getter for 'auto' fields *)
        (* put methods, fields (check type exist), constructor and parent in newclass *)
        (* check for duplicate field or method *)
        (* check all methods *)
        (newclass::classes, objects)
    end

(* verify all classes and add them to a list, then verify the main bloc *)
let verifProg (prog : Ast.progType) : unit =
    classInteger.methode <- [integer_toString];
    classString.methode <- [string_print; string_println];
    let classes = [classInteger; classString] in
    let objects = [] in
    let allClassesObjects = List.fold_left (fun lists cl -> verifClass cl (fst lists) (snd lists)) (classes, objects) (fst prog) in
    verifBloc (snd prog) (fst allClassesObjects) (snd allClassesObjects) []
