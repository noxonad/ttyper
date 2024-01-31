format ELF64
public main

extrn initscr
extrn noecho
extrn endwin
extrn getch
extrn mvprintw
extrn move

;
; Data
;
section '.data' writable
stext db '%s', 0xA, 0
hello_text db 'hello world', 0

macro _print_text y*, x*, text* {
  mov rsi, y
  mov rdi, x
  mov rcx, stext
  mov rdx, text
  call mvprintw

  mov rsi, y
  mov rdi, x
  call move
}

;
; Code
;
section '.text' executable
main:
  sub rsp, 8
  
  ; Initialize the screen
  call initscr
  call noecho

  ; Get terminal size
  
  ; Print text
  _print_text 10, 10, hello_text

  _while_loop:
    call getch
    cmp ax, 'q'
    jne _while_loop
  call endwin

  mov rax, 60 ; exit
  mov rdi, 0  ; error_code
  syscall
