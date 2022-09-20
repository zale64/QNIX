# <center>`BIOS int`中断使用说明</center>
1. `int 0x13`硬盘操作
>$注意事项$ ：<mark style=background-color:red>涉及到任何寄存器赋值，都必须完整</mark>
```asm
    ; al = 读写硬盘扇区的个数
    ; ah = 功能号(0x02读硬盘，0x03写硬盘...) 
    ; cl = bit0~5起始扇区的索引，bit6~7磁道号高两位
    ; ch = 磁道号的低8位
    ; dl = 驱动器编号(0x00~0x7f代表软盘，0x80~0xff代表硬盘)
    ; dh = 磁头号
    ; es:bx = 目的内存地址
    ; 示例：读1号硬盘的1扇区，一次读10个扇区，到内存0x7e00处
    mov ax, 0x020a
    mov bx, 0x7e00
    mov cx, 0x0001
    mov dx, 0x0080
    int 0x13
    ; 示例中的cx/dx，不能如以下赋值
    ; mov cx, 0x1
    ; mov dx, 0x80  
```
