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

; SYS_CALLS
define SYS_EXIT           0x3C
define SYS_TIME           0xC9 

; Keys
define KEY_ENTER          0x0A
define KEY_ESC            0x1B
define KEY_SPACE          0x20
define KEY_DEL            0x7E
define KEY_BACKSPACE      0x7F

; Default colors
define COLOR_DEFAULT      0xFFFF
define COLOR_BLACK        0x00
define COLOR_RED          0x01
define COLOR_GREEN        0x02

; Color index
define CORRECT_COLOR      0x01
define WRONG_COLOR        0x02
define SPACE_WRONG_COLOR  0x03



;
; Data
;
section '.data' writable
ctype   db '%c', 0
stype   db '%s', 0
lutype  db '%lu', 0
restype db 'Time: %lus - %lu mistakes - %.2f cpm / %.2f wpm - Accuracity: %.2f%%', 0
default_text db 'A large rose-tree stood near the entrance of the garden: the roses growing on it were white, but there were three gardeners at it, busily painting them red.', 0 ; Text the user has to type
default_text_size = $-default_text ; Text length

user_mistakes dd 0 ; Number of total mistyped letters
user_input dd 0 ; The key that user has pressed
user_char_writen dw 0 ; Count of user written characters (considered per line)
user_time_start_typing dq 0 ; When the user started typing the first character

; Terminal size
termx dw 0
termy dw 0



;
; Macros
;
macro INIT_NCURSES {
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
  INIT_PAIR SPACE_WRONG_COLOR, COLOR_RED, COLOR_DEFAULT
}

macro CLOSE_NCURSES {
  call endwin
}

macro INIT_PAIR pair*, fg*, bg* {
  mov rdi, pair
  mov rsi, bg
  mov rdx, fg
  call init_pair
}

macro PRINT_CHAR chr {
  mov rdi, ctype
  mov esi, chr
  call printw
}

macro COLOR_PAIR pair* {
  shl pair, 8
}

macro COLOR_ON pair* {
  mov rdi, [stdscr]
  mov rsi, pair
  shl rsi, 8
  xor rdx, rdx
  call wattr_on
}

macro COLOR_OFF pair* {
  mov rdi, [stdscr]
  mov rsi, pair
  shl rsi, 8

  xor rdx, rdx
  call wattr_off
}

macro PRINT_TEXT_AT y*, x*, text* {
  mov rdi, y
  mov rsi, x
  mov rdx, stype
  mov rcx, text
  call mvprintw
}

macro PRINT_CENTERED_TEXT text* {
  mov rdi, default_text_size ; get the center position of the text
  mov rsi, text
  call _get_center_position
  mov rdx, stype
  mov rcx, default_text
  call mvprintw
  ; PRINT_TEXT_AT rdi, rsi, default_text ; print the text
}

macro MOVE_CURSOR_TEXT_BEGIN {
  mov rdi, default_text_size
  call _get_center_position
  call move
}

macro MOVE_CURSOR_TEXT_USER_CURRENT {
  mov rdi, default_text_size
  call _get_center_position
  add si, [user_char_writen]
  call move
}



