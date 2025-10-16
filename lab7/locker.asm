PROGRAM segment
    assume CS:PROGRAM
    org 100h                ; пропуск PSP для COM-программы

Start: jmp InitProc         ; переход на инициализацию

; Р Е З И Д Е Н Т Н Ы Е   Д А Н Н Ы Е
FuncNum equ 0EEh             ; несуществующая функция прерывания BIOS Int16h
CodeOut equ 2D0Ch            ; код, возвращаемый нашим обработчиком Int16h
TestInt09 equ 9D0Ah          ; слово перед Int09h
TestInt16 equ 3AFAh          ; слово перед Int16h

OldInt09 label dword         ; сохраненный вектор Int09h:
    OfsInt09 dw ?            ; его смещение
    SegInt09 dw ?            ; и сегмент

OldInt16 label dword         ; сохраненный вектор Int16h:
    OfsInt16 dw ?            ; его смещение
    SegInt16 dw ?            ; и сегмент

OK_Text db 0                 ; признак гашения экрана
Sign db ?                    ; количество нажатий Ctrl

VideoLen equ 800h            ; длина видеобуфера
VideoBuf db 160 dup(' ')
db 13 dup(' ')
db '??????????????????????????????????????????????????????'
db 26 dup(' ')
db '?                                                    ?'
db 26 dup(' ')
db '?  Для разблокировки нажмите три раза LeftControl   ?'
db 26 dup(' ')
db '?                                                    ?'
db 26 dup(' ')
db '?          КЛАВИАТУРА ЗАБЛОКИРОВАНА!                ?'
db 26 dup(' ')
db '??????????????????????????????????????????????????????'
db 2000 dup(' ')

AttrBuf db VideoLen dup(07h) ; атрибуты экрана
VideoBeg dw 0B800h           ; адрес начала видеообласти
VideoOffs dw ?               ; смещение активной страницы
CurSize dw ?                 ; сохраненный размер курсора

; Р Е З И Д Е Н Т Н Ы Е   П Р О Ц Е Д У Р Ы

; ПОДПРОГРАММА ОБМЕНА ВИДЕООБЛАСТИ С БУФЕРОМ ПРОГРАММЫ
VideoXcg proc
    lea DI,VideoBuf          ; в DI - адрес буфера символов
    lea SI,AttrBuf           ; в SI - адрес буфера атрибутов
    mov AX,VideoBeg          ; в ES - сегментный адрес
    mov ES,AX                ; начала видеообласти
    mov CX,VideoLen          ; в CX - длина видеобуфера
    mov BX,VideoOffs         ; в BX - начальное смещение строки
Draw:
    mov AX,ES:[BX]           ; обменять символ/атрибут
    xchg AH,DS:[SI]          ; на экране с символом и атрибутом
    xchg AL,DS:[DI]          ; из буферов
    mov ES:[BX],AX
    inc SI                   ; увеличить адрес в буферах
    inc DI
    inc BX                   ; увеличить адрес в видеобуфере
    inc BX
    loop Draw                ; делать для всей видеообласти
    ret
VideoXcg endp

; ОБРАБОТЧИК ПРЕРЫВАНИЯ Int09h (ПРЕРЫВАНИЕ ОТ КЛАВИАТУРЫ)
    dw TestInt09             ; слово для обнаружения перехвата

Int09Hand proc
    push AX
    push BX
    push CX
    push DI
    push SI
    push DS
    push ES
    push CS                  ; указать DS на нашу программу
    pop DS

    in AL,60h                ; получить скан-код нажатой клавиши
    cmp AL,26h               ; проверить на скан-код клавиши <L>
    jne Exit_09              ; и выйти, если не он
    
    xor AX,AX
    mov ES,AX                ; проверить флаги клавиатуры на
    mov AL,ES:[418h]         ; нажатие <Ctrl+Alt>
    and AL,03h
    cmp AL,03h
    je Cont

Exit_09:
    jmp Exit09               ; выход

Cont:
    sti                      ; разрешить прерывания
    mov AH,0Fh               ; получить текущий видеорежим
    int 10h
    cmp AL,2
    je InText
    cmp AL,3                 ; если режим текстовый 80x25
    je InText
    cmp AL,7
    je InText
    jmp short SwLoop1        ; иначе - пропустить

InText:
    xor AX,AX                ; установить сегментный адрес в 0000h
    mov ES,AX
    mov AX,ES:[44Eh]         ; получить смещение активной страницы
    mov VideoOffs,AX
    
    mov AH,03h               ; сохранить размер курсора
    int 10h
    mov CurSize,CX
    mov AH,01h
    mov CH,20h               ; подавить курсор
    int 10h
    
    mov OK_Text,01h          ; установить признак гашения экрана
    call VideoXcg            ; вызвать процедуру гашения

