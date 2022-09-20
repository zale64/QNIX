[bits 32]

%include "selector.inc"

section .text
global print
global clear

; 打印
; c调用的函数，参数都在堆栈里面
; print(u8* addr)
; 进栈顺序：addr eip ebp
print:
    push ebp
    mov ebp, esp
    mov ebx, [ebp + 8] ; 获取字符串地址

    push es
    mov ax, DISP_SEL 
    mov es, ax
    ; 获取当前光标位置
.get_cursor:
    xor eax, eax
    mov al, 0xe
    mov dx, 0x3d4
    out dx, al
    inc dx
    in al, dx
    shl eax, 8
    dec dx
    mov al, 0xf
    out dx, al
    inc dx
    in al, dx   ;至此eax中保留着当前光标位置
    shl eax, 1
.show_char:    
    mov cl, byte [ebx]
    inc ebx
    cmp cl, 0    ; 判断当前字符是否是结束符
    jz .exit        ; 是就退出函数
    
    ; 此后进行特殊字符的处理
    ; 首先处理回车0xd
    cmp cl, 0xd
    jnz .is_0xa
    mov ch, 80
    div ch
    and eax, 0xff
    mul ch
    jmp .set_cursor

.is_0xa:  ;换行
    cmp cl, 0xa
    jnz .is_normal
    cmp eax, 160*24
    jge .scroll
    add eax, 160
    jmp .set_cursor
.is_normal:
    ;mov ebx, eax
    xor ch, ch
    mov byte [es:eax], cl
    add eax, 2
    cmp eax, 160*25
    ;mov eax, ebx
    jl .set_cursor
.scroll:    
    ; ds:esi
    ; es:edi
    push ds
    shl eax, 16
    mov ax, DISP_SEL 
    mov ds, ax
    shr eax, 16
    sub eax, 160
    xor edi, edi
    xor esi, esi
    mov esi, 0xa0
    mov ecx, eax    ; 设则字拷贝次数
    shr ecx, 1
    rep movsw
    mov ecx, 80
.empty_line:
    mov byte [es:edi], 0x20
    add edi, 2
    loop .empty_line
    pop ds
.set_cursor: ;设置光标位置
    mov ecx, eax
    shl eax, 7
    mov al, 0xf
    mov dx, 0x3d4
    out dx, al
    shr eax, 8
    inc dx
    out dx, al
    mov al, 0xe
    dec dx
    out dx, al
    inc dx
    shr eax, 8
    out dx, al
    mov eax, ecx ;eax中仍然是当前光标位置
    jmp .show_char
.exit:
    pop es
    leave
    ret

; 清屏函数
; void clear()
; 压栈顺序eip
clear:
    push ebp
    mov ebp, esp

    push es
    mov ax, DISP_SEL 
    mov es, ax
    mov ecx, 40*25
    xor ebx, ebx

;   获取显示开始位置
;    xor eax, eax
;    mov al, 0xc
;    mov dx, 0x3d4
;    out dx, al
;    inc dx
;    in al, dx
;    shl al, 8
;    dec dx
;    mov al, 0xd
;    out dx, al
;    inc dx
;    in al, dx
;   获取当前光标位置
;   得到的ax还需要乘2才是真正的光标位置

;   设置光标位置为 80*25-1=0x7cf，即屏幕的倒数第二行
;    mov dx, 0x3d4
;    mov al, 0xe
;    out dx, al
;    inc dx
;    mov al, 0x7
;    out dx, al
;    dec dx
;    mov al, 0xf
;    out dx, al
;    inc dx
;    mov al, 0xcf
;    out dx, al

.clr:
    mov dword [es:ebx], 0x07200720
    add ebx, 4
    loop .clr
    mov dx, 0x3d4
    mov al, 0xe
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    dec dx
    mov al, 0xf
    out dx, al
    inc dx
    mov al, 0
    out dx, al
    pop es
    leave
    ret
