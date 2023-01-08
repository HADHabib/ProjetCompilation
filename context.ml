open Ast


type classVerifType = {name : string; mutable champs : variable list; mutable methode : classmethod list; mutable constructeur : classmethod; mutable parent : classVerifType option; mutable id : int}
and variable = {name : string; typeVar : classVerifType; mutable offset : Ast.offset}
and classmethod = {name : string; returnType : classVerifType option; mutable parametre : variable list; mutable offset : int }
type objectVerifType = {name : string; mutable champs : variable list; mutable methode : classmethod list; mutable constructeur : classmethod}

(* builtin classes and methods *)
let classInteger : classVerifType = {name = "Integer"; champs = []; methode = []; constructeur = {name = "_constructor_"; returnType = None; parametre = []; offset = -1}; parent = None; id = -1}
let classString : classVerifType = {name = "String"; champs = []; methode = []; constructeur = {name = "_constructor_"; returnType = None; parametre = []; offset = -1}; parent = None; id = -1}
let integer_toString : classmethod = {name = "toString" ; returnType = Some classString ; parametre = []; offset = -1}
let string_print : classmethod = {name = "print"; returnType = None; parametre = []; offset = -1}
let string_println : classmethod = {name = "println"; returnType = None; parametre = []; offset = -1}

(* helper class and object *)
let classOBJECTCALL : classVerifType = {name = "_object_"; champs = []; methode = []; constructeur = {name = "_constructor_"; returnType = None; parametre = []; offset = -1}; parent = None; id = -1} (* Should be used for objects *)
let objEmpty : objectVerifType = {name = "_empty_"; champs = []; methode = []; constructeur = {name = "_constructor_"; returnType = None; parametre = []; offset = -1};} (* Should never be used *)

let globalBlocOff : int ref = ref (-1)
let globalFieldOff : int ref = ref 1
let globalMethodOff : int ref = ref 0
let globalCurrentClass : classVerifType ref = ref classOBJECTCALL
let globalCurrentObj : objectVerifType ref = ref objEmpty
let globalClassId : int ref = ref 0


(* helper functions *)
let findClass  (name : string) (classes   : classVerifType  list) : classVerifType  option = List.find_opt (fun (a : classVerifType ) -> name = a.name) classes
let findObject (name : string) (objects   : objectVerifType list) : objectVerifType option = List.find_opt (fun (a : objectVerifType) -> name = a.name) objects
let findVar    (name : string) (variables : variable        list) : variable        option = List.find_opt (fun (a : variable       ) -> name = a.name) variables
let findMethod (name : string) (methodes  : classmethod     list) : classmethod     option = List.find_opt (fun (a : classmethod    ) -> name = a.name) methodes

let getClass  (name : string) (classes   : classVerifType  list) : classVerifType  = (match findClass  name classes   with | None -> raise (VC_Error (Printf.sprintf "class not found : %s"    name)) | Some t -> t)
let getObject (name : string) (objects   : objectVerifType list) : objectVerifType = (match findObject name objects   with | None -> raise (VC_Error (Printf.sprintf "object not found : %s"   name)) | Some t -> t)
let getVar    (name : string) (variables : variable        list) : variable        = (match findVar    name variables with | None -> raise (VC_Error (Printf.sprintf "variable not found : %s" name)) | Some t -> t)
let getMethod (name : string) (methodes  : classmethod     list) : classmethod     = (match findMethod name methodes  with | None -> raise (VC_Error (Printf.sprintf "method not found : %s"   name)) | Some t -> t)

let optClassName (cl : classVerifType option) : string = match cl with None -> "Void" | Some c -> c.name
let optClassID   (cl : classVerifType option) :    int = match cl with None ->     -1 | Some c -> c.id

let rec compatibleClass (classe : classVerifType option) (name : string) : bool = match classe with None -> false | Some c -> if c.name = name then true else compatibleClass c.parent name

