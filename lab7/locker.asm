PROGRAM segment
    assume CS:PROGRAM
    org 100h                ; ������� PSP ��� COM-���������

Start: jmp InitProc         ; ������� �� �������������

; � � � � � � � � � � �   � � � � � �
FuncNum equ 0EEh             ; �������������� ������� ���������� BIOS Int16h
CodeOut equ 2D0Ch            ; ���, ������������ ����� ������������ Int16h
TestInt09 equ 9D0Ah          ; ����� ����� Int09h
TestInt16 equ 3AFAh          ; ����� ����� Int16h

OldInt09 label dword         ; ����������� ������ Int09h:
    OfsInt09 dw ?            ; ��� ��������
    SegInt09 dw ?            ; � �������

OldInt16 label dword         ; ����������� ������ Int16h:
    OfsInt16 dw ?            ; ��� ��������
    SegInt16 dw ?            ; � �������

OK_Text db 0                 ; ������� ������� ������
Sign db ?                    ; ���������� ������� Ctrl

VideoLen equ 800h            ; ����� �����������
VideoBuf db 160 dup(' ')
db 13 dup(' ')
db '??????????????????????????????????????????????????????'
db 26 dup(' ')
db '?                                                    ?'
db 26 dup(' ')
db '?  ��� ������������� ������� ��� ���� LeftControl   ?'
db 26 dup(' ')
db '?                                                    ?'
db 26 dup(' ')
db '?          ���������� �������������!                ?'
db 26 dup(' ')
db '??????????????????????????????????????????????????????'
db 2000 dup(' ')

AttrBuf db VideoLen dup(07h) ; �������� ������
VideoBeg dw 0B800h           ; ����� ������ ������������
VideoOffs dw ?               ; �������� �������� ��������
CurSize dw ?                 ; ����������� ������ �������

; � � � � � � � � � � �   � � � � � � � � �

; ������������ ������ ������������ � ������� ���������
VideoXcg proc
    lea DI,VideoBuf          ; � DI - ����� ������ ��������
    lea SI,AttrBuf           ; � SI - ����� ������ ���������
    mov AX,VideoBeg          ; � ES - ���������� �����
    mov ES,AX                ; ������ ������������
    mov CX,VideoLen          ; � CX - ����� �����������
    mov BX,VideoOffs         ; � BX - ��������� �������� ������
Draw:
    mov AX,ES:[BX]           ; �������� ������/�������
    xchg AH,DS:[SI]          ; �� ������ � �������� � ���������
    xchg AL,DS:[DI]          ; �� �������
    mov ES:[BX],AX
    inc SI                   ; ��������� ����� � �������
    inc DI
    inc BX                   ; ��������� ����� � �����������
    inc BX
    loop Draw                ; ������ ��� ���� ������������
    ret
VideoXcg endp

; ���������� ���������� Int09h (���������� �� ����������)
    dw TestInt09             ; ����� ��� ����������� ���������

Int09Hand proc
    push AX
    push BX
    push CX
    push DI
    push SI
    push DS
    push ES
    push CS                  ; ������� DS �� ���� ���������
    pop DS

    in AL,60h                ; �������� ����-��� ������� �������
    cmp AL,26h               ; ��������� �� ����-��� ������� <L>
    jne Exit_09              ; � �����, ���� �� ��
    
    xor AX,AX
    mov ES,AX                ; ��������� ����� ���������� ��
    mov AL,ES:[418h]         ; ������� <Ctrl+Alt>
    and AL,03h
    cmp AL,03h
    je Cont

Exit_09:
    jmp Exit09               ; �����

Cont:
    sti                      ; ��������� ����������
    mov AH,0Fh               ; �������� ������� ����������
    int 10h
    cmp AL,2
    je InText
    cmp AL,3                 ; ���� ����� ��������� 80x25
    je InText
    cmp AL,7
    je InText
    jmp short SwLoop1        ; ����� - ����������

InText:
    xor AX,AX                ; ���������� ���������� ����� � 0000h
    mov ES,AX
    mov AX,ES:[44Eh]         ; �������� �������� �������� ��������
    mov VideoOffs,AX
    
    mov AH,03h               ; ��������� ������ �������
    int 10h
    mov CurSize,CX
    mov AH,01h
    mov CH,20h               ; �������� ������
    int 10h
    
    mov OK_Text,01h          ; ���������� ������� ������� ������
    call VideoXcg            ; ������� ��������� �������

SwLoop1:
    in AL,60h                ; � AL - ��� ������� �������
    
    cmp AL,1Dh               ; ���� ������ LeftCtrl
    je SwLoop2               ; ��������� � �������� ����������
    
    cmp AL,9Dh               ; ���� �������� LeftCtrl
    je SwLoop1               ; ���������� �����
    
    ; ���������� ���� ��������� ������
    mov Sign,0               ; �������� ���-�� �������
    
    ; ��������� ���������� ���������� (��������!)
    mov AL,20h
    out 20h,AL
    
    jmp short SwLoop1        ; ����� �� ����� ����������

