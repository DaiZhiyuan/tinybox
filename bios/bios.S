#include <kvm/assembly.h>

    .org 0
#ifdef CONFIG_X86_64
    .code64
#else
    .code32
#endif

GLOBAL(bios_rom)
    .incbin "bios/bios-rom.bin"
END(bios_rom)
