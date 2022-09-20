; ------------------------------------------------------------------
; 创建段描述符的宏定义
; ------------------------------------------------------------------
%macro CREATE_DESC 3    ;32bits--addr_base 20bits--addr_limit 16bits--attr
    dw (%2 & 0xffff)
    dw (%1 & 0xffff)
    db (%1 >> 16) & 0xff
    dw (((%2 >> 8) & 0xf00) | (%3))
    db (%1 >> 24) & 0xff
%endmacro

; ------------------------------------------------------------------
; 段描述符的一系列属性
; ------------------------------------------------------------------
G_BYTE          equ (0 << 15)
G_PAGE          equ (1 << 15)
OP_SIZE_16      equ (0 << 14)
OP_SIZE_32      equ (1 << 14)
L_FLAG          equ (0 << 13)
L_FLAG_64       equ (1 << 13)
AVL_0           equ (0 << 12)
AVL_1           equ (1 << 12)
P_0             equ (0 <<  7)
P_1             equ (1 <<  7)
DPL_0           equ (0 <<  5)
DPL_1           equ (1 <<  5)
DPL_2           equ (2 <<  5)
DPL_3           equ (3 <<  5)
IS_SYS          equ (0 <<  4)
IS_NOR          equ (1 <<  4)
DATA_RO         equ (0)
DATA_RW         equ (2)
STACK_RO        equ (4)
STACK_RW        equ (6)
CODE_EXE        equ (8)
CODE_REXE       equ (10)
CODE_CONEXE     equ (12)
CODE_CONREXE    equ (14)
