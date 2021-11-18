#include "kvm/cpu.h"

#include <stdlib.h>

void cpu__reset(struct cpu *self)
{
    self->regs.eip = 0x000fff0UL;
    self->regs.eflags = 0x0000002UL;
}

struct cpu *cpu__new(void)
{
    return calloc(1, sizeof(struct cpu));
}
