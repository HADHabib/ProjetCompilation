    START
    PUSHN 1
    ALLOC 5
    DUPN 1
    PUSHA Point_x
    STORE 0
    DUPN 1
    PUSHA Point_y
    STORE 1
    DUPN 1
    PUSHA Point_print
    STORE 2
    DUPN 1
    PUSHA Point_callMethod2
    STORE 3
    DUPN 1
    PUSHA Point_method2
    STORE 4
    STOREG 0
    PUSHN 1
    ALLOC 3
    PUSHA Printer__constructor
    CALL
    STOREG 1
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

Point_callMethod2: NOP
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHL -1 -- this
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 0 -- Method
    CALL
    POPN 1 -- cleanup args
    PUSHL -1 -- this
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 4 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    RETURN

Point_method2: NOP
    PUSHN 1 -- Alloc space for local vars
    ALLOC 3
    PUSHL -2 -- a
    PUSHL -2 -- a
    PUSHA Point__constructor
    CALL
    POPN 2 -- cleanup args
    STOREL 0 -- y
    PUSHN 1 -- alloc return value
    PUSHL 0 -- y
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 2 -- Method
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    POPN 1 -- De-alloc space for local vars
    RETURN

Printer__constructor: NOP
    PUSHL -1 -- ptr
    PUSHG 1 -- Vtable_Printer
    STORE 0
    PUSHS "Hello, World!"
    PUSHL -1 -- this
    SWAP
    STORE 1 -- string
    ALLOC 3
    PUSHI 3
    PUSHI 3
    ADD
    PUSHI 4
    PUSHI 2
    DIV
    PUSHI 8
    ADD
    PUSHA Point__constructor
    CALL
    POPN 2 -- cleanup args
    PUSHL -1 -- this
    SWAP
    STORE 2 -- pt
    RETURN

Printer_print: NOP
    PUSHN 1 -- alloc return value
    PUSHG 1 -- this
    LOAD 1 -- string
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    RETURN

Printer_point: NOP
    PUSHG 1 -- this
    LOAD 2 -- pt
    STOREL -1 -- result
    RETURN

Printer_getPoint: NOP
    PUSHG 1 -- this
    LOAD 2 -- pt
    STOREL -1 -- result
    RETURN

start: NOP
    PUSHN 1 -- Alloc space for local vars
    ALLOC 3
    PUSHI 1
    PUSHI 2
    PUSHA Point__constructor
    CALL
    POPN 2 -- cleanup args
    STOREL 2 -- x
    PUSHN 1 -- alloc return value
    PUSHL 2 -- x
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 2 -- Method
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHA Printer_print
    CALL
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHA Printer_point
    CALL
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 2 -- Method
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHA Printer_getPoint
    CALL
    STOREL 2 -- x
    PUSHN 1 -- alloc return value
    PUSHL 2 -- x
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 3 -- Method
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHI 100
    PUSHL 2 -- x
    DUPN 1 -- this
    LOAD 0 -- VTable
    LOAD 4 -- Method
    CALL
    POPN 2 -- cleanup args
    POPN 1 -- cleanup stack
    POPN 1 -- De-alloc space for local vars
    STOP
