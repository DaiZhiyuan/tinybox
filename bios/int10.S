#include <kvm/bios.h>
#include <kvm/assembly.h>

	.org 0
#ifdef CONFIG_X86_64
	.code64
#else
	.code32
#endif
GLOBAL(bios_int10)
	.incbin "bios/int10-real.bin"
GLOBAL(bios_int10_end)
