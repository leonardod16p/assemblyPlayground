all:
	nasm allocator.asm -o allocator.o -f elf64
	ld allocator.o -o allocator
	gdb ./allocator
