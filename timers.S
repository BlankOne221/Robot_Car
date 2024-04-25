.ifndef TIMERS_S
.set TIMERS_S, 1
# Created by Dr. Murray / Artsem Labanau

.set GTC_BASEADDR, 0xF8F00200

.text

configure_GTC:

LDR r0, =GTC_BASEADDR


# set the comparator value to make a 1-second timer interrupt
# time interval / T_GTC = comparator + 1
# 1s / (1/1.302MHz) = comparator + 1 = 1,302,083; comparator = 1,302,084
LDR r1, =1302084
STR r1, [r0, #0x10] @ comparator register
STR r1, [r0, #0x18] @ auto incrementor
MOV r1, #0
STR r1, [r0, #0x14]


# set the global timer control register
# auto-increment on
# enable interrupts
# enable comparator
# enable timer
# we can choose the global timer's frequency by taking f_CPU3x2x / (prescaler + 1)
# the f_CPU3x2x = f_CPU/2, f_CPU = 666.666 MHz, f_CPU3x2x = 333.333 MHz
# choosing a prescaler = 255; f_GTC = 333.333 MHz / (255 + 1) = 1.302 MHz

LDR r1, =0xFF0E
STR r1, [r0, #0x08]
MOV pc, lr

# Starts the timer
start_timer:
LDR r0, =GTC_BASEADDR

LDR r1, [r0, #0x08]
ORR r1, r1, #0x01
STR r1, [r0, #0x08]
MOV pc, lr


# Ends the timer
end_timer:
LDR r0, =GTC_BASEADDR

LDR r1, [r0, #0x08]
MVN r2, #1
AND r1, r1, r2
STR r1, [r0, #0x08]
MOV pc, lr


# this makes a clock of 1 second and then clears it
# can be implemented to make multiple seconds
clock_timer:
BL start_timer

	timer_loop:
	LDR r0, =GTC_BASEADDR
	LDR r1, [r0, #0x214]
	CMP r1, #0x13
	BGE check_2
	B timer_loop

	check_2:
	BL end_timer
	LDR r0, =GTC_BASEADDR
	MOV r1, #0
	STR r1, [r0, #0x210]
	STR r1, [r0, #0x214]

BX lr


