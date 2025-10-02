; Задание 15: заменить все вхождения "111" на "000" в битовой строке FS:DI длиной ECX бит.
; По аналогии с findBits: используем BT/BTR над памятью с FS-override.

code segment
assume cs:code
public replace111
.386

replace111 proc
; Вход:
;   FS:DI — адрес начала битовой строки
;   ECX   — длина строки в битах (используется CX)
; Выход:
;   В памяти по FS:DI все вхождения "111" заменены на "000"

    xor     esi, esi          ; si = текущий индекс бита (i = 0)
    mov     eax, ecx          ; ax = длина в битах
    sub     eax, 2           ; последний допустимый i: i < len - 2

scan_next:
    cmp     si, ax
    jae     done            ; i >= len-2 => конец

    mov     bx, si          ; bx = i (сохраняем старт индекса тройки)

    ; Проверка бита i
    bt      fs:[di], bx
    jnc     advance         ; если бит i == 0, перейти к следующему i

    ; Проверка бита i+1
    inc     bx
    bt      fs:[di], bx
    jnc     advance         ; если бит i+1 == 0, перейти к следующему i

    ; Проверка бита i+2
    inc     bx
    bt      fs:[di], bx
    jnc     advance         ; если бит i+2 == 0, перейти к следующему i

    ; Нашли "111" по индексам i, i+1, i+2 — обнуляем их
    mov     bx, si
    btr     fs:[di], bx     ; bit i = 0
    inc     bx
    btr     fs:[di], bx     ; bit i+1 = 0
    inc     bx
    btr     fs:[di], bx     ; bit i+2 = 0

advance:
    inc     si
    jmp     scan_next

done:
    ret
replace111 endp

code ends
end
