format ELF64
public main

extrn initscr
extrn endwin
extrn getch

;
; Data
;
section '.data' writable

;
; Code
;
section '.text' executable
main:
  sub rsp, 8
  call initscr
  _while_loop:
    call getch
    cmp ax, 'q'
    jne _while_loop
  call endwin

  mov rax, 60 ; exit
  mov rdi, 0  ; error_code
  syscall