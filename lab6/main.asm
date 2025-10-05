;Программа транслируется в COM-файл:
; TASM demo.asm
; Tlink demo.obj /t
.386p

Gdt_Descriptor STRUC
  Seg_Limit    dw   0
  Base_Lo_Word dw   0
  Base_Hi_Byte db   0
  Acces_Rights db   0
               db   0
  Base_Top_Byte db  0
Gdt_Descriptor ENDS

Idt_Descriptor STRUC
  Int_Offset   dw   0
  Int_Selector dw   0
               db   0
  Access       db   0
               dw   0
Idt_Descriptor ENDS

Code_Seg_Access  Equ  10011010b
Data_Seg_Access  Equ  10010010b
Disable_Bit20    Equ  11011101b
Enable_Bit20     Equ  11011111b
Port_A           Equ  060h
Status_port      Equ  064h
Cmos_Port        Equ  070h

FILLDESCR MACRO Seg_Addr,Offset_Addr,Descr
    xor   edx,edx
    xor   ecx,ecx
    mov   dx,Seg_Addr
    mov   cx,offset Offset_Addr
    call  Form_32Bit_Address
    mov   &Descr.Base_Lo_Word,dx
    mov   &Descr.Base_Hi_Byte,cl
    mov   &Descr.Base_Top_Byte,ch
ENDM

CSEG    SEGMENT  Para USE16 public 'code'
        ASSUME  cs:Cseg,ds:Cseg
        ORG     100h
Start:
        jmp     Main

EVEN
Gdt     label   word
Gdt_Desc        EQU $-gdt
Gdt1    Gdt_Descriptor <gdt_leng,,,data_seg_access,>

Cs_Code         EQU $-gdt
Gdt2    Gdt_Descriptor<cseg_leng,,,code_seg_access,>

Cs_Data         EQU $-gdt
Gdt3    Gdt_Descriptor<cseg_leng,,,data_seg_access,>

Idt_Pointer     Gdt_Descriptor<idt_leng-1,,,data_seg_access>

Idt_Real        Gdt_Descriptor<3FFh,,,data_seg_access>

Video_Desc      EQU $-gdt
GdtB800         Gdt_Descriptor<1000h,8000h,0bh,data_seg_access>

Gdt_Leng        EQU $-gdt

EVEN
Idt     label   word
; 16-bit Interrupt Gate: 10000110b = 86h
ex0     Idt_Descriptor<offset ex0_proc,cs_code,0,86h,0>
ex1     Idt_Descriptor<offset ex1_proc,cs_code,0,86h,0>
ex2     Idt_Descriptor<offset ex2_proc,cs_code,0,86h,0>
ex3     Idt_Descriptor<offset ex3_proc,cs_code,0,86h,0>
ex4     Idt_Descriptor<offset ex4_proc,cs_code,0,86h,0>
ex5     Idt_Descriptor<offset ex5_proc,cs_code,0,86h,0>
ex6     Idt_Descriptor<offset ex6_proc,cs_code,0,86h,0>
ex7     Idt_Descriptor<offset ex7_proc,cs_code,0,86h,0>
ex8     Idt_Descriptor<offset ex8_proc,cs_code,0,86h,0>
ex9     Idt_Descriptor<offset ex9_proc,cs_code,0,86h,0>
ex10    Idt_Descriptor<offset ex10_proc,cs_code,0,86h,0>
ex11    Idt_Descriptor<offset ex11_proc,cs_code,0,86h,0>
ex12    Idt_Descriptor<offset ex12_proc,cs_code,0,86h,0>
ex13    Idt_Descriptor<offset ex13_proc,cs_code,0,86h,0>
ex14    Idt_Descriptor<offset ex14_proc,cs_code,0,86h,0>
ex15    Idt_Descriptor<offset ex15_proc,cs_code,0,86h,0>
ex16    Idt_Descriptor<offset ex16_proc,cs_code,0,86h,0>

        Idt_Descriptor 22 dup(<>)
