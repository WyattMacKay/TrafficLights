.data
green: .asciiz "green\n"
yellow: .asciiz "yellow\n"
red: .asciiz "red\n"

.text
.globl main

main:
li $v0, 30	#System time syscall code
syscall		#Get time

move $s0, $a0	#$s0 = Previous system time
li $s1, 1	#$s1 = Current state

li $s3, 1000	#$s3 = Time between states in ms ----------(THIS IS A CONSTANT!)------------

#State list:
#1: Green
#2: Yellow
#3: Red
#4: Red (almost green)

move $a0, $s1		#Load the current light state for function call
jal PrintCurrState	#Function call for printing light state

L1:
li $v0, 30	#System time syscall code
syscall		#Get current time

sub $s2, $a0, $s0	#$s2 = The time difference

blt $s2, $s3, ContinueLooping	#If time passed exceeds $s3 then execute following code
addi $s1, $s1, 1	#Change to next light state
li $t0, 4		#Total # of states
ble $s1, $t0, LightHasValidState	#If the light state > max number of states, execute following code
li $s1, 1	#Set the light back to state 1
LightHasValidState:
move $s0, $a0		#Set previous system time
move $a0, $s1		#Load the current light state for function call
jal PrintCurrState	#Function call for printing light state

ContinueLooping:
j L1


#Need to add better comments
#Can be made more efficient by checking state 3/4 together
#May even be possible with a while loop
PrintCurrState:
li $v0, 4	#Print string syscall code
li $t0, 4
beq $a0, $t0, State3or4	#If so: Branch to exit

li $t0, 3
beq $a0, $t0, State3or4	#If so: branch to print

li $t0, 2
beq $a0, $t0, State2	#If so: branch to print

#Otherwise, assume its at state 1
la $a0, green	#Load green string
j PrintCurrStateReturn

State2:
la $a0, yellow 	#Load yellow string
j PrintCurrStateReturn

State3or4:
la $a0, red	#Load red string

PrintCurrStateReturn:
syscall		#Print loaded string
jr $ra		#Return