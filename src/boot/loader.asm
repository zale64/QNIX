[bits 16]

org 0x7e00

%include "address.inc"
%include "descriptor.inc"
%include "selector.inc"

    jmp loader_start

; δ������ҳ�����µĶ�������
; �ܹ�Ԥ��100�����������Ŀռ䣬�Ա�֮�����ʹ��

NONE_SEG CREATE_DESC 0, 0, 0
CODE_SEG CREATE_DESC 0x00000000, 0xfffff, (G_PAGE|OP_SIZE_32|L_FLAG|AVL_0|P_1|DPL_0|IS_NOR|CODE_CONEXE)     ; 0x8
DATA_SEG CREATE_DESC 0x00000000, 0xfffff, (G_PAGE|OP_SIZE_32|L_FLAG|AVL_0|P_1|DPL_0|IS_NOR|DATA_RW)         ; 0x10
STCK_SEG CREATE_DESC 0x00000000, 0, (G_PAGE|OP_SIZE_32|L_FLAG|AVL_0|P_1|DPL_0|IS_NOR|STACK_RW)              ; 0x18
DISP_SEG CREATE_DESC 0x000b8000, 0x7fff, (G_BYTE|OP_SIZE_32|L_FLAG|AVL_0|P_1|DPL_0|IS_NOR|DATA_RW)           ; 0x20
times 760 db 0
gdt_len     equ ($-NONE_SEG)
gdt_ptr     dw (gdt_len - 1)
            dd NONE_SEG

loader_start:
    lgdt [gdt_ptr]

    in al, 0x92
    or al, 0000_0010b
    out 0x92, al

    cli         

    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    jmp dword CODE_SEL:pro_entry
    
[bits 32]
pro_entry:
    mov ax, DATA_SEL
    mov ds, ax
    mov fs, ax
    mov es, ax
    mov gs, ax
    mov ax, STCK_SEL
    mov ss, ax
    mov esp, KERNEL_ADDR 

    ; ���ں˶����ڴ�
    ; ��ȡ80��page(640������)  Ϊ���Է�����ȫ�����ں˶����ڴ棬һ�ζ������
    ; һ�������Զ�ȡ256������(0x1f2�˿�д0)
    ; ��������Ϊһ�ζ�128����������5�ζ���
    
    mov ecx, 5
    mov eax, 128
    mov ebx, 11
    mov edx, KERNEL_ADDR
.read:
    call read_disk
    add ebx, 128
    add edx, (128<<9)
    loop .read
    
    jmp KERNEL_ADDR     ; �����ں�
    
    hlt

read_disk:
    ; eax --- sector counts will be read 
    ; ebx --- begin sector index 
    ; edx --- dest addr
    ; port 0x1f2:����Ҫ��ȡ����ʼ�߼�������
    ;      0x1f3~0x1f6(��24bits)���Ҫ��ȡ���������� 
    push eax
    push ebx
    push ecx 
    push edx
    mov ecx, eax

    mov dx, 0x1f2
    out dx, al
    mov eax, ebx

    inc dx
    out dx, al

    inc dx
    shr eax, 8
    out dx, al

    inc dx
    shr eax, 8
    out dx, al

    inc dx
    shr eax, 8
    or al, 0xe0
    out dx, al
    
    inc dx
    mov al, 0x20
    out dx, al
.waits:
    in al, dx
    and al, 0x88
    cmp al, 0x08
    jnz .waits

    shl ecx, 8
    pop edx
    mov edi, edx
    mov ebx, edx
    mov dx, 0x1f0
.readw:
    in ax, dx 
    mov word [ebx], ax
    add ebx, 2
    loop .readw

    mov edx, edi
    pop ecx 
    pop ebx
    pop eax
    ret
