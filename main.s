.include "print_maze.s"


.section .data
MAZE_BUFFER:
	#.asciz "MMMMMMMMMMMMMMMMM M     M     MMM M MMM M MMM  MM M   M M M    MM MMM M M M  MMMM  X  M   M   #MMMMMMMMMMMMMMMMM"
	#.asciz "MMMMMMMMMMMMMMMMM             #MM M   MMM  MM  MM M  XM M   M  MM M   MMM  MM MMM              MMMMMMMMMMMMMMMMM"
	#.asciz "M@MMMMMMMMMMMMMMM M o   M     MMM M MMM M MMM oMMoM   M M Mo   MM MMM M M M  MMMM  X  M   M   #MMMMMMMM@MMMMMMMM" # Maze 1 Type 2
	.asciz "MMMMMMMMMMMMMMMMM M o         MMMXM MMM M MMM  @M M   M M M    MM MMM M M MMMMMMM M o M MMM  o MM MMMMMoM    MMM@       M MMMM MM  MMMMMM      MM   o      M# oMMMMMMMMMMMMMMMMM" # Maze 4 Type 2

# CHANGE !!!
MAZE_HEIGHT: .long 11
MAZE_CHARS: .long 176

ROT_TO_DIR: .quad 1, 0, 0, 1, -1, 0, 0, -1, 1, 0, 0, 1, -1, 0, 0, -1, 1, 0

INDEX_ROT_OFFSET: .quad 1, 16, -1, -16

format: .asciz "x: %d, y: %d\n\n"
format_maze: .asciz "\n%s\n"
format_maze_line: .asciz "%.16s\n"

.section .bss
.lcomm EXIT_INDEX, 1
.lcomm PORTAL_1_INDEX, 1
.lcomm PORTAL_2_INDEX, 1
.lcomm DIR_X, 8
.lcomm DIR_Y, 8
.lcomm ANGLE, 8
.lcomm ROTATIONS, 8

.equ MAZE_BUFFER_SIZE, 304
/* .lcomm MAZE_BUFFER, MAZE_BUFFER_SIZE
.lcomm MAZE_HEIGHT, 5
.lcomm MAZE_CHARS, 9
 */


.section .text

/* 
%r8  -> character index position
%r9  -> character x position
%r10 -> character y position

DIR_X -> character x direction
DIR_Y -> character y direction
ANGLE -> chracter angle
ROTATIONS -> character rotations

%r11 -> bonus count
%r12 -> portal system count

%r14b -> symbol below

%r15 -> steps count

NOT LONGER USED
											%r11 -> character x direction
											%r12 -> character y direction
											%r13 -> character angle
											%r14 -> character rotations
*/

.extern printf
.globl main

main:
	push %rbp
    mov %rsp, %rbp

	movb $0, EXIT_INDEX
	mov $0, %r11
	mov $0, %r12
	call find_all		# Update character stats
	call print_data
	movb $32, %r14b
	mov $0, %r15
	movq $1, DIR_X
	movq $0, DIR_Y
	movq $0, ANGLE
	movq $0, ROTATIONS

	call solve

	mov %rbp, %rsp
	pop %rbp
    ret

.type solve, @function 
solve:
main_loop:
	call print_maze
	call print_data

	cmpb EXIT_INDEX, %r8b
	jne continue_main_loop
	cmp $0, %r11
	jg continue_main_loop
	jmp main_loop_end

continue_main_loop:
	cmpq $0, ANGLE
	jne stick
	cmpq $0, ROTATIONS
	jne stick

no_stick:
	movq ANGLE, %rax
	call obstacle_at
	cmp $1, %rax
	jne go_forward
	movq ANGLE, %rax
	add $1, %rax
	call obstacle_at
	cmp $1, %rax
	jne go_right
	
	jmp go_back

stick:
	movq ANGLE, %rax
	sub $1, %rax
	call obstacle_at
	cmp $1, %rax
	jne go_left
	movq ANGLE, %rax
	call obstacle_at
	cmp $1, %rax
	jne go_forward
	movq ANGLE, %rax
	add $1, %rax
	call obstacle_at
	cmp $1, %rax
	jne go_right

	jmp go_back

go_forward:
	call walk
	jmp main_loop
go_right:
	call rotate_right
	call walk
	jmp main_loop
go_left:
	call rotate_left
	call walk
	jmp main_loop
go_back:
	call rotate_back
	call walk
	jmp main_loop

main_loop_end:
    ret


.type walk, @function
walk:
	cmpb $35, %r14b
	je set_end_symbol
	cmpb $79, %r14b
	je set_used_portal_symbol

set_empty_symbol:
	movb $32, MAZE_BUFFER(%r8)
	jmp continue_walk
set_end_symbol:
	movb $35, MAZE_BUFFER(%r8)
	jmp continue_walk
set_used_portal_symbol:
	movb $79, MAZE_BUFFER(%r8)		# Set O as used portal symbol

