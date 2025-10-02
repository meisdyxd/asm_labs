sseg segment stack 'stack'
    dw 256 dup(?)
sseg ends

data segment
    ; Тестовая строка (байты заданы для наглядности)
    ; Должны обнулиться все тройки 111, включая переходы через границы байт
    arr db 11100111b, 11111000b ; пример данных
    len_bits dw 16               ; длина в битах (2 байта = 16 бит)
data ends

code segment
assume ds:data, cs:code, ss:sseg

extrn replace111: near
.386

_start:
    mov ax, data
    mov ds, ax
    mov fs, ax

    lea di, arr          ; FS:DI -> начало битовой строки
    movzx ecx, len_bits  ; ECX = длина в битах

    call replace111      ; выполнить замену "111" -> "000"

    mov ax, 4c00h
    int 21h

code ends
end _start
