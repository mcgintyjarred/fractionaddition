NAME 		= fractionaddition
ASM_NAME	= fractionaddition.asm
C_OBJECT	= fractionaddition.o
ASM_OBJECT	= fractionaddition.o

OBJECTS		= $(ASM_OBJECT) $(C_OBJECT)



all: clean $(NAME)

$(NAME): $(OBJECTS)
	gcc -o $@ $(OBJECTS)

$(ASM_OBJECT): $(ASM_NAME)
	nasm -f elf32 $(ASM_NAME)


clean: 
	rm -f *.o *.map *.s *.bin
	rm -f $(NAME)
