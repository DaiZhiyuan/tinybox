#define IO_PIC		0x20
#define IRQ_OFFSET	32
#define IO_PIT		0x40
#define TIMER_FREQ	1193182
#define TIMER_DIV(x)	((TIMER_FREQ+(x)/2)/(x))

/*
 * 0xe0..0xef are "motherboard specific", but 0xe9 is
 * used for Bochs debugging and 0xed is the Phoenix-reserved
 * delay port
 */


#define DBG_PORT    0xe0

#define TEST_COUNT	0x0200

    .code16gcc
    .text
    .globl	_start
    .type	_start, @function
_start:
/*
 * fill up noop handlers
 */
    xorw    %ax, %ax
    xorw    %di, %di
    movw	%ax, %es
    movw    $256, %cx
fill_noop_idt:
    movw    $noop_handler, %es:(%di)
    movw    %cs, %es:2(%di)
    add     $4, %di
    loop    fill_noop_idt

set_idt:
    movw	$timer_isr, %es:(IRQ_OFFSET*4)
    movw	%cs, %es:(IRQ_OFFSET*4+2)

set_pic:
    # ICW1
    mov	$0x11, %al
    mov	$(IO_PIC), %dx
    out	%al,%dx
    # ICW2
    mov	$(IRQ_OFFSET), %al
    mov	$(IO_PIC+1), %dx
    out	%al, %dx
    # ICW3
    mov	$0x00, %al
    mov	$(IO_PIC+1), %dx
    out	%al, %dx
    # ICW4
    mov	$0x3, %al
    mov	$(IO_PIC+1), %dx
    out	%al, %dx

set_pit:
    # set 8254 mode
    mov	$(IO_PIT+3), %dx
    mov	$0x34, %al
    outb	%al, %dx
    # set 8254 freq 1000Hz
    mov	$(IO_PIT), %dx
    movb	$(TIMER_DIV(1000) % 256), %al
    outb	%al, %dx
    movb	$(TIMER_DIV(1000) / 256), %al
    outb	%al, %dx

enable_irq0:
    mov	$0xfe, %al
    mov	$(IO_PIC+1), %dx
    out	%al, %dx
    sti
loop:
    1:
    jmp	1b

test_ok:
    mov	$0x3f8,%dx
    cs lea	msg, %si
    mov	$(msg_end-msg), %cx
    cs rep/outsb
    /* not a valid port to force exit */
    outb    %al, $DBG_PORT

timer_isr:
    cli
	pushaw
	pushfw
	mov	$0x3f8,%dx
	mov	$0x2e, %al	# .
	out	%al,%dx
	decw	count
	jz	test_ok
	popfw
	popaw
	iretw

noop_handler:
    iretw

count:
	.word	TEST_COUNT

msg:
	.asciz "\nTEST OK\n"
msg_end:
