ifeq ($(strip $(V)),)
	E = @echo
	Q = @
else
	E = @\#
	Q =
endif
export E Q

PROGRAM	= kvm

OBJS	+= blk-virtio.o
OBJS	+= cpuid.o
OBJS	+= early_printk.o
OBJS	+= interrupt.o
OBJS	+= ioport.o
OBJS	+= kvm.o
OBJS	+= main.o
OBJS    += mmio.o
OBJS	+= pci.o
OBJS	+= util.o

DEPS	:= $(patsubst %.o,%.d,$(OBJS))

# Exclude BIOS object files from header dependencies.
OBJS	+= bios.o
OBJS	+= bios/bios.o

uname_M := $(shell uname -m | sed -e s/i.86/i386/)
ifeq ($(uname_M),i386)
	DEFINES += -DCONFIG_X86_32
ifeq ($(uname_M),x86_64)
	DEFINES += -DCONFIG_X86_64
endif
endif

CFLAGS	+= $(CPPFLAGS) -Iinclude -Os -g

WARNINGS += -Werror
WARNINGS += -Wall
WARNINGS += -Wcast-align
WARNINGS += -Wformat=2
WARNINGS += -Winit-self
WARNINGS += -Wmissing-declarations
WARNINGS += -Wmissing-prototypes
WARNINGS += -Wnested-externs
WARNINGS += -Wno-system-headers
WARNINGS += -Wold-style-definition
WARNINGS += -Wredundant-decls
WARNINGS += -Wsign-compare
WARNINGS += -Wstrict-prototypes
WARNINGS += -Wundef
WARNINGS += -Wvolatile-register-var
WARNINGS += -Wwrite-strings

CFLAGS	+= $(WARNINGS)

all: $(PROGRAM)

$(PROGRAM): $(DEPS) $(OBJS)
	$(E) "  LINK    " $@
	$(Q) $(CC) $(OBJS) -o $@

$(DEPS):
%.d: %.c
	$(Q) $(CC) -M -MT $(patsubst %.d,%.o,$@) $(CFLAGS) $< -o $@

$(OBJS):

%.o: %.c
	$(E) "  CC      " $@
	$(Q) $(CC) -c $(CFLAGS) $< -o $@

#
# BIOS assembly weirdness
#
BIOS_CFLAGS += -m32
BIOS_CFLAGS += -march=i386
BIOS_CFLAGS += -mregparm=3

bios.o: bios/bios-rom.bin
bios/bios.o: bios/bios.S bios/bios-rom.bin
	$(Q) $(CC) -c $(CFLAGS) bios/bios.S -o bios/bios.o

bios/bios-rom.bin: bios/bios-rom.S bios/e820.c
	$(E) "  CC      " $@
	$(Q) $(CC) -include code16gcc.h $(CFLAGS) $(BIOS_CFLAGS) -c -s bios/e820.c -o bios/e820.o
	$(Q) $(CC) $(CFLAGS) $(BIOS_CFLAGS) -c -s bios/bios-rom.S -o bios/bios-rom.o
	$(E) "  LD      " $@
	$(Q) ld -T bios/rom.ld.S -o bios/bios-rom.bin.elf bios/bios-rom.o bios/e820.o
	$(E) "  OBJCOPY " $@
	$(Q) objcopy -O binary -j .text bios/bios-rom.bin.elf bios/bios-rom.bin
	$(E) "  NM      " $@
	$(Q) cd bios && sh gen-offsets.sh > bios-rom.h && cd ..

check:$(PROGRAM)
	$(MAKE) -C tests
	./$(PROGRAM) tests/pit/tick.bin
.PHONY: check

clean:
	$(E) "  CLEAN"
	$(Q) rm -f bios/*.bin
	$(Q) rm -f bios/*.elf
	$(Q) rm -f bios/*.o
	$(Q) rm -f bios/bios-rom.h
	$(Q) rm -f $(DEPS) $(OBJS) $(PROGRAM)

.PHONY: clean

KVM_DEV	?= /dev/kvm

$(KVM_DEV):
	$(E) "  MKNOD " $@
	$(Q) mknod $@ char 10 232

devices: $(KVM_DEV)
.PHONY: devices

# Deps
-include $(DEPS)
