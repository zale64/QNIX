#ifndef GLOBAL_H
#define GLOBAL_H

// 段选择子
#define CODE_SEL        (1 << 3)
#define DATA_SEL        (2 << 3)
#define STCK_SEL        (3 << 3)
#define DISP_SEL        (4 << 3)

// 页目录以及第一个页表的物理地址
#define PAGE_DIR_ADDR   0x8000
#define PAGE_TAB_ADDR   0x9000

#define PAGE_SIZE       0x1000

#endif
