INTERFACES = tpParse.mli
SOURCES    = ast.ml tpParse.ml tpLex.ml misc.ml context.ml codegen.ml main.ml
GENERATED  = tpLex.ml tpParse.ml tpParse.mli tpParse.automaton tpParse.conflicts

tp: tpParse.mli $(SOURCES)
	ocamlc -g -c ast.ml
	ocamlc -g $(INTERFACES)
	ocamlc -g -o tp $(SOURCES)

ast.mli: ast.ml
	ocamlc -g -c ast.ml

tpLex.ml: tpLex.mll tpParse.mli ast.ml
	ocamllex tpLex.mll

tpParse.mli : tpParse.mly ast.mli
	menhir --dump --explain --infer tpParse.mly

clean:
	rm -rf tp *.o *.cmi *.cmo *.cmx *~ $(GENERATED) out.txt
