open Ast 

type classVerifType = {name : string; mutable champs : variable list; mutable methode : classmethod list; mutable constructeur : classmethod option; mutable parent : classVerifType option}
and variable = {name : string; typeVar : classVerifType; mutable offset : Ast.offset}
and classmethod = {name : string; returnType : classVerifType option; mutable parametre : variable list; mutable offset : int }
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

let globalBlocOff : int ref = ref (-1)
let globalFieldOff : int ref = ref 1
let globalMethodOff : int ref = ref 0
let globalCurrentClass : classVerifType ref = ref classOBJECTCALL
let globalCurrentObj : objectVerifType ref = ref objEmpty
let globalClassId : int ref = ref 0

let printList l = List.iter (fun x -> Printf.printf "%s ," x.name) l

(* helper functions *)
let findClass  (name : string) (classes   : classVerifType list) : classVerifType option = List.find_opt (fun (a : classVerifType) -> name = a.name) classes
let findVar    (name : string) (variables : variable       list) : variable       option = List.find_opt (fun (a : variable      ) -> name = a.name) variables
let findMethod (name : string) (methodes  : classmethod    list) : classmethod    option = List.find_opt (fun (a : classmethod   ) -> name = a.name) methodes

let getClass (name : string) (classes : classVerifType list) : classVerifType = (match findClass name classes with | None -> raise (VC_Error (Printf.sprintf "%d class not found : %s" !globalClassId name)) | Some t -> t)
let getMethod (name : string) (methode : classmethod list) : classmethod = (match findMethod name methode with | None -> raise (VC_Error "method not found") | Some t -> t)
let identIsObject (name : string) (objects : objectVerifType list) : bool =
    match List.find_opt (fun (a : objectVerifType) -> name = a.name) objects with None -> false | Some o -> true

