#ifndef KVM__PCI_H
#define KVM__PCI_H

/* some known offsets and register names */
#define PCI_CONFIG_ADDRESS  0xcf8
#define PCI_CONFIG_DATA     0xcfc

struct pci_config_address {
    unsigned                zeros           : 2;            /* 1  .. 0  */
    unsigned                register_number : 6;            /* 7  .. 2  */
    unsigned                function_number : 3;            /* 10 .. 8  */
    unsigned                device_number   : 5;            /* 15 .. 11 */
    unsigned                bus_number      : 8;            /* 23 .. 16 */
    unsigned                reserved        : 7;            /* 30 .. 24 */
    unsigned                enable_bit      : 1;            /* 31       */
};

void pci__init(void);

#endif /* KVM__PCI_H */
