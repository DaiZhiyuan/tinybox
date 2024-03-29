#include "kvm/kvm.h"

#include "kvm/util.h"

#include <sys/ioctl.h>
#include <stdlib.h>
#include <assert.h>

#define CPUID_FUNC_PERFMON 0x0A

#define	MAX_KVM_CPUID_ENTRIES 100

static void filter_cpuid(struct kvm_cpuid2 *kvm_cpuid)
{
    unsigned int i;

    /*
     * Filter CPUID functions that are not supported by the hypervisor.
     */
    for (i = 0; i < kvm_cpuid->nent; i++) {
        struct kvm_cpuid_entry2 *entry = &kvm_cpuid->entries[i];

        switch (entry->function) {
        case CPUID_FUNC_PERFMON:
            entry->eax = 0x00; /* disable it */
            break;
        default:
            /* Keep the CPUID function as -is */
            break;
        };
    }
}

void kvm__setup_cpuid(struct kvm *self)
{
	struct kvm_cpuid2 *kvm_cpuid;

    kvm_cpuid = calloc(1, sizeof(*kvm_cpuid) + MAX_KVM_CPUID_ENTRIES * sizeof(*kvm_cpuid->entries));

    kvm_cpuid->nent = MAX_KVM_CPUID_ENTRIES;

    if (ioctl(self->sys_fd, KVM_GET_SUPPORTED_CPUID, kvm_cpuid) < 0)
        die_perror("KVM_GET_SUPPORTED_CPUID failed");

    filter_cpuid(kvm_cpuid);

	if (ioctl(self->vcpu_fd, KVM_SET_CPUID2, kvm_cpuid) < 0)
		die_perror("KVM_SET_CPUID2 failed");

    free(kvm_cpuid);
}
