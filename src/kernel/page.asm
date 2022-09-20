[bits 32]

%include "selector.inc"
%include "address.inc"

section .text

global setupPage

; ���÷�ҳ����
; void setupPage(u8* buf)
; input:    buf(���ȫ�����������������ַ�Ļ���������6�ֽڴ�С)
; ����ֵ����gdtPtr��ֵ�˴����gdt�ĳ��ȣ��Լ�gdt�Ļ���ַ
; ������ջ��buf eip ebp
setupPage:
    push ebp
    mov ebp, esp
;    ������ҳ����
    mov ecx, 2048 
    mov ebx, PAGE_DIR_ADDR 
.clr_page:
    mov dword [ebx], 0
    add ebx, 4
    loop .clr_page 

    ; ���õ�һ��ҳĿ¼��
    mov ebx, PAGE_DIR_ADDR
    mov eax, PAGE_TAB_ADDR
    or eax, 0x3
    mov dword [ebx], eax
    ;�������ַ�ռ��Ϊ���������֣�0-2G�û���ַ�ռ䣬2-4G�ں˵�ַ�ռ�
    ;��������ҳĿ¼��һ��ƫ��0x200����ҳĿ¼��������0ƫ�ƴ���������ͬ
    mov ebx, (PAGE_DIR_ADDR + 0x800)
    mov dword [ebx], eax 
    ;��ҳĿ¼���һ������ΪҳĿ¼�Լ�
    mov ebx, (PAGE_TAB_ADDR - 4)
    mov eax, PAGE_DIR_ADDR
    or eax, 0x3
    mov dword [ebx], eax

    ; ����1MB�ں�����ռ��Ӧ��ҳ����
    mov ebx, PAGE_TAB_ADDR
    mov ecx, 256
    mov eax, 0
.set_page:
    or eax, 3
    mov dword [ebx], eax
    add eax, PAGE_SIZE
    add ebx, 4
    loop .set_page

    ; ��ȡgdtPtr
    mov ebx, dword [ebp + 8]
    sgdt [ebx]  ; ��û������ҳ��gdt��Ϣ������ebx��ָ�ڴ洦
    xor ecx, ecx
    mov cx, word [ebx]      ; gdtLen
    inc cx
    shr cx, 3               ; selNum    �������ĸ���, �����ж��ǲ�����ȷ(Ӧ��Ϊ100)

    mov cx, VALID_SEL       ; Ϊ�˽�Լʱ�䣬��ֵ��Ч�Ķ�ѡ���Ӹ���(�˹���ǵ��Ժ������Ҫ���ܻ��޸�)
    mov eax, dword [ebx + 2]; gdtBase
    mov edx, ebx            ; gdtPtr
    mov ebx, eax
    mov eax, 1
    ; �����޸Ķ��������ĸ�4λ������ַ+0x8000_0000
.set_sel:
    mov esi, eax
    shl esi, 3
    add esi, 4
    or dword [ebx + esi], 0x80000000
    inc eax
    loop .set_sel
    mov ebx, edx
    ;�����ں˶�ѡ����
    add dword [ebx + 2], 0x80000000

    ; ����cr3�Ĵ���
    xor eax, eax
    mov eax, PAGE_DIR_ADDR 
    mov cr3, eax

    ; ������ҳ����
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    lgdt [ebx]

    jmp CODE_SEL:.page_flush

.page_flush: 
    mov ax, DATA_SEL
    mov ds, ax
    mov fs, ax
    mov es, ax
    mov gs, ax
    mov ax, STCK_SEL
    mov ss, ax
;    mov esp, KERNEL_ADDR   
;    mov eax, dword [ebp + 4]
;    or eax, 0x80000000
;    push eax
    leave
    ret
