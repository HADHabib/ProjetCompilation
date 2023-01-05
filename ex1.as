    START
    PUSHN 1
    ALLOC 2
    PUSHA CptPoint__constructor
    CALL
    STOREG 0
    PUSHN 1
    ALLOC 10
    DUPN 1
    PUSHA Point_x
    STORE 0
    DUPN 1
    PUSHA Point_y
    STORE 1
    DUPN 1
    PUSHA Point_name
    STORE 2
    DUPN 1
    PUSHA Point_setName
    STORE 3
    DUPN 1
    PUSHA Point_isCloned
    STORE 4
    DUPN 1
    PUSHA Point_move
    STORE 5
    DUPN 1
    PUSHA Point_print
    STORE 6
    DUPN 1
    PUSHA Point_clone
    STORE 7
    DUPN 1
    PUSHA Point_allClones
    STORE 8
    DUPN 1
    PUSHA Point_egal
    STORE 9
    STOREG 1
    PUSHN 1
    ALLOC 2
    DUPN 1
    PUSHA Couleur_name
    STORE 0
    DUPN 1
    PUSHA Couleur_estGris
    STORE 1
    STOREG 2
    PUSHN 1
    ALLOC 4
    PUSHA CouleurFactory__constructor
    CALL
    STOREG 3
    PUSHN 1
    ALLOC 5
    DUPN 1
    PUSHA PointColore_couleur
    STORE 0
    DUPN 1
    PUSHA PointColore_colore
    STORE 1
    DUPN 1
    PUSHA PointColore_clone
    STORE 2
    DUPN 1
    PUSHA PointColore_estGris
    STORE 3
    DUPN 1
    PUSHA PointColore_print
    STORE 4
    STOREG 4
    PUSHN 1
    ALLOC 3
    DUPN 1
    PUSHA PointNoir_estGris
    STORE 0
    DUPN 1
    PUSHA PointNoir_colore
    STORE 1
    DUPN 1
    PUSHA PointNoir_couleur
    STORE 2
    STOREG 5
    PUSHN 1
    ALLOC 2
    DUPN 1
    PUSHA DefaultPoint_estGris
    STORE 0
    DUPN 1
    PUSHA DefaultPoint_couleur
    STORE 1
    STOREG 6
    PUSHN 1
    ALLOC 1
    PUSHA Test__constructor
    CALL
    STOREG 7
    JUMP start

Integer_toString: PUSHL -1
    STR
    STOREL -2
    RETURN

String_print: PUSHL -1
    WRITES
    RETURN

String_println: PUSHL -1
    PUSHS "\n"
    CONCAT
    WRITES
    RETURN

CptPoint__constructor: NOP
    PUSHL -1 -- ptr
    PUSHG 0 -- Vtable_CptPoint
    STORE 0
    PUSHI 0
    PUSHL -1 -- this
    SWAP
    STORE 1 -- next
    RETURN

CptPoint_get: NOP
    PUSHG 0 -- this
    LOAD 1 -- next
    STOREL -1 -- result
    RETURN

CptPoint_incr: NOP
    PUSHG 0 -- this
    LOAD 1 -- next
    PUSHI 1
    ADD
    PUSHG 0 -- this
    SWAP
    STORE 1 -- next
    PUSHG 0 -- this
    LOAD 1 -- next
    STOREL -1 -- result
    RETURN

Point__constructor: NOP
    PUSHL -3 -- ptr
    PUSHG 1 -- Vtable_Point
    STORE 0
    PUSHL -2 -- xc
    PUSHL -3 -- this
    SWAP
    STORE 1 -- x
    PUSHL -1 -- yc
    PUSHL -3 -- this
    SWAP
    STORE 2 -- y
    PUSHN 1 -- alloc return value
    PUSHA CptPoint_incr
    CALL
    PUSHL -3 -- this
    SWAP
    STORE 5 -- index
    PUSHN 1 -- alloc return value
    PUSHS "Point_"
    PUSHN 1 -- alloc return value
    PUSHL -3 -- this
    LOAD 5 -- index
    PUSHA Integer_toString
    CALL
    POPN 1 -- cleanup args
    CONCAT
    PUSHL -3 -- this
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 3 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHI 0
    PUSHL -3 -- this
    SWAP
    STORE 3 -- hasClone
    RETURN

