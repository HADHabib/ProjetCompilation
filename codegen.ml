open Ast

let globalProg: progType ref = ref ([], ([],[]))

let getClass name = List.find (fun c -> match c with (_,n,_,_,_,_) -> n = name) (fst !globalProg)

let getClassSize name =
    let cl = getClass name in match cl with (_,_,_,_,_,i) -> List.length (fst i) + 1

let genGet off name =
  (match off with | O(i) -> Printf.printf "    LOAD %d -- %s\n" i name | G(i) -> Printf.printf "    PUSHG %d -- %s\n" i name | L(i) -> Printf.printf "    PUSHL %d -- %s\n" i name)
let genStore off name =
  (match off with | O(i) -> Printf.printf "    STORE %d -- %s\n" i name | G(i) -> Printf.printf "    STOREG %d -- %s\n" i name | L(i) -> Printf.printf "    STOREL %d -- %s\n" i name)

let rec genGetVal v =
    match v with
    | Id(v) -> genGet v.off v.name
    | Method(m) -> if m.vTableId = -1 then if m.pushLeft then genStaticCall (m.objectName ^ "_" ^ m.name) (m.left::m.args) true  else genStaticCall (m.objectName ^ "_" ^ m.name) m.args true else genThisCall m
    | Access(a) -> genExpr a.left; genGet a.off a.name
    | Cste(i) -> Printf.printf "    PUSHI %d\n" i
    | Str(s) -> Printf.printf "    PUSHS %s\n" s
and genExpr e =
    match e with
    | Val(v) -> genGetVal v
    | Plus(e1, e2) -> genExpr e1; genExpr e2; Printf.printf "    ADD\n"
    | Times(e1, e2) -> genExpr e1; genExpr e2; Printf.printf "    MUL\n"
    | Minus(e1, e2) -> genExpr e1; genExpr e2; Printf.printf "    SUB\n"
    | Div(e1, e2) -> genExpr e1; genExpr e2; Printf.printf "    DIV\n"
    | And(e1, e2) -> genExpr e1; genExpr e2; Printf.printf "    AND\n"
    | Or(e1, e2) -> genExpr e1; genExpr e2; Printf.printf "    OR\n"
    | Concat(e1, e2) -> genExpr e1; genExpr e2; Printf.printf "    CONCAT\n"
    | UMinus(e) -> genExpr e; Printf.printf "    PUSHI -1\n    MUL\n"
    | Not(e) -> genExpr e; Printf.printf "    NOT\n"
    | Inst(n, a) -> Printf.printf "    ALLOC %d\n" (getClassSize n); genStaticCall (n ^ "__constructor") a false
    | Comp(e1, c, e2) -> match c with
    | Eq -> genExpr e1; genExpr e2; Printf.printf "    EQUAL\n"
    | Neq -> genExpr e1; genExpr e2; Printf.printf "    EQUAL\n    NOT\n"
    | Lt -> genExpr e1; genExpr e2; Printf.printf "    INF\n"
    | Le -> genExpr e1; genExpr e2; Printf.printf "    INFEQ\n"
    | Gt -> genExpr e1; genExpr e2; Printf.printf "    SUP\n"
    | Ge -> genExpr e1; genExpr e2; Printf.printf "    SUPEQ\n"
and genStaticCall name args allocRet =
    (if allocRet then Printf.printf "    PUSHN 1 -- alloc return value\n" else ());
    List.iter genExpr args;
    Printf.printf "    PUSHA %s\n    CALL\n" name;
    if (List.length args) > 0 then Printf.printf "    POPN %d -- cleanup args\n" (List.length args) else ()
and genThisCall m =
    Printf.printf "    PUSHN 1 -- alloc return value\n";
    List.iter genExpr m.args;
    genExpr m.left;
    Printf.printf "    DUPN 1 -- this\n    LOAD 0 -- VTable\n    LOAD %d -- Method\n    CALL\n    POPN %d -- cleanup args\n" m.vTableId (List.length m.args + 1)

let genStoreVal v =
    match v with
    | Id(v) -> genStore v.off v.name
    | Access(a) -> genExpr a.left; genStore a.off a.name
    | _ -> ()

