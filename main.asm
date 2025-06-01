.data
welcome_msg: .asciiz "Welcome to the traffic light simulator.\n1. Start simulator\n2. Set custom speed limit\n3. Set green light time\nEnter your selection: "
invalid_input: .asciiz "Invalid input...\n"
ask_speed_limit: .asciiz "Enter new speed limit: "
ask_green_time: .asciiz "Enter new green light time: "
new_line: .asciiz "\n"

temp_print_state: .asciiz "Current state is: "

.text
.globl init

#LIGHTS STATES (stored in $s0):
#0. NS lights green, EW lights red
#1. NS lights yellow, EW lights red
#2. NS lights red, EW lights about to be green
#3. NS lights red, EW lights green
#4. NS lights red, EW lights yellow
#5. NS lights about to be green, EW lights red

#CROSS WALK STATES (stored in $s1)
#0. No cross walks are active (can be active during any light state)
#1. NS cross walk is active (can only be active during light state 1)
#2. EW cross walk is active (can only be active during light state 4)

# ------------- Program initialization and defaults ---------------
init:
li $s0, 0 #lights state set to 0
li $s1, 0 #crosswalk state to 0
li $s2, 60 #default speed limit
li $s3, 3000 #default green light time
li $s4, 0 #start time of simulator cycle
li $s5, 0 #current time

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
beq $t0, $zero, main_simulator
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
main_simulator:
#get the time for the start of cycle
li $v0, 30
syscall
move $s4, $a0

rem $t1, $s0, 3 #if $t1 is 0, its a green light timer, if $t1 is 1 its a yellow timer, if $t1 is 2 its an all red timer

#Find out if the remainder of state / 3 is 0, 1, or 2 then go to the corresponding threshold setting block
beq $t1, $zero, thresh_set_green
addi $t1, $t1, -1
beq $t1, $zero, thresh_set_yellow
addi $t1, $t1, -1
beq $t1, $zero, thresh_set_red

thresh_set_green:
add $t1, $s3, $zero #set the threshold to the green light delay then exit the if
j exit_thresh_set

thresh_set_yellow:
addi $t1, $zero, 1000 #TEMPORARY SINCE YELLOW LIGHT TIMER LOGIC HASNT BEEN DECIDED YET
j exit_thresh_set

thresh_set_red:
addi $t1, $zero, 1000 #when lights are all red, wait 1 second to go to next state

exit_thresh_set: #label to skip other threshold setting blocks

jal print_curr_state

	L1:
	li $v0, 30 #syscall to get current time into $a0
	syscall
	
	sub $t0, $a0, $s4 #get the difference in time between the start of cycle and now
	
	blt $t0, $t1, L1 #if the difference is less than the threshold, loop again

addi $s0, $s0, 1 #increment state
j main_simulator #jump back up to print then loop again
	


# -------------- Print the current state (TEMPORARY LOGIC) ------------------
print_curr_state:
li $v0, 4
la $a0, temp_print_state
syscall
addi $a0, $s0, 0
li $v0, 1
syscall
li $v0, 4
la $a0, new_line
syscall
jr $ra