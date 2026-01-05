all: multi

multi: multi.o
	gcc -m32 multi.o -o multi

multi.o:
	nasm -f elf32 multi.s -o multi.o

clean:
	rm -f multi *.o