SwLoop2:
    in AL,60h                ; � AL - ����-��� �������
    cmp AL,9Dh               ; ���� �� ��� ���������� Ctrl
    jne SwLoop2              ; ������� ���������� �������
    
    ; ��������� ���������� ����������
    mov AL,20h
    out 20h,AL
    
    inc Sign                 ; ��������� ���-�� ������� �� Ctrl
    cmp Sign,3               ; ���� ��� �� ������ 3 ����
    jne SwLoop1              ; ������� �� ����� ����������
    
    mov Sign,0               ; �������� ���-�� ������� �� Ctrl
    cmp OK_Text,01h          ; ���� ����� �� ��� ��������
    jne Exit009              ; �� �����
    
    call VideoXcg            ; ����� �������� �����
    mov AH,01h
    mov CX,CurSize           ; ������������ ������
    int 10h
    mov OK_Text,0h           ; �������� ������� ������� ������

Exit009:
    xor AX,AX
    mov ES,AX                ; �������� ����� �������
    mov AL,ES:[417h]         ; <Control+Alt> �� ������ 0000h:0417h
    and AL,11110011b
    mov ES:[417h],AL
    mov AL,ES:[418h]         ; <LeftControl+LeftAlt> �� ������ 0000h:0418h
    and AL,11111100b
    mov ES:[418h],AL
    
    mov AL,20h               ; ��������� ���������� ����������
    out 20h,AL
    cli                      ; ��������� ����������
    pop ES
    pop DS
    pop SI
    pop DI
    pop CX
    pop BX
    pop AX
    iret                     ; ����� �� ����������

Exit09:
    cli                      ; ��������� ����������
    pop ES
    pop DS
    pop SI
    pop DI
    pop CX
    pop BX
    pop AX
    jmp CS:OldInt09          ; �������� ���������� �� �������
Int09Hand endp

; ���������� ���������� Int16h (����� ������� BIOS)
    dw TestInt16             ; ����� ��� ����������� ���������

Presense proc
    cmp AH,FuncNum           ; ��������� �� ����� ���������?
    jne CheckBlock           ; ���� ��� - ��������� ����������
    mov AX,CodeOut           ; ����� � AX ����������� ���
    iret

CheckBlock:
    cmp CS:OK_Text,01h       ; ��������� ���� ����������
    jne Pass                 ; ���� �� ������������� - ����������
    
    ; ���������� INT 16h ��� �������� ����������
    cmp AH,00h               ; ������� ������ �������?
    je BlockIt
    cmp AH,01h               ; ������� �������� ������?
    je BlockIt
    cmp AH,10h               ; ����������� ������?
    je BlockIt
    cmp AH,11h               ; ����������� ��������?
    je BlockIt
    jmp Pass

BlockIt:
    xor AX,AX                ; ���������� ������ ��������
    iret

Pass:
    jmp CS:OldInt16          ; �������� ���������� �� �������
Presense endp

; � � � � � � � � � � � � �   � � � � �

InitProc proc
    mov AH,FuncNum           ; ��������, ��������� �� ��������� � ������
    int 16h
    cmp AX,CodeOut           ; (�� ������������ ����)
    je AlreadyInstalled      ; ���� �� - �����

    ; ��������� ������ ������� ����������
    mov AX,3509h             ; �������� ������ Int09h
    int 21h                  ; � ES:BX
    mov OfsInt09,BX          ; ��������� ��������
    mov SegInt09,ES          ; ��������� �������

    mov AX,3516h             ; �������� ������ Int16h
    int 21h                  ; � ES:BX
    mov OfsInt16,BX          ; ��������� ��������
    mov SegInt16,ES          ; ��������� �������

    ; ���������� ����� ������� ����������
    mov AX,2509h             ; ���������� ������ Int09h
    lea DX,Int09Hand         ; �� ��� ����������
    int 21h

    mov AX,2516h             ; ���������� ������ Int16h
    lea DX,Presense          ; �� ��� ����������
    int 21h

    ; ������� ��������� � ��������
    mov AH,09h
    lea DX,MsgInstalled
    int 21h

    ; �������� ����������� ����������
    mov DX,offset InitProc   ; ������ ����������� �����
    add DX,15                ; ��������� �� ���������
    mov CL,4
    shr DX,CL                ; � ����������
    mov AX,3100h             ; ������� TSR
    int 21h

AlreadyInstalled:
    mov AH,09h
    lea DX,MsgAlready
    int 21h
    mov AX,4C00h             ; ����� �� ���������
    int 21h

MsgInstalled db 'LOCKER installed successfully.',13,10,'$'
MsgAlready db 'LOCKER already installed.',13,10,'$'

InitProc endp

PROGRAM ends
    end Start