Point_x: PUSHL -1
    LOAD 1
    STOREL -2
    RETURN

Point_y: PUSHL -1
    LOAD 2
    STOREL -2
    RETURN

Point_name: PUSHL -1
    LOAD 4
    STOREL -2
    RETURN

Point_setName: NOP
    PUSHL -2 -- newName
    PUSHL -1 -- this
    SWAP
    STORE 4 -- name
    RETURN

Point_isCloned: NOP
    PUSHL -1 -- this
    LOAD 3 -- hasClone
    PUSHI 0
    EQUAL
    NOT
    STOREL -1 -- result
    RETURN

Point_move: NOP
    PUSHL -1 -- this
    LOAD 1 -- x
    PUSHL -4 -- dx
    ADD
    PUSHL -1 -- this
    SWAP
    STORE 1 -- x
    PUSHN 1 -- alloc return value
    PUSHL -1 -- this
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 1 -- Method
    CALL
    POPN 1 -- cleanup args
    PUSHL -3 -- dy
    ADD
    PUSHL -1 -- this
    SWAP
    STORE 2 -- y
    PUSHL -2 -- verbose
    JZ lbl__1__else1
    PUSHN 1 -- alloc return value
    PUSHL -2 -- verbose
    PUSHL -1 -- this
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    JUMP lbl__2__endif2
lbl__1__else1: NOP
lbl__2__endif2: NOP
    PUSHL -1 -- this
    STOREL -4 -- result
    RETURN

Point_print: NOP
    PUSHL -2 -- verbose
    JZ lbl__3__else3
    PUSHN 1 -- alloc return value
    PUSHS "Inside Point::print"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    JUMP lbl__4__endif4
lbl__3__else3: NOP
lbl__4__endif4: NOP
    PUSHN 1 -- alloc return value
    PUSHL -1 -- this
    LOAD 4 -- name
    PUSHA String_print
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS "= ("
    PUSHN 1 -- alloc return value
    PUSHL -1 -- this
    LOAD 1 -- x
    PUSHA Integer_toString
    CALL
    POPN 1 -- cleanup args
    CONCAT
    PUSHS ", "
    CONCAT
    PUSHN 1 -- alloc return value
    PUSHL -1 -- this
    LOAD 2 -- y
    PUSHA Integer_toString
    CALL
    POPN 1 -- cleanup args
    CONCAT
    PUSHS ")"
    CONCAT
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    RETURN

Point_clone: NOP
    PUSHI 1
    PUSHL -1 -- this
    SWAP
    STORE 3 -- hasClone
    ALLOC 7
    PUSHL -1 -- this
    LOAD 1 -- x
    PUSHL -1 -- this
    LOAD 2 -- y
    PUSHA Point__constructor
    CALL
    POPN 2 -- cleanup args
    PUSHL -1 -- this
    SWAP
    STORE 6 -- clone
    PUSHN 1 -- alloc return value
    PUSHL -1 -- this
    LOAD 4 -- name
    PUSHS "'"
    CONCAT
    PUSHL -1 -- this
    LOAD 6 -- clone
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 3 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHL -1 -- this
    LOAD 6 -- clone
    STOREL -1 -- result
    RETURN

Point_allClones: NOP
    PUSHL -1 -- this
    LOAD 3 -- hasClone
    PUSHI 0
    EQUAL
    NOT
    JZ lbl__5__else5
    PUSHN 1 -- alloc return value
    PUSHI 1
    PUSHL -1 -- this
    LOAD 6 -- clone
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL -1 -- this
    LOAD 6 -- clone
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 8 -- Method
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    JUMP lbl__6__endif6
lbl__5__else5: NOP
lbl__6__endif6: NOP
    RETURN

