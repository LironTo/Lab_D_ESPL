all: clean link

link: compile
	gcc -m32 -o multi multi.o

compile: multi.o

multi.o:
	nasm -f elf32 multi.s -o multi.o

clean:
	rm -f *.o multi