Int39   Idt_Descriptor<offset int10_proc,cs_code,0,86h,0>
Idt_Leng        EQU $-Idt

Mess            db  'Protected Mode$'
Gate_Failure    db  "Error open A20$"

GPF_Title       db  "General Protection Fault (Int 13)$"
GPF_Code_Msg    db  "Error Code: $"
GPF_EXT_Msg     db  "EXT bit: $"
GPF_TI_Msg      db  "TI bit: $"
GPF_IDT_Msg     db  "IDT bit: $"
GPF_Index_Msg   db  "Selector Index: $"
Hex_Digits      db  "0123456789ABCDEF"

Main:
        FillDescr  cs,Gdt,Gdt1
        FillDescr  cs,0,gdt2
        FillDescr  cs,0,gdt3
        FillDescr  cs,Idt,Idt_Pointer

        cli
        mov   al,8fh
        out   cmos_port,al
        jmp   short $+2
        mov   al,5
        out   cmos_port+1,al

        mov   ah,Enable_Bit20
        call  Gate_A20
        or    al,al
        jz    A20_Opened
        mov   dx,offset Gate_Failure
        mov   ah,9
        int   21h
        sti
        int   20h

A20_Opened:
        lea   di,Real_CS
        mov   word ptr cs:[di],cs

        lgdt  Gdt1
        lidt  Idt_Pointer
        mov   eax,cr0
        or    eax,1
        mov   cr0,eax

        db    0EAh
        dw    offset Protect
        dw    Cs_Code

Protect:
        mov   ax,Cs_Data
        mov   ss,ax
        mov   ds,ax
        mov   es,ax
        call  My_Proc

        cli
        mov   eax,cr0
        and   eax,0FFFFFFFEh
        mov   cr0,eax

        db    0EAh
        dw    offset Real
Real_CS dw    ?

Real:
        lidt  Idt_Real
        mov   dx,cs
        mov   ds,dx
        mov   ss,dx
        mov   ah,Disable_Bit20
        call  Gate_A20
        sti
        int   20h

ex0_proc:  iret
ex1_proc:  iret
ex2_proc:  iret
ex3_proc:  iret
ex4_proc:  iret
ex5_proc:  iret
ex6_proc:  iret
ex7_proc:  iret
ex8_proc:  iret
ex9_proc:  iret
ex10_proc: iret
ex11_proc: iret
ex12_proc: iret

ex13_proc PROC NEAR
        cli
        pusha
        push  ds
        push  es

        mov   ax, Cs_Data
        mov   ds, ax
        mov   ax, Video_Desc
        mov   es, ax

        ; Очистить экран
        mov   cx, 2000
        xor   di, di
        mov   ax, 0F20h
        cld
        rep   stosw

        ; Получить код ошибки
        mov   bp, sp
        mov   di, [bp+20]  

        ; Строка 2: "General Protection Fault (Int 13)"
        mov   si, offset GPF_Title
        mov   bx, 160*2 + 20
        call  Print_String_SI 

        ; Строка 4: "Error Code: FFFC"
        mov   si, offset GPF_Code_Msg
        mov   bx, 160*4 + 20
        call  Print_String_SI 
        
        mov   ax, di
        mov   bx, 160*4 + 60
        call  Print_Hex_Word 

        ; Строка 6: "EXT bit: 0"
        mov   si, offset GPF_EXT_Msg
        mov   bx, 160*6 + 20
        call  Print_String_SI 
        
        mov   ax, di
        and   ax, 1
        add   al, '0'
        mov   ah, 0Fh     
        mov   es:[160*6 + 50], ax

        ; Строка 8: "TI bit: 0"
        mov   si, offset GPF_TI_Msg
        mov   bx, 160*8 + 20
        call  Print_String_SI 
        
        mov   ax, di
        shr   ax, 1
        and   ax, 1
        add   al, '0'
        mov   ah, 0Fh      
        mov   es:[160*8 + 48], ax

        ; Строка 10: "IDT bit: 1"
        mov   si, offset GPF_IDT_Msg
        mov   bx, 160*10 + 20
        call  Print_String_SI 
        
        mov   ax, di
        shr   ax, 2
        and   ax, 1
        add   al, '0'
        mov   ah, 0Fh      
        mov   es:[160*10 + 52], ax

        ; Строка 12: "Selector Index: 1FFF"
        mov   si, offset GPF_Index_Msg
        mov   bx, 160*12 + 20
        call  Print_String_SI 
        
        mov   ax, di
        shr   ax, 3
        mov   bx, 160*12 + 68
        call  Print_Hex_Word 