Point_egal: NOP
    PUSHN 2 -- Alloc space for local vars
    PUSHN 1 -- alloc return value
    PUSHL -2 -- p
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 0 -- Method
    CALL
    POPN 1 -- cleanup args
    PUSHN 1 -- alloc return value
    PUSHL -1 -- this
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 0 -- Method
    CALL
    POPN 1 -- cleanup args
    SUB
    STOREL 0 -- b1
    PUSHN 1 -- alloc return value
    PUSHL -2 -- p
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 1 -- Method
    CALL
    POPN 1 -- cleanup args
    PUSHL -1 -- this
    LOAD 2 -- y
    SUB
    STOREL 1 -- b2
    PUSHI 0
    STOREL -2 -- result
    PUSHL 0 -- b1
    JZ lbl__7__else7
    JUMP lbl__8__endif8
lbl__7__else7: NOP
    PUSHL 1 -- b2
    PUSHI 0
    EQUAL
    STOREL -2 -- result
lbl__8__endif8: NOP
    POPN 2 -- De-alloc space for local vars
    RETURN

Couleur__constructor: NOP
    PUSHL -2 -- ptr
    PUSHG 2 -- Vtable_Couleur
    STORE 0
    PUSHL -1 -- c
    PUSHI 0
    INF
    JZ lbl__9__else9
    PUSHI 0
    PUSHL -2 -- this
    SWAP
    STORE 1 -- coul
    JUMP lbl__10__endif10
lbl__9__else9: NOP
    PUSHL -1 -- c
    PUSHI 2
    SUP
    JZ lbl__11__else11
    PUSHI 2
    PUSHL -2 -- this
    SWAP
    STORE 1 -- coul
    JUMP lbl__12__endif12
lbl__11__else11: NOP
    PUSHL -1 -- c
    PUSHL -2 -- this
    SWAP
    STORE 1 -- coul
lbl__12__endif12: NOP
lbl__10__endif10: NOP
    RETURN

Couleur_name: NOP
    PUSHN 1 -- Alloc space for local vars
    PUSHL -2 -- verbose
    JZ lbl__13__else13
    PUSHN 1 -- alloc return value
    PUSHS "Inside Couleur::couleur"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    JUMP lbl__14__endif14
lbl__13__else13: NOP
lbl__14__endif14: NOP
    PUSHL -1 -- this
    LOAD 1 -- coul
    PUSHI 0
    EQUAL
    JZ lbl__15__else15
    PUSHS "Blanc"
    STOREL -2 -- result
    JUMP lbl__16__endif16
lbl__15__else15: NOP
    PUSHN 1 -- Alloc space for local vars
    PUSHS "Noir"
    STOREL 1 -- dummy
    PUSHS "Gris"
    STOREL 0 -- aux
    PUSHL -1 -- this
    LOAD 1 -- coul
    PUSHI 1
    EQUAL
    JZ lbl__17__else17
    PUSHL 1 -- dummy
    STOREL 0 -- aux
    JUMP lbl__18__endif18
lbl__17__else17: NOP
lbl__18__endif18: NOP
    PUSHL 0 -- aux
    STOREL -2 -- result
    POPN 1 -- De-alloc space for local vars
lbl__16__endif16: NOP
    POPN 1 -- De-alloc space for local vars
    RETURN

Couleur_estGris: NOP
    PUSHN 1 -- alloc return value
    PUSHS "Inside Couleur::estGris"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHL -1 -- this
    LOAD 1 -- coul
    PUSHI 2
    EQUAL
    STOREL -1 -- result
    RETURN

CouleurFactory__constructor: NOP
    PUSHL -1 -- ptr
    PUSHG 3 -- Vtable_CouleurFactory
    STORE 0
    ALLOC 2
    PUSHI 0
    PUSHA Couleur__constructor
    CALL
    POPN 1 -- cleanup args
    PUSHL -1 -- this
    SWAP
    STORE 1 -- blanc
    ALLOC 2
    PUSHI 1
    PUSHA Couleur__constructor
    CALL
    POPN 1 -- cleanup args
    PUSHL -1 -- this
    SWAP
    STORE 2 -- noir
    ALLOC 2
    PUSHI 2
    PUSHA Couleur__constructor
    CALL
    POPN 1 -- cleanup args
    PUSHL -1 -- this
    SWAP
    STORE 3 -- gris
    RETURN

CouleurFactory_blanc: PUSHL -1
    LOAD 1
    STOREL -2
    RETURN

CouleurFactory_noir: PUSHL -1
    LOAD 2
    STOREL -2
    RETURN

