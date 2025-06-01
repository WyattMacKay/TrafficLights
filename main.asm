.data
welcome_msg: .asciiz "Welcome to the traffic light simulator.\n1. Start simulator\n2. Set custom speed limit\n3. Set green light time\nEnter your selection: "
invalid_input: .asciiz "Invalid input...\n"
ask_speed_limit: .asciiz "Enter new speed limit: "
ask_green_time: .asciiz "Enter new green light time: "

.text
.globl init

# ------------- Program initialization and defaults ---------------
init:
li $s0, 60 #default speed limit
li $s1, 10 #default green light time

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
move $s0, $v0

#Input is accepted if new limit is greater than 0
bgt $s0, $zero, main

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
move $s1, $v0

#Input is accepted if new limit is greater than 0
bgt $s1, $zero, main

#Input is invalid, print invalid message then try again
li $v0, 4
la $a0, invalid_input
syscall
j set_green_time

# -------------- Starting the simulator ------------------
start_simulator:
nop