format ELF64
public main

extrn initscr
extrn noecho
extrn endwin
extrn getch
extrn printw
extrn mvprintw
extrn move
extrn refresh

define KEY_ENTER      0x0A
define KEY_ESC        0x1B
define KEY_SPACE      0x20
define KEY_DEL        0x7E
define KEY_BACKSPACE  0x7F

;
; Data
;
section '.data' writable
ctext db '%c', 0
stext db '%s', 0
hello_text db 'Hello, world!', 0
hello_text_size = $-hello_text
user_char_write dd 0 ; How many characters has user written (max 65535)

; Terminal size
termx dw 0
termy dw 0

macro _print_text y*, x*, text* {
  mov rdx, stext
  mov rcx, text
  call mvprintw
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
  mov rdi, hello_text_size ; get the center position of the text
  call _get_center_position
  _print_text rdi, rsi, hello_text ; print the text

  ; Move the cursor to the start of the text
  mov rdi, hello_text_size
  call _get_center_position
  call move


  _while_loop:
    call getch
    ; If ESC, exit
    cmp ax, KEY_ESC
    je _exit

    ; Remove a character at backspace
    cmp ax, KEY_BACKSPACE
    jne _backspace_pass
      dec [user_char_write]
      cmp [user_char_write], 0
      jge _user_len_neg_pass
        inc [user_char_write]
      _user_len_neg_pass:
      mov rdi, hello_text_size
      call _get_center_position
      add esi, [user_char_write]
      call move
      jmp _while_loop

    _backspace_pass:

    ; Check if key is printable
    ; Try again if it's not
    cmp ax, KEY_SPACE
    jl _while_loop
    cmp ax, KEY_DEL
    jge _while_loop

    ; Test for the end of a string
    push rax
    push rbx

    xor rax, rax
    mov eax, [user_char_write]
    mov rbx, hello_text_size
    dec rbx ; remove the null terminator
    cmp eax, ebx
    jge _while_loop

    pop rbx
    pop rax

    ; Todo: abstract into a function/macros
    ; Print single character
    mov edi, ctext
    movsx esi, ax
    call printw
    inc [user_char_write]
    jmp _while_loop
  call getch
  _exit:
  call endwin

  mov rax, 60 ; exit
  mov rdi, 0  ; error_code
  syscall

;
; Input:
;  rdi - text len
; Output:
;  rdi - y
;  rsi - x
;
_get_center_position:
  ; Set x = (termy - text_len)/2
  movsx rsi, word [termx]
  sub rsi, rdi
  shr rsi, 1

  ; Set y = termx / 2
  movsx rdi, word [termy]
  shr rdi, 1
  ret