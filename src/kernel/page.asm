[bits 32]

%include "selector.inc"
%include "address.inc"

section .text

global setupPage

; 设置分页机制
; void setupPage(u8* buf)
; input:    buf(存放全局描述符长度与基地址的缓冲区，共6字节大小)
; 返回值：新gdtPtr的值此处存放gdt的长度，以及gdt的基地址
; 函数堆栈：buf eip ebp
setupPage:
    push ebp
    mov ebp, esp
;    开启分页机制
    mov ecx, 2048 
    mov ebx, PAGE_DIR_ADDR 
.clr_page:
    mov dword [ebx], 0
    add ebx, 4
    loop .clr_page 

    ; 设置第一个页目录项
    mov ebx, PAGE_DIR_ADDR
    mov eax, PAGE_TAB_ADDR
    or eax, 0x3
    mov dword [ebx], eax
    ;将物理地址空间分为上下两部分，0-2G用户地址空间，2-4G内核地址空间
    ;方法：将页目录的一半偏移0x200处的页目录项设置与0偏移处的内容相同
    mov ebx, (PAGE_DIR_ADDR + 0x800)
    mov dword [ebx], eax 
    ;将页目录最后一项设置为页目录自己
    mov ebx, (PAGE_TAB_ADDR - 4)
    mov eax, PAGE_DIR_ADDR
    or eax, 0x3
    mov dword [ebx], eax

    ; 设置1MB内核物理空间对应的页表项
    mov ebx, PAGE_TAB_ADDR
    mov ecx, 256
    mov eax, 0
.set_page:
    or eax, 3
    mov dword [ebx], eax
    add eax, PAGE_SIZE
    add ebx, 4
    loop .set_page

    ; 获取gdtPtr
    mov ebx, dword [ebp + 8]
    sgdt [ebx]  ; 将没开启分页的gdt信息保存在ebx所指内存处
    xor ecx, ecx
    mov cx, word [ebx]      ; gdtLen
    inc cx
    shr cx, 3               ; selNum    描述符的个数, 可以判断是不是正确(应该为100)

    mov cx, VALID_SEL       ; 为了节约时间，赋值有效的段选择子个数(人工标记的以后可能需要智能化修改)
    mov eax, dword [ebx + 2]; gdtBase
    mov edx, ebx            ; gdtPtr
    mov ebx, eax
    mov eax, 1
    ; 依次修改段描述符的高4位，基地址+0x8000_0000
.set_sel:
    mov esi, eax
    shl esi, 3
    add esi, 4
    or dword [ebx + esi], 0x80000000
    inc eax
    loop .set_sel
    mov ebx, edx
    ;更换内核段选择子
    add dword [ebx + 2], 0x80000000

    ; 设置cr3寄存器
    xor eax, eax
    mov eax, PAGE_DIR_ADDR 
    mov cr3, eax

    ; 开启分页机制
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