continue_walk:
	addq DIR_X, %r9		# x (pos) += x (dir)
	addq DIR_Y, %r10		# y (pos) += y (dir)

	mov %r10, %r8
	shl $4, %r8			# i = y * 16
	add %r9, %r8		# i = y * 16 + x

	movb $88, MAZE_BUFFER(%r8)

	cmpb $111, %cl		# If sysmbol to step on is 'o'
	je set_bonus		# set bonus
	cmpb $64, %cl
	je walk_teleport
	jmp continue_2_walk

set_bonus:
	dec %r11			# If it is, decrease bonus count

continue_2_walk:
	inc %r15			# increase steps count

	movb %cl, %r14b		# set cl as r14b (symbol below)
	jmp end_walk

walk_teleport:
	call teleport

end_walk:
    ret

.type teleport, @function
teleport:
	movb $79, MAZE_BUFFER(%r8)		# Set entry portal symbol as used 'O'

	cmpb PORTAL_1_INDEX, %r8b
	je teleport_to_second_portal
teleport_to_first_portal:
	movb PORTAL_1_INDEX, %r8b
	jmp continue_teleport
teleport_to_second_portal:
	movb PORTAL_2_INDEX, %r8b
continue_teleport:
	movb $88, MAZE_BUFFER(%r8)		# Set X at exit portal
	movb $79, %r14b					# Set O as symbol below

	# Update coords
	mov %r8, %r10
	shr $4, %r10		# %r10 = %r8 / 16
	mov %r8, %r9
	and $15, %r9		# %r9 = %rsi mod 16

    ret

.type rotate_right, @function
rotate_right:
	cmpq $3, ANGLE
	je set_angle_0_right
	jmp inc_angle_right
set_angle_0_right:
	movq $0, ANGLE
	jmp continue_rot_right
inc_angle_right:
	incq ANGLE
continue_rot_right:
	incq ROTATIONS

	movq DIR_Y, %rax		
	movq DIR_X, %rbx
	neg %rax				# rax = -y (dir)
	movq %rbx, DIR_Y		# y (dir) = x (dir)
	movq %rax, DIR_X			# x (dir) = -y (dir)

    ret

.type rotate_left, @function
rotate_left:
	cmpq $0, ANGLE
	je set_angle_3_left
	jmp dec_angle_left
set_angle_3_left:
	movq $3, ANGLE
	jmp continue_rot_left
dec_angle_left:
	decq ANGLE
continue_rot_left:
	decq ROTATIONS

	movq DIR_X, %rax
	movq DIR_Y, %rbx		
	neg %rax					# rax = -x (dir)
	movq %rbx, DIR_X			# x (dir) = y (dir)
	movq %rax, DIR_Y			# y (dir) = -x (dir)

    ret


.type rotate_back, @function
rotate_back:
	call rotate_right
	call rotate_right
    ret


.type find_all, @function
find_all:
	mov $0, %rbx		# iterate over maze string

find_all_loop:
	cmpl MAZE_CHARS, %ebx
	jge find_all_loop_end
	movb MAZE_BUFFER(%rbx), %cl	# move byte at position %rbx to %dl

find_character:
	cmpb $88, %cl			# if it is equal to X find_character_update
	jne find_exit
	call character_pos_update

find_exit:
	cmpb $35, %cl
	jne find_bonus
	call exit_update

find_bonus:
	cmpb $111, %cl
	jne find_portal
	inc %r11					# increase bonus count

find_portal:
 	cmpb $64, %cl
	jne continue_find_loop
	call portal_update

continue_find_loop:
	inc %rbx
	jmp find_all_loop

find_all_loop_end:
	ret

.type character_pos_update, @function
character_pos_update:
	mov %rbx, %r8		# %r8 = %rsi
	mov %rbx, %r10
	shr $4, %r10		# %r10 = %rsi / 16
	mov %rbx, %r9
	and $15, %r9		# %r9 = %rsi mod 16
	ret

.type exit_update, @function
exit_update:
	movb %bl, EXIT_INDEX
	ret

.type portal_update, @function
portal_update:
	cmp $0, %r12				# if first portal already found
	jne second_portal_set		# then set second portal
first_portal_set:				# if first portal not found, set first portal
	movb %bl, PORTAL_1_INDEX
	mov $1, %r12
	jmp continue_portal_update
second_portal_set:
	movb %bl, PORTAL_2_INDEX
	jmp continue_portal_update
continue_portal_update:
	ret

# RAX(angle) ==> RAX(result)[bool]
.type obstacle_at, @function
obstacle_at:
check_sub_0:
	cmp $0, %rax
	jge check_super_3
	mov $3, %rax
	jmp continue_obs_at
check_super_3:
	cmp $3, %rax
	jle continue_obs_at
	mov $0, %rax
continue_obs_at:
	mov %r8, %rdx		# move character index to rdx
	shl $3, %rax
	movq INDEX_ROT_OFFSET(%rax), %rcx
	add %rcx, %rdx

	movb MAZE_BUFFER(%rdx), %cl

	cmpb $77, %cl
	je set_obs_at_true
	cmpb $79, %cl
	je set_obs_at_true
	jmp set_obs_at_false

set_obs_at_true:
	mov $1, %rax
	jmp end_obs_at
set_obs_at_false:
	mov $0, %rax
	jmp end_obs_at

end_obs_at:
	ret

