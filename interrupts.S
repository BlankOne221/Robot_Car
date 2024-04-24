
.ifndef INTERRUPTS_S
.set INTERRUPTS_S, 1

# Written by Dr. Murray / Artsem Labanau


# Important Base Registers of GIC
# Can check what each of these in the reference manuals
# Can alter anything with these base addresses

.set ICDIPTR_BASEADDR, 0xF8F01800
.set ICDICER_BASEADDR, 0xF8F01180
.set ICDDCR_BASEADDR, 0xF8F01000
.set ICDIPR_BASEADDR, 0xF8F01400
.set ICDICFR_BASEADDR, 0xF8F01C00
.set ICDISER_BASEADDR, 0xF8F01100
.set ICCPMR_BASEADDR, 0xF8F00104
.set ICCICR_BASEADDR, 0xF8F00100
.set ICCIAR_BASEADDR, 0xF8F0010C
.set ICCEOIR_BASEADDR, 0xF8F00110

# Important Base Registers of GPIO
.set GPIO_BASEADDR, 0xE000A000

# Important Base Register for GTC
.set GTC_BASEADDR, 0xF8F00200

# Base Register for LEDS
.set LEDS, 0x41210000

.text

# Disable All interrupts on the CPU-Side
disable_interrupts:
MSR cpsr_c, #0b11011111
MOV pc, lr

# Enable All interrupts on the CPU-Side
enable_interrupts:
MSR cpsr_c, #0b01011111
MOV pc, lr


# Configuring the GIC
configure_GIC:

# First three are just disabling everything

# 1. Disable the interrupt masks and any CPU's of handling interrupts (ICDIPTR and ICDICER)
LDR r0, =ICDIPTR_BASEADDR
MOV r1, #0
STR r1, [r0, #0x18] @ at id 27
STR r1, [r0, #0x34]

LDR r0, =ICDICER_BASEADDR
LDR r1, =#0x8000000
STR r1, [r0]
LDR r1, =#0x100000
STR r1, [r0, #0x04]

# 2. Disable the distributor using the Distributor Control Register (ICDDCR)
LDR r0, =ICDDCR_BASEADDR
MOV r1, #0
STR r1, [r0]

# 3. Set priority levels in the Interrupt Priority Register (ICDIPR)
# Basically the priority of the interrupt
LDR r0, =ICDIPR_BASEADDR
LDR r1, =#0x50000000 @ 0b01010..... bascially value of 10 or 10/32
STR r1, [r0, #0x18]
MOV r1, #0xA0
STR r1, [r0, #0x34] @ 20/32; 0b10100...

# 4. Configure Inerrput Processor Targets Register (ICDIPTR)
# Enabling what we disabled in step 1
LDR r0, =ICDIPTR_BASEADDR
LDR r1, =#0x1000000
STR r1, [r0, #0x18]

MOV r1, #0x1
STR r1, [r0, #0x34]

# 5. Set Interrupt Sensitivity in Interrupt Configuration Register (ICDICFR)
# Rising edge in this case
LDR r0, =ICDICFR_BASEADDR
LDR r1, =#0x7DC00000
STR r1, [r0, #0x04]

LDR r1, =#0x55555555
STR r1, [r0, #0x0C]

# 6. Enable Interrupts in the Interrupt Set-Enable Register (ICDISER)
# Just renabling the interrupt stuff
LDR r0, =ICDISER_BASEADDR
LDR r1, =#0x8000000
STR r1, [r0]

LDR r1, =#0x100000
STR r1, [r0, #0x04]

# 7. Enable all priority levels in the Interrupt Priority Mask Register (ICCPMR)
LDR r0, =ICCPMR_BASEADDR
MOV r1, #0xFF
STR r1, [r0]

# 8. Enable Interrupts in the CPU Interface Control Register (ICCICR)
# Both secure and non secure
LDR r0, =ICCICR_BASEADDR
MOV r1, #0b11
STR r1, [r0]

# 9. Enable Distributor in the Ditributor Control Register (ICDDCR)
LDR r0, =ICDDCR_BASEADDR
MOV r1, #0b11
STR r1, [r0]

MOV pc, lr


# Interrupt Service Request Handler
IRQ_Handler:
LDR r0, =ICCIAR_BASEADDR
LDR r1, [r0]

# Did we enter the handler becuase of IRQ ID 27?
CMP r1, #27
BEQ GTC_Int

B endIRQ_Handler

	# This either counts up or down using the buttons
	GTC_Int:
	PUSH {r4}

	# Controlled via the count_DI global variable
	LDR r3, =count
	LDR r4, =count_DI
	LDR r2, [r3]
	LDR r4, [r4]
	ADD r2, r2, r4
	STR r2, [r3]

	LDR r3, =GTC_BASEADDR
	MOV r2, #1
	STR r2, [r3, #0x0C] @ clear the bit that cuased us to enter here

	POP {r4}
	B endIRQ_Handler


	endIRQ_Handler:
	LDR r0, =ICCEOIR_BASEADDR
	STR r1, [r0] @ interrupt 52 was handled

MOV pc, lr

.endif
