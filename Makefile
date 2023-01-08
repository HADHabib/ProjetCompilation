INTERFACES = parser.mli
SOURCES    = ast.ml parser.ml lexer.ml misc.ml context.ml codegen.ml main.ml
GENERATED  = lexer.ml parser.ml parser.mli parser.automaton parser.conflicts

compile: parser.mli $(SOURCES)
	ocamlc -g -c ast.ml
	ocamlc -g $(INTERFACES)
	ocamlc -g -o compile $(SOURCES)

ast.mli: ast.ml
	ocamlc -g -c ast.ml

lexer.ml: lexer.mll parser.mli ast.ml
	ocamllex lexer.mll

parser.mli : parser.mly ast.mli
	menhir --dump --explain --infer parser.mly

clean:
	rm -rf compile *.o *.cmi *.cmo *.cmx *~ $(GENERATED) out.txt
