[bits 32]

%include "selector.inc"

section .text
global print
global clear

; ��ӡ
; c���õĺ������������ڶ�ջ����
; print(u8* addr)
; ��ջ˳��addr eip ebp
print:
    push ebp
    mov ebp, esp
    mov ebx, [ebp + 8] ; ��ȡ�ַ�����ַ

    push es
    mov ax, DISP_SEL 
    mov es, ax
    ; ��ȡ��ǰ���λ��
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
    in al, dx   ;����eax�б����ŵ�ǰ���λ��
    shl eax, 1
.show_char:    
    mov cl, byte [ebx]
    inc ebx
    cmp cl, 0    ; �жϵ�ǰ�ַ��Ƿ��ǽ�����
    jz .exit        ; �Ǿ��˳�����
    
    ; �˺���������ַ��Ĵ���
    ; ���ȴ���س�0xd
    cmp cl, 0xd
    jnz .is_0xa
    mov ch, 80
    div ch
    and eax, 0xff
    mul ch
    jmp .set_cursor

.is_0xa:  ;����
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
    mov ecx, eax    ; �����ֿ�������
    shr ecx, 1
    rep movsw
    mov ecx, 80
.empty_line:
    mov byte [es:edi], 0x20
    add edi, 2
    loop .empty_line
    pop ds
.set_cursor: ;���ù��λ��
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
    mov eax, ecx ;eax����Ȼ�ǵ�ǰ���λ��
    jmp .show_char
.exit:
    pop es
    leave
    ret

; ��������
; void clear()
; ѹջ˳��eip
clear:
    push ebp
    mov ebp, esp

    push es
    mov ax, DISP_SEL 
    mov es, ax
    mov ecx, 40*25
    xor ebx, ebx

;   ��ȡ��ʾ��ʼλ��
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
;   ��ȡ��ǰ���λ��
;   �õ���ax����Ҫ��2���������Ĺ��λ��

;   ���ù��λ��Ϊ 80*25-1=0x7cf������Ļ�ĵ����ڶ���
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
