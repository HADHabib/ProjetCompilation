open Ast


let genThisCall m = Printf.printf "    THISCALL?\n"

let rec genGetVal v =
    match v with
    | Id(v) -> (match v.off with | O(i) -> Printf.printf "    LOAD %d\n" i | G(i) -> Printf.printf "    PUSHG %d\n" i | L(i) -> Printf.printf "    PUSHL %d\n" i)
    | Method(m) -> genThisCall m (* or static call if object *)
    | Access(a) -> genExpr a.left; (match a.off with | O(i) -> Printf.printf "    LOAD %d\n" i | G(i) -> Printf.printf "    PUSHG %d\n" i | L(i) -> Printf.printf "    PUSHL %d\n" i)
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
    | Inst(n, a) -> Printf.printf "    ALLOC %d\n" 0 (* size of class including VTable *); genStaticCall (n ^ "__constructor") a
    | Comp(e1, c, e2) -> match c with
    | Eq -> genExpr e1; genExpr e2; Printf.printf "    EQUAL\n"
    | Neq -> genExpr e1; genExpr e2; Printf.printf "    EQUAL\n    NOT\n"
    | Lt -> genExpr e1; genExpr e2; Printf.printf "    INF\n"
    | Le -> genExpr e1; genExpr e2; Printf.printf "    INFEQ\n"
    | Gt -> genExpr e1; genExpr e2; Printf.printf "    SUP\n"
    | Ge -> genExpr e1; genExpr e2; Printf.printf "    SUPEQ\n"
and genStaticCall n args =
    List.iter genExpr args;
    Printf.printf "    PUSHA %s\n    CALL\n    POPN %d\n" n (List.length args)

let genStoreVal v =
    match v with
    | Id(v) -> (match v.off with | O(i) -> Printf.printf "    STORE %d\n" i | G(i) -> Printf.printf "    STOREG %d\n" i | L(i) -> Printf.printf "    STOREL %d\n" i)
    | Access(a) -> genExpr a.left; (match a.off with | O(i) -> Printf.printf "    STORE %d\n" i | G(i) -> Printf.printf "    STOREG %d\n" i | L(i) -> Printf.printf "    STOREL %d\n" i)
    | _ -> ()

let rec genInstr i =
    match i with
    | Expr(e) -> genExpr e; Printf.printf "    POPN 1\n"
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
     | l -> Printf.printf "    PUSHN %d\n" (List.fold_left (fun a v -> a + List.length (fst v)) 0 l)
    );
    List.iter genInstr (snd b)


let genMethod m =
    match m with
    | Calc(_, name, _, _, e) ->
        Printf.printf "%s: NOP\n" name;
        genExpr e;
        Printf.printf "    RETURN\n\n"
    | Body(_, name, _, _, b) ->
        Printf.printf "%s: NOP\n" name;
        genBloc b;
        Printf.printf "    RETURN\n\n"

let genConstructor n b =
    Printf.printf "%s__constructor: NOP\n" n;
    (* Affect VTable *)
    (match b with
     | None -> ()
     | Some bl -> genBloc bl);
    Printf.printf "    RETURN\n\n"

let preGenClass cl = ()

let genStatic prog =
    Printf.printf "    START\n";
    List.iter preGenClass (fst prog);
    Printf.printf "    JUMP start\n\n"
    (* gen code of int_toString, string_print(ln) *)

let genClass cl =
    match cl with (_,n,_,_,c,i) ->
        genConstructor n c;
        List.iter genMethod (snd i)

let genProg prog =
    genStatic prog;
    List.iter genClass (fst prog);
    Printf.printf "start: NOP\n";
    genBloc (snd prog);
    Printf.printf "    STOP\n"
