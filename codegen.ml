open Ast

let globalProg: progType ref = ref ([], ([],[]))

let getClass name = List.find (fun c -> match c with (_,n,_,_,_,_) -> n = name) (fst !globalProg)

let getClassId name = let i = ref (-1) in let j = ref (-1) in List.iter (fun c -> i := !i + 1; if (match c with (_,n,_,_,_,_) -> n = name) then j := !i) (fst !globalProg); !j

let rec getClassSize name =
    let cl = getClass name in match cl with (_,_,_,e,_,i) ->
    match e with None -> List.length (fst i) + 1
    | Some (s,_) -> (getClassSize s) + (List.length (fst i))

let genGet off name =
  (match off with | O(i) -> Printf.printf "    LOAD %d -- %s\n" i name | G(i) -> Printf.printf "    PUSHG %d -- %s\n" i name | L(i) -> Printf.printf "    PUSHL %d -- %s\n" i name)
let genStore off name =
  (match off with | O(i) -> Printf.printf "    SWAP\n    STORE %d -- %s\n" i name | G(i) -> Printf.printf "    STOREG %d -- %s\n" i name | L(i) -> Printf.printf "    STOREL %d -- %s\n" i name)

let rec getActualFieldOffset cl fname =
    let i = ref (-1) in let j = ref (-1) in
    match getClass cl with (_,_,_,e,_,inner) ->
        match e with None ->
            List.iter (fun f -> i := !i + 1; if (match f with (_,n,_) -> n = fname) then j := !i) (fst inner); !j+1
        | Some ex -> let parSiz = getClassSize (fst ex) in
            List.iter (fun f -> i := !i + 1; if (match f with (_,n,_) -> n = fname) then j := !i) (fst inner);
            if (!j = -1) then getActualFieldOffset (fst ex) fname else !j + parSiz


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
    | Concat(e1, e2) -> genExpr e1; genExpr e2; Printf.printf "    CONCAT\n"
    | UMinus(e) -> genExpr e; Printf.printf "    PUSHI -1\n    MUL\n"
    | Not(e) -> genExpr e; Printf.printf "    NOT\n"
    | Inst(n, a) -> Printf.printf "    ALLOC %d\n" (getClassSize n); genStaticCall (n ^ "__constructor") a false
    | Cast(t, e) -> genExpr e
    | EmptyExpr -> ()
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
    (if m.supercall > -1 then Printf.printf "    PUSHG %d -- super VTable\n" m.supercall else Printf.printf "    DUPN 1 -- this\n    LOAD 0 -- VTable\n");
    Printf.printf "    LOAD %d -- Method\n    CALL\n    POPN %d -- cleanup args\n" (m.vTableId+1) (List.length m.args + 1)

let genStoreVal v =
    match v with
    | Id(v) -> genStore v.off v.name
    | Access(a) -> genExpr a.left; genStore a.off a.name
    | _ -> ()

let i: int ref = ref 0
let genLabel (n : string) : string = i := !i + 1; Printf.sprintf "lbl__%d__%s%d" !i n !i

let rec genInstr i =
    match i with
    | Expr(e) -> genExpr e; Printf.printf "    POPN 1 -- cleanup stack\n"
    | Bloc(b) -> genBloc b
    | Return -> Printf.printf "    RETURN\n" (* nettoyer la pile ? *)
    | Assign(lv, e) -> genExpr e; genStoreVal lv
    | Ite(e, i1, i2) ->
        let label_else = genLabel "else" in
        let label_endif = genLabel "endif" in
        genExpr e; Printf.printf "    JZ %s\n" label_else;
        genInstr i1; Printf.printf "    JUMP %s\n" label_endif;
        Printf.printf "%s: NOP\n" label_else; genInstr i2;
        Printf.printf "%s: NOP\n" label_endif
and genBloc b =
    match (fst b) with
    | [] -> List.iter genInstr (snd b)
    | l -> let nb = List.fold_left (fun a v -> a + List.length (fst v)) 0 l in
        Printf.printf "    PUSHN %d -- Alloc space for local vars\n" nb;
        List.iter genInstr (snd b);
        Printf.printf "    POPN %d -- De-alloc space for local vars\n" nb

let globalClassName = ref ""
let globalClassId = ref 0

