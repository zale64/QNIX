; BIOS_INT  0x0_0000 - 0x0_03ff     (1024)
; BIOS_DATA 0x0_0400 - 0x0_04ff     (256) 
; AVA       0x0_0500 - 0x0_7bff     ()
; ENTRY     0x0_7c00 - 0x0_7dff     (512) 
; AVA       0x0_7e00 - 0x9_fbff
;           0x9_fc00 - 0x9_ffff     (1024)
;           0xa_0000 - 0xa_ffff
;           0xb_0000 - 0xb_7fff
; TEXT      0xb_8000 - 0xb_ffff
;           0xc_0000 - 0xc_7fff
;           0xc_8000 - 0xe_ffff
;           0xf_0000 - 0xf_ffef
; BIOS_ADDR 0xf_fff0 - 0xf_ffff


; ------------------------------------------------------------------
; ������ַ����
; ------------------------------------------------------------------
KERNEL_ADDR     equ 0x00010000      ;�ں˵ļ��ص�ַ
LOADER_ADDR     equ 0x7e00          ;Loader�ļ��ص�ַ

PAGE_DIR_ADDR   equ 0x9000          ;�ں�ҳĿ¼��ַ
PAGE_TAB_ADDR   equ 0xa000          ;�ں˵�һ��ҳ����ַ
PAGE_SIZE       equ 0x1000          ;ҳ��С