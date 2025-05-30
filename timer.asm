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
li $s1, 0	#$s1 = Current state

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

li $t1, 10
blt $s2, $t1, ContinueLooping	#If a second or more has passed, execute following code
addi $s1, $s1, 1	#Change to next light state
move $s0, $a0		#Set previous system time
move $a0, $s1		#Load the current light state for function call
jal PrintCurrState	#Function call for printing light state

ContinueLooping:
j L1




PrintCurrState:
li $v0, 4	#Print string syscall
li $t0, 4
rem $t1, $a0, $t0			#Is current state divisible by 4?
beq $t1, $zero, StateDivisibleBy3or4	#If so: Branch to exit

li $t0, 3
rem $t1, $a0, $t0			#Is current state divisible by 3?
beq $t1, $zero, StateDivisibleBy3or4	#If so: branch to print

li $t0, 2
rem $t1, $a0, $t0			#Is current state divisible by 2?
beq $t1, $zero, StateDivisibleBy2	#If so: branch to print

#Otherwise, assume its at state 1
la $a0, green	#Load green string
j PrintCurrStateReturn

StateDivisibleBy2:
la $a0, yellow 	#Load yellow string
j PrintCurrStateReturn

StateDivisibleBy3or4:
la $a0, red	#Load red string

PrintCurrStateReturn:
syscall		#Print loaded string
jr $ra