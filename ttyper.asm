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
hello_text_size = $-hello_text

; Terminal size
termx dw 0
termy dw 0

macro _print_text x*, y*, text* {
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
    ; Get terminal size
    mov bx, word [rax+4] ; y
    mov cx, word [rax+6] ; x
    mov [termy], bx
    mov [termx], cx
  call noecho


  ; Print text
  mov rsi, hello_text_size
  call _get_center_position
  _print_text rdi, rsi, hello_text

  _while_loop:
    call getch
    cmp ax, 'q'
    jne _while_loop
  call endwin

  mov rax, 60 ; exit
  mov rdi, 0  ; error_code
  syscall

;
; Input:
;  rsi - text len
; Output:
;  rsi - x
;  rdi - y
;
_get_center_position:
  push rbx
  ; xor rdi, rdi
  ; xor rbx, rbx

  ; Set y = termx / 2
  movsx rdi, word [termy]
  shr rdi, 1

  ; Set x = (termy - text_len)/2
  movsx rbx, word [termx]
  sub rbx, rsi
  shr rbx, 1
  mov rsi, rbx

  pop rbx
ret