CouleurFactory_gris: PUSHL -1
    LOAD 3
    STOREL -2
    RETURN

PointColore__constructor: NOP
    PUSHL -4 -- ptr
    PUSHL -1 -- xc
    PUSHL -2 -- yc
    PUSHA Point__constructor
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- remove ptr
    PUSHL -4 -- ptr
    PUSHG 4 -- Vtable_PointColore
    STORE 0
    PUSHL -1 -- c
    PUSHL -4 -- this
    SWAP
    STORE 7 -- couleur
    PUSHN 1 -- alloc return value
    PUSHS "PC_"
    PUSHN 1 -- alloc return value
    PUSHL -4 -- this
    LOAD 5 -- index
    PUSHA Integer_toString
    CALL
    POPN 1 -- cleanup args
    CONCAT
    PUSHL -4 -- this
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 3 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    RETURN

PointColore_couleur: PUSHL -1
    LOAD 1
    STOREL -2
    RETURN

PointColore_colore: NOP
    PUSHN 1 -- alloc return value
    PUSHL -1 -- this
    LOAD 7 -- couleur
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 1 -- Method
    CALL
    POPN 1 -- cleanup args
    PUSHI 0
    EQUAL
    NOT
    STOREL -1 -- result
    RETURN

PointColore_clone: NOP
    ALLOC 2
    PUSHL -1 -- this
    LOAD 1 -- x
    PUSHL -1 -- this
    LOAD 2 -- y
    PUSHL -1 -- this
    LOAD 7 -- couleur
    PUSHA PointColore__constructor
    CALL
    POPN 3 -- cleanup args
    STOREL -1 -- result
    RETURN

PointColore_estGris: NOP
    PUSHN 1 -- alloc return value
    PUSHL -1 -- this
    LOAD 7 -- couleur
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 1 -- Method
    CALL
    POPN 1 -- cleanup args
    STOREL -1 -- result
    RETURN

PointColore_print: NOP
    PUSHL -2 -- verbose
    JZ lbl__19__else19
    PUSHN 1 -- alloc return value
    PUSHS "Inside PointColore::print"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    JUMP lbl__20__endif20
lbl__19__else19: NOP
lbl__20__endif20: NOP
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHI 1
    PUSHN 1 -- alloc return value
    PUSHL -1 -- this
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 10 -- Method
    CALL
    POPN 1 -- cleanup args
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 0 -- Method
    CALL
    POPN 2 -- cleanup args
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    RETURN

PointNoir__constructor: NOP
    PUSHL -3 -- ptr
    PUSHL -1 -- xc
    PUSHL -2 -- yc
    PUSHN 1 -- alloc return value
    PUSHA CouleurFactory_noir
    CALL
    PUSHA PointColore__constructor
    CALL
    POPN 3 -- cleanup args
    POPN 1 -- remove ptr
    PUSHL -3 -- ptr
    PUSHG 5 -- Vtable_PointNoir
    STORE 0
    RETURN

PointNoir_estGris: NOP
    PUSHI 0
    STOREL -1 -- result
    RETURN

PointNoir_colore: NOP
    PUSHI 1
    STOREL -1 -- result
    RETURN

PointNoir_couleur: NOP
    PUSHN 1 -- alloc return value
    PUSHA CouleurFactory_noir
    CALL
    STOREL -1 -- result
    RETURN

DefaultPoint__constructor: NOP
    PUSHL -1 -- ptr
    PUSHI 0
    PUSHI 0
    PUSHN 1 -- alloc return value
    PUSHA CouleurFactory_blanc
    CALL
    PUSHA PointColore__constructor
    CALL
    POPN 3 -- cleanup args
    POPN 1 -- remove ptr
    PUSHL -1 -- ptr
    PUSHG 6 -- Vtable_DefaultPoint
    STORE 0
    RETURN

DefaultPoint_estGris: NOP
    PUSHI 0
    STOREL -1 -- result
    RETURN

DefaultPoint_couleur: NOP
    PUSHN 1 -- alloc return value
    PUSHA CouleurFactory_blanc
    CALL
    STOREL -1 -- result
    RETURN

Test__constructor: NOP
    PUSHL -1 -- ptr
    PUSHG 7 -- Vtable_Test
    STORE 0
    RETURN