let rec genInstr i =
    match i with
    | Expr(e) -> genExpr e; Printf.printf "    POPN 1 -- cleanup stack\n"
    | Bloc(b) -> genBloc b
    | Return -> Printf.printf "    RETURN\n" (* nettoyer la pile ? *)
    | Assign(lv, e) -> genExpr e; genStoreVal lv
    | Ite(e, i1, i2) -> genExpr e; Printf.printf "    JZ %s\n" "label_else"; (* TODO: auto generate label *)
                    genInstr i1; Printf.printf "    JUMP %s\n" "label_endif"; (* TODO: auto generate label *)
                    Printf.printf "%s: NOP\n" "label_else"; genInstr i2; (* TODO: use same label *)
                    Printf.printf "%s: NOP\n" "label_endif" (* TODO: use same label *)
and genBloc b =
    (match (fst b) with
     | [] -> ()
     | l -> Printf.printf "    PUSHN %d -- Alloc space for local vars\n" (List.fold_left (fun a v -> a + List.length (fst v)) 0 l)
    );
    List.iter genInstr (snd b)

let globalClassName = ref ""
let globalClassId = ref 0

let genMethod m =
    match m with
    | Calc(_, name, a, _, e) ->
        Printf.printf "%s_%s: NOP\n" !globalClassName name;
        genExpr e;
        Printf.printf "    STOREL %d -- result\n    RETURN\n\n" (-(List.length a)-2)
    | Body(_, name, _, _, b) ->
        Printf.printf "%s_%s: NOP\n" !globalClassName name;
        genBloc b;
        Printf.printf "    RETURN\n\n"

let genConstructor n a b p =
    Printf.printf "%s__constructor: NOP\n" n;
    (match p with
     | None -> ()
     | Some parent ->  (* call parent constructor *)
         Printf.printf "    PUSHL %d -- ptr\n" (-(List.length a) - 1);
         genStaticCall ((fst parent) ^ "__constructor") (snd parent) false;
         Printf.printf "    POPN 1 -- remove ptr\n"
    );
    Printf.printf "    PUSHG %d -- Vtable_%s\n    STORE 0\n" !globalClassId n; (* store VTable at offset 0 *)
    (match b with
     | None -> ()
     | Some bl -> genBloc bl
    );
    Printf.printf "    RETURN\n\n"



let genGetter c f =
    let cl = getClass c in
    let off = let i = ref 0 in let j = ref 0 in match cl with (_,_,_,_,_,inn) -> List.iter (fun fi -> match fi with (_,n,_) -> (if n=f then i := !j else ()); j := !j+1) (fst inn); !i in
    Printf.printf "%s_%s: PUSHL -1\n    LOAD %d\n    STOREL -2\n    RETURN\n\n" c f off

let preGenClass cl =
    match cl with (obj, name, _, _, _, inner) -> begin
        if obj then begin (* construct static instance *)
            Printf.printf "    ALLOC %d\n" (getClassSize name); genStaticCall (name ^ "__constructor") [] false;
            Printf.printf "    STOREG %d\n" !globalClassId;
        end else begin (* create VTable *)
            Printf.printf "    ALLOC %d\n    DUPN %d\n" (List.length (snd inner)) (List.length (snd inner));
            (* TODO: getters in VTable + redefinitions*)
            let i = ref 0 in List.iter (fun m -> (match m with
                                              | Calc(_, n, _, _, _) -> Printf.printf "    PUSHA %s_%s\n    STORE %d\n" name n !i
                                              | Body(_, n, _, _, _) -> Printf.printf "    PUSHA %s_%s\n    STORE %d\n" name n !i);
                                              i := !i + 1) (snd inner);
            Printf.printf "    STOREG %d\n" !globalClassId;
        end
    end;
    globalClassId := !globalClassId + 1

let genStatic prog =
    Printf.printf "    START\n";
    List.iter preGenClass (fst prog);
    Printf.printf "    JUMP start\n\n";
    Printf.printf "Integer_toString: PUSHL -1\n    STR\n    STOREL -2\n    RETURN\n\n";
    Printf.printf "String_print: PUSHL -1\n    WRITES\n    RETURN\n\n";
    Printf.printf "String_println: PUSHL -1\n    PUSHS \"\\n\"\n    CONCAT\n    WRITES\n    RETURN\n\n"

let genClass cl =
    match cl with (_,n,a,p,c,i) ->
        globalClassName := n;
        genConstructor n a c p;
        List.iter (fun field -> match field with (auto, fieldname, _) -> if auto then genGetter n fieldname else ()) (fst i);
        List.iter genMethod (snd i);
        globalClassId := !globalClassId + 1

let genProg prog =
    globalProg := prog;
    globalClassId := 0;
    genStatic prog;
    globalClassId := 0;
    List.iter genClass (fst prog);
    Printf.printf "start: NOP\n";
    genBloc (snd prog);
    Printf.printf "    STOP\n"
