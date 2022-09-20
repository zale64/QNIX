[bits 32]

%include "address.inc"

section .text

extern print

global alloc

; u32* alloc(u32 size) 内核内存分配
; input:    size(需要分配内存的大小)
; ouput:    eax(返回分配内存的首地址[虚拟地址])
; 分配内存以页page为单位
; 通过cs代码段选择子的属性来判断，是用户程序还是内核
alloc:
    push ebp
    mov ebp, esp

;    push ebx
;    push ecx
;    push edx

    mov eax, dword [ebp + 8]
    cmp eax, 0
    jnz .s1
    mov eax, wrongSizeMsg
    push eax
    call print
    pop eax
    hlt
.s1:
    xor edx, edx
    mov ebx, 4096
    div ebx 
    cmp edx, 0
    jz .s2
    inc eax
.s2:
    mov ecx, eax    ; 保存需要分配的页数目

    ; 先分配一个页，作为函数的返回值
    call onePhyPage ; 获得与虚拟地址对应的物理地址，准备填充页表项
    mov edx, eax
    xor esi, esi    ; 清零
    mov si, cs      ; 获取代码段选择子
    and si, 0x3     ; 获取选择子属性
    cmp si, 0x3     ; 判断是否为用户程序
    jl .is_core
    or edx, 0x7
    mov eax, 1
    jmp .next
.is_core:
    or edx, 0x3     ; 内核空间需要填充的页表项
    mov eax, 0
.next:
    call oneVirPage 
    push eax        ; 将第一个页表首地址压入栈中，作为返回值
    call fillPage   ; 填充页目录以及页表

    dec ecx         ; 分配剩下的内存
.s3:
    cmp ecx, 0
    jz .s4          ; 分配完毕，退出函数
    call onePhyPage ; 获得与虚拟地址对应的物理地址，准备填充页表项
    mov edx, eax
    cmp si, 0x3     ; 判读空间类型(用户空间 or 内核空间)
    jl .s5      
    or edx, 0x7     ; 需要填充的页表项
    mov eax, 1
    jmp .s6
.s5:
    or edx, 0x3     ; 需要填充的页表项
    mov eax, 0
.s6:
    call oneVirPage 
    call fillPage   ; 填充页目录以及页表   
    loop .s3
.s4:    
    pop eax
;    pop edx
;    pop ecx
;    pop ebx
    leave
    ret

; 物理地址与虚拟地址的映射
; 填充页目录以及页表
; input:    eax(虚拟地址) edx(页表项)[低12bit可以表示属性, bit2表示空间类型0--core 1--user]
fillPage:
    push eax
    push ebx
    push ecx
    push esi
    push edi
    push edx

    mov esi, edx
    and esi, 0x4    ; esi 中保存着空间属性

    mov edi, eax    ; edi 中保存着虚拟地址
    mov ebx, PAGE_DIR_ADDR
    shr eax, 22
    shl eax, 2
    mov ecx, eax
    add ebx, ecx
    ; 获取页目录项
    mov edx, dword [ebx]
    ; 判断页目录项是否存在
    mov esi, edx
    and edx, 0x1
    cmp edx, 0
    jnz .s1
    ; 页目录项不存在
    call onePhyPage ; 申请一页物理地址
    or eax, esi 
    mov dword [ebx], eax
    mov esi, eax
.s1:; 页目录项存在
    and esi, 0xfffff000 ; 获取页表的物理地址
    mov eax, edi ; 重新获得虚拟地址，用来定位页表中的偏移地址
    mov ecx, eax    ; 先保存虚拟地址，以便后面获得地址属性
    shr eax, 12
    and eax, 0x3ff
    shl eax, 2
    or esi, eax
    mov ebx, esi    ; 获得页表项的地址
    ; 将页表项填入
    pop edx
    mov dword [ebx], edx

    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret

; 分配一个物理页
; output:   eax(返回物理地址)
onePhyPage:
    push ebx
    push ecx

    mov ebx, phyBitMap
    mov eax, dword [nextFreePhyPageIndex]
    mov ecx, phyMapLen
.s1:
    bts [ebx], eax
    jnc .s2         ; 判断EFLAGS标志寄存器的CF位是否为0(bts指令将eax出的比特传送给CF位，0--空闲，1--占用)
    inc eax
    cmp eax, ecx
    jl .s1          ; eax小于最大可分配的内存

    ; 分配失败，已经没有空间可以分配
    mov eax, noFreeMemMsg
    push eax
    call print
    hlt

    ; 分配内存成功
    ; 将eax写回nextFreePhyPageIndex
.s2:
    mov dword [nextFreePhyPageIndex], eax
    shl eax, 12

    pop ecx
    pop ebx
    ret

; 分配一个虚拟页
; input:    eax(内核-0 or 用户-1)
; output:   eax(返回虚拟地址)
; 需要判断是内核申请空间，还是用户申请空间
; 内核(0x8000_0000 ~ 0xffff_ffff)
; 用户(0x0000_0000 ~ 0x7fff_ffff)
oneVirPage:
    push ebx
    push ecx
    push edx

    mov edx, eax
    cmp edx, 0
    jz .core

    ; 用户要分配内存
    mov ebx, virUserBitMap
    mov eax, dword [nextUserFreeVirPageIndex]
    mov ecx, virUserMapLen
    jmp .s1

.core:  ;内核要分配内存
    mov ebx, virCoreBitMap
    mov eax, dword [nextCoreFreeVirPageIndex]
    mov ecx, virCoreMapLen
.s1:
    bts [ebx], eax
    jnc .s2         ; 判断EFLAGS标志寄存器的CF位是否为0(bts指令将eax出的比特传送给CF位，0--空闲，1--占用)
    inc eax
    cmp eax, ecx
    jl .s1          ; eax小于最大可分配的内存

    ; 分配失败，已经没有空间可以分配
    mov eax, noFreeMemMsg
    push eax
    call print
    hlt
    
.s2:; 找到空闲的页
    cmp edx, 0
    jnz .s3
    ; 内核
    mov dword [nextCoreFreeVirPageIndex], eax
    add eax, 0x80000   
    jmp .s4
.s3:; 用户
    mov dword [nextUserFreeVirPageIndex], eax
.s4:
    shl eax, 12     ; 页个数 * PAGE_SIZE
    pop edx
    pop ecx
    pop ebx
    ret

section .data
phyBitMap   times 10 db 0xff            ; 0_0000 - 4_FFFF
            times 8  db 0x55            ; 5_0000 - 8_FFFF
            times 14 db 0xff            ; 9_0000 - F_FFFF
            times ((1<<17) - (1<<5)) db 0   ; 10_0000 - FFFF_FFFF
phyMapLen   equ ($ - phyBitMap) * 8
nextFreePhyPageIndex dd 0x00000050

virUserBitMap   times (1<<5) db 0xff        ; 前1MB已经分配
                times ((1<<16) - (1<<5)) db 0   ; 2G-1MB未分配
virUserMapLen   equ ($ - virUserBitMap) * 8

virCoreBitMap   times (1<<5) db 0xff        ; 2G-2G+1MB已经分配
                times ((1<<16) - (1<<5)) db 0   ; 剩余未分配
virCoreMapLen   equ ($ - virCoreBitMap) * 8

nextUserFreeVirPageIndex dd 0x000000ff
nextCoreFreeVirPageIndex dd 0x000000ff    ; 分配所得的页地址，还要再加上0x8000_0000才是真实的内核线性地址

noFreeMemMsg    db ' Sorry, there is no free space to alloc', 0xd,0xa,0
wrongSizeMsg    db ' The require size is zero, alloc memory failed',0xd,0xa,0
