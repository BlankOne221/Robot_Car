*
 * main.S
 *
 *  Created on: Apr 4, 2022
 *      Author: jacob
 */

# WARNING: DO NOT HAVE MOTORS DIRECTLY PLUGGED INTO BLACKBOARD
#          WHEN THE BOARD IS POWERED UP AND BEFORE PROGRAMMING THE BOARD.
# 		   THE H-BRIDGE WILL CREATE A SHORT-CIRCUIT AND YOU WILL DAMAGE IT.
#
# 		   YOU CAN CONNECT THE MOTORS AFTER YOU HAVE UPLOADED THE PROGRAM TO YOUR BOARD
#
#		   IF YOU SMELL BURNING, SHUT THE POWER OFF ON YOUR BOARD IMMEDIATELY TO PREVENT DAMAGE.
#
#		   This issue should largely be absent if you are using the DHB1 PMOD.
#
#		   However, still know that if you leave the DHB1 module and the battery connected,
#		   the motors will spin at full speed prior to programming your board.

.include "../src/robomal.S"
.include "../src/GPIO.S"
.include "../src/esp32.S"
.include "../src/UART.S"
.include "../src/RobotMotors.S"
.include "../src/timers.S"

.set SW_BASEADDR, 0x41220000
.set BTN_BASEADDR, 0x41200000

.global main

.data

# jump table for various modes
Mode: .word Nothing, Autonomous, Programmable, RC, line_following

.text

main:

	# Setup Motor 0 (connected to top row of PMODC)
	LDR r1, =MOTOR_0_BASEADDR
	BL setup_motor

	# Setup Motor 1 (connected to bottom row of PMODC)
	LDR r1, =MOTOR_1_BASEADDR
	BL setup_motor

	# set up all timers and interrupts
	# place all of my setup here
	BL configure_GTC

	# setup station commands
	BL setup_esp32
	BL setupSVNSEG
	BL timer


	whileOne:

		# value is in r1
		BL receive_char_UART0
		MOV r0, r1
		BL convert_hex
		MOV r1, r0


		Modes:

			# branching to correct mode using switch state
			LDR r0, =Mode
			LDR r2, [r0, r1, LSL #2]
			BX r2

			Nothing:

				# Program will wait for a switch to choose a mode

				B endmode

			# Agree on a code here
			Autonomous:

				# Autonomous mode, runs a default program

				LDR r0, =ROBO_Instructions
				# Store the instruction from the keypad to the label with iterator
				MOV r5, #0x42FF
				MOV r2, #0
				STR r5, [r0, r2, LSL #1]

				MOV r5, #0x43FF
				MOV r2, #1
				STR r5, [r0, r2, LSL #1]

				# can keep going with how many instructions you want
				# just end it with the halt instruction
				MOV r5, #0x3300
				MOV r2, #7
				STR r5, [r0, r2, LSL #1]

				BL runROBO_Program

				B endmode

			# The mode works !!!!
			Programmable:

				# Programmable mode, you send instructions
				# then it excutes all of them
				# 10 instructions
				MOV r4, #0
				commands:

				# sending in the string of bytes

	   			BL recieve_string_UART0
	   			# assume data is in r1
				BL writeSVNSEG
				# data now in r5
				MOV r5, r1

				# check if 0x33 on keypad entered
				CMP r5, #0x3300
				BEQ commands_end

				LDR r0, =ROBO_Instructions
				# Store the instruction from the keypad to the label with iterator
				STR r5, [r0, r4, LSL #1]

				# iterator incrementor
				ADD r4, r4, #1
				BL timer_calc

				B commands

				commands_end:

				BL runROBO_Program

				B endmode


			# Should work fine
			RC:
				#Send one instruction and it excutes it

				# sending in the string of bytes

	   			BL recieve_string_UART0
	   			# assume data is in r1
				BL writeSVNSEG

				# data now in r5
				MOV r5, r1

				LDR r0, =ROBO_Instructions
				# Store the instruction from the keypad to the label with iterator
				MOV r2, #0
				STR r5, [r0, r2, LSL #1]

				# termination code after one instruction
				MOV r5, #0x3300
				MOV r2, #1
				STR r5, [r0, r2, LSL #1]

				BL runROBO_Program

				B endmode

			line_following:

				# follows the black lines
				# connor got this
				B endmode


			endmode:



	B whileOne


.end