(* verif functions *)
let rec verifValue (v : Ast.valueType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) : classVerifType option =
    match v with
    | Id(var) -> let var_ : variable option = findVar var.name variables in (* get variable *)
        ( match var_ with | None -> raise (VC_Error (Printf.sprintf "Undefined variable : %s" var.name)) (* check if variable exists *)
        | Some v -> var.off <- v.offset; Some v.typeVar (* annotate AST and return type of variable *) )
    | Method(call) ->
        (* Special case for 'super' *)
        let typ_ : classVerifType option = match call.left with Val(Id(var)) -> if var.name = "super" then (call.supercall <- optClassID (getVar "this" variables).typeVar.parent; var.off <- (getVar "this" variables).offset; Some (getVar "this" variables).typeVar)
        else verifExpr call.left classes objects variables
        | _ -> verifExpr call.left classes objects variables in (* get type of left expression *)
        begin match typ_ with
        | None ->
            let obj : objectVerifType = getObject call.objectName objects in
            let methode_ : classmethod option = findMethod call.name obj.methode in (* check method exist in obj *)
            let methode : classmethod = (match methode_ with | None -> raise (VC_Error (Printf.sprintf "Undefined method : %s::%s" obj.name call.name)) | Some m -> m) in
            (if (List.length methode.parametre) <> (List.length call.args) then raise (VC_Error (Printf.sprintf "Wrong arguments for method %s::%s" call.objectName call.name)) else ()); (* verif parameters *)
            List.iter2 (fun (carg : Ast.expType) (marg : variable) -> if not (compatibleClass (verifExpr carg classes objects variables) marg.typeVar.name) then raise (VC_Error (Printf.sprintf "Wrong type argument for method %s::%s" call.objectName call.name))) call.args methode.parametre;
            methode.returnType (* return type of return value *)
        | Some typ ->
            let methode_ : classmethod option = findMethod call.name typ.methode in (* check method exist in typ *)
            let methode : classmethod = (match methode_ with | None -> raise (VC_Error (Printf.sprintf "Undefined method : %s::%s" typ.name call.name)) | Some m -> m) in
            (if (List.length methode.parametre) <> (List.length call.args) then raise (VC_Error (Printf.sprintf "Wrong arguments for method %s::%s" typ.name call.name)) else ()); (* verif parameters *)
            List.iter2 (fun (carg : Ast.expType) (marg : variable) -> if not (compatibleClass (verifExpr carg classes objects variables) marg.typeVar.name) then raise (VC_Error (Printf.sprintf "Wrong type argument for method %s::%s" typ.name call.name))) call.args methode.parametre;
            call.vTableId <- methode.offset; (* annotate AST *)
            (* special cases : *)
            (if methode = integer_toString then (call.objectName <- "Integer"; call.pushLeft <- true) else ());
            (if methode = string_print then (call.objectName <- "String"; call.pushLeft <- true) else ());
            (if methode = string_println then (call.objectName <- "String"; call.pushLeft <- true) else ());
            methode.returnType (* return type of return value *)
        end
    | Access(acc) ->
        let var_ : variable option = findVar "this" variables in (* you can only access this *)
        let var : variable = (match var_ with | None -> raise (VC_Error "Couldn't find variable 'this' in context") | Some v -> v) in
        let (this,typ_) : Ast.valueTypeId * classVerifType option =
          match acc.left with
          | Val(Id(v)) -> if v.name = "this" then (v, Some var.typeVar) else if v.name = "super" then (v, var.typeVar.parent) else raise (VC_Error (Printf.sprintf "Variable %s can't be accessed" v.name))
          | Cast(t, Val(Id(v))) -> if (v.name = "this" || v.name = "super") && compatibleClass (Some var.typeVar) t then (v, Some (getClass t classes)) else raise (VC_Error (Printf.sprintf "Variable %s can't be accessed" v.name))
          | _ -> raise (VC_Error (Printf.sprintf "This is not a variable" )) in
        this.off <- var.offset; (* annotate AST left *)
        let typ = match typ_ with None -> raise (VC_Error "type none ...") | Some t -> t in
        (* check if this is object - *)
        if typ.name = "_object_" then begin
            let obj : objectVerifType = !globalCurrentObj in
            let field_ : variable option = findVar acc.name obj.champs in
            let field : variable = (match field_ with | None -> raise (VC_Error (Printf.sprintf "Couldn't find field %s in object %s" acc.name obj.name)) | Some v -> v) in
            acc.off <- field.offset;
            Some field.typeVar
        end else begin
            let field_ : variable option = findVar acc.name typ.champs in
            let field : variable = (match field_ with | None -> raise (VC_Error (Printf.sprintf "Couldn't find field %s in class %s" acc.name typ.name)) | Some v -> v) in
            acc.off <- field.offset;
            Some field.typeVar
        end
    | Cste(i) -> Some classInteger
    | Str(s) -> Some classString
