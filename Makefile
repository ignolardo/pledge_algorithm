.PHONY: all asm

all: main.c.o
	gcc $< -o pledge

%.c.o: %.c
	gcc -g -c $< -o $@

gdb: all
	gdb pledge

asm: main.s.o
	gcc $< -no-pie -o asm_pledge

%.s.o: %.s
	gcc -g -c $< -no-pie -o $@

print_asm_filesize:
	@filesize=$$(stat -c %s main.s) && echo "Size: $$filesize bytes"  

print_asm_object_filesize:
	@filesize=$$(stat -c %s main.s.o) && echo "Size: $$filesize bytes"

print_asm_elf_filesize:
	@filesize=$$(stat -c %s asm_pledge) && echo "Size: $$filesize bytes"