Test_test: NOP
    PUSHN 4 -- Alloc space for local vars
    PUSHI 1
    STOREL 3 -- true
    PUSHN 1 -- alloc return value
    PUSHL 3 -- true
    PUSHL -3 -- p
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 3 -- true
    PUSHL -2 -- p2
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS "Appel 1: "
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL -2 -- p2
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 11 -- Method
    CALL
    POPN 1 -- cleanup args
    PUSHI 0
    EQUAL
    NOT
    JZ lbl__21__else21
    PUSHS "colore"
    STOREL 0 -- c
    JUMP lbl__22__endif22
lbl__21__else21: NOP
    PUSHS "gris"
    STOREL 0 -- c
lbl__22__endif22: NOP
    PUSHN 1 -- alloc return value
    PUSHS "Appel 2: "
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL -1 -- p3
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 11 -- Method
    CALL
    POPN 1 -- cleanup args
    PUSHI 0
    EQUAL
    NOT
    JZ lbl__23__else23
    PUSHS "colore"
    STOREL 1 -- c2
    JUMP lbl__24__endif24
lbl__23__else23: NOP
    PUSHS "gris"
    STOREL 1 -- c2
lbl__24__endif24: NOP
    PUSHN 1 -- alloc return value
    PUSHS "Appel 3: "
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL -1 -- p3
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 11 -- Method
    CALL
    POPN 1 -- cleanup args
    PUSHI 0
    EQUAL
    NOT
    JZ lbl__25__else25
    PUSHS "colore"
    STOREL 2 -- c3
    JUMP lbl__26__endif26
lbl__25__else25: NOP
    PUSHS "gris"
    STOREL 2 -- c3
lbl__26__endif26: NOP
    PUSHN 1 -- alloc return value
    PUSHS "Resultats de test: "
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 0 -- c
    PUSHA String_print
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS " "
    PUSHA String_print
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 1 -- c2
    PUSHA String_print
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS " "
    PUSHA String_print
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 2 -- c3
    PUSHA String_print
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS ""
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    POPN 4 -- De-alloc space for local vars
    RETURN

Test_test2: NOP
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHI 1
    PUSHN 1 -- alloc return value
    PUSHL -1 -- p
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 10 -- Method
    CALL
    POPN 1 -- cleanup args
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 0 -- Method
    CALL
    POPN 2 -- cleanup args
    PUSHA String_print
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    RETURN

start: NOP
    PUSHN 11 -- Alloc space for local vars
    PUSHN 1 -- alloc return value
    PUSHS "Debut du programme"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHI 1
    STOREL 13 -- true
    PUSHI 0
    STOREL 14 -- false
    ALLOC 7
    PUSHI 1
    PUSHI 5
    PUSHA Point__constructor
    CALL
    POPN 2 -- cleanup args
    STOREL 8 -- p1
    ALLOC 7
    PUSHI 2
    PUSHI 3
    PUSHA Point__constructor
    CALL
    POPN 2 -- cleanup args
    STOREL 9 -- p2
    ALLOC 7
    PUSHI 0
    PUSHI 0
    PUSHA Point__constructor
    CALL
    POPN 2 -- cleanup args
    STOREL 10 -- p3
    PUSHI 12
    STOREL 15 -- fv
    ALLOC 2
    PUSHI 0
    PUSHI 0
    PUSHN 1 -- alloc return value
    PUSHA CouleurFactory_blanc
    CALL
    PUSHA PointColore__constructor
    CALL
    POPN 3 -- cleanup args
    STOREL 16 -- o
    ALLOC 1
    PUSHI 1
    PUSHI 1
    PUSHI -1
    MUL
    PUSHA PointNoir__constructor
    CALL
    POPN 2 -- cleanup args
    STOREL 17 -- pn
    ALLOC 1
    PUSHA DefaultPoint__constructor
    CALL
    STOREL 18 -- dp
    PUSHN 1 -- alloc return value
    PUSHI 0
    PUSHL 8 -- p1
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHI 0
    PUSHL 9 -- p2
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHL 8 -- p1
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 0 -- Method
    CALL
    POPN 1 -- cleanup args
    PUSHN 1 -- alloc return value
    PUSHL 8 -- p1
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 1 -- Method
    CALL
    POPN 1 -- cleanup args
    PUSHI 0
    PUSHL 9 -- p2
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 5 -- Method
    CALL
    POPN 4 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHI 0
    PUSHL 9 -- p2
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHI 0
    PUSHL 16 -- o
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS "origine"
    PUSHL 16 -- o
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 3 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 13 -- true
    PUSHL 16 -- o
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHL 8 -- p1
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 0 -- Method
    CALL
    POPN 1 -- cleanup args
    PUSHI 2
    PUSHI 5
    MUL
    SUB
    PUSHI 3
    SUB
    PUSHN 1 -- alloc return value
    PUSHL 8 -- p1
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 1 -- Method
    CALL
    POPN 1 -- cleanup args
    PUSHI 0
    PUSHL 9 -- p2
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 5 -- Method
    CALL
    POPN 4 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 13 -- true
    PUSHL 9 -- p2
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS "On va essayer le clonage:"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 8 -- p1
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 7 -- Method
    CALL
    POPN 1 -- cleanup args
    STOREL 11 -- clone1
    PUSHN 1 -- alloc return value
    PUSHL 14 -- false
    PUSHL 11 -- clone1
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS "p1 isCloned: "
    PUSHA String_print
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 8 -- p1
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 4 -- Method
    CALL
    POPN 1 -- cleanup args
    JZ lbl__27__else27
    PUSHN 1 -- alloc return value
    PUSHS "OK"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    JUMP lbl__28__endif28