let genMethod m thiscall =
    match m with
    | Calc(_, name, a, _, e) ->
        Printf.printf "%s_%s: NOP\n" !globalClassName name;
        genExpr e;
        Printf.printf "    STOREL %d -- result\n    RETURN\n\n" (-(List.length a)-(if thiscall then 2 else 1))
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
    Printf.printf "    PUSHL %d -- ptr\n" (-(List.length a) - 1);
    Printf.printf "    PUSHG %d -- Vtable_%s\n    STORE 0\n" !globalClassId n; (* store VTable at offset 0 *)
    (match b with
     | None -> ()
     | Some bl -> genBloc bl
    );
    Printf.printf "    RETURN\n\n"



let genGetter c f objNum =
    Printf.printf "%s_%s: " c f;
    (if objNum = -1 then Printf.printf "PUSHL -1\n" else Printf.printf "PUSHG %d\n" objNum);
    (*let cl = getClass c in*)
    let off = getActualFieldOffset c f in (*let i = ref 0 in let j = ref 0 in match cl with (_,_,_,_,_,inn) -> List.iter (fun fi -> match fi with (_,n,_) -> (if n=f then i := !j else ()); j := !j+1) (fst inn); !i in*)
    Printf.printf "    LOAD %d\n    STOREL %d\n    RETURN\n\n" off (if objNum = -1 then -2 else -1)

type vtable = (string * string) list

let rec fillVtable (name : string) ext inner : vtable =
    match ext with None ->
        (* Getters *)
        (List.fold_right (fun (x : Ast.fieldType) (acc : vtable) -> match x with (a,n,_) -> if a then (n, Printf.sprintf "%s_%s" name n)::acc else acc) (fst inner) []) @
        (* Methods *)
        (List.fold_right (fun (x : Ast.methodType) (acc : vtable) -> match x with
          | Calc(_,n,_,_,_) -> (n, Printf.sprintf "%s_%s" name n)::acc
          | Body(_,n,_,_,_) -> (n, Printf.sprintf "%s_%s" name n)::acc) (snd inner) [])
    | Some e -> match getClass (fst e) with (_, supername, _, superext, _, superinner) ->
        let vTable = fillVtable supername superext superinner in
        let vTable2 = (List.fold_right (fun x acc ->
            match (List.find_opt (fun m -> match m with Calc(_,n,_,_,_) -> n = (fst x) | Body(_,n,_,_,_) -> n = (fst x)) (snd inner))
            with None -> x::acc | Some m -> match m with
            | Calc(_,n,_,_,_) -> (n, Printf.sprintf "%s_%s" name n)::acc
            | Body(_,n,_,_,_) -> (n, Printf.sprintf "%s_%s" name n)::acc
        ) vTable []) in
        vTable2 @ (List.fold_right (fun (x : Ast.fieldType) (acc : vtable) -> match x with (a,n,_) -> if a then (n, Printf.sprintf "%s_%s" name n)::acc else acc) (fst inner) []) @
        (List.fold_right (fun (x : Ast.methodType) (acc : vtable) -> match x with
          | Calc(o,n,_,_,_) -> if not o then (n, Printf.sprintf "%s_%s" name n)::acc else acc
          | Body(o,n,_,_,_) -> if not o then (n, Printf.sprintf "%s_%s" name n)::acc else acc) (snd inner) [])


let genVtable (vt : vtable) (ext : Ast.extendType option) : unit =
    Printf.printf "    PUSHN 1\n    ALLOC %d\n" (List.length vt + 1);
    (match ext with None -> () | Some e -> Printf.printf "    DUPN 1\n    PUSHG %d\n    STORE 0\n" (getClassId (fst e)));
    let i = ref 1 in
    List.iter (fun f -> Printf.printf "    DUPN 1\n    PUSHA %s\n    STORE %d\n" (snd f) !i; i := !i + 1) vt;
    Printf.printf "    STOREG %d\n" !globalClassId

let preGenClass cl =
    match cl with (obj, name, _, ext, _, inner) -> begin
        if obj then begin (* construct static instance *)
            Printf.printf "    PUSHN 1\n    ALLOC %d\n" (getClassSize name); genStaticCall (name ^ "__constructor") [] false;
            Printf.printf "    STOREG %d\n" !globalClassId;
        end else begin (* create VTable *)
            genVtable (fillVtable name ext inner) ext;
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
    match cl with (o,n,a,p,c,i) ->
        globalClassName := n;
        genConstructor n a c p;
        let objId = if o then !globalClassId else -1 in
        List.iter (fun field -> match field with (auto, fieldname, _) -> if auto then genGetter n fieldname objId else ()) (fst i);
        List.iter (fun m -> genMethod m (not o)) (snd i);
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
