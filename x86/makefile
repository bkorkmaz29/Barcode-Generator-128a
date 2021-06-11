CC=g++
ASMBIN=nasm
all : asm cc link
asm : 
	$(ASMBIN) -o gen128.o -f elf -g -l gen128.lst gen128.nasm
cc :
	$(CC) -m32 -c -g -O0 main.cpp &> errors.txt
link :
	$(CC) -m32 -g -o test main.o gen128.o
clean :
	rm *.o
	rm test
	rm errors.txt	
	rm gen128.lst
