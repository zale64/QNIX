#ifndef PAGE_H
#define PAGE_H
#include "type.h"

// 返回gdtPtr保存全局描述符长度以及全局描述符基地址
//extern u16* setupPage();
extern void setupPage(u8* buf);

#endif
