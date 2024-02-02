format ELF64
public _start

extrn initscr
extrn noecho
extrn endwin
extrn getch
extrn printw
extrn mvprintw
extrn move
extrn refresh
extrn use_default_colors
extrn start_color
extrn init_pair
extrn wattr_on
extrn wattr_off
extrn stdscr

; Keys
define KEY_ENTER      0x0A
define KEY_ESC        0x1B
define KEY_SPACE      0x20
define KEY_DEL        0x7E
define KEY_BACKSPACE  0x7F

; Default colors
define COLOR_DEFAULT        0xFFFF
define COLOR_BLACK          0x00
define COLOR_RED            0x01
define COLOR_GREEN          0x02

; Color index
define CORRECT_COLOR  0x01
define WRONG_COLOR    0x02

;
; Data
;
section '.data' writable
; stdscr dq 0
ctext db '%c', 0
stext db '%s', 0
hello_text db 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Tempus egestas sed sed risus.', 0
hello_text_size = $-hello_text
user_char_write dd 0 ; How many characters has user written (max 65535)

; Terminal size
termx dw 0
termy dw 0

macro INIT_PAIR pair*, fg*, bg* {
  mov rdi, pair
  mov rsi, bg
  mov rdx, fg
  call init_pair
}
macro PRINT_CHAR chr {
  mov rdi, ctext
  mov rsi, chr
  call printw
}

macro COLOR_PAIR pair* {
  shl pair, 8
}

macro COLOR_ON pair* {
  push rdi
  push rsi
  push rdx
  push rax

  mov rdi, [stdscr]
  mov rsi, pair
  shl rsi, 8
  xor rdx, rdx
  call wattr_on

  pop rax
  pop rdx
  pop rsi
  pop rdi
}

macro COLOR_OFF pair* {
  push rdi
  push rsi
  push rdx
  push rax

  mov rdi, [stdscr]
  mov rsi, pair
  shl rsi, 8

  xor rdx, rdx
  call wattr_off

  pop rax
  pop rdx
  pop rsi
  pop rdi
}

macro PRINT_TEXT_AT y*, x*, text* {
  mov rdx, stext
  mov rcx, text
  call mvprintw
}

macro PRINT_CENTERED_TEXT text* {
  mov rdi, hello_text_size ; get the center position of the text
  mov rsi, text
  call _get_center_position
  PRINT_TEXT_AT rdi, rsi, hello_text ; print the text
}

macro MOVE_CURSOR_TEXT_BEGIN {
  mov rdi, hello_text_size
  call _get_center_position
  call move
}

macro MOVE_CURSOR_TEXT_USER_CURRENT {
  mov rdi, hello_text_size
  call _get_center_position
  add esi, [user_char_write]
  call move
}

;
; Code
;
section '.text' executable
_start:
  ; Initialize the screen
  call initscr
    ; Get terminal size
    mov bx, word [rax+4] ; y
    mov cx, word [rax+6] ; x
    mov [termy], bx
    mov [termx], cx
  call noecho

  ; Initialize color
  call use_default_colors
  call start_color

  INIT_PAIR CORRECT_COLOR, COLOR_DEFAULT, COLOR_GREEN
  INIT_PAIR WRONG_COLOR, COLOR_DEFAULT, COLOR_RED

  PRINT_CENTERED_TEXT hello_text

  ; Move the cursor to the start of the text
  MOVE_CURSOR_TEXT_BEGIN
  
  _while_loop:
    call getch
    ; If ESC, exit
    cmp ax, KEY_ESC
    je _exit

    ; Remove a character at backspace
    cmp ax, KEY_BACKSPACE
    jne _backspace_pass
      ; Don't decrement if below 0
      cmp [user_char_write], 0
      jle _user_len_neg_pass
        dec [user_char_write]

      _user_len_neg_pass:

      ; Move the cursor at the correct position
      MOVE_CURSOR_TEXT_USER_CURRENT

      ; Print back the character from the text
      lea rsi, [hello_text]
      movzx rdi, word [user_char_write]
      call _get_char_at_offset
      ; and rdi, 0xFF
      PRINT_CHAR rsi

      ; Move the cursor at the correct position
      MOVE_CURSOR_TEXT_USER_CURRENT
      
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

    ; Print single character
    ; Check if the character is correct or not
    lea rdi, [hello_text]
    movzx rsi, word [user_char_write]
    call _get_char_at_offset
    cmp rsi, rax
    jne _char_typed_wrong

    ; the character is correctly typed
      COLOR_ON CORRECT_COLOR
      PRINT_CHAR rax
      COLOR_OFF CORRECT_COLOR
      jmp _user_input_wrapup

    ; The character is not correctly typed
    _char_typed_wrong:
      COLOR_ON WRONG_COLOR
      PRINT_CHAR rax
      COLOR_OFF WRONG_COLOR

    _user_input_wrapup:
    inc [user_char_write]
    jmp _while_loop

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
  movzx rsi, word [termx]
  sub rsi, rdi
  shr rsi, 1

  ; Set y = termx / 2
  movzx rdi, word [termy]
  shr rdi, 1
  ret

;
; Input:
;  rdi - string address
;  rsi - offset
; Output:
;  rsi - character at offset 
;
_get_char_at_offset:
  add rdi, rsi
  movzx rsi, byte [rdi]
  ret