let getObjectFromExpr (v : Ast.expType) (objects : objectVerifType list) : objectVerifType =
    match v with
     | Val(Id(ob)) -> (
        if ob.name = "this" then !globalCurrentObj else
        match List.find_opt(fun  (a : objectVerifType) -> ob.name = a.name) objects with
        | None -> raise (VC_Error (Printf.sprintf "%s is not an object" ob.name))
        | Some o -> o
    )| _ -> objEmpty
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
        if typ.name = "_object_" then begin
            let obj : objectVerifType = getObjectFromExpr call.left objects in
            let methode_ : classmethod option = findMethod call.name obj.methode in (* check method exist in obj *)
            let methode : classmethod = (match methode_ with | None -> (let str = Printf.sprintf "Undefined method : %s::%s" obj.name call.name in raise (VC_Error str)) | Some m -> m) in
            (if (List.length methode.parametre) <> (List.length call.args) then raise (VC_Error "Wrong arguments") else ()); (* verif parameters *)
            List.iter2 (fun (carg : Ast.expType) (marg : variable) -> if (optTypeAsNonOpt (verifExpr carg classes objects variables) "Argument can't be void").name <> marg.typeVar.name then raise (VC_Error "Wrong type argument")) call.args methode.parametre;
            call.vTableId <- -1; (* annotate AST *)
            call.objectName <- obj.name;
            call.pushLeft <- false;
            methode.returnType (* return type of return value *)
        end else begin
            let methode_ : classmethod option = findMethod call.name typ.methode in (* check method exist in typ *)
            let methode : classmethod = (match methode_ with | None -> (let str = Printf.sprintf "Undefined method : %s::%s" typ.name call.name in raise (VC_Error str)) | Some m -> m) in
            (if (List.length methode.parametre) <> (List.length call.args) then raise (VC_Error "Wrong arguments") else ()); (* verif parameters *)
            List.iter2 (fun (carg : Ast.expType) (marg : variable) -> if (optTypeAsNonOpt (verifExpr carg classes objects variables) "Argument can't be void").name <> marg.typeVar.name then raise (VC_Error "Wrong type argument")) call.args methode.parametre;
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
        if var.typeVar.name = "_object_" then begin
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
and optClassName (cl : classVerifType option) : string = match cl with None -> "_none_" | Some c -> c.name
and verifExpr (e : Ast.expType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) : classVerifType option =
    match e with
    | Val(v) -> verifValue v classes objects variables
    | Plus(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                      let t2 : classVerifType option = verifExpr e2 classes objects variables in
                      (if optClassName t1 <> "Integer" || optClassName t2 <> "Integer" then raise (VC_Error "Addition is between integer")); Some classInteger
    | Times(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                       let t2 : classVerifType option = verifExpr e2 classes objects variables in
                       (if optClassName t1 <> "Integer" || optClassName t2 <> "Integer" then raise (VC_Error "Multiplication is between integer")); Some classInteger
    | Minus(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                       let t2 : classVerifType option = verifExpr e2 classes objects variables in
                       (if optClassName t1 <> "Integer" || optClassName t2 <> "Integer" then raise (VC_Error "Subtraction is between integer")); Some classInteger
    | Div(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                     let t2 : classVerifType option = verifExpr e2 classes objects variables in
                     (if optClassName t1 <> "Integer" || optClassName t2 <> "Integer" then raise (VC_Error "Division is between integer")); Some classInteger
    | And(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                     let t2 : classVerifType option = verifExpr e2 classes objects variables in
                     (if optClassName t1 <> "Integer" || optClassName t2 <> "Integer" then raise (VC_Error "And is between integer")); Some classInteger
    | Or(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                    let t2 : classVerifType option = verifExpr e2 classes objects variables in
                    (if optClassName t1 <> "Integer" || optClassName t2 <> "Integer" then raise (VC_Error "Or is between integer")); Some classInteger
    | Comp(e1, _, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                         let t2 : classVerifType option = verifExpr e2 classes objects variables in
                         (if optClassName t1 <> "Integer" || optClassName t2 <> "Integer" then raise (VC_Error "Comparison is between integer")); Some classInteger
    | Concat(e1, e2) -> let t1 : classVerifType option = verifExpr e1 classes objects variables in
                        let t2 : classVerifType option = verifExpr e2 classes objects variables in
                        (if optClassName t1 <> "String" || optClassName t2 <> "String" then raise (VC_Error "Concatenation is between strings")); Some classString
    | UMinus(e) -> let t : classVerifType option = verifExpr e classes objects variables in
                   (if optClassName t <> "Integer" then raise (VC_Error "Negation is for integer")); Some classInteger
    | Not(e) -> let t : classVerifType option = verifExpr e classes objects variables in
                (if optClassName t <> "Integer" then raise (VC_Error "Not is for integer")); Some classInteger
    | Inst(n, a) ->
        let classe_ : classVerifType option = findClass n classes in (* Check class n exists *)
        let classe : classVerifType = (match classe_ with | None -> raise (VC_Error "Couldn't find class") | Some c -> c) in
        let cons_args : variable list = (match classe.constructeur with | None -> [] | Some c -> c.parametre) in
        (if (List.length cons_args) <> (List.length a) then raise (VC_Error (Printf.sprintf "Constructor of class %s takes %d parameters (got %d)" n (List.length cons_args) (List.length a))) else ()); (* verif parameters *)
        List.iter2 (fun (carg : Ast.expType) (marg : variable) -> if (optTypeAsNonOpt (verifExpr carg classes objects variables) "Argument can't be void").name <> marg.typeVar.name then raise (VC_Error "Wrong type argument")) a cons_args;
        Some classe (* Return the class n *)

let verifStore (lv : Ast.valueType) (e : Ast.expType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) : unit =
    (match lv with
     | Id(_) -> ()
     | Access(a) ->
         (match a.left with Val(Access(v)) -> if v.name = "this" then raise (VC_Error "Wrong store (access)") else () | _ -> ())
     | _ -> raise (VC_Error "Wrong store (not an lvalue)")
    );
    if optClassName (verifValue lv classes objects variables) <> optClassName(verifExpr e classes objects variables) then raise (VC_Error "Wrong store (type)") else ()

let rec verifInstr (i : Ast.instrType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) : unit =
    match i with
    | Expr(e) -> ignore (verifExpr e classes objects variables)
    | Bloc(b) -> verifBloc b classes objects variables
    | Return -> () (* IDK, verif reachable statement ? *)
    | Assign(lv, e) -> verifStore lv e classes objects variables
    | Ite(e, i1, i2) -> if (optClassName (verifExpr e classes objects variables) <> "Integer") then raise (VC_Error "Expression in if statement should return an integer") else (verifInstr i1 classes objects variables; verifInstr i2 classes objects variables)
and verifBloc (b : Ast.blocType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) : unit =
    Printf.printf "Enter verifBloc\n";
    (match (fst b) with
     | [] -> List.iter (fun (x : Ast.instrType) -> verifInstr x classes objects variables) (snd b)
     | l ->
         let vars = List.fold_left (fun (acc : variable list) (decl : Ast.declType) ->
            let classe_ : classVerifType option = findClass (snd decl) classes in (* Check class n exists *)
            let classe : classVerifType = (match classe_ with | None -> raise (VC_Error "Couldn't find class") | Some c -> c) in
            List.fold_left (fun (acc : variable list) (name : string) -> globalBlocOff := !globalBlocOff+1; {name = name; typeVar = classe; offset = L(!globalBlocOff)} :: acc) variables (fst decl)
         ) variables l in (* add variable to variables list *)
         List.iter (fun (x : Ast.instrType) -> verifInstr x classes objects vars) (snd b)
    );
    Printf.printf "Exit verifBloc\n"


let addMethod (m : Ast.methodType) (newclass : classVerifType) (classes : classVerifType list) : unit =
    let i : int ref = ref (-1) in
    match m with
    | Calc(override, name, params, retType, expr) ->
        let meth = {name = name; returnType = Some (getClass retType (newclass::classes)); parametre = []; offset = !globalMethodOff} in
        if override then begin
            let methoverride_ = findMethod name newclass.methode in (* class already has method : *)
            let methoverride = match methoverride_ with None -> raise (VC_Error "Method is not redefinition") | Some m -> m in
            (if (List.length methoverride.parametre) <> (List.length params) then raise (VC_Error "Method is not redefinition") else ()); (* verif parameters *)
            List.iter2 (fun (carg : Ast.paramType) (marg : variable) -> if (snd carg) <> marg.typeVar.name then raise (VC_Error "Method is not redefinition")) params methoverride.parametre;
            newclass.methode <- (meth :: newclass.methode)
        end else begin
            (match findMethod name newclass.methode with None -> () | Some _ -> raise (VC_Error "Method already defined")); (* check duplicate *)
            meth.parametre <- List.fold_left (fun acc x -> i := !i - 1; {name = (fst x); typeVar = getClass (snd x) (newclass::classes); offset = L(!i)}::acc ) [] params; (* get params *)
            newclass.methode <- (meth :: newclass.methode)
        end
    | Body(override, name, params, retType, bloc) ->
        let meth = {name = name; returnType = (match retType with None -> None | Some s -> Some (getClass s (newclass::classes))); parametre = []; offset = !globalMethodOff} in
        if override then begin
            let methoverride_ = findMethod name newclass.methode in (* class already has method : *)
            let methoverride = match methoverride_ with None -> raise (VC_Error "Method is not redefinition") | Some m -> m in
            (if (List.length methoverride.parametre) <> (List.length params) then raise (VC_Error "Method is not redefinition") else ()); (* verif parameters *)
            List.iter2 (fun (carg : Ast.paramType) (marg : variable) -> if (snd carg) <> marg.typeVar.name then raise (VC_Error "Method is not redefinition")) params methoverride.parametre;
            newclass.methode <- (meth :: newclass.methode)
        end else begin
            (match findMethod name newclass.methode with None -> () | Some _ -> raise (VC_Error "Method already defined")); (* check duplicate *)
            meth.parametre <- List.fold_right (fun x acc -> i := !i - 1; {name = (fst x); typeVar = getClass (snd x) (newclass::classes); offset = L(!i)}::acc ) params []; (* get params *)
            newclass.methode <- (meth :: newclass.methode)
        end

let addMethodObj (m : Ast.methodType) (newclass : objectVerifType) (classes : classVerifType list) : unit =
    let i : int ref = ref 0 in
    match m with
    | Calc(override, name, params, retType, expr) ->
        let meth = {name = name; returnType = Some (getClass retType classes); parametre = []; offset = !globalMethodOff} in
        (if override then raise (VC_Error "No subclass with objects") else ());
        (match findMethod name newclass.methode with None -> () | Some _ -> raise (VC_Error "Method already defined")); (* check duplicate *)
        meth.parametre <- List.fold_right (fun x acc -> i := !i - 1; {name = (fst x); typeVar = getClass (snd x) classes; offset = L(!i)}::acc ) params []; (* get params *)
        newclass.methode <- (meth :: newclass.methode)
    | Body(override, name, params, retType, bloc) ->
        let meth = {name = name; returnType = (match retType with None -> None | Some s -> Some (getClass s classes)); parametre = []; offset = !globalMethodOff} in
        (if override then raise (VC_Error "No subclass with objects") else ());
        (match findMethod name newclass.methode with None -> () | Some _ -> raise (VC_Error "Method already defined")); (* check duplicate *)
        meth.parametre <- List.fold_right (fun x acc -> i := !i - 1; {name = (fst x); typeVar = getClass (snd x) classes; offset = L(!i)}::acc ) params []; (* get params *)
        newclass.methode <- (meth :: newclass.methode)




let verifMethodBody (m : Ast.methodType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) (thiscall : bool) : unit =
    globalBlocOff := (-1);
    let params = if thiscall then {name = "this"; typeVar = !globalCurrentClass; offset = L(-1)} :: variables else variables in
    match m with
    | Calc(override, name, _, retType, expr) ->
        Printf.printf "In verifMethodBody(Calc) %s\n" name;
        if optClassName (verifExpr expr classes objects params) <> retType then raise (VC_Error "Return type don't match") else () (* check expr and compare return type *)
    | Body(override, name, _, retType, bloc) ->
        Printf.printf "In verifMethodBody(Body) %s\n" name;
        (match retType with (* check bloc, add variable for return *)
        | None -> verifBloc bloc classes objects params
        | Some t -> verifBloc bloc classes objects ({name = "result"; typeVar = getClass t classes; offset = L(-(List.length params))} :: params));
        Printf.printf "End verifMethodBody(Body) %s\n" name

let verifField (f : Ast.fieldType) (cl : classVerifType) (classes : classVerifType list): unit =
    match f with (a, n, t) ->
        let classe = if t = cl.name then cl else getClass t (cl::classes) in
        (if (List.exists (fun (x : variable) -> x.name = n) cl.champs) || (List.exists (fun (x : classmethod) -> x.name = n) cl.methode) then raise (VC_Error "duplicate field") else ());
        (if a then (cl.methode <- {name = n; returnType = Some classe; parametre = []; offset = !globalMethodOff} :: cl.methode; globalMethodOff := !globalMethodOff + 1) else ());
        cl.champs <- {name = n; typeVar = classe; offset = O(!globalFieldOff)} :: cl.champs;
        globalFieldOff := !globalFieldOff + 1

let verifFieldObj (f : Ast.fieldType) (cl : objectVerifType) (classes : classVerifType list): unit =
    match f with (a, n, t) ->
        let classe = getClass t classes in
        (if (List.exists (fun (x : variable) -> x.name = n) cl.champs) || (List.exists (fun (x : classmethod) -> x.name = n) cl.methode) then raise (VC_Error "duplicate field") else ());
        (if a then (cl.methode <- {name = n; returnType = Some classe; parametre = []; offset = !globalMethodOff} :: cl.methode; globalMethodOff := !globalMethodOff + 1) else ());
        cl.champs <- {name = n; typeVar = classe; offset = O(!globalFieldOff)} :: cl.champs;
        globalFieldOff := !globalFieldOff + 1

let methodName (m : Ast.methodType) : string =
    match m with Calc(_,s,_,_,_) -> s | Body(_,s,_,_,_) -> s

let verifObject (ob : Ast.classType) (classes : classVerifType list) (objects : objectVerifType list) : classVerifType list * objectVerifType list =
    match ob with (_, name, _, _, bl, inner) ->
    let newobj : objectVerifType = {name = name; champs = []; methode = []; constructeur = None} in
    Printf.printf "In verifObject %s\n" name;
    globalCurrentObj := newobj;
    globalCurrentClass := classOBJECTCALL;
    List.iter (fun f -> verifFieldObj f newobj classes) (fst inner);
    List.iter (fun m -> addMethodObj m newobj classes) (snd inner);
    (match bl with None -> () | Some b -> verifBloc b classes (newobj::objects) [{name = "this"; typeVar = classOBJECTCALL; offset = G(!globalClassId)}]);
    newobj.constructeur <- (match bl with None -> None | Some b -> Some {name = "_constructor_"; returnType = Some classOBJECTCALL; parametre = []; offset = -1});
    List.iter (fun m -> verifMethodBody m classes (newobj::objects) ({name = "this"; typeVar = classOBJECTCALL; offset = G(!globalClassId)}::((getMethod (methodName m) newobj.methode).parametre)) false) (snd inner);
    globalClassId := !globalClassId + 1;
    (classes, newobj::objects)


let verifParent (classe : classVerifType) (extends : Ast.extendType) (classes : classVerifType list) (objects: objectVerifType list) (params : Ast.paramType list) : unit =
    let parent = getClass (fst extends) classes in
    let i : int ref = ref 0 in
    let variables = (List.fold_left (fun acc x -> i := !i - 1; {name = (fst x); typeVar = getClass (snd x) (classe::classes); offset = L(!i)}::acc ) [{name = "this"; typeVar = !globalCurrentClass; offset = L(-(List.length params))}] params) in
    match parent.constructeur with
    | None -> if List.length params <> 0 then raise (VC_Error "Parent class doesn't have a constructor")
    | Some cons -> (if (List.length cons.parametre) <> (List.length params) then raise (VC_Error "Non matching constructor"));
                   List.iter2 (fun (carg : Ast.expType) (marg : variable) -> if optClassName (verifExpr carg classes objects variables) <> marg.typeVar.name then raise (VC_Error "Non matching constructor")) (snd extends) cons.parametre;
                   List.iter (fun x -> classe.champs <- x :: classe.champs; globalFieldOff := !globalFieldOff+1) parent.champs;
                   List.iter (fun x -> classe.methode <- x :: classe.methode; globalMethodOff := !globalMethodOff+1) parent.methode

let verifClass (cl : Ast.classType) (classes : classVerifType list) (objects : objectVerifType list) : classVerifType list * objectVerifType list =
    globalMethodOff := 0;
    globalFieldOff := 1;
    match cl with (obj, name, args, ext, bl, inner) ->
        (* TODO: forgot to check if class/object already exists *)
    if obj then verifObject cl classes objects else begin
        Printf.printf "In verifClass %s\n" name;
        let newclass : classVerifType = {name = name; champs = []; methode = []; constructeur = None; parent = None} in
        globalCurrentClass := newclass;
        (match ext with None -> () | Some e -> verifParent newclass e classes objects []);
        List.iter (fun f -> verifField f newclass classes) (fst inner);
        List.iter (fun m -> addMethod m newclass classes) (snd inner);
        let i : int ref = ref 0 in
        let cons_params = List.fold_right (fun x acc -> i := !i - 1; {name = (fst x); typeVar = getClass (snd x) (newclass::classes); offset = L(!i)}::acc ) args [] in
        (match bl with None -> () | Some b -> verifBloc b (newclass::classes) objects ({name = "this"; typeVar = newclass; offset = L(-(List.length args)-1)}::cons_params));
        newclass.constructeur <- (match bl with None -> None | Some b -> Some {name = "_constructor_"; returnType = Some newclass; parametre = cons_params; offset = -1});
        List.iter (fun m -> verifMethodBody m (newclass::classes) objects (getMethod (methodName m) (newclass.methode)).parametre true) (snd inner);
        globalClassId := !globalClassId + 1;
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
