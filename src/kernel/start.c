#include "global.h"
#include "type.h"
#include "console.h"
#include "page.h"
#include "mem.h"

u16     gdtLen         ;
u32     gdtBase        ;
u8      gdtPtr[6]      ;
void cstart() {
    clear();
    print("cstart begin\n\r");
    print("\n\rHello, this is QNIX\r\n");

    print("Now, test setupPage\n\r");
    setupPage(gdtPtr);
    print("Ok, test setupPage done\n\r");

    gdtLen = *gdtPtr;
    gdtBase = *(u32*)(gdtPtr + 1);

    print("Now, test alloc\n\r");
    u32* cstr = alloc(10);
    print("Ok, test alloc done\n\r");

    print("cstart end\n\r");
/*----------------  by zalechain 2022-09-15  ---------------------
    u16 gdtLen = *(u16*)gdtPtr;
    u32 gdtBase = *(u32*)(gdtPtr + 2);
------------------  by zalechain 2022-09-15  -------------------*/
}
