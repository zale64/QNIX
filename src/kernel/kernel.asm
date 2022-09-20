[bits 32]

extern cstart 

section .text
global _start
_start:
    mov ebx, 0xb8000
    mov byte [ebx+120], 'P'
    mov byte [ebx+121], 0x84 
    call cstart 
    hlt