SwLoop1:
    in AL,60h                ; в AL - код нажатой клавиши
    
    cmp AL,1Dh               ; если нажата LeftCtrl
    je SwLoop2               ; переходим к проверке отпускания
    
    cmp AL,9Dh               ; если отпущена LeftCtrl
    je SwLoop1               ; продолжаем ждать
    
    ; БЛОКИРОВКА ВСЕХ ОСТАЛЬНЫХ КЛАВИШ
    mov Sign,0               ; сбросить кол-во нажатий
    
    ; Обслужить контроллер прерываний (критично!)
    mov AL,20h
    out 20h,AL
    
    jmp short SwLoop1        ; снова на опрос клавиатуры

SwLoop2:
    in AL,60h                ; в AL - скан-код клавиши
    cmp AL,9Dh               ; если не код отпускания Ctrl
    jne SwLoop2              ; ожидать отпускания клавиши
    
    ; Обслужить контроллер прерываний
    mov AL,20h
    out 20h,AL
    
    inc Sign                 ; увеличить кол-во нажатий на Ctrl
    cmp Sign,3               ; если еще не нажали 3 раза
    jne SwLoop1              ; перейти на опрос клавиатуры
    
    mov Sign,0               ; сбросить кол-во нажатий на Ctrl
    cmp OK_Text,01h          ; если экран не был выключен
    jne Exit009              ; то выход
    
    call VideoXcg            ; иначе включить экран
    mov AH,01h
    mov CX,CurSize           ; восстановить курсор
    int 10h
    mov OK_Text,0h           ; сбросить признак гашения экрана

Exit009:
    xor AX,AX
    mov ES,AX                ; очистить флаги нажатия
    mov AL,ES:[417h]         ; <Control+Alt> по адресу 0000h:0417h
    and AL,11110011b
    mov ES:[417h],AL
    mov AL,ES:[418h]         ; <LeftControl+LeftAlt> по адресу 0000h:0418h
    and AL,11111100b
    mov ES:[418h],AL
    
    mov AL,20h               ; обслужить контроллер прерываний
    out 20h,AL
    cli                      ; запретить прерывания
    pop ES
    pop DS
    pop SI
    pop DI
    pop CX
    pop BX
    pop AX
    iret                     ; выйти из прерывания

Exit09:
    cli                      ; запретить прерывания
    pop ES
    pop DS
    pop SI
    pop DI
    pop CX
    pop BX
    pop AX
    jmp CS:OldInt09          ; передать управление по цепочке
Int09Hand endp

; ОБРАБОТЧИК ПРЕРЫВАНИЯ Int16h (ВИДЕО ФУНКЦИИ BIOS)
    dw TestInt16             ; слово для обнаружения перехвата

Presense proc
    cmp AH,FuncNum           ; обращение от нашей программы?
    jne CheckBlock           ; если нет - проверить блокировку
    mov AX,CodeOut           ; иначе в AX условленный код
    iret

CheckBlock:
    cmp CS:OK_Text,01h       ; проверить флаг блокировки
    jne Pass                 ; если не заблокирована - пропустить
    
    ; БЛОКИРОВКА INT 16h при активной блокировке
    cmp AH,00h               ; функция чтения клавиши?
    je BlockIt
    cmp AH,01h               ; функция проверки буфера?
    je BlockIt
    cmp AH,10h               ; расширенное чтение?
    je BlockIt
    cmp AH,11h               ; расширенная проверка?
    je BlockIt
    jmp Pass

BlockIt:
    xor AX,AX                ; возвращаем пустое значение
    iret

Pass:
    jmp CS:OldInt16          ; передать управление по цепочке
Presense endp

; Н Е Р Е З И Д Е Н Т Н А Я   Ч А С Т Ь

InitProc proc
    mov AH,FuncNum           ; проверка, загружена ли программа в память
    int 16h
    cmp AX,CodeOut           ; (по условленному коду)
    je AlreadyInstalled      ; если да - выход

    ; Сохранить старые векторы прерываний
    mov AX,3509h             ; получить вектор Int09h
    int 21h                  ; в ES:BX
    mov OfsInt09,BX          ; сохранить смещение
    mov SegInt09,ES          ; сохранить сегмент

    mov AX,3516h             ; получить вектор Int16h
    int 21h                  ; в ES:BX
    mov OfsInt16,BX          ; сохранить смещение
    mov SegInt16,ES          ; сохранить сегмент

    ; Установить новые векторы прерываний
    mov AX,2509h             ; установить вектор Int09h
    lea DX,Int09Hand         ; на наш обработчик
    int 21h

    mov AX,2516h             ; установить вектор Int16h
    lea DX,Presense          ; на наш обработчик
    int 21h

    ; Вывести сообщение о загрузке
    mov AH,09h
    lea DX,MsgInstalled
    int 21h

    ; Остаться резидентной программой
    mov DX,offset InitProc   ; размер резидентной части
    add DX,15                ; округлить до параграфа
    mov CL,4
    shr DX,CL                ; в параграфах
    mov AX,3100h             ; функция TSR
    int 21h

AlreadyInstalled:
    mov AH,09h
    lea DX,MsgAlready
    int 21h
    mov AX,4C00h             ; выход из программы
    int 21h

MsgInstalled db 'LOCKER installed successfully.',13,10,'$'
MsgAlready db 'LOCKER already installed.',13,10,'$'

InitProc endp

PROGRAM ends
    end Start