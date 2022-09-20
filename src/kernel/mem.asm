[bits 32]

%include "address.inc"

section .text

extern print

global alloc

; u32* alloc(u32 size) �ں��ڴ����
; input:    size(��Ҫ�����ڴ�Ĵ�С)
; ouput:    eax(���ط����ڴ���׵�ַ[�����ַ])
; �����ڴ���ҳpageΪ��λ
; ͨ��cs�����ѡ���ӵ��������жϣ����û��������ں�
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
    mov ecx, eax    ; ������Ҫ�����ҳ��Ŀ

    ; �ȷ���һ��ҳ����Ϊ�����ķ���ֵ
    call onePhyPage ; ����������ַ��Ӧ�������ַ��׼�����ҳ����
    mov edx, eax
    xor esi, esi    ; ����
    mov si, cs      ; ��ȡ�����ѡ����
    and si, 0x3     ; ��ȡѡ��������
    cmp si, 0x3     ; �ж��Ƿ�Ϊ�û�����
    jl .is_core
    or edx, 0x7
    mov eax, 1
    jmp .next
.is_core:
    or edx, 0x3     ; �ں˿ռ���Ҫ����ҳ����
    mov eax, 0
.next:
    call oneVirPage 
    push eax        ; ����һ��ҳ���׵�ַѹ��ջ�У���Ϊ����ֵ
    call fillPage   ; ���ҳĿ¼�Լ�ҳ��

    dec ecx         ; ����ʣ�µ��ڴ�
.s3:
    cmp ecx, 0
    jz .s4          ; ������ϣ��˳�����
    call onePhyPage ; ����������ַ��Ӧ�������ַ��׼�����ҳ����
    mov edx, eax
    cmp si, 0x3     ; �ж��ռ�����(�û��ռ� or �ں˿ռ�)
    jl .s5      
    or edx, 0x7     ; ��Ҫ����ҳ����
    mov eax, 1
    jmp .s6
.s5:
    or edx, 0x3     ; ��Ҫ����ҳ����
    mov eax, 0
.s6:
    call oneVirPage 
    call fillPage   ; ���ҳĿ¼�Լ�ҳ��   
    loop .s3
.s4:    
    pop eax
;    pop edx
;    pop ecx
;    pop ebx
    leave
    ret

; �����ַ�������ַ��ӳ��
; ���ҳĿ¼�Լ�ҳ��
; input:    eax(�����ַ) edx(ҳ����)[��12bit���Ա�ʾ����, bit2��ʾ�ռ�����0--core 1--user]
fillPage:
    push eax
    push ebx
    push ecx
    push esi
    push edi
    push edx

    mov esi, edx
    and esi, 0x4    ; esi �б����ſռ�����

    mov edi, eax    ; edi �б����������ַ
    mov ebx, PAGE_DIR_ADDR
    shr eax, 22
    shl eax, 2
    mov ecx, eax
    add ebx, ecx
    ; ��ȡҳĿ¼��
    mov edx, dword [ebx]
    ; �ж�ҳĿ¼���Ƿ����
    mov esi, edx
    and edx, 0x1
    cmp edx, 0
    jnz .s1
    ; ҳĿ¼�����
    call onePhyPage ; ����һҳ�����ַ
    or eax, esi 
    mov dword [ebx], eax
    mov esi, eax
.s1:; ҳĿ¼�����
    and esi, 0xfffff000 ; ��ȡҳ��������ַ
    mov eax, edi ; ���»�������ַ��������λҳ���е�ƫ�Ƶ�ַ
    mov ecx, eax    ; �ȱ��������ַ���Ա�����õ�ַ����
    shr eax, 12
    and eax, 0x3ff
    shl eax, 2
    or esi, eax
    mov ebx, esi    ; ���ҳ����ĵ�ַ
    ; ��ҳ��������
    pop edx
    mov dword [ebx], edx

    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret

; ����һ������ҳ
; output:   eax(���������ַ)
onePhyPage:
    push ebx
    push ecx

    mov ebx, phyBitMap
    mov eax, dword [nextFreePhyPageIndex]
    mov ecx, phyMapLen
.s1:
    bts [ebx], eax
    jnc .s2         ; �ж�EFLAGS��־�Ĵ�����CFλ�Ƿ�Ϊ0(btsָ�eax���ı��ش��͸�CFλ��0--���У�1--ռ��)
    inc eax
    cmp eax, ecx
    jl .s1          ; eaxС�����ɷ�����ڴ�

    ; ����ʧ�ܣ��Ѿ�û�пռ���Է���
    mov eax, noFreeMemMsg
    push eax
    call print
    hlt

    ; �����ڴ�ɹ�
    ; ��eaxд��nextFreePhyPageIndex
.s2:
    mov dword [nextFreePhyPageIndex], eax
    shl eax, 12

    pop ecx
    pop ebx
    ret

; ����һ������ҳ
; input:    eax(�ں�-0 or �û�-1)
; output:   eax(���������ַ)
; ��Ҫ�ж����ں�����ռ䣬�����û�����ռ�
; �ں�(0x8000_0000 ~ 0xffff_ffff)
; �û�(0x0000_0000 ~ 0x7fff_ffff)
oneVirPage:
    push ebx
    push ecx
    push edx

    mov edx, eax
    cmp edx, 0
    jz .core

    ; �û�Ҫ�����ڴ�
    mov ebx, virUserBitMap
    mov eax, dword [nextUserFreeVirPageIndex]
    mov ecx, virUserMapLen
    jmp .s1

.core:  ;�ں�Ҫ�����ڴ�
    mov ebx, virCoreBitMap
    mov eax, dword [nextCoreFreeVirPageIndex]
    mov ecx, virCoreMapLen
.s1:
    bts [ebx], eax
    jnc .s2         ; �ж�EFLAGS��־�Ĵ�����CFλ�Ƿ�Ϊ0(btsָ�eax���ı��ش��͸�CFλ��0--���У�1--ռ��)
    inc eax
    cmp eax, ecx
    jl .s1          ; eaxС�����ɷ�����ڴ�

    ; ����ʧ�ܣ��Ѿ�û�пռ���Է���
    mov eax, noFreeMemMsg
    push eax
    call print
    hlt
    
.s2:; �ҵ����е�ҳ
    cmp edx, 0
    jnz .s3
    ; �ں�
    mov dword [nextCoreFreeVirPageIndex], eax
    add eax, 0x80000   
    jmp .s4
.s3:; �û�
    mov dword [nextUserFreeVirPageIndex], eax
.s4:
    shl eax, 12     ; ҳ���� * PAGE_SIZE
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

virUserBitMap   times (1<<5) db 0xff        ; ǰ1MB�Ѿ�����
                times ((1<<16) - (1<<5)) db 0   ; 2G-1MBδ����
virUserMapLen   equ ($ - virUserBitMap) * 8

virCoreBitMap   times (1<<5) db 0xff        ; 2G-2G+1MB�Ѿ�����
                times ((1<<16) - (1<<5)) db 0   ; ʣ��δ����
virCoreMapLen   equ ($ - virCoreBitMap) * 8

nextUserFreeVirPageIndex dd 0x000000ff
nextCoreFreeVirPageIndex dd 0x000000ff    ; �������õ�ҳ��ַ����Ҫ�ټ���0x8000_0000������ʵ���ں����Ե�ַ

noFreeMemMsg    db ' Sorry, there is no free space to alloc', 0xd,0xa,0
wrongSizeMsg    db ' The require size is zero, alloc memory failed',0xd,0xa,0
