#	
#	bximage -func=create -hd=46 -imgmode=flat -sectsize=512 $@
#	ld $^ -m elf_i386 -static -o $@ -Ttext $(KENTRY) -M > $(BUILDDIR)map
#

#KENTRY=0x80010000
KENTRY=0x00010000

CURRENT=.
SRCDIR:=$(CURRENT)/src
BOOTDIR:=$(SRCDIR)/boot/
KERNELDIR:=$(SRCDIR)/kernel/
BUILDDIR:=$(CURRENT)/build/
INCDIR:=$(SRCDIR)/include/

KCSRC =$(notdir $(wildcard $(KERNELDIR)*.c)) # 获取所有c语言文件
KASRC =$(notdir $(wildcard $(KERNELDIR)*.asm)) # 获取所有汇编文件
OBJS =$(BUILDDIR)kernel/kernel.o
OBJS0 =$(patsubst %.asm, $(BUILDDIR)kernel/%.o, $(KASRC))
OBJS0 +=$(patsubst %.c, $(BUILDDIR)kernel/%.o, $(KCSRC))
OBJS1 :=$(filter-out $(BUILDDIR)kernel/kernel%, $(OBJS0))
OBJS +=$(OBJS1)

CFLAGS:= -m32\
		 -O0\
		 -Qn\
		 -static\
		 -nostdlib\
		 -nostdinc\
		 -nodefaultlibs\
		 -fno-pie\
		 -fno-pic\
		 -fno-asynchronous-unwind-tables\
		 -mpreferred-stack-boundary=2\
		 -fno-stack-protector\
		 -fomit-frame-pointer\
		 -fno-builtin\
		 -masm=intel\

LDFLAGS:=-m elf_i386 -static -Ttext $(KENTRY)
ifeq ($(shell uname), Linux)
	BOCHS=bochs -q -f bochs/linux/bochsrc
	BOCHSGDB=bochsgdb -q -f bochs/linux/bochsrcgdb
	BXFLAG=-hd -mode=flat -size=5
else
	BOCHS=bochsdbg -q -f bochs/win/bochsrc.bxrc
	BOCHSGDB=bochsgdb -q -f bochs/win/bochsrcgdb.bxrc
	BXFLAG=-func=create -hd=5 -imgmode=flat -sectsize=512
endif

.PHONY:test clean vmdk bochs qemu qemudbg qnix

# 处理boot && loader汇编
$(BUILDDIR)boot/%.bin:$(BOOTDIR)%.asm
	mkdir -p $(BUILDDIR)boot
	nasm $^ -f bin -I$(INCDIR) -o $@
# 处理kernel汇编
$(BUILDDIR)kernel/%.o:$(KERNELDIR)%.asm
	mkdir -p $(BUILDDIR)kernel
	nasm $^ -f elf32 -I$(INCDIR) -g -o $@
# 处理c语言
$(BUILDDIR)kernel/%.o:$(KERNELDIR)%.c
	mkdir -p $(BUILDDIR)kernel
	gcc $(CFLAGS) -c -I$(INCDIR) $^ -g -o $@

# 此时得到的elf文件，如果直接将elf加载入内存，在运行内核之前，必须对elf文件进行相应处理
$(BUILDDIR)kernel/kernel.bin:$(OBJS)
	mkdir -p $(BUILDDIR)kernel
	ld $^ $(LDFLAGS) -o $@ 

# 为了简化内核的操作，跳过对elf文件的相关处理，直接使用objcopy将内核拷贝至KENTRY处，便可以运行内核程序
$(BUILDDIR)kernel/system.bin:$(BUILDDIR)kernel/kernel.bin
	objcopy -O binary $^ $@

# 生成内存地址映射表
$(BUILDDIR)system.map:$(BUILDDIR)kernel/kernel.bin
	nm $< | sort > $@

$(BUILDDIR)faqn.img:$(BUILDDIR)boot/boot.bin $(BUILDDIR)boot/loader.bin $(BUILDDIR)kernel/system.bin $(BUILDDIR)system.map
	bximage $(BXFLAG) $@
	dd if=$(BUILDDIR)boot/boot.bin of=$@ bs=512 count=1 conv=notrunc
	dd if=$(BUILDDIR)boot/loader.bin of=$@ bs=512 count=10 seek=1 conv=notrunc
	dd if=$(BUILDDIR)kernel/system.bin of=$@ bs=512 count=640 seek=11 conv=notrunc

qnix:clean $(BUILDDIR)faqn.img

bochs:clean $(BUILDDIR)faqn.img
	$(BOCHS)

bochsg:clean $(BUILDDIR)faqn.img
	$(BOCHSGDB)

qemu:$(BUILDDIR)faqn.img
	qemu-system-i386 -m 32M -boot c -hda $<

qemudbg:$(BUILDDIR)faqn.img
	qemu-system-i386 -s -S -m 32M -boot c -hda $<

$(BUILDDIR)faqn.vmdk: $(BUILDDIR)faqn.img
	qemu-img convert -O vmdk $< $@

vmdk: $(BUILDDIR)faqn.vmdk

clean:
	rm -rf $(BUILDDIR)

test:
	echo $(OBJS0)
	echo $(OBJS1)
	echo $(OBJS)
