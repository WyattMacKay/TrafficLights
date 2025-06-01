.data
welcome_msg: .asciiz "Welcome to the traffic light simulator.\n1. Start simulator\n2. Set custom speed limit\n3. Set green light time\nEnter your selection: "
invalid_input: .asciiz "Invalid input...\n"
ask_speed_limit: .asciiz "Enter new speed limit: "
ask_green_time: .asciiz "Enter new green light time: "

.text
.globl init

#LIGHTS STATES (stored in $s0):
#0. Simulation has not started
#1. NS lights green, EW lights red
#2. NS lights yellow, EW lights red
#3. NS lights red, EW lights about to be green
#4. NS lights red, EW lights green
#5. NS lights red, EW lights yellow
#6. NS lights about to be green, EW lights red

#CROSS WALK STATES (stored in $s1)
#0. No cross walks are active (can be active during any light state)
#1. NS cross walk is active (can only be active during light state 1)
#2. EW cross walk is active (can only be active during light state 4)

# ------------- Program initialization and defaults ---------------
init:
li $s0, 0 #lights state set to 0 (Simulation has not started)
li $s1, 0 #crosswalk state to 0
li $s2, 60 #default speed limit
li $s3, 10 #default green light time

# ------------ Gather introductory information for the simulator ----------------
main:
#Print welcome message and get user input
li $v0, 4
la $a0, welcome_msg
syscall
li $v0, 5
syscall
addi $t0, $v0, -1

#Check input
beq $t0, $zero, start_simulator
addi $t0, $t0, -1
beq $t0, $zero, set_speed_limit
addi $t0, $t0, -1
beq $t0, $zero, set_green_time

#Input is invalid, print invalid message then try again
li $v0, 4
la $a0, invalid_input
syscall
j main

# -------------- Setting the custom speed limit ------------------
set_speed_limit:
li $v0, 4
la $a0, ask_speed_limit
syscall
li $v0, 5
syscall
move $s2, $v0

#Input is accepted if new limit is greater than 0
bgt $s2, $zero, main

#Input is invalid, print invalid message then try again
li $v0, 4
la $a0, invalid_input
syscall
j set_speed_limit

# -------------- Setting the custom green light time ------------------
set_green_time:
li $v0, 4
la $a0, ask_green_time
syscall
li $v0, 5
syscall
move $s3, $v0

#Input is accepted if new limit is greater than 0
bgt $s3, $zero, main

#Input is invalid, print invalid message then try again
li $v0, 4
la $a0, invalid_input
syscall
j set_green_time

# -------------- Starting the simulator ------------------
start_simulator:
li $s0, 1 #set program state to 1 (NS green, EW red)