and verifExpr (e : Ast.expType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) : classVerifType option =
    match e with
    | Val(v) -> verifValue v classes objects variables
    | Plus(e1, e2) -> let t1 : string = optClassName (verifExpr e1 classes objects variables) in
                      let t2 : string = optClassName (verifExpr e2 classes objects variables) in
                      (if t1 <> "Integer" || t2 <> "Integer" then raise (VC_Error (Printf.sprintf "Addition is between integer (got %s ans %s)" t1 t2))); Some classInteger
    | Times(e1, e2) -> let t1 : string = optClassName (verifExpr e1 classes objects variables) in
                       let t2 : string = optClassName (verifExpr e2 classes objects variables) in
                       (if t1 <> "Integer" || t2 <> "Integer" then raise (VC_Error (Printf.sprintf "Multiplication is between integer (got %s ans %s)" t1 t2))); Some classInteger
    | Minus(e1, e2) -> let t1 : string = optClassName (verifExpr e1 classes objects variables) in
                       let t2 : string = optClassName (verifExpr e2 classes objects variables) in
                       (if t1 <> "Integer" || t2 <> "Integer" then raise (VC_Error (Printf.sprintf "Subtraction is between integer (got %s ans %s)" t1 t2))); Some classInteger
    | Div(e1, e2) -> let t1 : string = optClassName (verifExpr e1 classes objects variables) in
                     let t2 : string = optClassName (verifExpr e2 classes objects variables) in
                     (if t1 <> "Integer" || t2 <> "Integer" then raise (VC_Error (Printf.sprintf "Division is between integer (got %s ans %s)" t1 t2))); Some classInteger
    | Comp(e1, _, e2) -> let t1 : string = optClassName (verifExpr e1 classes objects variables) in
                         let t2 : string = optClassName (verifExpr e2 classes objects variables) in
                         (if t1 <> "Integer" || t2 <> "Integer" then raise (VC_Error (Printf.sprintf "Comparison is between integer (got %s ans %s)" t1 t2))); Some classInteger
    | Concat(e1, e2) -> let t1 : string = optClassName (verifExpr e1 classes objects variables) in
                        let t2 : string = optClassName (verifExpr e2 classes objects variables) in
                        (if t1 <> "String" || t2 <> "String" then raise (VC_Error (Printf.sprintf "Concatenation is between strings (got %s ans %s)" t1 t2))); Some classString
    | UMinus(e) -> let t : string = optClassName (verifExpr e classes objects variables) in
                   (if t <> "Integer" then raise (VC_Error (Printf.sprintf "Negation is for integer (got %s)" t))); Some classInteger
    | Not(e) -> let t : string = optClassName (verifExpr e classes objects variables) in
                (if t <> "Integer" then raise (VC_Error (Printf.sprintf "Not is for integer (got %s)" t))); Some classInteger
    | EmptyExpr -> None
    | Inst(n, a) ->
        let classe_ : classVerifType option = findClass n classes in (* Check class n exists *)
        let classe : classVerifType = (match classe_ with | None -> raise (VC_Error (Printf.sprintf "Couldn't find class %s for instantiation" n)) | Some c -> c) in
        (if classe.name = "String" || classe.name = "Integer" then raise (VC_Error (Printf.sprintf "Can't instanciate class %s" classe.name)));
        (if (List.length classe.constructeur.parametre) <> (List.length a) then raise (VC_Error (Printf.sprintf "Constructor of class %s takes %d parameters (got %d)" n (List.length classe.constructeur.parametre) (List.length a))) else ()); (* verif parameters *)
        List.iter2 (fun (carg : Ast.expType) (marg : variable) -> if not (compatibleClass (verifExpr carg classes objects variables) marg.typeVar.name)
                                                                then raise (VC_Error (Printf.sprintf "Wrong type argument for constructor of class %s" n))) a classe.constructeur.parametre;
        Some classe (* Return the class n *)
    | Cast(c, e) -> if compatibleClass (verifExpr e classes objects variables) c then Some (getClass c classes) else raise (VC_Error (Printf.sprintf "Incompatible class cast to %s" c))


