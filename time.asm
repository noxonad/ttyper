format ELF64
public _start

extrn time
extrn printf

section '.data' writable
sprint db "The elapsed time is %d seconds", 0xA, 0x0
time_begin dq 0

section '.text' executable
_start:

    ; mov rdi, '%ld\n'
    ; movzx rsi, word [time_begin]
    ; call printf

    xor rdi, rdi
    call time
    mov [time_begin], rax

    xor rdi, rdi
    call time

    sub rax, [time_begin]

    mov rdi, sprint
    mov rsi, rax
    ; xor eax, eax
    call printf

    mov rdi, 0  ; error_code
    mov rax, 60 ; exit
    syscall