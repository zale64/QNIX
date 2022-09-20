[bits 16]

%include "address.inc"

org 0x7c00

jmp real_start

real_start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, KERNEL_ADDR
    
    ; 使用BIOS int 0x13号中断读取硬盘, 将loader加载进内存
    ; ah = 2(read disk) 3(write disk)
    ; al = num of sectors
    ; cl = bit0~5起始扇区   bit6~7磁道号高2位
    ; ch = 磁道号低8位
    ; dh = 磁头号   
    ; dl = 驱动器号 00-7f(软盘), 80-ff(硬盘)
    ; es:bx = 目的内存地址
    ; mov bx, LOADER_ADDR
    ; mov ax, 0x020a        ; 读10个扇区
    ; mov cx, 0x0002
    ; ;mov cx, 0x0001
    ; mov dx, 0x0080
    ; int 0x13
    ; 由于kernel比较大，所以不能使用BIOS 0x13中断来读取
    ; 只能通过硬盘控制端口进行读取较大的文件
    mov eax, 0xa
    mov ebx, 0x1
    mov edx, LOADER_ADDR
    call read_disk
    
    xor bx, bx

    jmp LOADER_ADDR    ; 跳入Loader

    hlt

read_disk:
    ; eax --- sector counts will be read 
    ; ebx --- begin sector index 
    ; edx --- dest addr
    ; port 0x1f2:设置要读取的起始逻辑扇区号
    ;      0x1f3~0x1f6(共24bits)存放要读取的扇区个数 
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
    mov ebx, edx
    mov dx, 0x1f0
.readw:
    in ax, dx 
    mov word [ebx], ax
    add bx, 2
    loop .readw
   
    pop ecx 
    ret
times 510-($-$$) db 0
                 db 0x55,0xaa