let verifStore (lv : Ast.valueType) (e : Ast.expType) (classes : classVerifType list) (objects : objectVerifType list) (variables : variable list) : unit =
    (match lv with
     | Id(_) -> ()
     | Access(a) ->
         (match a.left with Val(Access(v)) -> if v.name = "this" then raise (VC_Error "Wrong store : only 'this' can be accessed") else () | _ -> ())
     | _ -> raise (VC_Error "Wrong store : can't access an rvalue")
    );
    let n = optClassName (verifValue lv classes objects variables) in let cl = (verifExpr e classes objects variables) in
    if not (compatibleClass cl n) then raise (VC_Error (Printf.sprintf "Wrong store : non matching types %s & %s" (optClassName cl) n)) else ()

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
            let classe : classVerifType = getClass (snd decl) classes in (* Check class n exists *)
            acc @ List.fold_left (fun (acc : variable list) (name : string) -> globalBlocOff := !globalBlocOff+1; {name = name; typeVar = classe; offset = L(!globalBlocOff)} :: acc) variables (fst decl)
         ) variables l in (* add variable to variables list *)
         List.iter (fun (x : Ast.instrType) -> verifInstr x classes objects vars) (snd b)
    )


let addMethod (m : Ast.methodType) (newclass : classVerifType) (classes : classVerifType list) : unit =
    let i : int ref = ref (-1) in
    match m with
    | Calc(override, name, params, retType, expr) ->
        let meth = {name = name; returnType = Some (getClass retType (newclass::classes)); parametre = []; offset = !globalMethodOff} in
        globalMethodOff := !globalMethodOff + 1;
        if override then begin
            let methoverride_ = findMethod name newclass.methode in (* class already has method : *)
            let methoverride = match methoverride_ with None -> raise (VC_Error "Method is not redefinition") | Some m -> m in
            (if (List.length methoverride.parametre) <> (List.length params) then raise (VC_Error "Method is not redefinition") else ()); (* verif parameters *)
            List.iter2 (fun (carg : Ast.paramType) (marg : variable) -> if (snd carg) <> marg.typeVar.name then raise (VC_Error "Method is not redefinition")) params methoverride.parametre;
            newclass.methode <- (methoverride :: newclass.methode)
        end else begin
            (match findMethod name newclass.methode with None -> () | Some _ -> raise (VC_Error "Method already defined")); (* check duplicate *)
            meth.parametre <- List.fold_left (fun acc x -> i := !i - 1; {name = (fst x); typeVar = getClass (snd x) (newclass::classes); offset = L(!i)}::acc ) [] params; (* get params *)
            newclass.methode <- (meth :: newclass.methode)
        end
    | Body(override, name, params, retType, bloc) ->
        let meth = {name = name; returnType = (match retType with None -> None | Some s -> Some (getClass s (newclass::classes))); parametre = []; offset = !globalMethodOff} in
        globalMethodOff := !globalMethodOff + 1;
        if override then begin
            let methoverride_ = findMethod name newclass.methode in (* class already has method : *)
            let methoverride = match methoverride_ with None -> raise (VC_Error "Method is not redefinition") | Some m -> m in
            (if (List.length methoverride.parametre) <> (List.length params) then raise (VC_Error "Method is not redefinition") else ()); (* verif parameters *)
            List.iter2 (fun (carg : Ast.paramType) (marg : variable) -> if (snd carg) <> marg.typeVar.name then raise (VC_Error "Method is not redefinition")) params methoverride.parametre;
            newclass.methode <- (methoverride :: newclass.methode)
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
        globalMethodOff := !globalMethodOff + 1;
        (if override then raise (VC_Error "No subclass with objects") else ());
        (match findMethod name newclass.methode with None -> () | Some _ -> raise (VC_Error "Method already defined")); (* check duplicate *)
        meth.parametre <- List.fold_right (fun x acc -> i := !i - 1; {name = (fst x); typeVar = getClass (snd x) classes; offset = L(!i)}::acc ) params []; (* get params *)
        newclass.methode <- (meth :: newclass.methode)
    | Body(override, name, params, retType, bloc) ->
        let meth = {name = name; returnType = (match retType with None -> None | Some s -> Some (getClass s classes)); parametre = []; offset = !globalMethodOff} in
        globalMethodOff := !globalMethodOff + 1;
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
        if not (compatibleClass (verifExpr expr classes objects params) retType) then raise (VC_Error "Return type don't match") else () (* check expr and compare return type *)
    | Body(override, name, _, retType, bloc) ->
        Printf.printf "In verifMethodBody(Body) %s\n" name;
        (match retType with (* check bloc, add variable for return *)
        | None -> verifBloc bloc classes objects params
        | Some t -> verifBloc bloc classes objects ({name = "result"; typeVar = getClass t classes; offset = L(-(List.length params)-(if thiscall then 1 else 0))} :: params))