Hang:   jmp   Hang

        pop   es
        pop   ds
        popa
        add   sp, 2
        sti
        iret
ex13_proc ENDP

ex14_proc: iret
ex15_proc: iret
ex16_proc: iret

Print_String_SI PROC NEAR
        push  ax
        push  bx
        push  si
PS_Loop:
        lodsb
        cmp   al, '$'
        je    PS_Done
        mov   ah, 0Fh
        mov   es:[bx], ax
        add   bx, 2
        jmp   PS_Loop
PS_Done:
        pop   si
        pop   bx
        pop   ax
        ret
Print_String_SI ENDP

Print_Hex_Word PROC NEAR
        push  ax
        push  bx
        push  cx
        push  dx
        
        mov   cx, 4
PHW_Loop:
        rol   ax, 4
        push  ax
        and   ax, 0Fh
        cmp   al, 10
        jb    PHW_Digit
        add   al, 7
PHW_Digit:
        add   al, '0'
        mov   ah, 0Fh
        mov   es:[bx], ax
        add   bx, 2
        pop   ax
        loop  PHW_Loop
        
        pop   dx
        pop   cx
        pop   bx
        pop   ax
        ret
Print_Hex_Word ENDP

Gate_A20 PROC
        cli
        call  Empty_8042
        jnz   Gate_1
        mov   al,0d1h
        out   Status_Port,al
        call  Empty_8042
        jnz   Gate_1
        mov   al,ah
        out   Port_A,al
        call  Empty_8042
Gate_1:
        ret
Gate_A20 ENDP

;************************************************
Empty_8042 PROC
        push  cx
        xor   cx,cx
Empty_1:
        in    al,Status_Port
        and   al,00000010b
        loopnz Empty_1
        pop   cx
        ret
Empty_8042 ENDP

;************************************************
Form_32Bit_Address PROC
        shl   edx,4
        add   edx,ecx
        mov   ecx,edx
        shr   ecx,16
        ret
Form_32Bit_Address ENDP

;************************************************
Int10_Proc PROC Near
        pusha
        xor   cx,cx
        mov   cl,dh
        sal   cl,1
        xor   dh,dh
        imul  dx,160d
        add   dx,cx
        push  Video_Desc
        pop   es
        mov   di,dx
m:
        mov   ax,[bx]
        cmp   al,'$'
        jz    Ex
        mov   cx,es:[di]
        mov   ah,ch
        stosw
        inc   bx
        jmp   short m
Ex:
        popa
        iret
Int10_Proc Endp

;************************************************
MY_PROC PROC
        pusha
        push  es
        push  Video_Desc
        pop   es
        mov   dh,0fh
        call  Paint_Screen

        mov   ax,Cs_Data
        mov   ds,ax
        lea   bx,Mess
        mov   dx,200Bh
        int   39d

        ; ГЕНЕРАЦИЯ ИСКЛЮЧЕНИЯ 13
        mov   ax, 0FFFFh
        mov   ds, ax            ; Попытка загрузить несуществующий селектор

        pop   es
        popa
        ret
MY_PROC ENDP

;************************************************
PAINT_SCREEN PROC
        push  cx si di es
        mov   cx,80*25
        xor   si,si
        xor   di,di
Paint1:
        lodsw
        mov   ah,dh
        mov   al,20h
        stosw
        loop  Paint1
        pop   es di si cx
        RET
PAINT_SCREEN ENDP

Cseg_Leng       Equ  $
Cseg            Ends
                End  Start
