    START
    PUSHN 1
    ALLOC 3
    DUPN 1
    PUSHA Point_x
    STORE 0
    DUPN 1
    PUSHA Point_y
    STORE 1
    DUPN 1
    PUSHA Point_print
    STORE 2
    STOREG 0
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

Point__constructor: NOP
    PUSHL -3 -- ptr
    PUSHG 0 -- Vtable_Point
    STORE 0
    PUSHL -2 -- xc
    PUSHL -3 -- this
    SWAP
    STORE 1 -- x
    PUSHL -1 -- yc
    PUSHL -3 -- this
    SWAP
    STORE 2 -- y
    RETURN

Point_x: PUSHL -1
    LOAD 1
    STOREL -2
    RETURN

Point_y: PUSHL -1
    LOAD 2
    STOREL -2
    RETURN

Point_print: NOP
    PUSHN 1 -- alloc return value
    PUSHS "Point {x: "
    PUSHN 1 -- alloc return value
    PUSHL -1 -- this
    LOAD 1 -- x
    PUSHA Integer_toString
    CALL
    POPN 1 -- cleanup args
    CONCAT
    PUSHS ", y: "
    CONCAT
    PUSHN 1 -- alloc return value
    PUSHL -1 -- this
    LOAD 2 -- y
    PUSHA Integer_toString
    CALL
    POPN 1 -- cleanup args
    CONCAT
    PUSHS "}"
    CONCAT
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    RETURN

start: NOP
    PUSHN 1 -- Alloc space for local vars
    ALLOC 3
    PUSHI 1
    PUSHI 2
    PUSHA Point__constructor
    CALL
    POPN 2 -- cleanup args
    STOREL 0 -- x
    PUSHN 1 -- alloc return value
    PUSHL 0 -- x
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 2 -- Method
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    STOP