;
; Code
;
section '.text' executable
_start:
  INIT_NCURSES

  ; Print the text and move the cursor to the beginning
  PRINT_CENTERED_TEXT default_text
  MOVE_CURSOR_TEXT_BEGIN
  
  ; Handle user input
  _while_loop:
    ; Test for the end of a string
    xor rax, rax
    mov ax, [user_char_writen]
    mov rbx, default_text_size
    dec rbx ; remove the null terminator
    cmp eax, ebx
    jge _text_typed

    ; Get time when the user starts typing
    call getch
    mov [user_input], eax

    cmp [user_char_writen], 0
    jne _pass
      call _set_time_start
    _pass:

    ; If ESC, exit
    cmp [user_input], KEY_ESC
    je _exit

    ; Remove a character at backspace
    cmp [user_input], KEY_BACKSPACE
    jne _backspace_pass
      ; Don't decrement if below 0
      cmp [user_char_writen], 0
      jle _user_len_neg_pass
        dec [user_char_writen]

      _user_len_neg_pass:

      ; Move the cursor at the correct position
      MOVE_CURSOR_TEXT_USER_CURRENT

      ; Print back the character from the text
      lea rsi, [default_text]
      movzx rdi, word [user_char_writen]
      call _get_char_at_offset
      ; and rdi, 0xFF
      PRINT_CHAR esi

      ; Move the cursor at the correct position
      MOVE_CURSOR_TEXT_USER_CURRENT
      
      jmp _while_loop

    _backspace_pass:

    ; Check if key is printable
    ; Try again if it's not
    cmp [user_input], KEY_SPACE
    jl _while_loop
    cmp [user_input], KEY_DEL
    jge _while_loop

    ; Print single character
    ; Check if the character is correct or not
    xor eax, eax
    mov eax, [user_input]
    lea rdi, [default_text]
    movzx rsi, word [user_char_writen]
    call _get_char_at_offset
    cmp rsi, rax
    jne _char_typed_wrong

    ; the character is correctly typed
      COLOR_ON CORRECT_COLOR
      PRINT_CHAR [user_input]
      COLOR_OFF CORRECT_COLOR
      jmp _user_input_wrapup

    ; The character is not correctly typed
    _char_typed_wrong:
      inc [user_mistakes]
      cmp rax, KEY_SPACE
      je _wrong_input_space_skip
        COLOR_ON WRONG_COLOR
        PRINT_CHAR [user_input]
        COLOR_OFF WRONG_COLOR
        jmp _user_input_wrapup
      _wrong_input_space_skip:
        COLOR_ON SPACE_WRONG_COLOR
        mov rsi, default_text
        movzx rdi, [user_char_writen]
        call _get_char_at_offset
        PRINT_CHAR esi
        COLOR_OFF SPACE_WRONG_COLOR

    _user_input_wrapup:
      inc [user_char_writen]
      jmp _while_loop

  ; Print the time
  _text_typed:
    ; Get the end time
    xor rdi, rdi
    mov rax, SYS_TIME
    syscall
    ; Calculate the difference
    mov rbx, [user_time_start_typing]
    sub rax, rbx
    
    ; Print the time
    mov di, [termy]           ; y
    xor rsi, rsi              ; x
    mov rdx, restype          ; template 
    mov rcx, rax              ; seconds
    mov r8d, [user_mistakes]  ; mistakes

    ; Calculate the cpm
    cvtsi2sd xmm1, rax
    mov rax, default_text_size
    imul rax, 60              ; size * 60
    cvtsi2sd xmm0, rax        ; size
    divsd xmm0, xmm1          ; cpm = size * 60 / time

    ; Calculate the wpm
    ; wpm = cpm / 5
    movsd xmm1, xmm0
    mov rax, 5                ; 5 characters per word
    cvtsi2sd xmm2, rax
    divsd xmm1, xmm2

    ; Calculate the accuracity percentage
    xor rbx, rbx              ; (size - mistakes) / size * 100
    mov rax, default_text_size
    mov ebx, [user_mistakes]
    sub rax, rbx              ; (size - mistakes)
    imul rax, 100             ; ^^^^^^^^^^^^^^^^^ * 100
    cvtsi2sd xmm2, rax
    mov rax, default_text_size
    cvtsi2sd xmm3, rax
    divsd xmm2, xmm3          ; (mistakes * 100) / size

    mov rax, 3                ; number of xmm args
    
    call mvprintw

    call getch

  _exit:
    CLOSE_NCURSES

    ; Exit successfully
    xor rdi, rdi 
    mov rax, SYS_EXIT
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

_set_time_start:
  push rdi
  push rax

  xor rdi, rdi
  mov rax, SYS_TIME
  syscall
  mov [user_time_start_typing], rax

  pop rax
  pop rdi
  ret