lbl__27__else27: NOP
    PUSHN 1 -- alloc return value
    PUSHS "KO"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
lbl__28__endif28: NOP
    PUSHN 1 -- alloc return value
    PUSHL 11 -- clone1
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 7 -- Method
    CALL
    POPN 1 -- cleanup args
    STOREL 12 -- clone2
    PUSHN 1 -- alloc return value
    PUSHL 14 -- false
    PUSHN 1 -- alloc return value
    PUSHI 54
    PUSHI 36
    PUSHI 0
    PUSHL 12 -- clone2
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 5 -- Method
    CALL
    POPN 4 -- cleanup args
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS "Impression de tous les clones de p1:"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 8 -- p1
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 8 -- Method
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS "Fin de l'impression de tous les clones"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS "Valeur du compteur de nombre de points: "
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHA CptPoint_get
    CALL
    PUSHA Integer_toString
    CALL
    POPN 1 -- cleanup args
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHI 2
    PUSHI 3
    PUSHI -1
    MUL
    PUSHI 0
    PUSHN 1 -- alloc return value
    PUSHL 8 -- p1
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 7 -- Method
    CALL
    POPN 1 -- cleanup args
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 5 -- Method
    CALL
    POPN 4 -- cleanup args
    STOREL 8 -- p1
    PUSHN 1 -- alloc return value
    PUSHL 13 -- true
    PUSHL 8 -- p1
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 13 -- true
    PUSHN 1 -- alloc return value
    PUSHL 16 -- o
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 7 -- Method
    CALL
    POPN 1 -- cleanup args
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 6 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS "test(Point, PointColore, PointNoir)"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 8 -- p1
    PUSHL 16 -- o
    PUSHL 17 -- pn
    PUSHA Test_test
    CALL
    POPN 3 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS "test(PointNoir, PointNoir, PointNoir)"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 17 -- pn
    PUSHL 17 -- pn
    PUSHL 17 -- pn
    PUSHA Test_test
    CALL
    POPN 3 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHL 17 -- pn
    STOREL 8 -- p1
    PUSHN 1 -- alloc return value
    PUSHL 16 -- o
    PUSHA Test_test2
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 17 -- pn
    PUSHA Test_test2
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHL 17 -- pn
    STOREL 16 -- o
    PUSHN 1 -- alloc return value
    PUSHS "test(PointNoir, PointNoir, PointNoir)"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 8 -- p1
    PUSHL 16 -- o
    PUSHL 17 -- pn
    PUSHA Test_test
    CALL
    POPN 3 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 16 -- o
    PUSHA Test_test2
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHL 17 -- pn
    PUSHA Test_test2
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS "\nDone"
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    POPN 11 -- De-alloc space for local vars
    STOP
