.type print_data, @function
print_data:
	push %rbp
	mov %rsp, %rbp

	push %rax
	push %rbx
	push %rcx
	push %rdx
	push %r8
	push %r9
	push %r10
	push %r11
	push %r12
	push %r13
	push %r14

	mov $0, %rbx
print_line:
	lea format(%rip), %rdi   # 1er arg: puntero a la cadena de formato
    mov %r9, %rsi            
	mov %r10, %rdx
    xor %eax, %eax           # 0 en RAX/AL (indicador de args vectoriales)

	call printf

	pop %r14
	pop %r13
	pop %r12
	pop %r11
	pop %r10
	pop %r9
	pop %r8
	pop %rdx
	pop %rcx
	pop %rbx
	pop %rax

	mov %rbp, %rsp
	pop %rbp
	ret

.type print_maze, @function
print_maze:
	push %rbp
	mov %rsp, %rbp

	push %rax
	push %rbx
	push %rcx
	push %rdx
	push %r8
	push %r9
	push %r10
	push %r11
	push %r12
	push %r13
	push %r14

	mov $0, %rbx
print_maze_loop:	
	cmpl MAZE_CHARS, %ebx
	jge end_print_maze_loop
	lea format_maze_line(%rip), %rdi   # 1er arg: puntero a la cadena de formato
	mov $MAZE_BUFFER, %rcx
	add %rbx, %rcx
    mov %rcx, %rsi            
    xor %eax, %eax           # 0 en RAX/AL (indicador de args vectoriales)

	call printf
	add $16, %rbx
	jmp print_maze_loop
end_print_maze_loop:

	pop %r14
	pop %r13
	pop %r12
	pop %r11
	pop %r10
	pop %r9
	pop %r8
	pop %rdx
	pop %rcx
	pop %rbx
	pop %rax

	mov %rbp, %rsp
	pop %rbp
	ret

