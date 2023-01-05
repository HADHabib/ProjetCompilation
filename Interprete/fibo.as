    START
    PUSHN 1
    ALLOC 1
    PUSHA Fibo__constructor
    CALL
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

Fibo__constructor: NOP
    PUSHL -1 -- ptr
    PUSHG 0 -- Vtable_Fibo
    STORE 0
    RETURN

Fibo_run: NOP
    PUSHL -1 -- i
    PUSHI 1
    INFEQ
    JZ lbl__1__else1
    PUSHI 1
    STOREL -2 -- result
    JUMP lbl__2__endif2
lbl__1__else1: NOP
    PUSHN 1 -- alloc return value
    PUSHL -1 -- i
    PUSHI 1
    SUB
    PUSHA Fibo_run
    CALL
    POPN 1 -- cleanup args
    PUSHN 1 -- alloc return value
    PUSHL -1 -- i
    PUSHI 2
    SUB
    PUSHA Fibo_run
    CALL
    POPN 1 -- cleanup args
    ADD
    STOREL -2 -- result
lbl__2__endif2: NOP
    RETURN

start: NOP
    PUSHN 1 -- alloc return value
    PUSHS "Fibo(10) : "
    PUSHA String_print
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHI 10
    PUSHA Fibo_run
    CALL
    POPN 1 -- cleanup args
    PUSHA Integer_toString
    CALL
    POPN 1 -- cleanup args
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS "Fibo(15) : "
    PUSHA String_print
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHI 15
    PUSHA Fibo_run
    CALL
    POPN 1 -- cleanup args
    PUSHA Integer_toString
    CALL
    POPN 1 -- cleanup args
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHS "Fibo(20) : "
    PUSHA String_print
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHN 1 -- alloc return value
    PUSHI 20
    PUSHA Fibo_run
    CALL
    POPN 1 -- cleanup args
    PUSHA Integer_toString
    CALL
    POPN 1 -- cleanup args
    PUSHA String_println
    CALL
    POPN 1 -- cleanup args
    POPN 1 -- cleanup stack
    STOP