let verifField (f : Ast.fieldType) (cl : classVerifType) (classes : classVerifType list): unit =
    match f with (a, n, t) ->
        let classe = if t = cl.name then cl else getClass t (cl::classes) in
        (* TODO: check fields among only current class added fields : (if List.exists (fun (x : variable) -> x.name = n) cl.champs then raise (VC_Error "duplicate field") else ());*)
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
    let newobj : objectVerifType = {name = name; champs = []; methode = []; constructeur = {name = "_constructor_"; returnType = None; parametre = []; offset = -1};} in
    Printf.printf "In verifObject %s\n" name;
    globalCurrentObj := newobj;
    globalCurrentClass := classOBJECTCALL;
    List.iter (fun f -> verifFieldObj f newobj classes) (fst inner);
    List.iter (fun m -> addMethodObj m newobj classes) (snd inner);
    (match bl with None -> () | Some b -> verifBloc b classes (newobj::objects) [{name = "this"; typeVar = classOBJECTCALL; offset = L(-1)}]);
    List.iter (fun m -> verifMethodBody m classes (newobj::objects) ({name = "this"; typeVar = classOBJECTCALL; offset = G(!globalClassId)}::((getMethod (methodName m) newobj.methode).parametre)) false) (snd inner);
    globalClassId := !globalClassId + 1;
    (classes, newobj::objects)


let verifParent (classe : classVerifType) (extends : Ast.extendType) (classes : classVerifType list) (objects: objectVerifType list) (params : Ast.paramType list) : unit =
    let parent = getClass (fst extends) classes in
    (if parent.name = "Integer" || parent.name = "String" then raise (VC_Error (Printf.sprintf "%s can't be a subclass of %s" classe.name parent.name)));
    classe.parent <- Some parent;
    let i : int ref = ref 0 in
    let variables = (List.fold_right (fun x acc -> i := !i - 1; {name = (fst x); typeVar = getClass (snd x) (classe::classes); offset = L(!i)}::acc ) params [{name = "this"; typeVar = !globalCurrentClass; offset = L(-(List.length params))}]) in
    (if (List.length parent.constructeur.parametre) <> (List.length (snd extends))
    then raise (VC_Error (Printf.sprintf "%s : constructor of superclass %s takes %d parameters (got %d)" classe.name parent.name (List.length parent.constructeur.parametre) (List.length (snd extends)))));
    List.iter2 (fun (carg : Ast.expType) (marg : variable) -> if optClassName (verifExpr carg classes objects variables) <> marg.typeVar.name then raise (VC_Error "Non matching constructor (arg)")) (snd extends) parent.constructeur.parametre;
    List.iter (fun x -> classe.champs <- x :: classe.champs; globalFieldOff := !globalFieldOff+1) parent.champs;
    List.iter (fun x -> classe.methode <- x :: classe.methode; globalMethodOff := !globalMethodOff+1) parent.methode

let verifClass (cl : Ast.classType) (classes : classVerifType list) (objects : objectVerifType list) : classVerifType list * objectVerifType list =
    globalMethodOff := 0;
    globalFieldOff := 1;
    match cl with (obj, name, args, ext, bl, inner) ->
    (match findClass name classes with Some _ -> raise (VC_Error (Printf.sprintf "duplicate class %s" name)) | _ -> ());
    (match findObject name objects with Some _ -> raise (VC_Error (Printf.sprintf "duplicate class %s" name)) | _ -> ());
    if obj then verifObject cl classes objects else begin
        Printf.printf "In verifClass %s\n" name;
        let newclass : classVerifType = {name = name; champs = []; methode = []; constructeur = {name = "_constructor_"; returnType = None; parametre = []; offset = -1}; parent = None; id = !globalClassId} in
        globalCurrentClass := newclass;
        (match ext with None -> () | Some e -> verifParent newclass e classes objects args);
        List.iter (fun f -> verifField f newclass classes) (fst inner);
        List.iter (fun m -> addMethod m newclass classes) (snd inner);
        let i : int ref = ref 0 in
        newclass.constructeur.parametre <- List.fold_right (fun x acc -> i := !i - 1; {name = (fst x); typeVar = getClass (snd x) (newclass::classes); offset = L(!i)}::acc ) args [];
        (match bl with None -> () | Some b -> verifBloc b (newclass::classes) objects ({name = "this"; typeVar = newclass; offset = L(-(List.length args)-1)}::(newclass.constructeur.parametre)));
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
    globalBlocOff := !globalClassId - 1;
    verifBloc (snd prog) (fst allClassesObjects) (snd allClassesObjects) []
