.data
welcome_msg: .asciiz "Welcome to the traffic light simulator.\n1. Start simulator\n2. Set custom speed limit\n3. Set green light time\nEnter your selection: "
invalid_input: .asciiz "Invalid input...\n"
ask_speed_limit: .asciiz "Enter new speed limit: "
ask_green_time: .asciiz "Enter new green light time: "
new_line: .asciiz "\n"
cross_ew: .asciiz "You may cross EAST/WEST.\n"
cross_ns: .asciiz "You may cross NORTH/SOUTH.\n"

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
#0. No cross walks have cross requests
#1. NS cross walk has cross request
#2. EW cross walk has cross request
#3. Both cross walks have cross requests

# -------------------------Program initialization and defaults----------------------
#[ARGS]: 	No arguments
#[RETURN]: 	No return
init:
	li $s0, 0 	#lights state set to 0
	li $s1, 0 	#crosswalk input state 
	li $s2, 60 	#default speed limit
	li $s3, 3000 	#default green light time
	li $s4, 0 	#start time of simulator cycle
	li $s5, 0	#used for storing cycle time threshold


# ---------------Gather introductory information for the simulator------------------
#[ARGS]: 	No arguments
#[RETURN]: 	No return
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


# ---------------------------Setting the custom speed limit-------------------------
#[ARGS]: 	No arguments
#[RETURN]: 	No return
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


# ---------------------- Setting the custom green light time -----------------------
#[ARGS]: 	No arguments
#[RETURN]: 	No return
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


# -----------------------------Starting the simulator-------------------------------
#[ARGS]: 	No arguments
#[RETURN]: 	No return
main_simulator:
	#get the time for the start of cycle
	li $v0, 30
	syscall
	move $s4, $a0

	#Find out if the remainder of state / 3 is 0, 1, or 2 then go to the corresponding threshold setting block
	#remainder of 0 means its a green light, 1 means yellow light, 2 means all red
	#load params
	rem $a0, $s0, 3
	move $a1, $s2
	move $a2, $s3
	jal get_state_time #call the function which returns the time to wait for the current cycle
	move $s5, $v0

	rem $a0, $s0, 6		#set argument 0 to current light state
	move $a1, $s1		#set argument 1 to current crosswalk input state
	jal print_curr_state	#print the states
	move $s1, $v0		#save new crosswalk state from function call
	L1:
		jal check_for_input
		beq $v0, $zero, no_input
			move $a0, $s1	#pass the current crosswalk input state as a paramater
			move $a1, $v0	#pass the inputted character as a paramater
			jal verify_input
			move $s1, $v0
		
		no_input:
		li $v0, 30 #syscall to get current time into $a0
		syscall
	
		sub $t0, $a0, $s4 #get the difference in time between the start of cycle and now
		blt $t0, $s5, L1 #if the difference is less than the threshold, loop again

	addi $s0, $s0, 1 #increment state
	j main_simulator #jump back up to print then loop again


#------------------------------Crosswalk Input Check--------------------------------
#[ARGS]: 	No arguments
#[RETURN]: 	Returns the character if there is input, or returns 0 if there is no input
check_for_input:
	li $v0, 0
	lui $t0, 0xFFFF		#check if there is input
	lw $t1, 0($t0)
	and $t1, $t1, 1 
	beq $t1, $zero, skip
	#There is input. Return the value
		lb $v0, 4($t0)	#load character from 0xFFFF0004 (user input location)
	skip:
	jr $ra


#-------------------------------Verify Latest Input---------------------------------
#[ARGS]: 	$a0 = Crosswalk input state
#		$a1 = Character to verify
#[RETURN]: 	Returns updated crosswalk state
verify_input: #Function checks if the latest input is a valid input (E, W, N, or S)
	li $t0, 101	#e char
	beq $a1, $t0, EWInput
	li $t0, 119	#w char
	beq $a1, $t0, EWInput
	li $t0, 110	#n char
	beq $a1, $t0, NSInput
	li $t0, 115	#s char
	beq $a1, $t0, NSInput
	move $v0, $a0	#if not NSEW, return state unchanged
	jr $ra
	
	EWInput:
		ori $v0, $a0, 2		#set the 2nd least significant bit to a 1
		jr $ra
	NSInput:
		ori $v0, $a0, 1		#set the least significant bit to a 1
		jr $ra
	
#-----------------------------Get State Time Function-------------------------------
#[ARGS]: 	$a0 = Current state
#		$a1 = Speed limit
#		$a2 = Green light time
#[RETURN]: 	Returns time to wait before going to next state
get_state_time:
	beq $a0, $zero, thresh_set_green
	addi $a0, $a0, -1
	beq $a0, $zero, thresh_set_yellow
	
	#else, all must be red
		addi $v0, $zero, 1000 #when lights are all red, wait 1 second to go to next state
		jr $ra

	thresh_set_green:
		add $v0, $a2, $zero #set the threshold to the green light delay then exit the if
		jr $ra

	thresh_set_yellow:
		li $t0, 80		#80ms / (km/hr)
		mul $v0, $a1, $t0	#multiply km/hr by ms above	
		jr $ra


# ---------------- Print the current state (TEMPORARY LOGIC) -----------------------
#[ARGS]: 	$a0 = Current state
#		$a1 = Crosswalk input state
#[RETURN]: 	Returns new crosswalk state
print_curr_state:
	addi $sp, $sp, -4
	sw $s0, 0($sp)	#stash $s0 so we can use it to hold our argument
	
	move $s0, $a0	#set $s0 to the light state argument so we can reuse argument register
	
	li $v0, 4
	la $a0, temp_print_state	#print temporary state preamble
	syscall
	
	move $a0, $s0
	li $v0, 1			#print current state
	syscall
	
	li $v0, 4
	la $a0, new_line		#print new line
	syscall
	
	beq $s0, $zero, check_ns_cw	#if current state is NS green state, then go to check NS crosswalk
	
	li $t0, 3	#is current state EW green state?
	beq $s0, $t0, check_ew_cw	#if so, go to check EW crosswalk
	j exit_print
	
	check_ns_cw:
		andi $t0, $a1, 1
		beq $t0, $zero, exit_print	#if NS crosswalk input bit is 0, exit
		#if the NS bit is 1:
		li $v0, 4
		la $a0, cross_ns		#print that NS crosswalk active 
		syscall
		andi $a1, $a1, 2		#set NS bit to 0
		j exit_print
		
	check_ew_cw:
		andi $t0, $a1, 2
		beq $t0, $zero, exit_print	#if EW crosswalk input bit is 0, exit
		#if the EW bit is 1:
		li $v0, 4
		la $a0, cross_ew		#print that EW crosswalk active 
		syscall
		andi $a1, $a1, 1		#set EW bit to 0
	
	exit_print:
		move $v0, $a1 	#return (possibly modified) crosswalk input state
		lw $s0, 0($sp)	#restore $s0
		addi $sp, $sp, 4
		jr $ra
